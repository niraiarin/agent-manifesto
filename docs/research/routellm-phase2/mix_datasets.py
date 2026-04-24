#!/usr/bin/env python3
"""
mix_datasets.py — Mix Phase 1 domain preference data with HelpSteer3 general data.

Creates mixed datasets with different domain oversampling ratios for RouteLLM training.

Usage:
  uv run python3 mix_datasets.py \
    --domain ../golden-dataset/routellm/preference-data-threshold-0.3.jsonl \
    --general routellm/helpsteer3-battles.jsonl \
    --output-dir routellm/mixed \
    --ratios 1,5,10,20
"""

from __future__ import annotations

import argparse
import json
import random
from pathlib import Path


def load_jsonl(path: Path) -> list[dict]:
    with open(path) as f:
        return [json.loads(line) for line in f if line.strip()]


def normalize_schema(entry: dict, source_label: str) -> dict:
    """Ensure consistent schema across domain and general data."""
    return {
        "id": entry.get("id", "unknown"),
        "source": source_label,
        "prompt": entry.get("prompt", entry.get("input_data", {}).get("prompt", "")),
        "model_a": entry.get("model_a", "unknown"),
        "response_a": entry.get("response_a", ""),
        "model_b": entry.get("model_b", "unknown"),
        "response_b": entry.get("response_b", ""),
        "winner": entry.get("winner", "tie"),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[1])
    parser.add_argument("--domain", type=Path, required=True)
    parser.add_argument("--general", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--ratios", type=str, default="1,5,10,20",
                        help="comma-separated domain oversampling ratios")
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args()

    random.seed(args.seed)

    domain_raw = load_jsonl(args.domain)
    general_raw = load_jsonl(args.general)

    domain = [normalize_schema(e, "domain-phase1") for e in domain_raw]
    general = [normalize_schema(e, "helpsteer3") for e in general_raw]

    args.output_dir.mkdir(parents=True, exist_ok=True)
    ratios = [int(r) for r in args.ratios.split(",")]

    print(f"[mix] domain={len(domain)} general={len(general)}")

    for ratio in ratios:
        oversampled = domain * ratio
        mixed = oversampled + general
        random.shuffle(mixed)

        out_path = args.output_dir / f"mixed-ratio-{ratio}x.jsonl"
        with open(out_path, "w") as f:
            for entry in mixed:
                f.write(json.dumps(entry, ensure_ascii=False) + "\n")

        domain_count = sum(1 for e in mixed if e["source"] == "domain-phase1")
        general_count = sum(1 for e in mixed if e["source"] == "helpsteer3")
        domain_pct = domain_count / len(mixed) * 100

        print(f"[mix] ratio={ratio}x: {len(mixed)} total (domain={domain_count} [{domain_pct:.1f}%], general={general_count})")

    # Also emit general-only and domain-only for ablation
    with open(args.output_dir / "general-only.jsonl", "w") as f:
        for e in general:
            f.write(json.dumps(e, ensure_ascii=False) + "\n")
    print(f"[mix] general-only: {len(general)}")

    with open(args.output_dir / "domain-only.jsonl", "w") as f:
        for e in domain:
            f.write(json.dumps(e, ensure_ascii=False) + "\n")
    print(f"[mix] domain-only: {len(domain)}")


if __name__ == "__main__":
    main()
