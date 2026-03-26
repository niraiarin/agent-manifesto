/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **regulation** (ord=5): 保険業法・金融規制の法的義務 [C1, C2]
- **actuarial** (ord=4): 保険数理の前提・リスクモデル [H1, H2]
- **product_design** (ord=3): 保険商品設計の構造的制約 [C3, H3]
- **underwriting** (ord=2): 査定担当者が設定する引受基準 [C4, C5]
- **scoring** (ord=1): AIが算出するリスクスコア・査定推奨 [H4, H5]
-/

namespace TestCoverage.S15

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | reg1
  | reg2
  | act1
  | act2
  | pd1
  | pd2
  | uw1
  | uw2
  | uw3
  | sc1
  | sc2
  | sc3
  | sc4
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .reg1 => []
  | .reg2 => []
  | .act1 => []
  | .act2 => [.reg1]
  | .pd1 => [.reg1, .act1]
  | .pd2 => [.reg2, .act2]
  | .uw1 => [.pd1]
  | .uw2 => [.pd2, .act1]
  | .uw3 => [.reg2]
  | .sc1 => [.uw1, .act1]
  | .sc2 => [.uw2]
  | .sc3 => [.uw3, .pd1]
  | .sc4 => [.sc1]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 保険業法・金融規制の法的義務 (ord=5) -/
  | regulation
  /-- 保険数理の前提・リスクモデル (ord=4) -/
  | actuarial
  /-- 保険商品設計の構造的制約 (ord=3) -/
  | product_design
  /-- 査定担当者が設定する引受基準 (ord=2) -/
  | underwriting
  /-- AIが算出するリスクスコア・査定推奨 (ord=1) -/
  | scoring
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .regulation => 5
  | .actuarial => 4
  | .product_design => 3
  | .underwriting => 2
  | .scoring => 1

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
  bottom := .scoring
  nontrivial := ⟨.regulation, .scoring, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- regulation
  | .reg1 | .reg2 => .regulation
  -- actuarial
  | .act1 | .act2 => .actuarial
  -- product_design
  | .pd1 | .pd2 => .product_design
  -- underwriting
  | .uw1 | .uw2 | .uw3 => .underwriting
  -- scoring
  | .sc1 | .sc2 | .sc3 | .sc4 => .scoring

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

end TestCoverage.S15
