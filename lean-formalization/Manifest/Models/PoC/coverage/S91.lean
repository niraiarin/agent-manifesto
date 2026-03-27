/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **constraint** (ord=3): プロジェクトの不変前提。人間が覆さない限り変わらない。 [C1, C2]
- **empirical** (ord=2): データに基づく経験則。新データで更新されうる。 [C3, H1]
- **design** (ord=1): 設計上の選択。トレードオフに応じて変更可能。 [C4, C5, H2]
- **hypothesis** (ord=0): 未検証の仮説。運用を通じて検証が必要。 [H3, H4]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | prop_d37842
  | prop_0057e4
  | prop_0e9581
  | prop_242a52
  | prop_952f33
  | prop_7b261f
  | prop_42d964
  | prop_e2cddd
  | prop_3941a0
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .prop_d37842 => []
  | .prop_0057e4 => []
  | .prop_0e9581 => []
  | .prop_242a52 => []
  | .prop_952f33 => []
  | .prop_7b261f => []
  | .prop_42d964 => []
  | .prop_e2cddd => []
  | .prop_3941a0 => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- プロジェクトの不変前提。人間が覆さない限り変わらない。 (ord=3) -/
  | constraint
  /-- データに基づく経験則。新データで更新されうる。 (ord=2) -/
  | empirical
  /-- 設計上の選択。トレードオフに応じて変更可能。 (ord=1) -/
  | design
  /-- 未検証の仮説。運用を通じて検証が必要。 (ord=0) -/
  | hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .constraint => 3
  | .empirical => 2
  | .design => 1
  | .hypothesis => 0

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
  bottom := .hypothesis
  nontrivial := ⟨.constraint, .hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- constraint
  | .prop_d37842 | .prop_0057e4 | .prop_42d964 => .constraint
  -- empirical
  | .prop_0e9581 | .prop_952f33 => .empirical
  -- design
  | .prop_242a52 | .prop_7b261f => .design
  -- hypothesis
  | .prop_e2cddd | .prop_3941a0 => .hypothesis

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
