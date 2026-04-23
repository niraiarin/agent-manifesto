#!/usr/bin/env python3
"""
train_qlora.py — #653 Phase 2: Qwen 0.5B + LoRA 分類器 fine-tune.

multilingual-e5-small + SetFit の上位互換:
- LM 自身に agent-manifesto 語彙 (P3, D13, valueless_change 等) を embedding layer で学習
- LoRA で低コスト fine-tune (24GB Mac, no bitsandbytes)
- 5-way classification head 追加

注: bitsandbytes は Mac 非対応。fp16/fp32 + LoRA で代替 (quantization なし)。
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
    parser.add_argument("--base-model", type=str, default="Qwen/Qwen2.5-0.5B")
    parser.add_argument("--epochs", type=int, default=3)
    parser.add_argument("--batch-size", type=int, default=4)
    parser.add_argument("--lr", type=float, default=5e-5)
    parser.add_argument("--lora-rank", type=int, default=16)
    args = parser.parse_args()

    import os
    os.environ.setdefault("TOKENIZERS_PARALLELISM", "false")
    os.environ.setdefault("PYTORCH_MPS_HIGH_WATERMARK_RATIO", "0.0")

    import torch
    # MPS (Apple Silicon GPU) 優先、OOM 時は CPU
    if torch.backends.mps.is_available():
        device = "mps"
    elif torch.cuda.is_available():
        device = "cuda"
    else:
        device = "cpu"

    from transformers import AutoTokenizer, AutoModelForSequenceClassification, TrainingArguments, Trainer
    from peft import LoraConfig, get_peft_model, TaskType
    from datasets import Dataset

    print(f"[qlora] base={args.base_model} device={device}")

    train = load_jsonl(args.train)
    taxonomy = load_jsonl(args.validate_taxonomy)
    gt_ho = load_jsonl(args.gt_holdout) if args.gt_holdout else None
    print(f"[qlora] train={len(train)} tax_validate={len(taxonomy)} gt_holdout={len(gt_ho) if gt_ho else 0}")

    tokenizer = AutoTokenizer.from_pretrained(args.base_model, trust_remote_code=True)
    if tokenizer.pad_token is None:
        tokenizer.pad_token = tokenizer.eos_token

    model = AutoModelForSequenceClassification.from_pretrained(
        args.base_model,
        num_labels=len(LABELS),
        id2label=ID2LABEL,
        label2id=LABEL2ID,
        trust_remote_code=True,
        torch_dtype=torch.float32,
    )
    model.config.pad_token_id = tokenizer.pad_token_id
    model.to(device)

    lora_config = LoraConfig(
        task_type=TaskType.SEQ_CLS,
        r=args.lora_rank,
        lora_alpha=args.lora_rank * 2,
        lora_dropout=0.05,
        bias="none",
        target_modules=["q_proj", "v_proj"],
    )
    model = get_peft_model(model, lora_config)
    model.print_trainable_parameters()

    def tokenize(batch):
        tokens = tokenizer(batch["text"], truncation=True, padding="max_length", max_length=512)
        tokens["labels"] = batch["label_id"]
        return tokens

    def make_ds(items):
        ds = Dataset.from_dict({
            "text": [e["prompt"] for e in items],
            "label_id": [LABEL2ID[e.get("label") or e.get("gt_label")] for e in items],
        })
        return ds.map(tokenize, batched=True, remove_columns=["text"])

    train_ds = make_ds(train)
    tax_ds = make_ds(taxonomy)

    training_args = TrainingArguments(
        output_dir=str(args.model_out / "_training"),
        num_train_epochs=args.epochs,
        per_device_train_batch_size=args.batch_size,
        learning_rate=args.lr,
        logging_steps=20,
        save_steps=9999,
        save_total_limit=1,
        use_cpu=(device == "cpu"),
        report_to="none",
    )

    trainer = Trainer(
        model=model,
        args=training_args,
        train_dataset=train_ds,
        processing_class=tokenizer,
    )

    print(f"[qlora] training (epochs={args.epochs}, batch={args.batch_size}, lr={args.lr}, rank={args.lora_rank})...")
    trainer.train()

    print("\n=== Validation ===")
    print(f"\n[qlora] taxonomy validate (n={len(taxonomy)}):")
    tax_metrics = grade_on_gt(model, tokenizer, taxonomy, device)
    for k, v in tax_metrics.items():
        print(f"  {k}: {v:.4f}" if isinstance(v, float) else f"  {k}: {v}")

    gt_metrics = None
    if gt_ho:
        print(f"\n[qlora] GT hold-out (n={len(gt_ho)}):")
        gt_metrics = grade_on_gt(model, tokenizer, gt_ho, device)
        for k, v in gt_metrics.items():
            print(f"  {k}: {v:.4f}" if isinstance(v, float) else f"  {k}: {v}")

    args.model_out.mkdir(parents=True, exist_ok=True)
    model.save_pretrained(str(args.model_out / "qlora_adapter"))
    tokenizer.save_pretrained(str(args.model_out / "qlora_adapter"))

    metadata = {
        "model_type": "qlora",
        "base_model": args.base_model,
        "labels": LABELS,
        "epochs": args.epochs,
        "lora_rank": args.lora_rank,
        "train_n": len(train),
        "taxonomy_metrics": tax_metrics,
    }
    if gt_metrics:
        metadata["gt_holdout_metrics"] = gt_metrics
    (args.model_out / "qlora_metadata.json").write_text(json.dumps(metadata, indent=2))
    print(f"\n[qlora] saved → {args.model_out}")


if __name__ == "__main__":
    main()
