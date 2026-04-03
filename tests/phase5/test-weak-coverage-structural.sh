#!/usr/bin/env bash
# test-weak-coverage-structural.sh — 弱カバレッジ構造テスト
# Phase 5: P5, P6, L2, L3, L6, D7, D10, D12, D14 の弱カバレッジ検証
#
# テスト対象:
# - D10: evolve-state-loader.sh の存在と evolve-history.jsonl 参照
# - D7: adjust-action-space SKILL.md の d7_* 参照
# - L2: hallucination-check.sh の存在と Lean 検証機能
# - L6: p4-gate-logger.sh の存在と design-implementation-plan SKILL.md
# - P6: TaskClassification.lean + Principles.lean の定義
# - D12: DesignFoundation.lean の d12_* 定理
# - D14: DesignFoundation.lean の d14_* 定理
# - P5: Principles.lean の確率的解釈定理 + Foundation/Probability.lean

set -uo pipefail

BASE="$(git rev-parse --show-toplevel 2>/dev/null || echo /Users/nirarin/work/agent-manifesto)"
cd "$BASE"

PASS=0
FAIL=0

check() {
  local name="$1" cond="$2"
  echo -n "  $name... "
  if eval "$cond"; then echo "PASS"; PASS=$((PASS + 1)); else echo "FAIL"; FAIL=$((FAIL + 1)); fi
}

echo "=== Weak Coverage Structural Tests ==="
echo ""

# ============================================================
# D10: 構造永続性 — evolve-state-loader.sh
# ============================================================
echo "--- D10: Structural Permanence (evolve-state-loader) ---"

check "WC.1: .claude/hooks/evolve-state-loader.sh exists" \
  "[ -f '$BASE/.claude/hooks/evolve-state-loader.sh' ]"

check "WC.2: evolve-state-loader.sh references evolve-history.jsonl" \
  "grep -q 'evolve-history.jsonl' '$BASE/.claude/hooks/evolve-state-loader.sh'"

check "WC.3: evolve/SKILL.md references T1+T2" \
  "grep -q 'T1.*T2\|T2.*T1' '$BASE/.claude/skills/evolve/SKILL.md'"

echo ""

# ============================================================
# D7: 蓄積境界 / 毀損非有界 — adjust-action-space SKILL.md
# ============================================================
echo "--- D7: Accumulation bounded / Damage unbounded (adjust-action-space) ---"

check "WC.4: adjust-action-space/SKILL.md references d7_accumulation_bounded" \
  "grep -q 'd7_accumulation_bounded' '$BASE/.claude/skills/adjust-action-space/SKILL.md'"

check "WC.5: adjust-action-space/SKILL.md references d7_damage_unbounded" \
  "grep -q 'd7_damage_unbounded' '$BASE/.claude/skills/adjust-action-space/SKILL.md'"

check "WC.6: adjust-action-space/SKILL.md references defense design" \
  "grep -qi 'defense\|防護\|保護' '$BASE/.claude/skills/adjust-action-space/SKILL.md'"

echo ""

# ============================================================
# L2: 幻覚境界 — hallucination-check.sh
# ============================================================
echo "--- L2: Hallucination boundary (hallucination-check.sh) ---"

check "WC.7: .claude/hooks/hallucination-check.sh exists and is executable" \
  "[ -x '$BASE/.claude/hooks/hallucination-check.sh' ]"

check "WC.8: hallucination-check.sh validates Lean names" \
  "grep -qi 'lean' '$BASE/.claude/hooks/hallucination-check.sh'"

check "WC.9: hallucination-check.sh validates counts" \
  "grep -q 'count\|カウント' '$BASE/.claude/hooks/hallucination-check.sh'"

echo ""

# ============================================================
# L6: アーキテクチャ規約境界 — p4-gate-logger.sh, design-implementation-plan
# ============================================================
echo "--- L6: Architectural convention boundary (p4-gate-logger / design-implementation-plan) ---"

check "WC.10: .claude/hooks/p4-gate-logger.sh exists and is executable" \
  "[ -x '$BASE/.claude/hooks/p4-gate-logger.sh' ]"

check "WC.11: .claude/skills/design-implementation-plan/SKILL.md exists" \
  "[ -f '$BASE/.claude/skills/design-implementation-plan/SKILL.md' ]"

echo ""

# ============================================================
# P6: タスク自動化クラス — TaskClassification.lean + Principles.lean
# ============================================================
echo "--- P6: Task automation classification (TaskClassification + Principles) ---"

check "WC.12: TaskClassification.lean defines TaskAutomationClass" \
  "grep -q 'TaskAutomationClass' '$BASE/lean-formalization/Manifest/TaskClassification.lean'"

check "WC.13: Principles.lean has task_is_constraint_satisfaction" \
  "grep -q 'task_is_constraint_satisfaction' '$BASE/lean-formalization/Manifest/Principles.lean'"

check "WC.14: Principles.lean has task_is_constraint_satisfaction theorem" \
  "grep -q '^theorem task_is_constraint_satisfaction' '$BASE/lean-formalization/Manifest/Principles.lean'"

echo ""

# ============================================================
# D12: タスクは CSP / 設計は確率的 — DesignFoundation.lean
# ============================================================
echo "--- D12: Task is CSP / Design is probabilistic (DesignFoundation) ---"

check "WC.15: DesignFoundation.lean has d12_task_is_csp" \
  "grep -q 'd12_task_is_csp' '$BASE/lean-formalization/Manifest/DesignFoundation.lean'"

check "WC.16: DesignFoundation.lean has d12_task_design_probabilistic" \
  "grep -q 'd12_task_design_probabilistic' '$BASE/lean-formalization/Manifest/DesignFoundation.lean'"

echo ""

# ============================================================
# D14: 検証順序は CSP — DesignFoundation.lean
# ============================================================
echo "--- D14: Verification order is CSP (DesignFoundation) ---"

check "WC.17: DesignFoundation.lean has d14_verification_order_is_csp" \
  "grep -q 'd14_verification_order_is_csp' '$BASE/lean-formalization/Manifest/DesignFoundation.lean'"

echo ""

# ============================================================
# P5: 確率的解釈 — Principles.lean + Foundation/Probability.lean
# ============================================================
echo "--- P5: Probabilistic interpretation (Principles + Foundation/Probability) ---"

check "WC.18: Principles.lean has structure_interpretation_nondeterministic" \
  "grep -q 'structure_interpretation_nondeterministic' '$BASE/lean-formalization/Manifest/Principles.lean'"

check "WC.19: lean-formalization/Manifest/Foundation/Probability.lean exists" \
  "[ -f '$BASE/lean-formalization/Manifest/Foundation/Probability.lean' ]"

echo ""

# ============================================================
# L3: リソース境界 — Ontology.lean + Observable.lean + Axioms.lean
# ============================================================
echo "--- L3: Resource boundary (Ontology + Observable + Axioms) ---"

check "WC.20: Ontology.lean defines BoundaryId.resource (L3)" \
  "grep -q '| resource.*L3' '$BASE/lean-formalization/Manifest/Ontology.lean'"

check "WC.21: Observable.lean has resource_covered_by_constraint theorem (L3 derivation card)" \
  "grep -q '^theorem resource_covered_by_constraint' '$BASE/lean-formalization/Manifest/Observable.lean'"

check "WC.22: Observable.lean maps V7 to L3 via variableBoundary .v7 = .resource" \
  "grep -q '| .v7 => .resource' '$BASE/lean-formalization/Manifest/Observable.lean'"

check "WC.23: Axioms.lean has resource_finite axiom (T7 underlying L3)" \
  "grep -q '^axiom resource_finite' '$BASE/lean-formalization/Manifest/Axioms.lean'"

echo ""

# ============================================================
# Summary
# ============================================================
TOTAL=$((PASS + FAIL))
echo "=== Results: $PASS/$TOTAL passed ==="

if [ "$FAIL" -eq 0 ]; then
  exit 0
else
  exit 1
fi
