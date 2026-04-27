-- Phase 5 PI-18: critical theorem axiom dependency extraction (Day 193、source side)
--
-- 用途: lake env lean ./scripts/print_axioms_critical.lean (lean-formalization 内)
-- 出力: stdout に各 theorem の #print axioms 結果

import Manifest

-- T1-T8 axioms
#print axioms Manifest.session_bounded
#print axioms Manifest.no_cross_session_memory
#print axioms Manifest.session_no_shared_state
#print axioms Manifest.structure_persists
#print axioms Manifest.structure_accumulates
#print axioms Manifest.context_finite
#print axioms Manifest.context_bounds_action
#print axioms Manifest.output_nondeterministic

-- E1-E2 axioms
#print axioms Manifest.verification_requires_independence
#print axioms Manifest.shared_bias_reduces_detection

-- P main
#print axioms Manifest.cognitive_separation_required
#print axioms Manifest.no_self_verification

-- D main
#print axioms Manifest.d1_fixed_requires_structural
#print axioms Manifest.d1_enforcement_monotone
#print axioms Manifest.d2_from_e1
#print axioms Manifest.d3_observability_precedes_improvement
#print axioms Manifest.d4_no_self_dependency
#print axioms Manifest.d4_full_chain
#print axioms Manifest.critical_requires_all_four
#print axioms Manifest.subagent_only_sufficient_for_low

-- V measurable
#print axioms Manifest.v1_measurable
#print axioms Manifest.v2_measurable
#print axioms Manifest.v3_measurable
#print axioms Manifest.v4_measurable
#print axioms Manifest.v5_measurable
#print axioms Manifest.v6_measurable
#print axioms Manifest.v7_measurable

-- 他主要 theorem
#print axioms Manifest.constraint_has_boundary
#print axioms Manifest.platform_not_in_constraint_boundary
#print axioms Manifest.measurable_threshold_observable
#print axioms Manifest.system_health_observable
#print axioms Manifest.degradation_detectable_observable
#print axioms Manifest.observable_and
#print axioms Manifest.observable_or
#print axioms Manifest.observable_not
