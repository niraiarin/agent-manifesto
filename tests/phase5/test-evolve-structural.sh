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

# Hypothesizer 品質ゲート (obs-3-A, obs-3-B)
grep -q "事前検証チェックリスト\|Pre-Proposal Verification" "$HYP" && pass "Hypothesizer has pre-proposal verification checklist" || fail "Hypothesizer missing pre-proposal verification checklist"
grep -q "繰り返し提案の段階的抑止\|1 回 reject 後\|2 回以上 reject 後" "$HYP" && pass "Hypothesizer has repeated-proposal suppression rule" || fail "Hypothesizer missing repeated-proposal suppression rule"
grep -q "trivially-true.*回避\|trivially-true 定理の回避" "$HYP" && pass "Hypothesizer has trivially-true avoidance" || fail "Hypothesizer missing trivially-true avoidance"
grep -q "L1 行動空間制約\|hooks.*変更不可\|settings.json.*変更不可" "$HYP" && pass "Hypothesizer has L1 action space constraint" || fail "Hypothesizer missing L1 action space constraint"

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

# Workflow.lean 追加定理（Run 55 Gap 解消: no_self_knowledge_transition, knowledge_full_cycle_exists, feedback_precedes_improvement）
WORKFLOW_LEAN_PATH="lean-formalization/Manifest/Workflow.lean"
grep -q "no_self_knowledge_transition" "$WORKFLOW_LEAN_PATH" && pass "Lean trace: no_self_knowledge_transition exists in Workflow.lean" || fail "Lean trace: no_self_knowledge_transition not found in Workflow.lean"
grep -q "knowledge_full_cycle_exists" "$WORKFLOW_LEAN_PATH" && pass "Lean trace: knowledge_full_cycle_exists exists in Workflow.lean" || fail "Lean trace: knowledge_full_cycle_exists not found in Workflow.lean"
grep -q "feedback_precedes_improvement" "$WORKFLOW_LEAN_PATH" && pass "Lean trace: feedback_precedes_improvement exists in Workflow.lean" || fail "Lean trace: feedback_precedes_improvement not found in Workflow.lean"

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

# --- Loopback Redesign (Issue #7, #8, #9) ---
echo "--- Section 9b: Loopback Redesign (Issue #7, #8, #9) ---"

WORKFLOW_LEAN="lean-formalization/Manifest/Workflow.lean"

# φ₁₂: loopback target valid transition
grep -q "loopback_target_valid_transition" "$EVOLVE_SKILL_LEAN" && \
  pass "φ₁₂: loopback target valid transition" || \
  fail "φ₁₂: loopback_target_valid_transition not found"

# Lean trace: verification -> observation (observation_error loopback)
grep -q "verification.*observation.*True\|verification.*observation.*FAIL" "$WORKFLOW_LEAN" && \
  pass "Lean trace: verification -> observation (observation_error loopback)" || \
  fail "Missing verification -> observation transition in Workflow.lean"

# φ₁₃: loopback agent determined
grep -q "loopback_agent_determined" "$EVOLVE_SKILL_LEAN" && \
  pass "φ₁₃: loopback agent determined" || \
  fail "φ₁₃: loopback_agent_determined not found"

# φ₁₄: observation_error loops to observer
grep -q "observation_error_loops_to_observer" "$EVOLVE_SKILL_LEAN" && \
  pass "φ₁₄: observation_error loops to observer" || \
  fail "φ₁₄: observation_error_loops_to_observer not found"

# Issue #7: No hard-coded loopback limit without derivation
grep -q "LoopbackBudget\|ループバック予算" "$SKILL" && \
  pass "Issue #7: loopback budget parameterized (T6)" || \
  fail "Issue #7: loopback budget not parameterized"

# Issue #9: Loopback agent delegation documented
grep -q "loopbackTarget.*phaseAgent\|phaseAgent.*loopbackTarget\|loopback.*Observer.*observation_error\|observation_error.*Observer.*再起動\|observation_error.*Phase 1" "$SKILL" && \
  pass "Issue #9: loopback agent delegation documented" || \
  fail "Issue #9: loopback agent delegation not documented"

# φ₁₅: hypothesis_error loops to hypothesizer
grep -q "hypothesis_error_loops_to_hypothesizer" "$EVOLVE_SKILL_LEAN" && \
  pass "φ₁₅: hypothesis_error loops to hypothesizer" || \
  fail "φ₁₅: hypothesis_error_loops_to_hypothesizer not found"

# φ₁₆: precondition_error no loopback
grep -q "precondition_error_no_loopback" "$EVOLVE_SKILL_LEAN" && \
  pass "φ₁₆: precondition_error no loopback" || \
  fail "φ₁₆: precondition_error_no_loopback not found"

# φ₁₇: loopback_budget_is_parameter
grep -q "loopback_budget_is_parameter" "$EVOLVE_SKILL_LEAN" && \
  pass "φ₁₇: loopback budget is parameter" || \
  fail "φ₁₇: loopback_budget_is_parameter not found"

# Root cause classification completeness: all 4 types documented in SKILL.md
for rc in observation_error hypothesis_error assumption_error precondition_error; do
  echo -n "  Root cause '$rc' documented in SKILL.md... "
  grep -q "$rc" "$SKILL" && \
    pass "root cause $rc" || \
    fail "root cause $rc missing from SKILL.md"
done

# Loopback target mapping: each root cause maps to correct phase
echo -n "  observation_error -> Phase 1 mapping... "
grep -q "observation_error.*Phase 1\|observation_error.*Observer.*再起動" "$SKILL" && \
  pass "observation_error -> Phase 1" || \
  fail "observation_error -> Phase 1 mapping missing"

echo -n "  hypothesis_error -> Phase 2 mapping... "
grep -q "hypothesis_error.*Phase 2\|hypothesis_error.*Hypothesizer.*再起動\|hypothesis_error.*再設計" "$SKILL" && \
  pass "hypothesis_error -> Phase 2" || \
  fail "hypothesis_error -> Phase 2 mapping missing"

echo -n "  precondition_error -> no loopback mapping... "
grep -q "precondition_error.*ループバックなし\|precondition_error.*次の項目" "$SKILL" && \
  pass "precondition_error -> no loopback" || \
  fail "precondition_error -> no loopback mapping missing"

echo ""

# --- Section 10: evolve-history.jsonl notes/deferred 整合性 ---
echo "--- Section 10: Notes-Deferred Consistency ---"

HISTORY="$BASE/.claude/metrics/evolve-history.jsonl"
# 前方参照キーワードを含む notes が deferred=[] のエントリを検出
# Run 41 で制約を導入。それ以降の新規エントリのみ検証対象。
# 過去エントリの遡及修正は append-only 規約に反するため除外。
#
# 同一 Run ID に複数エントリがある場合（暫定記録と確定記録が混在）、
# 最終エントリ（ファイル末尾側）のみを orphan 検証対象とする。
# 根拠: SKILL.md Step 5 不変条件「1 Run につき 1 エントリのみ」だが、
#       移行期に暫定エントリが存在する場合の後方互換性を確保するため。
ORPHAN_COUNT=$(python3 -c "
import json, sys
FORWARD_KEYWORDS = ['次回', '次の evolve', 'next run', 'next evolve', '蓄積待ち', '蓄積され次第', '可能になる', 'が必要', 'TODO', 'remaining']
ENFORCEMENT_START = 41
# 同一 Run ID は最終エントリのみ対象（暫定記録を除外）
last_by_run = {}
for line in open('$HISTORY'):
    try:
        rec = json.loads(line.strip())
        run = rec.get('run')
        if run is not None and run >= ENFORCEMENT_START:
            last_by_run[run] = rec
    except:
        pass
count = 0
for rec in last_by_run.values():
    notes = rec.get('notes', '')
    deferred = rec.get('deferred', [])
    if not notes or not isinstance(deferred, list):
        continue
    has_forward_ref = any(k in notes for k in FORWARD_KEYWORDS)
    has_resolution_marker = any(k in notes for k in ['確認完了', '解消', '解決', 'resolved', 'completed'])
    if has_forward_ref and not has_resolution_marker and len(deferred) == 0:
        count += 1
print(count)
" 2>/dev/null)
echo -n "  No orphan forward-references in notes... "
if [ "${ORPHAN_COUNT:-0}" -eq 0 ]; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL ($ORPHAN_COUNT orphans)"; FAIL=$((FAIL+1)); fi

echo ""

# ============================================================
# Section 11: Structural Coherence (Half-Order) — Section 8 対応
# ============================================================
echo "--- Section 11: Structural Coherence (Half-Order) ---"

ONTOLOGY="$BASE/lean-formalization/Manifest/Ontology.lean"
DESIGN_FOUNDATION="$BASE/lean-formalization/Manifest/DesignFoundation.lean"
MANIFESTO="$BASE/manifesto.md"

# StructureKind inductive 存在
echo -n "  StructureKind inductive exists... "
grep -q "^inductive StructureKind" "$ONTOLOGY" && \
  pass "StructureKind inductive" || \
  fail "StructureKind inductive missing"

# StructureKind.priority 定義
echo -n "  StructureKind.priority defined... "
grep -q "def StructureKind.priority" "$ONTOLOGY" && \
  pass "StructureKind.priority" || \
  fail "StructureKind.priority missing"

# structureDependsOn 定義
echo -n "  structureDependsOn defined... "
grep -q "def structureDependsOn" "$ONTOLOGY" && \
  pass "structureDependsOn" || \
  fail "structureDependsOn missing"

# coherenceRequirement 定義
echo -n "  coherenceRequirement defined... "
grep -q "def coherenceRequirement" "$ONTOLOGY" && \
  pass "coherenceRequirement" || \
  fail "coherenceRequirement missing"

# 狭義半順序 3 性質
echo -n "  no_self_dependency theorem... "
grep -q "^theorem no_self_dependency" "$ONTOLOGY" && \
  pass "no_self_dependency" || \
  fail "no_self_dependency missing"

echo -n "  structureDependsOn_transitive theorem... "
grep -q "^theorem structureDependsOn_transitive" "$ONTOLOGY" && \
  pass "structureDependsOn_transitive" || \
  fail "structureDependsOn_transitive missing"

echo -n "  structureDependsOn_asymmetric theorem... "
grep -q "^theorem structureDependsOn_asymmetric" "$ONTOLOGY" && \
  pass "structureDependsOn_asymmetric" || \
  fail "structureDependsOn_asymmetric missing"

# 隣接優先度 4 定理
for thm in priority_manifest_gt_design priority_design_gt_skill priority_skill_gt_test priority_test_gt_document; do
  echo -n "  $thm theorem... "
  grep -q "^theorem $thm" "$ONTOLOGY" && \
    pass "$thm" || \
    fail "$thm missing"
done

# 極値 3 定理
for thm in manifest_highest_priority document_lowest_priority priority_injective; do
  echo -n "  $thm theorem... "
  grep -q "^theorem $thm" "$ONTOLOGY" && \
    pass "$thm" || \
    fail "$thm missing"
done

# D13 定理 2 件
echo -n "  d13_coherence_implies_propagation theorem... "
grep -q "^theorem d13_coherence_implies_propagation" "$DESIGN_FOUNDATION" && \
  pass "d13_coherence_implies_propagation" || \
  fail "d13_coherence_implies_propagation missing"

echo -n "  d13_retirement_requires_feedback theorem... "
grep -q "^theorem d13_retirement_requires_feedback" "$DESIGN_FOUNDATION" && \
  pass "d13_retirement_requires_feedback" || \
  fail "d13_retirement_requires_feedback missing"

# manifesto.md Section 8 存在
echo -n "  manifesto.md Section 8 (Structural Coherence) exists... "
grep -q "構造的整合性\|Structural Coherence" "$MANIFESTO" && \
  pass "Section 8 exists" || \
  fail "Section 8 missing"

# ============================================================
# Section 12: StructureKind LE/LT インスタンスと半順序性質定理
# ============================================================
echo "--- Section 12: StructureKind LE/LT Instances ---"

# LE インスタンスの存在
echo -n "  StructureKind LE instance exists... "
grep -q "^instance : LE StructureKind" "$ONTOLOGY" && \
  pass "StructureKind LE instance" || \
  fail "StructureKind LE instance missing"

# LT インスタンスの存在
echo -n "  StructureKind LT instance exists... "
grep -q "^instance : LT StructureKind" "$ONTOLOGY" && \
  pass "StructureKind LT instance" || \
  fail "StructureKind LT instance missing"

# 半順序性質: 反射律
echo -n "  structureKind_le_refl theorem exists... "
grep -q "^theorem structureKind_le_refl" "$ONTOLOGY" && \
  pass "structureKind_le_refl" || \
  fail "structureKind_le_refl missing"

# 半順序性質: 推移律
echo -n "  structureKind_le_trans theorem exists... "
grep -q "^theorem structureKind_le_trans" "$ONTOLOGY" && \
  pass "structureKind_le_trans" || \
  fail "structureKind_le_trans missing"

# 半順序性質: 反対称律（priority_injective から導出）
echo -n "  structureKind_le_antisymm theorem exists... "
grep -q "^theorem structureKind_le_antisymm" "$ONTOLOGY" && \
  pass "structureKind_le_antisymm" || \
  fail "structureKind_le_antisymm missing"

# LT と LE の整合性
echo -n "  structureKind_lt_iff_le_not_le theorem exists... "
grep -q "^theorem structureKind_lt_iff_le_not_le" "$ONTOLOGY" && \
  pass "structureKind_lt_iff_le_not_le" || \
  fail "structureKind_lt_iff_le_not_le missing"

echo ""

# ============================================================
# Section 13: Procedure.lean AGM Bridge 定理 Traceability（Run 56 Gap 解消）
# ============================================================
echo "--- Section 13: Procedure.lean AGM Bridge Theorems ---"

PROCEDURE_LEAN="$BASE/lean-formalization/Manifest/Procedure.lean"

grep -q "manifest_contraction_forbidden'" "$PROCEDURE_LEAN" && pass "Lean trace: manifest_contraction_forbidden' exists in Procedure.lean" || fail "Lean trace: manifest_contraction_forbidden' not found in Procedure.lean"
grep -q "manifest_revision_forbidden" "$PROCEDURE_LEAN" && pass "Lean trace: manifest_revision_forbidden exists in Procedure.lean" || fail "Lean trace: manifest_revision_forbidden not found in Procedure.lean"
grep -q "non_manifest_all_ops_permitted" "$PROCEDURE_LEAN" && pass "Lean trace: non_manifest_all_ops_permitted exists in Procedure.lean" || fail "Lean trace: non_manifest_all_ops_permitted not found in Procedure.lean"
grep -q "empty_world_no_contraction_affected" "$PROCEDURE_LEAN" && pass "Lean trace: empty_world_no_contraction_affected exists in Procedure.lean" || fail "Lean trace: empty_world_no_contraction_affected not found in Procedure.lean"
grep -q "manifest_no_contraction_affected" "$PROCEDURE_LEAN" && pass "Lean trace: manifest_no_contraction_affected exists in Procedure.lean" || fail "Lean trace: manifest_no_contraction_affected not found in Procedure.lean"
grep -q "contraction_affected_trans" "$PROCEDURE_LEAN" && pass "Lean trace: contraction_affected_trans exists in Procedure.lean" || fail "Lean trace: contraction_affected_trans not found in Procedure.lean"

echo ""

# ============================================================
# Section 14: D5 三層断裂修正の維持確認
# ============================================================
echo "--- Section 14: D5 Traceability Maintenance ---"

LEAN_TRACE="$BASE/.claude/skills/evolve/references/lean-traceability.md"
DESIGN_IMPL_PLAN="$BASE/.claude/skills/design-implementation-plan/SKILL.md"
FORMAL_DERIV="$BASE/.claude/skills/formal-derivation/SKILL.md"

# lean-traceability.md 存在確認
echo -n "  lean-traceability.md exists... "
[ -f "$LEAN_TRACE" ] && pass "lean-traceability.md exists" || fail "lean-traceability.md missing at .claude/skills/evolve/references/lean-traceability.md"

# Gap 列の存在確認
echo -n "  lean-traceability.md has Gap column... "
grep -q "Gap\|ギャップ" "$LEAN_TRACE" 2>/dev/null && pass "Gap column exists" || fail "Gap column missing in lean-traceability.md"

# FAIL loopback エントリの存在確認
echo -n "  lean-traceability.md has FAIL loopback entry... "
grep -q "loopback\|FAIL.*ループバック\|ループバック.*FAIL" "$LEAN_TRACE" 2>/dev/null && pass "FAIL loopback entry exists" || fail "FAIL loopback entry missing in lean-traceability.md"

# /design-implementation-plan D5 traceability チェックリスト存在確認
echo -n "  /design-implementation-plan has D5 traceability checklist... "
grep -q "D5.*トレーサビリティ\|traceability.*D5\|D5.*traceability\|逆引き可能\|三者間.*対応.*D5\|D5.*形式仕様.*テスト" "$DESIGN_IMPL_PLAN" 2>/dev/null && pass "D5 traceability checklist exists in design-implementation-plan" || fail "D5 traceability checklist missing in design-implementation-plan"

# /formal-derivation Step 4d 逆方向トレーサビリティ存在確認
echo -n "  /formal-derivation has Step 4d reverse traceability... "
grep -q "Step 4d\|逆方向トレーサビリティ\|reverse.*traceability\|traceability.*reverse" "$FORMAL_DERIV" 2>/dev/null && pass "Step 4d reverse traceability exists in formal-derivation" || fail "Step 4d reverse traceability missing in formal-derivation"

echo ""

# ============================================================
# スキル変数展開の安全性（全 SKILL.md 対象）
# ============================================================
echo "--- Skill variable expansion safety ---"

# SKILL.md 内の $0, $1, ... $9 はスキルローダーにより引数展開される。
# 意図しない展開を防ぐため、$[0-9] パターンが SKILL.md に含まれないことを検証する。
# 判例: Run 54 — H6 仮説テーブルの "$1.07" がスキル引数に展開され内容破損。
for skill_file in .claude/skills/*/SKILL.md; do
  skill_name="$(basename "$(dirname "$skill_file")")"
  echo -n "  $skill_name SKILL.md: no unescaped \$[0-9] patterns... "
  if grep -qE '\$[0-9]' "$skill_file" 2>/dev/null; then
    fail "$skill_name contains \$[0-9] — will be expanded by skill loader"
  else
    pass "$skill_name safe"
  fi
done

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
