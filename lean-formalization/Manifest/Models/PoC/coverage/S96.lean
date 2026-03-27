/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **constraint** (ord=3): 建築基準法・JIS規格に基づく不変前提。 [C1, C2]
- **empirical** (ord=2): 配合・養生データから得られた経験則。 [C3, H1]
- **design** (ord=1): 予測モデルの設計選択。 [C4, C5, H2]
- **hypothesis** (ord=0): 検証待ちの仮説。 [H3, H4]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | JISA_e88377
  | prop_b29279
  | prop_106776
  | prop_83e151
  | prop_9e3711
  | prop_56c679
  | prop_71ef35
  | prop_bf79fd
  | AIAbrams_56e217
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .JISA_e88377 => []
  | .prop_b29279 => []
  | .prop_106776 => []
  | .prop_83e151 => []
  | .prop_9e3711 => []
  | .prop_56c679 => []
  | .prop_71ef35 => []
  | .prop_bf79fd => []
  | .AIAbrams_56e217 => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 建築基準法・JIS規格に基づく不変前提。 (ord=3) -/
  | constraint
  /-- 配合・養生データから得られた経験則。 (ord=2) -/
  | empirical
  /-- 予測モデルの設計選択。 (ord=1) -/
  | design
  /-- 検証待ちの仮説。 (ord=0) -/
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
  | .JISA_e88377 | .prop_b29279 => .constraint
  -- empirical
  | .prop_106776 | .prop_56c679 => .empirical
  -- design
  | .prop_83e151 | .prop_9e3711 | .prop_71ef35 => .design
  -- hypothesis
  | .prop_bf79fd | .AIAbrams_56e217 => .hypothesis

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
