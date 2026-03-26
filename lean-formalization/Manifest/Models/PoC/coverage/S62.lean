/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **core_constraint** (ord=4): 検知の目的と安全に関わる不変前提 [C1, C2]
- **accuracy_postulate** (ord=3): 精度・信頼性に関する経験的仮定 [C3, H1]
- **operational_rule** (ord=2): 運用・設置に関する制約 [C4, C5]
- **design_choice** (ord=1): 技術的な実装判断 [H2, H3]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | prop_1e422f
  | prop_61c95f
  | prop_f7029c
  | prop_75ee94
  | prop_a0f2c2
  | UI_9a0dc5
  | YOLOv_0f5469
  | prop_701822
  | prop_32606a
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .prop_1e422f => []
  | .prop_61c95f => []
  | .prop_f7029c => []
  | .prop_75ee94 => []
  | .prop_a0f2c2 => []
  | .UI_9a0dc5 => []
  | .YOLOv_0f5469 => []
  | .prop_701822 => []
  | .prop_32606a => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 検知の目的と安全に関わる不変前提 (ord=4) -/
  | core_constraint
  /-- 精度・信頼性に関する経験的仮定 (ord=3) -/
  | accuracy_postulate
  /-- 運用・設置に関する制約 (ord=2) -/
  | operational_rule
  /-- 技術的な実装判断 (ord=1) -/
  | design_choice
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .core_constraint => 4
  | .accuracy_postulate => 3
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
  | .prop_1e422f | .prop_61c95f => .core_constraint
  -- accuracy_postulate
  | .prop_f7029c | .prop_75ee94 => .accuracy_postulate
  -- operational_rule
  | .prop_a0f2c2 | .UI_9a0dc5 => .operational_rule
  -- design_choice
  | .YOLOv_0f5469 | .prop_701822 | .prop_32606a => .design_choice

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
