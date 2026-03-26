/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **RacingRegulation** (ord=4): 競馬法・JRAルールに基づく不変制約 [C1, C2]
- **PerformanceEvidence** (ord=3): 過去レースデータから導かれる経験則 [C3, C4, H1]
- **PredictionStrategy** (ord=2): 予測モデルの設計選択。手法変更可能 [C5, H2, H3]
- **BettingHeuristic** (ord=1): 投票戦略の仮説。実績データで検証 [C6, H4, H5]
-/

namespace TestCoverage.S132

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s132_p01
  | s132_p02
  | s132_p03
  | s132_p04
  | s132_p05
  | s132_p06
  | s132_p07
  | s132_p08
  | s132_p09
  | s132_p10
  | s132_p11
  | s132_p12
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s132_p01 => []
  | .s132_p02 => []
  | .s132_p03 => [.s132_p01]
  | .s132_p04 => [.s132_p01, .s132_p02]
  | .s132_p05 => [.s132_p02]
  | .s132_p06 => [.s132_p03]
  | .s132_p07 => [.s132_p04]
  | .s132_p08 => [.s132_p03, .s132_p05]
  | .s132_p09 => [.s132_p06]
  | .s132_p10 => [.s132_p07]
  | .s132_p11 => [.s132_p08]
  | .s132_p12 => [.s132_p09, .s132_p10]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 競馬法・JRAルールに基づく不変制約 (ord=4) -/
  | RacingRegulation
  /-- 過去レースデータから導かれる経験則 (ord=3) -/
  | PerformanceEvidence
  /-- 予測モデルの設計選択。手法変更可能 (ord=2) -/
  | PredictionStrategy
  /-- 投票戦略の仮説。実績データで検証 (ord=1) -/
  | BettingHeuristic
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .RacingRegulation => 4
  | .PerformanceEvidence => 3
  | .PredictionStrategy => 2
  | .BettingHeuristic => 1

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
  bottom := .BettingHeuristic
  nontrivial := ⟨.RacingRegulation, .BettingHeuristic, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- RacingRegulation
  | .s132_p01 | .s132_p02 => .RacingRegulation
  -- PerformanceEvidence
  | .s132_p03 | .s132_p04 | .s132_p05 => .PerformanceEvidence
  -- PredictionStrategy
  | .s132_p06 | .s132_p07 | .s132_p08 => .PredictionStrategy
  -- BettingHeuristic
  | .s132_p09 | .s132_p10 | .s132_p11 | .s132_p12 => .BettingHeuristic

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

end TestCoverage.S132
