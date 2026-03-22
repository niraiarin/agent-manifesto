#!/usr/bin/env bash
set -uo pipefail
PASS=0; FAIL=0
BASE="$(git rev-parse --show-toplevel 2>/dev/null || echo /Users/nirarin/work/agent-manifesto)"

echo "=== Phase 4: P3 Structural Tests ==="

check() {
  local name="$1" cond="$2"
  echo -n "$name... "
  if eval "$cond"; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL"; FAIL=$((FAIL+1)); fi
}

check "S4.1 Compatibility check hook exists" \
  "[ -x '$BASE/.claude/hooks/p3-compatibility-check.sh' ]"

check "S4.2 Hook registered in settings.json" \
  "grep -q 'p3-compatibility-check' '$BASE/.claude/settings.json'"

check "S4.3 Governed learning rules exist" \
  "[ -f '$BASE/.claude/rules/p3-governed-learning.md' ]"

check "S4.4 Rules reference compatibility classification" \
  "grep -q 'conservative extension' '$BASE/.claude/rules/p3-governed-learning.md'"

check "S4.5 Rules reference retirement" \
  "grep -qi '退役\|retirement' '$BASE/.claude/rules/p3-governed-learning.md'"

check "S4.6 Rules reference lifecycle stages" \
  "grep -qi '観察.*仮説.*検証.*統合.*退役' '$BASE/.claude/rules/p3-governed-learning.md'"

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
