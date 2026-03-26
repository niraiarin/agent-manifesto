/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **taxonomy** (ord=3): 生物学的分類体系。学術的に確立された知識。 [C2]
- **requirement** (ord=2): 精度・動作要件。プロジェクト目標で固定。 [C1, C3]
- **design** (ord=1): 分類アルゴリズムの設計方針。技術進歩で変更可能。 [H1, H2]
- **hyp** (ord=0): 未検証の仮説。フィールドテストで検証が必要。 [H3]
-/

namespace Scenario216

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | tax1
  | tax2
  | req1
  | req2
  | req3
  | des1
  | des2
  | des3
  | des4
  | hyp1
  | hyp2
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .tax1 => []
  | .tax2 => []
  | .req1 => [.tax1]
  | .req2 => [.tax1]
  | .req3 => [.tax2]
  | .des1 => [.tax1, .req1]
  | .des2 => [.req2, .req3]
  | .des3 => [.req1, .req2]
  | .des4 => [.tax2, .req3]
  | .hyp1 => [.des1, .des3]
  | .hyp2 => [.des2, .des4]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 生物学的分類体系。学術的に確立された知識。 (ord=3) -/
  | taxonomy
  /-- 精度・動作要件。プロジェクト目標で固定。 (ord=2) -/
  | requirement
  /-- 分類アルゴリズムの設計方針。技術進歩で変更可能。 (ord=1) -/
  | design
  /-- 未検証の仮説。フィールドテストで検証が必要。 (ord=0) -/
  | hyp
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .taxonomy => 3
  | .requirement => 2
  | .design => 1
  | .hyp => 0

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
  bottom := .hyp
  nontrivial := ⟨.taxonomy, .hyp, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- taxonomy
  | .tax1 | .tax2 => .taxonomy
  -- requirement
  | .req1 | .req2 | .req3 => .requirement
  -- design
  | .des1 | .des2 | .des3 | .des4 => .design
  -- hyp
  | .hyp1 | .hyp2 => .hyp

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

end Scenario216
