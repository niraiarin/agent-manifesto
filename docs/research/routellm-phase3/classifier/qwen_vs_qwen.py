#!/usr/bin/env python3
"""
qwen_vs_qwen.py — Compare two Qwen label JSONLs on the same candidate set.

Reports Cohen's kappa, overall agreement, per-label confusion, and per-label
distribution delta. Designed for A/B comparison of Qwen quantization variants
(e.g., 35B-A3B Q2 vs 27B Q4) to gauge whether they produce consistent labels.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from pathlib import Path


LABELS = ["local_confident", "local_probable", "cloud_required", "hybrid", "unknown"]


def load_jsonl(path: Path) -> list[dict]:
    return [json.loads(line) for line in path.read_text().splitlines() if line.strip()]


def label_map(entries: list[dict]) -> dict[str, str]:
    result = {}
    for entry in entries:
        cid = entry.get("id")
        gt = entry.get("gt_label")
        if cid and gt in LABELS:
            result[cid] = gt
    return result


def confusion(a: dict[str, str], b: dict[str, str]) -> list[list[int]]:
    matrix = [[0 for _ in LABELS] for _ in LABELS]
    for cid in sorted(set(a) & set(b)):
        matrix[LABELS.index(a[cid])][LABELS.index(b[cid])] += 1
    return matrix


def cohen_kappa(a: dict[str, str], b: dict[str, str]) -> float:
    keys = sorted(set(a) & set(b))
    if not keys:
        return 0.0
    agreement = sum(1 for k in keys if a[k] == b[k]) / len(keys)
    ca = Counter(a[k] for k in keys)
    cb = Counter(b[k] for k in keys)
    n = len(keys)
    expected = sum((ca[l] / n) * (cb[l] / n) for l in LABELS)
    if expected == 1.0:
        return 1.0
    return (agreement - expected) / (1.0 - expected)


def render_matrix(matrix: list[list[int]], left_name: str, right_name: str) -> str:
    header = f"  {left_name} \\ {right_name}"
    lines = [header, "  rows=" + left_name + ", cols=" + right_name, ""]
    cols = " ".join(f"{l[:10]:>10}" for l in LABELS)
    lines.append(f"{'':>18}  {cols}")
    for i, label in enumerate(LABELS):
        row = " ".join(f"{matrix[i][j]:>10}" for j in range(len(LABELS)))
        lines.append(f"{label:>18}  {row}")
    return "\n".join(lines)


def distribution(labels: dict[str, str]) -> Counter:
    return Counter(labels.values())


def classifier_agreement(entries: list[dict]) -> tuple[int, int]:
    """How often does this annotator agree with the classifier's predicted_label?"""
    match = 0
    total = 0
    for entry in entries:
        gt = entry.get("gt_label")
        pred = entry.get("predicted_label")
        if gt in LABELS and pred in LABELS:
            total += 1
            if gt == pred:
                match += 1
    return match, total


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--a", type=Path, required=True, help="First annotator jsonl (e.g. qwen 35B)")
    parser.add_argument("--a-name", default="A")
    parser.add_argument("--b", type=Path, required=True, help="Second annotator jsonl (e.g. qwen 27B)")
    parser.add_argument("--b-name", default="B")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    a_entries = load_jsonl(args.a)
    b_entries = load_jsonl(args.b)

    a_labels = label_map(a_entries)
    b_labels = label_map(b_entries)

    overlap = sorted(set(a_labels) & set(b_labels))
    print(f"[compare] {args.a_name}: {len(a_labels)} labels; {args.b_name}: {len(b_labels)} labels; overlap: {len(overlap)}")

    kappa = cohen_kappa(a_labels, b_labels)
    agreement_count = sum(1 for cid in overlap if a_labels[cid] == b_labels[cid])
    agreement = agreement_count / len(overlap) if overlap else 0.0

    matrix = confusion(a_labels, b_labels)
    a_dist = distribution(a_labels)
    b_dist = distribution(b_labels)

    a_classifier_match, a_classifier_total = classifier_agreement(a_entries)
    b_classifier_match, b_classifier_total = classifier_agreement(b_entries)

    lines = [
        f"# Qwen A/B Agreement Analysis",
        "",
        f"- A: `{args.a_name}` from `{args.a.name}` ({len(a_labels)} items)",
        f"- B: `{args.b_name}` from `{args.b.name}` ({len(b_labels)} items)",
        f"- Overlap: {len(overlap)} items",
        "",
        f"## Summary",
        "",
        f"- Overall agreement: **{agreement:.4f}** ({agreement_count}/{len(overlap)})",
        f"- Cohen's kappa: **{kappa:.4f}**",
        f"- {args.a_name} vs. mDeBERTa classifier: {a_classifier_match}/{a_classifier_total} = {a_classifier_match / a_classifier_total if a_classifier_total else 0:.4f}",
        f"- {args.b_name} vs. mDeBERTa classifier: {b_classifier_match}/{b_classifier_total} = {b_classifier_match / b_classifier_total if b_classifier_total else 0:.4f}",
        "",
        f"## Label distribution",
        "",
        "| Label | " + args.a_name + " | " + args.b_name + " | delta |",
        "|---|---:|---:|---:|",
    ]
    for label in LABELS:
        a_count = a_dist.get(label, 0)
        b_count = b_dist.get(label, 0)
        lines.append(f"| {label} | {a_count} | {b_count} | {b_count - a_count:+d} |")
    lines.append("")

    lines.extend(
        [
            f"## Confusion matrix ({args.a_name} rows × {args.b_name} columns)",
            "",
            "```text",
            render_matrix(matrix, args.a_name, args.b_name),
            "```",
            "",
        ]
    )

    disagreements = [cid for cid in overlap if a_labels[cid] != b_labels[cid]]
    if disagreements:
        lines.append(f"## Disagreements sample (up to 20 of {len(disagreements)})")
        lines.append("")
        lines.append(f"| id | {args.a_name} | {args.b_name} | predicted | prompt preview |")
        lines.append("|---|---|---|---|---|")
        preview_a = {entry["id"]: entry for entry in a_entries if entry.get("id")}
        for cid in disagreements[:20]:
            entry = preview_a.get(cid, {})
            prompt = (entry.get("prompt") or "").replace("\n", " ").replace("|", "\\|")[:60]
            predicted = entry.get("predicted_label", "?")
            lines.append(f"| {cid} | {a_labels[cid]} | {b_labels[cid]} | {predicted} | {prompt}... |")
        lines.append("")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text("\n".join(lines))
    print(f"[compare] wrote {args.output}")
    print(f"[compare] agreement={agreement:.4f} kappa={kappa:.4f}")


if __name__ == "__main__":
    main()
