/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **physicsLaw** (ord=4): 大気物理学の基本法則。熱力学・流体力学の原理 [C1]
- **observationalBasis** (ord=3): 気象観測ネットワークとデータ品質基準 [C2, H1]
- **forecastModel** (ord=2): 雹形成メカニズムに基づく予測モデル構造 [H2, H3]
- **warningPolicy** (ord=1): 警報発令基準と伝達プロトコル [C3, H4]
- **localCalibration** (ord=0): 地域特性に応じたモデルパラメータ較正 [H5]
-/

namespace TestScenario.S162

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | thermodynamicConstraint
  | updraftDynamics
  | radarReliability
  | soundingDataQuality
  | satelliteIntegration
  | hailNucleation
  | stormCellTracking
  | hailSizeEstimation
  | falseAlarmTolerance
  | leadTimeTarget
  | disseminationChannel
  | terrainAdjustment
  | cropVulnerability
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .thermodynamicConstraint => []
  | .updraftDynamics => []
  | .radarReliability => [.thermodynamicConstraint]
  | .soundingDataQuality => [.thermodynamicConstraint]
  | .satelliteIntegration => [.updraftDynamics]
  | .hailNucleation => [.thermodynamicConstraint, .updraftDynamics]
  | .stormCellTracking => [.radarReliability, .satelliteIntegration]
  | .hailSizeEstimation => [.hailNucleation, .soundingDataQuality]
  | .falseAlarmTolerance => [.hailSizeEstimation]
  | .leadTimeTarget => [.stormCellTracking, .falseAlarmTolerance]
  | .disseminationChannel => [.falseAlarmTolerance]
  | .terrainAdjustment => [.hailNucleation, .stormCellTracking]
  | .cropVulnerability => [.hailSizeEstimation, .terrainAdjustment]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 大気物理学の基本法則。熱力学・流体力学の原理 (ord=4) -/
  | physicsLaw
  /-- 気象観測ネットワークとデータ品質基準 (ord=3) -/
  | observationalBasis
  /-- 雹形成メカニズムに基づく予測モデル構造 (ord=2) -/
  | forecastModel
  /-- 警報発令基準と伝達プロトコル (ord=1) -/
  | warningPolicy
  /-- 地域特性に応じたモデルパラメータ較正 (ord=0) -/
  | localCalibration
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .physicsLaw => 4
  | .observationalBasis => 3
  | .forecastModel => 2
  | .warningPolicy => 1
  | .localCalibration => 0

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
  bottom := .localCalibration
  nontrivial := ⟨.physicsLaw, .localCalibration, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- physicsLaw
  | .thermodynamicConstraint | .updraftDynamics => .physicsLaw
  -- observationalBasis
  | .radarReliability | .soundingDataQuality | .satelliteIntegration => .observationalBasis
  -- forecastModel
  | .hailNucleation | .stormCellTracking | .hailSizeEstimation => .forecastModel
  -- warningPolicy
  | .falseAlarmTolerance | .leadTimeTarget | .disseminationChannel => .warningPolicy
  -- localCalibration
  | .terrainAdjustment | .cropVulnerability => .localCalibration

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

end TestScenario.S162
