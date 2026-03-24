#!/usr/bin/env bash
# test-evolve-structural.sh — /evolve スキルの構造テスト
# Phase 5: 構造テスト + 回帰テスト
#
# テスト対象:
# - /evolve SKILL.md の存在と構造
# - Agent 定義の存在と構造
# - マニフェスト概念との整合性
# - Lean 形式化との整合性参照
# - Hook の登録

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

echo "=== /evolve Structure Tests ==="
echo ""

# ============================================================
# 1. ファイル存在テスト
# ============================================================
echo "--- 1. File Existence ---"

[ -f ".claude/skills/evolve/SKILL.md" ] && pass "SKILL.md exists" || fail "SKILL.md missing"
[ -f ".claude/agents/observer/AGENT.md" ] && pass "Observer AGENT.md exists" || fail "Observer AGENT.md missing"
[ -f ".claude/agents/hypothesizer/AGENT.md" ] && pass "Hypothesizer AGENT.md exists" || fail "Hypothesizer AGENT.md missing"
[ -f ".claude/agents/integrator/AGENT.md" ] && pass "Integrator AGENT.md exists" || fail "Integrator AGENT.md missing"
[ -f ".claude/agents/verifier.md" ] && pass "Verifier agent exists" || fail "Verifier agent missing"

echo ""

# ============================================================
# 2. SKILL.md 構造テスト
# ============================================================
echo "--- 2. SKILL.md Structure ---"

SKILL=".claude/skills/evolve/SKILL.md"

# frontmatter
grep -q "^name: evolve" "$SKILL" && pass "SKILL.md has name" || fail "SKILL.md missing name"
grep -q "^description:" "$SKILL" && pass "SKILL.md has description" || fail "SKILL.md missing description"

# マニフェスト概念の参照
grep -q "T1.*一時" "$SKILL" && pass "References T1 (ephemeral sessions)" || fail "Missing T1 reference"
grep -q "T2.*永続" "$SKILL" && pass "References T2 (persistent structure)" || fail "Missing T2 reference"
grep -q "T6.*人間" "$SKILL" && pass "References T6 (human authority)" || fail "Missing T6 reference"
grep -q "P2.*検証\|P2.*分離" "$SKILL" && pass "References P2 (cognitive separation)" || fail "Missing P2 reference"
grep -q "P3.*統治\|P3.*学習" "$SKILL" && pass "References P3 (governed learning)" || fail "Missing P3 reference"
grep -q "P4.*可観測" "$SKILL" && pass "References P4 (observability)" || fail "Missing P4 reference"

# 学習ライフサイクルの全フェーズ
grep -q "観察" "$SKILL" && pass "Lifecycle: observation" || fail "Missing observation phase"
grep -q "仮説化" "$SKILL" && pass "Lifecycle: hypothesizing" || fail "Missing hypothesizing phase"
grep -q "検証" "$SKILL" && pass "Lifecycle: verification" || fail "Missing verification phase"
grep -q "統合" "$SKILL" && pass "Lifecycle: integration" || fail "Missing integration phase"
grep -q "退役" "$SKILL" && pass "Lifecycle: retirement" || fail "Missing retirement phase"

# D9 自己適用
grep -q "D9.*自己\|自己適用\|SelfGoverning" "$SKILL" && pass "D9 self-application" || fail "Missing D9 self-application"

# 互換性分類
grep -q "conservative extension" "$SKILL" && pass "Compatibility: conservative extension" || fail "Missing conservative extension"
grep -q "compatible change" "$SKILL" && pass "Compatibility: compatible change" || fail "Missing compatible change"
grep -q "breaking change" "$SKILL" && pass "Compatibility: breaking change" || fail "Missing breaking change"

# Lean 形式化との対応表
grep -q "Workflow.lean" "$SKILL" && pass "Lean reference: Workflow.lean" || fail "Missing Workflow.lean reference"
grep -q "Evolution.lean" "$SKILL" && pass "Lean reference: Evolution.lean" || fail "Missing Evolution.lean reference"
grep -q "Procedure.lean" "$SKILL" && pass "Lean reference: Procedure.lean" || fail "Missing Procedure.lean reference"
grep -q "DesignFoundation.lean" "$SKILL" && pass "Lean reference: DesignFoundation.lean" || fail "Missing DesignFoundation.lean reference"

echo ""

# ============================================================
# 3. Agent 定義の構造テスト
# ============================================================
echo "--- 3. Agent Definitions ---"

# Observer
OBS=".claude/agents/observer/AGENT.md"
grep -q "^name: observer" "$OBS" && pass "Observer has name" || fail "Observer missing name"
grep -q "P4.*可観測" "$OBS" && pass "Observer references P4" || fail "Observer missing P4"
grep -q "metrics" "$OBS" && pass "Observer references metrics" || fail "Observer missing metrics"
grep -q "V1-V7\|V1–V7" "$OBS" && pass "Observer references V1-V7" || fail "Observer missing V1-V7"

# Hypothesizer
HYP=".claude/agents/hypothesizer/AGENT.md"
grep -q "^name: hypothesizer" "$HYP" && pass "Hypothesizer has name" || fail "Hypothesizer missing name"
grep -q "P3.*仮説\|P3.*学習" "$HYP" && pass "Hypothesizer references P3" || fail "Hypothesizer missing P3"
grep -q "互換性分類" "$HYP" && pass "Hypothesizer references compatibility" || fail "Hypothesizer missing compatibility"
grep -q "反証条件" "$HYP" && pass "Hypothesizer references refutation" || fail "Hypothesizer missing refutation"
grep -q "読み取り専用" "$HYP" && pass "Hypothesizer is read-only" || fail "Hypothesizer missing read-only constraint"
! grep -q "Edit\|Write" "$HYP" && pass "Hypothesizer has no Edit/Write tools" || fail "Hypothesizer should not have Edit/Write"

# Integrator
INT=".claude/agents/integrator/AGENT.md"
grep -q "^name: integrator" "$INT" && pass "Integrator has name" || fail "Integrator missing name"
grep -q "P3.*統合\|P3.*学習" "$INT" && pass "Integrator references P3" || fail "Integrator missing P3"
grep -q "git commit" "$INT" && pass "Integrator references git commit" || fail "Integrator missing git commit"
grep -q "T6\|人間.*承認" "$INT" && pass "Integrator references T6" || fail "Integrator missing T6"

# Retirement criteria separation (Issue 3 fix)
grep -q "Workflow.lean.*retirementCandidate\|基準 A.*Lean" "$SKILL" && pass "Formal retirement criteria (Workflow.lean)" || fail "Missing formal retirement criteria"
grep -q "p3-governed-learning\|基準 B.*ポリシー\|6ヶ月" "$SKILL" && pass "Policy retirement criteria (p3)" || fail "Missing policy retirement criteria"

# P2 limitation transparency (Issue 4 fix)
grep -q "moderate.*レベル\|P2.*限界" "$SKILL" && pass "P2 limitation documented" || fail "Missing P2 limitation note"

echo ""

# ============================================================
# 4. 仮説の明示テスト（Γ \ T₀ が反証可能）
# ============================================================
echo "--- 4. Hypotheses (refutable) ---"

grep -q "H1.*Agent Teams\|H1:.*Teams" "$SKILL" && pass "H1 documented" || fail "H1 missing"
grep -q "H2.*エージェント分離\|H2:.*分離" "$SKILL" && pass "H2 documented" || fail "H2 missing"
grep -q "H3.*指標\|H3:.*Goodhart" "$SKILL" && pass "H3 documented" || fail "H3 missing"
grep -q "反証条件" "$SKILL" && pass "Refutation conditions present" || fail "Missing refutation conditions"

echo ""

# ============================================================
# 5. Claude Code 機能活用テスト
# ============================================================
echo "--- 5. Claude Code Feature Coverage ---"

grep -q "Skills" "$SKILL" && pass "Uses Skills" || fail "Missing Skills"
grep -q "Agents\|AGENT.md" "$SKILL" && pass "Uses Agents" || fail "Missing Agents"
grep -q "Hook\|hook" "$SKILL" && pass "Uses Hooks" || fail "Missing Hooks"
grep -q "Memory\|MEMORY" "$SKILL" && pass "Uses Memory" || fail "Missing Memory"
grep -q "settings\|permissions" "$SKILL" && pass "Uses Settings/Permissions" || fail "Missing Settings"
grep -q "git" "$SKILL" && pass "Uses Git" || fail "Missing Git"
grep -q "metrics" "$SKILL" && pass "Uses Metrics" || fail "Missing Metrics"
grep -q "Bash\|bash" "$SKILL" && pass "Uses CLI/Bash" || fail "Missing CLI"

echo ""

# ============================================================
# 6. Hook 登録テスト
# ============================================================
echo "--- 6. Hook Registration ---"

SETTINGS=".claude/settings.json"
[ -f ".claude/hooks/evolve-state-loader.sh" ] && pass "evolve-state-loader.sh exists" || fail "evolve-state-loader.sh missing"
[ -f ".claude/hooks/evolve-metrics-recorder.sh" ] && pass "evolve-metrics-recorder.sh exists" || fail "evolve-metrics-recorder.sh missing"
grep -q "evolve-state-loader" "$SETTINGS" && pass "evolve-state-loader registered in settings.json" || fail "evolve-state-loader not in settings.json"
grep -q "evolve-metrics-recorder" "$SETTINGS" && pass "evolve-metrics-recorder registered in settings.json" || fail "evolve-metrics-recorder not in settings.json"

echo ""

# ============================================================
# 7. Lean Formal Spec Traceability（D5 三層対応検証）
# ============================================================
echo "--- 7. Lean Formal Spec Traceability ---"

# Workflow.lean の validPhaseTransition 6 ケースが SKILL.md/AGENT.md に対応しているか確認

# observation -> hypothesizing (Phase 1 -> Phase 2)
grep -q "観察\|observation" "$SKILL" && grep -q "仮説化\|hypothesiz" "$SKILL" && pass "Lean trace: observation -> hypothesizing (Phase 1->2 in SKILL.md)" || fail "Lean trace: observation -> hypothesizing not covered in SKILL.md"

# hypothesizing -> verification (Phase 2 -> Phase 3)
grep -q "仮説化\|hypothesiz" "$SKILL" && grep -q "検証\|verif" "$SKILL" && pass "Lean trace: hypothesizing -> verification (Phase 2->3 in SKILL.md)" || fail "Lean trace: hypothesizing -> verification not covered in SKILL.md"

# verification -> integration (Phase 3 -> Phase 4)
grep -q "検証\|verif" "$SKILL" && grep -q "統合\|integrat" "$SKILL" && pass "Lean trace: verification -> integration (Phase 3->4 in SKILL.md)" || fail "Lean trace: verification -> integration not covered in SKILL.md"

# integration -> retirement (Phase 4 -> Phase 5)
grep -q "統合\|integrat" "$SKILL" && grep -q "退役\|retir" "$SKILL" && pass "Lean trace: integration -> retirement (Phase 4->5 in SKILL.md)" || fail "Lean trace: integration -> retirement not covered in SKILL.md"

# verification -> hypothesizing (FAIL ループバック) — D5 断裂修復の核心
grep -q "FAIL.*分析\|ループバック\|loopback" "$SKILL" && pass "Lean trace: verification -> hypothesizing (FAIL loopback in SKILL.md)" || fail "Lean trace: FAIL loopback (verification->hypothesizing) not documented in SKILL.md"

# retirement -> observation (サイクル循環)
grep -q "退役\|retir" "$SKILL" && grep -q "観察\|observ" "$SKILL" && pass "Lean trace: retirement -> observation (cycle in SKILL.md)" || fail "Lean trace: retirement -> observation cycle not covered in SKILL.md"

echo ""

# ============================================================
# Section 8: T→L マッピング形式化（constraintBoundary）
# ============================================================
echo "--- Section 8: T→L Mapping Formalization ---"

ONTOLOGY="lean-formalization/Manifest/Ontology.lean"
OBSERVABLE="lean-formalization/Manifest/Observable.lean"

# ConstraintId が Ontology.lean に存在
grep -q "^inductive ConstraintId" "$ONTOLOGY" && pass "ConstraintId defined in Ontology.lean" || fail "ConstraintId not found in Ontology.lean"

# constraintBoundary が Observable.lean に存在
grep -q "^def constraintBoundary" "$OBSERVABLE" && pass "constraintBoundary defined in Observable.lean" || fail "constraintBoundary not found in Observable.lean"

# T1-T8 全ケースが定義されている
for t in t1 t2 t3 t4 t5 t6 t7 t8; do
  grep -q "\.$t =>" "$OBSERVABLE" && pass "constraintBoundary covers .$t" || fail "constraintBoundary missing .$t"
done

# constraint_has_boundary 定理が存在
grep -q "^theorem constraint_has_boundary" "$OBSERVABLE" && pass "constraint_has_boundary theorem exists" || fail "constraint_has_boundary theorem not found"

# platform_not_in_constraint_boundary 定理が存在（L5 除外の形式化）
grep -q "^theorem platform_not_in_constraint_boundary" "$OBSERVABLE" && pass "platform_not_in_constraint_boundary theorem exists (L5 exclusion)" || fail "platform_not_in_constraint_boundary theorem not found"

# constraint_boundary_covers_except_platform 定理が存在（L5 以外の網羅性）
grep -q "^theorem constraint_boundary_covers_except_platform" "$OBSERVABLE" && pass "constraint_boundary_covers_except_platform theorem exists" || fail "constraint_boundary_covers_except_platform theorem not found"

echo ""

# ============================================================
# Section 9: EvolveSkill.lean Theorem Traceability (D5)
# ============================================================
echo "--- Section 9: EvolveSkill.lean Theorem Traceability ---"

EVOLVE_SKILL_LEAN="lean-formalization/Manifest/EvolveSkill.lean"

# φ₁: Phase order
grep -q "phase_order_aligns_with_workflow" "$EVOLVE_SKILL_LEAN" && pass "Lean trace: EvolveSkill φ₁ phase_order_aligns_with_workflow" || fail "Lean trace: EvolveSkill φ₁ phase_order_aligns_with_workflow"

# φ₂: All agents used
grep -q "all_agents_used" "$EVOLVE_SKILL_LEAN" && pass "Lean trace: EvolveSkill φ₂ all_agents_used" || fail "Lean trace: EvolveSkill φ₂ all_agents_used"

# φ₃: Verifier sufficient for low
grep -q "evolve_verifier_sufficient_for_low" "$EVOLVE_SKILL_LEAN" && pass "Lean trace: EvolveSkill φ₃ evolve_verifier_sufficient_for_low" || fail "Lean trace: EvolveSkill φ₃ evolve_verifier_sufficient_for_low"

# φ₁₁: Deferral requires justification
grep -q "deferral_requires_justification" "$EVOLVE_SKILL_LEAN" && pass "Lean trace: EvolveSkill φ₁₁ deferral_requires_justification" || fail "Lean trace: EvolveSkill φ₁₁ deferral_requires_justification"

# Composite: evolve_skill_compliant
grep -q "evolve_skill_compliant" "$EVOLVE_SKILL_LEAN" && pass "Lean trace: EvolveSkill composite evolve_skill_compliant" || fail "Lean trace: EvolveSkill composite evolve_skill_compliant"

# φ₆: Conservative strategy safe
grep -q "conservative_strategy_safe" "$EVOLVE_SKILL_LEAN" && pass "Lean trace: EvolveSkill φ₆ conservative_strategy_safe" || fail "Lean trace: EvolveSkill φ₆ conservative_strategy_safe"

echo ""

# ============================================================
# 結果サマリ
# ============================================================
echo "=== Results: $PASS passed, $FAIL failed ==="
echo ""

if [ "$FAIL" -gt 0 ]; then
  exit 1
else
  exit 0
fi
