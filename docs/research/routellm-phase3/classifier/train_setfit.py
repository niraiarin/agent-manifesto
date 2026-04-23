#!/usr/bin/env python3
"""
train_setfit.py — #653 Phase 1: SetFit contrastive classifier.

既存 e5-small embedding を SetFit (contrastive fine-tune + head classifier) で学習。
class imbalance に強く、100 GT で従来の LR を超える精度を狙う。

Reference: https://huggingface.co/blog/setfit
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path


LABELS = ["local_confident", "local_probable", "cloud_required", "hybrid", "unknown"]
LOCAL = {"local_confident", "local_probable"}
CLOUD = {"cloud_required", "hybrid", "unknown"}


def load_jsonl(path: Path) -> list[dict]:
    with open(path) as f:
        return [json.loads(line) for line in f if line.strip()]


def grade_on_gt(model, labeled):
    """Compute metrics on labeled GT (has gt_label or label field)."""
    prompts = [e["prompt"] for e in labeled]
    gt_labels = [e.get("gt_label") or e.get("label") for e in labeled]

    preds = model.predict(prompts)
    if hasattr(preds, "tolist"):
        preds = preds.tolist()

    n = len(labeled)
    exact = sum(1 for p, g in zip(preds, gt_labels) if p == g)
    leak = sum(1 for p, g in zip(preds, gt_labels) if g in CLOUD and p in LOCAL)
    over = sum(1 for p, g in zip(preds, gt_labels) if g in LOCAL and p in CLOUD)
    route_correct = sum(1 for p, g in zip(preds, gt_labels) if (p in LOCAL) == (g in LOCAL))

    return {
        "n": n,
        "exact_accuracy": exact / n,
        "routing_accuracy": route_correct / n,
        "leak_rate": leak / n,
        "over_cautious_rate": over / n,
        "local_predictions": sum(1 for p in preds if p in LOCAL),
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--train", type=Path, required=True)
    parser.add_argument("--eval-taxonomy", type=Path, required=True, help="taxonomy labeled set")
    parser.add_argument("--gt-holdout", type=Path, default=None, help="real GT hold-out")
    parser.add_argument("--model-out", type=Path, required=True)
    parser.add_argument("--encoder", type=str, default="intfloat/multilingual-e5-small")
    parser.add_argument("--num-iterations", type=int, default=20)
    parser.add_argument("--epochs", type=int, default=1)
    parser.add_argument("--batch-size", type=int, default=16)
    args = parser.parse_args()

    import os
    # Force CPU if MPS is OOM-prone on this 24GB Mac
    os.environ.setdefault("PYTORCH_MPS_HIGH_WATERMARK_RATIO", "0.0")
    import torch
    torch.set_default_device("cpu")

    from datasets import Dataset
    from setfit import SetFitModel, Trainer, TrainingArguments

    train = load_jsonl(args.train)
    taxonomy = load_jsonl(args.eval_taxonomy)

    print(f"[setfit] train={len(train)} taxonomy-eval={len(taxonomy)}")
    gt_ho = None
    if args.gt_holdout:
        gt_ho = load_jsonl(args.gt_holdout)
        print(f"[setfit] gt_holdout={len(gt_ho)}")

    def to_dataset(items):
        return Dataset.from_dict({
            "text": [e["prompt"] for e in items],
            "label": [e.get("label") or e.get("gt_label") for e in items],
        })

    train_ds = to_dataset(train)
    tax_ds = to_dataset(taxonomy)

    model = SetFitModel.from_pretrained(
        args.encoder,
        labels=LABELS,
        device="cpu",  # MPS OOM on 24GB Mac with concurrent llama-server
    )

    training_args = TrainingArguments(
        batch_size=args.batch_size,
        num_epochs=args.epochs,
        num_iterations=args.num_iterations,
        output_dir=str(args.model_out / "_training"),
    )

    trainer = Trainer(
        model=model,
        args=training_args,
        train_dataset=train_ds,
        eval_dataset=tax_ds,
        metric="accuracy",
    )

    print(f"[setfit] training (iterations={args.num_iterations}, epochs={args.epochs})...")
    trainer.train()

    print("\n=== Evaluation ===")
    print(f"\n[setfit] taxonomy eval (n={len(taxonomy)}):")
    tax_metrics = grade_on_gt(model, taxonomy)
    for k, v in tax_metrics.items():
        print(f"  {k}: {v:.4f}" if isinstance(v, float) else f"  {k}: {v}")

    gt_metrics = None
    if gt_ho:
        print(f"\n[setfit] GT hold-out (n={len(gt_ho)}):")
        gt_metrics = grade_on_gt(model, gt_ho)
        for k, v in gt_metrics.items():
            print(f"  {k}: {v:.4f}" if isinstance(v, float) else f"  {k}: {v}")

    args.model_out.mkdir(parents=True, exist_ok=True)
    model.save_pretrained(str(args.model_out / "setfit_model"))

    metadata = {
        "model_type": "setfit",
        "encoder": args.encoder,
        "labels": LABELS,
        "num_iterations": args.num_iterations,
        "epochs": args.epochs,
        "train_n": len(train),
        "taxonomy_eval_metrics": tax_metrics,
    }
    if gt_metrics:
        metadata["gt_holdout_metrics"] = gt_metrics

    (args.model_out / "setfit_metadata.json").write_text(json.dumps(metadata, indent=2))
    print(f"\n[setfit] saved → {args.model_out}")


if __name__ == "__main__":
    main()
