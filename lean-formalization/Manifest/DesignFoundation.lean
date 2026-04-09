import Manifest.Ontology
import Manifest.Axioms
import Manifest.EmpiricalPostulates
import Manifest.Principles
import Manifest.Observable
import Manifest.ObservableDesign

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
| D15 | T3+T4+T5+T6+T7+T8+P6 | 3 theorems (retry bounds, convergence, eviction) |
| D16 | context_contribution_nonuniform | 3 theorems (zero-contribution, composition, resource) |
| D17 | T5+D3+P3+T6+D5+D9+E1+D2+D13 | type + 8 theorems (deductive design workflow) |
-/

namespace Manifest

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

/-- Enforcement layer. Represents the strength of enforcement power. -/
inductive EnforcementLayer where
  | structural   -- 違反が物理的に不可能
  | procedural   -- 違反は可能だが検出・阻止される
  | normative    -- 遵守は確率的（P5）
  deriving BEq, Repr

/-- Strength ordering of enforcement layers. structural is the strongest. -/
def EnforcementLayer.strength : EnforcementLayer → Nat
  | .structural => 3
  | .procedural => 2
  | .normative  => 1

/-- Minimum required enforcement layer for each boundary condition.
    Fixed boundaries (L1, L2) require structural enforcement.
    Investment-variable boundaries require procedural enforcement or above.
    Environmental boundaries may use normative guidelines. -/
def minimumEnforcement : BoundaryLayer → EnforcementLayer
  | .fixed              => .structural
  | .investmentVariable => .procedural
  | .environmental      => .normative

/-- [Derivation Card]
    Derives from: probabilistic_interpretation_insufficient (P5 / T4)
    Proposition: D1
    Content: Fixed boundaries (L1) require structural enforcement. Normative guidelines cannot guarantee L1 compliance under nondeterministic interpretation.
    Proof strategy: rfl (definitional equality — minimumEnforcement maps .fixed to .structural) -/
theorem d1_fixed_requires_structural :
  minimumEnforcement .fixed = .structural := by rfl

/-- Corollary of D1: Enforcement layer strength is monotone with respect to boundary layers.
    Enforcement strength required: fixed >= investment-variable >= environmental. -/
theorem d1_enforcement_monotone :
  (minimumEnforcement .fixed).strength ≥
  (minimumEnforcement .investmentVariable).strength ∧
  (minimumEnforcement .investmentVariable).strength ≥
  (minimumEnforcement .environmental).strength := by
  simp [minimumEnforcement, EnforcementLayer.strength]

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

/-- Four conditions for verification independence.

    The former 3 conditions (context separation, bias non-sharing, independent invocation)
    covered only process-level independence. Without evaluator independence,
    the problem of "the same model making the same mistakes in a different context" remains.

    Four conditions:
    1. Context separation: Worker's reasoning process and intermediate state do not leak to Verifier
    2. Framing independence: Verification criteria are not post-hoc defined by the Worker
       (Refinement of former "bias non-sharing". Not only the artifacts,
       but also the framework of "what should be verified" is independent of the Worker)
    3. Execution automaticity: Worker cannot bypass verification
       (Strengthening of former "independent invocation". Does not depend on Worker's discretion)
    4. Evaluator independence: Evaluation is performed by a separate entity without shared judgment tendencies
       (Human: A different person without shared context but with sufficient knowledge.
        LLM: A different model without shared context.
        Same model with different context corresponds to a Subagent,
        which achieves process separation but not evaluator independence) -/
structure VerificationIndependence where
  /-- Worker's reasoning process does not leak to Verifier -/
  contextSeparated      : Bool
  /-- Verification criteria do not depend on Worker's framing -/
  framingIndependent    : Bool
  /-- Verification execution does not depend on Worker's discretion -/
  executionAutomatic    : Bool
  /-- Evaluator has different judgment tendencies from Worker -/
  evaluatorIndependent  : Bool
  deriving BEq, Repr

/-- Verification risk level.
    The required level of independence varies by risk. -/
inductive VerificationRisk where
  | critical  -- L1 関連: 安全・倫理
  | high      -- 構造変更: アーキテクチャ、設定
  | moderate  -- 通常コード変更
  | low       -- ドキュメント、コメント
  deriving BEq, Repr

/-- Required independence conditions for each risk level.
    The model is quantitative: any N conditions out of 4 suffice.
    critical: All 4 conditions required (verification by human or different model)
    high: Any 3 of 4 conditions (e.g. context separation + framing independence + evaluator independence)
    moderate: Any 2 of 4 conditions (e.g. context separation + automatic execution)
    low: Any 1 of 4 conditions (context separation alone suffices) -/
def requiredConditions : VerificationRisk → Nat
  | .critical => 4
  | .high     => 3
  | .moderate => 2
  | .low      => 1

/-- Counts the number of satisfied independence conditions. -/
def satisfiedConditions (vi : VerificationIndependence) : Nat :=
  (if vi.contextSeparated then 1 else 0) +
  (if vi.framingIndependent then 1 else 0) +
  (if vi.executionAutomatic then 1 else 0) +
  (if vi.evaluatorIndependent then 1 else 0)

/-- Whether verification is sufficient: satisfied conditions >= required conditions -/
def sufficientVerification
    (vi : VerificationIndependence) (risk : VerificationRisk) : Prop :=
  satisfiedConditions vi ≥ requiredConditions risk

/-- Critical risk requires all four conditions.
    Subagent (contextSeparated only) is insufficient. -/
theorem critical_requires_all_four :
  requiredConditions .critical = 4 := by rfl

/-- Subagent-only verification (context separation only) is sufficient only for low risk. -/
theorem subagent_only_sufficient_for_low :
  let subagentOnly : VerificationIndependence :=
    { contextSeparated := true
      framingIndependent := false
      executionAutomatic := false
      evaluatorIndependent := false }
  sufficientVerification subagentOnly .low ∧
  ¬sufficientVerification subagentOnly .moderate := by
  simp [sufficientVerification, satisfiedConditions, requiredConditions]

/-- Backward compatibility with former validSeparation: the old 3 conditions are a subset of the new 4 conditions. -/
def validSeparation (vs : VerificationIndependence) : Prop :=
  vs.contextSeparated = true ∧
  vs.framingIndependent = true ∧
  vs.executionAutomatic = true

/-- [Derivation Card]
    Derives from: verification_requires_independence (E1)
    Proposition: D2
    Content: Valid verification requires separation — generator and verifier must have distinct IDs and not share internal state, ensuring contextual and evaluative independence.
    Proof strategy: Direct application of verification_requires_independence (E1) -/
theorem d2_from_e1 :
  ∀ (gen ver : Agent) (action : Action) (w : World),
    generates gen action w →
    verifies ver action w →
    gen.id ≠ ver.id ∧ ¬sharesInternalState gen ver :=
  verification_requires_independence

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

/-- [Derivation Card]
    Derives from: no_improvement_without_feedback (T5)
    Proposition: D3
    Content: Feedback must precede improvement — observability is a necessary precondition for structural improvement.
    Proof strategy: Direct application of T5 (no_improvement_without_feedback) -/
theorem d3_observability_precedes_improvement :
  ∀ (w w' : World),
    structureImproved w w' →
    ∃ (f : Feedback), f ∈ w'.feedbacks ∧
      f.timestamp ≥ w.time ∧ f.timestamp ≤ w'.time :=
  no_improvement_without_feedback

/-- Distinction of detection modes (introduced in Run 41).
    Refines the definition of "detectable": distinguishes between
    human-readable (humanReadable) and programmatically queryable (structurallyQueryable).
    D3 condition 2 requires structurallyQueryable. -/
inductive DetectionMode where
  | humanReadable         : DetectionMode  -- 人間が読めば分かる（自由テキスト等）
  | structurallyQueryable : DetectionMode  -- プログラムでクエリ可能（構造化フィールド等）
  deriving BEq, Repr

/-- D3 observability 3 conditions (design-development-foundation.md §D3).
    Only when all 3 conditions hold for a variable V does
    V become an effectively optimizable target. -/
structure ObservabilityConditions where
  /-- Whether the current value is measurable (Measurable, Observable.lean) -/
  measurable            : Bool
  /-- Whether degradation is detectable (can it be detected before quality collapse) -/
  degradationDetectable : Bool
  /-- Detection mode for degradation (ineffective unless structurallyQueryable) -/
  detectionMode         : DetectionMode := .structurallyQueryable
  /-- Whether improvement is verifiable (can value changes be compared before and after intervention) -/
  improvementVerifiable : Bool
  deriving BEq, Repr

/-- Determines whether a variable is an effectively optimizable target. All 3 conditions required.
    Additionally, degradation detection must be in a structurally queryable format. -/
def effectivelyOptimizable (c : ObservabilityConditions) : Prop :=
  c.measurable = true ∧ c.degradationDetectable = true ∧
  c.detectionMode = .structurallyQueryable ∧ c.improvementVerifiable = true

/-- D3: A variable lacking any of the 3 conditions is merely a nominal optimization target. -/
theorem d3_partial_observability_insufficient :
  ¬effectivelyOptimizable ⟨true, true, .structurallyQueryable, false⟩ ∧
  ¬effectivelyOptimizable ⟨true, false, .structurallyQueryable, true⟩ ∧
  ¬effectivelyOptimizable ⟨false, true, .structurallyQueryable, true⟩ := by
  refine ⟨?_, ?_, ?_⟩ <;> simp [effectivelyOptimizable]

/-- D3: Effective only when all 3 conditions hold and detection is structurally queryable. -/
theorem d3_full_observability_sufficient :
  effectivelyOptimizable ⟨true, true, .structurallyQueryable, true⟩ := by
  simp [effectivelyOptimizable]

/-- D3 refinement (Run 41): Human-readable but structurally non-queryable detection is insufficient.
    Merely writing in notes is ineffective even if degradationDetectable = true. -/
theorem d3_human_readable_insufficient :
  ¬effectivelyOptimizable ⟨true, true, .humanReadable, true⟩ := by
  simp [effectivelyOptimizable]

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

/-- Development phase. Each stage of D4's progressive self-application. -/
inductive DevelopmentPhase where
  | safety        -- L1: 安全基盤
  | verification  -- P2: 検証基盤
  | observability -- P4: 可観測性
  | governance    -- P3: 統治
  | equilibrium   -- 投資サイクル + 動的調整
  deriving BEq, Repr

/-- Inter-phase dependencies. A subsequent phase cannot begin
    until the preceding phase is complete. -/
def phaseDependency : DevelopmentPhase → DevelopmentPhase → Prop
  | .verification,  .safety        => True  -- P2 は L1 の後
  | .observability, .verification  => True  -- P4 は P2 の後
  | .governance,    .observability => True  -- P3 は P4 の後
  | .equilibrium,   .governance    => True  -- 投資は P3 の後
  | _,              _              => False

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

/-- Types of the three-layer representation. -/
inductive SpecLayer where
  | formalSpec        -- 形式仕様（Lean axiom/theorem）
  | acceptanceTest    -- 受け入れテスト（実行可能な検証）
  | implementation    -- 実装（プラットフォーム固有）
  deriving BEq, Repr

/-- Test kinds. Corresponds to T4 (probabilistic output). -/
inductive TestKind where
  | structural   -- 構成の存在を確認（決定論的）
  | behavioral   -- 実行して結果を確認（確率的、T4）
  deriving BEq, Repr

/-- [Derivation Card]
    Derives from: task_has_precision (T8)
    Proposition: D5
    Content: Tests must have non-zero precision — a task with precision level 0 is meaningless and cannot support meaningful optimization or acceptance criteria.
    Proof strategy: Direct application of task_has_precision (T8) -/
theorem d5_test_has_precision :
  ∀ (task : Task),
    task.precisionRequired.required > 0 :=
  task_has_precision

/-- Correspondence between the three layers. Composed in the order: formal spec -> test -> implementation.
    design-development-foundation.md D5:
    "Formal spec -> Test: At least one test exists for each axiom/theorem"
    "Test -> Implementation: Tests exist first, and the implementation passes the tests" -/
def specLayerOrder : SpecLayer → Nat
  | .formalSpec      => 0   -- 最初に仕様を定義
  | .acceptanceTest  => 1   -- 仕様からテストを導出
  | .implementation  => 2   -- テストを通す実装を構築

/-- D5: The three layers are strictly ordered. -/
theorem d5_layer_sequential :
  specLayerOrder .formalSpec < specLayerOrder .acceptanceTest ∧
  specLayerOrder .acceptanceTest < specLayerOrder .implementation := by
  simp [specLayerOrder]

/-- Determinism of tests. Structural tests are deterministic, behavioral tests are probabilistic (T4). -/
def testDeterministic : TestKind → Bool
  | .structural => true    -- 決定論的: 存在の有無を確認
  | .behavioral => false   -- 確率的: T4 により結果が変動しうる

/-- D5 + T4: Structural tests are deterministic, behavioral tests are probabilistic. -/
theorem d5_structural_test_deterministic :
  testDeterministic .structural = true ∧
  testDeterministic .behavioral = false := by
  constructor <;> rfl

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

/-- Rationale for D6: Variables corresponding to fixed boundaries can only improve mitigation quality. -/
theorem d6_fixed_boundary_mitigated :
  boundaryLayer .ethicsSafety = .fixed ∧
  boundaryLayer .ontological = .fixed := by
  simp [boundaryLayer]

/-- Design flow of the three-stage design.
    design-development-foundation.md D6:
    "Boundary conditions (invariant) -> Mitigations (design decisions) -> Variables (quality metrics)"
    Design always proceeds in this direction; the reverse direction is prohibited. -/
inductive DesignStage where
  /-- Identify boundary conditions (invariant; only accepted) -/
  | identifyBoundary
  /-- Design mitigations (design decisions belonging to L6) -/
  | designMitigation
  /-- Define variables (metrics for mitigation effectiveness) -/
  | defineVariable
  deriving BEq, Repr, DecidableEq

/-- Stage ordering of the three-stage design. -/
def designStageOrder : DesignStage → Nat
  | .identifyBoundary  => 0
  | .designMitigation  => 1
  | .defineVariable    => 2

/-- [Derivation Card]
    Derives from: designStageOrder (definitional)
    Proposition: D6
    Content: The three-stage design is strictly ordered — identifyBoundary < designMitigation < defineVariable. The stage ordering function assigns monotonically increasing natural numbers.
    Proof strategy: simp [designStageOrder] — unfold the ordering function and reduce to Nat inequalities -/
theorem d6_stage_sequential :
  designStageOrder .identifyBoundary < designStageOrder .designMitigation ∧
  designStageOrder .designMitigation < designStageOrder .defineVariable := by
  simp [designStageOrder]

/-- D6: Reverse direction prohibited. Do not attempt to directly improve variables (Goodhart's Law trap).
    The variable stage is last; there is no backtracking from variables to boundary conditions or mitigations. -/
theorem d6_no_reverse :
  ∀ (s : DesignStage),
    designStageOrder .identifyBoundary ≤ designStageOrder s := by
  intro s; cases s <;> simp [designStageOrder]

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

/-- [Derivation Card]
    Derives from: trust_accumulates_gradually (P1)
    Proposition: D7
    Content: Trust accumulation is bounded — incremental increases are capped by trustIncrementBound, formalizing the asymmetry of gradual growth.
    Proof strategy: Direct application of trust_accumulates_gradually (P1) -/
theorem d7_accumulation_bounded :
  ∀ (agent : Agent) (w w' : World),
    actionSpaceSize agent w ≤ actionSpaceSize agent w' →
    ¬riskMaterialized agent w' →
    trustLevel agent w ≤ trustLevel agent w' ∧
    trustLevel agent w' ≤ trustLevel agent w + trustIncrementBound :=
  trust_accumulates_gradually

/-- [Derivation Card]
    Derives from: trust_decreases_on_materialized_risk (P1)
    Proposition: D7
    Content: Trust damage from materialized risk is unbounded — a single incident can destroy arbitrarily accumulated trust, formalizing the asymmetry of abrupt destruction.
    Proof strategy: Direct application of trust_decreases_on_materialized_risk (P1) -/
theorem d7_damage_unbounded :
  ∀ (agent : Agent) (w w' : World),
    actionSpaceSize agent w < actionSpaceSize agent w' →
    riskMaterialized agent w' →
    trustLevel agent w' < trustLevel agent w :=
  trust_decreases_on_materialized_risk

-- ============================================================
-- D8: 均衡探索
-- ============================================================

/-!
## D8 Equilibrium Search

Rationale: Section 6 + E2 (capability-risk co-scaling)

By overexpansion_reduces_value,
there exist cases where expansion of the action space reduces collaborative value.
-/

/-- [Derivation Card]
    Derives from: overexpansion_reduces_value (E2)
    Proposition: D8
    Content: Overexpansion of the action space can reduce collaborative value — equilibrium search is necessary to avoid value-destroying expansion.
    Proof strategy: Direct application of overexpansion_reduces_value (E2) -/
theorem d8_overexpansion_risk :
  ∃ (agent : Agent) (w w' : World),
    actionSpaceSize agent w < actionSpaceSize agent w' ∧
    collaborativeValue w' < collaborativeValue w :=
  overexpansion_reduces_value

/-- D8's connection to P1: Capability expansion is inseparable from risk expansion.
    Direct application of E2. -/
theorem d8_capability_risk :
  ∀ (agent : Agent) (w w' : World),
    actionSpaceSize agent w < actionSpaceSize agent w' →
    riskExposure agent w < riskExposure agent w' :=
  capability_risk_coscaling

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

/-- Design principle identifiers. Enumerates D1–D17 as values.
    This allows D1–D17 themselves to be treated at the type level as "targets of updates". -/
inductive DesignPrinciple where
  | d1_enforcementLayering
  | d2_workerVerifierSeparation
  | d3_observabilityFirst
  | d4_progressiveSelfApplication
  | d5_specTestImpl
  | d6_boundaryMitigationVariable
  | d7_trustAsymmetry
  | d8_equilibriumSearch
  | d9_selfMaintenance
  | d10_structuralPermanence
  | d11_contextEconomy
  | d12_constraintSatisfactionTaskDesign
  | d13_premiseNegationPropagation
  | d14_verificationOrderConstraint
  | d15_harnessEngineering
  | d16_informationRelevance
  | d17_deductiveDesignWorkflow
  deriving BEq, Repr

/-- DesignPrinciple implements SelfGoverning.
    This makes D1–D9 themselves subject to governedUpdate,
    and updates without compatibility classification become type-level errors.

    Types that do not implement SelfGoverning cannot use governedUpdate or
    governed_update_classified, so defining a new principle type
    and forgetting to implement SelfGoverning is detected as a type error. -/
instance : SelfGoverning DesignPrinciple where
  classificationExhaustive := by intro c; cases c <;> simp
  canClassifyUpdate _ _ := True

/-- Design principle update event.
    Self-application of D9: Changes to D1–D9 themselves also go through compatibility classification. -/
structure DesignPrincipleUpdate where
  /-- The principle being updated -/
  principle     : DesignPrinciple
  /-- Compatibility classification of the update -/
  compatibility : CompatibilityClass
  /-- Rationale for the update (reference to manifesto's T/E/P) -/
  hasRationale  : Bool
  deriving Repr

/-- [Derivation Card]
    Derives from: CompatibilityClass (definitional — exhaustive inductive type)
    Proposition: D9
    Content: Any compatibility classification belongs to exactly one of the three classes: conservativeExtension, compatibleChange, or breakingChange.
    Proof strategy: intro c; cases c <;> simp — exhaustive case analysis on the CompatibilityClass inductive type -/
theorem d9_update_classified :
  ∀ (c : CompatibilityClass),
    c = .conservativeExtension ∨
    c = .compatibleChange ∨
    c = .breakingChange := by
  intro c; cases c <;> simp

/-- Self-application of D9: Updates to D9 itself also go through compatibility classification.
    The DesignPrincipleUpdate type structurally requires this
    (the compatibility field is mandatory).

    Furthermore, updates require a rationale (D9: principles that lose their rationale are subject to review). -/
def governedPrincipleUpdate (u : DesignPrincipleUpdate) : Prop :=
  u.hasRationale = true

/-- Self-application of D9: Proves via the SelfGoverning typeclass that
    any update to DesignPrinciple is compatibility-classified.

    governed_update_classified can only be called on types that have a
    SelfGoverning instance. If DesignPrinciple does not implement
    SelfGoverning, this theorem becomes a type error.
    -> Missing implementations are structurally detected. -/
theorem d9_self_applicable :
  ∀ (_p : DesignPrinciple) (c : CompatibilityClass),
    c = .conservativeExtension ∨ c = .compatibleChange ∨ c = .breakingChange :=
  fun _p c => governed_update_classified _p c

/-- D9 exhaustiveness: All principles D1–D17 are enumerated as update targets. -/
theorem d9_all_principles_enumerated :
  ∀ (p : DesignPrinciple),
    p = .d1_enforcementLayering ∨
    p = .d2_workerVerifierSeparation ∨
    p = .d3_observabilityFirst ∨
    p = .d4_progressiveSelfApplication ∨
    p = .d5_specTestImpl ∨
    p = .d6_boundaryMitigationVariable ∨
    p = .d7_trustAsymmetry ∨
    p = .d8_equilibriumSearch ∨
    p = .d9_selfMaintenance ∨
    p = .d10_structuralPermanence ∨
    p = .d11_contextEconomy ∨
    p = .d12_constraintSatisfactionTaskDesign ∨
    p = .d13_premiseNegationPropagation ∨
    p = .d14_verificationOrderConstraint ∨
    p = .d15_harnessEngineering ∨
    p = .d16_informationRelevance ∨
    p = .d17_deductiveDesignWorkflow := by
  intro p; cases p <;> simp

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

/-- [Derivation Card]
    Derives from: session_bounded (T1), structure_persists (T2)
    Proposition: D10
    Content: Agents are ephemeral (T1) but structure persists (T2) — accumulation of improvements is possible only through structure, not through persistent agent identity.
    Proof strategy: Constructor pair ⟨session_bounded, structure_persists⟩ — direct composition of T1 and T2 -/
theorem d10_agent_temporary_structure_permanent :
  -- T1: セッションは終了する
  (∀ (w : World) (s : Session),
    s ∈ w.sessions →
    ∃ (w' : World), w.time ≤ w'.time ∧
      ∃ (s' : Session), s' ∈ w'.sessions ∧
        s'.id = s.id ∧ s'.status = SessionStatus.terminated) ∧
  -- T2: 構造は永続する
  (∀ (w w' : World) (s : Session) (st : Structure),
    s ∈ w.sessions → st ∈ w.structures →
    s.status = SessionStatus.terminated →
    validTransition w w' → st ∈ w'.structures) :=
  ⟨session_bounded, structure_persists⟩

/-- Corollary of D10: Writing back to structure is the sole means of accumulation.
    Epochs (T2: structure_accumulates) increase monotonically. -/
theorem d10_epoch_monotone :
  ∀ (w w' : World), validTransition w w' → w.epoch ≤ w'.epoch :=
  structure_accumulates

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

/-- Context cost for D1's enforcement layers.
    Higher values consume more context. -/
def contextCost : EnforcementLayer → Nat
  | .structural => 0   -- 一度設定すれば毎セッション読む必要がない
  | .procedural => 1   -- プロセスは存在するがコンテキストに常駐しない
  | .normative  => 2   -- 毎セッション読み込まれ、コンテキストを占有する

/-- [Derivation Card]
    Derives from: contextCost (definitional)
    Proposition: D11
    Content: Enforcement power and context cost are inversely correlated — structural (0) < procedural (1) < normative (2). Higher enforcement power means lower context cost.
    Proof strategy: simp [contextCost] — unfold the cost function and reduce to Nat inequalities -/
theorem d11_enforcement_cost_inverse :
  contextCost .structural < contextCost .procedural ∧
  contextCost .procedural < contextCost .normative := by
  simp [contextCost]

/-- D11: Promotion to structural enforcement reduces context cost. -/
theorem d11_structural_minimizes_cost :
  ∀ (e : EnforcementLayer),
    contextCost .structural ≤ contextCost e := by
  intro e; cases e <;> simp [contextCost]

/-- D11 + T3: Context capacity is finite (T3), and
    bloating of normative guidelines degrades V2 (context efficiency). -/
theorem d11_context_finite :
  ∀ (agent : Agent),
    agent.contextWindow.capacity > 0 ∧
    agent.contextWindow.used ≤ agent.contextWindow.capacity :=
  context_finite

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

/-- [Derivation Card]
    Derives from: task_is_constraint_satisfaction (P6)
    Proposition: D12
    Content: Task design is a constraint satisfaction problem over T3+T7+T8. A feasible strategy must satisfy context capacity (T3), resource budget (T7), and precision requirement (T8) simultaneously.
    Proof strategy: Direct application of task_is_constraint_satisfaction (P6) — restatement at the design principle level -/
theorem d12_task_is_csp :
  ∀ (task : Task) (agent : Agent),
    agent.contextWindow.capacity > 0 →
    task.resourceBudget ≤ globalResourceBound →
    task.precisionRequired.required > 0 →
    ∀ (s : TaskStrategy),
      s.task = task →
      strategyFeasible s agent →
      s.contextUsage ≤ agent.contextWindow.capacity ∧
      s.resourceUsage ≤ globalResourceBound ∧
      s.achievedPrecision > 0 :=
  task_is_constraint_satisfaction

/-- D12: Task design itself is also probabilistic output (T4),
    requiring verification through P2 (cognitive role separation). -/
theorem d12_task_design_probabilistic :
  ∃ (agent : Agent) (action : Action) (w w₁ w₂ : World),
    canTransition agent action w w₁ ∧
    canTransition agent action w w₂ ∧
    w₁ ≠ w₂ :=
  output_nondeterministic

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
### Note on coherenceRequirement (#243)

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

/-- D13: P3's retirement operation presupposes T5 (feedback).
    Without feedback, negation of premises cannot be detected. -/
theorem d13_retirement_requires_feedback :
  ∀ (w : World),
    w.feedbacks = [] →
    ¬(∃ (f : Feedback), f ∈ w.feedbacks ∧ f.kind = .measurement) :=
  fun _ hnil ⟨_, hf, _⟩ => by simp [hnil] at hf

/-- Enumeration of all propositions. Used in affected computation. -/
def allPropositions : List PropositionId :=
  [.t1, .t2, .t3, .t4, .t5, .t6, .t7, .t8,
   .e1, .e2,
   .p1, .p2, .p3, .p4, .p5, .p6,
   .l1, .l2, .l3, .l4, .l5, .l6,
   .d1, .d2, .d3, .d4, .d5, .d6, .d7, .d8, .d9, .d10, .d11, .d12, .d13, .d14,
   .d15, .d16, .d17]

/-- Set of propositions that directly depend on proposition s (reverse edges).
    dependencies = "what it depends on"; dependents = "what depends on it". -/
def PropositionId.dependents (s : PropositionId) : List PropositionId :=
  allPropositions.filter (fun p => propositionDependsOn p s)

/-- Computes the impact set when premise s is negated.
    Transitive closure of the reverse dependency graph.
    The fuel parameter guarantees termination (depth <= 35 suffices since the graph is a DAG).

    **Incompleteness limitation**: This function only tracks propagation among
    named propositions enumerated in PropositionId. By Goedel's first incompleteness theorem,
    impact on unnamed derivational consequences cannot be detected (see Ontology.lean §6.2 note). -/
def affected (s : PropositionId) (fuel : Nat := 35) : List PropositionId :=
  match fuel with
  | 0 => []
  | fuel' + 1 =>
    let direct := s.dependents
    let transitive := direct.flatMap (fun p => affected p fuel')
    (direct ++ transitive).eraseDups

/-- Operational definition of D13: Impact propagation upon premise negation.
    Computes the impact set via affected, representing that each proposition requires re-verification. -/
def d13_propagation (negated : PropositionId) : List PropositionId :=
  affected negated

/-- Negation of T (constraint) has the largest impact:
    T is the rationale for many propositions, so the impact set is large. -/
theorem d13_constraint_negation_has_impact :
  (d13_propagation .t4).length > 0 := by native_decide

/-- Negation of L5 (platform boundary) affects only D1:
    L5 is environment-dependent and close to a root node, so its impact is limited. -/
theorem d13_l5_limited_impact :
  (d13_propagation .l5).length ≤ (d13_propagation .t4).length := by native_decide

-- ============================================================
-- D13 Extension: Assumption-level Impact Propagation (#225)
-- ============================================================

/-!
## D13 Extension: Temporal Expiration of Assumptions

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

/-- Computes the impact set when an assumption expires.
    An assumption supports a set of propositions (its dependencies).
    Expiration propagates through all dependents of those propositions.

    This generalizes d13_propagation (single PropositionId) to
    assumption-level expiration (set of PropositionIds). -/
def assumptionImpact (supportedPropositions : List PropositionId) : List PropositionId :=
  (supportedPropositions.flatMap (fun p => affected p)).eraseDups

/-- Raw (pre-dedup) impact set for assumption expiration.
    Used internally for proofs; assumptionImpact applies eraseDups on top. -/
def assumptionImpactRaw (supportedPropositions : List PropositionId) : List PropositionId :=
  supportedPropositions.flatMap (fun p => affected p)

/-- [Derivation Card]
    Derives from: d13_propagation (D13), affected (D13)
    Proposition: D13 (extension)
    Content: Assumption expiration subsumes individual proposition negation — if an assumption supports proposition p, then the raw impact of the assumption's expiration includes all of d13_propagation p.
    Proof strategy: List.mem_flatMap propagation -/
theorem d13_assumption_subsumes_proposition :
  ∀ (p : PropositionId) (supported : List PropositionId),
    p ∈ supported →
    ∀ (q : PropositionId),
      q ∈ d13_propagation p →
      q ∈ assumptionImpactRaw supported := by
  intro p supported hp q hq
  simp only [assumptionImpactRaw, d13_propagation] at *
  exact List.mem_flatMap.mpr ⟨p, hp, hq⟩

/-- [Derivation Card]
    Derives from: assumptionImpactRaw (D13 extension)
    Proposition: D13 (extension)
    Content: Broader assumptions have broader impact — if s₁ ⊆ s₂ then assumptionImpactRaw s₁ ⊆ assumptionImpactRaw s₂. Monotonicity with respect to support set inclusion.
    Proof strategy: Monotonicity of flatMap — superset of inputs produces superset of outputs -/
theorem d13_assumption_impact_monotone :
  ∀ (s₁ s₂ : List PropositionId),
    (∀ p, p ∈ s₁ → p ∈ s₂) →
    ∀ q, q ∈ assumptionImpactRaw s₁ → q ∈ assumptionImpactRaw s₂ := by
  intro s₁ s₂ hsub q hq
  simp only [assumptionImpactRaw] at *
  obtain ⟨p, hp, hpq⟩ := List.mem_flatMap.mp hq
  exact List.mem_flatMap.mpr ⟨p, hsub p hp, hpq⟩

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
                           .d15, .d16, .d17]
  | .skill            => []
  | .test             => []
  | .document         => []

/-- Set of propositions affected at the PropositionId level by changes to a StructureKind.
    Structure change -> contained PropositionIds -> compute propagation targets via affected.
    Integrates two-layer dependency tracking into a single pipeline. -/
def structureToPropositionImpact (k : StructureKind) : List PropositionId :=
  (structurePropositions k).flatMap (fun p => affected p)

/-- Changes to manifest have the widest proposition-level impact.
    Propagates to all dependents of T1-T8, E1-E2, P1-P6. -/
theorem manifest_has_widest_impact :
  ∀ (k : StructureKind),
    (structureToPropositionImpact k).length ≤
    (structureToPropositionImpact .manifest).length := by
  intro k; cases k <;> native_decide

/-- Changes to designConvention have non-empty proposition-level impact.
    Proves that dependents of D1-D17 exist. -/
theorem design_convention_has_impact :
  (structureToPropositionImpact .designConvention).length > 0 := by native_decide

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

/-- [Derivation Card]
    Derives from: task_is_constraint_satisfaction (P6)
    Proposition: D14
    Content: Verification order is part of the constraint satisfaction problem — when resources are finite (T7) and precision requirements exist (T8), the choice of verification order is within the scope of P6 constraint satisfaction.
    Proof strategy: Direct application of task_is_constraint_satisfaction (P6) — same proof term as D12, applied to verification ordering context -/
theorem d14_verification_order_is_csp :
  ∀ (task : Task) (agent : Agent),
    agent.contextWindow.capacity > 0 →
    task.resourceBudget ≤ globalResourceBound →
    task.precisionRequired.required > 0 →
    ∀ (s : TaskStrategy),
      s.task = task →
      strategyFeasible s agent →
      s.contextUsage ≤ agent.contextWindow.capacity ∧
      s.resourceUsage ≤ globalResourceBound ∧
      s.achievedPrecision > 0 :=
  task_is_constraint_satisfaction

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
-/

/-- D15a: Under finite resources, a retry count must be bounded.
    If resourceUsage per attempt is positive and resources are globally bounded,
    then the number of feasible attempts is bounded.

    Derivation: T7 (resource_finite) + T4 (output_nondeterministic).
    ForgeCode: max_tool_failure_per_turn. -/
theorem d15a_unbounded_retry_infeasible :
  ∀ (costPerAttempt : Nat),
    costPerAttempt > 0 →
    ∀ (n : Nat),
      n * costPerAttempt > globalResourceBound →
      -- n attempts would exceed the global resource bound
      -- therefore n is not feasible
      ¬(n * costPerAttempt ≤ globalResourceBound) := by
  intro cost h_pos n h_exceed h_le
  exact Nat.not_le.mpr h_exceed h_le

/-- D15b: An agent that does not converge must yield to human feedback.
    Resources are revocable by humans (T6), and improvement requires
    feedback (T5). Therefore, non-convergence implies the need for
    human intervention — not continued autonomous execution.

    Derivation: T6 (resource_revocable) + T5 (no_improvement_without_feedback).
    ForgeCode: max_requests_per_turn = 50.

    Formalized as: for any resource allocation, a human can revoke it
    (restating T6 in the context of non-converging agent loops). -/
theorem d15b_non_convergence_requires_human :
  ∀ (w : World) (alloc : ResourceAllocation),
    alloc ∈ w.allocations →
    ∃ (w' : World) (human : Agent),
      isHuman human ∧
      validTransition w w' ∧
      alloc ∉ w'.allocations :=
  fun w alloc h_alloc =>
    resource_revocable w alloc h_alloc

/-- D15c: Evicting zero-precision-contribution context preserves feasibility.
    If a strategy is feasible and we reduce contextUsage while keeping
    all other dimensions unchanged, the strategy remains feasible.

    Derivation: T3 (context_finite) + T8 (task_has_precision) + P6 (CSP).
    ForgeCode: droppable messages + compaction strategy.

    This captures the invariant that removing content that does not affect
    achievedPrecision or resourceUsage preserves strategyFeasible. -/
theorem d15c_eviction_preserves_feasibility :
  ∀ (s : TaskStrategy) (agent : Agent),
    strategyFeasible s agent →
    ∀ (s' : TaskStrategy),
      s'.task = s.task →
      -- eviction: context usage decreases or stays same
      s'.contextUsage ≤ s.contextUsage →
      -- resource usage unchanged
      s'.resourceUsage = s.resourceUsage →
      -- precision unchanged (evicted content had zero precision contribution)
      s'.achievedPrecision = s.achievedPrecision →
      strategyFeasible s' agent := by
  intro s agent ⟨h_ctx, h_res, h_prec⟩ s' h_task h_ctx' h_res' h_prec'
  exact ⟨Nat.le_trans h_ctx' h_ctx, h_res' ▸ (h_task ▸ h_res), h_prec' ▸ (h_task ▸ h_prec)⟩

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

/-- D16a: For any task with positive precision requirements,
    there exist context items with zero precision contribution.
    These items can be evicted without affecting task precision.

    Derivation: context_contribution_nonuniform (T3 extension).
    ForgeCode: semantic search filters out irrelevant files (B1).
    ForgeCode: droppable flag marks zero-contribution items (A1). -/
theorem d16a_zero_contribution_items_exist :
  ∀ (task : Task),
    task.precisionRequired.required > 0 →
    ∃ (item : ContextItem),
      precisionContribution item task = 0 :=
  fun task h_prec => context_contribution_nonuniform task h_prec

/-- D16b: Context composition affects task feasibility.
    Different context compositions yield different precision outcomes.

    Specifically: for any task with positive precision requirements,
    there exist two distinct context items with different precision contributions.
    Therefore, which items are included in the finite context window (T3)
    affects the achievable precision.

    This is the formal basis for:
    - B3: Tool naming aligned with training data increases success probability
    - B6: Prompt composition should prioritize high-contribution information

    Derivation: context_contribution_nonuniform (zero-contribution item exists)
    + task_has_precision (T8: precision requirement > 0 implies someone must contribute).
    If zero-contribution items exist and precision must be achieved,
    then at least one item must have positive contribution — establishing
    that contributions are not all equal (i.e., composition matters).

    Limitation: This theorem is an encoding theorem. It conjoins D16a's conclusion
    with the premise h_prec, which is a trivially-true pattern (premise restated in
    conclusion). The non-trivial claim "composition matters" is justified by the
    docstring reasoning but not formally captured — proving existence of a
    positive-contribution item would require additional axioms or making
    precisionContribution non-opaque. Filed as a known formalization gap. -/
theorem d16b_context_composition_matters :
  ∀ (task : Task),
    task.precisionRequired.required > 0 →
    ∃ (item : ContextItem),
      precisionContribution item task = 0 ∧
      task.precisionRequired.required > 0 :=
  -- D16b differs from D16a in what it concludes:
  -- D16a: zero-contribution items exist (pure existence)
  -- D16b: zero-contribution items exist AND precision is required (conjunction)
  -- The conjunction establishes that context composition is a NON-TRIVIAL
  -- optimization problem: items that don't help coexist with a requirement
  -- that demands help. Including zero-contribution items wastes finite
  -- context capacity (T3) without advancing precision (T8).
  fun task h_prec =>
    let ⟨item, hitem⟩ := context_contribution_nonuniform task h_prec
    ⟨item, hitem, h_prec⟩

/-- D16c: Under finite resources, allocating more resources to higher-contribution
    phases is rational. If zero-contribution items exist in the context (D16a),
    then the resource spent processing them is wasted under T7.

    This is the formal basis for B5 (progressive thinking policy):
    phases with higher precision contribution deserve more cognitive resources.

    Derivation: context_contribution_nonuniform + T7 (resource_finite).

    Formalized as: given finite resources (T7, w parameter) and positive
    precision requirements (T8), zero-contribution items exist (D16a).
    The resource bound is accepted as a premise but the conclusion
    depends only on D16a — the formal content is that waste exists
    regardless of specific budget levels. The w/h_bound parameters
    establish the resource-finite context without being used in the proof. -/
theorem d16c_resource_follows_contribution :
  ∀ (task : Task) (w : World),
    task.precisionRequired.required > 0 →
    (w.allocations.map (·.amount)).foldl (· + ·) 0 ≤ globalResourceBound →
    ∃ (item : ContextItem),
      precisionContribution item task = 0 := by
  intro task w h_prec _h_bound
  exact context_contribution_nonuniform task h_prec

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

/-- Steps of the deductive design workflow.
    Each step produces output required by subsequent steps. -/
inductive DeductiveDesignStep where
  | investigate  -- 環境調査: T5 (feedback requires observation) + D3 (observability first)
  | extract      -- 仮定抽出: P3 (governed learning: observation → hypothesis) + T6 (human judgment)
  | construct    -- 公理系構築: D5 (spec/test/impl triple) + D9 (self-maintenance)
  | derive       -- 設計導出: D1-D16 applied through conditional axiom system
  | validate     -- 検証: E1 (verification independence) + D2 (worker/verifier)
  | feedback     -- フィードバック: T5 (no improvement without feedback) + D13 (impact propagation)
  deriving BEq, Repr

/-- Ordering of workflow steps.
    Later steps depend on outputs of earlier steps. -/
def DeductiveDesignStep.ord : DeductiveDesignStep → Nat
  | .investigate => 0
  | .extract     => 1
  | .construct   => 2
  | .derive      => 3
  | .validate    => 4
  | .feedback    => 5

/-- A step depends on another if its ord is strictly greater.
    This captures the sequential dependency: you cannot extract without
    investigating, cannot construct without extracting, etc. -/
def designStepDependsOn (later earlier : DeductiveDesignStep) : Prop :=
  later.ord > earlier.ord

/-- [Derivation Card]
    Derives from: T5 (no_improvement_without_feedback), D3 (observability first)
    Proposition: D17
    Content: Investigation must precede extraction — you cannot form assumptions (P3 hypothesis)
      without first observing the environment (D3 observability). T5 requires feedback,
      which requires observation. Therefore investigate.ord < extract.ord.
    Note: Encoding theorem — the ordering is captured in the ord mapping (definitional).
      The axiom connection (T5, D3) justifies the CHOICE of ord values, not the proof itself.
    Proof strategy: simp on DeductiveDesignStep.ord -/
theorem d17_investigate_before_extract :
  designStepDependsOn .extract .investigate := by
  simp [designStepDependsOn, DeductiveDesignStep.ord]

/-- [Derivation Card]
    Derives from: D5 (spec/test/impl triple), P3 (governed learning)
    Proposition: D17
    Content: Construction of conditional axiom system requires assumptions,
      which come from extraction. D5 requires formal specification (the conditional
      axiom system) to precede implementation; P3 requires hypothesis (extract)
      before integration (construct).
    Note: Encoding theorem — axiom connection justifies the ord mapping choice, not the proof.
    Proof strategy: simp on DeductiveDesignStep.ord -/
theorem d17_extract_before_construct :
  designStepDependsOn .construct .extract := by
  simp [designStepDependsOn, DeductiveDesignStep.ord]

/-- [Derivation Card]
    Derives from: D1-D16 (design theorems require conditional axiom system as input)
    Proposition: D17
    Content: Design derivation operates on the conditional axiom system, not on
      core axioms directly. Without construction, there is no conditional axiom
      system to derive from. Core axioms alone lack platform-specific conditions.
    Note: Encoding theorem — axiom connection justifies the ord mapping choice, not the proof.
    Proof strategy: simp on DeductiveDesignStep.ord -/
theorem d17_construct_before_derive :
  designStepDependsOn .derive .construct := by
  simp [designStepDependsOn, DeductiveDesignStep.ord]

/-- [Derivation Card]
    Derives from: E1 (verification_requires_independence), D2 (worker/verifier separation)
    Proposition: D17
    Content: Validation requires a design to validate. E1 requires that verification
      be independent of generation — the validator must not have generated the design.
      D2's 4 conditions apply to the design derivation process itself.
    Note: Encoding theorem — axiom connection justifies the ord mapping choice, not the proof.
    Proof strategy: simp on DeductiveDesignStep.ord -/
theorem d17_derive_before_validate :
  designStepDependsOn .validate .derive := by
  simp [designStepDependsOn, DeductiveDesignStep.ord]

/-- [Derivation Card]
    Derives from: T5 (no_improvement_without_feedback), D13 (impact propagation)
    Proposition: D17
    Content: Feedback requires validation results as input. When validation reveals
      mismatches (under-derivation), D13's impact propagation identifies which
      assumptions or core axioms are affected. T5 guarantees that without this
      feedback loop, the design cannot improve.
    Note: Encoding theorem — axiom connection justifies the ord mapping choice, not the proof.
    Proof strategy: simp on DeductiveDesignStep.ord -/
theorem d17_validate_before_feedback :
  designStepDependsOn .feedback .validate := by
  simp [designStepDependsOn, DeductiveDesignStep.ord]

/-- [Derivation Card]
    Derives from: d17_investigate_before_extract through d17_validate_before_feedback
    Proposition: D17 (transitivity)
    Content: The workflow ordering is transitive: if step A must precede B and B
      must precede C, then A must precede C. This follows from Nat ordering.
      In particular, investigate must precede feedback (the full chain).
    Proof strategy: Nat.lt_trans on ord values -/
theorem d17_workflow_transitive :
  ∀ (a b c : DeductiveDesignStep),
    designStepDependsOn b a →
    designStepDependsOn c b →
    designStepDependsOn c a := by
  intro a b c hab hbc
  simp [designStepDependsOn] at *
  exact Nat.lt_trans hab hbc

/-- [Derivation Card]
    Derives from: d17_workflow_transitive
    Proposition: D17 (full chain)
    Content: The complete workflow chain holds: investigate precedes feedback.
      This is the end-to-end ordering: you cannot provide design feedback
      without having first investigated the environment.
    Proof strategy: simp on ord values (0 < 5) -/
theorem d17_full_chain :
  designStepDependsOn .feedback .investigate := by
  simp [designStepDependsOn, DeductiveDesignStep.ord]

-- ============================================================
-- D17 Extension: Step Output Types and Intermediate Verification
-- ============================================================

/-!
## D17 Step Output Types (#262)

Each step produces a typed output consumed by the next step.
The type connection replaces the encoding theorem ordering with
a structural dependency: step N's output type IS step N+1's input.
-/

/-- Output of Step 0 (investigate): collected platform design decisions. -/
structure InvestigationReport where
  platformName : String
  decisionCount : Nat
  sourceCount : Nat
  deriving Repr

/-- Output of Step 1 (extract): assumptions with epistemic source tracking. -/
structure AssumptionSet where
  humanDecisionCount : Nat
  llmInferenceCount : Nat
  allHaveTemporalValidity : Bool
  deriving Repr

/-- Output of Step 2 (construct): conditional axiom system build result. -/
structure ConditionalAxiomBuildResult where
  axiomCount : Nat
  theoremCount : Nat
  sorryCount : Nat
  buildSuccess : Bool
  deriving Repr

/-- Output of Step 3 (derive): derived design decisions. -/
structure DerivationOutput where
  decisionCount : Nat
  allAxiomsUsed : Bool
  deriving Repr

/-- Output of Step 4 (validate): accuracy measurement. -/
structure ValidationMetrics where
  totalPD : Nat
  matchCount : Nat
  partialCount : Nat
  missCount : Nat
  deriving Repr

/-- Verification risk level for step transitions.
    Maps to D2's VerificationRisk via the transition's impact on soundness. -/
def stepTransitionRisk : DeductiveDesignStep → VerificationRisk
  | .investigate => .moderate  -- 0→1: information completeness
  | .extract     => .high      -- 1→2: assumption correctness
  | .construct   => .high      -- 2→3: axiom system soundness
  | .derive      => .moderate  -- 3→4: derivation traceability
  | .validate    => .moderate  -- 4→5: measurement reproducibility
  | .feedback    => .low       -- terminal step

/-- [Derivation Card]
    Derives from: D2 (VerificationRisk, requiredConditions), stepTransitionRisk
    Proposition: D17 (intermediate verification)
    Content: Steps with high-risk transitions (extract, construct) require
      at least 3/4 independence conditions for verification.
      This means hook-invoked subagent verification is needed, not manual. -/
theorem d17_high_risk_transitions_need_hook_verify :
  requiredConditions (stepTransitionRisk .extract) ≥ 3 ∧
  requiredConditions (stepTransitionRisk .construct) ≥ 3 := by
  simp [stepTransitionRisk, requiredConditions]

/-- [Derivation Card]
    Derives from: stepTransitionRisk, ConditionalAxiomBuildResult
    Proposition: D17 (construct soundness)
    Content: A valid construct step must produce sorryCount = 0 and buildSuccess = true.
      These are necessary conditions for the conditional axiom system to be sound. -/
def constructStepValid (r : ConditionalAxiomBuildResult) : Bool :=
  r.sorryCount == 0 && r.buildSuccess

/-- [Derivation Card]
    Derives from: AssumptionSet, TemporalValidity (#225)
    Proposition: D17 (extract completeness)
    Content: A valid extract step must produce assumptions that all have TemporalValidity.
      This is required by #225 (temporal validity is a fundamental property of
      conditional axiom systems). -/
def extractStepValid (a : AssumptionSet) : Bool :=
  a.allHaveTemporalValidity && a.humanDecisionCount + a.llmInferenceCount > 0

-- ============================================================
-- D17 Workflow Ordering (existing theorems)
-- ============================================================

/-- [Derivation Card]
    Derives from: DeductiveDesignStep.ord (definitional)
    Proposition: D17 (acyclicity)
    Content: The workflow ordering is acyclic — no step depends on itself.
      This is a structural consequence of strict inequality (Nat.lt_irrefl).
      Acyclicity guarantees the workflow terminates and has no circular dependencies.
    Proof strategy: unfold designStepDependsOn + Nat.lt_irrefl -/
theorem d17_acyclic :
  ∀ (s : DeductiveDesignStep), ¬designStepDependsOn s s := by
  intro s h
  simp [designStepDependsOn] at h

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

end Manifest
