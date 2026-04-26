#!/usr/bin/env python3
"""
compute_disagreement_tiers.py — Active-learning tier assignment over 3 model labels.

For each prompt with labels from 3 sources (Qwen 35B, Qwen 27B, mDeBERTa),
classify into one of 3 tiers:

- **tier 0** — all 3 models agree → auto-accept majority label as GT.
- **tier 1** — 2 models agree, 1 dissents → low-cost quick review (show
  minority label as a "reconsider" hint to the annotator).
- **tier 2** — all 3 models disagree → high-cost deep review (annotator
  decides from scratch with all 3 model labels visible).

Input format (3 JSONL files, keyed by `id`):
  {"id": "gt-qwen-0001", "prompt": "...", "label": "local_confident", ...}

Output: `disagreement-tiers.jsonl`, one record per prompt:
  {
    "id": "gt-qwen-0001",
    "prompt": "...",
    "tier": 0 | 1 | 2,
    "model_labels": {"qwen35b": "...", "qwen27b": "...", "mdeberta": "..."},
    "majority_label": "..." | null,    # null when tier=2 (no majority)
    "minority_models": [...] | null,   # populated for tier 1 + degraded tier 2
    "agreement_count": 3 | 2 | 1 | 0   # 0 only when all 3 models lack a label
  }

Prompts missing in any of the 3 inputs are skipped with a stderr note unless
`--allow-missing` is set (then the missing model is recorded as null and tier
falls back to "tier 2 with degraded info").

Usage:
  python3 compute_disagreement_tiers.py \\
    --qwen35b qwen-labels-500.jsonl \\
    --qwen27b qwen-labels-27b-q4.jsonl \\
    --mdeberta mdeberta-predictions-500.jsonl \\
    --output disagreement-tiers.jsonl \\
    [--summary]                            # print tier counts to stderr
"""

from __future__ import annotations

import argparse
import json
import sys
from collections import Counter
from pathlib import Path
from typing import Optional


VALID_LABELS = {"local_confident", "local_probable", "cloud_required", "hybrid", "unknown"}
MODEL_KEYS = ("qwen35b", "qwen27b", "mdeberta")


def load_label_jsonl(path: Path, label_field: str = "label") -> dict[str, dict]:
    """
    Load a JSONL of label records, keyed by `id`. Tolerates two common
    field names: `label` (Qwen output) or `predicted_label` (classifier output).
    Returns {id: {raw record}}.
    """
    out: dict[str, dict] = {}
    if not path.exists():
        raise FileNotFoundError(f"label file not found: {path}")
    for line_num, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        raw = raw.strip()
        if not raw:
            continue
        try:
            entry = json.loads(raw)
        except json.JSONDecodeError as exc:
            print(f"[skip] {path}:{line_num} invalid json: {exc}", file=sys.stderr)
            continue
        if not isinstance(entry, dict):
            continue
        item_id = entry.get("id")
        if not item_id:
            continue
        out[item_id] = entry
    return out


def extract_label(entry: dict) -> Optional[str]:
    """Return the model's label, falling back across known field names."""
    for field in ("label", "predicted_label", "gt_label"):
        v = entry.get(field)
        if isinstance(v, str) and v in VALID_LABELS:
            return v
    return None


def classify_tier(labels_by_model: dict[str, Optional[str]]) -> dict:
    """
    Given {"qwen35b": label, "qwen27b": label, "mdeberta": label} (any may be None),
    compute tier, agreement_count, majority_label, minority_models.
    """
    valid = {model: lbl for model, lbl in labels_by_model.items() if lbl is not None}
    if not valid:
        return {
            "tier": 2,
            "agreement_count": 0,
            "majority_label": None,
            "minority_models": list(labels_by_model.keys()),
        }

    counts = Counter(valid.values())
    most_label, most_count = counts.most_common(1)[0]

    # 3-way agreement: all valid models picked the same label AND we have 3 valid.
    if most_count == 3 and len(valid) == 3:
        return {
            "tier": 0,
            "agreement_count": 3,
            "majority_label": most_label,
            "minority_models": None,
        }

    # 2-way agreement: 2 picked the same label, 1 picked a different label
    # (with all 3 valid). Or 2 valid models agree and the third is missing.
    if most_count == 2:
        majority_models = [m for m, lbl in valid.items() if lbl == most_label]
        minority_models = [m for m in MODEL_KEYS if m not in majority_models]
        return {
            "tier": 1,
            "agreement_count": 2,
            "majority_label": most_label,
            "minority_models": minority_models,
        }

    # most_count == 1 means all picks were unique → 3-way disagreement.
    # Or 1 valid model and 2 missing → degraded; treat as tier 2.
    return {
        "tier": 2,
        "agreement_count": most_count,
        "majority_label": None,
        "minority_models": list(labels_by_model.keys()),
    }


def compute_tiers(
    qwen35b: dict[str, dict],
    qwen27b: dict[str, dict],
    mdeberta: dict[str, dict],
    *,
    allow_missing: bool = False,
) -> list[dict]:
    all_ids = sorted(set(qwen35b) | set(qwen27b) | set(mdeberta))
    out: list[dict] = []
    for item_id in all_ids:
        e35 = qwen35b.get(item_id)
        e27 = qwen27b.get(item_id)
        emd = mdeberta.get(item_id)

        if not allow_missing and (e35 is None or e27 is None or emd is None):
            print(
                f"[skip] {item_id}: missing model "
                f"({'qwen35b ' if e35 is None else ''}"
                f"{'qwen27b ' if e27 is None else ''}"
                f"{'mdeberta' if emd is None else ''})".strip(),
                file=sys.stderr,
            )
            continue

        labels_by_model = {
            "qwen35b": extract_label(e35) if e35 else None,
            "qwen27b": extract_label(e27) if e27 else None,
            "mdeberta": extract_label(emd) if emd else None,
        }
        tier_info = classify_tier(labels_by_model)

        prompt = ""
        for entry in (e35, e27, emd):
            if isinstance(entry, dict):
                p = entry.get("prompt") or entry.get("text")
                if isinstance(p, str):
                    prompt = p
                    break

        out.append({
            "id": item_id,
            "prompt": prompt,
            "tier": tier_info["tier"],
            "model_labels": labels_by_model,
            "majority_label": tier_info["majority_label"],
            "minority_models": tier_info["minority_models"],
            "agreement_count": tier_info["agreement_count"],
        })
    return out


def write_jsonl(path: Path, entries: list[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        for entry in entries:
            f.write(json.dumps(entry, ensure_ascii=False) + "\n")


def summary_counts(entries: list[dict]) -> str:
    by_tier = Counter(e["tier"] for e in entries)
    lines = ["tier distribution:"]
    for tier in (0, 1, 2):
        n = by_tier.get(tier, 0)
        pct = 100.0 * n / len(entries) if entries else 0.0
        label = {0: "all-agree", 1: "2-vs-1", 2: "all-disagree"}[tier]
        lines.append(f"  tier {tier} ({label:13s}): {n:5d} ({pct:5.1f}%)")
    lines.append(f"  total                    : {len(entries):5d}")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[1] if __doc__ else None)
    parser.add_argument("--qwen35b", type=Path, required=True, help="Qwen 35B labels JSONL")
    parser.add_argument("--qwen27b", type=Path, required=True, help="Qwen 27B labels JSONL")
    parser.add_argument("--mdeberta", type=Path, required=True, help="mDeBERTa predictions JSONL")
    parser.add_argument("--output", type=Path, required=True, help="output disagreement-tiers JSONL")
    parser.add_argument(
        "--allow-missing",
        action="store_true",
        help="record nulls instead of skipping when a model is missing a prompt",
    )
    parser.add_argument(
        "--summary",
        action="store_true",
        help="print per-tier counts to stderr after writing",
    )
    args = parser.parse_args()

    qwen35b = load_label_jsonl(args.qwen35b)
    qwen27b = load_label_jsonl(args.qwen27b)
    mdeberta = load_label_jsonl(args.mdeberta)
    print(
        f"[load] qwen35b={len(qwen35b)} qwen27b={len(qwen27b)} mdeberta={len(mdeberta)}",
        file=sys.stderr,
    )

    entries = compute_tiers(qwen35b, qwen27b, mdeberta, allow_missing=args.allow_missing)
    write_jsonl(args.output, entries)
    print(f"[write] {args.output} ({len(entries)} entries)", file=sys.stderr)

    if args.summary:
        print(summary_counts(entries), file=sys.stderr)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
