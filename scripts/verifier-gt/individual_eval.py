#!/usr/bin/env python3
"""Individual (absolute) scoring variant for comparison with pairwise mode (#590).

Scores each response in isolation (no other response in context), then compares
the two individual scores to determine winner. Contrasts with pairwise mode
where both responses share context during scoring.
"""

from __future__ import annotations

import json
import sys
import time
from pathlib import Path
from typing import Optional

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent.parent
sys.path.insert(0, str(REPO_ROOT / "scripts"))
sys.path.insert(0, str(SCRIPT_DIR))

import verifier_local  # noqa: E402
from benchmark_loaders import load  # noqa: E402
from converter import convert_pairwise  # noqa: E402


def create_individual_prompt(problem: str, response: str, criterion: dict) -> str:
    """Paper 'Judge' mode: score one response alone."""
    scale_desc = (
        "Rate on a 20-point scale using letters A through T:\n"
        "  A = clearly excellent (best)\n"
        "  E-G = above average\n"
        "  H-J = uncertain, leans toward success\n"
        "  K-M = uncertain, leans toward failure\n"
        "  N-P = below average\n"
        "  T = clearly failed (worst)"
    )
    return (
        f"<|im_start|>user\n"
        f"You are an expert evaluator. Evaluate the following response "
        f"on ONE criterion: **{criterion['name']}**.\n\n"
        f"**Context:**\n{problem}\n\n"
        f"**Response:**\n{response}\n\n"
        f"**Criterion — {criterion['name']}:**\n"
        f"{criterion['description']}\n\n"
        f"**Rating Scale:**\n{scale_desc}\n\n"
        f"Output your final score:\n"
        f"<score>LETTER_A_TO_T</score>\n"
        f"<|im_end|>\n"
        f"<|im_start|>assistant\n"
        f"<think>\n\n</think>\n<score>"
    )


def score_individual(problem: str, response: str, criterion: dict) -> float:
    prompt = create_individual_prompt(problem, response, criterion)
    score, _ = verifier_local.extract_score_direct(prompt)
    return score


def individual_compare(problem: str, trace_a: str, trace_b: str,
                       criteria: list, k_rounds: int = 3) -> dict:
    """K-round individual scoring. Winner = higher mean score. Tie if equal."""
    a_rounds = []
    b_rounds = []
    for _ in range(k_rounds):
        for crit in criteria:
            a_rounds.append(score_individual(problem, trace_a, crit))
            b_rounds.append(score_individual(problem, trace_b, crit))
    mean_a = sum(a_rounds) / len(a_rounds)
    mean_b = sum(b_rounds) / len(b_rounds)
    if abs(mean_a - mean_b) < 1e-9:
        winner = "TIE"
    elif mean_a > mean_b:
        winner = "A"
    else:
        winner = "B"
    return {
        "winner": winner,
        "mean_a": round(mean_a, 6),
        "mean_b": round(mean_b, 6),
        "margin": round(mean_a - mean_b, 6),
    }


def main():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--dataset", default="rewardbench")
    parser.add_argument("--limit", type=int, default=100)
    parser.add_argument("--k-rounds", type=int, default=3)
    parser.add_argument("--stratified", action="store_true")
    parser.add_argument("--output", type=str,
                        default="research/verifier-gt/individual_rewardbench_n100_k3.json")
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args()

    if not verifier_local.ensure_server():
        raise RuntimeError("llama-server unavailable")

    results = []
    overall_correct = 0
    overall_tie = 0
    overall_total = 0
    start = time.time()

    loader_kwargs = {"limit": args.limit}
    if args.dataset in ("rewardbench", "judgebench", "ultrafeedback"):
        loader_kwargs["stratified"] = args.stratified

    for i, ex in enumerate(load(args.dataset, **loader_kwargs)):
        inp = convert_pairwise(ex)
        r = individual_compare(inp.problem, inp.proposal_a, inp.proposal_b,
                               inp.criteria, k_rounds=args.k_rounds)
        correct = r["winner"] == inp.ground_truth_winner
        tie = r["winner"] == "TIE"
        overall_total += 1
        if correct:
            overall_correct += 1
        if tie:
            overall_tie += 1
        results.append({
            "example_id": ex.example_id,
            "category": ex.category,
            "gt_winner": inp.ground_truth_winner,
            "winner": r["winner"],
            "margin": r["margin"],
            "correct": correct,
            "tie": tie,
        })
        if args.verbose and overall_total % 10 == 0:
            elapsed = time.time() - start
            rate = overall_total / elapsed if elapsed > 0 else 0
            acc = overall_correct / overall_total
            tie_rate = overall_tie / overall_total
            print(f"  [{overall_total}] acc={acc:.3f} tie={tie_rate:.3f} "
                  f"rate={rate:.2f}/s", flush=True)

    elapsed = time.time() - start
    summary = {
        "dataset": args.dataset,
        "mode": "individual",
        "limit": args.limit,
        "k_rounds": args.k_rounds,
        "total": overall_total,
        "correct": overall_correct,
        "tie_count": overall_tie,
        "accuracy": round(overall_correct / overall_total, 6) if overall_total else 0,
        "tie_rate": round(overall_tie / overall_total, 6) if overall_total else 0,
        "elapsed_seconds": round(elapsed, 2),
    }

    out_path = Path(args.output)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with open(out_path, "w") as f:
        json.dump({"summary": summary, "per_example": results}, f, indent=2)

    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
