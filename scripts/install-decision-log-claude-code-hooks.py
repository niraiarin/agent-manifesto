#!/usr/bin/env python3
"""
install-decision-log-claude-code-hooks.py — patch .claude/settings.json to
register decision-log-emit.sh on UserPromptSubmit / PreToolUse / PostToolUse / Stop.

Governance: this script modifies a governance config file. Run only with
explicit user authorization. Idempotent (re-running detects existing entries).
A timestamped backup is written next to the original.

Usage:
  python3 scripts/install-decision-log-claude-code-hooks.py

Reverts:
  cp .claude/settings.json.pre-decision-log.<timestamp>.bak .claude/settings.json
"""

from __future__ import annotations

import json
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path


REGISTRATIONS = [
    ("UserPromptSubmit", "user.turn"),
    ("PreToolUse", "agent.tool_call"),
    ("PostToolUse", "agent.tool_call_complete"),
    ("Stop", "agent.output"),
]


def main() -> int:
    repo_root = Path(__file__).resolve().parent.parent
    settings_path = repo_root / ".claude" / "settings.json"
    if not settings_path.exists():
        print(f"[install] settings.json not found at {settings_path}", file=sys.stderr)
        return 1

    backup_path = settings_path.with_suffix(
        f".json.pre-decision-log.{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}.bak"
    )
    shutil.copy(settings_path, backup_path)
    print(f"[install] backup: {backup_path}")

    settings = json.loads(settings_path.read_text())
    added: list[tuple[str, str]] = []
    for event_name, event_type in REGISTRATIONS:
        existing = settings.setdefault("hooks", {}).setdefault(event_name, [])
        already = any(
            any(
                (h.get("command") or "").endswith(f"decision-log-emit.sh {event_type}")
                for h in (m.get("hooks") or [])
            )
            for m in existing
        )
        if already:
            print(f"  {event_name:18s}: already registered, skipping")
            continue
        existing.append(
            {
                "matcher": "",
                "hooks": [
                    {
                        "type": "command",
                        "command": f"bash $CLAUDE_PROJECT_DIR/scripts/decision-log-emit.sh {event_type}",
                        "async": True,
                    }
                ],
            }
        )
        added.append((event_name, event_type))
        print(f"  {event_name:18s}: added decision-log-emit.sh {event_type}")

    if not added:
        print("[install] no changes — all 4 registrations already present")
        backup_path.unlink(missing_ok=True)
        return 0

    settings_path.write_text(json.dumps(settings, ensure_ascii=False, indent=2) + "\n")
    print(f"\n[install] wrote {settings_path}")
    print(f"[install] {len(added)} new registrations")
    print(f"[install] revert with: cp {backup_path} {settings_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
