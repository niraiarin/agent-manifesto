/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **PreservationInvariant** (ord=3): 原本文書の物理的保護・デジタル保存の不可逆損傷防止に関する絶対制約 [C1, C2]
- **TranscriptionAccuracyPolicy** (ord=2): 文字認識精度・文脈整合性・校正プロセスに関する方針 [C3, C4]
- **HistoricalInterpretationHypothesis** (ord=1): 変体仮名・くずし字・異体字認識モデルの精度向上に関する仮説 [H1, H2, H3, H4, H5]
-/

namespace TestCoverage.S400

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s400_p01
  | s400_p02
  | s400_p03
  | s400_p04
  | s400_p05
  | s400_p06
  | s400_p07
  | s400_p08
  | s400_p09
  | s400_p10
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s400_p01 => []
  | .s400_p02 => []
  | .s400_p03 => [.s400_p01]
  | .s400_p04 => [.s400_p02]
  | .s400_p05 => [.s400_p03, .s400_p04]
  | .s400_p06 => [.s400_p03]
  | .s400_p07 => [.s400_p04]
  | .s400_p08 => [.s400_p05]
  | .s400_p09 => [.s400_p06]
  | .s400_p10 => [.s400_p07, .s400_p08, .s400_p09]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 原本文書の物理的保護・デジタル保存の不可逆損傷防止に関する絶対制約 (ord=3) -/
  | PreservationInvariant
  /-- 文字認識精度・文脈整合性・校正プロセスに関する方針 (ord=2) -/
  | TranscriptionAccuracyPolicy
  /-- 変体仮名・くずし字・異体字認識モデルの精度向上に関する仮説 (ord=1) -/
  | HistoricalInterpretationHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .PreservationInvariant => 3
  | .TranscriptionAccuracyPolicy => 2
  | .HistoricalInterpretationHypothesis => 1

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
  bottom := .HistoricalInterpretationHypothesis
  nontrivial := ⟨.PreservationInvariant, .HistoricalInterpretationHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- PreservationInvariant
  | .s400_p01 | .s400_p02 => .PreservationInvariant
  -- TranscriptionAccuracyPolicy
  | .s400_p03 | .s400_p04 | .s400_p05 => .TranscriptionAccuracyPolicy
  -- HistoricalInterpretationHypothesis
  | .s400_p06 | .s400_p07 | .s400_p08 | .s400_p09 | .s400_p10 => .HistoricalInterpretationHypothesis

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

end TestCoverage.S400
