/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **safety_constraint** (ord=4): 食品安全・アレルギー・宗教的食事制限の不変制約 [C1, C2]
- **nutrition_postulate** (ord=3): 栄養学的な前提（推奨摂取量・栄養バランス） [C3, H1]
- **recipe_principle** (ord=2): レシピ生成の原則（実現可能性・味の整合性・季節性） [C4, C5, H2]
- **presentation_design** (ord=1): レシピの表示・手順説明の設計判断 [H3, H4, H5]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | prop_98e98c
  | prop_6cd4be
  | prop_d8ae0a
  | PFC_593d24
  | prop_3f74f5
  | prop_069bf0
  | prop_c3fc9b
  | prop_a32ea3
  | prop_729537
  | prop_121b78
  | prop_b174b3
  | prop_e076af
  | AI_f777cc
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .prop_98e98c => []
  | .prop_6cd4be => []
  | .prop_d8ae0a => []
  | .PFC_593d24 => []
  | .prop_3f74f5 => []
  | .prop_069bf0 => []
  | .prop_c3fc9b => []
  | .prop_a32ea3 => []
  | .prop_729537 => []
  | .prop_121b78 => []
  | .prop_b174b3 => []
  | .prop_e076af => []
  | .AI_f777cc => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 食品安全・アレルギー・宗教的食事制限の不変制約 (ord=4) -/
  | safety_constraint
  /-- 栄養学的な前提（推奨摂取量・栄養バランス） (ord=3) -/
  | nutrition_postulate
  /-- レシピ生成の原則（実現可能性・味の整合性・季節性） (ord=2) -/
  | recipe_principle
  /-- レシピの表示・手順説明の設計判断 (ord=1) -/
  | presentation_design
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .safety_constraint => 4
  | .nutrition_postulate => 3
  | .recipe_principle => 2
  | .presentation_design => 1

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
  bottom := .presentation_design
  nontrivial := ⟨.safety_constraint, .presentation_design, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- safety_constraint
  | .prop_98e98c | .prop_6cd4be | .prop_d8ae0a => .safety_constraint
  -- nutrition_postulate
  | .PFC_593d24 | .prop_3f74f5 | .prop_069bf0 => .nutrition_postulate
  -- recipe_principle
  | .prop_c3fc9b | .prop_a32ea3 | .prop_729537 => .recipe_principle
  -- presentation_design
  | .prop_121b78 | .prop_b174b3 | .prop_e076af | .AI_f777cc => .presentation_design

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
