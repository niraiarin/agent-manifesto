#!/usr/bin/env python3
"""
spot_check_questioner.py — Tier 2 spot check for Model-Questioner task (#647).

単一ターンの simulated dialogue: 仮想ユーザーのビジョン → C/H assumption 抽出。
Model-Questioner AGENT.md の Phase 0 (自由対話) → Phase 1 (構造化) を
1 プロンプトに折り畳んだ form。
"""

from __future__ import annotations

import argparse
import json
import time
import urllib.request
from pathlib import Path


QUESTIONER_PROMPT = """あなたは agent-manifesto プロジェクトの Model-Questioner エージェント。
人間のプロジェクトビジョンを聞き取り、認識論的層モデル (EpistemicLayerClass) の
条件付き公理体系 (C/H set) に必要な情報を抽出する。

## ユーザーのプロジェクトビジョン（Phase 0 free-form output）

```
{vision}
```

## タスク

このビジョンから以下を抽出し、構造化された JSON で出力する:

1. **要件 (requirements)**: 明示された目標・制約
2. **仮定 (assumptions)**: 明示されていないが前提となる事実。以下で分類:
   - `C` (Human Decision): 人間が選択した設計判断。人間が別の選択をしていたら変わる
   - `H` (LLM Inference): ドキュメント・経験から推論可能な事実
3. **不明点 (open_questions)**: ビジョンから判断できず追加対話が必要な項目
4. **L1-L6 層推定 (layer_inference)**: 各層の該当要素（L1 安全, L2 文脈, L3 人格, L4 行動, L5 生産物, L6 共有）

## 出力フォーマット

```json
{{
  "requirements": [
    {{"id": "R1", "text": "...", "priority": "high|medium|low"}}
  ],
  "assumptions": [
    {{"id": "CC-C1", "class": "C", "text": "...", "reason": "..."}},
    {{"id": "CC-H1", "class": "H", "text": "...", "falsifiability": "..."}}
  ],
  "open_questions": [
    {{"id": "Q1", "text": "...", "blocks_layer": "L4"}}
  ],
  "layer_inference": {{
    "L1_safety": ["..."],
    "L2_context": ["..."],
    "L3_persona": ["..."],
    "L4_action": ["..."],
    "L5_product": ["..."],
    "L6_shared": ["..."]
  }}
}}
```

JSON のみ出力。説明文は不要。
"""


SIMULATED_VISION = """
社内 Slack 用のナレッジボット を作りたい。

現状の問題:
- 社内 wiki (Notion) が散らかっていて、新人が質問を同じチャンネルに繰り返す
- 古い情報（過去の技術選定とか）が新しい wiki ページで上書きされず混在している
- Slack で聞くと「スレッドを遡ってね」と言われるが、チャンネルが多すぎて非現実的

欲しいもの:
- Slack の @mention で社内 wiki + 過去の Slack スレッドから答える
- 「これ古い情報かも」のフラグを付けてくれる（情報の鮮度を出す）
- 答えが wiki にない場合は「誰に聞くべきか」を推薦（社内の詳しい人を過去の発言から推定）
- 個人情報・機密情報は絶対に外部に出さない。全てローカル LLM で動く必要がある

制約:
- 社員 30 人の小さな会社。大規模 GPU クラスタはない
- Mac mini M4 (24GB) を 1 台用意できる
- Notion API + Slack API は既に導入済み
- 1 日 100-200 クエリ想定

使わないと思うもの:
- 画像生成・動画理解・多言語（日本語オンリー）

スケジュール:
- PoC を 2 週間で出したい。本番運用は 2 ヶ月後
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
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    prompt = QUESTIONER_PROMPT.format(vision=SIMULATED_VISION.strip())
    print(f"[questioner-spot] prompt_chars={len(prompt)}")

    resp, elapsed = send_to_ccr(prompt)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(resp, ensure_ascii=False, indent=2))

    content = resp.get("content", [])
    text = next((b["text"] for b in content if b.get("type") == "text"), "")
    thinking = sum(len(b.get("thinking", "")) for b in content if b.get("type") == "thinking")

    # Parse structured JSON output
    try:
        # Extract JSON block from markdown fence or raw
        import re
        m = re.search(r"```(?:json)?\s*(\{.*?\})\s*```", text, re.DOTALL)
        payload = json.loads(m.group(1)) if m else json.loads(text)
        n_req = len(payload.get("requirements", []))
        n_assum = len(payload.get("assumptions", []))
        n_c = sum(1 for a in payload.get("assumptions", []) if a.get("class") == "C")
        n_h = sum(1 for a in payload.get("assumptions", []) if a.get("class") == "H")
        n_open = len(payload.get("open_questions", []))
        layers = payload.get("layer_inference", {})
        n_layers_filled = sum(1 for k, v in layers.items() if v)
        parse_ok = True
    except Exception as e:
        parse_ok = False
        n_req = n_assum = n_c = n_h = n_open = n_layers_filled = 0

    print(f"[questioner-spot] elapsed={elapsed:.1f}s thinking={thinking} text={len(text)} stop={resp.get('stop_reason','?')}")
    print(f"[questioner-spot] parse_ok={parse_ok} req={n_req} assum={n_assum} (C={n_c},H={n_h}) open_q={n_open} layers_filled={n_layers_filled}/6")
    print(f"[questioner-spot] preview: {text[:300]}")


if __name__ == "__main__":
    main()
