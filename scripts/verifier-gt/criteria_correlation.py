#!/usr/bin/env python3
"""Criteria correlation analysis (#591).

For a set of criteria, score the same (problem, response_A, response_B) pairs
on each criterion independently. Then compute pairwise Pearson correlations
across examples.

Gate:
- PASS: all pairs have |r| < 0.8 (criteria independent)
- CONDITIONAL: some pair |r| >= 0.8 (merging candidate)
- FAIL: >= 60% pairs have |r| >= 0.8 (criteria not decomposing)
"""

from __future__ import annotations

import json
import math
import sys
import time
from itertools import combinations
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent.parent
sys.path.insert(0, str(REPO_ROOT / "scripts"))
sys.path.insert(0, str(SCRIPT_DIR))

import verifier_local  # noqa: E402
from benchmark_loaders import load  # noqa: E402
from converter import REWARDBENCH_CRITERIA_DECOMPOSED, convert_pairwise  # noqa: E402


def pearson(xs, ys):
    n = len(xs)
    if n < 2:
        return 0.0
    mx = sum(xs) / n
    my = sum(ys) / n
    num = sum((x - mx) * (y - my) for x, y in zip(xs, ys))
    dx = math.sqrt(sum((x - mx) ** 2 for x in xs))
    dy = math.sqrt(sum((y - my) ** 2 for y in ys))
    if dx == 0 or dy == 0:
        return 0.0
    return num / (dx * dy)


def main():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--dataset", default="rewardbench")
    parser.add_argument("--limit", type=int, default=60)
    parser.add_argument("--stratified", action="store_true")
    parser.add_argument("--output", type=str,
                        default="research/verifier-gt/criteria_correlation.json")
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args()

    if not verifier_local.ensure_server():
        raise RuntimeError("llama-server unavailable")

    criteria = REWARDBENCH_CRITERIA_DECOMPOSED
    crit_ids = [c["id"] for c in criteria]
    # per-criterion list of (margin = score_a - score_b) across examples
    per_crit_margins = {cid: [] for cid in crit_ids}

    loader_kwargs = {"limit": args.limit}
    if args.dataset in ("rewardbench", "judgebench", "ultrafeedback"):
        loader_kwargs["stratified"] = args.stratified

    start = time.time()
    n_done = 0
    for ex in load(args.dataset, **loader_kwargs):
        inp = convert_pairwise(ex)
        for crit in criteria:
            r = verifier_local.score_pair(inp.problem, inp.proposal_a,
                                          inp.proposal_b, crit)
            per_crit_margins[crit["id"]].append(r["score_a"] - r["score_b"])
        n_done += 1
        if args.verbose and n_done % 10 == 0:
            elapsed = time.time() - start
            rate = n_done / elapsed if elapsed > 0 else 0
            print(f"  [{n_done}] rate={rate:.2f} ex/s", flush=True)

    # Pairwise correlations
    corr = {}
    for a, b in combinations(crit_ids, 2):
        r = pearson(per_crit_margins[a], per_crit_margins[b])
        corr[f"{a}__{b}"] = round(r, 4)

    # Gate
    high_pairs = [k for k, v in corr.items() if abs(v) >= 0.8]
    total_pairs = len(corr)
    frac_high = len(high_pairs) / total_pairs if total_pairs else 0
    if not high_pairs:
        gate = "PASS"
    elif frac_high < 0.6:
        gate = "CONDITIONAL"
    else:
        gate = "FAIL"

    summary = {
        "dataset": args.dataset,
        "n_examples": n_done,
        "criteria": crit_ids,
        "pairwise_correlations": corr,
        "high_correlation_pairs (|r|>=0.8)": high_pairs,
        "gate": gate,
        "elapsed_seconds": round(time.time() - start, 2),
    }

    out_path = Path(args.output)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with open(out_path, "w") as f:
        json.dump({"summary": summary, "per_crit_margins": per_crit_margins},
                  f, indent=2)

    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
