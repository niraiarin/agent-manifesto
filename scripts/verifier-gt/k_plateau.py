#!/usr/bin/env python3
"""K-round plateau verification (#614).

Runs N=128 rounds of score_pair forward on ~3 near-quality pairs.
Subsample-analyzes SD(margin) for K in {1,2,4,8,16,32,64}.

Gate:
- PASS: SD(K=16) / SD(K=32) ratio in range [1.0, 1.1] (plateau reached)
- CONDITIONAL: 1.1-1.5 (decay continuing)
- FAIL: > 1.5 (no plateau)
"""

from __future__ import annotations

import json
import math
import random
import sys
import time
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent.parent
sys.path.insert(0, str(REPO_ROOT / "scripts"))
sys.path.insert(0, str(SCRIPT_DIR))

import verifier_local  # noqa: E402
from benchmark_loaders import load  # noqa: E402
from converter import convert_pairwise  # noqa: E402


def _std(xs):
    if len(xs) < 2:
        return 0.0
    m = sum(xs) / len(xs)
    return (sum((x - m) ** 2 for x in xs) / (len(xs) - 1)) ** 0.5


def collect_rounds(problem, trace_a, trace_b, criterion, n_rounds):
    """Call score_pair N times forward, return list of {score_a, score_b, margin}."""
    records = []
    for i in range(n_rounds):
        r = verifier_local.score_pair(problem, trace_a, trace_b, criterion)
        records.append({
            "round": i,
            "score_a": r["score_a"],
            "score_b": r["score_b"],
            "margin": r["score_a"] - r["score_b"],
        })
    return records


def subsample_sd(margins, k, n_subsamples=64, seed=42):
    """Compute SD of mean(K subsampled margins) over n_subsamples draws.

    If k >= len(margins), only compute the single mean (SD=0 or n/a).
    """
    if k > len(margins):
        return None, 0
    rng = random.Random(seed)
    sample_means = []
    # deterministic: draw non-overlapping chunks when possible
    n_chunks = len(margins) // k
    if n_chunks >= 2:
        # non-overlapping chunks
        for c in range(n_chunks):
            chunk = margins[c * k : (c + 1) * k]
            sample_means.append(sum(chunk) / len(chunk))
    else:
        # bootstrap when k > len/2
        for _ in range(n_subsamples):
            draw = rng.sample(margins, k)
            sample_means.append(sum(draw) / len(draw))
    return _std(sample_means), len(sample_means)


def analyze_pair(records, ks=(1, 2, 4, 8, 16, 32, 64)):
    """Return dict {K: {sd: float, n_sub: int, mean_margin: float}}."""
    margins = [r["margin"] for r in records]
    result = {}
    for k in ks:
        sd, n_sub = subsample_sd(margins, k)
        result[k] = {
            "sd": round(sd, 6) if sd is not None else None,
            "n_sub": n_sub,
        }
    result["mean_margin"] = round(sum(margins) / len(margins), 6)
    result["n_total"] = len(margins)
    return result


def main():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--dataset", default="ultrafeedback")
    parser.add_argument("--n-rounds", type=int, default=128)
    parser.add_argument("--n-pairs", type=int, default=3)
    parser.add_argument("--output", type=str,
                        default="research/verifier-gt/k_plateau_n128.json")
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args()

    if not verifier_local.ensure_server():
        print("llama-server unreachable", file=sys.stderr)
        sys.exit(1)

    # pick first N pairs from dataset
    all_pairs = []
    for ex in load(args.dataset, limit=args.n_pairs):
        inp = convert_pairwise(ex)
        all_pairs.append((ex, inp))
        if len(all_pairs) >= args.n_pairs:
            break

    start = time.time()
    pair_results = []
    for pi, (ex, inp) in enumerate(all_pairs):
        if args.verbose:
            print(f"[{pi+1}/{len(all_pairs)}] example_id={ex.example_id} "
                  f"prompt_len={len(inp.problem)} a_len={len(inp.proposal_a)} b_len={len(inp.proposal_b)}",
                  flush=True)
        records = collect_rounds(inp.problem, inp.proposal_a, inp.proposal_b,
                                 inp.criteria[0], args.n_rounds)
        analysis = analyze_pair(records)
        pair_results.append({
            "example_id": ex.example_id,
            "category": ex.category,
            "analysis": analysis,
            "records": records,
        })
        if args.verbose:
            print(f"  mean_margin={analysis['mean_margin']:.3f}",
                  "  ".join(f"SD(K={k})={analysis[k]['sd']:.3f}" for k in (1,2,4,8,16,32,64)),
                  flush=True)

    elapsed = time.time() - start

    # Aggregate across pairs: mean SD per K
    ks = (1, 2, 4, 8, 16, 32, 64)
    agg = {}
    for k in ks:
        sds = [p["analysis"][k]["sd"] for p in pair_results if p["analysis"][k]["sd"] is not None]
        agg[k] = {
            "mean_sd": round(sum(sds) / len(sds), 6) if sds else None,
            "n_pairs": len(sds),
        }

    # Plateau gate
    sd16 = agg[16]["mean_sd"]
    sd32 = agg[32]["mean_sd"]
    ratio_16_32 = sd16 / sd32 if sd32 else None
    if ratio_16_32 is not None:
        if 1.0 <= ratio_16_32 <= 1.1:
            gate = "PASS"
        elif ratio_16_32 <= 1.5:
            gate = "CONDITIONAL"
        else:
            gate = "FAIL"
    else:
        gate = "UNKNOWN"

    summary = {
        "dataset": args.dataset,
        "n_rounds": args.n_rounds,
        "n_pairs": len(pair_results),
        "aggregate": agg,
        "plateau_ratio_16_32": round(ratio_16_32, 3) if ratio_16_32 else None,
        "gate": gate,
        "elapsed_seconds": round(elapsed, 2),
    }

    out_path = Path(args.output)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with open(out_path, "w") as f:
        json.dump({"summary": summary, "pairs": pair_results}, f, indent=2)

    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
