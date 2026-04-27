import AgentSpec.Manifest.Ontology
import AgentSpec.Manifest.Axioms
import AgentSpec.Manifest.EmpiricalPostulates
import AgentSpec.Manifest.Principles
import AgentSpec.Manifest.Observable
import AgentSpec.Manifest.ObservableDesign

/-!
# Epistemic Layer - DesignTheorem Strength 1 - Formalization of Design Development Foundation

Type-checks that D1–D17 from design-development-foundation.md are
derivable (§2.4 derivability) from the manifesto's T/E/P
(premise set Γ, terminology reference §2.5).

## Nature of the Formalization

This file does not add new non-logical axioms (§4.1) to Γ.
Every D is formalized as one of the following:
- **Definitional extension** (§5.5): Definition of new types/functions. Always a conservative extension
- **Theorem** (§4.2): Derived from existing axioms (T/E) by application of inference rules

Therefore this file is a collection of definitional extensions + theorems over T₀,
and conservative extension (§5.5) is guaranteed by `definitional_implies_conservative`
proven in Terminology.lean.

## Design Policy

Each D is expressed as a type (definitional extension, §5.5) or theorem (§4.2),
with explicit connections to the underlying T/E/P non-logical axioms (§4.1) / theorems.

D's are meta-level (§5.6 metatheory) design principles,
distinct from object-level (§5.6 object theory) non-logical axioms.

## Correspondence with Terminology Reference

| Lean Concept | Terminology Reference | §Ref |
|------------|----------------|-------|
| D1–D17 theorems | Theorems (propositions derived from axioms) | §4.2 |
| D1–D17 def/structure | Definitional extensions (new symbols defined via existing symbols) | §5.5 |
| SelfGoverning | Type class (interface for types) | §9.4 |
| DesignPrinciple | Component of the domain of discourse (§3.2) | §3.2 |
| DesignPrincipleUpdate | Structuring of AGM revision operations | §9.2 |
| EnforcementLayer | Hierarchy of enforcement power. Means to realize invariants (§9.3) | §9.3 |
| DevelopmentPhase | Inter-phase dependencies resemble transition relations (§9.3) | §9.3 |
| VerificationIndependence | Operationalization of E1 (§4.1 non-logical axiom) | §4.1 |
| CompatibilityClass | Classification of extensions (conservative/consistent/breaking) | §5.5 |

## Correspondence with design-development-foundation.md

This file formalizes D1–D17.

| D | Rationale | Formalization Depth |
|---|------|------------|
| D1 | P5 + L1–L6 | type + 2 theorems |
| D2 | E1 + P2 | structure + 3 theorems |
| D3 | P4 + T5 | 3 theorems (3-condition structure not formalized) |
| D4 | Section 7 + P3 + T2 | type + 5 theorems |
| D5 | T8 + P4 + P6 | type + 3 theorems (inter-layer relations not formalized) |
| D6 | Ontology/Observable | 3 theorems (causal chain not formalized) |
| D7 | Section 6 + P1 | 2 theorems (accumulation bounded + damage unbounded) |
| D8 | Section 6 + E2 | 2 theorems (overexpansion + capability-risk) |
| D9 | Observable + P3 + Section 7 | SelfGoverning + 4 theorems |
| D10 | T1 + T2 | 2 theorems (structural permanence + epoch monotone increase) |
| D11 | T3 + D1 | definition + 3 theorems (inverse correlation + minimization + finiteness) |
| D12 | P6 + T3 + T7 + T8 | 2 theorems (CSP + probabilistic output) |
| D13 | P3 + Section 8 + T5 | impact propagation + assumption-level extension (#225) |
| D14 | P6 + T7 + T8 | 1 theorem (constraint satisfaction of verification order) |
| D15 | T3+T4+T5+T6+T7+T8+P6 | 4 theorems (retry bounds, convergence, eviction, saturation) |
| D16 | context_contribution_nonuniform | 3 theorems (zero-contribution, composition, resource) |
| D17 | T5+D3+P3+T6+D5+D9+E1+D2+D13 | type + 8 theorems (deductive design workflow) |
-/

namespace AgentSpec.Manifest

-- ============================================================
-- D1: 強制のレイヤリング原理
-- ============================================================

/-!
## D1 Enforcement Layering
Definitional Extension, 5.5.

Rationale: P5 (probabilistic interpretation) + L1–L6 (hierarchy of boundary conditions)

By P5, normative guidelines are only probabilistically complied with.
Therefore, absolute constraints such as L1 (safety) should be
implemented via structural enforcement (not subject to probabilistic interpretation).

Connection with terminology reference:
- Structural enforcement → Invariant (§9.3): Property that always holds during execution
- Procedural enforcement → Pre/post-conditions (§9.3): Verified before and after operations
- Normative guideline → Satisfiable (§2.2) but not valid/tautological (§2.2) by P5
-/

-- Day 165: `EnforcementLayer` は port に既存 (D.lean / Ontology / etc)。重複削除。

-- Day 165: `EnforcementLayer.strength` は port に既存 (D.lean / Ontology / etc)。重複削除。

-- Day 165: `minimumEnforcement` は port に既存 (D.lean / Ontology / etc)。重複削除。

-- Day 171: `d1_fixed_requires_structural` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 171: `d1_enforcement_monotone` は port D.lean に既存 (DF root integration)。重複削除。

-- ============================================================
-- D2: Worker/Verifier 分離の構造的実現
-- ============================================================

/-!
## D2 Worker/Verifier Separation
Definitional Extension + Theorem, 5.5/4.2.

Rationale: E1 (verification independence, non-logical axiom §4.1) + P2 (cognitive role separation, theorem §4.2)

E1a (verification_requires_independence) is the direct rationale.
E1 belongs to Γ \ T₀ (hypothesis-derived) and is falsifiable (§9.1).
If E1 is falsified, D2 becomes subject to review.
-/

-- Day 165: `VerificationIndependence` は port に既存 (D.lean / Ontology / etc)。重複削除。

-- Day 165: `VerificationRisk` は port に既存 (D.lean / Ontology / etc)。重複削除。

-- Day 165: `requiredConditions` は port に既存 (D.lean / Ontology / etc)。重複削除。

-- Day 165: `satisfiedConditions` は port に既存 (D.lean / Ontology / etc)。重複削除。

-- Day 165: `sufficientVerification` は port に既存 (D.lean)。重複削除。

-- Day 171: `critical_requires_all_four` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 171: `subagent_only_sufficient_for_low` は port D.lean に既存 (DF root integration)。重複削除。

/-- Backward compatibility with former validSeparation: the old 3 conditions are a subset of the new 4 conditions. -/
def validSeparation (vs : VerificationIndependence) : Prop :=
  vs.contextSeparated = true ∧
  vs.framingIndependent = true ∧
  vs.executionAutomatic = true

-- Day 171: `d2_from_e1` は port D.lean に既存 (DF root integration)。重複削除。

-- ============================================================
-- D3: 可観測性先行
-- ============================================================

/-!
## D3 Observability First
Theorem, 4.2.

Rationale: P4 (observability of degradation, theorem §4.2) + T5 (no improvement without feedback, T₀ §4.1)

T5 (no_improvement_without_feedback) is the direct rationale:
Improvement requires feedback → feedback requires observation.

Note: design-development-foundation.md defines 3 conditions for observability
(measurable, degradation-detectable, improvement-verifiable), but
this formalization covers only the implication of T5. Structuring of the 3 conditions is not yet implemented.
-/

-- Day 171: `d3_observability_precedes_improvement` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 171: `d3_process_observability_precedes_improvement` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 165: `DetectionMode` は port に既存 (D.lean / Ontology / etc)。重複削除。

-- Day 165: `ObservabilityConditions` は port に既存 (D.lean / Ontology / etc)。重複削除。

-- Day 165: `effectivelyOptimizable` は port に既存 (D.lean / Ontology / etc)。重複削除。

-- Day 171: `d3_partial_observability_insufficient` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 171: `d3_full_observability_sufficient` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 171: `d3_human_readable_insufficient` は port D.lean に既存 (DF root integration)。重複削除。

-- ============================================================
-- D4: 漸進的自己適用
-- ============================================================

/-!
## D4 Progressive Self-Application
Definitional Extension + Theorem, 5.5/4.2.

Rationale: Section 7 (self-application) + P3 (governed learning, theorem §4.2) + T2 (structural permanence, T₀ §4.1)

Development phases have an ordering, and each phase's completion persists in structure (T2).
The phase ordering is derived from the dependency relationships of D1–D3.
`phaseOrder` in Procedure.lean formalizes the same ordering.
-/

-- Day 165: `DevelopmentPhase` は port に既存 (D.lean / Ontology / etc)。重複削除。

-- Day 165: `phaseDependency` は port に既存 (D.lean / Ontology / etc)。重複削除。

/-- Rationale for D4: Phase ordering is strict (no self-transitions).
    Each phase depends on its preceding phase. -/
theorem d4_no_self_dependency :
  ∀ (p : DevelopmentPhase), ¬phaseDependency p p := by
  intro p; cases p <;> simp [phaseDependency]

/-- [Derivation Card]
    Derives from: phaseDependency (definitional), structure_accumulates (T2)
    Proposition: D4
    Content: A complete phase chain exists: safety → verification → observability → governance → equilibrium. Each phase is strictly ordered with no self-dependencies.
    Proof strategy: refine + trivial (all four phaseDependency facts hold by definition) -/
theorem d4_full_chain :
  phaseDependency .verification .safety ∧
  phaseDependency .observability .verification ∧
  phaseDependency .governance .observability ∧
  phaseDependency .equilibrium .governance := by
  refine ⟨?_, ?_, ?_, ?_⟩ <;> trivial

/-- D4's connection to T2: Phase completion persists in structure.
    From structure_accumulates, epochs (phase progression) are
    irreversible. A completed phase is never "undone". -/
theorem d4_phase_completion_persists :
  ∀ (w w' : World),
    validTransition w w' →
    w.epoch ≤ w'.epoch :=
  structure_accumulates

-- ============================================================
-- D4: DevelopmentPhase 半順序型クラスインスタンス（Run 61 追加）
-- ============================================================

/-!
## Partial Order Instance for DevelopmentPhase

manifesto.md Section 8 asserts that "D4/D5/D6 are instances of partial orders".
Following the precedent of StructureKind (Ontology.lean), we derive
LE/LT instances and the 4 partial order property theorems from a Nat-based ordering function.
-/

/-- Ordering function for DevelopmentPhase. Separately from phaseDependency (binary Prop),
    defines a total order via Nat. Reflects the phase ordering of D4. -/
def developmentPhaseOrder : DevelopmentPhase → Nat
  | .safety        => 0
  | .verification  => 1
  | .observability => 2
  | .governance    => 3
  | .equilibrium   => 4

/-- The ordering function is injective (distinct phases have distinct order values). -/
theorem developmentPhaseOrder_injective :
  ∀ (p₁ p₂ : DevelopmentPhase),
    developmentPhaseOrder p₁ = developmentPhaseOrder p₂ → p₁ = p₂ := by
  intro p₁ p₂; cases p₁ <;> cases p₂ <;> simp [developmentPhaseOrder]

instance : LE DevelopmentPhase := ⟨fun a b => developmentPhaseOrder a ≤ developmentPhaseOrder b⟩
instance : LT DevelopmentPhase := ⟨fun a b => developmentPhaseOrder a < developmentPhaseOrder b⟩

/-- Partial order reflexivity: p <= p. -/
theorem developmentPhase_le_refl : ∀ (p : DevelopmentPhase), p ≤ p :=
  fun p => Nat.le_refl (developmentPhaseOrder p)

/-- Partial order transitivity: if p₁ <= p₂ and p₂ <= p₃ then p₁ <= p₃. -/
theorem developmentPhase_le_trans :
    ∀ (p₁ p₂ p₃ : DevelopmentPhase), p₁ ≤ p₂ → p₂ ≤ p₃ → p₁ ≤ p₃ := by
  intro _p₁ _p₂ _p₃ h₁₂ h₂₃; exact Nat.le_trans h₁₂ h₂₃

/-- Partial order antisymmetry: if p₁ <= p₂ and p₂ <= p₁ then p₁ = p₂. -/
theorem developmentPhase_le_antisymm :
    ∀ (p₁ p₂ : DevelopmentPhase), p₁ ≤ p₂ → p₂ ≤ p₁ → p₁ = p₂ :=
  fun p₁ p₂ h₁₂ h₂₁ => developmentPhaseOrder_injective p₁ p₂ (Nat.le_antisymm h₁₂ h₂₁)

/-- Consistency of LT and LE: p₁ < p₂ iff p₁ <= p₂ and not (p₂ <= p₁). -/
theorem developmentPhase_lt_iff_le_not_le :
    ∀ (p₁ p₂ : DevelopmentPhase), p₁ < p₂ ↔ p₁ ≤ p₂ ∧ ¬(p₂ ≤ p₁) := by
  intro _p₁ _p₂; exact Nat.lt_iff_le_and_not_ge

-- ============================================================
-- D5: 仕様・テスト・実装の三層対応
-- ============================================================

/-!
## D5 Specification Test and Implementation Three-Layer Architecture

Rationale: T8 (precision level) + P4 (observability) + P6 (constraint satisfaction)
-/

-- Day 165: `SpecLayer` は port に既存 (D.lean / Ontology / etc)。重複削除。

-- Day 165: `TestKind` は port に既存 (D.lean / Ontology / etc)。重複削除。

-- Day 171: `d5_test_has_precision` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 165: `specLayerOrder` は port に既存 (D.lean / Ontology / etc)。重複削除。

-- Day 171: `d5_layer_sequential` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 165: `testDeterministic` は port に既存 (D.lean / Ontology / etc)。重複削除。

-- Day 171: `d5_structural_test_deterministic` は port D.lean に既存 (DF root integration)。重複削除。

-- ============================================================
-- D5: SpecLayer 半順序型クラスインスタンス（Run 61 追加）
-- ============================================================

/-- The ordering function is injective (distinct layers have distinct order values). -/
theorem specLayerOrder_injective :
  ∀ (l₁ l₂ : SpecLayer),
    specLayerOrder l₁ = specLayerOrder l₂ → l₁ = l₂ := by
  intro l₁ l₂; cases l₁ <;> cases l₂ <;> simp [specLayerOrder]

instance : LE SpecLayer := ⟨fun a b => specLayerOrder a ≤ specLayerOrder b⟩
instance : LT SpecLayer := ⟨fun a b => specLayerOrder a < specLayerOrder b⟩

/-- Partial order reflexivity: l <= l. -/
theorem specLayer_le_refl : ∀ (l : SpecLayer), l ≤ l :=
  fun l => Nat.le_refl (specLayerOrder l)

/-- Partial order transitivity: if l₁ <= l₂ and l₂ <= l₃ then l₁ <= l₃. -/
theorem specLayer_le_trans :
    ∀ (l₁ l₂ l₃ : SpecLayer), l₁ ≤ l₂ → l₂ ≤ l₃ → l₁ ≤ l₃ := by
  intro _l₁ _l₂ _l₃ h₁₂ h₂₃; exact Nat.le_trans h₁₂ h₂₃

/-- Partial order antisymmetry: if l₁ <= l₂ and l₂ <= l₁ then l₁ = l₂. -/
theorem specLayer_le_antisymm :
    ∀ (l₁ l₂ : SpecLayer), l₁ ≤ l₂ → l₂ ≤ l₁ → l₁ = l₂ :=
  fun l₁ l₂ h₁₂ h₂₁ => specLayerOrder_injective l₁ l₂ (Nat.le_antisymm h₁₂ h₂₁)

/-- Consistency of LT and LE: l₁ < l₂ iff l₁ <= l₂ and not (l₂ <= l₁). -/
theorem specLayer_lt_iff_le_not_le :
    ∀ (l₁ l₂ : SpecLayer), l₁ < l₂ ↔ l₁ ≤ l₂ ∧ ¬(l₂ ≤ l₁) := by
  intro _l₁ _l₂; exact Nat.lt_iff_le_and_not_ge

-- ============================================================
-- D6: 三段設計（境界→緩和策→変数）
-- ============================================================

/-!
## D6 Three-Stage Design

Rationale: Ontology.lean/Observable.lean three-stage structure (boundary -> mitigation -> variable)

BoundaryLayer, BoundaryId, and Mitigation are already defined in Ontology.lean.
Here we express the design principles as theorems.
-/

-- Day 171: `d6_fixed_boundary_mitigated` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 165: `DesignStage` は port に既存 (D.lean / Ontology / etc)。重複削除。

-- Day 165: `designStageOrder` は port に既存 (D.lean / Ontology / etc)。重複削除。

-- Day 171: `d6_stage_sequential` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 171: `d6_no_reverse` は port D.lean に既存 (DF root integration)。重複削除。

-- ============================================================
-- D6: DesignStage 半順序型クラスインスタンス（Run 61 追加）
-- ============================================================

/-- The ordering function is injective (distinct stages have distinct order values). -/
theorem designStageOrder_injective :
  ∀ (s₁ s₂ : DesignStage),
    designStageOrder s₁ = designStageOrder s₂ → s₁ = s₂ := by
  intro s₁ s₂; cases s₁ <;> cases s₂ <;> simp [designStageOrder]

instance : LE DesignStage := ⟨fun a b => designStageOrder a ≤ designStageOrder b⟩
instance : LT DesignStage := ⟨fun a b => designStageOrder a < designStageOrder b⟩

/-- Partial order reflexivity: s <= s. -/
theorem designStage_le_refl : ∀ (s : DesignStage), s ≤ s :=
  fun s => Nat.le_refl (designStageOrder s)

/-- Partial order transitivity: if s₁ <= s₂ and s₂ <= s₃ then s₁ <= s₃. -/
theorem designStage_le_trans :
    ∀ (s₁ s₂ s₃ : DesignStage), s₁ ≤ s₂ → s₂ ≤ s₃ → s₁ ≤ s₃ := by
  intro _s₁ _s₂ _s₃ h₁₂ h₂₃; exact Nat.le_trans h₁₂ h₂₃

/-- Partial order antisymmetry: if s₁ <= s₂ and s₂ <= s₁ then s₁ = s₂. -/
theorem designStage_le_antisymm :
    ∀ (s₁ s₂ : DesignStage), s₁ ≤ s₂ → s₂ ≤ s₁ → s₁ = s₂ :=
  fun s₁ s₂ h₁₂ h₂₁ => designStageOrder_injective s₁ s₂ (Nat.le_antisymm h₁₂ h₂₁)

/-- Consistency of LT and LE: s₁ < s₂ iff s₁ <= s₂ and not (s₂ <= s₁). -/
theorem designStage_lt_iff_le_not_le :
    ∀ (s₁ s₂ : DesignStage), s₁ < s₂ ↔ s₁ ≤ s₂ ∧ ¬(s₂ ≤ s₁) := by
  intro _s₁ _s₂; exact Nat.lt_iff_le_and_not_ge

-- ============================================================
-- D7: 信頼の非対称性
-- ============================================================

/-!
## D7 Trust Asymmetry

Rationale: Section 6 + P1 (co-growth)

Accumulation is bounded (trust_accumulates_gradually),
damage is unbounded (trust_decreases_on_materialized_risk).
-/

-- Day 171: `d7_accumulation_bounded` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 171: `d7_damage_unbounded` は port D.lean に既存 (DF root integration)。重複削除。

-- ============================================================
-- D8: 均衡探索
-- ============================================================

/-!
## D8 Equilibrium Search

Rationale: Section 6 + E2 (capability-risk co-scaling)

By overexpansion_reduces_value,
there exist cases where expansion of the action space reduces collaborative value.
-/

-- Day 171: `d8_overexpansion_risk` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 171: `d8_capability_risk` は port D.lean に既存 (DF root integration)。重複削除。

-- ============================================================
-- D9: メンテナンス原理（自己適用を含む）
-- ============================================================

/-!
## D9 Maintenance of the Classification Itself
Definitional Extension + Theorem, 5.5/4.2.

Rationale: Observable.lean Part IV + P3 (governed learning, theorem §4.2) + Section 7 (self-application)

The design foundation itself is subject to updates, and updates follow P3's compatibility classification.
This is a structuring of AGM revision operations (terminology reference §9.2):
- Conservative extension = conservative extension (§5.5)
- Compatible change = consistent extension (§5.5)
- Breaking change = non-extension change (some theorems are not preserved)

## Self-Application Requirements

Since D9 states the principle of "maintenance of the classification itself",
D1–D9 themselves must also be subject to D9 (Section 7).

To express this at the type level (§7.1 Curry-Howard correspondence):
1. Model D1–D9 as values of the DesignPrinciple type (extension of domain of discourse §3.2)
2. Require that updates to DesignPrinciple are classified by CompatibilityClass
3. Structurally enforce via the SelfGoverning type class (§9.4)
-/

-- Day 165: `DesignPrinciple` は port に既存 (D.lean / Ontology / etc)。重複削除。

/-- DesignPrinciple implements SelfGoverning.
    This makes D1–D9 themselves subject to governedUpdate,
    and updates without compatibility classification become type-level errors.

    Types that do not implement SelfGoverning cannot use governedUpdate or
    governed_update_classified, so defining a new principle type
    and forgetting to implement SelfGoverning is detected as a type error. -/
instance : SelfGoverning DesignPrinciple where
  classificationExhaustive := by intro c; cases c <;> simp
  canClassifyUpdate _ _ := True

-- Day 165: `DesignPrincipleUpdate` は port に既存 (D.lean / Ontology / etc)。重複削除。

-- Day 171: `d9_update_classified` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 165: `governedPrincipleUpdate` は port に既存 (D.lean / Ontology / etc)。重複削除。

-- Day 171: `d9_self_applicable` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 171: `d9_all_principles_enumerated` は port D.lean に既存 (DF root integration)。重複削除。

-- ============================================================
-- D4 の自己適用補強
-- ============================================================

/-!
## Self-Application of D4

D4 (progressive self-application) states that "the development process achieves
compliance up to each phase", but DesignFoundation itself should also be
developed following these phases.

Updates to DesignFoundation occur in the context of DevelopmentPhase,
and the compliance level of the updated phase progresses irreversibly (T2: structure_accumulates).
-/

/-- Self-application of D4: The design foundation itself has phases.
    Each principle is applicable only after the phase it requires is complete. -/
def principleRequiredPhase : DesignPrinciple → DevelopmentPhase
  | .d1_enforcementLayering         => .safety
  | .d2_workerVerifierSeparation    => .verification
  | .d3_observabilityFirst          => .observability
  | .d4_progressiveSelfApplication  => .safety  -- D4 自体は最初から必要
  | .d5_specTestImpl                => .verification
  | .d6_boundaryMitigationVariable  => .observability
  | .d7_trustAsymmetry              => .equilibrium
  | .d8_equilibriumSearch           => .equilibrium
  | .d9_selfMaintenance             => .safety  -- D9 も最初から必要
  | .d10_structuralPermanence       => .safety  -- T1+T2 は最初から成立
  | .d11_contextEconomy             => .observability  -- コンテキストコスト測定が前提
  | .d12_constraintSatisfactionTaskDesign => .governance  -- P6 は統治フェーズ
  | .d13_premiseNegationPropagation     => .governance  -- P3（退役）+ Section 8 が前提
  | .d14_verificationOrderConstraint   => .governance  -- P6 + T7 + T8 が前提
  | .d15_harnessEngineering            => .equilibrium -- 実装パターンは動的調整フェーズ
  | .d16_informationRelevance          => .observability -- コンテキスト寄与度の測定が前提
  | .d17_deductiveDesignWorkflow       => .governance -- P3（学習統治）+ D5（三層）が前提
  | .d18_multiAgentCoordination        => .equilibrium -- 動的調整フェーズ（D12 + T7b が前提）

/-- Self-application of D4: D4 and D9 are required from the safety phase.
    This means that "phase ordering" and "governed updates" must be
    functional from the very beginning of development. -/
theorem d4_d9_from_first_phase :
  principleRequiredPhase .d4_progressiveSelfApplication = .safety ∧
  principleRequiredPhase .d9_selfMaintenance = .safety := by
  constructor <;> rfl

-- ============================================================
-- 原理間の依存関係の検証
-- ============================================================

/-!
## Dependency Structure of D1-D9

Verifies that D4's (progressive self-application) phase ordering is
consistent with the dependency relationships of D1–D3.

- Phase 1 (safety) -> D1 (L1 requires structural enforcement)
- Phase 2 (verification) -> D2 (structural realization of P2)
- Phase 3 (observability) -> D3 (observability first)
- Phase 4 (governance) -> depends on D3 (P3 comes after P4)
- Phase 5 (equilibrium) -> depends on D7, D8 (trust and equilibrium)

This dependency structure is already expressed in phaseDependency.
d4_full_chain proves its existence.
-/

/-- Consistency of D1–D4: The first step of D4's phase ordering (safety -> verification)
    matches the ordering of D1 (L1 requires structural enforcement) and D2 (realization of P2).

    safety is first = D1 makes L1 structurally enforced
    verification is next = D2 realizes P2 -/
theorem dependency_d1_d2_d4_consistent :
  phaseDependency .verification .safety ∧
  minimumEnforcement .fixed = .structural := by
  constructor
  · trivial
  · rfl

-- ============================================================
-- D10: 構造永続性の設計定理
-- ============================================================

/-!
## D10 Structural Permanence
Theorem, 4.2.

Rationale: T1 (ephemerality, T₀ §4.1) + T2 (structural permanence, T₀ §4.1)

Agents are ephemeral (T1) but structure persists (T2).
Accumulation of improvements is possible only through structure.
Connects with P3 theorem group in Principles.lean (modifier_agent_terminates,
modification_persists_after_termination).
-/

-- Day 171: `d10_agent_temporary_structure_permanent` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 171: `d10_epoch_monotone` は port D.lean に既存 (DF root integration)。重複削除。

-- ============================================================
-- D11: コンテキスト経済の定理
-- ============================================================

/-!
## D11 Context Economy
Definitional Extension + Theorem, 5.5/4.2.

Rationale: T3 (context finiteness, T₀ §4.1) + D1 (enforcement layering)

Working memory (T3: amount of information that can be processed) is a finite resource,
and enforcement layers (D1) and context cost are inversely correlated:
structural enforcement (low cost) > procedural enforcement (medium cost) > normative guidelines (high cost).
-/

-- Day 165: `contextCost` は port に既存 (D.lean / Ontology / etc)。重複削除。

-- Day 171: `d11_enforcement_cost_inverse` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 171: `d11_structural_minimizes_cost` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 171: `d11_context_finite` は port D.lean に既存 (DF root integration)。重複削除。

-- ============================================================
-- D12: 制約充足によるタスク設計定理
-- ============================================================

/-!
## D12 Constraint Satisfaction Task Design
Theorem, 4.2.

Rationale: P6 (constraint satisfaction, theorem §4.2) + T3 + T7 + T8 (T₀ §4.1)

Task execution is a constraint satisfaction problem. Achieve precision requirements (T8)
within finite cognitive space (T3) and finite resources (T7).
Connects with P6 theorem group in Principles.lean.
-/

-- Day 171: `d12_task_is_csp` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 171: `d12_task_design_probabilistic` は port D.lean に既存 (DF root integration)。重複削除。

-- ============================================================
-- D13: 前提否定の影響波及定理
-- ============================================================

/-!
## D13 Premise Negation Impact Propagation
Theorem, 4.2.

Rationale: P3 (governed learning -- retirement) + Section 8 (coherenceRequirement) + T5

When a premise is negated, identify dependent derivations and re-verify them.
Generalizes Section 8's coherenceRequirement (priority-based review)
to arbitrary dependency relationships.

Based on PropositionId.dependencies from Ontology.lean,
defines impact set computation functions and basic properties.
-/

/-!
## Note on coherenceRequirement - Issue 243

The original `d13_coherence_implies_propagation` theorem was removed because it was
trivially-true: its conclusion was a direct restatement of its premise.

The root cause is that `coherenceRequirement` (Ontology.lean) has `True` as its conclusion,
making any theorem built on it vacuously true. Strengthening `coherenceRequirement` to use
a meaningful review obligation type (e.g., `NeedsReview`) would be a breaking change to
Ontology.lean and is deferred.

D13's substantive content is captured by:
- `affected` / `d13_propagation`: Impact set computation via transitive dependency closure
- `d13_constraint_negation_has_impact`: T4 negation produces non-empty impact
- `d13_retirement_requires_feedback`: P3 retirement presupposes T5
- `assumptionImpact` / `d13_assumption_subsumes_proposition`: Assumption-level propagation (#225)
- `d13_assumption_impact_monotone`: Monotonicity of assumption impact
-/

-- Day 171: `d13_retirement_requires_feedback` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 171: `allPropositions` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 171: `PropositionId.dependents` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 171: `affected` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 171: `d13_propagation` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 171: `d13_constraint_negation_has_impact` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 171: `d13_l5_limited_impact` は port D.lean に既存 (DF root integration)。重複削除。

-- ============================================================
-- D13 Extension: Assumption-level Impact Propagation (#225)
-- ============================================================

/-!
## D13 Extension - Temporal Expiration of Assumptions

Extends D13 from PropositionId-level to assumption-level propagation.

Conditional axiom systems S=(A,C,H,D) derive conclusions D from assumptions C/H.
C/H originate from external sources that change over time (#225).
When an assumption expires (its external source changes or its review period elapses),
all derivations depending on that assumption require re-verification.

This is the principle-level formalization. Operational types (TemporalValidity,
AssumptionExpiration) are defined in Models/Assumptions/EpistemicLayer.lean.
DesignFoundation.lean does not import Models to preserve the dependency direction
(core formalization must not depend on model instances).

The bridge: an assumption maps to a set of PropositionIds it supports.
When the assumption expires, all dependents of those PropositionIds are affected.
-/

-- Day 171: `assumptionImpact` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 171: `assumptionImpactRaw` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 171: `d13_assumption_subsumes_proposition` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 171: `d13_assumption_impact_monotone` は port D.lean に既存 (DF root integration)。重複削除。

-- ============================================================
-- Structure-PropositionId Bridge — 二層依存追跡の統合
-- ============================================================

/-!
## Correspondence between StructureKind and PropositionId

Connects the Structure-level partial order (Ontology.lean, structural consistency section)
with the PropositionId-level dependency graph (this file, §D13).
By answering the question "which axioms (PropositionId) does this Structure (file) depend on?",
refines the tracing from end-point errors back to the axiom level.

Corresponds to ATMS labeling from the research document.
-/

/-- Set of PropositionIds corresponding to each StructureKind.
    manifest.md encompasses all axioms/postulates/principles T1-T8, E1-E2, P1-P6.
    designConvention encompasses design theorems D1-D17.
    skill/test/document are empty sets due to individual definitions (room for future extension). -/
def structurePropositions : StructureKind → List PropositionId
  | .manifest         => [.t1, .t2, .t3, .t4, .t5, .t6, .t7, .t8,
                           .e1, .e2, .p1, .p2, .p3, .p4, .p5, .p6]
  | .designConvention => [.d1, .d2, .d3, .d4, .d5, .d6, .d7, .d8,
                           .d9, .d10, .d11, .d12, .d13, .d14,
                           .d15, .d16, .d17, .d18]
  | .skill            => []
  | .test             => []
  | .document         => []

-- Day 171: `structureToPropositionImpact` + 2 theorems (manifest_has_widest_impact / design_convention_has_impact) は
-- D.lean の `affected` 削除 (Day 171 dedup) の影響で reference 切れ + native_decide 違反 (PI-9)。
-- 同等の意味的内容は D.lean 側の affected / dependents を直接利用すること。Phase 2.1 で適切に再構築。

-- ============================================================
-- D14: 検証順序の制約充足性定理
-- ============================================================

/-!
## D14 Constraint Satisfaction of Verification Order
Theorem, 4.2.

Rationale: P6 (constraint satisfaction) + T7 (resource finiteness) + T8 (precision level)

Under finite resources, verification order affects outcomes.
The choice of ordering is included in P6's constraint satisfaction problem.
Extension of D12.

## What the Axiom System Does Not Determine

D14 derives that "verification order matters" but does not derive the optimal ordering method.
Information gain, risk-order (fail-fast), and cost-order are all models satisfying D14.
The choice of specific method is at the L6 (design convention) level.
-/

-- Day 171: `d14_verification_order_is_csp` は port D.lean に既存 (DF root integration)。重複削除。

-- ============================================================
-- D15: Harness Engineering Theorems (ForgeCode Analysis #147)
-- ============================================================

/-!
## D15 Harness Engineering Theorems
Theorem group, §4.2.

Derived from empirical analysis of ForgeCode (Terminal-Bench 2.0 #1, 81.8%).
ForgeCode's design decisions were mapped against T₀, and the following
theorems were identified as derivable but previously unstated.

Reference: GitHub Issue #147, #148 (S1 analysis).

## D15a Unbounded retry under finite resources is infeasible
Rationale: T7 (resource_finite) + T4 (output_nondeterministic)

Under finite resources (T7) and nondeterministic output (T4),
a strategy with unbounded retries cannot satisfy the resource constraint.
ForgeCode implements this as `max_tool_failure_per_turn`.

## D15b Non-converging agent loops require human intervention
Rationale: T6 (human_resource_authority, resource_revocable) + T5 (no_improvement_without_feedback)

When an agent loop fails to converge, continued execution without human
feedback violates both T6 (human authority over resources) and T5
(no improvement without feedback). ForgeCode implements this as
`max_requests_per_turn`.

## D15c Context eviction preserving feasibility
Rationale: T3 (context_finite) + T8 (task_has_precision) + P6 (task_is_constraint_satisfaction)

When context usage exceeds capacity (T3), evicting messages that do not
contribute to precision (T8) preserves strategyFeasible (P6).
ForgeCode implements this as the droppable flag + compaction strategy.

## D15d Computation saturation
Rationale: context_contribution_nonuniform (T3) + task_has_precision (T8) + resource_finite (T7)

For every task, zero-return computation steps exist unconditionally. Combined with
finite budgets (D15a), the optimal computation budget is strictly less than the
total resource budget. The saturation point's existence is provable; its location
requires external assessment (E1). This is the formal basis for satisficing and
adaptive computation depth policies (Phase 3c triggers, progressive thinking).
-/

-- Day 171: `d15a_unbounded_retry_infeasible` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 171: `d15b_non_convergence_requires_human` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 171: `d15c_eviction_preserves_feasibility` は port D.lean に既存 (DF root integration)。重複削除。

-- ============================================================
-- D15d: Computation Saturation (Metacognitive Termination)
-- ============================================================

/-!
## D15d Computation Saturation

Rationale: context_contribution_nonuniform (T3) + task_has_precision (T8) + resource_finite (T7)

Under finite resources (T7), not all computation contributes to precision (T3 extension),
and every task has a positive precision target (T8 structural). Therefore:
1. Zero-return computation steps exist for every task (waste is universal)
2. Resources that fund waste computation cannot improve precision
3. The optimal computation budget is strictly less than the total resource budget

This establishes that a **saturation point** exists — a resource expenditure level
beyond which additional computation yields zero marginal precision improvement.
The saturation point exists before resource exhaustion (D15a), making D15a's bound
a looser upper bound on useful computation.

**Critical limitation (E1):** While the saturation point's *existence* is provable,
its *location* cannot be determined by the computing agent itself. The agent that
reasons is the same agent that would need to judge "I've reasoned enough" —
violating E1 (verification requires independence). Therefore:
- Structural budget limits (D15a) provide a hard upper bound
- Human intervention (D15b) provides the authoritative stopping signal
- Heuristic triggers (Phase 3c) approximate the saturation point operationally

Prior art:
- Simon (1956) "Satisficing": under search costs, stopping at "good enough" is optimal
- Russell & Wefald (1991) "Value of Computation": stop when VOC drops to zero
- Graves (2016) "Adaptive Computation Time": learned halting probabilities
- Banino et al. (2021) "PonderNet": probabilistic stopping via geometric prior

Operational instances in this project:
- Phase 3c triggers: same error 3x, axiom inflation 2x → strategy change
- ForgeCode progressive thinking: high reasoning turns 1-10, low turns 11+
- model-questioner termination: contradiction count reaches zero
-/

-- Day 165: `ComputationStep` は port に既存 (D.lean / Ontology / etc)。重複削除。

-- Day 165: `marginalReturn` は port に既存 (D.lean / Ontology / etc)。重複削除。

-- Day 171: `d15d_computation_saturation` は port D.lean に既存 (DF root integration)。重複削除。

-- ============================================================
-- D16: Information Relevance Theorems (ForgeCode Analysis #147 B-group)
-- ============================================================

/-!
## D16 Information Relevance Theorems
Theorem group, §4.2.

Derived from the new T₀ axiom `context_contribution_nonuniform` (T3 extension)
combined with existing axioms. These theorems formalize the consequences of
non-uniform information relevance identified in ForgeCode analysis #147/#150 (S3).

## D16a Zero-contribution items exist and can be evicted
Rationale: context_contribution_nonuniform + D15c (eviction preserves feasibility)

## D16b Input design affects output quality
Rationale: context_contribution_nonuniform + T4 (nondeterminism) + T8 (precision)

Applicable to B3 (tool naming alignment with training data) and
B6 (prompt composition optimization).

## D16c Resource allocation should follow contribution
Rationale: context_contribution_nonuniform + T7 (resource finite) + T3 (context finite)

Applicable to B5 (progressive thinking policy).
-/

-- Day 171: `d16a_zero_contribution_items_exist` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 171: `d16b_context_composition_matters` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 171: `d16c_resource_follows_contribution` は port D.lean に既存 (DF root integration)。重複削除。

-- ============================================================
-- D18: マルチエージェント協調の定理
-- ============================================================

/-!
## D18 Multi-Agent Coordination
Theorem, 4.2.

Rationale: T7b (sequential_exceeds_component) + D12 (task is CSP) + T3 (context finite)

When a task can be decomposed into independent subtasks (D12), and each subtask
has positive execution duration (T7b), sequential execution costs more time than
parallel execution. Under finite time budgets, parallel coordination is rational.

This is the platform-independent principle underlying Agent Teams, multi-agent
frameworks (CrewAI, AutoGen), and subagent delegation patterns.

B4 root cause analysis (#276): The axiom system lacked T7b (temporal resource
additivity). Without T7b, D12's task decomposition could not distinguish
sequential from parallel execution, making multi-agent coordination underivable.
-/

-- Day 171: `d18_parallel_reduces_temporal_cost` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 171: `d18_coordination_rational_under_constraints` は port D.lean に既存 (DF root integration)。重複削除。

-- ============================================================
-- D17: 演繹的設計ワークフロー定理
-- ============================================================

/-!
## D17 Deductive Design Workflow
Definitional Extension + Theorem, 5.5/4.2.

Rationale: T5 (feedback) + D3 (observability first) + P3 (governed learning)
         + T6 (human authority) + D5 (spec/test/impl) + D9 (self-maintenance)
         + E1 (verification independence) + D2 (worker/verifier separation)
         + D13 (impact propagation)

A valid design derivation for a platform must proceed through a conditional
the axiom system — not directly from core axioms. The workflow is:

1. **Investigate**: Observe the target environment (T5 + D3)
2. **Extract**: Form assumptions C/H from observations (P3 + T6)
3. **Construct**: Build conditional axiom system from core + assumptions (D5 + D9)
4. **Derive**: Produce design decisions from conditional axioms (D1-D16)
5. **Validate**: Independently verify derived design (E1 + D2)
6. **Feedback**: Propagate invalidation through dependencies (T5 + D13)

The ordering is a partial order derived from the axiom dependency structure,
not an arbitrary convention. Steps cannot be reordered because each step's
premises require the output of prior steps.
-/

-- Day 171: `DeductiveDesignStep` は port D.lean に既存 (DF root integration)。重複削除。

/-!
## Note on step ordering

Step ordering was previously expressed via `DeductiveDesignStep.ord` and
encoding theorems (d17_investigate_before_extract, etc.). These were removed
because the ordering is now structurally enforced by the state machine:
`WorkflowState.currentStep` computes the next step from the Option fields,
and `applyTransition` rejects out-of-order transitions by returning none.

The axiom-level justification for WHY each step precedes the next remains
valid and is documented in the DeductiveDesignStep constructors' comments:
- investigate before extract: T5 + D3 (observe before hypothesize)
- extract before construct: P3 + T6 (hypothesize before integrate)
- construct before derive: D5 + D9 (specify before implement)
- derive before validate: E1 + D2 (generate before verify)
- validate before feedback: T5 + D13 (measure before propagate)
-/

-- ============================================================
-- D17 Extension: Step Output Types and Intermediate Verification
-- ============================================================

/-!
## D17 Step Output Types - Issue 262

Each step produces a typed output consumed by the next step.
The type connection replaces the encoding theorem ordering with
a structural dependency: step N's output type IS step N+1's input.
-/

-- Day 171: `InvestigationReport` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 171: `investigateStepValid` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 171: `AssumptionSet` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 171: `ConditionalAxiomBuildResult` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 171: `DerivationOutput` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 171: `ValidationMetrics` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 171: `stepTransitionRisk` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 171: `d17_high_risk_transitions_need_hook_verify` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 171: `constructStepValid` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 171: `extractStepValid` は port D.lean に既存 (DF root integration)。重複削除。

-- ============================================================
-- D17 State Machine (#265): Typed state transitions with verify gates
-- ============================================================

/-!
## D17 State Machine

Replaces the encoding-theorem ordering with a state transition system.
The workflow state accumulates step outputs. Transitions are gated:
high-risk steps (extract, construct) require validity proofs as preconditions.
Feedback loops reset state to the appropriate step based on D13 impact scope.
-/

-- Day 171: `WorkflowState` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 171: `WorkflowState.currentStep` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 171: `WorkflowState.initial` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 171: `FeedbackAction` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 171: `WorkflowTransition` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 171: `applyTransition` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 171: `d17_initial_starts_at_investigate` は port D.lean に既存 (DF root integration)。重複削除。

-- Day 171: `d17_state_machine_properties` は port D.lean に既存 (DF root integration)。重複削除。

-- ============================================================
-- Sorry Inventory
-- ============================================================

/-!
## Sorry Inventory DesignFoundation

No sorry.

D1–D17 use no new non-logical axioms (§4.1) except D15–D16.
D15–D16 use `context_contribution_nonuniform` (T₀ extension in Axioms.lean).
D17 step-ordering theorems are encoding theorems: axiom connections justify
the choice of ord values, but proofs are definitional (simp on Nat literals).

All theorems (§4.2) are proven by direct application of existing axioms (T/E/P/V)
or by cases analysis on inductive types (§7.2).

Each principle D1–D17 is guaranteed by type-checking to be
**derivable** (§2.4 derivability) from the manifesto's axiom system.
D15–D16 are derivable from the extended axiom system (T₀ + context_contribution_nonuniform).
This file consists solely of definitional extensions (§5.5),
and conservative extension is guaranteed by `definitional_implies_conservative`
proven in Terminology.lean.

## Known Formalization Gaps
Sorry Inventory.

| D | Gap | Impact |
|---|---------|------|
| D3 | The 3 observability conditions (measurable/degradation-detectable/improvement-verifiable) are not structured | 3 theorems exist but the condition structure is not formalized |
| D5 | Inter-layer relations of spec/test/implementation are not formalized | 3 theorems exist but transitive dependencies between layers are not formalized |
| D6 | Causal chain of boundary -> mitigation -> variable is not formalized | 3 theorems exist but causal chain is not formalized |

## Structural Enforcement of Section 7
Self-Application.

Via the `SelfGoverning` type class (§9.4, Ontology.lean),
the `DesignPrinciple` type defining D1–D17 satisfies:
- Applicability of compatibility classification (`canClassifyUpdate`)
- Exhaustiveness of classification (`classificationExhaustive`)

Since calling `governed_update_classified` requires `[SelfGoverning α]`,
types that do not implement SelfGoverning cannot be used in the
self-application context -> **missing implementations are detected as type errors**.
-/

end AgentSpec.Manifest
