#!/usr/bin/env bash
# exit 0 + JSON で ask を返す
cat << 'JSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "ask",
    "permissionDecisionReason": "PoC2: This command requires human confirmation"
  }
}
JSON
exit 0
