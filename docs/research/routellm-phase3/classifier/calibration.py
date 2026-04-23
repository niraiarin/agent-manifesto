#!/usr/bin/env python3
"""
calibration.py — classifier の confidence と actual accuracy の乖離を測定.

reliability diagram 相当のデータを JSON で出力。
confidence bin [0.0-0.2, 0.2-0.4, 0.4-0.6, 0.6-0.8, 0.8-1.0] ごとに accuracy を集計。
"""

from __future__ import annotations

import argparse
import json
from collections import defaultdict
from pathlib import Path

import numpy as np


def load_jsonl(path: Path) -> list[dict]:
    with open(path) as f:
        return [json.loads(line) for line in f if line.strip()]


def predict_encoder(model_dir: Path, evaluation: list[dict], batch_size: int):
    import torch
    from transformers import AutoModelForSequenceClassification, AutoTokenizer

    meta = json.load(open(model_dir / "encoder_metadata.json"))
    labels = meta["labels"]
    label_map = {label: i for i, label in enumerate(labels)}

    if torch.backends.mps.is_available():
        device = "mps"
    elif torch.cuda.is_available():
        device = "cuda"
    else:
        device = "cpu"

    tokenizer = AutoTokenizer.from_pretrained(
        str(model_dir / "encoder_model"),
        trust_remote_code=True,
        fix_mistral_regex=True,
    )
    model = AutoModelForSequenceClassification.from_pretrained(str(model_dir / "encoder_model"), trust_remote_code=True)
    model.to(device)
    model.eval()

    prompts = [e["prompt"] for e in evaluation]
    y_true = np.array([label_map[e.get("label") or e.get("gt_label")] for e in evaluation])
    probs = []
    with torch.no_grad():
        for i in range(0, len(prompts), batch_size):
            batch = prompts[i:i + batch_size]
            inputs = tokenizer(batch, return_tensors="pt", padding=True, truncation=True, max_length=512)
            inputs = {k: v.to(device) for k, v in inputs.items()}
            logits = model(**inputs).logits
            probs.extend(torch.softmax(logits, dim=-1).detach().cpu().numpy())
    return meta, label_map, np.array(probs), y_true


def predict_lr(model_dir: Path, evaluation: list[dict], batch_size: int):
    import joblib
    from sentence_transformers import SentenceTransformer

    meta = json.load(open(model_dir / "metadata.json"))
    clf = joblib.load(model_dir / "clf.joblib")
    encoder = SentenceTransformer(meta["encoder"])
    label_map = meta["label_map"]

    prompts = [f"query: {e['prompt']}" for e in evaluation]
    y_true = np.array([label_map[e["label"]] for e in evaluation])
    X = encoder.encode(prompts, convert_to_numpy=True, batch_size=batch_size)

    return meta, label_map, clf.predict_proba(X), y_true


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--eval", type=Path, required=True)
    parser.add_argument("--model-dir", type=Path, required=True)
    parser.add_argument("--output", type=Path, default=Path("../analysis/calibration.json"))
    parser.add_argument("--batch-size", type=int, default=16)
    args = parser.parse_args()

    evaluation = load_jsonl(args.eval)
    if (args.model_dir / "encoder_metadata.json").exists():
        meta, label_map, probs, y_true = predict_encoder(args.model_dir, evaluation, args.batch_size)
        model_kind = "encoder_fullft"
    else:
        meta, label_map, probs, y_true = predict_lr(args.model_dir, evaluation, args.batch_size)
        model_kind = "lr_sentence_transformer"
    id_to_label = {v: k for k, v in label_map.items()}

    confidences = probs.max(axis=1)
    predictions = probs.argmax(axis=1)

    # Bin by confidence
    bins = [(0.0, 0.2), (0.2, 0.3), (0.3, 0.4), (0.4, 0.5), (0.5, 0.6), (0.6, 0.8), (0.8, 1.0)]
    bin_data = []
    ece = 0.0  # Expected Calibration Error
    n_total = len(y_true)

    for lo, hi in bins:
        mask = (confidences >= lo) & (confidences < hi)
        n = int(mask.sum())
        if n == 0:
            bin_data.append({"bin": f"[{lo:.1f},{hi:.1f})", "n": 0, "accuracy": None, "mean_confidence": None})
            continue
        acc = float((predictions[mask] == y_true[mask]).mean())
        mean_conf = float(confidences[mask].mean())
        gap = abs(acc - mean_conf)
        ece += (n / n_total) * gap
        bin_data.append({
            "bin": f"[{lo:.2f},{hi:.2f})",
            "n": n,
            "accuracy": round(acc, 3),
            "mean_confidence": round(mean_conf, 3),
            "gap": round(gap, 3),
        })

    # Per-class calibration
    per_class = {}
    for class_id, class_name in id_to_label.items():
        class_mask = y_true == class_id
        if class_mask.sum() == 0:
            continue
        correct = predictions[class_mask] == y_true[class_mask]
        per_class[class_name] = {
            "n": int(class_mask.sum()),
            "accuracy": float(correct.mean()),
            "mean_confidence_when_predicted": float(confidences[predictions == class_id].mean())
            if (predictions == class_id).any() else None,
        }

    report = {
        "model_kind": model_kind,
        "base_model": meta.get("base_model") or meta.get("encoder"),
        "n": n_total,
        "overall_accuracy": float((predictions == y_true).mean()),
        "overall_mean_confidence": float(confidences.mean()),
        "expected_calibration_error": round(ece, 4),
        "bins": bin_data,
        "per_class": per_class,
    }

    print(f"[calib] n={n_total} accuracy={report['overall_accuracy']:.3f} mean_conf={report['overall_mean_confidence']:.3f} ECE={report['expected_calibration_error']:.4f}")
    print("\n[calib] reliability diagram:")
    print(f"  {'bin':<15}{'n':>5}{'acc':>8}{'conf':>8}{'gap':>8}")
    for b in bin_data:
        if b["n"] == 0:
            continue
        print(f"  {b['bin']:<15}{b['n']:>5}{b['accuracy']:>8.3f}{b['mean_confidence']:>8.3f}{b['gap']:>8.3f}")

    print("\n[calib] per-class:")
    for cls, v in per_class.items():
        mconf = v.get("mean_confidence_when_predicted")
        print(f"  {cls:<20} n={v['n']:<3} acc={v['accuracy']:.3f}  conf@pred={mconf if mconf is None else f'{mconf:.3f}'}")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
