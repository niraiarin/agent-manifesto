/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **bioChemInvariant** (ord=5): 分子生物学の基本原理。塩基対合則・セントラルドグマ [C1]
- **scoringTheory** (ord=4): 置換行列・ギャップペナルティの理論的基盤 [C2, H1]
- **algorithmGuarantee** (ord=3): アラインメントアルゴリズムの計算量・最適性保証 [H2]
- **qualityFilter** (ord=2): シーケンス品質フィルタリングとエラー補正 [H3, H4]
- **heuristicTuning** (ord=1): BLAST系ヒューリスティックの閾値調整 [H5]
- **outputFormat** (ord=0): 結果表示形式と可視化パラメータ [H6]
-/

namespace TestScenario.S164

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | basePairComplementarity
  | codonDegeneracy
  | evolutionaryModel
  | substitutionMatrix
  | gapPenaltyModel
  | affineGapExtension
  | dpOptimality
  | seedAndExtend
  | phredScoreThreshold
  | adapterTrimming
  | lowComplexityMask
  | eValueCutoff
  | wordSizeParam
  | msaVisualization
  | conservationHighlight
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .basePairComplementarity => []
  | .codonDegeneracy => []
  | .evolutionaryModel => []
  | .substitutionMatrix => [.basePairComplementarity, .evolutionaryModel]
  | .gapPenaltyModel => [.evolutionaryModel]
  | .affineGapExtension => [.gapPenaltyModel]
  | .dpOptimality => [.substitutionMatrix, .gapPenaltyModel]
  | .seedAndExtend => [.dpOptimality]
  | .phredScoreThreshold => [.basePairComplementarity]
  | .adapterTrimming => [.phredScoreThreshold]
  | .lowComplexityMask => [.seedAndExtend]
  | .eValueCutoff => [.seedAndExtend, .phredScoreThreshold]
  | .wordSizeParam => [.seedAndExtend]
  | .msaVisualization => [.eValueCutoff, .lowComplexityMask]
  | .conservationHighlight => [.substitutionMatrix, .msaVisualization]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 分子生物学の基本原理。塩基対合則・セントラルドグマ (ord=5) -/
  | bioChemInvariant
  /-- 置換行列・ギャップペナルティの理論的基盤 (ord=4) -/
  | scoringTheory
  /-- アラインメントアルゴリズムの計算量・最適性保証 (ord=3) -/
  | algorithmGuarantee
  /-- シーケンス品質フィルタリングとエラー補正 (ord=2) -/
  | qualityFilter
  /-- BLAST系ヒューリスティックの閾値調整 (ord=1) -/
  | heuristicTuning
  /-- 結果表示形式と可視化パラメータ (ord=0) -/
  | outputFormat
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .bioChemInvariant => 5
  | .scoringTheory => 4
  | .algorithmGuarantee => 3
  | .qualityFilter => 2
  | .heuristicTuning => 1
  | .outputFormat => 0

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
  bottom := .outputFormat
  nontrivial := ⟨.bioChemInvariant, .outputFormat, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- bioChemInvariant
  | .basePairComplementarity | .codonDegeneracy | .evolutionaryModel => .bioChemInvariant
  -- scoringTheory
  | .substitutionMatrix | .gapPenaltyModel | .affineGapExtension => .scoringTheory
  -- algorithmGuarantee
  | .dpOptimality | .seedAndExtend => .algorithmGuarantee
  -- qualityFilter
  | .phredScoreThreshold | .adapterTrimming | .lowComplexityMask => .qualityFilter
  -- heuristicTuning
  | .eValueCutoff | .wordSizeParam => .heuristicTuning
  -- outputFormat
  | .msaVisualization | .conservationHighlight => .outputFormat

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

end TestScenario.S164
