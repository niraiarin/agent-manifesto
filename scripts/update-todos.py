#!/usr/bin/env python3
"""
update-todos.py — Knowledge Base 6-category todos.md writer / updater.

Traces: [S3 §3] AutoResearchClaw Knowledge Base.
Schema: .claude/skills/paperize/references/schemas/todos.schema.json

Inputs:
  - manifest.json (aggregate-jsonl.sh output) — source of new entries
  - existing todos.md (optional) — entries preserved unless superseded

Output:
  - todos.md (YAML front-matter + markdown sections by category)

The LLM Phase 2/3 produces candidate entries in a side channel; this script
merges them with existing todos, applies decay_days, and writes the final
todos.md deterministically.

Entry format (JSON, one per line) on stdin OR --entries-json:
  {"category":"decisions","text":"K=3 adopted","source":{"commit":"9159f62c"},
   "compatibility":"compatible change"}

Usage:
  echo '{"category":"questions","text":"margin threshold tuning?"}' \\
    | scripts/update-todos.py --manifest path/to/manifest.json \\
                              --output path/to/todos.md [--decay-days 30]
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import date, datetime, timedelta, timezone
from pathlib import Path

CATEGORIES = ["decisions", "experiments", "findings", "literature", "questions", "reviews"]
SCHEMA_VERSION = "1"


def _parse_entry(obj: dict, today: date, decay_days: int) -> dict:
    cat = obj.get("category")
    if cat not in CATEGORIES:
        raise ValueError(f"invalid category: {cat!r} (must be one of {CATEGORIES})")
    text = obj.get("text")
    if not text:
        raise ValueError("entry missing 'text'")
    entry = {
        "category": cat,
        "recorded_at": obj.get("recorded_at") or today.isoformat(),
        "text": text,
    }
    if "source" in obj and obj["source"]:
        entry["source"] = obj["source"]
    if "compatibility" in obj and obj["compatibility"]:
        entry["compatibility"] = obj["compatibility"]
    # decay only applies to `questions` by design
    if cat == "questions":
        decay_at = obj.get("decay_at")
        if not decay_at:
            rec = date.fromisoformat(entry["recorded_at"])
            decay_at = (rec + timedelta(days=decay_days)).isoformat()
        entry["decay_at"] = decay_at
    return entry


def _render_source(src: dict | None) -> str:
    if not src:
        return ""
    parts = []
    if "commit" in src:
        parts.append(f"commit `{src['commit'][:8]}`")
    if "pr" in src:
        parts.append(f"PR #{src['pr']}")
    if "issue" in src:
        parts.append(f"issue #{src['issue']}")
    if "file" in src:
        parts.append(f"file `{src['file']}`")
    return " / ".join(parts)


def _render_markdown(entries: list[dict], manifest_path: str, decay_days: int) -> str:
    now = datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")
    header = [
        "---",
        f"schema_version: \"{SCHEMA_VERSION}\"",
        f"generated_at: {now}",
        f"source_manifest: {manifest_path}",
        f"decay_days: {decay_days}",
        "---",
        "",
        "# Follow-up todos (Knowledge Base)",
        "",
    ]
    by_cat: dict[str, list[dict]] = {c: [] for c in CATEGORIES}
    for e in entries:
        by_cat[e["category"]].append(e)

    body: list[str] = []
    for cat in CATEGORIES:
        items = by_cat[cat]
        if not items:
            body.append(f"## {cat}\n\n_(empty)_\n")
            continue
        body.append(f"## {cat}\n")
        items.sort(key=lambda x: x["recorded_at"], reverse=True)
        for e in items:
            line = f"- [{e['recorded_at']}] {e['text']}"
            extras = []
            src = _render_source(e.get("source"))
            if src:
                extras.append(src)
            if "compatibility" in e:
                extras.append(e["compatibility"])
            if "decay_at" in e:
                extras.append(f"decay_at={e['decay_at']}")
            if extras:
                line += "  \n  - " + "  \n  - ".join(extras)
            body.append(line)
        body.append("")
    return "\n".join(header + body).rstrip() + "\n"


_FRONTMATTER_RE = re.compile(r"\A---\n(.*?)\n---\n", re.DOTALL)


def _parse_existing(path: Path) -> list[dict]:
    """Best-effort parse of prior todos.md entry lines.

    Non-deterministic manual edits are preserved only if they match our format.
    We parse lines starting with `- [YYYY-MM-DD] ` under `## <category>` headers.
    """
    if not path.exists():
        return []
    text = path.read_text()
    text = _FRONTMATTER_RE.sub("", text, count=1)
    entries: list[dict] = []
    current_cat = None
    for line in text.splitlines():
        stripped = line.strip()
        m = re.match(r"^##\s+(\w+)\s*$", stripped)
        if m:
            current_cat = m.group(1) if m.group(1) in CATEGORIES else None
            continue
        if not current_cat:
            continue
        m = re.match(r"^-\s+\[(\d{4}-\d{2}-\d{2})\]\s+(.*)$", stripped)
        if m:
            entries.append({
                "category": current_cat,
                "recorded_at": m.group(1),
                "text": m.group(2).strip(),
            })
    return entries


def _dedup(entries: list[dict]) -> list[dict]:
    seen = set()
    out = []
    for e in entries:
        key = (e["category"], e.get("recorded_at"), e["text"])
        if key in seen:
            continue
        seen.add(key)
        out.append(e)
    return out


def _load_stdin_entries(today: date, decay_days: int) -> list[dict]:
    if sys.stdin.isatty():
        return []
    out = []
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        out.append(_parse_entry(json.loads(line), today, decay_days))
    return out


def _load_json_entries(path: Path, today: date, decay_days: int) -> list[dict]:
    data = json.loads(path.read_text())
    if not isinstance(data, list):
        raise SystemExit(f"{path}: expected JSON array of entries")
    return [_parse_entry(obj, today, decay_days) for obj in data]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", type=Path, required=True,
                        help="path to manifest.json (for source_manifest header)")
    parser.add_argument("--output", type=Path, required=True,
                        help="path to todos.md (read + write)")
    parser.add_argument("--entries-json", type=Path, default=None,
                        help="JSON file with array of entry objects (in addition to stdin)")
    parser.add_argument("--decay-days", type=int, default=30,
                        help="days after which `questions` expire (default 30)")
    args = parser.parse_args()

    if not args.manifest.exists():
        raise SystemExit(f"manifest not found: {args.manifest}")

    today = date.today()

    entries = _parse_existing(args.output)
    entries.extend(_load_stdin_entries(today, args.decay_days))
    if args.entries_json:
        entries.extend(_load_json_entries(args.entries_json, today, args.decay_days))

    for e in entries:
        if e["category"] == "questions" and "decay_at" not in e:
            rec = date.fromisoformat(e["recorded_at"])
            e["decay_at"] = (rec + timedelta(days=args.decay_days)).isoformat()

    entries = _dedup(entries)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(_render_markdown(entries, str(args.manifest), args.decay_days))
    print(f"[update-todos] wrote {args.output} ({len(entries)} entries)")


if __name__ == "__main__":
    main()
