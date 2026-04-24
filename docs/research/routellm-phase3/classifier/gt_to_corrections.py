#!/usr/bin/env python3
"""
gt_to_corrections.py — Convert labeled GT JSONL into retrain_cli.py corrections.jsonl.
"""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path


def load_jsonl(path: Path) -> list[dict]:
    return [json.loads(line) for line in path.read_text().splitlines() if line.strip()]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--labeled", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--only-disagreements", action="store_true")
    args = parser.parse_args()

    labeled = load_jsonl(args.labeled)
    ts = datetime.now(timezone.utc).replace(microsecond=0).isoformat()
    corrections = []

    for entry in labeled:
        gt_label = entry.get("gt_label")
        predicted_label = entry.get("predicted_label")
        prompt = entry.get("prompt")
        if not gt_label or not prompt:
            continue
        if args.only_disagreements and gt_label == predicted_label:
            continue
        corrections.append(
            {
                "prompt": prompt,
                "label": gt_label,
                "corrected_from": predicted_label,
                "ts": ts,
            }
        )

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text("\n".join(json.dumps(entry, ensure_ascii=False) for entry in corrections) + "\n")
    print(f"[gt-to-corrections] wrote {len(corrections)} entries → {args.output}")


if __name__ == "__main__":
    main()
