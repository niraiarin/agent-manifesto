#!/usr/bin/env python3
"""
train_calibrated.py — Gap 1: isotonic / Platt calibration で ECE 削減.

train.py (raw LR) と比較して ECE + accuracy を測定。
target: ECE <= 0.10 (cf. PR #650 raw LR ECE = 0.44)
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path


LABEL_TO_ID = {
    "local_confident": 0,
    "local_probable": 1,
    "cloud_required": 2,
    "hybrid": 3,
    "unknown": 4,
}
ID_TO_LABEL = {v: k for k, v in LABEL_TO_ID.items()}


def load_jsonl(path: Path) -> list[dict]:
    with open(path) as f:
        return [json.loads(line) for line in f if line.strip()]


def compute_ece(probs, y_true, n_bins: int = 10) -> float:
    """Expected Calibration Error."""
    import numpy as np
    confidences = probs.max(axis=1)
    predictions = probs.argmax(axis=1)
    accuracies = (predictions == y_true).astype(float)

    bin_edges = np.linspace(0, 1, n_bins + 1)
    ece = 0.0
    n = len(y_true)
    for lo, hi in zip(bin_edges[:-1], bin_edges[1:]):
        mask = (confidences >= lo) & (confidences < hi)
        if mask.sum() == 0:
            continue
        bin_acc = accuracies[mask].mean()
        bin_conf = confidences[mask].mean()
        ece += (mask.sum() / n) * abs(bin_acc - bin_conf)
    return float(ece)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--train", type=Path, required=True)
    parser.add_argument("--eval", type=Path, required=True)
    parser.add_argument("--model-out", type=Path, required=True)
    parser.add_argument("--encoder", type=str, default="intfloat/multilingual-e5-small")
    parser.add_argument("--method", choices=["isotonic", "sigmoid", "both"], default="both",
                        help="sigmoid = Platt scaling")
    parser.add_argument("--cv", type=int, default=5, help="CV folds for calibration")
    args = parser.parse_args()

    from sentence_transformers import SentenceTransformer
    from sklearn.linear_model import LogisticRegression
    from sklearn.calibration import CalibratedClassifierCV
    from sklearn.metrics import classification_report
    import joblib
    import numpy as np

    print(f"[calib] loading encoder {args.encoder}")
    encoder = SentenceTransformer(args.encoder)

    train = load_jsonl(args.train)
    evaluation = load_jsonl(args.eval)
    print(f"[calib] train={len(train)} eval={len(evaluation)} cv={args.cv}")

    def encode(texts):
        return encoder.encode([f"query: {t}" for t in texts], convert_to_numpy=True, batch_size=32)

    X_tr = encode([e["prompt"] for e in train])
    y_tr = np.array([LABEL_TO_ID[e["label"]] for e in train])
    X_ev = encode([e["prompt"] for e in evaluation])
    y_ev = np.array([LABEL_TO_ID[e["label"]] for e in evaluation])

    # Baseline: raw LR (for comparison)
    base = LogisticRegression(max_iter=1000, class_weight="balanced", random_state=42)
    base.fit(X_tr, y_tr)
    base_probs = base.predict_proba(X_ev)
    base_acc = (base_probs.argmax(axis=1) == y_ev).mean()
    base_ece = compute_ece(base_probs, y_ev)
    print(f"[calib] raw LR:      accuracy={base_acc:.4f} ECE={base_ece:.4f}")

    # Calibrated
    methods = ["isotonic", "sigmoid"] if args.method == "both" else [args.method]
    results = {
        "raw": {"accuracy": float(base_acc), "ece": float(base_ece)},
    }
    best_clf = base
    best_method = "raw"
    best_ece = base_ece

    for m in methods:
        cc = CalibratedClassifierCV(
            LogisticRegression(max_iter=1000, class_weight="balanced", random_state=42),
            method=m,
            cv=args.cv,
        )
        cc.fit(X_tr, y_tr)
        probs = cc.predict_proba(X_ev)
        acc = (probs.argmax(axis=1) == y_ev).mean()
        ece = compute_ece(probs, y_ev)
        results[m] = {"accuracy": float(acc), "ece": float(ece)}
        marker = "★" if ece < best_ece else " "
        print(f"[calib] {marker} {m:<10}: accuracy={acc:.4f} ECE={ece:.4f}")
        if ece < best_ece:
            best_ece = ece
            best_clf = cc
            best_method = m

    print(f"\n[calib] best method: {best_method} (ECE {best_ece:.4f})")

    # Full eval on best
    best_probs = best_clf.predict_proba(X_ev)
    best_pred = best_probs.argmax(axis=1)
    label_names = [ID_TO_LABEL[i] for i in sorted(ID_TO_LABEL)]
    print(f"\n[calib] best ({best_method}) classification report:")
    print(classification_report(y_ev, best_pred, target_names=label_names, zero_division=0))

    # Reliability diagram for best
    print(f"\n[calib] best ({best_method}) reliability diagram:")
    confidences = best_probs.max(axis=1)
    bin_edges = [0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]
    print(f"  {'bin':<15}{'n':>5}{'acc':>8}{'conf':>8}{'gap':>8}")
    for lo, hi in zip([0.0] + bin_edges[:-1], bin_edges):
        mask = (confidences >= lo) & (confidences < hi)
        n = int(mask.sum())
        if n == 0:
            continue
        acc = float((best_pred[mask] == y_ev[mask]).mean())
        mc = float(confidences[mask].mean())
        print(f"  [{lo:.2f},{hi:.2f})    {n:>5}{acc:>8.3f}{mc:>8.3f}{abs(acc-mc):>8.3f}")

    # Save
    args.model_out.mkdir(parents=True, exist_ok=True)
    joblib.dump(best_clf, args.model_out / "clf.joblib")
    (args.model_out / "metadata.json").write_text(json.dumps({
        "encoder": args.encoder,
        "label_map": LABEL_TO_ID,
        "calibration_method": best_method,
        "eval_accuracy": float((best_pred == y_ev).mean()),
        "eval_ece": best_ece,
        "comparison": results,
        "n_train": len(train),
        "n_eval": len(evaluation),
    }, indent=2))
    print(f"\n[calib] saved best ({best_method}) → {args.model_out}")


if __name__ == "__main__":
    main()
