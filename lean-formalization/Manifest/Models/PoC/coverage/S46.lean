/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **tax_law** (ord=4): 税法・国税通則法・会計基準など法的に不変の制約 [C1, C2]
- **accounting_practice** (ord=3): 一般的な経理実務・帳簿慣行に関する経験的前提 [C3, H1]
- **advisory_policy** (ord=2): 提案の出し方・免責事項・税理士連携の方針 [C4, C5, H2, H3]
- **ui_parameter** (ord=1): 入力フォーム設計・計算精度・表示フォーマット [C6, H4]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | t1
  | t4
  | t6
  | e1
  | e2
  | p1
  | p2
  | p5
  | l1
  | l2
  | d1
  | d8
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .t1 => []
  | .t4 => []
  | .t6 => []
  | .e1 => []
  | .e2 => []
  | .p1 => []
  | .p2 => []
  | .p5 => []
  | .l1 => []
  | .l2 => []
  | .d1 => []
  | .d8 => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 税法・国税通則法・会計基準など法的に不変の制約 (ord=4) -/
  | tax_law
  /-- 一般的な経理実務・帳簿慣行に関する経験的前提 (ord=3) -/
  | accounting_practice
  /-- 提案の出し方・免責事項・税理士連携の方針 (ord=2) -/
  | advisory_policy
  /-- 入力フォーム設計・計算精度・表示フォーマット (ord=1) -/
  | ui_parameter
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .tax_law => 4
  | .accounting_practice => 3
  | .advisory_policy => 2
  | .ui_parameter => 1

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
  bottom := .ui_parameter
  nontrivial := ⟨.tax_law, .ui_parameter, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- tax_law
  | .t1 | .t4 | .t6 => .tax_law
  -- accounting_practice
  | .e1 | .e2 | .p1 => .accounting_practice
  -- advisory_policy
  | .p2 | .p5 | .l1 | .l2 => .advisory_policy
  -- ui_parameter
  | .d1 | .d8 => .ui_parameter

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
