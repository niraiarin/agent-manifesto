/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **LifeSafetyDispatchInvariant** (ord=3): 生命危機事案への即時対応保障。分類誤りによる応急遅延は絶対許容不可 [C1, C2]
- **TriageClassificationPolicy** (ord=2): 緊急度A/B/C分類基準・管轄機関振り分け・二次確認プロセスの方針 [C3, C4, H1, H2]
- **CallAnalysisHypothesis** (ord=1): 音声特徴・キーワード抽出・発信者属性による緊急度推定仮説 [C5, H3, H4]
-/

namespace TestCoverage.S454

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s454_p01
  | s454_p02
  | s454_p03
  | s454_p04
  | s454_p05
  | s454_p06
  | s454_p07
  | s454_p08
  | s454_p09
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s454_p01 => []
  | .s454_p02 => []
  | .s454_p03 => [.s454_p01]
  | .s454_p04 => [.s454_p02]
  | .s454_p05 => [.s454_p03, .s454_p04]
  | .s454_p06 => [.s454_p03]
  | .s454_p07 => [.s454_p04]
  | .s454_p08 => [.s454_p05, .s454_p06]
  | .s454_p09 => [.s454_p07, .s454_p08]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 生命危機事案への即時対応保障。分類誤りによる応急遅延は絶対許容不可 (ord=3) -/
  | LifeSafetyDispatchInvariant
  /-- 緊急度A/B/C分類基準・管轄機関振り分け・二次確認プロセスの方針 (ord=2) -/
  | TriageClassificationPolicy
  /-- 音声特徴・キーワード抽出・発信者属性による緊急度推定仮説 (ord=1) -/
  | CallAnalysisHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .LifeSafetyDispatchInvariant => 3
  | .TriageClassificationPolicy => 2
  | .CallAnalysisHypothesis => 1

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
  bottom := .CallAnalysisHypothesis
  nontrivial := ⟨.LifeSafetyDispatchInvariant, .CallAnalysisHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- LifeSafetyDispatchInvariant
  | .s454_p01 | .s454_p02 => .LifeSafetyDispatchInvariant
  -- TriageClassificationPolicy
  | .s454_p03 | .s454_p04 | .s454_p05 => .TriageClassificationPolicy
  -- CallAnalysisHypothesis
  | .s454_p06 | .s454_p07 | .s454_p08 | .s454_p09 => .CallAnalysisHypothesis

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

end TestCoverage.S454
