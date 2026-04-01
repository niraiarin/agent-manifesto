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

# 11.9: Judge evaluation criteria (G1-G4) in SKILL.md
if grep -q 'G1.*問い応答' ".claude/skills/research/SKILL.md"; then
  pass "SKILL.md has Judge evaluation criteria (G1-G4)"
else
  fail "SKILL.md has Judge evaluation criteria (G1-G4)"
fi

# 11.10: Judge evaluation criteria (G1-G4) in research-workflow.md
if grep -q 'G1.*Question Response' "docs/research/workflow/research-workflow.md"; then
  pass "research-workflow.md has Judge evaluation criteria (G1-G4)"
else
  fail "research-workflow.md has Judge evaluation criteria (G1-G4)"
fi

# 11.11: Step ordering consistency — Worktree before Experiment before Gate in SKILL.md
SKILL_WT=$(grep -n 'Step 4:.*Worktree\|Step 4:.*worktree' ".claude/skills/research/SKILL.md" | head -1 | cut -d: -f1)
SKILL_EX=$(grep -n 'Step 5:.*実験\|Step 5:.*Experiment' ".claude/skills/research/SKILL.md" | head -1 | cut -d: -f1)
SKILL_GT=$(grep -n 'Step 6:.*Judge\|Step 6:.*Gate' ".claude/skills/research/SKILL.md" | head -1 | cut -d: -f1)
if [[ -n "${SKILL_WT:-}" && -n "${SKILL_EX:-}" && -n "${SKILL_GT:-}" ]] && [[ "$SKILL_WT" -lt "$SKILL_EX" && "$SKILL_EX" -lt "$SKILL_GT" ]]; then
  pass "SKILL.md: Worktree < Experiment < Gate step order"
else
  fail "SKILL.md: Worktree < Experiment < Gate step order (WT=${SKILL_WT:-?} EX=${SKILL_EX:-?} GT=${SKILL_GT:-?})"
fi

# 11.12: Step ordering consistency — Worktree before Experiment before Gate in research-workflow.md
WF_WT=$(grep -n '^### [0-9]*\. .*[Ww]orktree' "docs/research/workflow/research-workflow.md" | head -1 | cut -d: -f1)
WF_EX=$(grep -n '^### [0-9]*\. .*[Ee]xperiment' "docs/research/workflow/research-workflow.md" | head -1 | cut -d: -f1)
WF_GT=$(grep -n '^### [0-9]*\. .*[Gg]ate\|^### [0-9]*\. .*[Jj]udge' "docs/research/workflow/research-workflow.md" | head -1 | cut -d: -f1)
if [[ -n "${WF_WT:-}" && -n "${WF_EX:-}" && -n "${WF_GT:-}" ]] && [[ "$WF_WT" -lt "$WF_EX" && "$WF_EX" -lt "$WF_GT" ]]; then
  pass "research-workflow.md: Worktree < Experiment < Gate step order"
else
  fail "research-workflow.md: Worktree < Experiment < Gate step order (WT=${WF_WT:-?} EX=${WF_EX:-?} GT=${WF_GT:-?})"
fi

# 11.13: Judge agent file exists
if [ -f ".claude/agents/judge.md" ]; then
  pass "Judge agent file exists"
else
  fail "Judge agent file exists"
fi

# 11.14: SKILL.md references judge.md
if grep -q 'judge\.md' ".claude/skills/research/SKILL.md"; then
  pass "SKILL.md references judge.md"
else
  fail "SKILL.md references judge.md"
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
