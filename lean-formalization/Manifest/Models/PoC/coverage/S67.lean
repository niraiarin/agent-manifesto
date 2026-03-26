/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **knowledge_integrity** (ord=4): ワイン知識の正確性に関する不変制約 [C1, C2]
- **recommendation_quality** (ord=3): 推薦品質に関する基準 [C3, H1]
- **service_rule** (ord=2): サービス提供上のルール [C4, C5]
- **algorithm_choice** (ord=1): アルゴリズム・モデルの選択 [H2, H3]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | prop_44d981
  | prop_4c0061
  | prop_21c007
  | prop_ea7298
  | prop_ac66cd
  | prop_868e5e
  | prop_f2f850
  | prop_8711e8
  | prop_474dbc
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .prop_44d981 => []
  | .prop_4c0061 => []
  | .prop_21c007 => []
  | .prop_ea7298 => []
  | .prop_ac66cd => []
  | .prop_868e5e => []
  | .prop_f2f850 => []
  | .prop_8711e8 => []
  | .prop_474dbc => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- ワイン知識の正確性に関する不変制約 (ord=4) -/
  | knowledge_integrity
  /-- 推薦品質に関する基準 (ord=3) -/
  | recommendation_quality
  /-- サービス提供上のルール (ord=2) -/
  | service_rule
  /-- アルゴリズム・モデルの選択 (ord=1) -/
  | algorithm_choice
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .knowledge_integrity => 4
  | .recommendation_quality => 3
  | .service_rule => 2
  | .algorithm_choice => 1

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
  bottom := .algorithm_choice
  nontrivial := ⟨.knowledge_integrity, .algorithm_choice, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- knowledge_integrity
  | .prop_44d981 | .prop_4c0061 => .knowledge_integrity
  -- recommendation_quality
  | .prop_21c007 | .prop_ea7298 => .recommendation_quality
  -- service_rule
  | .prop_ac66cd | .prop_868e5e | .prop_474dbc => .service_rule
  -- algorithm_choice
  | .prop_f2f850 | .prop_8711e8 => .algorithm_choice

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
