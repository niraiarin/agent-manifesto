#!/usr/bin/env python3
"""
train_encoder.py — lightweight encoder full fine-tune comparison.

Qwen 0.5B LoRA failed (overfitting), so switch to encoder (280M) full fine-tune.
Encoders are classification-native and handle 680 samples without overfit.

Candidates:
  - jhu-clsp/mmBERT-base        (280M, ModernBERT multilingual)
  - microsoft/mdeberta-v3-base  (280M, JA classification SOTA 2025)
  - xlm-roberta-base            (278M, classic multilingual baseline)
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path


LABELS = ["local_confident", "local_probable", "cloud_required", "hybrid", "unknown"]
LABEL2ID = {l: i for i, l in enumerate(LABELS)}
ID2LABEL = {i: l for i, l in enumerate(LABELS)}
LOCAL = {"local_confident", "local_probable"}
CLOUD = {"cloud_required", "hybrid", "unknown"}


def load_jsonl(path: Path) -> list[dict]:
    with open(path) as f:
        return [json.loads(line) for line in f if line.strip()]


def grade_on_gt(model, tokenizer, labeled, device):
    import torch
    model.eval()
    prompts = [e["prompt"] for e in labeled]
    gt_labels = [e.get("gt_label") or e.get("label") for e in labeled]

    preds = []
    with torch.no_grad():
        for p in prompts:
            inputs = tokenizer(p, return_tensors="pt", truncation=True, max_length=512)
            inputs = {k: v.to(device) for k, v in inputs.items()}
            out = model(**inputs)
            pred_id = int(out.logits.argmax(dim=-1).item())
            preds.append(ID2LABEL[pred_id])

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
    parser.add_argument("--validate-taxonomy", type=Path, required=True)
    parser.add_argument("--gt-holdout", type=Path, default=None)
    parser.add_argument("--model-out", type=Path, required=True)
    parser.add_argument("--base-model", type=str, required=True)
    parser.add_argument("--epochs", type=int, default=3)
    parser.add_argument("--batch-size", type=int, default=16)
    parser.add_argument("--lr", type=float, default=2e-5)
    parser.add_argument("--max-length", type=int, default=512)
    args = parser.parse_args()

    import os
    os.environ.setdefault("TOKENIZERS_PARALLELISM", "false")
    os.environ.setdefault("PYTORCH_MPS_HIGH_WATERMARK_RATIO", "0.0")

    import torch
    from transformers import AutoTokenizer, AutoModelForSequenceClassification, TrainingArguments, Trainer
    from datasets import Dataset

    if torch.backends.mps.is_available():
        device = "mps"
    elif torch.cuda.is_available():
        device = "cuda"
    else:
        device = "cpu"
    print(f"[encoder] base={args.base_model} device={device}")

    train = load_jsonl(args.train)
    taxonomy = load_jsonl(args.validate_taxonomy)
    gt_ho = load_jsonl(args.gt_holdout) if args.gt_holdout else None
    print(f"[encoder] train={len(train)} tax={len(taxonomy)} gt_holdout={len(gt_ho) if gt_ho else 0}")

    tokenizer = AutoTokenizer.from_pretrained(args.base_model, trust_remote_code=True, fix_mistral_regex=True)
    if tokenizer.pad_token is None:
        tokenizer.pad_token = tokenizer.eos_token

    model = AutoModelForSequenceClassification.from_pretrained(
        args.base_model,
        num_labels=len(LABELS),
        id2label=ID2LABEL,
        label2id=LABEL2ID,
        trust_remote_code=True,
    )
    model.to(device)

    total_params = sum(p.numel() for p in model.parameters())
    trainable = sum(p.numel() for p in model.parameters() if p.requires_grad)
    print(f"[encoder] total params: {total_params/1e6:.1f}M, trainable: {trainable/1e6:.1f}M")

    def tokenize(batch):
        tokens = tokenizer(batch["text"], truncation=True, padding="max_length", max_length=args.max_length)
        tokens["labels"] = batch["label_id"]
        return tokens

    def make_ds(items):
        ds = Dataset.from_dict({
            "text": [e["prompt"] for e in items],
            "label_id": [LABEL2ID[e.get("label") or e.get("gt_label")] for e in items],
        })
        return ds.map(tokenize, batched=True, remove_columns=["text"])

    train_ds = make_ds(train)

    training_args = TrainingArguments(
        output_dir=str(args.model_out / "_training"),
        num_train_epochs=args.epochs,
        per_device_train_batch_size=args.batch_size,
        learning_rate=args.lr,
        logging_steps=20,
        save_steps=99999,
        save_total_limit=1,
        warmup_ratio=0.1,
        weight_decay=0.01,
        report_to="none",
    )

    trainer = Trainer(
        model=model,
        args=training_args,
        train_dataset=train_ds,
        processing_class=tokenizer,
    )

    print(f"[encoder] training (epochs={args.epochs}, batch={args.batch_size}, lr={args.lr})...")
    trainer.train()

    print("\n=== Validation ===")
    print(f"\n[encoder] taxonomy (n={len(taxonomy)}):")
    tax_metrics = grade_on_gt(model, tokenizer, taxonomy, device)
    for k, v in tax_metrics.items():
        print(f"  {k}: {v:.4f}" if isinstance(v, float) else f"  {k}: {v}")

    gt_metrics = None
    if gt_ho:
        print(f"\n[encoder] GT hold-out (n={len(gt_ho)}):")
        gt_metrics = grade_on_gt(model, tokenizer, gt_ho, device)
        for k, v in gt_metrics.items():
            print(f"  {k}: {v:.4f}" if isinstance(v, float) else f"  {k}: {v}")

    args.model_out.mkdir(parents=True, exist_ok=True)
    model.save_pretrained(str(args.model_out / "encoder_model"))
    tokenizer.save_pretrained(str(args.model_out / "encoder_model"))

    metadata = {
        "model_type": "encoder_fullft",
        "base_model": args.base_model,
        "labels": LABELS,
        "epochs": args.epochs,
        "batch_size": args.batch_size,
        "lr": args.lr,
        "train_n": len(train),
        "total_params_M": round(total_params / 1e6, 1),
        "taxonomy_metrics": tax_metrics,
    }
    if gt_metrics:
        metadata["gt_holdout_metrics"] = gt_metrics
    (args.model_out / "encoder_metadata.json").write_text(json.dumps(metadata, indent=2))
    print(f"\n[encoder] saved to {args.model_out}")


if __name__ == "__main__":
    main()
