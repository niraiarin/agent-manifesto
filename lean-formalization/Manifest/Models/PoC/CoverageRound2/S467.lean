/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **FairPlayInvariant** (ord=3): チート検知・不正行為排除の絶対制約。試合結果の公正性保証 [C1, C2]
- **GameRuleCompliance** (ord=2): ゲームタイトル毎のルール・大会レギュレーション・プラットフォームポリシー準拠 [C3, C4, H1]
- **PerformanceModelHypothesis** (ord=1): プレイヤーの行動パターン・チーム連携・スキル成長を推定する仮説層 [H2, H3, H4, H5, H6, H7]
-/

namespace TestCoverage.S467

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s467_p01
  | s467_p02
  | s467_p03
  | s467_p04
  | s467_p05
  | s467_p06
  | s467_p07
  | s467_p08
  | s467_p09
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s467_p01 => []
  | .s467_p02 => [.s467_p01]
  | .s467_p03 => [.s467_p01]
  | .s467_p04 => [.s467_p02]
  | .s467_p05 => [.s467_p03]
  | .s467_p06 => [.s467_p04]
  | .s467_p07 => [.s467_p05]
  | .s467_p08 => [.s467_p06]
  | .s467_p09 => [.s467_p07, .s467_p08]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- チート検知・不正行為排除の絶対制約。試合結果の公正性保証 (ord=3) -/
  | FairPlayInvariant
  /-- ゲームタイトル毎のルール・大会レギュレーション・プラットフォームポリシー準拠 (ord=2) -/
  | GameRuleCompliance
  /-- プレイヤーの行動パターン・チーム連携・スキル成長を推定する仮説層 (ord=1) -/
  | PerformanceModelHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .FairPlayInvariant => 3
  | .GameRuleCompliance => 2
  | .PerformanceModelHypothesis => 1

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
  bottom := .PerformanceModelHypothesis
  nontrivial := ⟨.FairPlayInvariant, .PerformanceModelHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- FairPlayInvariant
  | .s467_p01 | .s467_p02 => .FairPlayInvariant
  -- GameRuleCompliance
  | .s467_p03 | .s467_p04 => .GameRuleCompliance
  -- PerformanceModelHypothesis
  | .s467_p05 | .s467_p06 | .s467_p07 | .s467_p08 | .s467_p09 => .PerformanceModelHypothesis

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

end TestCoverage.S467
