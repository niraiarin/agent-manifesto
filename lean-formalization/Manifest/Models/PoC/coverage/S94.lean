/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **constraint** (ord=3): 法規・物理法則に基づく不変前提。 [C1, C2]
- **empirical** (ord=2): 落雷データ・設置実績から得られた経験則。 [C3, H1]
- **design** (ord=1): 最適化アルゴリズムの設計選択。 [C4, C5, H2]
- **hypothesis** (ord=0): 検証待ちの最適化仮説。 [H3, H4]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | JISA_6d68d3
  | prop_49da32
  | prop_0a29be
  | D_0bad48
  | CAD_7a2f0f
  | prop_5494bb
  | prop_36f27d
  | prop_3a8ed2
  | prop_6c1a7d
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .JISA_6d68d3 => []
  | .prop_49da32 => []
  | .prop_0a29be => []
  | .D_0bad48 => []
  | .CAD_7a2f0f => []
  | .prop_5494bb => []
  | .prop_36f27d => []
  | .prop_3a8ed2 => []
  | .prop_6c1a7d => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 法規・物理法則に基づく不変前提。 (ord=3) -/
  | constraint
  /-- 落雷データ・設置実績から得られた経験則。 (ord=2) -/
  | empirical
  /-- 最適化アルゴリズムの設計選択。 (ord=1) -/
  | design
  /-- 検証待ちの最適化仮説。 (ord=0) -/
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
  | .JISA_6d68d3 | .prop_49da32 => .constraint
  -- empirical
  | .prop_0a29be | .prop_5494bb => .empirical
  -- design
  | .D_0bad48 | .CAD_7a2f0f | .prop_36f27d => .design
  -- hypothesis
  | .prop_3a8ed2 | .prop_6c1a7d => .hypothesis

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
