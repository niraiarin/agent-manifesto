#!/usr/bin/env python3
"""
utility_decision.py — 期待効用最大化ベースの routing 決定.

Cost matrix (action × true_label):
                    true: cloud    true: local
  action: cloud       +1              -cost_cloud   (Local 可能を Cloud 流し、cost 無駄)
  action: local       -cost_safety   +1             (Cloud 必須を Local 流し、safety risk)

期待効用:
  U(cloud | x) = P(cloud|x) * 1 + P(local|x) * (-cost_cloud)
  U(local | x) = P(cloud|x) * (-cost_safety) + P(local|x) * 1

Local を選ぶ条件: U(local) > U(cloud)
  <=> P(local) / P(cloud) > (1 + cost_safety) / (1 + cost_cloud)

cost_safety >> cost_cloud の非対称状況で、argmax (cost_safety=cost_cloud=1 と等価) より
Local 選択を厳しくする = zero-leak 維持しつつ reject を減らす。
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from pathlib import Path


LABEL_TO_ID = {"local_confident": 0, "local_probable": 1, "cloud_required": 2, "hybrid": 3, "unknown": 4}
ID_TO_LABEL = {v: k for k, v in LABEL_TO_ID.items()}
LOCAL_CLASSES = {"local_confident", "local_probable"}
CLOUD_CLASSES = {"cloud_required", "hybrid", "unknown"}


def utility_decide(probs_row, cost_safety: float, cost_cloud: float) -> str:
    """Expected-utility-maximizing routing decision.

    Returns "local_confident"/"local_probable" (→ Local) or "cloud_required" (→ Cloud fallback).
    Keeps original top class for Local side (so we know which Local variant);
    maps all Cloud-side decisions to "cloud_required" for simplicity.
    """
    p_local = sum(probs_row[LABEL_TO_ID[c]] for c in LOCAL_CLASSES)
    p_cloud = sum(probs_row[LABEL_TO_ID[c]] for c in CLOUD_CLASSES)

    # Utilities
    u_cloud = p_cloud * 1.0 + p_local * (-cost_cloud)
    u_local = p_cloud * (-cost_safety) + p_local * 1.0

    if u_local > u_cloud:
        # Return whichever Local variant has higher prob
        if probs_row[LABEL_TO_ID["local_confident"]] > probs_row[LABEL_TO_ID["local_probable"]]:
            return "local_confident"
        return "local_probable"
    return "cloud_required"


def argmax_decide(probs_row) -> str:
    """Standard argmax (MAP) for comparison."""
    top_id = int(probs_row.argmax())
    return ID_TO_LABEL[top_id]


def evaluate(probs, y_true, decision_fn) -> dict:
    n = len(y_true)
    leak = over = correct = 0
    route_counts = Counter()

    for i in range(n):
        true_label = ID_TO_LABEL[int(y_true[i])]
        pred = decision_fn(probs[i])
        route_counts[pred] += 1

        # Effective routing category
        pred_is_local = pred in LOCAL_CLASSES
        true_is_local = true_label in LOCAL_CLASSES
        true_is_cloud = true_label in CLOUD_CLASSES

        if pred == true_label:
            correct += 1
        elif true_is_cloud and pred_is_local:
            leak += 1
        elif true_is_local and not pred_is_local:
            over += 1
        # else: within-cloud or within-local confusion — still routing-correct
        if pred_is_local == true_is_local:
            if pred != true_label:
                # same routing direction but different sub-label; count as routing-correct
                correct += 0  # already not counted above

    # Count all routing-correct (pred_is_local == true_is_local), not just exact match
    routing_correct = 0
    for i in range(n):
        true_label = ID_TO_LABEL[int(y_true[i])]
        pred = decision_fn(probs[i])
        if (pred in LOCAL_CLASSES) == (true_label in LOCAL_CLASSES):
            routing_correct += 1

    return {
        "n": n,
        "routing_accuracy": round(routing_correct / n, 4),
        "leak_rate": round(leak / n, 4),
        "over_cautious_rate": round(over / n, 4),
        "local_routed": sum(v for k, v in route_counts.items() if k in LOCAL_CLASSES),
        "cloud_routed": sum(v for k, v in route_counts.items() if k in CLOUD_CLASSES),
        "label_dist": dict(route_counts),
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--eval", type=Path, required=True)
    parser.add_argument("--real-prompts", type=Path, default=None)
    parser.add_argument("--model-dir", type=Path, required=True)
    parser.add_argument("--cost-safety", type=float, default=10.0)
    parser.add_argument("--cost-cloud", type=float, default=1.0)
    parser.add_argument("--sweep", action="store_true", help="sweep cost_safety to trace Pareto")
    parser.add_argument("--output", type=Path, default=Path("../analysis/utility-decision.json"))
    args = parser.parse_args()

    import joblib
    import numpy as np
    from sentence_transformers import SentenceTransformer

    meta = json.load(open(args.model_dir / "metadata.json"))
    clf = joblib.load(args.model_dir / "clf.joblib")
    encoder = SentenceTransformer(meta["encoder"])

    evaluation = [json.loads(l) for l in args.eval.read_text().splitlines() if l.strip()]
    X_ev = encoder.encode([f"query: {e['prompt']}" for e in evaluation], convert_to_numpy=True, batch_size=32, show_progress_bar=False)
    y_ev = np.array([LABEL_TO_ID[e["label"]] for e in evaluation])
    probs_ev = clf.predict_proba(X_ev)

    # Baseline (argmax)
    argmax_eval = evaluate(probs_ev, y_ev, argmax_decide)
    print(f"[decision] argmax (baseline):")
    print(f"  routing_acc={argmax_eval['routing_accuracy']:.4f}  leak={argmax_eval['leak_rate']:.4f}  over={argmax_eval['over_cautious_rate']:.4f}")
    print(f"  local={argmax_eval['local_routed']}  cloud={argmax_eval['cloud_routed']}")

    results = {"eval_argmax": argmax_eval}

    if args.sweep:
        print(f"\n[decision] cost_safety sweep (cost_cloud=1.0):")
        print(f"  {'cost_safety':>12} {'routing_acc':>12} {'leak_rate':>10} {'local':>7} {'cloud':>7}")
        sweep = []
        for cs in [1, 2, 5, 10, 20, 50]:
            decide = lambda r, cs=cs: utility_decide(r, cs, 1.0)
            res = evaluate(probs_ev, y_ev, decide)
            sweep.append({"cost_safety": cs, **res})
            print(f"  {cs:>12} {res['routing_accuracy']:>12.4f} {res['leak_rate']:>10.4f} {res['local_routed']:>7} {res['cloud_routed']:>7}")
        results["sweep"] = sweep

    # Point estimate at given cost_safety
    decide = lambda r: utility_decide(r, args.cost_safety, args.cost_cloud)
    utility_eval = evaluate(probs_ev, y_ev, decide)
    print(f"\n[decision] utility (cost_safety={args.cost_safety}, cost_cloud={args.cost_cloud}):")
    print(f"  routing_acc={utility_eval['routing_accuracy']:.4f}  leak={utility_eval['leak_rate']:.4f}  over={utility_eval['over_cautious_rate']:.4f}")
    print(f"  local={utility_eval['local_routed']}  cloud={utility_eval['cloud_routed']}")
    results["eval_utility"] = {"cost_safety": args.cost_safety, "cost_cloud": args.cost_cloud, **utility_eval}

    # Real corpus (unlabeled — only routing dist)
    if args.real_prompts:
        reals = [json.loads(l) for l in args.real_prompts.read_text().splitlines() if l.strip()]
        X_re = encoder.encode([f"query: {p['prompt']}" for p in reals], convert_to_numpy=True, batch_size=32, show_progress_bar=False)
        probs_re = clf.predict_proba(X_re)
        am_counts = Counter(argmax_decide(r) for r in probs_re)
        ut_counts = Counter(utility_decide(r, args.cost_safety, args.cost_cloud) for r in probs_re)
        am_local = sum(v for k, v in am_counts.items() if k in LOCAL_CLASSES)
        ut_local = sum(v for k, v in ut_counts.items() if k in LOCAL_CLASSES)
        print(f"\n[decision] real corpus (n={len(reals)}):")
        print(f"  argmax:  local {am_local} ({am_local/len(reals):.1%}) / cloud {len(reals)-am_local}")
        print(f"  utility: local {ut_local} ({ut_local/len(reals):.1%}) / cloud {len(reals)-ut_local}")
        results["real_corpus"] = {
            "n": len(reals),
            "argmax_local": am_local,
            "utility_local": ut_local,
            "argmax_dist": dict(am_counts),
            "utility_dist": dict(ut_counts),
        }

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(results, indent=2, ensure_ascii=False))
    print(f"\n[decision] wrote {args.output}")


if __name__ == "__main__":
    main()
