/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **LinguisticPrinciple** (ord=3): 翻訳品質の言語学的原則。意味的等価性・自然さの基準 [C1, C2]
- **SubtitleConstraint** (ord=2): 字幕固有の制約。時間・文字数・可読性 [C3, C4, H1]
- **EvaluationMetric** (ord=1): 品質評価指標の設計選択 [C5, H2, H3, H4]
- **CorpusHypothesis** (ord=0): コーパス・学習データに関する仮説 [H5, H6]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s130_p01
  | s130_p02
  | s130_p03
  | s130_p04
  | s130_p05
  | s130_p06
  | s130_p07
  | s130_p08
  | s130_p09
  | s130_p10
  | s130_p11
  | s130_p12
  | s130_p13
  | s130_p14
  | s130_p15
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s130_p01 => []
  | .s130_p02 => []
  | .s130_p03 => []
  | .s130_p04 => [.s130_p01]
  | .s130_p05 => [.s130_p01, .s130_p02]
  | .s130_p06 => [.s130_p03]
  | .s130_p07 => [.s130_p04]
  | .s130_p08 => [.s130_p05]
  | .s130_p09 => [.s130_p04, .s130_p06]
  | .s130_p10 => [.s130_p05]
  | .s130_p11 => [.s130_p07]
  | .s130_p12 => [.s130_p08]
  | .s130_p13 => [.s130_p09, .s130_p10]
  | .s130_p14 => [.s130_p11]
  | .s130_p15 => [.s130_p12, .s130_p13]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 翻訳品質の言語学的原則。意味的等価性・自然さの基準 (ord=3) -/
  | LinguisticPrinciple
  /-- 字幕固有の制約。時間・文字数・可読性 (ord=2) -/
  | SubtitleConstraint
  /-- 品質評価指標の設計選択 (ord=1) -/
  | EvaluationMetric
  /-- コーパス・学習データに関する仮説 (ord=0) -/
  | CorpusHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .LinguisticPrinciple => 3
  | .SubtitleConstraint => 2
  | .EvaluationMetric => 1
  | .CorpusHypothesis => 0

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
  bottom := .CorpusHypothesis
  nontrivial := ⟨.LinguisticPrinciple, .CorpusHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- LinguisticPrinciple
  | .s130_p01 | .s130_p02 | .s130_p03 => .LinguisticPrinciple
  -- SubtitleConstraint
  | .s130_p04 | .s130_p05 | .s130_p06 => .SubtitleConstraint
  -- EvaluationMetric
  | .s130_p07 | .s130_p08 | .s130_p09 | .s130_p10 => .EvaluationMetric
  -- CorpusHypothesis
  | .s130_p11 | .s130_p12 | .s130_p13 | .s130_p14 | .s130_p15 => .CorpusHypothesis

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
