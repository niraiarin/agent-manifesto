#!/usr/bin/env python3
"""
SI3: Evaluation harness — feed converted pairs into verifier_local.py,
collect accuracy against ground truth.
"""

from __future__ import annotations

import json
import sys
import time
from collections import defaultdict
from pathlib import Path
from typing import Optional

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent.parent
sys.path.insert(0, str(REPO_ROOT / "scripts"))
sys.path.insert(0, str(SCRIPT_DIR))

import verifier_local  # noqa: E402
from benchmark_loaders import load, PairwiseExample  # noqa: E402
from converter import (  # noqa: E402
    convert_pairwise,
    VerifierInput,
    REWARDBENCH_CRITERION,
    REWARDBENCH_CRITERIA_DECOMPOSED,
)


def _checkpoint(output_file: Path, summary: dict, per_example: list):
    """Save intermediate progress (resumable)."""
    output_file.parent.mkdir(parents=True, exist_ok=True)
    with open(output_file, "w") as f:
        json.dump({"summary": summary, "per_example": per_example}, f, indent=2)


def _query_model_name() -> str:
    """Query llama-server for the currently loaded model name."""
    try:
        import urllib.request
        with urllib.request.urlopen("http://localhost:8090/v1/models", timeout=3) as resp:
            data = json.loads(resp.read())
        models = data.get("models") or data.get("data") or []
        if models:
            return models[0].get("name") or models[0].get("id") or "unknown"
    except Exception:
        pass
    return "unknown"


def evaluate(
    dataset: str,
    limit: Optional[int] = None,
    k_rounds: int = 3,
    bidirectional: bool = True,
    criteria: Optional[list] = None,
    verbose: bool = False,
    output_file: Optional[Path] = None,
    stratified: bool = False,
    checkpoint_every: int = 100,
    resume: bool = True,
    model_name: Optional[str] = None,
) -> dict:
    """Run pairwise evaluation over a benchmark.

    Supports checkpoint/resume: if output_file exists and resume=True,
    already-processed example_ids are skipped.

    Returns aggregated results with accuracy.
    """
    if not verifier_local.ensure_server():
        raise RuntimeError("llama-server unavailable")

    # Auto-detect model name if not provided
    if model_name is None:
        model_name = _query_model_name()

    overall_correct = 0
    overall_total = 0
    by_category = defaultdict(lambda: {"correct": 0, "total": 0})
    per_example = []
    processed_ids = set()

    # Resume from checkpoint if present
    if resume and output_file and output_file.exists():
        try:
            with open(output_file) as f:
                existing = json.load(f)
            per_example = existing.get("per_example", [])
            for e in per_example:
                processed_ids.add(e["example_id"])
                overall_total += 1
                if e.get("correct"):
                    overall_correct += 1
                cat = e.get("category", "uncategorized")
                by_category[cat]["total"] += 1
                if e.get("correct"):
                    by_category[cat]["correct"] += 1
            if verbose and processed_ids:
                print(f"Resuming from checkpoint: {len(processed_ids)} already processed "
                      f"(acc={overall_correct/max(overall_total,1):.3f})", flush=True)
        except Exception as e:
            print(f"Warning: could not load checkpoint: {e}", file=sys.stderr)

    start = time.time()

    loader_kwargs = {"limit": limit}
    if dataset in ("rewardbench", "judgebench", "commit-faithfulness", "lean-proof",
                   "ultrafeedback", "chatbot-arena", "mt-bench",
                   "humaneval", "gsm8k", "fever"):
        loader_kwargs["stratified"] = stratified

    for i, ex in enumerate(load(dataset, **loader_kwargs)):
        if ex.example_id in processed_ids:
            continue
        inp = convert_pairwise(ex, criteria=criteria)

        result = verifier_local.pairwise_compare(
            problem=inp.problem,
            trace_a=inp.proposal_a,
            trace_b=inp.proposal_b,
            criteria=inp.criteria,
            k_rounds=k_rounds,
            bidirectional=bidirectional,
        )

        predicted_winner = result["winner"]
        correct = predicted_winner == inp.ground_truth_winner

        overall_total += 1
        if correct:
            overall_correct += 1

        cat = ex.category or "uncategorized"
        by_category[cat]["total"] += 1
        if correct:
            by_category[cat]["correct"] += 1

        per_example.append({
            "example_id": ex.example_id,
            "category": cat,
            "gt_winner": inp.ground_truth_winner,
            "predicted_winner": predicted_winner,
            "margin": result["margin"],
            "correct": correct,
        })

        if verbose and (overall_total) % 10 == 0:
            elapsed = time.time() - start
            # processed_this_run excludes resumed examples for accurate rate
            processed_this_run = overall_total - len(processed_ids)
            rate = processed_this_run / elapsed if elapsed > 0 else 0
            print(f"  [{overall_total}] acc={overall_correct/overall_total:.3f} "
                  f"({overall_correct}/{overall_total}) "
                  f"rate={rate:.2f}/s",
                  flush=True)

        # Checkpoint periodically
        if output_file and overall_total % checkpoint_every == 0:
            ckpt_summary = {
                "dataset": dataset, "model_name": model_name,
                "limit": limit, "k_rounds": k_rounds,
                "bidirectional": bidirectional, "total": overall_total,
                "correct": overall_correct,
                "accuracy": round(overall_correct / overall_total, 6),
                "by_category": {c: {"correct": v["correct"], "total": v["total"],
                                    "accuracy": round(v["correct"]/v["total"], 4) if v["total"] else 0}
                                for c, v in by_category.items()},
                "elapsed_seconds": round(time.time() - start, 2),
                "checkpoint": True,
            }
            _checkpoint(output_file, ckpt_summary, per_example)

    overall_acc = overall_correct / overall_total if overall_total else 0
    category_acc = {
        cat: {
            "correct": v["correct"],
            "total": v["total"],
            "accuracy": round(v["correct"] / v["total"], 4) if v["total"] else 0,
        }
        for cat, v in by_category.items()
    }

    summary = {
        "dataset": dataset,
        "model_name": model_name,
        "limit": limit,
        "k_rounds": k_rounds,
        "bidirectional": bidirectional,
        "total": overall_total,
        "correct": overall_correct,
        "accuracy": round(overall_acc, 6),
        "by_category": category_acc,
        "elapsed_seconds": round(time.time() - start, 2),
    }

    output = {
        "summary": summary,
        "per_example": per_example,
    }

    if output_file:
        output_file.parent.mkdir(parents=True, exist_ok=True)
        with open(output_file, "w") as f:
            json.dump(output, f, indent=2)
        print(f"Saved: {output_file}")

    return output


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("dataset", help="Benchmark name (rewardbench, judgebench)")
    parser.add_argument("--limit", type=int, default=None, help="Number of examples")
    parser.add_argument("--k-rounds", type=int, default=3)
    parser.add_argument("--no-bidirectional", action="store_true")
    parser.add_argument("--output", type=str, default=None, help="Output JSON path")
    parser.add_argument("--verbose", action="store_true")
    parser.add_argument("--stratified", action="store_true", help="Stratified sampling across subsets")
    parser.add_argument("--decomposed", action="store_true", help="Use 3 decomposed criteria instead of 1")
    parser.add_argument("--model-name", type=str, default=None, help="Model identifier (auto-detected if omitted)")
    args = parser.parse_args()

    criteria = None
    if args.decomposed and args.dataset == "rewardbench":
        criteria = REWARDBENCH_CRITERIA_DECOMPOSED

    out = None
    if args.output:
        out = Path(args.output)

    result = evaluate(
        dataset=args.dataset,
        limit=args.limit,
        k_rounds=args.k_rounds,
        bidirectional=not args.no_bidirectional,
        verbose=args.verbose,
        output_file=out,
        stratified=args.stratified,
        criteria=criteria,
        model_name=args.model_name,
    )

    print("\n" + "=" * 60)
    print("SUMMARY")
    print("=" * 60)
    print(json.dumps(result["summary"], indent=2))
