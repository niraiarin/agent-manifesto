#!/usr/bin/env python3
"""
serve_setfit.py — #653 Phase 1: FastAPI endpoint with SetFit classifier.

従来 serve.py (LR + e5) の置換。同じ API (/classify, /healthz, /metadata) を提供。
SetFit は predict_proba に対応しているので utility decision も router.js で動作可能。
"""

from __future__ import annotations

import argparse
import hashlib
import json
import logging
import time
from pathlib import Path

from fastapi import FastAPI
from pydantic import BaseModel


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


LABELS = ["local_confident", "local_probable", "cloud_required", "hybrid", "unknown"]
LOCAL_SET = {"local_confident", "local_probable"}
CLOUD_SET = {"cloud_required", "hybrid", "unknown"}


class DriftLogger:
    def __init__(self, path: Path):
        self.path = path
        path.parent.mkdir(parents=True, exist_ok=True)

    def log(self, req: ClassifyRequest, resp: ClassifyResponse):
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


def create_app(model_dir: Path, log_path: Path, oov_threshold: float = 0.3) -> FastAPI:
    app = FastAPI(title="Agent-Manifesto Routing Classifier (SetFit)")
    log = logging.getLogger("routing")

    import os
    import torch
    os.environ.setdefault("PYTORCH_MPS_HIGH_WATERMARK_RATIO", "0.0")
    torch.set_default_device("cpu")

    from setfit import SetFitModel

    meta = json.load(open(model_dir / "setfit_metadata.json"))
    model = SetFitModel.from_pretrained(str(model_dir / "setfit_model"), device="cpu")
    drift_logger = DriftLogger(log_path)

    @app.post("/classify", response_model=ClassifyResponse)
    def classify(req: ClassifyRequest) -> ClassifyResponse:
        t0 = time.time()

        # SetFit predict_proba returns tensor of shape (1, num_labels)
        probs_tensor = model.predict_proba([req.prompt])
        if hasattr(probs_tensor, "cpu"):
            probs_arr = probs_tensor.cpu().numpy()[0]
        else:
            probs_arr = probs_tensor[0]

        probs_dict = {LABELS[i]: float(probs_arr[i]) for i in range(len(LABELS))}
        top_id = int(probs_arr.argmax())
        confidence = float(probs_arr[top_id])

        p_local = probs_dict.get("local_confident", 0.0) + probs_dict.get("local_probable", 0.0)
        p_cloud = probs_dict.get("cloud_required", 0.0) + probs_dict.get("hybrid", 0.0) + probs_dict.get("unknown", 0.0)
        u_local = p_cloud * (-1.8) + p_local * 1.0
        u_cloud = p_cloud * 1.0 + p_local * (-1.0)
        utility_route = "local" if u_local > u_cloud else "cloud"

        threshold = req.min_confidence if req.min_confidence is not None else oov_threshold
        fallback = confidence < threshold
        label = "cloud_required" if fallback else LABELS[top_id]

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
        return {"status": "ok", "model_type": "setfit", "labels": LABELS}

    @app.get("/metadata")
    def metadata():
        return meta

    return app


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--model-dir", type=Path, default=Path("../model-setfit"))
    parser.add_argument("--log-path", type=Path, default=Path("../logs/predictions-setfit.jsonl"))
    parser.add_argument("--port", type=int, default=9001)
    parser.add_argument("--oov-threshold", type=float, default=0.3)
    args = parser.parse_args()

    import uvicorn
    app = create_app(args.model_dir, args.log_path, args.oov_threshold)
    uvicorn.run(app, host="127.0.0.1", port=args.port)


if __name__ == "__main__":
    main()
