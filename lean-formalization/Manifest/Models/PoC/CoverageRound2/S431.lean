/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **PhysicalConstraint** (ord=4): スポーツルール・フィジカル限界・競技規則の絶対制約 [C1, C2]
- **PerformanceBaseline** (ord=3): 選手の能力指標・統計的パフォーマンス基準 [C3, C4]
- **TacticalPolicy** (ord=2): 戦術選択・フォーメーション・プレースタイルの方針 [C5, H1, H2]
- **MatchPredictionHypothesis** (ord=1): 対戦相手の行動・試合展開に関する予測仮説 [H3, H4, H5, H6]
-/

namespace TestCoverage.S431

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s431_p01
  | s431_p02
  | s431_p03
  | s431_p04
  | s431_p05
  | s431_p06
  | s431_p07
  | s431_p08
  | s431_p09
  | s431_p10
  | s431_p11
  | s431_p12
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s431_p01 => []
  | .s431_p02 => []
  | .s431_p03 => [.s431_p01, .s431_p02]
  | .s431_p04 => [.s431_p01]
  | .s431_p05 => [.s431_p02]
  | .s431_p06 => [.s431_p04, .s431_p05]
  | .s431_p07 => [.s431_p03]
  | .s431_p08 => [.s431_p04]
  | .s431_p09 => [.s431_p06, .s431_p07]
  | .s431_p10 => [.s431_p07]
  | .s431_p11 => [.s431_p08, .s431_p09]
  | .s431_p12 => [.s431_p10, .s431_p11]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- スポーツルール・フィジカル限界・競技規則の絶対制約 (ord=4) -/
  | PhysicalConstraint
  /-- 選手の能力指標・統計的パフォーマンス基準 (ord=3) -/
  | PerformanceBaseline
  /-- 戦術選択・フォーメーション・プレースタイルの方針 (ord=2) -/
  | TacticalPolicy
  /-- 対戦相手の行動・試合展開に関する予測仮説 (ord=1) -/
  | MatchPredictionHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .PhysicalConstraint => 4
  | .PerformanceBaseline => 3
  | .TacticalPolicy => 2
  | .MatchPredictionHypothesis => 1

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
  bottom := .MatchPredictionHypothesis
  nontrivial := ⟨.PhysicalConstraint, .MatchPredictionHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- PhysicalConstraint
  | .s431_p01 | .s431_p02 | .s431_p03 => .PhysicalConstraint
  -- PerformanceBaseline
  | .s431_p04 | .s431_p05 | .s431_p06 => .PerformanceBaseline
  -- TacticalPolicy
  | .s431_p07 | .s431_p08 | .s431_p09 => .TacticalPolicy
  -- MatchPredictionHypothesis
  | .s431_p10 | .s431_p11 | .s431_p12 => .MatchPredictionHypothesis

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

end TestCoverage.S431
