/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **SearchInvariant** (ord=3): 調査網羅性と判断透明性に関する絶対不変条件 [C1, C2, C3, C4]
- **SearchPolicy** (ord=2): 検索戦略と結果提示の運用ポリシー [C5, H2, H4, H5]
- **AnalyticalHypothesis** (ord=1): 意味検索モデルと分類手法に関する技術仮説 [H1, H3]
-/

namespace TestCoverage.S388

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s388_p01
  | s388_p02
  | s388_p03
  | s388_p04
  | s388_p05
  | s388_p06
  | s388_p07
  | s388_p08
  | s388_p09
  | s388_p10
  | s388_p11
  | s388_p12
  | s388_p13
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s388_p01 => []
  | .s388_p02 => []
  | .s388_p03 => [.s388_p01, .s388_p02]
  | .s388_p04 => [.s388_p01]
  | .s388_p05 => [.s388_p01, .s388_p03]
  | .s388_p06 => [.s388_p02]
  | .s388_p07 => [.s388_p01]
  | .s388_p08 => [.s388_p05]
  | .s388_p09 => [.s388_p06]
  | .s388_p10 => [.s388_p01, .s388_p04]
  | .s388_p11 => [.s388_p06, .s388_p07]
  | .s388_p12 => [.s388_p09, .s388_p10]
  | .s388_p13 => [.s388_p08, .s388_p11]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 調査網羅性と判断透明性に関する絶対不変条件 (ord=3) -/
  | SearchInvariant
  /-- 検索戦略と結果提示の運用ポリシー (ord=2) -/
  | SearchPolicy
  /-- 意味検索モデルと分類手法に関する技術仮説 (ord=1) -/
  | AnalyticalHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .SearchInvariant => 3
  | .SearchPolicy => 2
  | .AnalyticalHypothesis => 1

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
  bottom := .AnalyticalHypothesis
  nontrivial := ⟨.SearchInvariant, .AnalyticalHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- SearchInvariant
  | .s388_p01 | .s388_p02 | .s388_p03 | .s388_p04 => .SearchInvariant
  -- SearchPolicy
  | .s388_p05 | .s388_p06 | .s388_p07 | .s388_p08 | .s388_p11 | .s388_p13 => .SearchPolicy
  -- AnalyticalHypothesis
  | .s388_p09 | .s388_p10 | .s388_p12 => .AnalyticalHypothesis

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

end TestCoverage.S388
