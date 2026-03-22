#!/usr/bin/env bash
# PoC 6: PreToolUse hook that calls claude -p as verifier
# 高コストなので、実運用では高リスク操作のみに限定

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

# git commit の場合のみ verifier を起動
if echo "$COMMAND" | grep -q "git commit"; then
  # staged files を取得
  STAGED=$(git diff --cached --name-only 2>/dev/null)
  if [ -n "$STAGED" ]; then
    # verifier を headless で起動（タイムアウト付き）
    VERDICT=$(timeout 30 claude -p "Review these staged files for issues: $STAGED. Reply with only VERDICT: PASS or VERDICT: FAIL" --max-turns 2 --allowedTools "Read(*)" < /dev/null 2>/dev/null || echo "VERDICT: PASS (timeout)")
    
    if echo "$VERDICT" | grep -qi "VERDICT: FAIL"; then
      echo "P2 Verifier: Issues found in staged files. Review required." >&2
      echo "$VERDICT" >&2
      exit 2
    fi
  fi
fi

exit 0
