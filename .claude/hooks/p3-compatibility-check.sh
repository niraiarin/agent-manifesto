#!/usr/bin/env bash
# P3 Compatibility Classification — PreToolUse: Bash (git commit)
#
# D8（均衡探索）: 段階的厳格化
# - 1回目 → 警告
# - 2回目以降で分類なし → ブロック

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

if ! echo "$COMMAND" | grep -qE 'git\s+commit'; then
  exit 0
fi

# Resolve git working directory for worktree support
GIT_DIR=""
if echo "$COMMAND" | grep -qE '^[[:space:]]*cd[[:space:]]+'; then
GIT_DIR=$(echo "$COMMAND" | sed -n 's/^[[:space:]]*cd[[:space:]][[:space:]]*\("\([^"]*\)"\|\([^ &;]*\)\).*//p')
fi
GIT_CMD=(git)
if [ -n "$GIT_DIR" ] && [ -d "$GIT_DIR" ]; then
GIT_CMD=(git -C "$GIT_DIR")
fi
STRUCTURAL_PATTERNS='\.claude/|tests/|manifesto\.md|docs/|research/|reports/|lean-formalization/'
STAGED=$(git diff --cached --name-only 2>/dev/null)

if echo "$STAGED" | grep -qE "$STRUCTURAL_PATTERNS"; then
  # コミットメッセージから互換性分類を検出（POSIX 互換）
  MSG=$(echo "$COMMAND" | sed -n 's/.*-m[[:space:]]*["'"'"']\([^"'"'"']*\)["'"'"'].*/\1/p')

  if echo "$MSG$COMMAND" | grep -qiE '(conservative|compatible|breaking|保守的|互換的|破壊的)'; then
    exit 0
  fi

  SESSION=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null)
  STATE_FILE="/tmp/p3-warned-${SESSION}"

  if [ -f "$STATE_FILE" ]; then
    echo "P3: Structural commit BLOCKED — compatibility classification required." >&2
    echo "Include one of: conservative extension / compatible change / breaking change" >&2
    exit 2
  else
    touch "$STATE_FILE"
    echo "P3: Structural files changed. Commit message should include compatibility classification:" >&2
    echo "  - conservative extension / compatible change / breaking change" >&2
    echo "Next attempt without classification will be blocked." >&2
    exit 0
  fi
fi

exit 0
