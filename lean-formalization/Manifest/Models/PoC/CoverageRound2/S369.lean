/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **OccupantWellbeing** (ord=3): 居住者の健康・快適性・安全に関する不変条件 [C1, C2]
- **EnergyRegulationPolicy** (ord=2): 省エネ法・建築環境基準・CO2排出規制への適合方針 [C3, C4, H1, H2]
- **EnvironmentControlHypothesis** (ord=1): 温湿度・CO2・照度・気流の制御最適化推論仮説 [H3, H4, H5, H6]
-/

namespace TestCoverage.S369

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s369_p01
  | s369_p02
  | s369_p03
  | s369_p04
  | s369_p05
  | s369_p06
  | s369_p07
  | s369_p08
  | s369_p09
  | s369_p10
  | s369_p11
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s369_p01 => []
  | .s369_p02 => [.s369_p01]
  | .s369_p03 => [.s369_p01]
  | .s369_p04 => [.s369_p02]
  | .s369_p05 => [.s369_p03, .s369_p04]
  | .s369_p06 => [.s369_p03]
  | .s369_p07 => [.s369_p04]
  | .s369_p08 => [.s369_p05, .s369_p06]
  | .s369_p09 => [.s369_p07]
  | .s369_p10 => [.s369_p08, .s369_p09]
  | .s369_p11 => [.s369_p02, .s369_p10]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 居住者の健康・快適性・安全に関する不変条件 (ord=3) -/
  | OccupantWellbeing
  /-- 省エネ法・建築環境基準・CO2排出規制への適合方針 (ord=2) -/
  | EnergyRegulationPolicy
  /-- 温湿度・CO2・照度・気流の制御最適化推論仮説 (ord=1) -/
  | EnvironmentControlHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .OccupantWellbeing => 3
  | .EnergyRegulationPolicy => 2
  | .EnvironmentControlHypothesis => 1

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
  bottom := .EnvironmentControlHypothesis
  nontrivial := ⟨.OccupantWellbeing, .EnvironmentControlHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- OccupantWellbeing
  | .s369_p01 | .s369_p02 => .OccupantWellbeing
  -- EnergyRegulationPolicy
  | .s369_p03 | .s369_p04 | .s369_p05 => .EnergyRegulationPolicy
  -- EnvironmentControlHypothesis
  | .s369_p06 | .s369_p07 | .s369_p08 | .s369_p09 | .s369_p10 | .s369_p11 => .EnvironmentControlHypothesis

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

end TestCoverage.S369
