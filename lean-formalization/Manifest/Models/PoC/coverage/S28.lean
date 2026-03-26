/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **physical_law_constraint** (ord=5): 大気物理の基本法則。熱力学・流体力学は不変 [C1]
- **observational_postulate** (ord=4): 観測データの前提。観測網とデータ品質 [C2, C3, H1]
- **modeling_principle** (ord=3): 数値モデリングの原則。解像度とパラメタリゼーション [C4, H2, H3]
- **verification_boundary** (ord=2): 検証の境界条件。精度評価の枠組み [C5, H4]
- **tuning_hypothesis** (ord=0): チューニングの仮説。実験で調整 [H5, H6]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | navier_stokes_basis
  | thermodynamic_consistency
  | observation_network_coverage
  | satellite_data_quality
  | grid_resolution_target
  | convection_parameterization
  | forecast_skill_score
  | ensemble_spread_calibration
  | ml_postprocessing_weight
  | data_assimilation_cycle
  | boundary_condition_update
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .navier_stokes_basis => []
  | .thermodynamic_consistency => []
  | .observation_network_coverage => []
  | .satellite_data_quality => []
  | .grid_resolution_target => []
  | .convection_parameterization => []
  | .forecast_skill_score => []
  | .ensemble_spread_calibration => []
  | .ml_postprocessing_weight => []
  | .data_assimilation_cycle => []
  | .boundary_condition_update => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 大気物理の基本法則。熱力学・流体力学は不変 (ord=5) -/
  | physical_law_constraint
  /-- 観測データの前提。観測網とデータ品質 (ord=4) -/
  | observational_postulate
  /-- 数値モデリングの原則。解像度とパラメタリゼーション (ord=3) -/
  | modeling_principle
  /-- 検証の境界条件。精度評価の枠組み (ord=2) -/
  | verification_boundary
  /-- チューニングの仮説。実験で調整 (ord=0) -/
  | tuning_hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .physical_law_constraint => 5
  | .observational_postulate => 4
  | .modeling_principle => 3
  | .verification_boundary => 2
  | .tuning_hypothesis => 0

/-- 認識論的層構造の typeclass（スタンドアロン版）。 -/
class EpistemicLayerClass (α : Type) where
  ord : α → Nat
  bottom : α
  nontrivial : ∃ (a b : α), ord a ≠ ord b
  ord_injective : ∀ (a b : α), ord a = ord b → a = b
  ord_bounded : ∃ (n : Nat), ∀ (a : α), ord a ≤ n
  bottom_minimum : ∀ (a : α), ord bottom ≤ ord a

instance : EpistemicLayerClass ConcreteLayer where
  ord := ConcreteLayer.ord
  bottom := .tuning_hypothesis
  nontrivial := ⟨.physical_law_constraint, .tuning_hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- physical_law_constraint
  | .navier_stokes_basis | .thermodynamic_consistency => .physical_law_constraint
  -- observational_postulate
  | .observation_network_coverage | .satellite_data_quality | .data_assimilation_cycle => .observational_postulate
  -- modeling_principle
  | .grid_resolution_target | .convection_parameterization | .boundary_condition_update => .modeling_principle
  -- verification_boundary
  | .forecast_skill_score => .verification_boundary
  -- tuning_hypothesis
  | .ensemble_spread_calibration | .ml_postprocessing_weight => .tuning_hypothesis

-- ============================================================
-- 4. 証明
-- ============================================================

/-- classify は依存関係の単調性を尊重する。 -/
theorem classify_monotone :
    ∀ (a b : PropositionId),
      propositionDependsOn a b = true →
      ConcreteLayer.ord (classify b) ≥ ConcreteLayer.ord (classify a) := by
  intro a b h; cases a <;> cases b <;> revert h <;> native_decide

/-- classify は全域関数。 -/
theorem classify_total :
    ∀ (p : PropositionId), ∃ (l : ConcreteLayer), classify p = l :=
  fun p => ⟨classify p, rfl⟩

end Manifest.Models
