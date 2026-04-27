-- Phase 5 PI-18: critical theorem axiom dependency extraction (Day 193)
--
-- 用途: lake env lean ./scripts/print_axioms_critical.lean
-- 出力: stdout に各 theorem の #print axioms 結果
--
-- 50 critical theorems の cover範囲:
-- - T1-T8 axioms (8 件)
-- - E1-E2 axioms (2 件)
-- - P1-P6 main theorems (6 件)
-- - D1-D18 main theorems (18 件)
-- - V1-V7 measurable (7 件)
-- - その他主要 theorem (9 件)

import AgentSpec

-- T1-T8 axioms
#print axioms AgentSpec.Manifest.session_bounded
#print axioms AgentSpec.Manifest.no_cross_session_memory
#print axioms AgentSpec.Manifest.session_no_shared_state
#print axioms AgentSpec.Manifest.structure_persists
#print axioms AgentSpec.Manifest.structure_accumulates
#print axioms AgentSpec.Manifest.context_finite
#print axioms AgentSpec.Manifest.context_bounds_action
#print axioms AgentSpec.Manifest.output_nondeterministic

-- E1-E2 axioms
#print axioms AgentSpec.Manifest.verification_requires_independence
#print axioms AgentSpec.Manifest.shared_bias_reduces_detection

-- P main
#print axioms AgentSpec.Manifest.cognitive_separation_required
#print axioms AgentSpec.Manifest.no_self_verification

-- D main
#print axioms AgentSpec.Manifest.d1_fixed_requires_structural
#print axioms AgentSpec.Manifest.d1_enforcement_monotone
#print axioms AgentSpec.Manifest.d2_from_e1
#print axioms AgentSpec.Manifest.d3_observability_precedes_improvement
#print axioms AgentSpec.Manifest.d4_no_self_dependency
#print axioms AgentSpec.Manifest.d4_full_chain
#print axioms AgentSpec.Manifest.critical_requires_all_four
#print axioms AgentSpec.Manifest.subagent_only_sufficient_for_low

-- V measurable
#print axioms AgentSpec.Manifest.v1_measurable
#print axioms AgentSpec.Manifest.v2_measurable
#print axioms AgentSpec.Manifest.v3_measurable
#print axioms AgentSpec.Manifest.v4_measurable
#print axioms AgentSpec.Manifest.v5_measurable
#print axioms AgentSpec.Manifest.v6_measurable
#print axioms AgentSpec.Manifest.v7_measurable

-- 他主要 theorem
#print axioms AgentSpec.Manifest.constraint_has_boundary
#print axioms AgentSpec.Manifest.platform_not_in_constraint_boundary
#print axioms AgentSpec.Manifest.measurable_threshold_observable
#print axioms AgentSpec.Manifest.system_health_observable
#print axioms AgentSpec.Manifest.degradation_detectable_observable
#print axioms AgentSpec.Manifest.observable_and
#print axioms AgentSpec.Manifest.observable_or
#print axioms AgentSpec.Manifest.observable_not
