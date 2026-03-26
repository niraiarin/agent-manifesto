/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **constraint** (ord=4): 軌道力学・宇宙法の不変前提。 [C1, C2, C3]
- **empirical** (ord=3): 追跡データ・衝突統計から得られた経験則。 [C4, H1]
- **principle** (ord=2): 運用ポリシー・意思決定基準。 [C5, C6, H2]
- **design** (ord=1): 回避アルゴリズムの設計選択。 [H3, H4]
- **hypothesis** (ord=0): 検証待ちの技術仮説。 [H5]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | prop_504ed7
  | prop_f5d4b6
  | OST_837bea
  | TLE_58e965
  | prop_b75fc4
  | prop_f67d42
  | prop_ae58dc
  | prop_2780aa
  | prop_0cce41
  | AI_b6b1d9
  | prop_65502e
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .prop_504ed7 => []
  | .prop_f5d4b6 => []
  | .OST_837bea => []
  | .TLE_58e965 => []
  | .prop_b75fc4 => []
  | .prop_f67d42 => []
  | .prop_ae58dc => []
  | .prop_2780aa => []
  | .prop_0cce41 => []
  | .AI_b6b1d9 => []
  | .prop_65502e => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 軌道力学・宇宙法の不変前提。 (ord=4) -/
  | constraint
  /-- 追跡データ・衝突統計から得られた経験則。 (ord=3) -/
  | empirical
  /-- 運用ポリシー・意思決定基準。 (ord=2) -/
  | principle
  /-- 回避アルゴリズムの設計選択。 (ord=1) -/
  | design
  /-- 検証待ちの技術仮説。 (ord=0) -/
  | hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .constraint => 4
  | .empirical => 3
  | .principle => 2
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
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- constraint
  | .prop_504ed7 | .prop_f5d4b6 | .OST_837bea => .constraint
  -- empirical
  | .TLE_58e965 | .prop_b75fc4 => .empirical
  -- principle
  | .prop_f67d42 | .prop_ae58dc | .prop_65502e => .principle
  -- design
  | .prop_2780aa | .prop_0cce41 => .design
  -- hypothesis
  | .AI_b6b1d9 => .hypothesis

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
