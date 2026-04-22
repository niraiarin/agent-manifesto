#!/usr/bin/env python3
"""
spot_check_observer.py — Tier 2 spot check for Observer task (#647).

Sends an Observer-style prompt to Q2 via ccr, captures response.
Compares coherence against Phase 1 M-interp baseline.

Usage:
  uv run python3 spot_check_observer.py \
    --input /path/to/metrics-input.json \
    --output spot-check-tier2/observer-001.json
"""

from __future__ import annotations

import argparse
import json
import time
import urllib.request
from pathlib import Path


OBSERVER_PROMPT_TEMPLATE = """あなたは agent-manifesto プロジェクトの Observer エージェント。
P4 可観測性フェーズを担当する。以下の観察データから構造の現在状態を報告する。
**判断や提案はしない** — 観察のみを行う。

## 観察データ

```json
{data}
```

## 出力フォーマット

### V1-V7 観察

| V | 指標 | 現在値 | 評価 |
|---|------|--------|------|
| V1 | skill_quality | ... | ... |
| ... | ... | ... | ... |

### Lean 構造

- Axiom 数: N
- Theorem 数: N
- Sorry 数: N
- ビルド状態: ...

### 停滞シグナル

- valueless_change: streak N (halt_recommended: Y/N)
- 他の停滞指標: ...

### 改善候補（列挙のみ、判断なし）

1. [Observable: 具体的な観察事実に基づく改善候補]
2. ...

TaskClassification タグ ([D] deterministic / [B] bounded / [J] judgmental) を各候補に付ける。
"""


def send_to_ccr(prompt: str, max_tokens: int = 8192) -> tuple[dict, float]:
    body = {
        "model": "claude-3-5-sonnet-20241022",
        "max_tokens": max_tokens,
        "messages": [{"role": "user", "content": prompt}],
    }
    req = urllib.request.Request(
        "http://localhost:3456/v1/messages",
        data=json.dumps(body).encode(),
        headers={
            "Authorization": "Bearer test",
            "Content-Type": "application/json",
            "anthropic-version": "2023-06-01",
        },
    )
    start = time.time()
    with urllib.request.urlopen(req, timeout=900) as resp:
        raw = resp.read()
    elapsed = time.time() - start
    return json.loads(raw), elapsed


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--max-tokens", type=int, default=8192)
    args = parser.parse_args()

    src = json.load(open(args.input))
    data_str = json.dumps(src.get("data", src), indent=2, ensure_ascii=False)
    prompt = OBSERVER_PROMPT_TEMPLATE.format(data=data_str)

    print(f"[observer-spot] input={args.input.name} prompt_chars={len(prompt)}")

    resp, elapsed = send_to_ccr(prompt, args.max_tokens)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(resp, ensure_ascii=False, indent=2))

    content = resp.get("content", [])
    text = next((b["text"] for b in content if b.get("type") == "text"), "")
    thinking = sum(len(b.get("thinking", "")) for b in content if b.get("type") == "thinking")

    print(f"[observer-spot] elapsed={elapsed:.1f}s model={resp.get('model','?')}")
    print(f"[observer-spot] thinking={thinking} chars, text={len(text)} chars")
    print(f"[observer-spot] stop={resp.get('stop_reason','?')}")
    print(f"[observer-spot] preview: {text[:400]}")


if __name__ == "__main__":
    main()
