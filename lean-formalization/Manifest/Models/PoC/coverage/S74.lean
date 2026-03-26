/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **competitive_constraint** (ord=4): 競技規則・アンチチート・選手の健康に関する不変制約 [C1, C2]
- **analysis_postulate** (ord=3): 対戦データ分析・メタゲーム推定の前提 [C3, H1]
- **coaching_principle** (ord=2): コーチングの原則（個別適応・段階的改善・メンタル考慮） [C4, C5, H2]
- **feedback_design** (ord=1): フィードバック表示・練習メニューの設計判断 [H3, H4, H5]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | API_b3b226
  | prop_73c0ff
  | prop_b124c1
  | prop_cc3ead
  | prop_f8bf4f
  | prop_f8cbb6
  | prop_4c4b29
  | prop_fb6b0e
  | prop_a190bc
  | prop_95bd5c
  | prop_1fcc4d
  | prop_ddad77
  | prop_c94b67
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .API_b3b226 => []
  | .prop_73c0ff => []
  | .prop_b124c1 => []
  | .prop_cc3ead => []
  | .prop_f8bf4f => []
  | .prop_f8cbb6 => []
  | .prop_4c4b29 => []
  | .prop_fb6b0e => []
  | .prop_a190bc => []
  | .prop_95bd5c => []
  | .prop_1fcc4d => []
  | .prop_ddad77 => []
  | .prop_c94b67 => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 競技規則・アンチチート・選手の健康に関する不変制約 (ord=4) -/
  | competitive_constraint
  /-- 対戦データ分析・メタゲーム推定の前提 (ord=3) -/
  | analysis_postulate
  /-- コーチングの原則（個別適応・段階的改善・メンタル考慮） (ord=2) -/
  | coaching_principle
  /-- フィードバック表示・練習メニューの設計判断 (ord=1) -/
  | feedback_design
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .competitive_constraint => 4
  | .analysis_postulate => 3
  | .coaching_principle => 2
  | .feedback_design => 1

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
  bottom := .feedback_design
  nontrivial := ⟨.competitive_constraint, .feedback_design, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- competitive_constraint
  | .API_b3b226 | .prop_73c0ff | .prop_b124c1 => .competitive_constraint
  -- analysis_postulate
  | .prop_cc3ead | .prop_f8bf4f | .prop_f8cbb6 => .analysis_postulate
  -- coaching_principle
  | .prop_4c4b29 | .prop_fb6b0e | .prop_a190bc => .coaching_principle
  -- feedback_design
  | .prop_95bd5c | .prop_1fcc4d | .prop_ddad77 | .prop_c94b67 => .feedback_design

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
