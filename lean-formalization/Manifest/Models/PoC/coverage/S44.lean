/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **content_regulation** (ord=4): 年齢制限・著作権・コンテンツポリシーなど法的・倫理的制約 [C1, C2]
- **user_behavior** (ord=3): ユーザーの視聴パターン・嗜好モデルに関する経験的仮定 [C3, H1]
- **recommendation_policy** (ord=2): 推薦アルゴリズム選択・多様性バランス・フィルタリング方針 [C4, H2, H3]
- **display_parameter** (ord=1): 表示件数・ランキング重み・A/Bテストパラメータ [C5, H4]
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
  /-- 年齢制限・著作権・コンテンツポリシーなど法的・倫理的制約 (ord=4) -/
  | content_regulation
  /-- ユーザーの視聴パターン・嗜好モデルに関する経験的仮定 (ord=3) -/
  | user_behavior
  /-- 推薦アルゴリズム選択・多様性バランス・フィルタリング方針 (ord=2) -/
  | recommendation_policy
  /-- 表示件数・ランキング重み・A/Bテストパラメータ (ord=1) -/
  | display_parameter
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .content_regulation => 4
  | .user_behavior => 3
  | .recommendation_policy => 2
  | .display_parameter => 1

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
  bottom := .display_parameter
  nontrivial := ⟨.content_regulation, .display_parameter, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- content_regulation
  | .t1 | .t4 | .t6 => .content_regulation
  -- user_behavior
  | .e1 | .e2 | .p1 => .user_behavior
  -- recommendation_policy
  | .p2 | .p5 | .l1 => .recommendation_policy
  -- display_parameter
  | .d1 | .d8 => .display_parameter

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
