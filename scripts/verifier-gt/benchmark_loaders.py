#!/usr/bin/env python3
"""
SI1: Dataset loader — unified interface for ground-truth benchmarks.

Loads pairwise evaluation benchmarks from HuggingFace and custom sources,
returning a uniform structure for downstream processing.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Iterator, Optional

try:
    from datasets import load_dataset
except ImportError:
    load_dataset = None  # type: ignore


@dataclass
class PairwiseExample:
    """One ground-truth pairwise comparison."""

    example_id: str
    prompt: str  # context / question / task description
    chosen: str  # the preferred response (ground truth winner)
    rejected: str  # the dispreferred response
    category: Optional[str] = None
    metadata: dict = field(default_factory=dict)


def load_rewardbench(
    limit: Optional[int] = None,
    split: str = "filtered",
    cache_dir: Optional[str] = None,
    stratified: bool = False,
) -> Iterator[PairwiseExample]:
    """Load RewardBench (allenai/reward-bench) pairwise pairs.

    Args:
        limit: optional number of examples to yield
        split: "filtered" (cleaned, default) or "raw"
        cache_dir: HuggingFace cache directory
        stratified: if True, sample roughly equal count from each subset

    Yields PairwiseExample objects.
    """
    if load_dataset is None:
        raise RuntimeError("datasets library not installed")

    ds = load_dataset("allenai/reward-bench", split=split, cache_dir=cache_dir)

    if stratified and limit:
        from collections import defaultdict
        by_subset = defaultdict(list)
        for row in ds:
            subset = row.get("subset") or row.get("category") or "unknown"
            by_subset[subset].append(row)
        n_subsets = len(by_subset)
        per_subset = max(1, limit // n_subsets)

        count = 0
        for subset, rows in by_subset.items():
            for idx, row in enumerate(rows[:per_subset]):
                yield PairwiseExample(
                    example_id=str(row.get("id", f"{subset}-{idx}")),
                    prompt=row["prompt"],
                    chosen=row["chosen"],
                    rejected=row["rejected"],
                    category=subset,
                    metadata={
                        "source": "rewardbench",
                        "chosen_model": row.get("chosen_model"),
                        "rejected_model": row.get("rejected_model"),
                    },
                )
                count += 1
                if count >= limit:
                    return
        return

    count = 0
    for row in ds:
        yield PairwiseExample(
            example_id=str(row.get("id", count)),
            prompt=row["prompt"],
            chosen=row["chosen"],
            rejected=row["rejected"],
            category=row.get("subset") or row.get("category"),
            metadata={
                "source": "rewardbench",
                "chosen_model": row.get("chosen_model"),
                "rejected_model": row.get("rejected_model"),
            },
        )
        count += 1
        if limit is not None and count >= limit:
            break


def load_judgebench(
    limit: Optional[int] = None,
    cache_dir: Optional[str] = None,
    stratified: bool = False,
    split: str = "all",
) -> Iterator[PairwiseExample]:
    """Load JudgeBench (ScalerLab/JudgeBench).

    Schema: pair_id, question, response_A, response_B, label ("A>B" or "B>A"),
            source (category), response_model.
    Splits: 'claude' (350), 'gpt' (350), 'all' (700).
    """
    if load_dataset is None:
        raise RuntimeError("datasets library not installed")

    splits = ["claude", "gpt"] if split == "all" else [split]
    all_rows = []
    for sp in splits:
        ds = load_dataset("ScalerLab/JudgeBench", split=sp, cache_dir=cache_dir)
        for row in ds:
            all_rows.append({**row, "_split": sp})

    def convert(row, idx):
        label = row.get("label", "A>B")
        if label.startswith("A>"):
            chosen, rejected = row["response_A"], row["response_B"]
        else:
            chosen, rejected = row["response_B"], row["response_A"]
        return PairwiseExample(
            example_id=str(row.get("pair_id", idx)),
            prompt=row["question"],
            chosen=chosen,
            rejected=rejected,
            category=row.get("source"),
            metadata={
                "source": "judgebench",
                "split": row["_split"],
                "response_model": row.get("response_model"),
                "original_label": label,
            },
        )

    if stratified and limit:
        from collections import defaultdict
        by_subset = defaultdict(list)
        for row in all_rows:
            by_subset[row.get("source") or "unknown"].append(row)
        n_subsets = len(by_subset)
        per_subset = max(1, limit // n_subsets)
        count = 0
        for subset, rows in by_subset.items():
            for idx, row in enumerate(rows[:per_subset]):
                yield convert(row, f"{subset}-{idx}")
                count += 1
                if count >= limit:
                    return
        return

    for idx, row in enumerate(all_rows):
        yield convert(row, idx)
        if limit is not None and idx + 1 >= limit:
            break


# --- Registry ---

def load_swebench(
    limit: Optional[int] = None,
    cache_dir: Optional[str] = None,
    stratified: bool = False,
) -> Iterator[PairwiseExample]:
    """Load SWE-Bench Verified as distractor pairs.

    Since SWE-Bench Verified has a single correct patch per issue, we
    construct pairwise comparisons by using another issue's patch as the
    distractor (rejected). The correct patch should be preferred because
    it actually addresses the given problem.

    Schema mapping:
        prompt = problem_statement
        chosen = own patch (correct)
        rejected = another issue's patch (distractor)
        category = difficulty bucket
    """
    if load_dataset is None:
        raise RuntimeError("datasets library not installed")

    ds = load_dataset("princeton-nlp/SWE-bench_Verified", split="test", cache_dir=cache_dir)
    rows = list(ds)

    n = len(rows)
    for i, row in enumerate(rows):
        # Distractor: use row ((i + n//2) % n) — deterministic, far from own
        distractor = rows[(i + n // 2) % n]
        yield PairwiseExample(
            example_id=row["instance_id"],
            prompt=row["problem_statement"],
            chosen=row["patch"],
            rejected=distractor["patch"],
            category=row.get("difficulty") or "unknown",
            metadata={
                "source": "swebench-verified",
                "repo": row.get("repo"),
                "distractor_instance": distractor["instance_id"],
            },
        )
        if limit is not None and i + 1 >= limit:
            break


LOADERS = {
    "rewardbench": load_rewardbench,
    "judgebench": load_judgebench,
    "swebench": load_swebench,
}


def load(dataset_name: str, limit: Optional[int] = None, **kwargs) -> Iterator[PairwiseExample]:
    if dataset_name not in LOADERS:
        raise ValueError(f"Unknown dataset: {dataset_name}. Available: {list(LOADERS)}")
    return LOADERS[dataset_name](limit=limit, **kwargs)


if __name__ == "__main__":
    # Quick smoke test
    import sys

    name = sys.argv[1] if len(sys.argv) > 1 else "rewardbench"
    n = int(sys.argv[2]) if len(sys.argv) > 2 else 3
    for i, ex in enumerate(load(name, limit=n)):
        print(f"[{i}] {ex.example_id} ({ex.category}): prompt_len={len(ex.prompt)}, "
              f"chosen_len={len(ex.chosen)}, rejected_len={len(ex.rejected)}")
