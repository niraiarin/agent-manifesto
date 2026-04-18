#!/usr/bin/env python3
"""
SI2: Format converter — benchmark PairwiseExample → Verifier pairwise input.

Also provides benchmark-specific criteria definitions.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Optional


# --- Benchmark-specific criteria ---

REWARDBENCH_CRITERION = {
    "id": "preference_match",
    "name": "Preference Match",
    "description": (
        "Which response better addresses the user's prompt? Consider helpfulness, "
        "correctness, clarity, and completeness. The response that more directly "
        "solves the user's need scores HIGH; the response that is less helpful, "
        "contains errors, or misses the point scores LOW."
    ),
}

JUDGEBENCH_CRITERION = {
    "id": "judge_preference",
    "name": "Judge Preference",
    "description": (
        "Which response is better overall? Consider correctness of facts, "
        "coherence of reasoning, and quality of expression. A clearly superior "
        "response scores HIGH; a response with errors, confusion, or weak "
        "reasoning scores LOW."
    ),
}

SWEBENCH_CRITERION = {
    "id": "patch_relevance",
    "name": "Patch Relevance",
    "description": (
        "Does this code patch address the given problem? A patch that modifies "
        "the correct files and implements the described fix scores HIGH. "
        "A patch that touches unrelated files, addresses a different issue, "
        "or is missing the core fix scores LOW."
    ),
}

LEAN_PROOF_CRITERION = {
    "id": "lean_proof_matching",
    "name": "Lean Proof Matching",
    "description": (
        "Does this Lean 4 proof body prove the given theorem signature? "
        "A proof whose tactics match the goal type scores HIGH. "
        "A proof that targets a different theorem or uses wrong lemmas "
        "scores LOW."
    ),
}

COMMIT_FAITHFULNESS_CRITERION = {
    "id": "commit_message_faithfulness",
    "name": "Commit Message Faithfulness",
    "description": (
        "Does this commit message accurately describe the diff? A message that "
        "matches the files changed, scale of changes, and nature of the work "
        "scores HIGH. A message that describes unrelated changes, wrong scope, "
        "or different type of work scores LOW."
    ),
}

ULTRAFEEDBACK_CRITERION = {
    "id": "gpt4_preference",
    "name": "GPT-4 Preference",
    "description": (
        "Which response is better per high-quality judgment? Consider "
        "correctness, helpfulness, and clarity. A high-quality response "
        "scores HIGH; a response with factual errors, poor instruction "
        "following, or weak reasoning scores LOW."
    ),
}

ARENA_CRITERION = {
    "id": "human_preference",
    "name": "Human Preference",
    "description": (
        "Which response would a human prefer? Consider helpfulness, "
        "correctness, naturalness, and completeness. A response humans "
        "would rate as better scores HIGH; one they would reject scores LOW."
    ),
}

MT_BENCH_CRITERION = {
    "id": "response_quality",
    "name": "Response Quality",
    "description": (
        "Which response better addresses the question? Consider correctness, "
        "depth, structure, and adherence to instructions. A strong answer "
        "scores HIGH; a weaker or incorrect answer scores LOW."
    ),
}

HUMANEVAL_CRITERION = {
    "id": "code_relevance",
    "name": "Code Relevance",
    "description": (
        "Does this Python code correctly implement the described function? "
        "Code whose logic matches the signature and docstring scores HIGH. "
        "Code that implements a different function or contains obvious bugs "
        "scores LOW."
    ),
}

GSM8K_CRITERION = {
    "id": "math_answer_relevance",
    "name": "Math Answer Relevance",
    "description": (
        "Does this reasoning and answer address the given math word problem? "
        "A step-by-step solution that matches the problem's quantities and "
        "produces a consistent numeric answer scores HIGH. A solution that "
        "uses unrelated numbers or targets a different problem scores LOW."
    ),
}

FEVER_CRITERION = {
    "id": "evidence_relevance",
    "name": "Evidence Relevance",
    "description": (
        "Does this text provide evidence directly relevant to the claim? "
        "Text that addresses the claim's subject and supports or refutes it "
        "with specific facts scores HIGH. Text about a different topic or "
        "unrelated evidence scores LOW."
    ),
}

# Multi-criteria decomposition (for RQ2 — decomposition effect)
REWARDBENCH_CRITERIA_DECOMPOSED = [
    {
        "id": "correctness",
        "name": "Correctness",
        "description": (
            "Is the response factually correct and free of errors? Accurate "
            "responses score HIGH; responses with incorrect information or "
            "logical errors score LOW."
        ),
    },
    {
        "id": "helpfulness",
        "name": "Helpfulness",
        "description": (
            "Does the response directly address the user's need? A response that "
            "solves the user's problem scores HIGH; one that misses the point or "
            "is off-topic scores LOW."
        ),
    },
    {
        "id": "clarity",
        "name": "Clarity",
        "description": (
            "Is the response clearly written and well-structured? Clear, organized "
            "responses score HIGH; confusing or poorly formatted responses score LOW."
        ),
    },
]


@dataclass
class VerifierInput:
    """Input format for verifier_local.py pairwise_compare."""

    problem: str
    proposal_a: str
    proposal_b: str
    criteria: list
    # Ground truth (not sent to verifier, used for accuracy comparison)
    ground_truth_winner: str  # "A" or "B"


def convert_pairwise(
    example,  # PairwiseExample from benchmark_loaders
    criteria: Optional[list] = None,
    swap: bool = False,
) -> VerifierInput:
    """Convert a benchmark example into VerifierInput.

    Args:
        example: PairwiseExample
        criteria: criteria list; defaults to benchmark-specific single criterion
        swap: if True, place rejected as A and chosen as B (for position bias testing)

    Returns VerifierInput with ground_truth_winner set to where 'chosen' ended up.
    """
    source = example.metadata.get("source", "")

    if criteria is None:
        if source == "rewardbench":
            criteria = [REWARDBENCH_CRITERION]
        elif source == "judgebench":
            criteria = [JUDGEBENCH_CRITERION]
        elif source == "swebench-verified":
            criteria = [SWEBENCH_CRITERION]
        elif source == "git-commit-faithfulness":
            criteria = [COMMIT_FAITHFULNESS_CRITERION]
        elif source == "lean-proof-matching":
            criteria = [LEAN_PROOF_CRITERION]
        elif source == "ultrafeedback":
            criteria = [ULTRAFEEDBACK_CRITERION]
        elif source == "chatbot-arena":
            criteria = [ARENA_CRITERION]
        elif source == "mt-bench":
            criteria = [MT_BENCH_CRITERION]
        elif source == "humaneval":
            criteria = [HUMANEVAL_CRITERION]
        elif source == "gsm8k":
            criteria = [GSM8K_CRITERION]
        elif source == "fever":
            criteria = [FEVER_CRITERION]
        else:
            criteria = [REWARDBENCH_CRITERION]  # default

    if swap:
        # rejected in slot A, chosen in slot B → ground truth winner is B
        proposal_a = example.rejected
        proposal_b = example.chosen
        gt_winner = "B"
    else:
        # chosen in slot A, rejected in slot B → ground truth winner is A
        proposal_a = example.chosen
        proposal_b = example.rejected
        gt_winner = "A"

    return VerifierInput(
        problem=example.prompt,
        proposal_a=proposal_a,
        proposal_b=proposal_b,
        criteria=criteria,
        ground_truth_winner=gt_winner,
    )


if __name__ == "__main__":
    # Smoke test
    import sys
    sys.path.insert(0, ".")
    from benchmark_loaders import load

    name = sys.argv[1] if len(sys.argv) > 1 else "rewardbench"
    for ex in load(name, limit=2):
        inp = convert_pairwise(ex)
        print(f"{ex.example_id}: problem_len={len(inp.problem)}, "
              f"A_len={len(inp.proposal_a)}, B_len={len(inp.proposal_b)}, "
              f"gt={inp.ground_truth_winner}, criteria={len(inp.criteria)}")
