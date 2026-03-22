#!/usr/bin/env bash
INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
if echo "$CMD" | grep -q "dangerous"; then
  echo "L1 SAFETY: Command contains 'dangerous' — blocked by PreToolUse hook" >&2
  exit 2
fi
exit 0
