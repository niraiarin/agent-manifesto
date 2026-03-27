/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **safety_regulation** (ord=3): 飼料安全法・ペットフード安全法の法的基準。不変 [C1, C2]
- **nutrition_science** (ord=2): 動物栄養学の確立知見。AAFCO/FEDIAF 基準 [C4, C5, H1]
- **formulation** (ord=1): 原材料配合・コスト最適化のアルゴリズム的判断 [C6, C7, H4, H5]
- **hypothesis** (ord=0): 新素材・機能性成分の効果に関する未検証仮説 [H5, H6]
-/

namespace PetFoodFormulation

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | safe_ingredient
  | safe_contaminant
  | safe_labeling
  | nutr_protein
  | nutr_mineral
  | nutr_calorie
  | nutr_life_stage
  | form_ingredient_mix
  | form_cost_opt
  | form_palatability
  | form_shelf_life
  | form_label_gen
  | hyp_insect_protein
  | hyp_probiotic
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .safe_ingredient => []
  | .safe_contaminant => []
  | .safe_labeling => []
  | .nutr_protein => [.safe_ingredient]
  | .nutr_mineral => [.safe_contaminant]
  | .nutr_calorie => []
  | .nutr_life_stage => [.nutr_protein, .nutr_calorie]
  | .form_ingredient_mix => [.nutr_protein, .nutr_mineral]
  | .form_cost_opt => [.form_ingredient_mix]
  | .form_palatability => [.nutr_life_stage]
  | .form_shelf_life => [.safe_contaminant, .form_ingredient_mix]
  | .form_label_gen => [.safe_labeling, .form_ingredient_mix]
  | .hyp_insect_protein => [.nutr_protein]
  | .hyp_probiotic => [.nutr_life_stage, .form_palatability]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 飼料安全法・ペットフード安全法の法的基準。不変 (ord=3) -/
  | safety_regulation
  /-- 動物栄養学の確立知見。AAFCO/FEDIAF 基準 (ord=2) -/
  | nutrition_science
  /-- 原材料配合・コスト最適化のアルゴリズム的判断 (ord=1) -/
  | formulation
  /-- 新素材・機能性成分の効果に関する未検証仮説 (ord=0) -/
  | hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .safety_regulation => 3
  | .nutrition_science => 2
  | .formulation => 1
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
  nontrivial := ⟨.safety_regulation, .hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- safety_regulation
  | .safe_ingredient | .safe_contaminant | .safe_labeling => .safety_regulation
  -- nutrition_science
  | .nutr_protein | .nutr_mineral | .nutr_calorie | .nutr_life_stage => .nutrition_science
  -- formulation
  | .form_ingredient_mix | .form_cost_opt | .form_palatability | .form_shelf_life | .form_label_gen => .formulation
  -- hypothesis
  | .hyp_insect_protein | .hyp_probiotic => .hypothesis

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

end PetFoodFormulation
