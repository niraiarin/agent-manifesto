#!/usr/bin/env python3
"""
verifier-refinement.py — /paperize Phase 4 Refinement halt-rule evaluator.

Wraps scripts/verifier_local.pairwise_compare() with the AgentReview halt rule:
  - winner = B              → halt (keep A, B rejected)
  - winner = A, margin <= 0 → halt (no net improvement)
  - winner = A, margin > 0  → accept B

Traces: [S2 §2.5] PaperOrchestra AgentReview + PR #637 logprob pairwise.

Stateless: one A/B comparison per invocation. Iteration / max_iterations
is owned by the SKILL.md orchestrator.

Usage:
  scripts/verifier-refinement.py \\
    --paper-a path/to/paper-v1.tex \\
    --paper-b path/to/paper-v2.tex \\
    [--criteria factual_grounding,citation_integrity,narrative_coherence] \\
    [--k-rounds 3] [--halt-threshold 0.0] [--unidirectional]

Output: JSON to stdout with {winner, margin, criteria, halt, halt_reason, ...}
Exit code: 0 always (halt decision is in JSON, not exit code).
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

import verifier_local  # noqa: E402


DEFAULT_CRITERIA = [
    {
        "id": "factual_grounding",
        "name": "Factual Grounding",
        "description": (
            "Numeric claims, experimental results, and assertions in the paper "
            "are supported by evidence present in manifest.json or evidence/. "
            "Unsupported claims must carry [UNVERIFIED] tag."
        ),
    },
    {
        "id": "citation_integrity",
        "name": "Citation Integrity",
        "description": (
            "Internal citations to PRs / issues / commits include an 8-char SHA "
            "or issue number. External citations are pre-declared in paperize.yaml."
        ),
    },
    {
        "id": "narrative_coherence",
        "name": "Narrative Coherence",
        "description": (
            "Section ordering follows the outline, logical flow is preserved, "
            "and the conclusion is entailed by the body."
        ),
    },
]


PROBLEM_PROMPT = (
    "Two revisions of an internal research paper (paper.tex content) are "
    "compared against three axes. Prefer the version with stronger factual "
    "grounding, higher citation integrity, and clearer narrative. Pure style "
    "or wording preferences are not differentiators."
)


def run(
    paper_a_path: Path,
    paper_b_path: Path,
    criteria: list[dict],
    k_rounds: int,
    bidirectional: bool,
    halt_threshold: float,
) -> dict:
    trace_a = paper_a_path.read_text()
    trace_b = paper_b_path.read_text()

    if not verifier_local.ensure_server():
        raise RuntimeError(
            "llama-server unreachable at http://localhost:8090. "
            "Start it before running /paperize refinement."
        )

    result = verifier_local.pairwise_compare(
        problem=PROBLEM_PROMPT,
        trace_a=trace_a,
        trace_b=trace_b,
        criteria=criteria,
        k_rounds=k_rounds,
        bidirectional=bidirectional,
    )

    winner = result["winner"]
    margin = result.get("margin", result["total_a"] - result["total_b"])

    if winner == "B":
        halt = True
        halt_reason = "winner_is_B"
    elif margin <= halt_threshold:
        halt = True
        halt_reason = f"margin_below_threshold (margin={margin:.4f} <= {halt_threshold})"
    else:
        halt = False
        halt_reason = None

    return {
        "paper_a": str(paper_a_path),
        "paper_b": str(paper_b_path),
        "winner": winner,
        "margin": round(float(margin), 6),
        "total_a": round(float(result["total_a"]), 6),
        "total_b": round(float(result["total_b"]), 6),
        "criteria": [
            {
                "id": c["criterion"],
                "winner": c["winner"],
                "mean_a": c["mean_a"],
                "mean_b": c["mean_b"],
            }
            for c in result["criteria_results"]
        ],
        "k_rounds": result.get("k_rounds", k_rounds),
        "bidirectional": result.get("bidirectional", bidirectional),
        "halt": halt,
        "halt_reason": halt_reason,
        "halt_threshold": halt_threshold,
    }


def _parse_criteria(spec: str | None) -> list[dict]:
    if not spec:
        return DEFAULT_CRITERIA
    wanted = [s.strip() for s in spec.split(",") if s.strip()]
    by_id = {c["id"]: c for c in DEFAULT_CRITERIA}
    out = []
    for w in wanted:
        if w not in by_id:
            raise SystemExit(f"unknown criterion: {w} (known: {list(by_id)})")
        out.append(by_id[w])
    return out


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[1])
    parser.add_argument("--paper-a", type=Path, required=True, help="path to version A (current)")
    parser.add_argument("--paper-b", type=Path, required=True, help="path to version B (revised)")
    parser.add_argument("--criteria", type=str, default=None,
                        help="comma-separated criterion ids (default: all 3)")
    parser.add_argument("--k-rounds", type=int, default=3, help="independent rounds (default 3)")
    parser.add_argument("--halt-threshold", type=float, default=0.0,
                        help="margin threshold below which halt triggers (default 0.0)")
    parser.add_argument("--unidirectional", action="store_true",
                        help="disable bidirectional averaging (default: bidirectional)")
    parser.add_argument("--out", type=Path, default=None,
                        help="write result JSON here in addition to stdout")
    args = parser.parse_args()

    for p in (args.paper_a, args.paper_b):
        if not p.exists():
            raise SystemExit(f"not found: {p}")

    result = run(
        paper_a_path=args.paper_a,
        paper_b_path=args.paper_b,
        criteria=_parse_criteria(args.criteria),
        k_rounds=args.k_rounds,
        bidirectional=not args.unidirectional,
        halt_threshold=args.halt_threshold,
    )

    out_json = json.dumps(result, indent=2, ensure_ascii=False)
    print(out_json)
    if args.out:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(out_json + "\n")


if __name__ == "__main__":
    main()
