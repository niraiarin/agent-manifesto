/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **constraint** (ord=3): 動物福祉・訓練基準の不変前提。 [C1, C2, C3]
- **empirical** (ord=2): 訓練データ・行動科学の経験則。 [C4, H1, H2]
- **design** (ord=1): AIシステムの設計選択。 [C5, C6, H3]
- **hypothesis** (ord=0): 検証待ちの仮説。 [H4, H5]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | prop_4dd613
  | prop_715752
  | IGDF_1f4518
  | prop_1a98cd
  | prop_bab487
  | prop_9a3a66
  | prop_d403ff
  | prop_26b812
  | AI_6a3450
  | prop_7fe0ca
  | prop_70ef5f
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .prop_4dd613 => []
  | .prop_715752 => []
  | .IGDF_1f4518 => []
  | .prop_1a98cd => []
  | .prop_bab487 => []
  | .prop_9a3a66 => []
  | .prop_d403ff => []
  | .prop_26b812 => []
  | .AI_6a3450 => []
  | .prop_7fe0ca => []
  | .prop_70ef5f => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 動物福祉・訓練基準の不変前提。 (ord=3) -/
  | constraint
  /-- 訓練データ・行動科学の経験則。 (ord=2) -/
  | empirical
  /-- AIシステムの設計選択。 (ord=1) -/
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
  | .prop_4dd613 | .prop_715752 | .IGDF_1f4518 | .prop_70ef5f => .constraint
  -- empirical
  | .prop_1a98cd | .prop_bab487 => .empirical
  -- design
  | .prop_9a3a66 | .prop_d403ff | .prop_7fe0ca => .design
  -- hypothesis
  | .prop_26b812 | .AI_6a3450 => .hypothesis

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
