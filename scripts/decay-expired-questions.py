#!/usr/bin/env python3
"""
decay-expired-questions.py — move stale `questions` from todos.md to expired log.

Traces: [S3 §3] 30-day time decay.

Rules:
  - Only `## questions` entries are subject to decay.
  - An entry with `decay_at` < today is moved out of todos.md into
    <output-dir>/evidence/expired-questions.md.
  - Other categories (decisions, findings, etc.) are never decayed.

Usage:
  scripts/decay-expired-questions.py --todos path/to/todos.md \\
                                     --evidence-dir path/to/evidence
"""

from __future__ import annotations

import argparse
import re
from datetime import date, datetime, timezone
from pathlib import Path

CATEGORIES = ["decisions", "experiments", "findings", "literature", "questions", "reviews"]


def _split_sections(todos_text: str) -> tuple[str, dict[str, list[str]], str]:
    """Return (frontmatter_block, sections_lines_by_cat, trailing)."""
    m = re.match(r"\A(---\n.*?\n---\n)", todos_text, re.DOTALL)
    frontmatter = m.group(1) if m else ""
    body = todos_text[len(frontmatter):]

    sections: dict[str, list[str]] = {c: [] for c in CATEGORIES}
    current = None
    lines = body.splitlines()
    header_re = re.compile(r"^##\s+(\w+)\s*$")
    preamble: list[str] = []
    for line in lines:
        h = header_re.match(line.strip())
        if h and h.group(1) in CATEGORIES:
            current = h.group(1)
            continue
        if current is None:
            preamble.append(line)
        else:
            sections[current].append(line)

    # rejoin preamble as trailing-free header block
    return frontmatter, sections, "\n".join(preamble)


_ENTRY_RE = re.compile(r"^-\s+\[(\d{4}-\d{2}-\d{2})\]\s+")
_DECAY_RE = re.compile(r"decay_at\s*=\s*(\d{4}-\d{2}-\d{2})")


def _partition_questions(q_lines: list[str], today: date) -> tuple[list[str], list[str]]:
    """Walk indented entry blocks, split into (alive, expired)."""
    blocks: list[list[str]] = []
    cur: list[str] = []
    for line in q_lines:
        if _ENTRY_RE.match(line.strip()) and cur:
            blocks.append(cur)
            cur = [line]
        else:
            cur.append(line)
    if cur:
        blocks.append(cur)

    alive: list[str] = []
    expired: list[str] = []
    for block in blocks:
        joined = "\n".join(block)
        m = _DECAY_RE.search(joined)
        if not m:
            alive.extend(block)
            continue
        try:
            d = date.fromisoformat(m.group(1))
        except ValueError:
            alive.extend(block)
            continue
        if d < today:
            expired.extend(block)
        else:
            alive.extend(block)
    return alive, expired


def _render_todos(frontmatter: str, preamble: str, sections: dict[str, list[str]]) -> str:
    out = [frontmatter, preamble.rstrip(), ""]
    for cat in CATEGORIES:
        lines = sections[cat]
        trimmed = "\n".join(lines).strip("\n")
        if not trimmed:
            out.append(f"## {cat}\n\n_(empty)_\n")
        else:
            out.append(f"## {cat}\n")
            out.append(trimmed)
            out.append("")
    return "\n".join(out).rstrip() + "\n"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--todos", type=Path, required=True, help="path to todos.md")
    parser.add_argument("--evidence-dir", type=Path, required=True,
                        help="path to evidence/ directory (expired-questions.md written here)")
    parser.add_argument("--today", type=str, default=None,
                        help="override today (ISO date, for testing)")
    args = parser.parse_args()

    if not args.todos.exists():
        raise SystemExit(f"todos not found: {args.todos}")

    today = date.fromisoformat(args.today) if args.today else date.today()

    text = args.todos.read_text()
    fm, sections, preamble = _split_sections(text)
    alive, expired = _partition_questions(sections["questions"], today)
    sections["questions"] = alive

    args.todos.write_text(_render_todos(fm, preamble, sections))

    if expired:
        args.evidence_dir.mkdir(parents=True, exist_ok=True)
        expired_path = args.evidence_dir / "expired-questions.md"
        ts = datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")
        header = [
            "# Expired Questions",
            "",
            f"Decayed at {ts} (today = {today.isoformat()})",
            "",
        ]
        prior = expired_path.read_text() if expired_path.exists() else ""
        expired_path.write_text("\n".join(header) + "\n".join(expired) + "\n\n" + prior)
        print(f"[decay] moved {sum(1 for L in expired if _ENTRY_RE.match(L.strip()))} questions → {expired_path}")
    else:
        print("[decay] no expired questions")


if __name__ == "__main__":
    main()
