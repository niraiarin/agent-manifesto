#!/usr/bin/env python3
"""
held_out_calibration.py — #653 Phase 4.

double-dipping 解消: train を 60/20/20 に 3 分割.
- Train (60%): classifier 学習
- Calibration set (20%): CalibratedClassifierCV が内部 CV で使用
- True hold-out (20%): method selection に使わず、純粋に ECE + accuracy 測定

目的: ECE 0.073 が実際に held-out でも維持されるか検証
"""

from __future__ import annotations

import argparse
import json
import random
from pathlib import Path


LABEL_TO_ID = {"local_confident": 0, "local_probable": 1, "cloud_required": 2, "hybrid": 3, "unknown": 4}
ID_TO_LABEL = {v: k for k, v in LABEL_TO_ID.items()}


def load_jsonl(path: Path) -> list[dict]:
    with open(path) as f:
        return [json.loads(line) for line in f if line.strip()]


def stratified_split(data: list[dict], ratios: tuple[float, float, float], seed: int = 42):
    """Stratified split by label, preserving class distribution across splits."""
    random.seed(seed)
    by_label: dict[str, list[dict]] = {}
    for e in data:
        by_label.setdefault(e["label"], []).append(e)

    splits = [[], [], []]
    for label, items in by_label.items():
        random.shuffle(items)
        n = len(items)
        n1 = int(n * ratios[0])
        n2 = int(n * (ratios[0] + ratios[1]))
        splits[0].extend(items[:n1])
        splits[1].extend(items[n1:n2])
        splits[2].extend(items[n2:])
    for s in splits:
        random.shuffle(s)
    return splits


def compute_ece(probs, y_true, n_bins: int = 10) -> float:
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
    parser.add_argument("--train-full", type=Path, required=True,
                        help="Full labeled data (before train/eval split)")
    parser.add_argument("--encoder", type=str, default="intfloat/multilingual-e5-small")
    parser.add_argument("--output", type=Path, default=Path("../analysis/held-out-calibration.json"))
    args = parser.parse_args()

    import joblib
    import numpy as np
    from sentence_transformers import SentenceTransformer
    from sklearn.linear_model import LogisticRegression
    from sklearn.calibration import CalibratedClassifierCV
    from sklearn.metrics import classification_report

    # Merge train + eval into full corpus
    full = load_jsonl(args.train_full)
    print(f"[held-out] full corpus: n={len(full)}")

    # Stratified 60/20/20 split
    train_set, calib_set, holdout_set = stratified_split(full, (0.60, 0.20, 0.20), seed=42)
    print(f"[held-out] splits: train={len(train_set)}  calib={len(calib_set)}  holdout={len(holdout_set)}")
    for name, s in [("train", train_set), ("calib", calib_set), ("holdout", holdout_set)]:
        from collections import Counter
        dist = Counter(e["label"] for e in s)
        print(f"  {name:<10} dist: {dict(dist)}")

    enc = SentenceTransformer(args.encoder)

    def encode(items):
        return enc.encode([f"query: {e['prompt']}" for e in items], convert_to_numpy=True, batch_size=32, show_progress_bar=False)

    X_tr = encode(train_set)
    y_tr = np.array([LABEL_TO_ID[e["label"]] for e in train_set])
    X_cal = encode(calib_set)
    y_cal = np.array([LABEL_TO_ID[e["label"]] for e in calib_set])
    X_ho = encode(holdout_set)
    y_ho = np.array([LABEL_TO_ID[e["label"]] for e in holdout_set])

    results = {}

    # === Baseline: raw LR trained on train_set only ===
    base = LogisticRegression(max_iter=1000, class_weight="balanced", random_state=42)
    base.fit(X_tr, y_tr)
    for split_name, X, y in [("calib", X_cal, y_cal), ("holdout", X_ho, y_ho)]:
        probs = base.predict_proba(X)
        acc = float((probs.argmax(axis=1) == y).mean())
        ece = compute_ece(probs, y)
        results[f"raw_{split_name}"] = {"accuracy": acc, "ece": ece}
        print(f"[held-out] raw LR on {split_name}: acc={acc:.4f}  ece={ece:.4f}")

    # === Isotonic calibration on train+calib via CV (still on combined set) ===
    # This is the realistic setup for user-facing classifier.
    X_trcal = np.concatenate([X_tr, X_cal])
    y_trcal = np.concatenate([y_tr, y_cal])
    iso = CalibratedClassifierCV(
        LogisticRegression(max_iter=1000, class_weight="balanced", random_state=42),
        method="isotonic",
        cv=5,
    )
    iso.fit(X_trcal, y_trcal)

    # Measure on true hold-out (never seen during calibration CV or method selection)
    probs_ho = iso.predict_proba(X_ho)
    acc_ho = float((probs_ho.argmax(axis=1) == y_ho).mean())
    ece_ho = compute_ece(probs_ho, y_ho)
    results["isotonic_holdout"] = {"accuracy": acc_ho, "ece": ece_ho}
    print(f"\n[held-out] isotonic (trained on train+calib) evaluated on TRUE HOLD-OUT: acc={acc_ho:.4f}  ece={ece_ho:.4f}")

    # Reliability diagram on hold-out
    print(f"\n[held-out] isotonic reliability on HOLD-OUT:")
    print(f"  {'bin':<15}{'n':>5}{'acc':>8}{'conf':>8}{'gap':>8}")
    confs = probs_ho.max(axis=1)
    preds = probs_ho.argmax(axis=1)
    reliability = []
    for lo in [0.0, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]:
        hi = lo + 0.1 if lo >= 0.2 else 0.2
        mask = (confs >= lo) & (confs < hi)
        n = int(mask.sum())
        if n == 0:
            continue
        acc = float((preds[mask] == y_ho[mask]).mean())
        mc = float(confs[mask].mean())
        gap = abs(acc - mc)
        reliability.append({"bin": f"[{lo:.2f},{hi:.2f})", "n": n, "accuracy": acc, "mean_conf": mc, "gap": gap})
        print(f"  [{lo:.2f},{hi:.2f})  {n:>5}{acc:>8.3f}{mc:>8.3f}{gap:>8.3f}")
    results["reliability_holdout"] = reliability

    # Compare to PoC-era ECE on train-eval split (the "official" v2 numbers)
    print(f"\n[held-out] comparison:")
    print(f"  v2 report (train-eval split, CV=5 on train-eval): ECE=0.0734, acc=0.9660")
    print(f"  v3 true-holdout (CV=5 on train+calib, measure on holdout): ECE={ece_ho:.4f}, acc={acc_ho:.4f}")
    diff = ece_ho - 0.0734
    print(f"  ECE delta (true - reported): {diff:+.4f}")
    if diff > 0.05:
        print(f"  ⚠️ Double-dipping was inflating calibration claim by ~{diff:.3f}")
    else:
        print(f"  ✅ Reported ECE is representative")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps({
        "splits": {
            "train": len(train_set),
            "calib": len(calib_set),
            "holdout": len(holdout_set),
        },
        "results": results,
        "conclusion": {
            "double_dipping_inflation": round(diff, 4),
            "inflation_severe_gt_0_05": diff > 0.05,
        },
    }, indent=2))
    print(f"\n[held-out] wrote {args.output}")


if __name__ == "__main__":
    main()
