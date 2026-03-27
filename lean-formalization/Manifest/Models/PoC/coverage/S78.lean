/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **legal_constraint** (ord=4): 区分所有法・管理規約に基づく法的制約 [C1, C2]
- **financial_postulate** (ord=3): 管理費・修繕積立金の財務的前提 [C3, H1]
- **governance_principle** (ord=2): 合意形成・情報公開の運営原則 [C4, C5, H2]
- **tool_design** (ord=1): 支援ツールのUI・通知・帳票の設計判断 [H3, H4, H5]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | prop_ac22b2
  | prop_a0411d
  | prop_b195fe
  | prop_1c578b
  | prop_10ff56
  | prop_21478e
  | prop_aba16c
  | prop_e55adc
  | prop_c1b45a
  | prop_858c91
  | prop_b7bbe2
  | prop_540e69
  | prop_f34109
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .prop_ac22b2 => []
  | .prop_a0411d => []
  | .prop_b195fe => []
  | .prop_1c578b => []
  | .prop_10ff56 => []
  | .prop_21478e => []
  | .prop_aba16c => []
  | .prop_e55adc => []
  | .prop_c1b45a => []
  | .prop_858c91 => []
  | .prop_b7bbe2 => []
  | .prop_540e69 => []
  | .prop_f34109 => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 区分所有法・管理規約に基づく法的制約 (ord=4) -/
  | legal_constraint
  /-- 管理費・修繕積立金の財務的前提 (ord=3) -/
  | financial_postulate
  /-- 合意形成・情報公開の運営原則 (ord=2) -/
  | governance_principle
  /-- 支援ツールのUI・通知・帳票の設計判断 (ord=1) -/
  | tool_design
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .legal_constraint => 4
  | .financial_postulate => 3
  | .governance_principle => 2
  | .tool_design => 1

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
  bottom := .tool_design
  nontrivial := ⟨.legal_constraint, .tool_design, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- legal_constraint
  | .prop_ac22b2 | .prop_a0411d | .prop_b195fe => .legal_constraint
  -- financial_postulate
  | .prop_1c578b | .prop_10ff56 | .prop_21478e => .financial_postulate
  -- governance_principle
  | .prop_aba16c | .prop_e55adc | .prop_c1b45a => .governance_principle
  -- tool_design
  | .prop_858c91 | .prop_b7bbe2 | .prop_540e69 | .prop_f34109 => .tool_design

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
