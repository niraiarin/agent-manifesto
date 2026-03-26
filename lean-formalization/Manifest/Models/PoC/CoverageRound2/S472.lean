/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **StorageRequirementInvariant** (ord=3): 法定備蓄基準・賞味期限管理・保管環境の絶対条件 [C1, C2]
- **RotationAndReplenishPolicy** (ord=2): 先入れ先出し・定期ローテーション・自動発注のポリシー [C3, C4, H1]
- **DemandForecastHypothesis** (ord=1): 災害発生時の消費予測と備蓄量最適化に関する推論仮説 [H2, H3, H4, H5]
-/

namespace TestCoverage.S472

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s472_p01
  | s472_p02
  | s472_p03
  | s472_p04
  | s472_p05
  | s472_p06
  | s472_p07
  | s472_p08
  | s472_p09
  | s472_p10
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s472_p01 => []
  | .s472_p02 => []
  | .s472_p03 => [.s472_p01, .s472_p02]
  | .s472_p04 => [.s472_p01]
  | .s472_p05 => [.s472_p02]
  | .s472_p06 => [.s472_p03, .s472_p04]
  | .s472_p07 => [.s472_p04]
  | .s472_p08 => [.s472_p05]
  | .s472_p09 => [.s472_p06, .s472_p07]
  | .s472_p10 => [.s472_p08, .s472_p09]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 法定備蓄基準・賞味期限管理・保管環境の絶対条件 (ord=3) -/
  | StorageRequirementInvariant
  /-- 先入れ先出し・定期ローテーション・自動発注のポリシー (ord=2) -/
  | RotationAndReplenishPolicy
  /-- 災害発生時の消費予測と備蓄量最適化に関する推論仮説 (ord=1) -/
  | DemandForecastHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .StorageRequirementInvariant => 3
  | .RotationAndReplenishPolicy => 2
  | .DemandForecastHypothesis => 1

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
  bottom := .DemandForecastHypothesis
  nontrivial := ⟨.StorageRequirementInvariant, .DemandForecastHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- StorageRequirementInvariant
  | .s472_p01 | .s472_p02 | .s472_p03 => .StorageRequirementInvariant
  -- RotationAndReplenishPolicy
  | .s472_p04 | .s472_p05 | .s472_p06 => .RotationAndReplenishPolicy
  -- DemandForecastHypothesis
  | .s472_p07 | .s472_p08 | .s472_p09 | .s472_p10 => .DemandForecastHypothesis

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

end TestCoverage.S472
