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


def load_git_commit_faithfulness(
    limit: Optional[int] = None,
    cache_dir: Optional[str] = None,
    stratified: bool = False,
    repo_path: str = ".",
    max_commits: int = 500,
    min_diff_lines: int = 10,
) -> Iterator[PairwiseExample]:
    """Git commit message faithfulness benchmark (#623).

    Construct pairs from real git history:
        prompt  = diff stat (files changed + +/- counts)
        chosen  = actual commit message
        rejected = another commit's message (distractor)

    Ground truth: chosen (actual message matching diff) should win.
    """
    import subprocess
    import re as _re

    log_output = subprocess.check_output(
        ["git", "-C", repo_path, "log", "--no-merges",
         "--pretty=format:%H\t%s", f"-{max_commits}"],
        text=True,
    ).strip().split("\n")

    commits = []
    for line in log_output:
        if "\t" not in line:
            continue
        sha, subject = line.split("\t", 1)
        try:
            stat = subprocess.check_output(
                ["git", "-C", repo_path, "show", "--stat", "--format=", sha],
                text=True,
            ).strip()
        except subprocess.CalledProcessError:
            continue
        if not stat:
            continue
        summary = stat.split("\n")[-1]
        total = sum(int(m.group(1)) for m in _re.finditer(r"(\d+)\s+(?:insertion|deletion)", summary))
        if total < min_diff_lines:
            continue
        cat = "other"
        for prefix in ["feat", "fix", "refactor", "docs", "test", "chore", "style", "perf"]:
            if subject.lower().startswith(prefix):
                cat = prefix
                break
        commits.append({"sha": sha, "subject": subject, "stat": stat, "category": cat})

    n = len(commits)
    if n < 2:
        return

    def convert(c, d):
        return PairwiseExample(
            example_id=c["sha"][:12],
            prompt=f"Diff stat for commit:\n{c['stat']}",
            chosen=c["subject"],
            rejected=d["subject"],
            category=c["category"],
            metadata={"source": "git-commit-faithfulness", "sha": c["sha"], "distractor_sha": d["sha"]},
        )

    if stratified and limit:
        from collections import defaultdict
        by_cat = defaultdict(list)
        for c in commits:
            by_cat[c["category"]].append(c)
        n_cats = len(by_cat)
        per_cat = max(1, limit // n_cats)
        count = 0
        for cat, cs in by_cat.items():
            for c in cs[:per_cat]:
                idx = commits.index(c)
                yield convert(c, commits[(idx + n // 2) % n])
                count += 1
                if count >= limit:
                    return
        return

    for i, c in enumerate(commits):
        yield convert(c, commits[(i + n // 2) % n])
        if limit is not None and i + 1 >= limit:
            break


def load_lean_proof_matching(
    limit: Optional[int] = None,
    cache_dir: Optional[str] = None,
    stratified: bool = False,
    lean_root: str = "../agent-manifesto/lean-formalization",
) -> Iterator[PairwiseExample]:
    """Lean theorem/proof matching benchmark (#624).

    prompt   = theorem signature
    chosen   = actual proof body
    rejected = different theorem's proof body (distractor)
    """
    import sys as _sys
    from pathlib import Path as _Path
    _sys.path.insert(0, str(_Path(__file__).resolve().parent))
    from lean_extractor import extract_theorems as _extract

    theorems = list(_extract(_Path(lean_root)))
    n = len(theorems)
    if n < 2:
        return

    def convert(t, d):
        return PairwiseExample(
            example_id=t["name"],
            prompt=f"Lean 4 theorem signature:\n{t['signature']}",
            chosen=t["body"],
            rejected=d["body"],
            category=_Path(t["file"]).stem,
            metadata={"source": "lean-proof-matching",
                      "file": t["file"],
                      "distractor": d["name"]},
        )

    if stratified and limit:
        from collections import defaultdict
        by_file = defaultdict(list)
        for t in theorems:
            by_file[_Path(t["file"]).stem].append(t)
        n_files = len(by_file)
        per_file = max(1, limit // n_files)
        count = 0
        for stem, ts in by_file.items():
            for t in ts[:per_file]:
                idx = theorems.index(t)
                yield convert(t, theorems[(idx + n // 2) % n])
                count += 1
                if count >= limit:
                    return
        return

    for i, t in enumerate(theorems):
        yield convert(t, theorems[(i + n // 2) % n])
        if limit is not None and i + 1 >= limit:
            break


def load_ultrafeedback(
    limit: Optional[int] = None,
    cache_dir: Optional[str] = None,
    stratified: bool = False,
) -> Iterator[PairwiseExample]:
    """UltraFeedback (argilla/ultrafeedback-binarized-preferences, #625).

    Uses chosen/rejected from GPT-4 preference (quasi-ground-truth).
    """
    if load_dataset is None:
        raise RuntimeError("datasets library not installed")

    ds = load_dataset("argilla/ultrafeedback-binarized-preferences", split="train", cache_dir=cache_dir)

    def convert(row, idx):
        # Schema: source, instruction, chosen_response, rejected_response, chosen_rating, rejected_rating
        prompt = row.get("instruction") or ""
        chosen = row.get("chosen_response") or row.get("chosen", "")
        rejected = row.get("rejected_response") or row.get("rejected", "")
        return PairwiseExample(
            example_id=str(idx),
            prompt=prompt,
            chosen=chosen,
            rejected=rejected,
            category=row.get("source"),
            metadata={
                "source": "ultrafeedback",
                "chosen_rating": row.get("chosen_rating"),
                "rejected_rating": row.get("rejected_rating"),
            },
        )

    if stratified and limit:
        from collections import defaultdict
        by_src = defaultdict(list)
        for idx, row in enumerate(ds):
            by_src[row.get("source") or "unknown"].append((idx, row))
        n_src = len(by_src)
        per_src = max(1, limit // n_src)
        count = 0
        for src, items in by_src.items():
            for idx, row in items[:per_src]:
                yield convert(row, idx)
                count += 1
                if count >= limit:
                    return
        return

    for idx, row in enumerate(ds):
        yield convert(row, idx)
        if limit is not None and idx + 1 >= limit:
            break


def load_chatbot_arena(
    limit: Optional[int] = None,
    cache_dir: Optional[str] = None,
    stratified: bool = False,
) -> Iterator[PairwiseExample]:
    """Chatbot Arena Conversations (lmsys/chatbot_arena_conversations, #626).

    Filters rows with clear winner vote. Uses single-turn prompts.
    """
    if load_dataset is None:
        raise RuntimeError("datasets library not installed")

    ds = load_dataset("lmsys/chatbot_arena_conversations", split="train", cache_dir=cache_dir)

    def _extract_first_turn(conv):
        """conv is a list of dicts with role/content. Return first user prompt and assistant reply."""
        if not conv:
            return "", ""
        user = ""
        assistant = ""
        for msg in conv:
            role = msg.get("role", "")
            if role == "user" and not user:
                user = msg.get("content", "") or ""
            elif role == "assistant" and user and not assistant:
                assistant = msg.get("content", "") or ""
                break
        return user, assistant

    def convert(row, idx):
        winner = row.get("winner", "")
        if winner not in ("model_a", "model_b"):
            return None
        conv_a = row.get("conversation_a") or []
        conv_b = row.get("conversation_b") or []
        prompt_a, resp_a = _extract_first_turn(conv_a)
        prompt_b, resp_b = _extract_first_turn(conv_b)
        prompt = prompt_a or prompt_b
        if not prompt or not resp_a or not resp_b:
            return None
        if winner == "model_a":
            chosen, rejected = resp_a, resp_b
        else:
            chosen, rejected = resp_b, resp_a
        return PairwiseExample(
            example_id=str(row.get("question_id", idx)),
            prompt=prompt,
            chosen=chosen,
            rejected=rejected,
            category=row.get("language") or row.get("turn"),
            metadata={
                "source": "chatbot-arena",
                "model_a": row.get("model_a"),
                "model_b": row.get("model_b"),
                "winner": winner,
            },
        )

    count = 0
    all_rows = []
    for idx, row in enumerate(ds):
        ex = convert(row, idx)
        if ex is None:
            continue
        all_rows.append(ex)

    if stratified and limit:
        from collections import defaultdict
        by_cat = defaultdict(list)
        for ex in all_rows:
            by_cat[ex.category or "unknown"].append(ex)
        n_cats = len(by_cat)
        per_cat = max(1, limit // n_cats)
        for cat, items in by_cat.items():
            for ex in items[:per_cat]:
                yield ex
                count += 1
                if count >= limit:
                    return
        return

    for ex in all_rows:
        yield ex
        count += 1
        if limit is not None and count >= limit:
            break


def load_mt_bench(
    limit: Optional[int] = None,
    cache_dir: Optional[str] = None,
    stratified: bool = False,
) -> Iterator[PairwiseExample]:
    """MT-Bench human judgments (lmsys/mt_bench_human_judgments, #627).

    Uses first-turn pairwise human-preference judgments.
    """
    if load_dataset is None:
        raise RuntimeError("datasets library not installed")

    ds = load_dataset("lmsys/mt_bench_human_judgments", split="human", cache_dir=cache_dir)

    def convert(row, idx):
        winner = row.get("winner", "")
        if winner not in ("model_a", "model_b"):
            return None
        conv_a = row.get("conversation_a") or []
        conv_b = row.get("conversation_b") or []

        def turns_to_text(conv):
            if not conv:
                return "", ""
            user = ""
            assistant = ""
            for msg in conv:
                r = msg.get("role")
                c = msg.get("content") or ""
                if r == "user" and not user:
                    user = c
                elif r == "assistant" and user and not assistant:
                    assistant = c
                    break
            return user, assistant

        prompt_a, resp_a = turns_to_text(conv_a)
        prompt_b, resp_b = turns_to_text(conv_b)
        prompt = prompt_a or prompt_b
        if not prompt or not resp_a or not resp_b:
            return None
        if winner == "model_a":
            chosen, rejected = resp_a, resp_b
        else:
            chosen, rejected = resp_b, resp_a
        return PairwiseExample(
            example_id=str(row.get("question_id", idx)),
            prompt=prompt,
            chosen=chosen,
            rejected=rejected,
            category=row.get("category") or row.get("turn"),
            metadata={
                "source": "mt-bench",
                "model_a": row.get("model_a"),
                "model_b": row.get("model_b"),
                "turn": row.get("turn"),
            },
        )

    all_rows = []
    for idx, row in enumerate(ds):
        ex = convert(row, idx)
        if ex is not None:
            all_rows.append(ex)

    if stratified and limit:
        from collections import defaultdict
        by_cat = defaultdict(list)
        for ex in all_rows:
            by_cat[ex.category or "unknown"].append(ex)
        n_cats = len(by_cat)
        per_cat = max(1, limit // n_cats)
        count = 0
        for cat, items in by_cat.items():
            for ex in items[:per_cat]:
                yield ex
                count += 1
                if count >= limit:
                    return
        return

    count = 0
    for ex in all_rows:
        yield ex
        count += 1
        if limit is not None and count >= limit:
            break


def load_humaneval(
    limit: Optional[int] = None,
    cache_dir: Optional[str] = None,
    stratified: bool = False,
) -> Iterator[PairwiseExample]:
    """HumanEval (openai_humaneval, #628).

    Constructed pairwise: prompt = function signature + docstring;
    chosen = canonical_solution (passes tests); rejected = another problem's solution (distractor).
    """
    if load_dataset is None:
        raise RuntimeError("datasets library not installed")

    ds = load_dataset("openai_humaneval", split="test", cache_dir=cache_dir)
    rows = list(ds)
    n = len(rows)

    def convert(row, d):
        return PairwiseExample(
            example_id=row["task_id"],
            prompt=row["prompt"],
            chosen=row["canonical_solution"],
            rejected=d["canonical_solution"],
            category=row["task_id"].split("/")[0],
            metadata={"source": "humaneval", "distractor": d["task_id"]},
        )

    for i, row in enumerate(rows):
        distractor = rows[(i + n // 2) % n]
        yield convert(row, distractor)
        if limit is not None and i + 1 >= limit:
            break


def load_gsm8k(
    limit: Optional[int] = None,
    cache_dir: Optional[str] = None,
    stratified: bool = False,
) -> Iterator[PairwiseExample]:
    """GSM8K (gsm8k, #629).

    Constructed pairwise: prompt = math word problem;
    chosen = correct reasoning + answer; rejected = another problem's reasoning (distractor).
    """
    if load_dataset is None:
        raise RuntimeError("datasets library not installed")

    ds = load_dataset("gsm8k", "main", split="test", cache_dir=cache_dir)
    rows = list(ds)
    n = len(rows)

    def convert(row, d, idx):
        return PairwiseExample(
            example_id=str(idx),
            prompt=row["question"],
            chosen=row["answer"],
            rejected=d["answer"],
            category="gsm8k",
            metadata={"source": "gsm8k"},
        )

    for i, row in enumerate(rows):
        distractor = rows[(i + n // 2) % n]
        yield convert(row, distractor, i)
        if limit is not None and i + 1 >= limit:
            break


def load_fever(
    limit: Optional[int] = None,
    cache_dir: Optional[str] = None,
    stratified: bool = False,
) -> Iterator[PairwiseExample]:
    """FEVER with gold evidence (copenlu/fever_gold_evidence, #630).

    Substitutes for the original SciFact plan (HF-gated dataset scripts).
    Constructed pairwise over claims + evidence:
    chosen = this claim's own gold evidence (topically relevant);
    rejected = another claim's evidence (topical distractor).
    """
    if load_dataset is None:
        raise RuntimeError("datasets library not installed")

    ds = load_dataset("copenlu/fever_gold_evidence", split="validation", cache_dir=cache_dir)
    rows = []
    for row in ds:
        ev = row.get("evidence")
        if not ev:
            continue
        # evidence is a stringified list-of-lists [[title, line_id, text], ...]
        try:
            import ast
            parsed = ast.literal_eval(ev) if isinstance(ev, str) else ev
            evidence_texts = []
            for e in parsed:
                if isinstance(e, list) and len(e) >= 3:
                    evidence_texts.append(str(e[2]))
            ev_joined = " ".join(evidence_texts)[:1500]
        except Exception:
            continue
        if not ev_joined:
            continue
        rows.append({
            "id": row.get("id"),
            "claim": row.get("claim", ""),
            "evidence": ev_joined,
            "label": row.get("label", ""),
        })

    n = len(rows)
    if n < 2:
        return

    def convert(r, d, i):
        return PairwiseExample(
            example_id=str(r["id"] or i),
            prompt=f"Claim: {r['claim']}\n\nWhich text provides evidence directly relevant to this claim?",
            chosen=r["evidence"],
            rejected=d["evidence"],
            category=r["label"],
            metadata={"source": "fever", "distractor": d["id"]},
        )

    if stratified and limit:
        from collections import defaultdict
        by_label = defaultdict(list)
        for r in rows:
            by_label[r["label"]].append(r)
        n_labels = len(by_label)
        per_label = max(1, limit // n_labels)
        count = 0
        for label, items in by_label.items():
            for idx, r in enumerate(items[:per_label]):
                orig_idx = rows.index(r)
                yield convert(r, rows[(orig_idx + n // 2) % n], orig_idx)
                count += 1
                if count >= limit:
                    return
        return

    for i, r in enumerate(rows):
        yield convert(r, rows[(i + n // 2) % n], i)
        if limit is not None and i + 1 >= limit:
            break


LOADERS = {
    "rewardbench": load_rewardbench,
    "judgebench": load_judgebench,
    "swebench": load_swebench,
    "commit-faithfulness": load_git_commit_faithfulness,
    "lean-proof": load_lean_proof_matching,
    "ultrafeedback": load_ultrafeedback,
    "chatbot-arena": load_chatbot_arena,
    "mt-bench": load_mt_bench,
    "humaneval": load_humaneval,
    "gsm8k": load_gsm8k,
    "fever": load_fever,
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
