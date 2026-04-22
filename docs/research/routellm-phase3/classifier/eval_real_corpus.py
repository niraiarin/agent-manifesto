#!/usr/bin/env python3
"""
eval_real_corpus.py — Gap 2: 1173 real prompts を classifier に通して分布を測定.

期待する routing 分布に対し、実運用プロンプトの routing 判定分布を比較。
"""

from __future__ import annotations

import argparse
import json
import statistics
from collections import Counter
from pathlib import Path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--real-prompts", type=Path, required=True)
    parser.add_argument("--model-dir", type=Path, required=True)
    parser.add_argument("--output", type=Path, default=Path("../analysis/real-corpus-distribution.json"))
    args = parser.parse_args()

    import joblib
    import numpy as np
    from sentence_transformers import SentenceTransformer

    meta = json.load(open(args.model_dir / "metadata.json"))
    clf = joblib.load(args.model_dir / "clf.joblib")
    encoder = SentenceTransformer(meta["encoder"])
    id_to_label = {v: k for k, v in meta["label_map"].items()}

    prompts = [json.loads(l) for l in args.real_prompts.read_text().splitlines() if l.strip()]
    print(f"[real] {len(prompts)} prompts loaded")

    # Encode in batches
    texts = [f"query: {p['prompt']}" for p in prompts]
    X = encoder.encode(texts, convert_to_numpy=True, batch_size=32, show_progress_bar=False)
    probs = clf.predict_proba(X)
    preds = probs.argmax(axis=1)
    confs = probs.max(axis=1)

    # Mirror router.js safety nets
    FORCE_CLOUD_PREFIXES = ("/research", "/verify", "/formal-derivation", "/evolve",
                            "/ground-axiom", "/spec-driven-workflow", "/instantiate-model",
                            "/generate-plugin", "/brownfield", "/design-implementation-plan")

    # Analyze
    label_dist = Counter()
    route_dist = Counter()  # post-safety-net
    high_conf_count = 0
    low_conf_count = 0
    force_cloud_count = 0

    results_per_prompt = []
    for i, p in enumerate(prompts):
        lbl = id_to_label[int(preds[i])]
        c = float(confs[i])
        label_dist[lbl] += 1

        # Apply safety nets
        post_label = lbl
        via = "classifier"
        trimmed = p["prompt"].lstrip()
        for pref in FORCE_CLOUD_PREFIXES:
            if trimmed.startswith(pref):
                post_label = "cloud_required"
                via = f"force_cloud[{pref}]"
                force_cloud_count += 1
                break

        route_target = post_label
        route_dist[route_target] += 1

        if c >= 0.80:
            high_conf_count += 1
        elif c < 0.30:
            low_conf_count += 1

        results_per_prompt.append({
            "session_id": p["session_id"],
            "prompt_preview": p["prompt"][:80],
            "prompt_len": p["prompt_len"],
            "label": lbl,
            "confidence": round(c, 3),
            "post_safety": post_label,
            "via": via,
        })

    # Routing split
    LOCAL = {"local_confident", "local_probable"}
    CLOUD = {"cloud_required", "hybrid", "unknown"}
    local_count = sum(v for k, v in route_dist.items() if k in LOCAL)
    cloud_count = sum(v for k, v in route_dist.items() if k in CLOUD)

    report = {
        "total": len(prompts),
        "prompt_length_stats": {
            "mean": round(statistics.mean([p["prompt_len"] for p in prompts]), 1),
            "median": sorted(p["prompt_len"] for p in prompts)[len(prompts)//2],
            "p95": sorted(p["prompt_len"] for p in prompts)[int(len(prompts)*0.95)],
            "max": max(p["prompt_len"] for p in prompts),
        },
        "confidence_stats": {
            "mean": round(float(confs.mean()), 3),
            "median": round(float(np.median(confs)), 3),
            "high_conf_ge_80": high_conf_count,
            "low_conf_lt_30": low_conf_count,
        },
        "label_distribution_classifier_only": dict(label_dist),
        "label_distribution_post_safety": dict(route_dist),
        "force_cloud_triggers": force_cloud_count,
        "routing_split": {
            "local": local_count,
            "cloud": cloud_count,
            "local_pct": round(local_count / len(prompts) * 100, 1),
            "cloud_pct": round(cloud_count / len(prompts) * 100, 1),
        },
    }

    print("\n=== Real Corpus Distribution ===")
    print(f"Total prompts: {report['total']}")
    print(f"Prompt length: mean={report['prompt_length_stats']['mean']} median={report['prompt_length_stats']['median']} p95={report['prompt_length_stats']['p95']} max={report['prompt_length_stats']['max']}")
    print(f"Confidence: mean={report['confidence_stats']['mean']} median={report['confidence_stats']['median']}")
    print(f"  high_conf (>=0.80): {report['confidence_stats']['high_conf_ge_80']}")
    print(f"  low_conf (<0.30): {report['confidence_stats']['low_conf_lt_30']}")
    print(f"\nLabel distribution (classifier only):")
    for k, v in sorted(label_dist.items(), key=lambda x: -x[1]):
        pct = v / len(prompts) * 100
        print(f"  {k:<20} {v:>5} ({pct:.1f}%)")
    print(f"\nForce-cloud prefix triggers: {force_cloud_count}")
    print(f"\nRouting split (post-safety):")
    print(f"  Local: {local_count} ({report['routing_split']['local_pct']}%)")
    print(f"  Cloud: {cloud_count} ({report['routing_split']['cloud_pct']}%)")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2, ensure_ascii=False))

    # Also export per-prompt results (for manual review)
    per_prompt_path = args.output.parent / "real-corpus-per-prompt.jsonl"
    per_prompt_path.write_text("\n".join(json.dumps(r, ensure_ascii=False) for r in results_per_prompt) + "\n")
    print(f"\n[real] wrote {args.output} + {per_prompt_path}")


if __name__ == "__main__":
    main()
