#!/usr/bin/env python3
"""
threshold_tuning.py — Gap 3: per-class 非対称閾値の設計.

calibration 後の classifier に対し、以下の loss function で per-class threshold を最適化:

  L(thresholds) = alpha * P(Cloud→Local leak) + beta * P(Local→Cloud over-cautious)
                  + gamma * P(reject as unknown)

Cloud→Local leak は safety risk なので alpha を大きく (10.0)。
Local→Cloud は cost (1.0)。
unknown fallback は cost の半分 (0.5)。

target: Cloud→Local leak rate = 0 while maximizing Local usage.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path


LABEL_TO_ID = {
    "local_confident": 0, "local_probable": 1, "cloud_required": 2, "hybrid": 3, "unknown": 4,
}
ID_TO_LABEL = {v: k for k, v in LABEL_TO_ID.items()}


def load_jsonl(path: Path) -> list[dict]:
    with open(path) as f:
        return [json.loads(line) for line in f if line.strip()]


def decide(probs_row, thresholds: dict[str, float]) -> str:
    """Apply per-class threshold. Returns final routing label."""
    import numpy as np
    top_id = int(probs_row.argmax())
    top_conf = float(probs_row[top_id])
    top_label = ID_TO_LABEL[top_id]

    t = thresholds.get(top_label, 0.5)
    if top_conf < t:
        return "unknown"  # → Cloud fallback
    return top_label


def evaluate_thresholds(probs, y_true, thresholds):
    import numpy as np
    n = len(y_true)
    leak_count = 0      # Cloud → Local (safety risk)
    over_count = 0      # Local → Cloud (cost only)
    reject_count = 0    # predicted but rejected as unknown
    correct = 0

    LOCAL = {"local_confident", "local_probable"}
    CLOUD = {"cloud_required", "hybrid", "unknown"}

    for i in range(n):
        true_id = int(y_true[i])
        true_label = ID_TO_LABEL[true_id]
        pred_label = decide(probs[i], thresholds)

        if pred_label == "unknown":
            reject_count += 1
            # Routing outcome: rejected → Cloud fallback.
            # Safety-correct if true was in CLOUD; over-cautious if true in LOCAL.
            if true_label in CLOUD:
                correct += 1
            else:
                over_count += 1
            continue

        if pred_label == true_label:
            correct += 1
            continue

        # Misclassification paths (pred != true, pred != unknown)
        if true_label in CLOUD and pred_label in LOCAL:
            leak_count += 1
        elif true_label in LOCAL and pred_label in CLOUD:
            over_count += 1

    return {
        "accuracy": correct / n,
        "leak_rate": leak_count / n,  # Cloud→Local rate
        "over_cautious_rate": over_count / n,
        "reject_rate": reject_count / n,
    }


def grid_search(probs, y_true, candidate_thresholds):
    """Search over per-class threshold combinations."""
    import itertools
    best = None
    best_score = float("inf")

    # Different class gets different threshold; hold unknown & hybrid at 0.3 baseline
    for t_conf, t_prob in itertools.product(candidate_thresholds, repeat=2):
        for t_cloud in candidate_thresholds:
            thresholds = {
                "local_confident": t_conf,
                "local_probable": t_prob,
                "cloud_required": t_cloud,  # lower threshold → more aggressive cloud detection
                "hybrid": 0.30,
                "unknown": 0.30,
            }
            metrics = evaluate_thresholds(probs, y_true, thresholds)
            # Score: heavy penalty on leak, light on over-cautious
            score = 10.0 * metrics["leak_rate"] + 1.0 * metrics["over_cautious_rate"] + 0.5 * metrics["reject_rate"]
            if metrics["leak_rate"] == 0 and score < best_score:
                best_score = score
                best = (thresholds, metrics)
    return best


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--eval", type=Path, required=True)
    parser.add_argument("--model-dir", type=Path, required=True)
    parser.add_argument("--output", type=Path, default=Path("../analysis/asymmetric-thresholds.json"))
    args = parser.parse_args()

    import joblib
    import numpy as np
    from sentence_transformers import SentenceTransformer

    meta = json.load(open(args.model_dir / "metadata.json"))
    clf = joblib.load(args.model_dir / "clf.joblib")
    encoder = SentenceTransformer(meta["encoder"])

    evaluation = load_jsonl(args.eval)
    X_ev = encoder.encode([f"query: {e['prompt']}" for e in evaluation], convert_to_numpy=True, batch_size=32)
    y_ev = np.array([LABEL_TO_ID[e["label"]] for e in evaluation])
    probs = clf.predict_proba(X_ev)

    # Baseline: single threshold 0.5 (current router.js)
    baseline = evaluate_thresholds(probs, y_ev, {
        "local_confident": 0.50, "local_probable": 0.50,
        "cloud_required": 0.30, "hybrid": 0.30, "unknown": 0.30,
    })
    print(f"[threshold] baseline (uniform local=0.5):")
    print(f"  accuracy={baseline['accuracy']:.3f}  leak={baseline['leak_rate']:.3%}  over-cautious={baseline['over_cautious_rate']:.3%}  reject={baseline['reject_rate']:.3%}")

    # Grid search
    candidates = [0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90]
    result = grid_search(probs, y_ev, candidates)
    if result is None:
        print("[threshold] no zero-leak configuration found; falling back to uniform 0.9")
        thresholds = {k: 0.9 for k in LABEL_TO_ID}
        thresholds["cloud_required"] = 0.3
        metrics = evaluate_thresholds(probs, y_ev, thresholds)
    else:
        thresholds, metrics = result

    print(f"\n[threshold] asymmetric (zero-leak):")
    print(f"  thresholds: {json.dumps(thresholds, indent=2)}")
    print(f"  accuracy={metrics['accuracy']:.3f}  leak={metrics['leak_rate']:.3%}  over-cautious={metrics['over_cautious_rate']:.3%}  reject={metrics['reject_rate']:.3%}")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps({
        "baseline": {
            "thresholds": {"local_*": 0.50, "cloud_*": 0.30},
            "metrics": baseline,
        },
        "asymmetric": {
            "thresholds": thresholds,
            "metrics": metrics,
        },
    }, indent=2))
    print(f"[threshold] wrote {args.output}")


if __name__ == "__main__":
    main()
