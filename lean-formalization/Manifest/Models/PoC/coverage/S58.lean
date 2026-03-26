/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **compliance** (ord=3): 法規制・プラットフォーム規約の不変条件 [C2, C3]
- **budget** (ord=2): ユーザーが設定する予算・上限制約 [C1, C4]
- **tactic** (ord=1): 入札タイミング・方式の運用方針 [C5, H2, H5]
- **prediction** (ord=0): AIが自律的に最適化する価格予測 [H1, H3, H4]
-/

namespace AuctionBidding

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | comp1
  | comp2
  | bud1
  | bud2
  | bud3
  | tac1
  | tac2
  | tac3
  | pred1
  | pred2
  | pred3
  | pred4
  | pred5
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .comp1 => []
  | .comp2 => []
  | .bud1 => [.comp2]
  | .bud2 => [.comp1]
  | .bud3 => []
  | .tac1 => [.comp1, .bud1]
  | .tac2 => [.comp2, .bud1]
  | .tac3 => [.bud3]
  | .pred1 => [.tac1]
  | .pred2 => [.bud2, .tac1]
  | .pred3 => [.tac2]
  | .pred4 => [.tac3]
  | .pred5 => [.bud2]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 法規制・プラットフォーム規約の不変条件 (ord=3) -/
  | compliance
  /-- ユーザーが設定する予算・上限制約 (ord=2) -/
  | budget
  /-- 入札タイミング・方式の運用方針 (ord=1) -/
  | tactic
  /-- AIが自律的に最適化する価格予測 (ord=0) -/
  | prediction
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .compliance => 3
  | .budget => 2
  | .tactic => 1
  | .prediction => 0

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
  bottom := .prediction
  nontrivial := ⟨.compliance, .prediction, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- compliance
  | .comp1 | .comp2 => .compliance
  -- budget
  | .bud1 | .bud2 | .bud3 => .budget
  -- tactic
  | .tac1 | .tac2 | .tac3 => .tactic
  -- prediction
  | .pred1 | .pred2 | .pred3 | .pred4 | .pred5 => .prediction

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

end AuctionBidding
