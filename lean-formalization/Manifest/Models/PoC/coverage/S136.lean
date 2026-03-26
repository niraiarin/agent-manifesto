/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **BusinessRule** (ord=3): 景品表示法・特商法等の法的制約と事業方針 [C1, C2, C3]
- **RecommendationLogic** (ord=2): 推薦アルゴリズムの設計。ABテストで改善 [C4, C5, H1, H2]
- **EngagementHypothesis** (ord=1): 視聴者行動に関する仮説。実データで検証 [H3, H4, H5]
-/

namespace TestCoverage.S136

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s136_p01
  | s136_p02
  | s136_p03
  | s136_p04
  | s136_p05
  | s136_p06
  | s136_p07
  | s136_p08
  | s136_p09
  | s136_p10
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s136_p01 => []
  | .s136_p02 => []
  | .s136_p03 => []
  | .s136_p04 => [.s136_p01]
  | .s136_p05 => [.s136_p02]
  | .s136_p06 => [.s136_p01, .s136_p03]
  | .s136_p07 => [.s136_p03]
  | .s136_p08 => [.s136_p04]
  | .s136_p09 => [.s136_p05, .s136_p06]
  | .s136_p10 => [.s136_p07]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 景品表示法・特商法等の法的制約と事業方針 (ord=3) -/
  | BusinessRule
  /-- 推薦アルゴリズムの設計。ABテストで改善 (ord=2) -/
  | RecommendationLogic
  /-- 視聴者行動に関する仮説。実データで検証 (ord=1) -/
  | EngagementHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .BusinessRule => 3
  | .RecommendationLogic => 2
  | .EngagementHypothesis => 1

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
  bottom := .EngagementHypothesis
  nontrivial := ⟨.BusinessRule, .EngagementHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- BusinessRule
  | .s136_p01 | .s136_p02 | .s136_p03 => .BusinessRule
  -- RecommendationLogic
  | .s136_p04 | .s136_p05 | .s136_p06 | .s136_p07 => .RecommendationLogic
  -- EngagementHypothesis
  | .s136_p08 | .s136_p09 | .s136_p10 => .EngagementHypothesis

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

end TestCoverage.S136
