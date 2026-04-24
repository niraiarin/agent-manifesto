#!/usr/bin/env python3
"""
serve_encoder.py — FastAPI endpoint for the fine-tuned encoder router.

POST /classify {"prompt": "..."} -> ClassifyResponse compatible with router.js.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import logging
import os
import sys
from collections import Counter, deque
from pathlib import Path
from typing import Any

from fastapi import FastAPI, Response
from pydantic import BaseModel

sys.path.insert(0, str(Path(__file__).resolve().parent))
from decision_logger import DecisionLogger, new_event_id, sha256_hex, build_context


LOCAL_LABELS = {"local_confident", "local_probable"}
CLOUD_LABELS = {"cloud_required", "hybrid", "unknown"}


class ClassifyRequest(BaseModel):
    prompt: str
    min_confidence: float | None = None
    session_id: str | None = None
    turn_id: int | None = None
    parent_event_id: str | None = None


class ClassifyResponse(BaseModel):
    label: str
    confidence: float
    probs: dict[str, float]
    fallback: bool
    latency_ms: float
    p_local: float
    p_cloud: float
    utility_route: str
    event_id: str | None = None


class DriftLogger:
    """Append-only JSONL log for drift monitoring."""

    def __init__(self, path: Path, buffer_size: int = 1000):
        self.path = path
        self.recent: deque[dict[str, Any]] = deque(maxlen=buffer_size)
        self.prediction_total: Counter[str] = Counter()
        self.fallback_total = 0
        path.parent.mkdir(parents=True, exist_ok=True)

    def log(self, req: ClassifyRequest, resp: ClassifyResponse):
        import hashlib
        import time

        entry = {
            "ts": time.time(),
            "prompt_sha": hashlib.sha256(req.prompt.encode()).hexdigest()[:16],
            "prompt_len": len(req.prompt),
            "label": resp.label,
            "confidence": resp.confidence,
            "fallback": resp.fallback,
            "latency_ms": resp.latency_ms,
            "p_local": resp.p_local,
            "p_cloud": resp.p_cloud,
            "utility_route": resp.utility_route,
        }
        self.recent.append(entry)
        self.prediction_total[resp.label] += 1
        if resp.fallback:
            self.fallback_total += 1
        with open(self.path, "a") as f:
            f.write(json.dumps(entry) + "\n")

    def metrics_text(self) -> str:
        lines = [
            "# HELP router_prediction_total Total predictions by label",
            "# TYPE router_prediction_total counter",
        ]
        for label in sorted(self.prediction_total):
            lines.append(f'router_prediction_total{{label="{label}"}} {self.prediction_total[label]}')

        confidences = [float(entry["confidence"]) for entry in self.recent]
        confidence_mean = sum(confidences) / len(confidences) if confidences else 0.0
        lines.extend(
            [
                "",
                "# HELP router_confidence_mean Mean confidence (recent 1000 predictions)",
                "# TYPE router_confidence_mean gauge",
                f"router_confidence_mean {confidence_mean:.6f}",
                "",
                "# HELP router_fallback_total Total fallback triggers",
                "# TYPE router_fallback_total counter",
                f"router_fallback_total {self.fallback_total}",
                "",
                "# HELP router_latency_p95_ms p95 latency in milliseconds (recent 1000)",
                "# TYPE router_latency_p95_ms gauge",
                f"router_latency_p95_ms {self._latency_p95_ms():.6f}",
            ]
        )
        return "\n".join(lines) + "\n"

    def _latency_p95_ms(self) -> float:
        latencies = sorted(float(entry["latency_ms"]) for entry in self.recent)
        if not latencies:
            return 0.0
        index = min(len(latencies) - 1, int(len(latencies) * 0.95))
        return latencies[index]


def utility_decide(p_local: float, p_cloud: float, cost_safety: float, cost_cloud: float) -> str:
    u_local = p_cloud * (-cost_safety) + p_local * 1.0
    u_cloud = p_cloud * 1.0 + p_local * (-cost_cloud)
    return "local" if u_local > u_cloud else "cloud"


def create_app(
    model_dir: Path,
    log_path: Path,
    oov_threshold: float = 0.3,
    cost_safety: float = 1.8,
    cost_cloud: float = 1.0,
    decision_log_dir: Path | None = None,
    redaction_level: str = "prompt_sha_only",
) -> FastAPI:
    import torch
    from transformers import AutoModelForSequenceClassification, AutoTokenizer

    app = FastAPI(title="Agent-Manifesto Encoder Routing Classifier")
    log = logging.getLogger("routing")

    meta = json.load(open(model_dir / "encoder_metadata.json"))
    encoder_dir = model_dir / "encoder_model"
    labels = meta["labels"]

    if torch.backends.mps.is_available():
        device = "mps"
    elif torch.cuda.is_available():
        device = "cuda"
    else:
        device = "cpu"

    tokenizer = AutoTokenizer.from_pretrained(str(encoder_dir), trust_remote_code=True, fix_mistral_regex=True)
    model = AutoModelForSequenceClassification.from_pretrained(str(encoder_dir), trust_remote_code=True)
    model.to(device)
    model.eval()
    drift_logger = DriftLogger(log_path)

    classifier_id = meta.get("base_model", "unknown")
    classifier_version = meta.get("model_type", "encoder_fullft")

    decision_logger_instance: DecisionLogger | None = None
    if decision_log_dir is not None:
        decision_logger_instance = DecisionLogger(
            log_dir=decision_log_dir,
            recorded_by="serve_encoder",
            hook_id="post.classify",
            redaction_level=redaction_level,
        )
        log.info("decision logger enabled at %s (redaction=%s)", decision_log_dir, redaction_level)

    log.info("loaded encoder router base=%s device=%s", meta.get("base_model"), device)

    @app.post("/classify", response_model=ClassifyResponse)
    def classify(req: ClassifyRequest) -> ClassifyResponse:
        import time

        t0 = time.time()
        with torch.no_grad():
            inputs = tokenizer(req.prompt, return_tensors="pt", truncation=True, max_length=512)
            inputs = {k: v.to(device) for k, v in inputs.items()}
            logits = model(**inputs).logits
            probs_arr = torch.softmax(logits, dim=-1).squeeze(0).detach().cpu().tolist()

        label_id = max(range(len(probs_arr)), key=probs_arr.__getitem__)
        confidence = float(probs_arr[label_id])
        probs_dict = {labels[i]: float(p) for i, p in enumerate(probs_arr)}

        p_local = sum(probs_dict.get(label, 0.0) for label in LOCAL_LABELS)
        p_cloud = sum(probs_dict.get(label, 0.0) for label in CLOUD_LABELS)
        utility_route = utility_decide(p_local, p_cloud, cost_safety, cost_cloud)

        threshold = req.min_confidence if req.min_confidence is not None else oov_threshold
        fallback = confidence < threshold
        label = "cloud_required" if fallback else labels[label_id]

        latency_ms = (time.time() - t0) * 1000

        event_id: str | None = None
        if decision_logger_instance is not None:
            event_id = new_event_id()
            prompt_text = req.prompt
            input_payload: dict[str, Any] = {
                "prompt_sha256": sha256_hex(prompt_text),
                "prompt_length": len(prompt_text),
                "prompt_source": "hook",
            }
            if redaction_level == "none":
                input_payload["prompt"] = prompt_text
            session_id = req.session_id or "anonymous"
            context = build_context(
                session_id=session_id,
                project_id="agent-manifesto",
                turn_id=req.turn_id,
            )
            decision_payload = {
                "kind": "classification",
                "classifier_id": classifier_id,
                "classifier_version": classifier_version,
                "probs": probs_dict,
                "predicted_label": label,
                "predicted_confidence": confidence,
                "p_local": round(p_local, 4),
                "p_cloud": round(p_cloud, 4),
                "latency_ms": round(latency_ms, 2),
            }
            decision_logger_instance.emit({
                "event_id": event_id,
                "parent_event_id": req.parent_event_id,
                "event_type": "router.classification",
                "context": context,
                "input": input_payload,
                "decision": decision_payload,
            })

        resp = ClassifyResponse(
            label=label,
            confidence=confidence,
            probs=probs_dict,
            fallback=fallback,
            latency_ms=round(latency_ms, 2),
            p_local=round(p_local, 4),
            p_cloud=round(p_cloud, 4),
            utility_route=utility_route,
            event_id=event_id,
        )
        drift_logger.log(req, resp)
        return resp

    @app.get("/healthz")
    def health():
        return {
            "status": "ok",
            "model_type": meta.get("model_type"),
            "base_model": meta.get("base_model"),
            "device": device,
            "labels": labels,
        }

    @app.get("/metadata")
    def metadata():
        return meta

    @app.get("/metrics")
    def metrics():
        return Response(
            content=drift_logger.metrics_text(),
            media_type="text/plain; version=0.0.4",
        )

    return app


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--model-dir", type=Path, default=Path("../model-mdeberta"))
    parser.add_argument("--log-path", type=Path, default=Path("../logs/predictions-mdeberta.jsonl"))
    parser.add_argument("--port", type=int, default=9001)
    parser.add_argument("--oov-threshold", type=float, default=0.3)
    parser.add_argument("--cost-safety", type=float, default=float(os.environ.get("ROUTING_COST_SAFETY", "1.8")))
    parser.add_argument("--cost-cloud", type=float, default=float(os.environ.get("ROUTING_COST_CLOUD", "1.0")))
    default_decision_dir = os.environ.get("DECISION_LOG_DIR")
    parser.add_argument(
        "--decision-log-dir",
        type=Path,
        default=Path(default_decision_dir) if default_decision_dir else None,
        help="If set, emit router.classification events (decision_event v1.0.0) to this dir.",
    )
    parser.add_argument(
        "--decision-redaction",
        choices=("none", "prompt_sha_only"),
        default=os.environ.get("DECISION_LOG_REDACTION", "prompt_sha_only"),
        help="Redaction level for prompt in decision log events (default: prompt_sha_only).",
    )
    args = parser.parse_args()

    import uvicorn

    app = create_app(
        args.model_dir,
        args.log_path,
        args.oov_threshold,
        args.cost_safety,
        args.cost_cloud,
        decision_log_dir=args.decision_log_dir,
        redaction_level=args.decision_redaction,
    )
    uvicorn.run(app, host="127.0.0.1", port=args.port)


if __name__ == "__main__":
    main()
