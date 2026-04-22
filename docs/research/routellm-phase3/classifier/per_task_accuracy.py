#!/usr/bin/env python3
"""
per_task_accuracy.py — #653 Phase 5: task-level accuracy breakdown.

label_data.py の TASK_SEED_PROMPTS は (task, label, prompt) 3-tuple なので task 名が保持される。
eval set の各 entry の `task` field で group by して per-task accuracy を集計。

目的: 24 taxonomy task のうち何 task が training coverage あり、各 task の
production-readiness を測定。
"""

from __future__ import annotations

import argparse
import json
from collections import defaultdict
from pathlib import Path


LABEL_TO_ID = {"local_confident": 0, "local_probable": 1, "cloud_required": 2, "hybrid": 3, "unknown": 4}
ID_TO_LABEL = {v: k for k, v in LABEL_TO_ID.items()}
LOCAL = {"local_confident", "local_probable"}
CLOUD = {"cloud_required", "hybrid", "unknown"}


def normalize_task(task: str) -> str:
    """Collapse -long / -3 / variant suffixes to base task name."""
    for suffix in ("-long", "-long-3", "-long-2", "-2", "-3", "-4", "-5"):
        if task.endswith(suffix):
            return task[:-len(suffix)]
    return task


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--eval-set", type=Path, required=True)
    parser.add_argument("--train-set", type=Path, required=True, help="for coverage check")
    parser.add_argument("--model-dir", type=Path, required=True)
    parser.add_argument("--output", type=Path, default=Path("../analysis/per-task-accuracy.md"))
    args = parser.parse_args()

    import joblib
    import numpy as np
    from sentence_transformers import SentenceTransformer

    meta = json.load(open(args.model_dir / "metadata.json"))
    clf = joblib.load(args.model_dir / "clf.joblib")
    enc = SentenceTransformer(meta["encoder"])

    eval_data = [json.loads(l) for l in args.eval_set.read_text().splitlines() if l.strip()]
    train_data = [json.loads(l) for l in args.train_set.read_text().splitlines() if l.strip()]

    # Train coverage by task
    train_tasks = defaultdict(int)
    for e in train_data:
        train_tasks[normalize_task(e.get("task", "unknown"))] += 1

    # Eval by task
    X = enc.encode([f"query: {e['prompt']}" for e in eval_data], convert_to_numpy=True, batch_size=32, show_progress_bar=False)
    y = np.array([LABEL_TO_ID[e["label"]] for e in eval_data])
    probs = clf.predict_proba(X)
    preds = probs.argmax(axis=1)
    confs = probs.max(axis=1)

    by_task: dict[str, dict] = {}
    for i, e in enumerate(eval_data):
        task = normalize_task(e.get("task", "unknown"))
        if task not in by_task:
            by_task[task] = {"n": 0, "correct": 0, "routing_correct": 0, "confs": [], "label": e["label"]}
        by_task[task]["n"] += 1
        pred_label = ID_TO_LABEL[int(preds[i])]
        if pred_label == e["label"]:
            by_task[task]["correct"] += 1
        # Routing direction match
        pred_local = pred_label in LOCAL
        true_local = e["label"] in LOCAL
        if pred_local == true_local:
            by_task[task]["routing_correct"] += 1
        by_task[task]["confs"].append(float(confs[i]))

    # Output
    print(f"[per-task] eval n={len(eval_data)} covering {len(by_task)} tasks (train has {len(train_tasks)} tasks)\n")
    print(f"{'task':<25} {'n':>3} {'label':<18} {'acc':>6} {'route_acc':>10} {'mean_conf':>10} {'train_n':>8}")

    rows = []
    for task, stats in sorted(by_task.items(), key=lambda x: -x[1]["n"]):
        acc = stats["correct"] / stats["n"] if stats["n"] else 0
        r_acc = stats["routing_correct"] / stats["n"] if stats["n"] else 0
        mean_conf = sum(stats["confs"]) / len(stats["confs"]) if stats["confs"] else 0
        tr_n = train_tasks.get(task, 0)
        rows.append({
            "task": task,
            "label": stats["label"],
            "n_eval": stats["n"],
            "accuracy": round(acc, 3),
            "routing_accuracy": round(r_acc, 3),
            "mean_confidence": round(mean_conf, 3),
            "n_train": tr_n,
        })
        print(f"{task:<25} {stats['n']:>3} {stats['label']:<18} {acc:>6.3f} {r_acc:>10.3f} {mean_conf:>10.3f} {tr_n:>8}")

    # Identify weak tasks (routing accuracy < 0.80)
    weak = [r for r in rows if r["routing_accuracy"] < 0.80 and r["n_eval"] >= 2]
    if weak:
        print(f"\n[per-task] weak tasks (routing_acc < 0.80, n >= 2):")
        for w in weak:
            print(f"  {w['task']}: {w['routing_accuracy']:.3f} (n={w['n_eval']}, train_n={w['n_train']})")

    # Write markdown report
    args.output.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        "# Per-task Accuracy Breakdown (#653 Phase 5)",
        "",
        f"Eval n={len(eval_data)}. Tasks with coverage: {len(by_task)}.",
        "",
        "## Per-task results",
        "",
        "| Task | Label | n_eval | n_train | Accuracy | Routing acc | Mean conf |",
        "|------|-------|--------|---------|----------|-------------|-----------|",
    ]
    for r in rows:
        lines.append(f"| {r['task']} | {r['label']} | {r['n_eval']} | {r['n_train']} | {r['accuracy']:.3f} | {r['routing_accuracy']:.3f} | {r['mean_confidence']:.3f} |")

    # Weak tasks section
    lines.append("")
    lines.append("## Weak tasks (routing acc < 0.80)")
    lines.append("")
    if weak:
        for w in weak:
            lines.append(f"- **{w['task']}**: routing_acc={w['routing_accuracy']:.3f}, n_eval={w['n_eval']}, n_train={w['n_train']} — may need more training variants")
    else:
        lines.append("なし。全 task で routing_acc ≥ 0.80.")

    # Train coverage gap
    train_task_set = set(train_tasks.keys())
    eval_task_set = set(by_task.keys())
    train_only = train_task_set - eval_task_set
    eval_only = eval_task_set - train_task_set
    lines.append("")
    lines.append("## Coverage gap")
    lines.append("")
    lines.append(f"- Train only (no eval coverage): {len(train_only)} tasks")
    if train_only:
        lines.append(f"  - {', '.join(sorted(train_only))}")
    lines.append(f"- Eval only (no train coverage): {len(eval_only)} tasks")
    if eval_only:
        lines.append(f"  - {', '.join(sorted(eval_only))}")

    args.output.write_text("\n".join(lines) + "\n")
    print(f"\n[per-task] wrote {args.output}")


if __name__ == "__main__":
    main()
