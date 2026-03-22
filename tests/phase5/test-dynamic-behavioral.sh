#!/usr/bin/env bash
set -uo pipefail
PASS=0; FAIL=0
BASE="$(git rev-parse --show-toplevel 2>/dev/null || echo /Users/nirarin/work/agent-manifesto)"

echo "=== Phase 5: Dynamic Adjustment Behavioral Tests ==="

check() {
  local name="$1" cond="$2"
  echo -n "$name... "
  if eval "$cond"; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL"; FAIL=$((FAIL+1)); fi
}

# B5.1: 拡張トリガー条件が具体的な閾値を含む
check "B5.1 Expansion requires V4 > 90%" \
  "grep -q '90' '$BASE/.claude/skills/adjust-action-space/SKILL.md'"

# B5.2: 縮小トリガー条件が具体的な閾値を含む
check "B5.2 Contraction triggers on V4 < 70%" \
  "grep -q '70' '$BASE/.claude/skills/adjust-action-space/SKILL.md'"

# B5.3: 拡張には全条件の同時充足が必要（AND）
check "B5.3 Expansion requires ALL conditions" \
  "grep -qi '全て\|すべて\|all' '$BASE/.claude/skills/adjust-action-space/SKILL.md'"

# B5.4: 縮小はいずれか1条件で発動（OR）
check "B5.4 Contraction triggers on ANY condition" \
  "grep -qi 'いずれか\|any' '$BASE/.claude/skills/adjust-action-space/SKILL.md'"

# B5.5: 拡張提案に防護設計フィールドがある
check "B5.5 Expansion proposal includes defense design" \
  "grep -q '防護設計' '$BASE/.claude/skills/adjust-action-space/SKILL.md'"

# B5.6: T6（人間が最終決定者）が明記
check "B5.6 Human approval required (T6)" \
  "grep -qi '人間.*承認\|Elicitation' '$BASE/.claude/skills/adjust-action-space/SKILL.md'"

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
