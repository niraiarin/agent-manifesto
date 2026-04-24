#!/usr/bin/env python3
"""
sample_for_gt.py — #653 Phase 1: real corpus から 100 件を層化サンプリング.

戦略:
- 予測 label 分布を維持 (local_confident 5%, local_probable 20%, cloud_required 23%, hybrid 38%, unknown 14%)
- 各 confidence bin から均等に (0.2-0.4 from each of {0.3-0.5, 0.5-0.7, 0.7-0.9, 0.9-1.0})
- 長さ分布も意識 (short / medium / long 各 30% 程度)

出力:
  real-gt-candidates.jsonl: 100 件、人手ラベル用 (label フィールド空)
  annotate.html: 簡易アノテーションツール (CLI / ブラウザ両対応)
"""

from __future__ import annotations

import argparse
import json
import random
import urllib.error
import urllib.parse
import urllib.request
from collections import Counter, defaultdict
from pathlib import Path

import joblib
import numpy as np


LABEL_TO_ID = {
    "local_confident": 0,
    "local_probable": 1,
    "cloud_required": 2,
    "hybrid": 3,
    "unknown": 4,
}
ID_TO_LABEL = {v: k for k, v in LABEL_TO_ID.items()}
TARGET_LABEL_PCT = {
    "local_confident": 0.05,
    "local_probable": 0.20,
    "cloud_required": 0.23,
    "hybrid": 0.38,
    "unknown": 0.14,
}


def conf_bin(confidence: float) -> str:
    if confidence < 0.30:
        return "low"
    if confidence < 0.50:
        return "mid"
    if confidence < 0.70:
        return "high"
    if confidence < 0.90:
        return "vhigh"
    return "peak"


def length_bin(length: int) -> str:
    if length < 100:
        return "short"
    if length < 500:
        return "medium"
    if length < 2000:
        return "long"
    return "xlong"


def prompt_key(entry: dict) -> tuple[str | None, str]:
    return entry.get("session_id"), entry.get("prompt", "")[:200]


def load_jsonl(path: Path | None) -> list[dict]:
    if path is None or not path.exists():
        return []
    return [json.loads(line) for line in path.read_text().splitlines() if line.strip()]


def next_gt_index(existing_entries: list[dict]) -> int:
    max_index = -1
    for entry in existing_entries:
        identifier = str(entry.get("id", ""))
        if identifier.startswith("gt-"):
            suffix = identifier[3:]
            if suffix.isdigit():
                max_index = max(max_index, int(suffix))
    return max_index + 1


def predict_lr(model_dir: Path, prompts: list[str]) -> tuple[np.ndarray, np.ndarray]:
    from sentence_transformers import SentenceTransformer

    meta = json.load(open(model_dir / "metadata.json"))
    clf = joblib.load(model_dir / "clf.joblib")
    encoder = SentenceTransformer(meta["encoder"])
    encoded = encoder.encode(
        [f"query: {prompt}" for prompt in prompts],
        convert_to_numpy=True,
        batch_size=32,
        show_progress_bar=False,
    )
    probs = clf.predict_proba(encoded)
    return probs.argmax(axis=1), probs


def _validate_localhost_url(url: str) -> str:
    parsed = urllib.parse.urlparse(url)
    if parsed.scheme not in {"http", "https"}:
        raise ValueError(f"unsupported serve url scheme: {url}")
    if parsed.hostname not in {"127.0.0.1", "localhost"}:
        raise ValueError(f"serve url must point to localhost: {url}")
    return url


def predict_mdeberta(prompts: list[str], serve_url: str) -> tuple[np.ndarray, np.ndarray]:
    serve_url = _validate_localhost_url(serve_url)
    labels = [ID_TO_LABEL[i] for i in range(len(ID_TO_LABEL))]
    probs_rows: list[list[float]] = []

    for prompt in prompts:
        request = urllib.request.Request(
            serve_url.rstrip("/") + "/classify",
            data=json.dumps({"prompt": prompt}).encode("utf-8"),
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        try:
            with urllib.request.urlopen(request, timeout=30) as response:
                payload = json.loads(response.read().decode("utf-8"))
        except urllib.error.URLError as exc:
            raise RuntimeError(f"failed to classify prompt via {serve_url}: {exc}") from exc

        probs = payload.get("probs")
        if not isinstance(probs, dict):
            raise RuntimeError("invalid /classify response: missing probs")
        probs_rows.append([float(probs.get(label, 0.0)) for label in labels])

    matrix = np.array(probs_rows, dtype=float)
    return matrix.argmax(axis=1), matrix


def proportional_targets(n: int) -> dict[str, int]:
    targets = {label: max(1, int(n * pct)) for label, pct in TARGET_LABEL_PCT.items()}
    total = sum(targets.values())
    if total < n:
        targets["hybrid"] += n - total
    elif total > n:
        overflow = total - n
        for label in ("hybrid", "unknown", "cloud_required", "local_probable", "local_confident"):
            if overflow == 0:
                break
            removable = min(overflow, max(0, targets[label] - 1))
            targets[label] -= removable
            overflow -= removable
    return targets


def sample_indices(
    reals: list[dict],
    preds: np.ndarray,
    confs: np.ndarray,
    n: int,
    exclude_keys: set[tuple[str | None, str]],
) -> list[int]:
    targets = proportional_targets(n)
    pool: dict[tuple[str, str], list[int]] = defaultdict(list)
    eligible = set()

    for index, prompt in enumerate(reals):
        if prompt_key(prompt) in exclude_keys:
            continue
        eligible.add(index)
        label = ID_TO_LABEL[int(preds[index])]
        pool[(label, conf_bin(float(confs[index])))].append(index)

    sampled_indices: list[int] = []
    sampled_set: set[int] = set()

    for label, count in targets.items():
        bins = {cb: indices for (lbl, cb), indices in pool.items() if lbl == label}
        if not bins:
            continue
        per_bin = max(1, count // max(1, len(bins)))
        taken = 0
        for cb, indices in sorted(bins.items()):
            remaining = count - taken
            if remaining <= 0:
                break
            candidates = [idx for idx in indices if idx not in sampled_set]
            take = min(per_bin, len(candidates), remaining)
            if take <= 0:
                continue
            chosen = random.sample(candidates, take)
            sampled_indices.extend(chosen)
            sampled_set.update(chosen)
            taken += take

        remaining = count - taken
        if remaining > 0:
            extras = [
                idx
                for (lbl, _), indices in pool.items()
                if lbl == label
                for idx in indices
                if idx not in sampled_set
            ]
            chosen = random.sample(extras, min(remaining, len(extras)))
            sampled_indices.extend(chosen)
            sampled_set.update(chosen)

    if len(sampled_indices) < n:
        extras = [idx for idx in sorted(eligible) if idx not in sampled_set]
        need = min(n - len(sampled_indices), len(extras))
        if need > 0:
            chosen = random.sample(extras, need)
            sampled_indices.extend(chosen)
            sampled_set.update(chosen)

    return sampled_indices[:n]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--real-prompts", type=Path, required=True)
    parser.add_argument("--model-dir", type=Path, required=True)
    parser.add_argument("--output", type=Path, default=Path("../label-data/real-gt-candidates.jsonl"))
    parser.add_argument("--n", type=int, default=100)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--exclude", type=Path)
    parser.add_argument("--backend", choices=("lr", "mdeberta"), default="lr")
    parser.add_argument("--serve-url", default="http://localhost:9001")
    args = parser.parse_args()

    random.seed(args.seed)

    reals = load_jsonl(args.real_prompts)
    print(f"[sample] {len(reals)} real prompts loaded")

    prompts = [entry["prompt"] for entry in reals]
    if args.backend == "lr":
        preds, probs = predict_lr(args.model_dir, prompts)
    else:
        preds, probs = predict_mdeberta(prompts, args.serve_url)
    confs = probs.max(axis=1)

    exclude_entries = load_jsonl(args.exclude)
    exclude_keys = {prompt_key(entry) for entry in exclude_entries}
    sampled_indices = sample_indices(reals, preds, confs, args.n, exclude_keys)
    start_index = next_gt_index(exclude_entries)

    entries = []
    for offset, index in enumerate(sampled_indices):
        prompt = reals[index]
        entries.append(
            {
                "id": f"gt-{start_index + offset:03d}",
                "session_id": prompt.get("session_id"),
                "prompt": prompt["prompt"],
                "prompt_len": prompt.get("prompt_len", len(prompt["prompt"])),
                "predicted_label": ID_TO_LABEL[int(preds[index])],
                "predicted_confidence": round(float(confs[index]), 3),
                "predicted_probs": {
                    ID_TO_LABEL[label_id]: round(float(probs[index][label_id]), 3)
                    for label_id in range(len(ID_TO_LABEL))
                },
                "conf_bin": conf_bin(float(confs[index])),
                "length_bin": length_bin(len(prompt["prompt"])),
                "gt_label": None,
                "annotator_notes": None,
            }
        )

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text("\n".join(json.dumps(entry, ensure_ascii=False) for entry in entries) + "\n")

    label_dist = Counter(entry["predicted_label"] for entry in entries)
    conf_dist = Counter(entry["conf_bin"] for entry in entries)
    len_dist = Counter(entry["length_bin"] for entry in entries)

    print(f"[sample] wrote {len(entries)} candidates → {args.output}")
    if args.exclude:
        print(f"[sample] excluded {len(exclude_entries)} existing entries from {args.exclude}")
    print(f"[sample] backend={args.backend}")
    print(f"[sample] predicted label dist: {dict(label_dist)}")
    print(f"[sample] conf bin dist: {dict(conf_dist)}")
    print(f"[sample] length bin dist: {dict(len_dist)}")


if __name__ == "__main__":
    main()
