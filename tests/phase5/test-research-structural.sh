#!/usr/bin/env bash
# test-research-structural.sh — /research スキルの構造テスト
# Phase 5: 構造テスト
#
# テスト対象:
# - /research SKILL.md の存在と構造
# - P3 ライフサイクルとの対応
# - Gate 判定テンプレートの存在

set -euo pipefail

BASE="$(git rev-parse --show-toplevel 2>/dev/null || echo /Users/nirarin/work/agent-manifesto)"
cd "$BASE"

PASS=0
FAIL=0
TOTAL=0

pass() {
  PASS=$((PASS + 1))
  TOTAL=$((TOTAL + 1))
  echo "  PASS: $1"
}

fail() {
  FAIL=$((FAIL + 1))
  TOTAL=$((TOTAL + 1))
  echo "  FAIL: $1"
}

echo "--- Section 11: Research Skill Structural Tests ---"

# 11.1: SKILL.md exists
if [ -f ".claude/skills/research/SKILL.md" ]; then
  pass "SKILL.md exists"
else
  fail "SKILL.md exists"
fi

# 11.2: frontmatter has name: research
if grep -q '^name: research' ".claude/skills/research/SKILL.md"; then
  pass "frontmatter name: research"
else
  fail "frontmatter name: research"
fi

# 11.3: P3 lifecycle table present
if grep -q 'P3.*段階\|P3 段階\|P3 ライフサイクル' ".claude/skills/research/SKILL.md"; then
  pass "P3 lifecycle table present"
else
  fail "P3 lifecycle table present"
fi

# 11.4: Gate judgment template present (PASS/CONDITIONAL/FAIL)
if grep -q 'PASS.*CONDITIONAL.*FAIL\|PASS.*FAIL' ".claude/skills/research/SKILL.md"; then
  pass "Gate judgment template present"
else
  fail "Gate judgment template present"
fi

# 11.5: Anti-patterns section present
if grep -q 'アンチパターン' ".claude/skills/research/SKILL.md"; then
  pass "Anti-patterns section present"
else
  fail "Anti-patterns section present"
fi

# 11.6: D13 reference present
if grep -q 'D13\|d13_propagation' ".claude/skills/research/SKILL.md"; then
  pass "D13 reference present"
else
  fail "D13 reference present"
fi

# 11.7: CLAUDE.md lists /research skill
if grep -q '/research' "CLAUDE.md"; then
  pass "CLAUDE.md lists /research"
else
  fail "CLAUDE.md lists /research"
fi

# 11.8: Workflow reference doc exists
if [ -f "docs/research/workflow/research-workflow.md" ]; then
  pass "Workflow reference doc exists"
else
  fail "Workflow reference doc exists"
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
