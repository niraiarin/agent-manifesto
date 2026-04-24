#!/usr/bin/env python3
"""
qwen_vs_opus.py — Agreement analysis between Qwen and Opus pseudo-GT.

Since the 100-candidate Opus labels are keyed by gt-NNN id (and the
original candidates file is gitignored), we reconstruct the overlap by
matching Qwen outputs with Opus labels using session_id + prompt prefix
against a reference candidates file (optional) or just list Qwen's
distribution when no overlap exists.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
from collections import Counter
from pathlib import Path

LABELS = ["local_confident", "local_probable", "cloud_required", "hybrid", "unknown"]


def load_jsonl(path: Path) -> list[dict]:
    return [json.loads(line) for line in path.read_text().splitlines() if line.strip()]


def load_opus_labels(path: Path) -> dict[str, tuple[str, str]]:
    spec = importlib.util.spec_from_file_location("opus_labels", path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"failed to load {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return {item[0]: (item[1], item[2]) for item in getattr(module, "OPUS_LABELS", [])}


def confusion(left: dict[str, str], right: dict[str, str]) -> list[list[int]]:
    matrix = [[0 for _ in LABELS] for _ in LABELS]
    for key in sorted(set(left) & set(right)):
        matrix[LABELS.index(left[key])][LABELS.index(right[key])] += 1
    return matrix


def cohen_kappa(left: dict[str, str], right: dict[str, str]) -> float:
    keys = sorted(set(left) & set(right))
    if not keys:
        return 0.0
    agreement = sum(1 for key in keys if left[key] == right[key]) / len(keys)
    left_counts = Counter(left[key] for key in keys)
    right_counts = Counter(right[key] for key in keys)
    expected = sum(
        (left_counts[label] / len(keys)) * (right_counts[label] / len(keys))
        for label in LABELS
    )
    if expected == 1.0:
        return 1.0
    return (agreement - expected) / (1.0 - expected)


def render_matrix(matrix: list[list[int]]) -> str:
    header = "                   " + " ".join(f"{label[:10]:>10}" for label in LABELS)
    lines = [header]
    for index, label in enumerate(LABELS):
        row = f"{label:>18} " + " ".join(f"{value:>10}" for value in matrix[index])
        lines.append(row)
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--qwen", type=Path, required=True, help="qwen-labels-500.jsonl")
    parser.add_argument("--opus-source", type=Path, required=True, help="opus_labels.py")
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument(
        "--candidates-ref",
        type=Path,
        help="Optional candidates jsonl that includes the original gt-NNN ids used by opus_labels. "
        "If provided, we match Qwen entries to Opus ids by session_id + prompt[:100].",
    )
    args = parser.parse_args()

    qwen_entries = load_jsonl(args.qwen)
    opus = load_opus_labels(args.opus_source)
    print(f"[qwen-vs-opus] qwen={len(qwen_entries)} opus={len(opus)}")

    qwen_labels: dict[str, str] = {}
    if args.candidates_ref and args.candidates_ref.exists():
        ref_entries = load_jsonl(args.candidates_ref)
        ref_index = {
            (str(entry.get("session_id") or ""), (entry.get("prompt") or "")[:100]): entry.get("id")
            for entry in ref_entries
        }
        for entry in qwen_entries:
            key = (str(entry.get("session_id") or ""), (entry.get("prompt") or "")[:100])
            mapped_id = ref_index.get(key)
            if mapped_id and mapped_id in opus:
                qwen_labels[mapped_id] = entry.get("gt_label")
    else:
        for entry in qwen_entries:
            cid = entry.get("id")
            if cid in opus:
                qwen_labels[cid] = entry.get("gt_label")

    opus_labels = {key: value[0] for key, value in opus.items() if key in qwen_labels}
    qwen_labels = {key: value for key, value in qwen_labels.items() if key in opus_labels}

    overlap_count = len(qwen_labels)
    lines: list[str] = ["# Qwen vs Opus Agreement", ""]
    lines.append(f"- Qwen labeled entries: {len(qwen_entries)}")
    lines.append(f"- Opus labels available: {len(opus)}")
    lines.append(f"- Overlap (matched ids): {overlap_count}")
    lines.append("")

    if overlap_count == 0:
        lines.append(
            "Overlap is zero. Qwen candidates do not share ids with `opus_labels.OPUS_LABELS`."
        )
        lines.append(
            "Provide `--candidates-ref` pointing to a JSONL containing gt-NNN ids matching"
            " the Opus set, or relabel the existing gt-000..gt-099 candidates via Qwen."
        )
    else:
        if overlap_count < 30:
            lines.append(
                f"**WARNING**: overlap {overlap_count} < 30. Cohen's kappa is unreliable."
            )
            lines.append("")

        kappa = cohen_kappa(qwen_labels, opus_labels)
        agreement = sum(1 for key in qwen_labels if qwen_labels[key] == opus_labels[key]) / overlap_count
        lines.append(f"- Overall agreement: {agreement:.4f}")
        lines.append(f"- Cohen's kappa: {kappa:.4f}")
        lines.append("")

        matrix = confusion(qwen_labels, opus_labels)
        lines.append("## Confusion matrix (Qwen rows vs Opus columns)")
        lines.append("")
        lines.append("```text")
        lines.append(render_matrix(matrix))
        lines.append("```")
        lines.append("")

        disagreements = [
            key for key in sorted(qwen_labels) if qwen_labels[key] != opus_labels[key]
        ]
        if disagreements:
            lines.append(f"## Top disagreements (up to 20 of {len(disagreements)})")
            lines.append("")
            lines.append("| id | Qwen | Opus | Opus rationale |")
            lines.append("|---|---|---|---|")
            for key in disagreements[:20]:
                rationale = opus[key][1].replace("|", "\\|")
                lines.append(f"| {key} | {qwen_labels[key]} | {opus_labels[key]} | {rationale} |")
            lines.append("")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text("\n".join(lines))
    print(f"[qwen-vs-opus] wrote {args.output}")


if __name__ == "__main__":
    main()
