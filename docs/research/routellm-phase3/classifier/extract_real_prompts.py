#!/usr/bin/env python3
"""
extract_real_prompts.py — Gap 2: 実セッション transcript から user prompts 抽出.

~/.claude/projects/<project>/*.jsonl に保存されている Claude Code の会話記録から
type=user の message を抜き、classifier 評価用の JSONL に整形する。
"""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter
from pathlib import Path


def iter_user_prompts(transcript_path: Path):
    try:
        for line in transcript_path.open():
            try:
                d = json.loads(line)
            except Exception:
                continue
            if d.get("type") != "user":
                continue
            msg = d.get("message", {})
            content = msg.get("content")
            if isinstance(content, str):
                yield content
            elif isinstance(content, list):
                # Anthropic content block format
                for block in content:
                    if isinstance(block, dict) and block.get("type") == "text":
                        yield block.get("text", "")
    except Exception:
        return


def is_meaningful(text: str, min_len: int = 20) -> bool:
    """Filter out tool results, XML tags, and short prompts."""
    if not text or len(text) < min_len:
        return False
    stripped = text.lstrip()
    if stripped.startswith("<") and stripped.endswith(">"):
        return False
    # Tool results and system messages
    if stripped.startswith("<tool_result>") or stripped.startswith("<command-"):
        return False
    # system-reminders
    if "<system-reminder>" in text[:50]:
        return False
    return True


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-dir", type=Path,
                        default=Path.home() / ".claude/projects/-Users-nirarin-work-agent-manifesto")
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--max-len", type=int, default=2000)
    parser.add_argument("--dedup", action="store_true")
    args = parser.parse_args()

    prompts = []
    sources = Counter()

    for transcript in sorted(args.project_dir.glob("*.jsonl")):
        session_id = transcript.stem[:8]
        for p in iter_user_prompts(transcript):
            if not is_meaningful(p):
                continue
            prompts.append({
                "session_id": session_id,
                "prompt": p[:args.max_len],
                "prompt_len": len(p),
                "truncated": len(p) > args.max_len,
                "source_file": transcript.name,
            })
            sources[session_id] += 1

    if args.dedup:
        seen = set()
        unique = []
        for p in prompts:
            key = p["prompt"][:200]
            if key in seen:
                continue
            seen.add(key)
            unique.append(p)
        print(f"[extract] dedup: {len(prompts)} → {len(unique)}")
        prompts = unique

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text("\n".join(json.dumps(p, ensure_ascii=False) for p in prompts) + "\n")

    lens = [p["prompt_len"] for p in prompts]
    print(f"[extract] {len(prompts)} prompts from {len(sources)} sessions")
    print(f"[extract] prompt len: mean={sum(lens)/len(lens):.0f} median={sorted(lens)[len(lens)//2]} max={max(lens)}")
    print(f"[extract] top 5 sessions by count: {sources.most_common(5)}")
    print(f"[extract] wrote {args.output}")


if __name__ == "__main__":
    main()
