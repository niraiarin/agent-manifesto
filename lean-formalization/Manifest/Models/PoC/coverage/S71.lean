/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **biomedical_constraint** (ord=4): 医学的・遺伝学的に確立された事実と倫理基準 [C1, C2, C5]
- **analysis_postulate** (ord=3): 解析手法の前提となる統計的・生物学的仮定 [C3, H1]
- **reporting_principle** (ord=2): レポート生成の原則（可読性・正確性・情報量のバランス） [C4, C6, H2]
- **presentation_design** (ord=1): UI/可視化・表現レベルの設計判断 [H3, H4, H5]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | prop_eee714
  | prop_ef1fe6
  | ClinVarACM_7cdc4b
  | VUS_5b7e00
  | prop_818f8c
  | prop_8162c9
  | prop_f395ad
  | prop_c01f50
  | prop_a2ac40
  | prop_a41f63
  | prop_8bf11f
  | IGV_119541
  | PDFA_5ba337
  | prop_85c0a2
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .prop_eee714 => []
  | .prop_ef1fe6 => []
  | .ClinVarACM_7cdc4b => []
  | .VUS_5b7e00 => []
  | .prop_818f8c => []
  | .prop_8162c9 => []
  | .prop_f395ad => []
  | .prop_c01f50 => []
  | .prop_a2ac40 => []
  | .prop_a41f63 => []
  | .prop_8bf11f => []
  | .IGV_119541 => []
  | .PDFA_5ba337 => []
  | .prop_85c0a2 => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 医学的・遺伝学的に確立された事実と倫理基準 (ord=4) -/
  | biomedical_constraint
  /-- 解析手法の前提となる統計的・生物学的仮定 (ord=3) -/
  | analysis_postulate
  /-- レポート生成の原則（可読性・正確性・情報量のバランス） (ord=2) -/
  | reporting_principle
  /-- UI/可視化・表現レベルの設計判断 (ord=1) -/
  | presentation_design
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .biomedical_constraint => 4
  | .analysis_postulate => 3
  | .reporting_principle => 2
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
  nontrivial := ⟨.biomedical_constraint, .presentation_design, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- biomedical_constraint
  | .prop_eee714 | .prop_ef1fe6 | .ClinVarACM_7cdc4b | .VUS_5b7e00 => .biomedical_constraint
  -- analysis_postulate
  | .prop_818f8c | .prop_8162c9 | .prop_f395ad => .analysis_postulate
  -- reporting_principle
  | .prop_c01f50 | .prop_a2ac40 | .prop_a41f63 => .reporting_principle
  -- presentation_design
  | .prop_8bf11f | .IGV_119541 | .PDFA_5ba337 | .prop_85c0a2 => .presentation_design

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
