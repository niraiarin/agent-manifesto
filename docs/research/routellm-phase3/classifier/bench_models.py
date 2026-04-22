#!/usr/bin/env python3
"""
bench_models.py — sentence-transformer 候補モデルの推論性能 bench.

24GB Mac で routing 判定に使える軽量 model を選定。
target: <=100ms/inference (ccr hook で実用)
"""

from __future__ import annotations

import time
import statistics

CANDIDATES = [
    "sentence-transformers/all-MiniLM-L6-v2",              # 22M, English
    "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2",  # 118M, JA/EN
    "intfloat/multilingual-e5-small",                      # 118M, JA/EN
    "cl-tohoku/bert-base-japanese-v3",                     # 110M, JA-only
]

SAMPLE_PROMPTS = [
    "V1-V7 メトリクスを分析して停滞シグナルを報告してください。",
    "この commit のコード変更を独立検証してください。L1 safety 違反はないか。",
    "research gap の優先順位付けを G1-G5 基準で行ってください。",
    "Please write a Python function to sort a list of dicts by a nested field.",
    "agent-manifesto の /evolve スキルの Phase 2 Hypothesizer を呼び出して。",
    "Slack でナレッジボットを作りたい。どう設計すべき？",
]


def bench(model_name: str, n_warmup: int = 3, n_trials: int = 10) -> dict:
    from sentence_transformers import SentenceTransformer

    print(f"[bench] loading {model_name}")
    t0 = time.time()
    model = SentenceTransformer(model_name)
    load_ms = (time.time() - t0) * 1000

    # warmup
    for _ in range(n_warmup):
        model.encode(SAMPLE_PROMPTS[0], convert_to_numpy=True)

    times = []
    for _ in range(n_trials):
        prompt = SAMPLE_PROMPTS[_ % len(SAMPLE_PROMPTS)]
        t0 = time.time()
        model.encode(prompt, convert_to_numpy=True)
        times.append((time.time() - t0) * 1000)

    return {
        "model": model_name,
        "load_ms": round(load_ms),
        "mean_ms": round(statistics.mean(times), 2),
        "median_ms": round(statistics.median(times), 2),
        "p95_ms": round(sorted(times)[int(len(times) * 0.95)], 2),
        "dim": model.get_sentence_embedding_dimension(),
    }


def main():
    results = []
    for name in CANDIDATES:
        try:
            r = bench(name)
            results.append(r)
            print(f"  {r}")
        except Exception as e:
            print(f"  FAILED {name}: {e}")

    print("\n=== summary ===")
    print(f"{'model':<60} {'dim':>5} {'load':>6} {'mean':>6} {'p95':>6}")
    for r in sorted(results, key=lambda x: x["mean_ms"]):
        name = r["model"].split("/")[-1]
        print(f"{name:<60} {r['dim']:>5} {r['load_ms']:>5}ms {r['mean_ms']:>5}ms {r['p95_ms']:>5}ms")


if __name__ == "__main__":
    main()
