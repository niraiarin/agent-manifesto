/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **privacy_constraint** (ord=4): 児童生徒の個人情報保護に関する不変制約 [C1, C2]
- **accuracy_standard** (ord=3): 出欠記録の正確性に関する基準 [C3, H1]
- **operational_rule** (ord=2): 学校運用上のルール [C4, C5]
- **implementation_choice** (ord=1): 技術的実装の選択 [H2, H3]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | prop_e5da8d
  | prop_1b87cc
  | prop_9c5df4
  | prop_e8015a
  | prop_c963de
  | prop_58387b
  | ArcFace_f2b931
  | ONNXRu_862f73
  | prop_72de01
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .prop_e5da8d => []
  | .prop_1b87cc => []
  | .prop_9c5df4 => []
  | .prop_e8015a => []
  | .prop_c963de => []
  | .prop_58387b => []
  | .ArcFace_f2b931 => []
  | .ONNXRu_862f73 => []
  | .prop_72de01 => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 児童生徒の個人情報保護に関する不変制約 (ord=4) -/
  | privacy_constraint
  /-- 出欠記録の正確性に関する基準 (ord=3) -/
  | accuracy_standard
  /-- 学校運用上のルール (ord=2) -/
  | operational_rule
  /-- 技術的実装の選択 (ord=1) -/
  | implementation_choice
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .privacy_constraint => 4
  | .accuracy_standard => 3
  | .operational_rule => 2
  | .implementation_choice => 1

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
  bottom := .implementation_choice
  nontrivial := ⟨.privacy_constraint, .implementation_choice, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- privacy_constraint
  | .prop_e5da8d | .prop_1b87cc => .privacy_constraint
  -- accuracy_standard
  | .prop_9c5df4 | .prop_e8015a => .accuracy_standard
  -- operational_rule
  | .prop_c963de | .prop_58387b => .operational_rule
  -- implementation_choice
  | .ArcFace_f2b931 | .ONNXRu_862f73 | .prop_72de01 => .implementation_choice

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
