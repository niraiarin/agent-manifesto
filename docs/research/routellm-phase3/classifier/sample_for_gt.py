#!/usr/bin/env python3
"""
sample_for_gt.py — #653 Phase 1: real corpus から 100 件を層化サンプリング.

戦略:
- 予測 label 分布を維持 (local_confident 5%, local_probable 20%, cloud_required 23%, hybrid 38%, unknown 14%)
- 各 confidence bin から均等に (0.2-0.4 from each of {0.3-0.5, 0.5-0.7, 0.7-0.9, 0.9-1.0})
- 長さ分布も意識 (short / medium / long 各 30% 程度)

出力:
  real-gt-candidates.jsonl: 100 件、人手ラベル用 (label フィールド空)
  annotate.html: 簡易アノテーションツール (CLI / ブラウザ両対応)
"""

from __future__ import annotations

import argparse
import json
import random
from pathlib import Path
from collections import defaultdict

import joblib
import numpy as np


LABEL_TO_ID = {"local_confident": 0, "local_probable": 1, "cloud_required": 2, "hybrid": 3, "unknown": 4}
ID_TO_LABEL = {v: k for k, v in LABEL_TO_ID.items()}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--real-prompts", type=Path, required=True)
    parser.add_argument("--model-dir", type=Path, required=True)
    parser.add_argument("--output", type=Path, default=Path("../label-data/real-gt-candidates.jsonl"))
    parser.add_argument("--n", type=int, default=100)
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args()

    random.seed(args.seed)

    from sentence_transformers import SentenceTransformer
    meta = json.load(open(args.model_dir / "metadata.json"))
    clf = joblib.load(args.model_dir / "clf.joblib")
    enc = SentenceTransformer(meta["encoder"])

    reals = [json.loads(l) for l in args.real_prompts.read_text().splitlines() if l.strip()]
    print(f"[sample] {len(reals)} real prompts loaded")

    X = enc.encode([f"query: {p['prompt']}" for p in reals], convert_to_numpy=True, batch_size=32, show_progress_bar=False)
    probs = clf.predict_proba(X)
    preds = probs.argmax(axis=1)
    confs = probs.max(axis=1)

    # Stratification keys
    def conf_bin(c):
        if c < 0.30: return "low"
        if c < 0.50: return "mid"
        if c < 0.70: return "high"
        if c < 0.90: return "vhigh"
        return "peak"

    def length_bin(L):
        if L < 100: return "short"
        if L < 500: return "medium"
        if L < 2000: return "long"
        return "xlong"

    # Target distribution: 10 conf bins × 5 length bins × 5 labels
    # Simplified: aim for proportional label + balanced conf
    # Target per label (from v2 real corpus dist):
    target_label_pct = {
        "local_confident": 0.05,
        "local_probable": 0.20,
        "cloud_required": 0.23,
        "hybrid": 0.38,
        "unknown": 0.14,
    }
    target_label_count = {k: max(1, int(args.n * v)) for k, v in target_label_pct.items()}
    total = sum(target_label_count.values())
    if total < args.n:
        target_label_count["hybrid"] += (args.n - total)

    # Group candidates by (predicted label, conf bin)
    pool: dict[tuple, list[int]] = defaultdict(list)
    for i, p in enumerate(reals):
        label = ID_TO_LABEL[int(preds[i])]
        cb = conf_bin(float(confs[i]))
        pool[(label, cb)].append(i)

    # Sample per (label, bin) proportionally
    sampled_indices = []
    for label, count in target_label_count.items():
        # Get bins for this label
        bins = {cb: idxs for (lbl, cb), idxs in pool.items() if lbl == label}
        if not bins:
            continue
        # Distribute count across bins as uniformly as possible
        per_bin = max(1, count // max(1, len(bins)))
        taken = 0
        for cb, idxs in sorted(bins.items()):
            take = min(per_bin, len(idxs), count - taken)
            chosen = random.sample(idxs, take)
            sampled_indices.extend(chosen)
            taken += take
            if taken >= count:
                break
        # Fill remaining from any bin for this label
        remaining = count - taken
        if remaining > 0:
            all_idxs_for_label = [i for (lbl, _), idxs in pool.items() if lbl == label for i in idxs if i not in sampled_indices]
            extras = random.sample(all_idxs_for_label, min(remaining, len(all_idxs_for_label)))
            sampled_indices.extend(extras)

    # Dedup
    sampled_indices = list(dict.fromkeys(sampled_indices))[:args.n]

    # Write output
    entries = []
    for idx in sampled_indices:
        p = reals[idx]
        entries.append({
            "id": f"gt-{len(entries):03d}",
            "session_id": p.get("session_id"),
            "prompt": p["prompt"],
            "prompt_len": p.get("prompt_len", len(p["prompt"])),
            "predicted_label": ID_TO_LABEL[int(preds[idx])],
            "predicted_confidence": round(float(confs[idx]), 3),
            "predicted_probs": {ID_TO_LABEL[i]: round(float(probs[idx][i]), 3) for i in range(5)},
            "conf_bin": conf_bin(float(confs[idx])),
            "length_bin": length_bin(len(p["prompt"])),
            "gt_label": None,  # ← human annotator fills this in
            "annotator_notes": None,
        })

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text("\n".join(json.dumps(e, ensure_ascii=False) for e in entries) + "\n")

    # Stats
    from collections import Counter
    dist = Counter(e["predicted_label"] for e in entries)
    conf_dist = Counter(e["conf_bin"] for e in entries)
    len_dist = Counter(e["length_bin"] for e in entries)

    print(f"[sample] wrote {len(entries)} candidates → {args.output}")
    print(f"[sample] predicted label dist: {dict(dist)}")
    print(f"[sample] conf bin dist: {dict(conf_dist)}")
    print(f"[sample] length bin dist: {dict(len_dist)}")


if __name__ == "__main__":
    main()
