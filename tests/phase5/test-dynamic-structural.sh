#!/usr/bin/env bash
set -uo pipefail
PASS=0; FAIL=0
BASE="$(git rev-parse --show-toplevel 2>/dev/null || echo /Users/nirarin/work/agent-manifesto)"

echo "=== Phase 5: Dynamic Adjustment Structural Tests ==="

check() {
  local name="$1" cond="$2"
  echo -n "$name... "
  if eval "$cond"; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL"; FAIL=$((FAIL+1)); fi
}

check "S5.1 Action space adjustment skill exists" \
  "[ -f '$BASE/.claude/skills/adjust-action-space/SKILL.md' ]"

check "S5.2 Skill has expansion triggers" \
  "grep -qi 'expansion\|拡張トリガー' '$BASE/.claude/skills/adjust-action-space/SKILL.md'"

check "S5.3 Skill has contraction triggers" \
  "grep -qi 'contraction\|縮小トリガー' '$BASE/.claude/skills/adjust-action-space/SKILL.md'"

check "S5.4 Skill references D8 (equilibrium)" \
  "grep -qi 'D8\|均衡' '$BASE/.claude/skills/adjust-action-space/SKILL.md'"

check "S5.5 Skill references T6 (human authority)" \
  "grep -qi 'T6\|人間.*最終決定\|human' '$BASE/.claude/skills/adjust-action-space/SKILL.md'"

check "S5.6 Expansion requires defense design" \
  "grep -qi '防護設計\|defense\|防護' '$BASE/.claude/skills/adjust-action-space/SKILL.md'"

check "S5.7 All 5 phase test dirs exist" \
  "[ -d '$BASE/tests/phase1' ] && [ -d '$BASE/tests/phase2' ] && [ -d '$BASE/tests/phase3' ] && [ -d '$BASE/tests/phase4' ] && [ -d '$BASE/tests/phase5' ]"

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
