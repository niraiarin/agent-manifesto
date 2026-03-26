/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **FoodSafety** (ord=4): 食品衛生法・アレルゲン管理。違反不可 [C1]
- **QualityStandard** (ord=3): 食材品質基準。シェフの判断に基づく [C2, H1]
- **InventoryPolicy** (ord=2): 在庫回転・発注ルール。経営判断で調整可能 [C3, H2]
- **CostOptimization** (ord=1): コスト最適化・仕入れ先選定の効率化 [C4, H3]
-/

namespace TestCoverage.S6

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s6_p01
  | s6_p02
  | s6_p03
  | s6_p04
  | s6_p05
  | s6_p06
  | s6_p07
  | s6_p08
  | s6_p09
  | s6_p10
  | s6_p11
  | s6_p12
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s6_p01 => []
  | .s6_p02 => []
  | .s6_p03 => [.s6_p01]
  | .s6_p04 => [.s6_p02]
  | .s6_p05 => [.s6_p01, .s6_p02]
  | .s6_p06 => [.s6_p03]
  | .s6_p07 => [.s6_p04]
  | .s6_p08 => [.s6_p03, .s6_p05]
  | .s6_p09 => [.s6_p06]
  | .s6_p10 => [.s6_p07]
  | .s6_p11 => [.s6_p08]
  | .s6_p12 => [.s6_p09, .s6_p10]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 食品衛生法・アレルゲン管理。違反不可 (ord=4) -/
  | FoodSafety
  /-- 食材品質基準。シェフの判断に基づく (ord=3) -/
  | QualityStandard
  /-- 在庫回転・発注ルール。経営判断で調整可能 (ord=2) -/
  | InventoryPolicy
  /-- コスト最適化・仕入れ先選定の効率化 (ord=1) -/
  | CostOptimization
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .FoodSafety => 4
  | .QualityStandard => 3
  | .InventoryPolicy => 2
  | .CostOptimization => 1

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
  bottom := .CostOptimization
  nontrivial := ⟨.FoodSafety, .CostOptimization, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- FoodSafety
  | .s6_p01 | .s6_p02 => .FoodSafety
  -- QualityStandard
  | .s6_p03 | .s6_p04 | .s6_p05 => .QualityStandard
  -- InventoryPolicy
  | .s6_p06 | .s6_p07 | .s6_p08 => .InventoryPolicy
  -- CostOptimization
  | .s6_p09 | .s6_p10 | .s6_p11 | .s6_p12 => .CostOptimization

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

end TestCoverage.S6
