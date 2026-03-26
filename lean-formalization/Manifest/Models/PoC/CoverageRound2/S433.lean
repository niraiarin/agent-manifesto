/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **ChemicalLawInvariant** (ord=5): 土壌化学・反応速度論・pH平衡の不変制約 [C1, C2]
- **EnvironmentalRegulation** (ord=4): 土壌汚染対策法・農薬残留基準・重金属規制 [C3, C4]
- **SamplingAnalysisPolicy** (ord=3): 土壌サンプリング手法・分析プロトコル・精度保証 [C5, H1]
- **NutrientModelHypothesis** (ord=2): 窒素・リン・カリウムの作物吸収モデルに関する推論 [C6, H2, H3, H4]
- **RecommendationAlgorithm** (ord=1): 施肥量・改良材推奨アルゴリズムの仮説的選択 [H5, H6, H7]
-/

namespace TestCoverage.S433

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s433_p01
  | s433_p02
  | s433_p03
  | s433_p04
  | s433_p05
  | s433_p06
  | s433_p07
  | s433_p08
  | s433_p09
  | s433_p10
  | s433_p11
  | s433_p12
  | s433_p13
  | s433_p14
  | s433_p15
  | s433_p16
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s433_p01 => []
  | .s433_p02 => []
  | .s433_p03 => [.s433_p01, .s433_p02]
  | .s433_p04 => [.s433_p01]
  | .s433_p05 => [.s433_p02]
  | .s433_p06 => [.s433_p04, .s433_p05]
  | .s433_p07 => [.s433_p03]
  | .s433_p08 => [.s433_p06]
  | .s433_p09 => [.s433_p07, .s433_p08]
  | .s433_p10 => [.s433_p07]
  | .s433_p11 => [.s433_p08]
  | .s433_p12 => [.s433_p09, .s433_p10]
  | .s433_p13 => [.s433_p11, .s433_p12]
  | .s433_p14 => [.s433_p10]
  | .s433_p15 => [.s433_p12, .s433_p14]
  | .s433_p16 => [.s433_p13, .s433_p15]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 土壌化学・反応速度論・pH平衡の不変制約 (ord=5) -/
  | ChemicalLawInvariant
  /-- 土壌汚染対策法・農薬残留基準・重金属規制 (ord=4) -/
  | EnvironmentalRegulation
  /-- 土壌サンプリング手法・分析プロトコル・精度保証 (ord=3) -/
  | SamplingAnalysisPolicy
  /-- 窒素・リン・カリウムの作物吸収モデルに関する推論 (ord=2) -/
  | NutrientModelHypothesis
  /-- 施肥量・改良材推奨アルゴリズムの仮説的選択 (ord=1) -/
  | RecommendationAlgorithm
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .ChemicalLawInvariant => 5
  | .EnvironmentalRegulation => 4
  | .SamplingAnalysisPolicy => 3
  | .NutrientModelHypothesis => 2
  | .RecommendationAlgorithm => 1

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
  bottom := .RecommendationAlgorithm
  nontrivial := ⟨.ChemicalLawInvariant, .RecommendationAlgorithm, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- ChemicalLawInvariant
  | .s433_p01 | .s433_p02 | .s433_p03 => .ChemicalLawInvariant
  -- EnvironmentalRegulation
  | .s433_p04 | .s433_p05 | .s433_p06 => .EnvironmentalRegulation
  -- SamplingAnalysisPolicy
  | .s433_p07 | .s433_p08 | .s433_p09 => .SamplingAnalysisPolicy
  -- NutrientModelHypothesis
  | .s433_p10 | .s433_p11 | .s433_p12 | .s433_p13 => .NutrientModelHypothesis
  -- RecommendationAlgorithm
  | .s433_p14 | .s433_p15 | .s433_p16 => .RecommendationAlgorithm

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

end TestCoverage.S433
