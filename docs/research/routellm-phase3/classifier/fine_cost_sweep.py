#!/usr/bin/env python3
"""
fine_cost_sweep.py — #653 Phase 3: fine-grained cost_safety sweep.

Verifier B-3 指摘: cost_safety={1,2,5,10,20,50} の粗い grid で「2 が sweet spot」と断定。
連続空間の最適は確認不可。0.1 刻みで 1.0-3.0 を探索して真の optimum を特定。
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


def grade_eval_set(probs, y_true, cost_safety, cost_cloud):
    n = len(y_true)
    leak = over = 0
    routing_correct = 0
    local_count = 0
    for i in range(n):
        true_label = ID_TO_LABEL[int(y_true[i])]
        pred = utility_decide(probs[i], cost_safety, cost_cloud)
        pred_local = pred in LOCAL
        true_local = true_label in LOCAL
        true_cloud = true_label in CLOUD
        if pred_local:
            local_count += 1
        if pred_local == true_local:
            routing_correct += 1
        if true_cloud and pred_local:
            leak += 1
        elif true_local and not pred_local:
            over += 1
    return {
        "routing_acc": routing_correct / n,
        "leak_rate": leak / n,
        "over_rate": over / n,
        "local_count": local_count,
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--eval-set", type=Path, required=True)
    parser.add_argument("--real-prompts", type=Path, default=None)
    parser.add_argument("--model-dir", type=Path, required=True)
    parser.add_argument("--cost-min", type=float, default=1.0)
    parser.add_argument("--cost-max", type=float, default=3.0)
    parser.add_argument("--cost-step", type=float, default=0.1)
    parser.add_argument("--output", type=Path, default=Path("../analysis/fine-cost-sweep.json"))
    args = parser.parse_args()

    import joblib
    import numpy as np
    from sentence_transformers import SentenceTransformer

    meta = json.load(open(args.model_dir / "metadata.json"))
    clf = joblib.load(args.model_dir / "clf.joblib")
    enc = SentenceTransformer(meta["encoder"])

    eval_data = [json.loads(l) for l in args.eval_set.read_text().splitlines() if l.strip()]
    X_ev = enc.encode([f"query: {e['prompt']}" for e in eval_data], convert_to_numpy=True, batch_size=32, show_progress_bar=False)
    y_ev = np.array([LABEL_TO_ID[e["label"]] for e in eval_data])
    probs_ev = clf.predict_proba(X_ev)

    real_probs = None
    if args.real_prompts:
        reals = [json.loads(l) for l in args.real_prompts.read_text().splitlines() if l.strip()]
        X_re = enc.encode([f"query: {p['prompt']}" for p in reals], convert_to_numpy=True, batch_size=32, show_progress_bar=False)
        real_probs = clf.predict_proba(X_re)
        print(f"[fine-sweep] real corpus: n={len(reals)}")

    steps = int((args.cost_max - args.cost_min) / args.cost_step) + 1
    results = []
    print(f"[fine-sweep] cost_safety sweep @ {args.cost_step} step ({steps} points):")
    print(f"  {'cost':>6} {'acc':>8} {'leak':>8} {'over':>8} {'eval_local':>10} {'real_local':>10} {'real_pct':>8}")

    first_zero_leak = None
    best_acc = (0, -1.0)

    for i in range(steps):
        cs = round(args.cost_min + i * args.cost_step, 3)
        grade = grade_eval_set(probs_ev, y_ev, cs, 1.0)
        row = {"cost_safety": cs, **grade}
        if real_probs is not None:
            real_counts = Counter(utility_decide(r, cs, 1.0) for r in real_probs)
            real_local = sum(v for k, v in real_counts.items() if k in LOCAL)
            row["real_local"] = real_local
            row["real_local_pct"] = round(real_local / len(real_probs) * 100, 2)

        results.append(row)
        real_loc_str = f"{row.get('real_local', '-'):>10}" if real_probs is not None else ""
        real_pct_str = f"{row.get('real_local_pct', '-'):>8.1f}" if real_probs is not None else ""
        print(f"  {cs:>6.2f} {grade['routing_acc']:>8.4f} {grade['leak_rate']:>8.4f} {grade['over_rate']:>8.4f} {grade['local_count']:>10}{real_loc_str}{real_pct_str}")

        if grade["leak_rate"] == 0.0 and first_zero_leak is None:
            first_zero_leak = cs
        if grade["leak_rate"] == 0.0 and grade["routing_acc"] > best_acc[1]:
            best_acc = (cs, grade["routing_acc"])

    print(f"\n[fine-sweep] first zero-leak at cost_safety={first_zero_leak}")
    print(f"[fine-sweep] best zero-leak accuracy: cost_safety={best_acc[0]} acc={best_acc[1]:.4f}")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps({
        "range": {"min": args.cost_min, "max": args.cost_max, "step": args.cost_step},
        "first_zero_leak": first_zero_leak,
        "best_zero_leak": {"cost_safety": best_acc[0], "routing_acc": best_acc[1]},
        "sweep": results,
    }, indent=2))
    print(f"[fine-sweep] wrote {args.output}")


if __name__ == "__main__":
    main()
