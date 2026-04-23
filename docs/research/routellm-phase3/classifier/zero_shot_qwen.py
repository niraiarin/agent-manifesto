#!/usr/bin/env python3
"""
zero_shot_qwen.py — Qwen3.5-4B を llama-server 経由で zero-shot classification.

Fine-tune なし。prompt engineering で 5-way routing 分類を直接実行。
4B reasoning が我々の 680 samples 学習 LR を超えるか検証。
"""

from __future__ import annotations

import argparse
import json
import time
import urllib.request
from pathlib import Path


LABELS = ["local_confident", "local_probable", "cloud_required", "hybrid", "unknown"]
LOCAL = {"local_confident", "local_probable"}
CLOUD = {"cloud_required", "hybrid", "unknown"}


SYSTEM = """あなたは agent-manifesto プロジェクトの routing classifier。
Claude Code の LLM タスクを 5 分類のいずれかにラベル付けする。

## 分類定義

- **local_confident**: 構造化・低ドメイン知識・batch (例: outline 生成、要約、handoff)
- **local_probable**: ドメイン知識 medium、構造化推論 (例: V1-V7 解釈、trace 解釈、論文執筆)
- **cloud_required**: safety-critical or deep reasoning (例: /verify, /evolve, /research, コード生成)
- **hybrid**: 入力依存で動的切替 (例: Q&A、相談型会話)
- **unknown**: 5 category に属さない OOD (例: 雑談、料理、天気)

## 判定ヒント

- `/research`, `/verify`, `/evolve` 等の slash command → cloud_required
- コード修正、ファイル操作、PR 管理 → cloud_required
- V1-V7 / manifest-trace 等の観察データ → local_probable
- 短い ack, 状態確認、質問 → hybrid
- プロジェクトと無関係 → unknown

## 出力

以下の JSON 1 行のみ出力。説明や reasoning は含めない:
{"label": "<one of 5 labels>"}"""


def classify(prompt: str, url: str = "http://localhost:8090/v1/chat/completions") -> tuple[str, float]:
    # /no_think disable thinking mode; max_tokens 512 for safety
    body = {
        "model": "qwen3.5-4b",
        "messages": [
            {"role": "system", "content": "/no_think\n" + SYSTEM},
            {"role": "user", "content": prompt[:1500]},
        ],
        "max_tokens": 512,
        "temperature": 0.0,
    }
    req = urllib.request.Request(
        url,
        data=json.dumps(body).encode(),
        headers={"Content-Type": "application/json"},
    )
    t0 = time.time()
    with urllib.request.urlopen(req, timeout=60) as resp:
        data = json.loads(resp.read())
    latency = time.time() - t0
    content = data["choices"][0]["message"].get("content", "")
    # Parse JSON label
    import re
    match = re.search(r'"label"\s*:\s*"([^"]+)"', content)
    if match:
        label = match.group(1)
        if label in LABELS:
            return label, latency
    # Fallback: first label name found
    for lbl in LABELS:
        if lbl in content:
            return lbl, latency
    return "unknown", latency


def grade(labeled: list[dict]) -> dict:
    results = []
    exact = route_correct = leak = over = 0
    n = len(labeled)
    local_pred = 0

    for i, e in enumerate(labeled):
        gt = e.get("gt_label") or e.get("label")
        label, lat = classify(e["prompt"])
        results.append({"id": e.get("id", f"e-{i}"), "gt": gt, "pred": label, "latency": round(lat, 2)})

        pred_local = label in LOCAL
        gt_local = gt in LOCAL
        gt_cloud = gt in CLOUD

        if pred_local:
            local_pred += 1
        if pred_local == gt_local:
            route_correct += 1
        if label == gt:
            exact += 1
        if gt_cloud and pred_local:
            leak += 1
        if gt_local and not pred_local:
            over += 1

        print(f"  [{i+1}/{n}] gt={gt:<18} pred={label:<18} lat={lat:.1f}s {'✅' if label == gt else ('🟢' if pred_local == gt_local else '❌')}")

    return {
        "n": n,
        "exact_accuracy": exact / n,
        "routing_accuracy": route_correct / n,
        "leak_rate": leak / n,
        "over_cautious_rate": over / n,
        "local_predictions": local_pred,
        "per_sample": results,
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--labeled", type=Path, required=True)
    parser.add_argument("--output", type=Path, default=Path("../analysis/zero-shot-qwen-4b.json"))
    args = parser.parse_args()

    entries = [json.loads(l) for l in args.labeled.read_text().splitlines() if l.strip()]
    print(f"[zero-shot] {len(entries)} entries to classify")

    metrics = grade(entries)
    print(f"\n=== Zero-shot Qwen3.5-4B Results (n={metrics['n']}) ===")
    for k, v in metrics.items():
        if k == "per_sample":
            continue
        print(f"  {k}: {v:.4f}" if isinstance(v, float) else f"  {k}: {v}")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(metrics, indent=2, ensure_ascii=False))
    print(f"\n[zero-shot] wrote {args.output}")


if __name__ == "__main__":
    main()
