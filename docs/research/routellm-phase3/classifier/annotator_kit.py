#!/usr/bin/env python3
"""
annotator_kit.py — Generate per-annotator JSONL/Markdown work packets.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path


LABELS = [
    "local_confident",
    "local_probable",
    "cloud_required",
    "hybrid",
    "unknown",
]


def load_jsonl(path: Path) -> list[dict]:
    return [json.loads(line) for line in path.read_text().splitlines() if line.strip()]


def write_jsonl(path: Path, entries: list[dict]) -> None:
    path.write_text("\n".join(json.dumps(entry, ensure_ascii=False) for entry in entries) + "\n")


def markdown_for_annotator(annotator: str, entries: list[dict], taxonomy_ref: str) -> str:
    lines = [
        f"# GT Labeling Packet: {annotator}",
        "",
        "Read the taxonomy guide before labeling.",
        f"Reference: `{taxonomy_ref}`",
        "",
        "Allowed labels:",
        "",
    ]
    for label in LABELS:
        lines.append(f"- `{label}`")
    lines.extend(
        [
            "",
            "For each item, decide the final `gt_label`, keep notes brief, and do not edit `id` or `prompt`.",
            "",
        ]
    )

    for index, entry in enumerate(entries, start=1):
        probs = entry.get("predicted_probs") or {}
        prob_text = ", ".join(f"{label}={probs.get(label, 0.0)}" for label in LABELS)
        lines.extend(
            [
                f"## {index}. {entry['id']}",
                "",
                f"- `session_id`: `{entry.get('session_id')}`",
                f"- `predicted_label`: `{entry.get('predicted_label')}`",
                f"- `predicted_confidence`: `{entry.get('predicted_confidence')}`",
                f"- `predicted_probs`: {prob_text}",
                f"- `length_bin`: `{entry.get('length_bin')}`",
                "",
                "### Prompt",
                "",
                "```text",
                entry["prompt"],
                "```",
                "",
                "### Fill Before Return",
                "",
                f"- `gt_label`: `[{ '|'.join(LABELS) }]`",
                "- `annotator_notes`: ``",
                "",
            ]
        )

    return "\n".join(lines) + "\n"


def shared_readme(taxonomy_ref: str, annotators: list[str]) -> str:
    lines = [
        "# GT Annotation Kit",
        "",
        "This directory contains one JSONL and one Markdown packet per annotator.",
        "",
        "## Procedure",
        "",
        "1. Read the taxonomy guide before editing anything.",
        "2. Fill only `gt_label` and `annotator_notes` in your JSONL copy.",
        "3. Keep `id`, `prompt`, `predicted_*`, and `session_id` unchanged.",
        "4. Return the completed JSONL file to the reviewer.",
        "",
        "## Taxonomy",
        "",
        f"- Primary reference: `{taxonomy_ref}`",
        "- Labels: `local_confident`, `local_probable`, `cloud_required`, `hybrid`, `unknown`",
        "",
        "## Prohibited",
        "",
        "- Do not share prompts outside the review team.",
        "- Do not paste prompt contents into external tools or hosted LLMs.",
        "- Do not rename files or rewrite record ids.",
        "",
        "## Annotators",
        "",
    ]
    lines.extend(f"- `{annotator}`" for annotator in annotators)
    lines.append("")
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--candidates", type=Path, required=True)
    parser.add_argument("--annotators", nargs="+", required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument(
        "--taxonomy-ref",
        default="../analysis/label-guide.md",
        help="Path shown inside generated markdown/readme.",
    )
    args = parser.parse_args()

    candidates = load_jsonl(args.candidates)
    args.output_dir.mkdir(parents=True, exist_ok=True)

    for annotator in args.annotators:
        entries = []
        for entry in candidates:
            cloned = dict(entry)
            cloned["gt_label"] = None
            cloned["annotator"] = annotator
            if "annotator_notes" not in cloned:
                cloned["annotator_notes"] = None
            entries.append(cloned)

        jsonl_path = args.output_dir / f"{annotator}.jsonl"
        md_path = args.output_dir / f"{annotator}.md"
        write_jsonl(jsonl_path, entries)
        md_path.write_text(markdown_for_annotator(annotator, entries, args.taxonomy_ref))
        print(f"[annotator-kit] wrote {jsonl_path}")
        print(f"[annotator-kit] wrote {md_path}")

    readme_path = args.output_dir / "README.md"
    readme_path.write_text(shared_readme(args.taxonomy_ref, args.annotators))
    print(f"[annotator-kit] wrote {readme_path}")


if __name__ == "__main__":
    main()
