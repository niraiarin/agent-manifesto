/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **FoodSafetyLaw** (ord=4): 食品衛生法・消費期限の法的規制。違反不可 [C1, C2]
- **SupplyChainRule** (ord=3): サプライチェーンの確立された商慣行 [C3, C4]
- **DemandForecast** (ord=2): 需要予測モデルと在庫管理ルール [C5, H1, H2]
- **WasteReductionHypothesis** (ord=1): 廃棄削減効果に関する未検証仮説 [C6, H3, H4]
-/

namespace TestCoverage.S105

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s105_p01
  | s105_p02
  | s105_p03
  | s105_p04
  | s105_p05
  | s105_p06
  | s105_p07
  | s105_p08
  | s105_p09
  | s105_p10
  | s105_p11
  | s105_p12
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s105_p01 => []
  | .s105_p02 => []
  | .s105_p03 => [.s105_p01]
  | .s105_p04 => [.s105_p01, .s105_p02]
  | .s105_p05 => [.s105_p02]
  | .s105_p06 => [.s105_p03]
  | .s105_p07 => [.s105_p04]
  | .s105_p08 => [.s105_p03, .s105_p05]
  | .s105_p09 => [.s105_p06]
  | .s105_p10 => [.s105_p07]
  | .s105_p11 => [.s105_p08]
  | .s105_p12 => [.s105_p09, .s105_p10]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 食品衛生法・消費期限の法的規制。違反不可 (ord=4) -/
  | FoodSafetyLaw
  /-- サプライチェーンの確立された商慣行 (ord=3) -/
  | SupplyChainRule
  /-- 需要予測モデルと在庫管理ルール (ord=2) -/
  | DemandForecast
  /-- 廃棄削減効果に関する未検証仮説 (ord=1) -/
  | WasteReductionHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .FoodSafetyLaw => 4
  | .SupplyChainRule => 3
  | .DemandForecast => 2
  | .WasteReductionHypothesis => 1

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
  bottom := .WasteReductionHypothesis
  nontrivial := ⟨.FoodSafetyLaw, .WasteReductionHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- FoodSafetyLaw
  | .s105_p01 | .s105_p02 => .FoodSafetyLaw
  -- SupplyChainRule
  | .s105_p03 | .s105_p04 | .s105_p05 => .SupplyChainRule
  -- DemandForecast
  | .s105_p06 | .s105_p07 | .s105_p08 => .DemandForecast
  -- WasteReductionHypothesis
  | .s105_p09 | .s105_p10 | .s105_p11 | .s105_p12 => .WasteReductionHypothesis

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

end TestCoverage.S105
