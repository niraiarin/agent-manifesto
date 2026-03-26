/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **PlayerExperience** (ord=3): プレイヤーの公正性知覚・フラストレーション回避に関する絶対要件 [C1, C2]
- **GameDesignPolicy** (ord=2): 難易度曲線・スキルギャップ・報酬設計に関するゲームデザイン方針 [C3, C4, H1, H2]
- **BalanceHypothesis** (ord=1): キャラクター強度・マップ優位性・メタゲーム変化に関するバランス仮説 [H3, H4, H5]
-/

namespace TestCoverage.S423

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s423_p01
  | s423_p02
  | s423_p03
  | s423_p04
  | s423_p05
  | s423_p06
  | s423_p07
  | s423_p08
  | s423_p09
  | s423_p10
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s423_p01 => []
  | .s423_p02 => []
  | .s423_p03 => [.s423_p01]
  | .s423_p04 => [.s423_p02]
  | .s423_p05 => [.s423_p03, .s423_p04]
  | .s423_p06 => [.s423_p03]
  | .s423_p07 => [.s423_p04]
  | .s423_p08 => [.s423_p06]
  | .s423_p09 => [.s423_p07]
  | .s423_p10 => [.s423_p08, .s423_p09]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- プレイヤーの公正性知覚・フラストレーション回避に関する絶対要件 (ord=3) -/
  | PlayerExperience
  /-- 難易度曲線・スキルギャップ・報酬設計に関するゲームデザイン方針 (ord=2) -/
  | GameDesignPolicy
  /-- キャラクター強度・マップ優位性・メタゲーム変化に関するバランス仮説 (ord=1) -/
  | BalanceHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .PlayerExperience => 3
  | .GameDesignPolicy => 2
  | .BalanceHypothesis => 1

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
  bottom := .BalanceHypothesis
  nontrivial := ⟨.PlayerExperience, .BalanceHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- PlayerExperience
  | .s423_p01 | .s423_p02 => .PlayerExperience
  -- GameDesignPolicy
  | .s423_p03 | .s423_p04 | .s423_p05 => .GameDesignPolicy
  -- BalanceHypothesis
  | .s423_p06 | .s423_p07 | .s423_p08 | .s423_p09 | .s423_p10 => .BalanceHypothesis

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

end TestCoverage.S423
