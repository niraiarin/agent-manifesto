#!/usr/bin/env python3
"""
kappa.py — Inter-annotator agreement metrics for GT labeling.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter, defaultdict
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


def confusion_matrix(left: dict[str, str], right: dict[str, str]) -> list[list[int]]:
    matrix = [[0 for _ in LABELS] for _ in LABELS]
    for item_id in sorted(set(left) & set(right)):
        matrix[LABELS.index(left[item_id])][LABELS.index(right[item_id])] += 1
    return matrix


def cohen_kappa(left: dict[str, str], right: dict[str, str]) -> float:
    item_ids = sorted(set(left) & set(right))
    if not item_ids:
        return 0.0
    agreement = sum(1 for item_id in item_ids if left[item_id] == right[item_id]) / len(item_ids)

    left_counts = Counter(left[item_id] for item_id in item_ids)
    right_counts = Counter(right[item_id] for item_id in item_ids)
    expected = sum((left_counts[label] / len(item_ids)) * (right_counts[label] / len(item_ids)) for label in LABELS)
    if expected == 1.0:
        return 1.0
    return (agreement - expected) / (1.0 - expected)


def fleiss_kappa(assignments: dict[str, list[str]]) -> float:
    if not assignments:
        return 0.0

    counts_per_item = []
    for labels in assignments.values():
        counts = [labels.count(label) for label in LABELS]
        counts_per_item.append(counts)

    n_items = len(counts_per_item)
    n_raters = sum(counts_per_item[0])
    if n_raters <= 1:
        return 1.0

    p_j = [sum(item[label_idx] for item in counts_per_item) / (n_items * n_raters) for label_idx in range(len(LABELS))]
    p_bar = sum(
        (sum(count * count for count in item) - n_raters) / (n_raters * (n_raters - 1))
        for item in counts_per_item
    ) / n_items
    p_e = sum(probability * probability for probability in p_j)
    if p_e == 1.0:
        return 1.0
    return (p_bar - p_e) / (1.0 - p_e)


def majority_vote(records: list[dict[str, str]], source_entries: dict[str, dict]) -> list[dict]:
    votes: dict[str, list[str]] = defaultdict(list)
    for record in records:
        votes[record["id"]].append(record["gt_label"])

    majority = []
    for item_id in sorted(votes):
        counter = Counter(votes[item_id])
        winner, winner_count = sorted(counter.items(), key=lambda item: (-item[1], item[0]))[0]
        entry = dict(source_entries[item_id])
        entry["gt_label"] = winner
        entry["majority_count"] = winner_count
        entry["vote_counts"] = {label: counter.get(label, 0) for label in LABELS}
        majority.append(entry)
    return majority


def agreement_against_reference(reference: dict[str, str], target: dict[str, str]) -> float | None:
    item_ids = sorted(set(reference) & set(target))
    if not item_ids:
        return None
    return sum(1 for item_id in item_ids if reference[item_id] == target[item_id]) / len(item_ids)


def parse_annotation_file(path: Path) -> tuple[str, list[dict]]:
    entries = load_jsonl(path)
    annotator = entries[0].get("annotator") if entries else path.stem
    rows = []
    for entry in entries:
        label = entry.get("gt_label")
        if label not in LABELS:
            continue
        rows.append({"id": entry["id"], "gt_label": label, "entry": entry})
    return annotator or path.stem, rows


def run_test_mode() -> None:
    perfect_a = {"x": "cloud_required", "y": "hybrid", "z": "unknown"}
    perfect_b = {"x": "cloud_required", "y": "hybrid", "z": "unknown"}
    disagree_a = {"x": "cloud_required", "y": "hybrid", "z": "unknown", "w": "local_confident"}
    disagree_b = {"x": "local_confident", "y": "hybrid", "z": "local_probable", "w": "cloud_required"}
    triple = {
        "a": ["cloud_required", "cloud_required", "cloud_required"],
        "b": ["hybrid", "hybrid", "hybrid"],
        "c": ["local_confident", "local_probable", "local_confident"],
    }

    assert abs(cohen_kappa(perfect_a, perfect_b) - 1.0) < 1e-9
    assert cohen_kappa(disagree_a, disagree_b) < 0.5
    assert fleiss_kappa(triple) > 0.4
    print("PASS kappa --test")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--annotations", nargs="+", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--majority-output", type=Path)
    parser.add_argument("--pseudo-gt", type=Path)
    parser.add_argument("--test", action="store_true")
    args = parser.parse_args()

    if args.test:
        run_test_mode()
        return

    if not args.annotations or not args.output:
        parser.error("--annotations and --output are required unless --test is used")

    annotator_rows: dict[str, dict[str, str]] = {}
    source_entries: dict[str, dict] = {}
    flat_records: list[dict[str, str]] = []

    for path in args.annotations:
        annotator, rows = parse_annotation_file(path)
        annotator_rows[annotator] = {row["id"]: row["gt_label"] for row in rows}
        for row in rows:
            source_entries.setdefault(row["id"], row["entry"])
            flat_records.append({"id": row["id"], "gt_label": row["gt_label"]})

    pairwise = []
    annotators = sorted(annotator_rows)
    for idx, left_name in enumerate(annotators):
        for right_name in annotators[idx + 1 :]:
            left = annotator_rows[left_name]
            right = annotator_rows[right_name]
            pairwise.append(
                {
                    "annotators": [left_name, right_name],
                    "cohen_kappa": round(cohen_kappa(left, right), 4),
                    "confusion_matrix": confusion_matrix(left, right),
                }
            )

    assignments: dict[str, list[str]] = defaultdict(list)
    for annotator in annotators:
        for item_id, label in annotator_rows[annotator].items():
            assignments[item_id].append(label)

    majority = majority_vote(flat_records, source_entries)
    majority_labels = {entry["id"]: entry["gt_label"] for entry in majority}

    pseudo_gt_agreement = None
    if args.pseudo_gt:
        pseudo_entries = load_jsonl(args.pseudo_gt)
        pseudo_map = {
            entry["id"]: entry["gt_label"]
            for entry in pseudo_entries
            if entry.get("gt_label") in LABELS
        }
        pseudo_gt_agreement = {
            "majority_vote": agreement_against_reference(pseudo_map, majority_labels),
            "per_annotator": {
                annotator: agreement_against_reference(pseudo_map, labels)
                for annotator, labels in annotator_rows.items()
            },
        }

    report = {
        "annotators": annotators,
        "n_items": len(assignments),
        "pairwise": pairwise,
        "fleiss_kappa": round(fleiss_kappa(assignments), 4) if len(annotators) >= 3 else None,
        "majority_vote": [
            {
                "id": entry["id"],
                "gt_label": entry["gt_label"],
                "majority_count": entry["majority_count"],
                "vote_counts": entry["vote_counts"],
            }
            for entry in majority
        ],
        "pseudo_gt_agreement": pseudo_gt_agreement,
    }

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n")
    print(f"[kappa] wrote {args.output}")

    if args.majority_output or len(annotators) >= 3:
        majority_output = args.majority_output or args.output.with_suffix(".majority.jsonl")
        majority_output.write_text("\n".join(json.dumps(entry, ensure_ascii=False) for entry in majority) + "\n")
        print(f"[kappa] wrote {majority_output}")


if __name__ == "__main__":
    main()
