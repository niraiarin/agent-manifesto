#!/usr/bin/env python3
"""
serve_encoder.py — FastAPI endpoint for the fine-tuned encoder router.

POST /classify {"prompt": "..."} -> ClassifyResponse compatible with router.js.
"""

from __future__ import annotations

import argparse
import json
import logging
import os
from pathlib import Path

from fastapi import FastAPI
from pydantic import BaseModel


LOCAL_LABELS = {"local_confident", "local_probable"}
CLOUD_LABELS = {"cloud_required", "hybrid", "unknown"}


class ClassifyRequest(BaseModel):
    prompt: str
    min_confidence: float | None = None


class ClassifyResponse(BaseModel):
    label: str
    confidence: float
    probs: dict[str, float]
    fallback: bool
    latency_ms: float
    p_local: float
    p_cloud: float
    utility_route: str


class DriftLogger:
    """Append-only JSONL log for drift monitoring."""

    def __init__(self, path: Path):
        self.path = path
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
        with open(self.path, "a") as f:
            f.write(json.dumps(entry) + "\n")


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
        resp = ClassifyResponse(
            label=label,
            confidence=confidence,
            probs=probs_dict,
            fallback=fallback,
            latency_ms=round(latency_ms, 2),
            p_local=round(p_local, 4),
            p_cloud=round(p_cloud, 4),
            utility_route=utility_route,
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

    return app


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--model-dir", type=Path, default=Path("../model-mdeberta"))
    parser.add_argument("--log-path", type=Path, default=Path("../logs/predictions-mdeberta.jsonl"))
    parser.add_argument("--port", type=int, default=9001)
    parser.add_argument("--oov-threshold", type=float, default=0.3)
    parser.add_argument("--cost-safety", type=float, default=float(os.environ.get("ROUTING_COST_SAFETY", "1.8")))
    parser.add_argument("--cost-cloud", type=float, default=float(os.environ.get("ROUTING_COST_CLOUD", "1.0")))
    args = parser.parse_args()

    import uvicorn

    app = create_app(args.model_dir, args.log_path, args.oov_threshold, args.cost_safety, args.cost_cloud)
    uvicorn.run(app, host="127.0.0.1", port=args.port)


if __name__ == "__main__":
    main()
