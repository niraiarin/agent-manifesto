/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **assessmentTheory** (ord=3): 教育測定学の基本理論。信頼性・妥当性・公平性 [C1]
- **rubricDesign** (ord=2): 採点ルーブリックの構造と基準定義 [C2, H1]
- **nlpPipeline** (ord=1): 自然言語処理による回答分析パイプライン [H2, H3]
- **feedbackGen** (ord=0): 学習者へのフィードバック生成と提示 [H4]
-/

namespace TestScenario.S170

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | constructValidity
  | interRaterReliability
  | biasProhibition
  | criterionDefinition
  | partialCreditRule
  | anchorResponse
  | semanticSimilarity
  | keywordExtraction
  | plagiarismDetect
  | scoreCalibration
  | diagnosticComment
  | improvementSuggest
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .constructValidity => []
  | .interRaterReliability => []
  | .biasProhibition => []
  | .criterionDefinition => [.constructValidity]
  | .partialCreditRule => [.criterionDefinition, .interRaterReliability]
  | .anchorResponse => [.criterionDefinition]
  | .semanticSimilarity => [.criterionDefinition, .anchorResponse]
  | .keywordExtraction => [.semanticSimilarity]
  | .plagiarismDetect => [.biasProhibition, .semanticSimilarity]
  | .scoreCalibration => [.partialCreditRule, .keywordExtraction]
  | .diagnosticComment => [.scoreCalibration, .semanticSimilarity]
  | .improvementSuggest => [.diagnosticComment, .anchorResponse]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 教育測定学の基本理論。信頼性・妥当性・公平性 (ord=3) -/
  | assessmentTheory
  /-- 採点ルーブリックの構造と基準定義 (ord=2) -/
  | rubricDesign
  /-- 自然言語処理による回答分析パイプライン (ord=1) -/
  | nlpPipeline
  /-- 学習者へのフィードバック生成と提示 (ord=0) -/
  | feedbackGen
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .assessmentTheory => 3
  | .rubricDesign => 2
  | .nlpPipeline => 1
  | .feedbackGen => 0

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
  bottom := .feedbackGen
  nontrivial := ⟨.assessmentTheory, .feedbackGen, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- assessmentTheory
  | .constructValidity | .interRaterReliability | .biasProhibition => .assessmentTheory
  -- rubricDesign
  | .criterionDefinition | .partialCreditRule | .anchorResponse => .rubricDesign
  -- nlpPipeline
  | .semanticSimilarity | .keywordExtraction | .plagiarismDetect | .scoreCalibration => .nlpPipeline
  -- feedbackGen
  | .diagnosticComment | .improvementSuggest => .feedbackGen

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

end TestScenario.S170
