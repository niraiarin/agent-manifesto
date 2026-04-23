#!/usr/bin/env python3
"""
gt_accuracy.py — #653 Phase 2: Opus GT labels での true accuracy 測定.

gt_label が埋まった 100 件に対し:
- exact label accuracy
- routing direction accuracy (Local vs Cloud)
- leak rate (true cloud → predicted local)
- utility decision outcome at cost_safety=1.8
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from pathlib import Path


LABEL_TO_ID = {"local_confident": 0, "local_probable": 1, "cloud_required": 2, "hybrid": 3, "unknown": 4}
ID_TO_LABEL = {v: k for k, v in LABEL_TO_ID.items()}
LOCAL = {"local_confident", "local_probable"}
CLOUD = {"cloud_required", "hybrid", "unknown"}


def utility_decide(probs_row, cost_safety, cost_cloud):
    p_local = sum(probs_row[LABEL_TO_ID[c]] for c in LOCAL)
    p_cloud = sum(probs_row[LABEL_TO_ID[c]] for c in CLOUD)
    u_cloud = p_cloud * 1.0 + p_local * (-cost_cloud)
    u_local = p_cloud * (-cost_safety) + p_local * 1.0
    if u_local > u_cloud:
        if probs_row[LABEL_TO_ID["local_confident"]] > probs_row[LABEL_TO_ID["local_probable"]]:
            return "local_confident"
        return "local_probable"
    return "cloud_required"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--labeled", type=Path, required=True)
    parser.add_argument("--model-dir", type=Path, required=True)
    parser.add_argument("--cost-safety", type=float, default=1.8)
    parser.add_argument("--output", type=Path, default=Path("../analysis/gt-accuracy.json"))
    args = parser.parse_args()

    import joblib
    import numpy as np
    from sentence_transformers import SentenceTransformer

    meta = json.load(open(args.model_dir / "metadata.json"))
    clf = joblib.load(args.model_dir / "clf.joblib")
    enc = SentenceTransformer(meta["encoder"])

    entries = [json.loads(l) for l in args.labeled.read_text().splitlines() if l.strip()]
    entries = [e for e in entries if e.get("gt_label")]
    print(f"[gt-acc] {len(entries)} labeled entries")

    X = enc.encode([f"query: {e['prompt']}" for e in entries], convert_to_numpy=True, batch_size=32, show_progress_bar=False)
    probs = clf.predict_proba(X)

    # Metrics
    exact_correct = 0
    routing_correct_argmax = 0
    routing_correct_utility = 0
    leak_argmax = 0
    leak_utility = 0
    over_argmax = 0
    over_utility = 0
    per_gt_label = Counter()
    confusion_argmax = Counter()
    confusion_utility = Counter()

    local_pred_argmax = 0
    local_pred_utility = 0

    for i, e in enumerate(entries):
        gt = e["gt_label"]
        per_gt_label[gt] += 1

        argmax_pred = ID_TO_LABEL[int(probs[i].argmax())]
        utility_pred = utility_decide(probs[i], args.cost_safety, 1.0)

        if argmax_pred == gt:
            exact_correct += 1

        gt_local = gt in LOCAL
        argmax_local = argmax_pred in LOCAL
        utility_local = utility_pred in LOCAL

        if argmax_local:
            local_pred_argmax += 1
        if utility_local:
            local_pred_utility += 1

        if argmax_local == gt_local:
            routing_correct_argmax += 1
        if utility_local == gt_local:
            routing_correct_utility += 1

        if gt_local is False and argmax_local:
            leak_argmax += 1
        if gt_local is False and utility_local:
            leak_utility += 1

        if gt_local and not argmax_local:
            over_argmax += 1
        if gt_local and not utility_local:
            over_utility += 1

        confusion_argmax[(gt, argmax_pred)] += 1
        confusion_utility[(gt, utility_pred)] += 1

    n = len(entries)
    print(f"\n=== Exact label accuracy: {exact_correct}/{n} = {exact_correct/n:.1%} ===")

    print(f"\n=== Routing direction (argmax) ===")
    print(f"  accuracy: {routing_correct_argmax}/{n} = {routing_correct_argmax/n:.1%}")
    print(f"  leak (true Cloud → pred Local): {leak_argmax}/{n} = {leak_argmax/n:.1%}")
    print(f"  over-cautious (true Local → pred Cloud): {over_argmax}/{n} = {over_argmax/n:.1%}")
    print(f"  Local predictions: {local_pred_argmax}/{n} = {local_pred_argmax/n:.1%}")

    print(f"\n=== Routing direction (utility cost_safety={args.cost_safety}) ===")
    print(f"  accuracy: {routing_correct_utility}/{n} = {routing_correct_utility/n:.1%}")
    print(f"  leak: {leak_utility}/{n} = {leak_utility/n:.1%}")
    print(f"  over-cautious: {over_utility}/{n} = {over_utility/n:.1%}")
    print(f"  Local predictions: {local_pred_utility}/{n} = {local_pred_utility/n:.1%}")

    print(f"\n=== GT label distribution ===")
    for lbl, cnt in sorted(per_gt_label.items(), key=lambda x: -x[1]):
        print(f"  {lbl}: {cnt} ({cnt/n:.1%})")

    print(f"\n=== Confusion matrix (utility vs GT) ===")
    # Rows = GT, columns = utility pred
    all_labels = ["local_confident", "local_probable", "cloud_required", "hybrid", "unknown"]
    print(f"{'GT':<20} " + " ".join(f"{l[:8]:>8}" for l in all_labels))
    for gt in all_labels:
        row = [confusion_utility.get((gt, p), 0) for p in all_labels]
        if sum(row) == 0: continue
        print(f"{gt:<20} " + " ".join(f"{v:>8}" for v in row))

    report = {
        "n": n,
        "cost_safety": args.cost_safety,
        "exact_accuracy": exact_correct / n,
        "routing_argmax": {
            "accuracy": routing_correct_argmax / n,
            "leak_rate": leak_argmax / n,
            "over_cautious_rate": over_argmax / n,
            "local_predictions": local_pred_argmax,
        },
        "routing_utility": {
            "accuracy": routing_correct_utility / n,
            "leak_rate": leak_utility / n,
            "over_cautious_rate": over_utility / n,
            "local_predictions": local_pred_utility,
        },
        "gt_distribution": dict(per_gt_label),
        "confusion_utility": {f"{k[0]}→{k[1]}": v for k, v in confusion_utility.items()},
    }

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2, ensure_ascii=False))
    print(f"\n[gt-acc] wrote {args.output}")


if __name__ == "__main__":
    main()
