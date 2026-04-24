#!/usr/bin/env python3
"""
load_test.py — 同時接続 N で /classify を叩いて latency 分布を出す.
"""

from __future__ import annotations

import argparse
import asyncio
import json
import statistics
import time
from pathlib import Path

import aiohttp


SAMPLE_PROMPTS = [
    "V1-V7 メトリクスを解釈して停滞シグナルを報告してください。",
    "このコード変更を独立検証してください。L1 safety 違反をチェック。",
    "今日の天気はどう？",
    "outline と evidence から Method セクションを single-pass で執筆。",
    "Python の asyncio と threading の違いを説明。",
]


async def one_request(session: aiohttp.ClientSession, url: str, prompt: str) -> float:
    t0 = time.time()
    async with session.post(url, json={"prompt": prompt}) as resp:
        await resp.json()
    return (time.time() - t0) * 1000


async def run(concurrency: int, total: int, url: str) -> list[float]:
    latencies = []
    sem = asyncio.Semaphore(concurrency)

    async with aiohttp.ClientSession() as session:
        async def worker(i: int):
            async with sem:
                prompt = SAMPLE_PROMPTS[i % len(SAMPLE_PROMPTS)]
                ms = await one_request(session, url, prompt)
                latencies.append(ms)

        tasks = [worker(i) for i in range(total)]
        await asyncio.gather(*tasks)
    return latencies


def percentile(xs: list[float], p: float) -> float:
    s = sorted(xs)
    return s[min(len(s) - 1, int(len(s) * p))]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--url", default="http://localhost:9001/classify")
    parser.add_argument("--concurrency", type=int, nargs="+", default=[1, 5, 10])
    parser.add_argument("--total", type=int, default=50)
    parser.add_argument("--output", type=Path, default=Path("../analysis/load-test.json"))
    args = parser.parse_args()

    report = {"url": args.url, "total_per_setting": args.total, "results": []}

    for c in args.concurrency:
        print(f"[load] concurrency={c} total={args.total}")
        t0 = time.time()
        latencies = asyncio.run(run(c, args.total, args.url))
        wall_s = time.time() - t0
        qps = args.total / wall_s

        r = {
            "concurrency": c,
            "total": args.total,
            "wall_seconds": round(wall_s, 2),
            "qps": round(qps, 1),
            "mean_ms": round(statistics.mean(latencies), 1),
            "median_ms": round(statistics.median(latencies), 1),
            "p50_ms": round(percentile(latencies, 0.50), 1),
            "p95_ms": round(percentile(latencies, 0.95), 1),
            "p99_ms": round(percentile(latencies, 0.99), 1),
            "max_ms": round(max(latencies), 1),
        }
        report["results"].append(r)
        print(f"  qps={r['qps']:.1f} mean={r['mean_ms']}ms p50={r['p50_ms']}ms p95={r['p95_ms']}ms p99={r['p99_ms']}ms")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2))
    print(f"\n[load] wrote {args.output}")


if __name__ == "__main__":
    main()
