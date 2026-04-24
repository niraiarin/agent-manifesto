#!/usr/bin/env python3
"""
calibrate_from_gt.py — Measure calibration against labeled GT.
"""

from __future__ import annotations

import argparse
import json
import math
import urllib.error
import urllib.parse
import urllib.request
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


def validate_localhost_url(url: str) -> str:
    parsed = urllib.parse.urlparse(url)
    if parsed.scheme not in {"http", "https"}:
        raise ValueError(f"unsupported serve url scheme: {url}")
    if parsed.hostname not in {"127.0.0.1", "localhost"}:
        raise ValueError(f"serve url must point to localhost: {url}")
    return url.rstrip("/")


def try_predict_via_server(entries: list[dict], serve_url: str) -> list[dict] | None:
    serve_url = validate_localhost_url(serve_url)
    predictions = []
    try:
        for entry in entries:
            request = urllib.request.Request(
                serve_url + "/classify",
                data=json.dumps({"prompt": entry["prompt"]}).encode("utf-8"),
                headers={"Content-Type": "application/json"},
                method="POST",
            )
            with urllib.request.urlopen(request, timeout=30) as response:
                payload = json.loads(response.read().decode("utf-8"))
            predictions.append(
                {
                    "predicted_label": payload["label"],
                    "predicted_confidence": float(payload["confidence"]),
                    "predicted_probs": {label: float(payload["probs"].get(label, 0.0)) for label in LABELS},
                    "source": "serve_url",
                }
            )
    except (urllib.error.URLError, KeyError, ValueError):
        return None
    return predictions


def predict_direct(entries: list[dict], model_dir: Path) -> list[dict]:
    import torch
    from transformers import AutoModelForSequenceClassification, AutoTokenizer

    meta = json.load(open(model_dir / "encoder_metadata.json"))
    labels = meta["labels"]
    tokenizer = AutoTokenizer.from_pretrained(
        str(model_dir / "encoder_model"),
        trust_remote_code=True,
        fix_mistral_regex=True,
    )
    model = AutoModelForSequenceClassification.from_pretrained(
        str(model_dir / "encoder_model"),
        trust_remote_code=True,
    )

    if torch.backends.mps.is_available():
        device = "mps"
    elif torch.cuda.is_available():
        device = "cuda"
    else:
        device = "cpu"

    model.to(device)
    model.eval()

    predictions = []
    with torch.no_grad():
        for entry in entries:
            tokens = tokenizer(entry["prompt"], return_tensors="pt", truncation=True, max_length=512)
            tokens = {name: tensor.to(device) for name, tensor in tokens.items()}
            logits = model(**tokens).logits
            probs = torch.softmax(logits, dim=-1).squeeze(0).detach().cpu().tolist()
            label_id = max(range(len(probs)), key=probs.__getitem__)
            predictions.append(
                {
                    "predicted_label": labels[label_id],
                    "predicted_confidence": float(probs[label_id]),
                    "predicted_probs": {labels[idx]: float(value) for idx, value in enumerate(probs)},
                    "source": "model_dir",
                }
            )
    return predictions


def confidence_bins() -> list[tuple[float, float]]:
    return [(0.0, 0.2), (0.2, 0.4), (0.4, 0.6), (0.6, 0.8), (0.8, 1.01)]


def compute_bin_metrics(entries: list[dict]) -> tuple[list[dict], float, float]:
    n_total = max(1, len(entries))
    ece = 0.0
    mce = 0.0
    bins = []

    for lower, upper in confidence_bins():
        bucket = [
            entry
            for entry in entries
            if lower <= float(entry["predicted_confidence"]) < upper
        ]
        count = len(bucket)
        if count == 0:
            bins.append({"bin": f"[{lower:.1f},{min(upper, 1.0):.1f})", "n": 0})
            continue
        accuracy = sum(1 for entry in bucket if entry["predicted_label"] == entry["gt_label"]) / count
        mean_confidence = sum(float(entry["predicted_confidence"]) for entry in bucket) / count
        gap = abs(accuracy - mean_confidence)
        ece += (count / n_total) * gap
        mce = max(mce, gap)
        bins.append(
            {
                "bin": f"[{lower:.1f},{min(upper, 1.0):.1f})",
                "n": count,
                "accuracy": round(accuracy, 4),
                "mean_confidence": round(mean_confidence, 4),
                "gap": round(gap, 4),
            }
        )
    return bins, ece, mce


def compute_per_label(entries: list[dict]) -> dict[str, dict]:
    results = {}
    for label in LABELS:
        label_entries = [entry for entry in entries if entry["gt_label"] == label]
        if not label_entries:
            continue
        bins, ece, mce = compute_bin_metrics(label_entries)
        predicted_confidences = [
            entry["predicted_probs"].get(label, 0.0)
            for entry in entries
            if entry["predicted_label"] == label
        ]
        results[label] = {
            "n": len(label_entries),
            "ece": round(ece, 4),
            "mce": round(mce, 4),
            "mean_confidence_when_predicted": round(sum(predicted_confidences) / len(predicted_confidences), 4)
            if predicted_confidences
            else None,
            "bins": bins,
        }
    return results


def ascii_reliability(bins: list[dict]) -> str:
    lines = ["bin            n   acc   conf  gap  chart"]
    for item in bins:
        if item["n"] == 0:
            lines.append(f"{item['bin']:<13} {item['n']:>3}   -     -    -")
            continue
        acc_blocks = "#" * max(1, int(round(item["accuracy"] * 10)))
        conf_blocks = "." * max(1, int(round(item["mean_confidence"] * 10)))
        lines.append(
            f"{item['bin']:<13} {item['n']:>3} {item['accuracy']:.2f} {item['mean_confidence']:.2f} {item['gap']:.2f} {acc_blocks}|{conf_blocks}"
        )
    return "\n".join(lines)


def maybe_plot_reliability(bins: list[dict], output: Path) -> str | None:
    try:
        import matplotlib.pyplot as plt
    except ImportError:
        return None

    xs = []
    ys = []
    for item in bins:
        if item["n"] == 0:
            continue
        xs.append(item["mean_confidence"])
        ys.append(item["accuracy"])

    if not xs:
        return None

    output_path = output.with_suffix(".png")
    fig, ax = plt.subplots(figsize=(5, 5))
    ax.plot([0, 1], [0, 1], linestyle="--", color="gray")
    ax.scatter(xs, ys, color="tab:blue")
    ax.set_xlabel("Mean confidence")
    ax.set_ylabel("Accuracy")
    ax.set_title("Reliability diagram")
    fig.tight_layout()
    fig.savefig(output_path)
    plt.close(fig)
    return output_path.name


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--labeled", type=Path, required=True)
    parser.add_argument("--model-dir", type=Path, required=True)
    parser.add_argument("--serve-url", default="http://localhost:9001")
    parser.add_argument("--output", type=Path, default=Path("../analysis/mdeberta-calibration-gt500.md"))
    args = parser.parse_args()

    labeled = [entry for entry in load_jsonl(args.labeled) if entry.get("gt_label") in LABELS]
    predictions = try_predict_via_server(labeled, args.serve_url)
    if predictions is None:
        predictions = predict_direct(labeled, args.model_dir)

    merged = []
    for entry, prediction in zip(labeled, predictions):
        combined = dict(entry)
        combined.update(prediction)
        merged.append(combined)

    bins, overall_ece, overall_mce = compute_bin_metrics(merged)
    per_label = compute_per_label(merged)
    prediction_counts = {label: 0 for label in LABELS}
    for entry in merged:
        prediction_counts[entry["predicted_label"]] += 1

    image_name = maybe_plot_reliability(bins, args.output)
    lines = [
        "# mDeBERTa GT Calibration",
        "",
        f"- n: {len(merged)}",
        f"- overall_ece: {overall_ece:.4f}",
        f"- overall_mce: {overall_mce:.4f}",
        f"- prediction_source: {merged[0]['source'] if merged else 'n/a'}",
        "",
        "## Confidence Distribution",
        "",
    ]
    lines.extend(f"- {label}: {prediction_counts[label]}" for label in LABELS)
    lines.extend(
        [
            "",
            "## Reliability",
            "",
            "```text",
            ascii_reliability(bins),
            "```",
            "",
        ]
    )
    if image_name:
        lines.extend([f"Matplotlib diagram: `{image_name}`", ""])
    lines.extend(["## Per-label ECE / MCE", ""])
    for label in LABELS:
        metrics = per_label.get(label)
        if not metrics:
            continue
        mean_pred = metrics["mean_confidence_when_predicted"]
        mean_pred_text = "n/a" if mean_pred is None else f"{mean_pred:.4f}"
        lines.extend(
            [
                f"### {label}",
                "",
                f"- n: {metrics['n']}",
                f"- ece: {metrics['ece']:.4f}",
                f"- mce: {metrics['mce']:.4f}",
                f"- mean_confidence_when_predicted: {mean_pred_text}",
                "",
            ]
        )

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text("\n".join(lines))
    print(f"[calibrate-from-gt] wrote {args.output}")
    print(f"[calibrate-from-gt] overall_ece={overall_ece:.4f} overall_mce={overall_mce:.4f} n={len(merged)}")


if __name__ == "__main__":
    main()
