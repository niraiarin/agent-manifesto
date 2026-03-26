/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **EnvironmentalInvariant** (ord=3): 生態系保護・騒音規制・景観条例への適合の絶対不変条件 [C1, C2, C3]
- **EnergyPolicy** (ord=2): 発電効率目標・系統安定化・メンテナンス計画の方針 [C4, C5, H1, H2, H3]
- **OptimizationHypothesis** (ord=1): 風況予測・タービン間干渉・土地利用効率に関する推論仮説 [C6, H4, H5, H6]
-/

namespace TestCoverage.S347

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s347_p01
  | s347_p02
  | s347_p03
  | s347_p04
  | s347_p05
  | s347_p06
  | s347_p07
  | s347_p08
  | s347_p09
  | s347_p10
  | s347_p11
  | s347_p12
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s347_p01 => []
  | .s347_p02 => []
  | .s347_p03 => [.s347_p01, .s347_p02]
  | .s347_p04 => [.s347_p01]
  | .s347_p05 => [.s347_p02]
  | .s347_p06 => [.s347_p03, .s347_p04]
  | .s347_p07 => [.s347_p05]
  | .s347_p08 => [.s347_p04]
  | .s347_p09 => [.s347_p05]
  | .s347_p10 => [.s347_p06, .s347_p08]
  | .s347_p11 => [.s347_p07, .s347_p09]
  | .s347_p12 => [.s347_p10, .s347_p11]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 生態系保護・騒音規制・景観条例への適合の絶対不変条件 (ord=3) -/
  | EnvironmentalInvariant
  /-- 発電効率目標・系統安定化・メンテナンス計画の方針 (ord=2) -/
  | EnergyPolicy
  /-- 風況予測・タービン間干渉・土地利用効率に関する推論仮説 (ord=1) -/
  | OptimizationHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .EnvironmentalInvariant => 3
  | .EnergyPolicy => 2
  | .OptimizationHypothesis => 1

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
  bottom := .OptimizationHypothesis
  nontrivial := ⟨.EnvironmentalInvariant, .OptimizationHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- EnvironmentalInvariant
  | .s347_p01 | .s347_p02 | .s347_p03 => .EnvironmentalInvariant
  -- EnergyPolicy
  | .s347_p04 | .s347_p05 | .s347_p06 | .s347_p07 => .EnergyPolicy
  -- OptimizationHypothesis
  | .s347_p08 | .s347_p09 | .s347_p10 | .s347_p11 | .s347_p12 => .OptimizationHypothesis

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

end TestCoverage.S347
