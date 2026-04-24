#!/usr/bin/env python3
"""
spot_check_writing.py — Tier 2 spot check for /paperize writing task (#647).

Sends a section-writing prompt to Q2 via ccr, captures response.
Input: outline + evidence summary. Output: paper section (markdown).
"""

from __future__ import annotations

import argparse
import json
import time
import urllib.request
from pathlib import Path


WRITING_PROMPT_TEMPLATE = """あなたは /paperize skill の Writing Agent。
PaperOrchestra 5-agent pipeline の Section Writing フェーズを担当する。

与えられた outline と evidence から指定セクションの本文を生成する。
- single-pass writeup（反復なし）
- 未検証事実には [UNVERIFIED] タグを付ける
- 内部 citation は 8-char SHA 付きで (commit `xxxxxxxx`) / (PR #N) 形式
- ページ予算内で簡潔に
- 数値主張は必ず evidence への参照を伴う

## Outline（対象セクション: {section_name}）

{outline}

## Evidence

{evidence}

## 出力

`{section_name}` セクション本文のみ markdown で出力。
他セクションのプレースホルダやメタ説明は含めない。
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
    parser.add_argument("--section", type=str, required=True,
                        help="section name, e.g. 'Method' or 'Findings'")
    parser.add_argument("--outline-file", type=Path, required=True)
    parser.add_argument("--evidence-file", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    outline_text = args.outline_file.read_text()
    evidence_text = args.evidence_file.read_text()

    prompt = WRITING_PROMPT_TEMPLATE.format(
        section_name=args.section,
        outline=outline_text[:4000],
        evidence=evidence_text[:8000],
    )

    print(f"[writing-spot] section={args.section} prompt_chars={len(prompt)}")
    resp, elapsed = send_to_ccr(prompt)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(resp, ensure_ascii=False, indent=2))

    content = resp.get("content", [])
    text = next((b["text"] for b in content if b.get("type") == "text"), "")
    thinking = sum(len(b.get("thinking", "")) for b in content if b.get("type") == "thinking")

    print(f"[writing-spot] elapsed={elapsed:.1f}s thinking={thinking} text={len(text)} stop={resp.get('stop_reason','?')}")
    print(f"[writing-spot] preview: {text[:400]}")


if __name__ == "__main__":
    main()
