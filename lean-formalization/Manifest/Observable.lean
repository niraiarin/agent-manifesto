import Manifest.Ontology
import Manifest.Axioms

/-!
# Epistemic Layer - Boundary Strength 2 - Foundation of V1-V7 Observable Variables

**Variables are not boundary conditions.** They are parameters that agents can improve
through structure, serving as indicators of structural quality. If boundary conditions
(L1–L6 in Ontology.lean) are "walls of the action space," then variables are
"levers that structure can move within those walls."

However, variables are **not independent levers but a mutually interacting system**.

## Layer Separation

This file contains only definitions belonging to the **boundary layer (strength 2)**:
- Opaque definitions for V1–V7 and Measurable axioms (measurability guarantees)
- Measurability axioms for trust/degradation
- systemHealthy (basic definition of system health)
- Mapping structure from boundaries to variables to constraints
- Measurable to Observable bridge theorems

Definitions belonging to the designTheorem layer (strength 1) — tradeoffs, Goodhart,
investment cycles, HealthThresholds, Pareto, etc. — are separated into
**ObservableDesign.lean**.

## Position as Gamma Extension of T_0
Procedure Manual 2.4.

The axioms in this file belong to the extension part (Gamma \ T_0) of the premise set Gamma,
and are non-logical axioms (§4.1) derived from design decisions (domain model premises,
design judgments). They constitute a consistent extension (Glossary §5.5) of T_0 (Axioms.lean)
and may be subject to contraction (§9.2) in the revision loop.

## Design Policy

Boundary conditions (T) are immovable walls, mitigations (L) are design decisions,
and variables (V) are measures of **how well** mitigations work.

## Observable vs Measurable

- **Observable** (`World → Prop` is decidable) — binary judgment. Similar to preconditions/postconditions in Glossary §9.3
- **Measurable** (`World → Nat` is computable) — quantitative measurement. Glossary §9.5 note: distinct from the measure-theoretic concept of measurable functions

V1–V7 are quantitative indicators and are therefore formalized as `Measurable`.
`Measurable m` means "a procedure exists to compute the value of `m` from external observations."

## Prerequisite - Observability P4

By P4 (observability of degradation), variables **become optimization targets only when
they are observable**.

For each variable, the following questions are posed:
- **Is the current value observable?** Does a measurement method exist, and is measurement actually being performed?
- **Is degradation detectable?** If the value worsens, can it be detected before quality collapse?
- **Is improvement verifiable?** Can the change in value be compared before and after intervention?

A variable without means of observation is merely a nominal optimization target.

## V1-V7 Correspondence Table

| Definition | V | Description | Measurement Method | Related Boundary Conditions |
|------------|---|-------------|-------------------|-----------------------------|
| `skillQuality` | V1 | Precision and effectiveness of skill definitions | benchmark.json | L2, L5 |
| `contextEfficiency` | V2 | Utilization of finite context | completion rate / token count | L2, L3 |
| `outputQuality` | V3 | Quality of code, design, and documentation | gate pass rate, review finding count | L1, L4 |
| `gatePassRate` | V4 | First-pass gate clearance rate | pass/fail statistics | L6, L4 |
| `proposalAccuracy` | V5 | Hit rate of design proposals | approval/rejection rate | L4, L6 |
| `knowledgeStructureQuality` | V6 | Degree of structuring of persistent knowledge | context restoration speed, retirement detection rate | L2 |
| `taskDesignEfficiency` | V7 | Efficiency of task design | completion rate / resource ratio | L3, L6 |
-/

namespace Manifest

-- ============================================================
-- Observable / Measurable 定義
-- ============================================================

/-- Observable: a decision procedure exists for a given property.
    Expresses that `P : World → Prop` is binary-decidable. -/
def Observable (P : World → Prop) : Prop :=
  ∃ f : World → Bool, ∀ w, f w = true ↔ P w

/-- Measurable: a computation procedure exists for a quantitative indicator.
    Expresses that the value of `m : World → Nat` can be computed from external observations.

    Formally, "there exists a computable function `f` that agrees with `m`."
    By declaring this as an axiom for an opaque `m`, we promise the system
    that "a measurement procedure exists in principle."

    **Why this is non-trivial**

    When `m` is opaque, `f = m` does not pass type-checking
    (due to the non-unfoldability of opaque definitions). Therefore,
    the axiom declaration of Measurable constitutes a non-trivial promise. -/
def Measurable (m : World → Nat) : Prop :=
  ∃ f : World → Nat, ∀ w, f w = m w

-- ============================================================
-- Proxy 成熟度分類
-- ============================================================

/-- Proxy maturity levels. Assigns a classification to each V proxy in observe.sh.
    - provisional: Tentative proxy indicator. Formal measurement method not yet implemented.
    - established: Stable proxy indicator. Operational sufficiency confirmed (T6 judgment).
    - formal: Formal measurement method implemented. -/
inductive ProxyMaturityLevel where
  | provisional : ProxyMaturityLevel
  | established : ProxyMaturityLevel
  | formal : ProxyMaturityLevel
  deriving BEq, Repr, DecidableEq

/-- Current proxy maturity for V1.
    provisional → formal (2026-03-27, #77):
    - GQM chain defined (R1 #85): Q1 structural contribution, Q2 verification quality, Q3 operational stability
    - Formal schema implemented in benchmark.json (G1 #78)
    - Automated measurement in observe.sh (G2 #79)
    - Retrospective validation over 63 runs confirmed all metrics satisfy hypotheses
    - Goodhart 5-layer defense: governance metrics (R2), correlation monitoring (R3), non-triviality gate (R5), saturation detection (R6), bias review obligation (G1b-2)
    - Legacy proxy (success_rate) confirmed to be uncorrelated with new benchmark (r=0.006-0.069) (G3 #80) -/
def v1ProxyMaturity : ProxyMaturityLevel := .formal

/-- Current proxy maturity for V3.
    provisional → formal (2026-03-27, #77):
    - GQM chain defined (R1 #85): Q1 acceptance criteria, Q2 structural integrity, Q3 error trend
    - Formal schema implemented in benchmark.json (G1 #78)
    - Automated measurement in observe.sh (G2 #79)
    - Legacy proxy (test_pass_rate) confirmed invalid as quality signal due to zero variance (G3 #80)
    - hallucination proxy (Run 54+) functions as a new indicator for error trend -/
def v3ProxyMaturity : ProxyMaturityLevel := .formal

-- ============================================================
-- V1–V7: 最適化変数
-- ============================================================

/-- V1: Skill quality. Precision and effectiveness of skill definitions.
    Measurement method: benchmark.json (with/without comparison).
    Related boundary conditions: L2 (mitigating training data discontinuity), L5 (skill system).
    observe.sh proxy: evolve_success_rate (successful run ratio), lean_health (sorry=0 check),
    skill_count (number of skill files).
    Proxy maturity classification:
    - provisional_proxy: Tentative proxy indicator. Formal measurement method not yet implemented.
    - established_proxy: Stable proxy indicator. Judged operationally sufficient.
    - formal_measurement: Formal measurement method implemented.
    V1 proxy promoted to formal_measurement (2026-03-27, #77). Measured via benchmark.json GQM schema. -/
opaque skillQuality : World → Nat

/-- V2: Context efficiency. Utilization of finite context.
    Measurement method: task completion rate / consumed token count.
    Related boundary conditions: L2 (finite context), L3 (token budget).
    observe.sh proxy: recent_avg (median of last 10 session deltas, primary),
    cumulative_avg (all-history average excluding micro-sessions, baseline).
    primary_metric: recent_median (median-based, robust to outliers).
    Operational note: a divergence of ±20% or more between recent_avg and cumulative_avg
    is interpreted as a trend change.
    Divergence interpretation: V2 is a hub variable with tradeoff relationships to 5 other
    variables (theorem tradeoff_context_is_hub). Since evolve sessions (heavy tool usage)
    push recent_avg upward, divergence_percent > 100% is not necessarily problematic.
    The tendency for recent_avg to rise as evolve depth and frequency increase is expected. -/
opaque contextEfficiency : World → Nat

/-- V3: Output quality. Quality of code, design, and documentation.
    Measurement method: gate pass rate, review finding count.
    Related boundary conditions: L1 (safety standards), L4 (basis for action space adjustment).
    observe.sh proxy: test_pass_rate (all-tests pass rate) +
    hallucination_proxy (rejected[].failure_type aggregation).
    Legacy fix_ratio_percent proxy (commit prefix ratio) was removed in Run 69.
    Proxy maturity classification:
    - provisional_proxy: Tentative proxy indicator. Formal measurement method not yet implemented.
    - established_proxy: Stable proxy indicator. Judged operationally sufficient.
    - formal_measurement: Formal measurement method implemented.
    V3 proxy promoted to formal_measurement (2026-03-27, #77). Measured via benchmark.json GQM schema. -/
opaque outputQuality : World → Nat

/-- V4: Gate pass rate. Rate of clearing each phase's gate on the first attempt.
    P2 (cognitive separation of concerns) guarantees gate reliability.
    Measurement method: pass/fail statistics.
    Related boundary conditions: L6 (gate definition granularity), L4 (auto-merge judgment).
    observe.sh proxy: Bash passed / (passed + blocked).
    "tool":"Bash" event count / (Bash + gate_blocked event count) from tool-usage.jsonl. -/
opaque gatePassRate : World → Nat

/-- V5: Proposal accuracy. Hit rate of design and scope proposals.
    Measurement method: human approval/rejection rate.
    Related boundary conditions: L4 (basis for action space adjustment), L6 (design convention improvement).
    observe.sh proxy: approved / total entry ratio from v5-approvals.jsonl. -/
opaque proposalAccuracy : World → Nat

/-- V6: Knowledge structure quality. Degree of structuring of persistent knowledge.
    P3 (governed learning) defines the knowledge lifecycle
    (observation -> hypothesis formation -> verification -> integration -> retirement).
    Knowledge that is not retired accumulates and degrades V2.
    Measurement method: context restoration speed in the next session, retirement target detection rate.
    Related boundary conditions: L2 (mitigating memory loss).
    observe.sh proxy: memory_entries (MEMORY.md entry count), memory_files (memory file count),
    last_update_days_ago (days since last update), retired_count (retired entry count). -/
opaque knowledgeStructureQuality : World → Nat

/-- V7: Task design efficiency. Quality of P6 (task design as constraint satisfaction).
    Two data sources:
    (1) External knowledge: public benchmarks, model performance characteristics
    (2) Internal knowledge: execution logs, resource consumption records, outcome-to-cost ratio
    Measurement method: task completion rate / consumed resource ratio, redesign frequency.
    Related boundary conditions: L3 (resource limits), L6 (design conventions).
    observe.sh proxy: completed (task completion count from v7-tasks.jsonl), unique_subjects (unique subject count),
    teamwork_percent (ratio of entries with teammate field).
    Operational note: teamwork_percent is suppressed in single-agent operation (teamwork_status="suppressed_single_agent").
    Since this field requires multi-agent/human collaboration, it is excluded from observation reports in single-agent environments. -/
opaque taskDesignEfficiency : World → Nat

-- ============================================================
-- V1–V7 可測性 axiom
-- ============================================================

/-!
## Measurability Declarations for V1-V7 - Gamma Extension of T_0 Design-Derived

Each variable is declared as `Measurable` via non-logical axioms (Glossary §4.1).
This is a design-level promise that "measurement is possible in principle," with
concrete measurement implementations delegated to the operational layer.

Membership in Gamma \ T_0 (Procedure Manual §2.4): the justification for these axioms
originates from the designer's design judgments (not from external authority), and therefore
they belong to the extension part.

Why axioms: since V1–V7 are opaque (opaque definitions, Glossary §9.4),
`Measurable` cannot be proved as a theorem (§4.2) due to the non-unfoldability of opaque
definitions. Measurability is guaranteed by external operational systems and is assumed
as a non-logical axiom within the formal system.
-/

/-- [Axiom Card]
    Layer: Gamma \ T_0 (design-derived)
    Content: V1 (skill quality) is measurable
    Basis: with/without comparison via benchmark.json exists as a measurement procedure
    Source: Ontology.lean V1 definition
    Adopted: 2026-03-22
    Last validated: 2026-03-28
    Review cycle: 6m
    Refutation condition: if it is shown that a measurement procedure for skill quality is in principle unconstructible -/
axiom v1_measurable : Measurable skillQuality

/-- [Axiom Card]
    Layer: Gamma \ T_0 (design-derived)
    Content: V2 (context efficiency) is measurable
    Basis: the ratio of task completion rate to consumed token count exists as a measurement procedure
    Source: Ontology.lean V2 definition
    Adopted: 2026-03-22
    Last validated: 2026-03-28
    Review cycle: 6m
    Refutation condition: if it is shown that a measurement procedure for context efficiency is in principle unconstructible -/
axiom v2_measurable : Measurable contextEfficiency

/-- [Axiom Card]
    Layer: Gamma \ T_0 (design-derived)
    Content: V3 (output quality) is measurable
    Basis: gate pass rate and review finding count exist as measurement procedures
    Source: Ontology.lean V3 definition
    Adopted: 2026-03-22
    Last validated: 2026-03-28
    Review cycle: 6m
    Refutation condition: if it is shown that a measurement procedure for output quality is in principle unconstructible -/
axiom v3_measurable : Measurable outputQuality

/-- [Axiom Card]
    Layer: Gamma \ T_0 (design-derived)
    Content: V4 (gate pass rate) is measurable
    Basis: pass/fail statistics exist as a measurement procedure
    Source: Ontology.lean V4 definition
    Adopted: 2026-03-22
    Last validated: 2026-03-28
    Review cycle: 6m
    Refutation condition: if it is shown that a measurement procedure for gate pass rate is in principle unconstructible -/
axiom v4_measurable : Measurable gatePassRate

/-- [Axiom Card]
    Layer: Gamma \ T_0 (design-derived)
    Content: V5 (proposal accuracy) is measurable
    Basis: human approval/rejection rate exists as a measurement procedure
    Source: Ontology.lean V5 definition
    Adopted: 2026-03-22
    Last validated: 2026-03-28
    Review cycle: 6m
    Refutation condition: if it is shown that a measurement procedure for proposal accuracy is in principle unconstructible -/
axiom v5_measurable : Measurable proposalAccuracy

/-- [Axiom Card]
    Layer: Gamma \ T_0 (design-derived)
    Content: V6 (knowledge structure quality) is measurable
    Basis: context restoration speed and retirement target detection rate exist as measurement procedures
    Source: Ontology.lean V6 definition
    Adopted: 2026-03-22
    Last validated: 2026-03-28
    Review cycle: 6m
    Refutation condition: if it is shown that a measurement procedure for knowledge structure quality is in principle unconstructible -/
axiom v6_measurable : Measurable knowledgeStructureQuality

/-- [Axiom Card]
    Layer: Gamma \ T_0 (design-derived)
    Content: V7 (task design efficiency) is measurable
    Basis: task completion rate / consumed resource ratio exists as a measurement procedure
    Source: Ontology.lean V7 definition
    Adopted: 2026-03-22
    Last validated: 2026-03-28
    Review cycle: 6m
    Refutation condition: if it is shown that a measurement procedure for task design efficiency is in principle unconstructible -/
axiom v7_measurable : Measurable taskDesignEfficiency

-- ============================================================
-- 系の健全性
-- ============================================================

/-!
## System Health

Rather than maximizing individual variables, maintain the health of the system as a whole.
Even when metrics for one variable improve, verify that other variables have not deteriorated.

Health is formulated as "all variables are at or above a threshold."
Threshold settings are operational judgments (T6: humans are the final decision-makers for resources).
-/

/-- System health. The state in which all V1–V7 meet the minimum threshold.

    Note: thresholds should ideally differ per variable rather than being uniform,
    but Phase 4 uses a uniform threshold for simplicity.
    Phase 5 extends this to per-variable thresholds (HealthThresholds /
    systemHealthyPerVar in ObservableDesign.lean). -/
def systemHealthy (threshold : Nat) (w : World) : Prop :=
  skillQuality w ≥ threshold ∧
  contextEfficiency w ≥ threshold ∧
  outputQuality w ≥ threshold ∧
  gatePassRate w ≥ threshold ∧
  proposalAccuracy w ≥ threshold ∧
  knowledgeStructureQuality w ≥ threshold ∧
  taskDesignEfficiency w ≥ threshold

-- ============================================================
-- 信頼度・劣化度の可測性
-- ============================================================

/-- [Axiom Card]
    Layer: Gamma \ T_0 (design-derived)
    Content: trustLevel is measurable.
             Indirectly observed from investment behavior (fluctuations in resource allocation)
    Basis: trust is concretized as investment behavior (resource allocation fluctuations)
    Source: manifesto.md Section 6
    Adopted: 2026-03-22
    Last validated: 2026-03-28
    Review cycle: 6m
    Refutation condition: if it is shown that a measurement procedure for trust level is in principle unconstructible -/
axiom trust_measurable :
  ∀ (agent : Agent), Measurable (trustLevel agent)

/-- [Axiom Card]
    Layer: Gamma \ T_0 (design-derived)
    Content: degradationLevel is measurable. Computed from temporal changes in V1–V7
    Basis: if V1–V7 are Measurable, their rate of change is also computable
    Source: design of P4 (observability of degradation)
    Adopted: 2026-03-22
    Last validated: 2026-03-28
    Review cycle: 6m
    Refutation condition: if it is shown that a measurement procedure for degradation level is in principle unconstructible -/
axiom degradation_measurable : Measurable degradationLevel

-- ============================================================
-- 境界→緩和策→変数の接続 (taxonomy Part II)
-- ============================================================

/-!
## Three-Tier Structure Connection Boundary to Mitigation to Variable

Many variables represent the quality of structures designed as **mitigations** for boundary conditions:

```
Boundary (invariant)          ->  Mitigation (structure)         ->  Variable (quality)
L2: Memory loss               ->  Implementation Notes           ->  V6: Knowledge structure quality
L2: Finite context             ->  50% rule, lightweight design   ->  V2: Context efficiency
L2: Non-determinism            ->  Gate verification              ->  V4: Gate pass rate
L2: Training data discontinuity ->  docs/ SSOT, skills           ->  V1: Skill quality
```

Boundary conditions do not move. Mitigations are design decisions (L6). Variables measure
**how well** mitigations work. This three-tier structure clarifies "what is fixed, what is
a design choice, and what is an optimization target."
-/

/-- Correspondence between boundary conditions and variables.
    Expresses the "boundary -> variable" mapping of the three-tier structure as a type.
    Mitigations are design decisions (L6) positioned between them. -/
inductive VariableId where
  | v1 | v2 | v3 | v4 | v5 | v6 | v7
  deriving BEq, Repr

/-- Boundary condition corresponding to each variable.
    Expresses the "boundary -> variable" mapping of the three-tier structure as a function.
    Mitigations are design decisions (L6) positioned between them. -/
def variableBoundary : VariableId → BoundaryId
  | .v1 => .ontological   -- L2: 学習データ断絶 → V1: スキル品質
  | .v2 => .ontological   -- L2: コンテキスト有限性 → V2: コンテキスト効率
  | .v3 => .ethicsSafety   -- L1: 安全基準 → V3: 出力品質
  | .v4 => .ontological   -- L2: 非決定性 → V4: ゲート通過率
  | .v5 => .actionSpace    -- L4: 行動空間調整の根拠 → V5: 提案精度
  | .v6 => .ontological   -- L2: 記憶喪失 → V6: 知識構造の質
  | .v7 => .resource       -- L3: リソース上限 → V7: タスク設計効率

/-- Variables corresponding to fixed boundaries cannot move the boundary itself;
    only the quality of mitigations can be improved. -/
theorem fixed_boundary_variables_mitigate_only :
  boundaryLayer (variableBoundary .v1) = .fixed ∧
  boundaryLayer (variableBoundary .v2) = .fixed ∧
  boundaryLayer (variableBoundary .v4) = .fixed ∧
  boundaryLayer (variableBoundary .v6) = .fixed := by
  simp [variableBoundary, boundaryLayer]

/-- Boundary conditions corresponding to each constraint (T1-T8).
    Expresses the "constraint -> boundary condition" mapping of the three-tier structure as a function.
    T->L mapping: which boundary condition category each constraint belongs to.

    Mapping justification:
    - T1 -> L2: Session ephemerality is an ontological fact (agent is bound to session)
    - T2 -> L2: Structural persistence is an ontological fact (structure outlives agent)
    - T3 -> L2, L3: Finite context is both an ontological and a resource constraint
    - T4 -> L2: Output stochasticity is an ontological property of LLMs
    - T5 -> L2: Feedback requirement is an ontological prerequisite for improvement
    - T6 -> L1, L4: Human authority spans the safety boundary (L1) and action space boundary (L4)
    - T7 -> L3: Resource finiteness directly corresponds to the resource boundary
    - T8 -> L6: Precision level is defined as a task design convention (architecturalConvention)

    Note: L5 (platform) is intentionally excluded.
    L5 represents provider-specific environmental constraints (Claude Code, Codex CLI, etc.),
    while T1-T8 are technology-independent constraints. L5 is not derived from T but arises
    from the human judgment of platform selection (upstream of T6).
    In variableBoundary as well, V1-V7 are not mapped to L5. -/
def constraintBoundary : ConstraintId → List BoundaryId
  | .t1 => [.ontological]
  | .t2 => [.ontological]
  | .t3 => [.ontological, .resource]
  | .t4 => [.ontological]
  | .t5 => [.ontological]
  | .t6 => [.ethicsSafety, .actionSpace]
  | .t7 => [.resource]
  | .t8 => [.architecturalConvention]

/-- Every constraint corresponds to at least one boundary condition.
    Surjectivity onto coverage of the T->L mapping. -/
theorem constraint_has_boundary :
  ∀ c : ConstraintId, (constraintBoundary c).length > 0 := by
  intro c
  cases c <;> simp [constraintBoundary]

/-- L5 (platform) is not included in the constraintBoundary of any T1-T8.
    L5 is a provider-specific environmental constraint and is not derived from
    the technology-independent constraints T. -/
theorem platform_not_in_constraint_boundary :
  ∀ c : ConstraintId, BoundaryId.platform ∉ constraintBoundary c := by
  intro c
  cases c <;> simp [constraintBoundary]

/-- Every boundary condition except L5 is included in the constraintBoundary of at least one constraint.
    constraintBoundary covers L1-L6 except L5. -/
theorem constraint_boundary_covers_except_platform :
  (∃ c, BoundaryId.ethicsSafety ∈ constraintBoundary c) ∧
  (∃ c, BoundaryId.ontological ∈ constraintBoundary c) ∧
  (∃ c, BoundaryId.resource ∈ constraintBoundary c) ∧
  (∃ c, BoundaryId.actionSpace ∈ constraintBoundary c) ∧
  (∃ c, BoundaryId.architecturalConvention ∈ constraintBoundary c) := by
  refine ⟨⟨.t6, ?_⟩, ⟨.t1, ?_⟩, ⟨.t3, ?_⟩, ⟨.t6, ?_⟩, ⟨.t8, ?_⟩⟩ <;>
    simp [constraintBoundary]

-- ============================================================
-- Derived theorems: Measurable → Observable bridge
-- ============================================================

/-!
## Measurable to Observable Bridge

A general theorem stating that threshold comparison of Measurable indicators is Observable.
An aggregation lemma that collects the Measurable axioms of V1–V7.
-/

/-- Threshold comparison of a Measurable indicator is Observable (Measurable->Observable bridge).
    Constructs a decision procedure for m w >= t from Measurable m. -/
theorem measurable_threshold_observable {m : World → Nat} (hm : Measurable m) (t : Nat) :
    Observable (fun w => m w ≥ t) := by
  obtain ⟨f, hf⟩ := hm
  exact ⟨fun w => decide (f w ≥ t), fun w => by simp [hf w]⟩

/-- All 7 variables are Measurable (aggregation lemma). -/
theorem all_variables_measurable :
    Measurable skillQuality ∧ Measurable contextEfficiency ∧
    Measurable outputQuality ∧ Measurable gatePassRate ∧
    Measurable proposalAccuracy ∧ Measurable knowledgeStructureQuality ∧
    Measurable taskDesignEfficiency :=
  ⟨v1_measurable, v2_measurable, v3_measurable, v4_measurable,
   v5_measurable, v6_measurable, v7_measurable⟩

-- ============================================================
-- Derived theorems: Observable conjunction + system health
-- ============================================================

/-- Conjunction closure of Observable. The conjunction of two Observable properties is also Observable. -/
theorem observable_and {P Q : World → Prop} (hp : Observable P) (hq : Observable Q) :
    Observable (fun w => P w ∧ Q w) := by
  obtain ⟨fp, hfp⟩ := hp
  obtain ⟨fq, hfq⟩ := hq
  refine ⟨fun w => fp w && fq w, fun w => ?_⟩
  simp [Bool.and_eq_true]
  exact ⟨fun ⟨a, b⟩ => ⟨(hfp w).mp a, (hfq w).mp b⟩,
         fun ⟨a, b⟩ => ⟨(hfp w).mpr a, (hfq w).mpr b⟩⟩

/-- System health is Observable (binary-decidable).
    Since each Vi is Measurable, threshold comparison is decidable.
    Proved via measurable_threshold_observable + observable_and.
    (Originally an axiom, demoted to theorem in Run 27) -/
theorem system_health_observable :
    ∀ (threshold : Nat), Observable (systemHealthy threshold) := by
  intro t
  unfold systemHealthy
  apply observable_and (measurable_threshold_observable v1_measurable t)
  apply observable_and (measurable_threshold_observable v2_measurable t)
  apply observable_and (measurable_threshold_observable v3_measurable t)
  apply observable_and (measurable_threshold_observable v4_measurable t)
  apply observable_and (measurable_threshold_observable v5_measurable t)
  apply observable_and (measurable_threshold_observable v6_measurable t)
  exact measurable_threshold_observable v7_measurable t

-- ============================================================
-- Part IV: この分類自体のメンテナンス
-- ============================================================

/-!
## Part IV Maintaining the Classification Itself

This classification (L1–L6, V1–V7) is a **hypothesis** based on current understanding,
not a fixed truth. Its type-level representation is formalized as `ReviewSignal` in Evolution.lean.

## Signals That Should Trigger Review

| Signal | Example | Response |
|--------|---------|----------|
| Misclassification | An item placed in L1 is actually conditionally modifiable | Move to another category |
| Missing boundary condition | Regulatory/legal constraints restrict the action space but are absent from the classification | Add a new Layer |
| Vanished boundary condition | Technological advances have effectively overcome an L2 item | Delete or reclassify |
| Variable deficit/surplus | There are optimization targets not included in V1-V7 | Add, merge, or split variables |
| Ambiguous category boundary | Something could belong to either "fixed boundary" or "investment-variable boundary" | Refine the judgment criteria |

## Caution - Avoiding Self-Rigidification of the Classification

The greatest risk is that **the classification itself begins to function as a boundary condition** --
inducing reasoning such as "it cannot be changed because it is written in L1."

Preventive measures:
- Maintain the rationale for "why this category" for each item in every Layer
- "Fixed" means "no means of changing it has been found at present"
- Reclassification of boundary conditions is a legitimate act consistent with the spirit of the manifesto
-/

-- ============================================================
-- 核心的洞察
-- ============================================================

/-!
## Core Insights

1. **The subject of optimization is structure, not the agent.** The agent is an ephemeral catalyst (T1).
   Improvements accumulate within structure (T2).

2. **Variables are not independent levers but a mutually interacting system.** Improving V1 can degrade V2.
   Rather than maximizing individual variables, maintain the health of the system as a whole.

3. **The purpose of the investment cycle is equilibrium, not expansion.** Rather than maximizing the action space,
   search for the equilibrium point where collaborative value is maximized. The equilibrium point shifts with context.

4. **The investment cycle simultaneously contains positive and negative feedback.** By P1, expansion of the action space
   is inseparable from expansion of the attack surface. Expansion without defense increases the potential destructive
   power of the reverse cycle.

5. **Gate reliability depends on P2, and P2 rests on E1.** V4 is meaningful only when generation and evaluation
   are structurally separated.

6. **Variable optimization presupposes P4.** What cannot be observed cannot be optimized.

7. **Structure is interpreted probabilistically (P5).** Designs that assume 100% compliance are fragile.

8. **Task execution is a constraint satisfaction problem (P6).** Simultaneous satisfaction of T3, T7, and T8
   drives task design.

9. **L5 determines the ceiling of structural improvement.** Building a custom platform is justified when the
   investment cycle has sufficiently progressed and the L5 ceiling has become a bottleneck.

10. **The axiom system has a three-layer structure.** Constraints (T: undeniable), empirical postulates
    (E: falsifiable but unfalsified), and foundational principles (P: derived from T/E). The robustness of
    each P differs depending on whether its justification includes E.

11. **This classification itself is subject to review.** The L1–L6, V1–V7 classification is not a fixed truth;
    reclassification, addition, and deletion of items may occur during operation.
-/

-- ============================================================
-- Derived theorems: Quality measurement priority (G1b-1 #91)
-- ============================================================

/-!
## Quality Measurement Priority G1b-1

Analysis from G1b-1 (#91) revealed that the following quality priorities are derivable from
the manifesto's axiom system. These follow logically from existing axioms and design principles,
without depending on T6 (human judgment).

## Non-Derivable Domain V1-V7
Mutual priority among V1-V7 is not derivable. TradeoffExists is a symmetric relation and
does not imply orderings such as "V1 > V3." This is an intentional design decision;
priority among V's reduces to T6 judgment (G1b-2 #92).
-/

/-- Quality measurement category: measurement of structural change vs measurement of process success rate.
    Formalization of the proxy mismatch identified in R1 (GQM redefinition). -/
inductive QualityMeasureCategory where
  | structuralOutcome   -- 構造的成果: theorem delta, test delta, axiom count
  | processSuccess      -- プロセス成功率: evolve success rate, skill invocation rate
  deriving BEq, Repr

/-- Priority of quality measurement categories. Structural outcomes are a more direct indicator
    of quality than process success rates.
    Basis:
    - Supreme mission "persistent structure continues to improve itself" -> structural change defines improvement
    - Analogy from D5 (specification layer ordering): outcome (what was produced) > process (how it was produced)
    - Anthropic eval guide: "grade what the agent produced, not the path it took" -/
def qualityMeasurePriority : QualityMeasureCategory → Nat
  | .structuralOutcome => 1  -- higher priority
  | .processSuccess    => 0  -- lower priority

/-- Measurement of structural outcomes takes priority over measurement of process success rates as a quality indicator.
    Quality is "skills producing structural improvement," not merely "skills running successfully." -/
theorem structural_outcome_gt_process_success :
    qualityMeasurePriority .structuralOutcome >
    qualityMeasurePriority .processSuccess := by
  native_decide

/-- Classification of verification signals: independent verification vs self-assessment.
    Formalization of P2 + E1 + ICLR 2024 (Huang et al.). -/
inductive VerificationSignalType where
  | independentlyVerified  -- P2: 独立エージェントまたは構造的テストによる検証
  | selfAssessed           -- 同一インスタンスによる自己評価
  deriving BEq, Repr

/-- Reliability of verification signals. Independent verification is more reliable than self-assessment.
    Basis:
    - P2: Cognitive separation of concerns (separation of Worker and Verifier)
    - E1: Experience precedes theory -- self-assessment using self-generated theory is circular
    - ICLR 2024 Huang et al.: intrinsic self-correction degrades accuracy -/
def verificationReliability : VerificationSignalType → Nat
  | .independentlyVerified => 1  -- higher reliability
  | .selfAssessed          => 0  -- lower reliability

/-- Independently verified quality signals are more reliable than self-assessed quality signals. -/
theorem independent_verification_gt_self_assessment :
    verificationReliability .independentlyVerified >
    verificationReliability .selfAssessed := by
  native_decide

/-- Quality assurance layers: defect absence vs value creation.
    Application of the D6 DesignStage ordering to the quality dimension. -/
inductive QualityAssuranceLayer where
  | defectAbsence    -- 壊れていないことの確認（test pass, Lean build, sorry=0）
  | valueCreation    -- 良いことの確認（改善の実質性、有用性）
  deriving BEq, Repr

/-- Measurement priority of quality assurance. Confirming defect absence precedes confirming value creation.
    Basis:
    - D6: Boundary (constraint satisfaction) > Variable (quality improvement)
    - D4: Safety > Governance -- safety (not broken) precedes governance (making better)
    - Logical consequence: measuring "substantiveness of improvement" in a broken system is meaningless -/
def qualityAssurancePriority : QualityAssuranceLayer → Nat
  | .defectAbsence  => 1  -- higher measurement priority
  | .valueCreation  => 0  -- lower measurement priority (but not less important)

/-- Measurement of defect absence takes priority over measurement of value creation (as measurement ordering).
    Note: this means "should be measured first," not "defect absence is more important."
    Measurement of value creation becomes meaningful only after defect absence is confirmed. -/
theorem defect_absence_measurement_gt_value_creation :
    qualityAssurancePriority .defectAbsence >
    qualityAssurancePriority .valueCreation := by
  native_decide

end Manifest
