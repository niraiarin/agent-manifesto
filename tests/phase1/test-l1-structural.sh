#!/usr/bin/env bash
set -uo pipefail
PASS=0; FAIL=0
BASE="$(git rev-parse --show-toplevel 2>/dev/null || echo /Users/nirarin/work/agent-manifesto)"

echo "=== Phase 1 v2: L1 Structural Tests ==="

check() {
  local name="$1" cond="$2"
  echo -n "$name... "
  if eval "$cond"; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL"; FAIL=$((FAIL+1)); fi
}

check "S1.1 settings.json has hooks" \
  "jq -e '.hooks' '$BASE/.claude/settings.json' >/dev/null 2>&1"

check "S1.2 PreToolUse Bash hook registered" \
  "jq -e '.hooks.PreToolUse[] | select(.matcher==\"Bash\")' '$BASE/.claude/settings.json' >/dev/null 2>&1"

check "S1.3 PreToolUse Edit hook registered" \
  "jq -e '.hooks.PreToolUse[] | select(.matcher==\"Edit\")' '$BASE/.claude/settings.json' >/dev/null 2>&1"

check "S1.4 PreToolUse Write hook registered" \
  "jq -e '.hooks.PreToolUse[] | select(.matcher==\"Write\")' '$BASE/.claude/settings.json' >/dev/null 2>&1"

# S1.5: 修正 — シンプルな比較
DENY_COUNT=$(jq '.permissions.deny | length' "$BASE/.claude/settings.json" 2>/dev/null || echo 0)
check "S1.5 deny list has 10+ entries (found: $DENY_COUNT)" \
  "[ '$DENY_COUNT' -ge 10 ]"

check "S1.6 l1-safety-check.sh exists and executable" \
  "[ -x '$BASE/.claude/hooks/l1-safety-check.sh' ]"

check "S1.7 l1-file-guard.sh exists and executable" \
  "[ -x '$BASE/.claude/hooks/l1-file-guard.sh' ]"

check "S1.8 L1 rules file exists" \
  "[ -f '$BASE/.claude/rules/l1-safety.md' ]"

check "S1.9 PostToolUse hooks are async-only (non-blocking)" \
  "jq -e '.hooks.PostToolUse[0].hooks[0].async == true' '$BASE/.claude/settings.json' >/dev/null 2>&1"

# S1.10: 修正 — 絶対パスが存在しないことを確認（反転ロジック修正）
check "S1.10 No absolute paths in hook commands" \
  "! jq -r '.hooks.PreToolUse[].hooks[].command' '$BASE/.claude/settings.json' | grep -q '^/'"

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
