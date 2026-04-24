#!/usr/bin/env bash
# decision-log-emit.sh — Claude Code hook script that emits decision_event v1.0.0.
#
# Invocation contract: Claude Code passes hook input JSON on stdin. We parse it,
# append a decision event to the daily JSONL, and pass the original stdin through
# so Claude Code is never blocked.
#
# Registration (manual, requires human approval to edit .claude/settings.json):
#   {
#     "hooks": {
#       "UserPromptSubmit": [{"hooks": [{"type": "command",
#          "command": "bash $CLAUDE_PROJECT_DIR/scripts/decision-log-emit.sh user.turn"}]}],
#       "PreToolUse":      [{"hooks": [{"type": "command",
#          "command": "bash $CLAUDE_PROJECT_DIR/scripts/decision-log-emit.sh agent.tool_call"}]}],
#       "PostToolUse":     [{"hooks": [{"type": "command",
#          "command": "bash $CLAUDE_PROJECT_DIR/scripts/decision-log-emit.sh agent.tool_call_complete"}]}],
#       "Stop":            [{"hooks": [{"type": "command",
#          "command": "bash $CLAUDE_PROJECT_DIR/scripts/decision-log-emit.sh agent.output"}]}]
#     }
#   }
#
# Environment overrides:
#   DECISION_LOG_DIR        — destination (default: <repo>/docs/research/routellm-phase3/logs)
#   DECISION_LOG_REDACTION  — "none" | "prompt_sha_only" (default: prompt_sha_only)
#   DECISION_LOG_PROJECT_ID — project tag in context (default: agent-manifesto)
#
# Best-effort: any failure is logged to stderr and exit 0 is returned so Claude
# Code is never blocked.

set -u

EVENT_TYPE="${1:-manual.note}"
INPUT="$(cat)"

LOG_DIR="${DECISION_LOG_DIR:-${CLAUDE_PROJECT_DIR:-.}/docs/research/routellm-phase3/logs}"
REDACTION="${DECISION_LOG_REDACTION:-prompt_sha_only}"

mkdir -p "$LOG_DIR" 2>/dev/null || true
DATE=$(date -u +%Y-%m-%d)
LOG_FILE="$LOG_DIR/decisions-$DATE.jsonl"

# Delegate JSON assembly to Python (stdlib only). If Python is missing or
# the script errors, we simply exit 0 without writing — never break session.
# We use DECISION_LOG_PAYLOAD env var rather than stdin because stdin is
# already consumed above into $INPUT.
DECISION_LOG_PAYLOAD="$INPUT" python3 -c "$(cat <<'PY'
import hashlib
import json
import os
import sys
import uuid
from datetime import datetime, timezone

event_type, log_file, redaction = sys.argv[1], sys.argv[2], sys.argv[3]

raw = os.environ.get("DECISION_LOG_PAYLOAD", "")
try:
    payload = json.loads(raw) if raw.strip() else {}
except Exception:
    payload = {"_raw": raw[:500]}

session_id = (
    payload.get("session_id")
    or os.environ.get("CLAUDE_SESSION_ID")
    or os.environ.get("DECISION_LOG_SESSION_ID")
    or f"cc-{uuid.uuid4()}"
)
project_path = os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd()
working_dir = os.getcwd()
parent_event_id = payload.get("parent_event_id") or os.environ.get("DECISION_LOG_PARENT_ID")

def sha256_hex(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()

context = {
    "session_id": session_id,
    "project_id": os.environ.get("DECISION_LOG_PROJECT_ID", "agent-manifesto"),
    "project_path": project_path,
    "working_directory": working_dir,
}

input_section = None
if event_type in {"user.turn", "user.correction"}:
    prompt = payload.get("prompt") or payload.get("user_prompt") or ""
    input_section = {
        "prompt_sha256": sha256_hex(prompt),
        "prompt_length": len(prompt),
        "prompt_source": "user",
    }
    if redaction == "none" and prompt:
        input_section["prompt"] = prompt

decision_section = None
if event_type in {"agent.tool_call", "agent.tool_call_complete"}:
    tool_name = payload.get("tool_name") or payload.get("name")
    tool_input = payload.get("tool_input") or payload.get("input") or {}
    args_json = json.dumps(tool_input, ensure_ascii=False, sort_keys=True)
    decision_section = {
        "kind": "tool_call",
        "name": tool_name or "unknown",
        "args_sha": sha256_hex(args_json),
        "args_preview": args_json[:200],
    }

execution_section = None
outcome_section = None
if event_type == "agent.tool_call_complete":
    tool_response = payload.get("tool_response") or {}
    success = not bool(tool_response.get("error"))
    execution_section = {
        "success": success,
        "error_class": tool_response.get("error_class") if not success else None,
    }
    outcome_section = {
        "horizon": "immediate",
        "exit_status": "completed" if success else "failed",
    }
elif event_type == "agent.output":
    outcome_section = {
        "horizon": "immediate",
        "exit_status": payload.get("exit_status", "completed"),
    }

envelope = {
    "schema_version": "1.0.0",
    "event_id": str(uuid.uuid4()),
    "parent_event_id": parent_event_id,
    "event_type": event_type,
    "timestamp_utc": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
    "context": context,
    "provenance": {
        "schema_version": "1.0.0",
        "logger_version": "1.0.0",
        "recorded_by": "claude-code-hook",
        "hook_id": f"{event_type}.decision-log-emit",
        "redaction_level": redaction,
    },
}
if input_section is not None:
    envelope["input"] = input_section
if decision_section is not None:
    envelope["decision"] = decision_section
if execution_section is not None:
    envelope["execution"] = execution_section
if outcome_section is not None:
    envelope["outcome"] = outcome_section

try:
    with open(log_file, "a", encoding="utf-8") as f:
        f.write(json.dumps(envelope, ensure_ascii=False, separators=(",", ":")) + "\n")
except OSError:
    pass
PY
)" "$EVENT_TYPE" "$LOG_FILE" "$REDACTION" >/dev/null 2>&1

# Pass through the original hook input unchanged (Claude Code contract).
printf '%s' "$INPUT"
exit 0
