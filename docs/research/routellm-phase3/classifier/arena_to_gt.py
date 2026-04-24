#!/usr/bin/env python3
"""
arena_to_gt.py — Convert lmarena-ai/arena-human-preference-100k to our 5-label taxonomy.

Arena entries carry human-derived metadata in `category_tag.criteria_v0.1`:
  complexity, creativity, domain_knowledge, problem_solving,
  real_world, specificity, technical_accuracy (all booleans)
plus `is_code`, `is_refusal`, `is_code`, `math_v0.1`, and `winner` (human vote).

We combine these signals via a deterministic rule so labels trace back to
human-annotated inputs. The mapping is intentionally conservative: when in
doubt we bias toward `cloud_required` (safer for routing).
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from pathlib import Path

import pyarrow.parquet as pq


LABELS = ["local_confident", "local_probable", "cloud_required", "hybrid", "unknown"]


STRONG_MODELS = {
    # Frontier tier (likely to win when task is hard)
    "claude-3-5-sonnet-20240620",
    "claude-3-5-sonnet-20241022",
    "claude-3-opus-20240229",
    "gpt-4o-2024-05-13",
    "gpt-4o-2024-08-06",
    "gpt-4o-2024-11-20",
    "gpt-4-turbo-2024-04-09",
    "o1-preview",
    "o1-mini",
    "gemini-1.5-pro-002",
    "gemini-1.5-pro-exp-0827",
    "grok-2-2024-08-13",
    "chatgpt-4o-latest",
}
WEAK_MODELS = {
    "gpt-3.5-turbo-0125",
    "gpt-3.5-turbo-1106",
    "claude-3-haiku-20240307",
    "gemini-1.5-flash-002",
    "gemini-1.5-flash-exp-0827",
    "gemini-1.5-flash-8b-exp-0827",
    "llama-3-8b-instruct",
    "llama-3.1-8b-instruct",
    "mistral-7b-instruct",
    "qwen2-7b-instruct",
    "gpt-4o-mini-2024-07-18",
}


def apply_label_rules(row: dict) -> tuple[str, str]:
    """Return (label, rationale) based on Arena metadata.

    Priority order:
      1. Refusal / language issues → unknown
      2. Complexity + multiple hard flags → cloud_required
      3. Code + complexity → cloud_required
      4. Creativity + complexity → hybrid
      5. Medium complexity → local_probable
      6. Low complexity, few flags → local_confident
      7. Winner gives stronger signal if model tiers known
    """
    cat = row.get("category_tag") or {}
    crit = cat.get("criteria_v0.1") or {}
    math_v = cat.get("math_v0.1") or {}

    is_code = bool(row.get("is_code"))
    is_refusal = bool(row.get("is_refusal"))
    is_math = bool(math_v.get("math"))

    complexity = bool(crit.get("complexity"))
    creativity = bool(crit.get("creativity"))
    domain_knowledge = bool(crit.get("domain_knowledge"))
    problem_solving = bool(crit.get("problem_solving"))
    technical_accuracy = bool(crit.get("technical_accuracy"))
    specificity = bool(crit.get("specificity"))

    # Rule 1: refusals indicate safety / OOD
    if is_refusal:
        return "unknown", "is_refusal=True (safety or unsupported request)"

    # Rule 2: code tasks with complexity are hard routing
    if is_code and (complexity or technical_accuracy):
        return "cloud_required", "code + (complexity|technical_accuracy)"

    # Rule 3: math reasoning tasks
    if is_math and complexity:
        return "cloud_required", "math + complexity"

    # Rule 4: complexity + multiple hard flags
    hard_flag_count = sum([complexity, technical_accuracy, problem_solving, domain_knowledge])
    if complexity and hard_flag_count >= 3:
        return "cloud_required", f"complexity + hard_flags={hard_flag_count}"

    # Rule 5: creativity + complexity → hybrid (local can start, cloud refines)
    if creativity and complexity:
        return "hybrid", "creativity + complexity"

    # Rule 6: domain_knowledge without complexity → local_probable
    if domain_knowledge and not complexity and not technical_accuracy:
        return "local_probable", "domain_knowledge only"

    # Rule 7: low complexity, few flags → local_confident
    if not complexity and hard_flag_count <= 1:
        return "local_confident", f"no complexity, hard_flags={hard_flag_count}"

    # Rule 8: complexity alone or with 1-2 flags → local_probable
    if complexity and hard_flag_count <= 2:
        return "local_probable", f"complexity with hard_flags={hard_flag_count}"

    # Default: probably needs cloud
    return "cloud_required", f"default (hard_flags={hard_flag_count}, specificity={specificity})"


def winner_signal(row: dict) -> str | None:
    """Return 'cloud_required', 'local', or None if undetermined.

    Strong model wins → task needed the strong model → cloud_required.
    Weak model wins or tie with weak models → local likely suffices.
    """
    winner = row.get("winner")
    model_a = row.get("model_a") or ""
    model_b = row.get("model_b") or ""

    a_strong = model_a in STRONG_MODELS
    a_weak = model_a in WEAK_MODELS
    b_strong = model_b in STRONG_MODELS
    b_weak = model_b in WEAK_MODELS

    if winner == "model_a" and a_strong and b_weak:
        return "cloud_required"
    if winner == "model_b" and b_strong and a_weak:
        return "cloud_required"
    if winner in {"tie", "tie (bothbad)"} and (a_weak or b_weak):
        return "local"
    return None


def extract_first_user_prompt(conversation: list[dict]) -> str:
    if not conversation:
        return ""
    for turn in conversation:
        if turn.get("role") == "user":
            return (turn.get("content") or "").strip()
    return ""


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--parquet", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--language", default="English")
    parser.add_argument("--max-prompt-len", type=int, default=2000)
    parser.add_argument("--max-items", type=int, default=0, help="If >0, stop after N items (for quick tests).")
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--turn-1-only", action="store_true", help="Keep only first-turn exchanges")
    args = parser.parse_args()

    print(f"[arena] reading {args.parquet}")
    table = pq.read_table(str(args.parquet))
    print(f"[arena] total rows: {table.num_rows}")

    rows = table.to_pylist()

    entries: list[dict] = []
    dist = Counter()
    winner_disagree = 0
    winner_agree = 0
    for row in rows:
        if args.language and row.get("language") != args.language:
            continue
        if args.turn_1_only and row.get("turn") != 1:
            continue
        prompt = extract_first_user_prompt(row.get("conversation_a") or [])
        if not prompt:
            continue
        if len(prompt) > args.max_prompt_len:
            prompt = prompt[: args.max_prompt_len]

        label, rationale = apply_label_rules(row)
        w_signal = winner_signal(row)
        if w_signal:
            if w_signal == "cloud_required" and label == "cloud_required":
                winner_agree += 1
            elif w_signal == "local" and label in {"local_confident", "local_probable"}:
                winner_agree += 1
            else:
                winner_disagree += 1

        entries.append(
            {
                "id": f"gt-arena-{len(entries):05d}",
                "question_id": row.get("question_id"),
                "prompt": prompt,
                "prompt_len": len(prompt),
                "language": row.get("language"),
                "is_code": bool(row.get("is_code")),
                "is_refusal": bool(row.get("is_refusal")),
                "category_tag": row.get("category_tag"),
                "winner": row.get("winner"),
                "model_a": row.get("model_a"),
                "model_b": row.get("model_b"),
                "gt_label": label,
                "annotator": "arena-rules-v1",
                "annotator_notes": rationale,
                "winner_signal": w_signal,
            }
        )
        dist[label] += 1
        if args.max_items and len(entries) >= args.max_items:
            break

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text("\n".join(json.dumps(e, ensure_ascii=False) for e in entries) + "\n")

    total = len(entries)
    print(f"[arena] wrote {total} → {args.output}")
    print(f"[arena] label distribution:")
    for label in LABELS:
        count = dist.get(label, 0)
        print(f"  {label:18s} {count:6d}  ({count / total * 100 if total else 0:.1f}%)")

    if winner_agree + winner_disagree > 0:
        print(f"[arena] winner-signal cross-check: agree={winner_agree} disagree={winner_disagree} "
              f"agreement={winner_agree / (winner_agree + winner_disagree):.3f}")


if __name__ == "__main__":
    main()
