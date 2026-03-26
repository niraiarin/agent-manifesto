/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **constraint** (ord=2): 古物営業法・消費者契約法に基づく不変条件 [C1, C2, C3]
- **market** (ord=1): 中古車市場・車両状態の前提と運用方針 [C4, H1, H2, H3]
- **hypothesis** (ord=0): 未検証の査定精度・価格予測仮説 [H4, H5, H6]
-/

namespace UsedCarAppraisal

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | safe1
  | safe2
  | safe3
  | mkt1
  | mkt2
  | mkt3
  | mkt4
  | mkt5
  | hyp1
  | hyp2
  | hyp3
  | hyp4
  | hyp5
  | hyp6
  | hyp7
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .safe1 => []
  | .safe2 => []
  | .safe3 => []
  | .mkt1 => []
  | .mkt2 => [.safe1]
  | .mkt3 => [.safe2]
  | .mkt4 => [.safe3, .mkt1]
  | .mkt5 => [.mkt1, .mkt2]
  | .hyp1 => [.mkt1, .mkt2]
  | .hyp2 => [.mkt3, .mkt4]
  | .hyp3 => [.mkt5]
  | .hyp4 => [.hyp1, .hyp2]
  | .hyp5 => [.hyp1, .hyp3]
  | .hyp6 => [.hyp4]
  | .hyp7 => [.hyp5, .hyp6]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 古物営業法・消費者契約法に基づく不変条件 (ord=2) -/
  | constraint
  /-- 中古車市場・車両状態の前提と運用方針 (ord=1) -/
  | market
  /-- 未検証の査定精度・価格予測仮説 (ord=0) -/
  | hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .constraint => 2
  | .market => 1
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
  ord_bounded := ⟨2, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- constraint
  | .safe1 | .safe2 | .safe3 => .constraint
  -- market
  | .mkt1 | .mkt2 | .mkt3 | .mkt4 | .mkt5 => .market
  -- hypothesis
  | .hyp1 | .hyp2 | .hyp3 | .hyp4 | .hyp5 | .hyp6 | .hyp7 => .hypothesis

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

end UsedCarAppraisal
