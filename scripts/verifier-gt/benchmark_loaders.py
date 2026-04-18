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
) -> Iterator[PairwiseExample]:
    """Load JudgeBench (pending concrete HF dataset name verification)."""
    if load_dataset is None:
        raise RuntimeError("datasets library not installed")

    # JudgeBench canonical dataset: ScalerLab/JudgeBench (tentative)
    ds = load_dataset("ScalerLab/JudgeBench", split="train", cache_dir=cache_dir)

    count = 0
    for row in ds:
        # JudgeBench format may differ — normalize best-effort
        prompt = row.get("question") or row.get("prompt") or ""
        chosen = row.get("chosen") or row.get("response_A") or ""
        rejected = row.get("rejected") or row.get("response_B") or ""

        yield PairwiseExample(
            example_id=str(row.get("id", count)),
            prompt=prompt,
            chosen=chosen,
            rejected=rejected,
            category=row.get("category"),
            metadata={"source": "judgebench"},
        )
        count += 1
        if limit is not None and count >= limit:
            break


# --- Registry ---

LOADERS = {
    "rewardbench": load_rewardbench,
    "judgebench": load_judgebench,
    # SS3 SWE-Bench, SA1 commit, SA2 lean — added in later phases
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
