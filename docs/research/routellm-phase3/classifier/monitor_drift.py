#!/usr/bin/env python3
"""
monitor_drift.py — routing classifier drift detection.

predictions.jsonl の時系列ログから:
- label 分布の時間変化
- confidence 分布の drift (mean / p50 / p05 の推移)
- fallback 率の推移
- 新規プロンプト(新しい prompt_sha)の出現率

を集計。日次 or 週次バッチで実行。
"""

from __future__ import annotations

import argparse
import json
import statistics
from collections import Counter, defaultdict
from datetime import datetime
from pathlib import Path


def load_predictions(path: Path) -> list[dict]:
    if not path.exists():
        return []
    with open(path) as f:
        return [json.loads(line) for line in f if line.strip()]


def bucket_by_day(entries: list[dict]) -> dict[str, list[dict]]:
    buckets = defaultdict(list)
    for e in entries:
        day = datetime.utcfromtimestamp(e["ts"]).strftime("%Y-%m-%d")
        buckets[day].append(e)
    return dict(buckets)


def summarize_bucket(entries: list[dict]) -> dict:
    if not entries:
        return {}
    label_dist = Counter(e["label"] for e in entries)
    confs = [e["confidence"] for e in entries]
    fallback_count = sum(1 for e in entries if e["fallback"])
    unique_prompts = len({e["prompt_sha"] for e in entries})
    latencies = [e["latency_ms"] for e in entries]

    return {
        "n": len(entries),
        "unique_prompts": unique_prompts,
        "label_dist": dict(label_dist),
        "label_pct": {k: round(v / len(entries) * 100, 1) for k, v in label_dist.items()},
        "confidence_mean": round(statistics.mean(confs), 3),
        "confidence_median": round(statistics.median(confs), 3),
        "confidence_p05": round(sorted(confs)[max(0, len(confs) // 20)], 3),
        "fallback_count": fallback_count,
        "fallback_pct": round(fallback_count / len(entries) * 100, 1),
        "latency_median_ms": round(statistics.median(latencies), 2),
        "latency_p95_ms": round(sorted(latencies)[int(len(latencies) * 0.95)], 2) if len(latencies) >= 20 else None,
    }


def compute_drift(current: dict, reference: dict) -> dict:
    """Simple L1 distance on label distribution + delta on key stats."""
    if not current or not reference:
        return {"sufficient_data": False}

    all_labels = set(current["label_dist"]) | set(reference["label_dist"])
    l1_distance = sum(
        abs(current["label_pct"].get(l, 0) - reference["label_pct"].get(l, 0))
        for l in all_labels
    ) / 2  # normalize to [0, 100]

    return {
        "sufficient_data": True,
        "label_distribution_l1_pct": round(l1_distance, 2),
        "confidence_mean_delta": round(current["confidence_mean"] - reference["confidence_mean"], 3),
        "fallback_pct_delta": round(current["fallback_pct"] - reference["fallback_pct"], 2),
        "alert": l1_distance > 15 or abs(current["confidence_mean"] - reference["confidence_mean"]) > 0.1,
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--log-path", type=Path, default=Path("../logs/predictions.jsonl"))
    parser.add_argument("--reference-days", type=int, default=7,
                        help="Earlier window for drift baseline (days back from now)")
    parser.add_argument("--output", type=Path, default=None)
    args = parser.parse_args()

    entries = load_predictions(args.log_path)
    if not entries:
        print(f"[drift] no predictions logged at {args.log_path}")
        return

    buckets = bucket_by_day(entries)
    days = sorted(buckets.keys())
    print(f"[drift] {len(entries)} predictions across {len(days)} days: {days[0]} → {days[-1]}")

    # Build daily summaries
    summaries = {day: summarize_bucket(buckets[day]) for day in days}

    # Compute drift: latest day vs reference window
    if len(days) >= 2:
        latest = summaries[days[-1]]
        # reference window: days[-reference_days-1 .. -2]
        ref_window_start = max(0, len(days) - args.reference_days - 1)
        ref_entries = []
        for d in days[ref_window_start:len(days) - 1]:
            ref_entries.extend(buckets[d])
        reference = summarize_bucket(ref_entries)

        drift = compute_drift(latest, reference)
        print(f"\n[drift] latest day ({days[-1]}) vs reference ({days[ref_window_start]}..{days[-2]}):")
        for k, v in drift.items():
            print(f"  {k}: {v}")

        if drift.get("alert"):
            print("\n⚠️  DRIFT DETECTED — re-evaluate classifier")
    else:
        drift = {"sufficient_data": False, "reason": "need >=2 days of data"}

    result = {
        "generated_at": datetime.utcnow().isoformat() + "Z",
        "log_path": str(args.log_path),
        "n_total": len(entries),
        "days": days,
        "per_day": summaries,
        "drift": drift,
    }

    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(result, indent=2, ensure_ascii=False))
        print(f"\n[drift] wrote {args.output}")


if __name__ == "__main__":
    main()
