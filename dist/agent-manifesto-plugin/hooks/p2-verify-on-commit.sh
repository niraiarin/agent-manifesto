#!/usr/bin/env bash
# P2 Verification Hook — PreToolUse: Bash (git commit)
#
# D8（均衡探索）: 段階的厳格化
# - 1回目の高リスクコミット → 警告（exit 0 + stderr）
# - 2回目以降 → ブロック（exit 2）
# 状態は /tmp に session ごとに記録。

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

if ! echo "$COMMAND" | grep -qE 'git\s+commit'; then
  exit 0
fi

STAGED=$(git diff --cached --name-only 2>/dev/null)
if [ -z "$STAGED" ]; then
  exit 0
fi

HIGH_RISK_PATTERNS='\.claude/|tests/|\.test\.|_test\.|settings\.json'
HIGH_RISK_FILES=$(echo "$STAGED" | grep -E "$HIGH_RISK_PATTERNS" || true)

if [ -n "$HIGH_RISK_FILES" ]; then
  SESSION=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null)
  STATE_FILE="/tmp/p2-warned-${SESSION}"

  if [ -f "$STATE_FILE" ]; then
    # 2回目以降: ブロック
    echo "P2: High-risk commit blocked. Run /verify first, then retry." >&2
    echo "Staged high-risk files:" >&2
    echo "$HIGH_RISK_FILES" | while read -r f; do echo "  - $f" >&2; done
    exit 2
  else
    # 1回目: 警告 + 状態記録
    touch "$STATE_FILE"
    echo "P2: High-risk files staged. Independent verification recommended." >&2
    echo "  Run /verify before committing. Next attempt will be blocked." >&2
    echo "Staged high-risk files:" >&2
    echo "$HIGH_RISK_FILES" | while read -r f; do echo "  - $f" >&2; done
    # 警告のみ
    exit 0
  fi
fi

exit 0
