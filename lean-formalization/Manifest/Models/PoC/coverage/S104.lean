/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **ArchivalIntegrity** (ord=5): 原本の保全・非破壊原則。文化財保護法に基づく不変制約 [C1]
- **PaleographicPrinciple** (ord=4): 古文書学の確立された読解原則 [C2, H1]
- **HistoricalContext** (ord=3): 歴史学的文脈に基づく解釈の枠組み [C3, H2]
- **DigitizationMethod** (ord=2): 撮影・画像処理の技術的手法選択 [C4, C5, H3]
- **OCRHypothesis** (ord=1): 文字認識精度・自動解読に関する技術的仮説 [H4, H5]
-/

namespace TestCoverage.S104

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s104_p01
  | s104_p02
  | s104_p03
  | s104_p04
  | s104_p05
  | s104_p06
  | s104_p07
  | s104_p08
  | s104_p09
  | s104_p10
  | s104_p11
  | s104_p12
  | s104_p13
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s104_p01 => []
  | .s104_p02 => []
  | .s104_p03 => [.s104_p01]
  | .s104_p04 => [.s104_p01, .s104_p02]
  | .s104_p05 => [.s104_p03]
  | .s104_p06 => [.s104_p03, .s104_p04]
  | .s104_p07 => [.s104_p05]
  | .s104_p08 => [.s104_p01]
  | .s104_p09 => [.s104_p05, .s104_p06]
  | .s104_p10 => [.s104_p07]
  | .s104_p11 => [.s104_p08]
  | .s104_p12 => [.s104_p09, .s104_p10]
  | .s104_p13 => [.s104_p07, .s104_p11]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 原本の保全・非破壊原則。文化財保護法に基づく不変制約 (ord=5) -/
  | ArchivalIntegrity
  /-- 古文書学の確立された読解原則 (ord=4) -/
  | PaleographicPrinciple
  /-- 歴史学的文脈に基づく解釈の枠組み (ord=3) -/
  | HistoricalContext
  /-- 撮影・画像処理の技術的手法選択 (ord=2) -/
  | DigitizationMethod
  /-- 文字認識精度・自動解読に関する技術的仮説 (ord=1) -/
  | OCRHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .ArchivalIntegrity => 5
  | .PaleographicPrinciple => 4
  | .HistoricalContext => 3
  | .DigitizationMethod => 2
  | .OCRHypothesis => 1

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
  bottom := .OCRHypothesis
  nontrivial := ⟨.ArchivalIntegrity, .OCRHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- ArchivalIntegrity
  | .s104_p01 | .s104_p02 => .ArchivalIntegrity
  -- PaleographicPrinciple
  | .s104_p03 | .s104_p04 => .PaleographicPrinciple
  -- HistoricalContext
  | .s104_p05 | .s104_p06 => .HistoricalContext
  -- DigitizationMethod
  | .s104_p07 | .s104_p08 | .s104_p09 => .DigitizationMethod
  -- OCRHypothesis
  | .s104_p10 | .s104_p11 | .s104_p12 | .s104_p13 => .OCRHypothesis

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

end TestCoverage.S104
