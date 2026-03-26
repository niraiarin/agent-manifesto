/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **core_constraint** (ord=4): システムの存在意義に関わる不変前提 [C1, C2]
- **quality_postulate** (ord=3): 品質・正確性に関する経験的仮定 [C3, H1]
- **operational_rule** (ord=2): 運用上の制約・ルール [C4, H2]
- **design_choice** (ord=1): 実装上の設計判断 [H3, H4]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | prop_8eabe0
  | prop_84540b
  | prop_f2d035
  | prop_1828e0
  | prop_e0e735
  | Markdown_528f8f
  | prop_dc3a9f
  | prop_7da1da
  | prop_8e5115
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .prop_8eabe0 => []
  | .prop_84540b => []
  | .prop_f2d035 => []
  | .prop_1828e0 => []
  | .prop_e0e735 => []
  | .Markdown_528f8f => []
  | .prop_dc3a9f => []
  | .prop_7da1da => []
  | .prop_8e5115 => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- システムの存在意義に関わる不変前提 (ord=4) -/
  | core_constraint
  /-- 品質・正確性に関する経験的仮定 (ord=3) -/
  | quality_postulate
  /-- 運用上の制約・ルール (ord=2) -/
  | operational_rule
  /-- 実装上の設計判断 (ord=1) -/
  | design_choice
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .core_constraint => 4
  | .quality_postulate => 3
  | .operational_rule => 2
  | .design_choice => 1

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
  bottom := .design_choice
  nontrivial := ⟨.core_constraint, .design_choice, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- core_constraint
  | .prop_8eabe0 | .prop_84540b | .prop_e0e735 => .core_constraint
  -- quality_postulate
  | .prop_f2d035 | .prop_8e5115 => .quality_postulate
  -- operational_rule
  | .prop_1828e0 | .prop_7da1da => .operational_rule
  -- design_choice
  | .Markdown_528f8f | .prop_dc3a9f => .design_choice

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
