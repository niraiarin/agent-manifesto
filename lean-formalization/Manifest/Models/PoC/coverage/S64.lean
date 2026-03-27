/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **service_constraint** (ord=4): 顧客対応の絶対的な制約 [C1, C2]
- **quality_standard** (ord=3): 応対品質に関する基準 [C3, H1]
- **escalation_rule** (ord=2): エスカレーション・運用ルール [C4, C5]
- **response_design** (ord=1): 応答の設計・実装判断 [H2, H3]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | prop_298d8a
  | prop_feb32d
  | prop_d869b6
  | prop_69a961
  | prop_65d467
  | prop_1644b2
  | FAQRAG_8b5697
  | prop_188cf7
  | API_d15bf0
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .prop_298d8a => []
  | .prop_feb32d => []
  | .prop_d869b6 => []
  | .prop_69a961 => []
  | .prop_65d467 => []
  | .prop_1644b2 => []
  | .FAQRAG_8b5697 => []
  | .prop_188cf7 => []
  | .API_d15bf0 => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 顧客対応の絶対的な制約 (ord=4) -/
  | service_constraint
  /-- 応対品質に関する基準 (ord=3) -/
  | quality_standard
  /-- エスカレーション・運用ルール (ord=2) -/
  | escalation_rule
  /-- 応答の設計・実装判断 (ord=1) -/
  | response_design
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .service_constraint => 4
  | .quality_standard => 3
  | .escalation_rule => 2
  | .response_design => 1

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
  bottom := .response_design
  nontrivial := ⟨.service_constraint, .response_design, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- service_constraint
  | .prop_298d8a | .prop_feb32d => .service_constraint
  -- quality_standard
  | .prop_d869b6 | .prop_69a961 => .quality_standard
  -- escalation_rule
  | .prop_65d467 | .prop_1644b2 => .escalation_rule
  -- response_design
  | .FAQRAG_8b5697 | .prop_188cf7 | .API_d15bf0 => .response_design

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
