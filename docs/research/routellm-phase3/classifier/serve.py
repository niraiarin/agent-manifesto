#!/usr/bin/env python3
"""
serve.py — FastAPI endpoint serving the routing classifier.

POST /classify {"prompt": "..."} → {"label": "...", "confidence": 0.xx, "probs": {...}}

ccr CUSTOM_ROUTER_PATH hook から呼ばれる前提。localhost:9001 で listen。
"""

from __future__ import annotations

import argparse
import json
import logging
import os
from pathlib import Path

import joblib
from fastapi import FastAPI
from pydantic import BaseModel
from sentence_transformers import SentenceTransformer


class ClassifyRequest(BaseModel):
    prompt: str
    min_confidence: float | None = None


class ClassifyResponse(BaseModel):
    label: str
    confidence: float
    probs: dict[str, float]
    fallback: bool
    latency_ms: float


class DriftLogger:
    """Append-only JSONL log for drift monitoring."""

    def __init__(self, path: Path):
        self.path = path
        path.parent.mkdir(parents=True, exist_ok=True)

    def log(self, req: ClassifyRequest, resp: ClassifyResponse):
        import time
        entry = {
            "ts": time.time(),
            "prompt_sha": self._sha(req.prompt),
            "prompt_len": len(req.prompt),
            "label": resp.label,
            "confidence": resp.confidence,
            "fallback": resp.fallback,
            "latency_ms": resp.latency_ms,
        }
        with open(self.path, "a") as f:
            f.write(json.dumps(entry) + "\n")

    @staticmethod
    def _sha(s: str) -> str:
        import hashlib
        return hashlib.sha256(s.encode()).hexdigest()[:16]


def create_app(model_dir: Path, log_path: Path, oov_threshold: float = 0.5) -> FastAPI:
    app = FastAPI(title="Agent-Manifesto Routing Classifier")
    log = logging.getLogger("routing")

    meta = json.load(open(model_dir / "metadata.json"))
    clf = joblib.load(model_dir / "clf.joblib")
    encoder = SentenceTransformer(meta["encoder"])
    id_to_label = {v: k for k, v in meta["label_map"].items()}
    drift_logger = DriftLogger(log_path)

    @app.post("/classify", response_model=ClassifyResponse)
    def classify(req: ClassifyRequest) -> ClassifyResponse:
        import time
        t0 = time.time()

        vec = encoder.encode(f"query: {req.prompt}", convert_to_numpy=True)
        probs_arr = clf.predict_proba([vec])[0]
        label_id = int(probs_arr.argmax())
        confidence = float(probs_arr[label_id])

        probs_dict = {id_to_label[i]: float(p) for i, p in enumerate(probs_arr)}

        # OOV fallback: if top confidence below threshold, treat as unknown→cloud
        threshold = req.min_confidence if req.min_confidence is not None else oov_threshold
        fallback = confidence < threshold
        label = "cloud_required" if fallback else id_to_label[label_id]

        latency_ms = (time.time() - t0) * 1000
        resp = ClassifyResponse(
            label=label,
            confidence=confidence,
            probs=probs_dict,
            fallback=fallback,
            latency_ms=round(latency_ms, 2),
        )
        drift_logger.log(req, resp)
        return resp

    @app.get("/healthz")
    def health():
        return {"status": "ok", "encoder": meta["encoder"], "labels": list(meta["label_map"])}

    @app.get("/metadata")
    def metadata():
        return meta

    return app


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--model-dir", type=Path, default=Path("../model"))
    parser.add_argument("--log-path", type=Path, default=Path("../logs/predictions.jsonl"))
    parser.add_argument("--port", type=int, default=9001)
    parser.add_argument("--oov-threshold", type=float, default=0.5)
    args = parser.parse_args()

    import uvicorn
    app = create_app(args.model_dir, args.log_path, args.oov_threshold)
    uvicorn.run(app, host="127.0.0.1", port=args.port)


if __name__ == "__main__":
    main()
