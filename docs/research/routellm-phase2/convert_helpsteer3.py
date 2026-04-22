#!/usr/bin/env python3
"""
convert_helpsteer3.py — HelpSteer3-Preference → RouteLLM battle format.

Source: nvidia/HelpSteer3 (HuggingFace, CC-BY-4.0)
Output: JSONL with {id, model_a, response_a, model_b, response_b, winner, ...}

Usage:
  uv run python3 convert_helpsteer3.py --output routellm/helpsteer3-battles.jsonl [--limit N]
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


def convert_preference(pref: int) -> str:
    """Convert HelpSteer3 overall_preference (-3..+3) to RouteLLM winner."""
    if pref < 0:
        return "model_a"  # response1 wins
    elif pref > 0:
        return "model_b"  # response2 wins
    else:
        return "tie"


def extract_prompt(context: list[dict]) -> str:
    """Extract the last user message as the comparison prompt."""
    for msg in reversed(context):
        if msg.get("role") == "user":
            return msg["content"]
    return context[-1]["content"] if context else ""


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[1])
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--limit", type=int, default=None,
                        help="max rows to convert (default: all)")
    parser.add_argument("--min-abs-pref", type=int, default=0,
                        help="minimum |overall_preference| to include (0=all, 1=exclude ties)")
    args = parser.parse_args()

    from datasets import load_dataset

    ds = load_dataset("nvidia/HelpSteer3", split="train", streaming=True)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    n = 0
    stats = {"model_a": 0, "model_b": 0, "tie": 0, "skipped": 0}

    with open(args.output, "w") as f:
        for row in ds:
            pref = row["overall_preference"]
            if abs(pref) < args.min_abs_pref:
                stats["skipped"] += 1
                continue

            winner = convert_preference(pref)
            stats[winner] += 1

            prompt = extract_prompt(row["context"])

            entry = {
                "id": f"hs3-{n:06d}",
                "source": "helpsteer3",
                "domain": row.get("domain", "unknown"),
                "language": row.get("language", "unknown"),
                "prompt": prompt[:2000],  # truncate for size
                "model_a": "helpsteer3-response1",
                "response_a": row["response1"][:4000],
                "model_b": "helpsteer3-response2",
                "response_b": row["response2"][:4000],
                "overall_preference": pref,
                "winner": winner,
            }
            f.write(json.dumps(entry, ensure_ascii=False) + "\n")
            n += 1

            if args.limit and n >= args.limit:
                break

            if n % 5000 == 0:
                print(f"  [{n}] a={stats['model_a']} b={stats['model_b']} tie={stats['tie']}", file=sys.stderr)

    print(f"[convert] wrote {n} entries to {args.output}")
    print(f"[convert] distribution: model_a={stats['model_a']} model_b={stats['model_b']} tie={stats['tie']} skipped={stats['skipped']}")


if __name__ == "__main__":
    main()
