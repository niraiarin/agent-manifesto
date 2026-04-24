#!/usr/bin/env python3
"""
sample_qwen_candidates.py — Stratified 500-item sampler for Qwen labeling.

Joins real-prompts.jsonl (full text) with real-corpus-per-prompt.jsonl
(mDeBERTa predictions) by session_id + prompt prefix. Samples stratified
by production routing distribution.
"""

from __future__ import annotations

import argparse
import json
import random
from collections import Counter, defaultdict
from pathlib import Path


LABELS = ["local_confident", "local_probable", "cloud_required", "hybrid", "unknown"]
TARGET_DIST = {
    "local_confident": 0.15,
    "local_probable": 0.50,
    "cloud_required": 0.20,
    "hybrid": 0.10,
    "unknown": 0.05,
}


def load_jsonl(path: Path) -> list[dict]:
    return [json.loads(line) for line in path.read_text().splitlines() if line.strip()]


def prompt_key(session_id: str | None, prompt: str) -> tuple[str, str]:
    return (str(session_id or ""), (prompt or "")[:100])


def conf_bin(value: float) -> str:
    if value < 0.5:
        return "low"
    if value < 0.8:
        return "mid"
    return "high"


def proportional_targets(n: int) -> dict[str, int]:
    targets = {label: max(1, int(round(n * pct))) for label, pct in TARGET_DIST.items()}
    total = sum(targets.values())
    if total < n:
        targets["local_probable"] += n - total
    elif total > n:
        overflow = total - n
        for label in ("unknown", "hybrid", "local_confident", "cloud_required", "local_probable"):
            if overflow == 0:
                break
            removable = min(overflow, max(0, targets[label] - 1))
            targets[label] -= removable
            overflow -= removable
    return targets


def sample_by_stratum(
    pool: dict[tuple[str, str], list[dict]],
    targets: dict[str, int],
) -> list[dict]:
    sampled: list[dict] = []
    sampled_keys: set[tuple[str, str]] = set()

    for label, count in targets.items():
        bins = {cb: list(entries) for (lbl, cb), entries in pool.items() if lbl == label}
        if not bins:
            continue
        per_bin = max(1, count // max(1, len(bins)))
        taken = 0
        for cb in sorted(bins):
            remaining = count - taken
            if remaining <= 0:
                break
            candidates = [
                entry
                for entry in bins[cb]
                if (entry["session_id"], entry["prompt"][:100]) not in sampled_keys
            ]
            take = min(per_bin, len(candidates), remaining)
            if take <= 0:
                continue
            chosen = random.sample(candidates, take)
            for entry in chosen:
                sampled.append(entry)
                sampled_keys.add((entry["session_id"], entry["prompt"][:100]))
            taken += take

        remaining = count - taken
        if remaining > 0:
            extras = [
                entry
                for (lbl, _), entries in pool.items()
                if lbl == label
                for entry in entries
                if (entry["session_id"], entry["prompt"][:100]) not in sampled_keys
            ]
            take = min(remaining, len(extras))
            if take > 0:
                chosen = random.sample(extras, take)
                for entry in chosen:
                    sampled.append(entry)
                    sampled_keys.add((entry["session_id"], entry["prompt"][:100]))

    return sampled


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--real-prompts", type=Path, required=True)
    parser.add_argument("--corpus-classified", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--n", type=int, default=500)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--id-prefix", default="gt-qwen")
    args = parser.parse_args()

    random.seed(args.seed)

    real_prompts = load_jsonl(args.real_prompts)
    classified = load_jsonl(args.corpus_classified)

    classified_index: dict[tuple[str, str], dict] = {}
    for entry in classified:
        session_id = entry.get("session_id")
        preview = entry.get("prompt_preview") or ""
        classified_index[(str(session_id or ""), preview[:100])] = entry

    pool: dict[tuple[str, str], list[dict]] = defaultdict(list)
    joined = 0
    for entry in real_prompts:
        key = prompt_key(entry.get("session_id"), entry.get("prompt", ""))
        classified_entry = classified_index.get(key)
        if classified_entry is None:
            continue
        label = classified_entry.get("label")
        if label not in LABELS:
            continue
        confidence = float(classified_entry.get("confidence") or 0.0)
        merged = {
            "session_id": entry.get("session_id"),
            "prompt": entry.get("prompt"),
            "prompt_len": entry.get("prompt_len") or len(entry.get("prompt") or ""),
            "predicted_label": label,
            "predicted_confidence": round(confidence, 3),
        }
        pool[(label, conf_bin(confidence))].append(merged)
        joined += 1

    print(f"[sample] real_prompts={len(real_prompts)} classified={len(classified)} joined={joined}")

    targets = proportional_targets(args.n)
    sampled = sample_by_stratum(pool, targets)
    if len(sampled) < args.n:
        extras_pool = [
            entry
            for entries in pool.values()
            for entry in entries
            if entry not in sampled
        ]
        remaining = args.n - len(sampled)
        if extras_pool and remaining > 0:
            sampled.extend(random.sample(extras_pool, min(remaining, len(extras_pool))))

    sampled = sampled[: args.n]

    entries_out: list[dict] = []
    for index, entry in enumerate(sampled):
        entries_out.append(
            {
                "id": f"{args.id_prefix}-{index:04d}",
                "session_id": entry["session_id"],
                "prompt": entry["prompt"],
                "prompt_len": entry["prompt_len"],
                "predicted_label": entry["predicted_label"],
                "predicted_confidence": entry["predicted_confidence"],
                "gt_label": None,
                "annotator_notes": None,
            }
        )

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text("\n".join(json.dumps(entry, ensure_ascii=False) for entry in entries_out) + "\n")

    dist = Counter(entry["predicted_label"] for entry in entries_out)
    print(f"[sample] wrote {len(entries_out)} → {args.output}")
    print(f"[sample] label distribution: {dict(dist)}")
    print(f"[sample] target distribution: {targets}")


if __name__ == "__main__":
    main()
