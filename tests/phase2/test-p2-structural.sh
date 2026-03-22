#!/usr/bin/env bash
# Phase 2: P2 構造的テスト
set -uo pipefail
PASS=0; FAIL=0
BASE="$(git rev-parse --show-toplevel 2>/dev/null || echo /Users/nirarin/work/agent-manifesto)"

echo "=== Phase 2: P2 Structural Tests ==="

check() {
  local name="$1" cond="$2"
  echo -n "$name... "
  if eval "$cond"; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL"; FAIL=$((FAIL+1)); fi
}

check "S2.1 Verifier agent definition exists" \
  "[ -f '$BASE/.claude/agents/verifier.md' ]"

check "S2.2 Verifier agent has model specified" \
  "grep -q 'model:' '$BASE/.claude/agents/verifier.md'"

check "S2.3 Verifier agent has read-only tools" \
  "grep -q 'Read' '$BASE/.claude/agents/verifier.md' && ! grep -q 'Edit\|Write\|Bash' '$BASE/.claude/agents/verifier.md'"

check "S2.4 Verify skill exists" \
  "[ -f '$BASE/.claude/skills/verify/SKILL.md' ]"

check "S2.5 P2 commit hook exists and executable" \
  "[ -x '$BASE/.claude/hooks/p2-verify-on-commit.sh' ]"

check "S2.6 P2 hook registered in settings.json" \
  "grep -q 'p2-verify-on-commit' '$BASE/.claude/settings.json'"

check "S2.7 Verify skill references D2 conditions" \
  "grep -qi 'コンテキスト分離\|context.*separation\|bias\|独立' '$BASE/.claude/skills/verify/SKILL.md'"

check "S2.8 Verify skill references Subagent" \
  "grep -qi 'subagent\|サブエージェント' '$BASE/.claude/skills/verify/SKILL.md'"

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
