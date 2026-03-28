/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **GeneticFundamentalLaw** (ord=6): メンデル遺伝則・DNA複製メカニズムの不変法則 [C1, C2]
- **BioethicsRegulation** (ord=5): 遺伝子組換え規制・生物多様性条約・倫理審査基準 [C3, C4]
- **BreedingObjectivePolicy** (ord=4): 目標形質の優先順位・育種目標・選抜基準の方針 [C5, C6]
- **SimulationModelPolicy** (ord=3): ゲノム選抜モデル・量的形質座位解析手法の選択 [C7, H1, H2]
- **PhenotypeExpressionModel** (ord=2): 遺伝子型・環境相互作用・表現型発現の推論モデル [H3, H4, H5]
- **GenerationPredictionHypothesis** (ord=1): 世代進行・形質固定確率・育種年限の予測仮説 [H6, H7, H8]
-/

namespace TestCoverage.S437

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s437_p01
  | s437_p02
  | s437_p03
  | s437_p04
  | s437_p05
  | s437_p06
  | s437_p07
  | s437_p08
  | s437_p09
  | s437_p10
  | s437_p11
  | s437_p12
  | s437_p13
  | s437_p14
  | s437_p15
  | s437_p16
  | s437_p17
  | s437_p18
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s437_p01 => []
  | .s437_p02 => []
  | .s437_p03 => [.s437_p01]
  | .s437_p04 => [.s437_p02]
  | .s437_p05 => [.s437_p03, .s437_p04]
  | .s437_p06 => [.s437_p03]
  | .s437_p07 => [.s437_p04]
  | .s437_p08 => [.s437_p06, .s437_p07]
  | .s437_p09 => [.s437_p05]
  | .s437_p10 => [.s437_p06]
  | .s437_p11 => [.s437_p08, .s437_p09]
  | .s437_p12 => [.s437_p09]
  | .s437_p13 => [.s437_p10]
  | .s437_p14 => [.s437_p11, .s437_p12]
  | .s437_p15 => [.s437_p12]
  | .s437_p16 => [.s437_p13, .s437_p15]
  | .s437_p17 => [.s437_p14, .s437_p16]
  | .s437_p18 => [.s437_p15, .s437_p16, .s437_p17]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- メンデル遺伝則・DNA複製メカニズムの不変法則 (ord=6) -/
  | GeneticFundamentalLaw
  /-- 遺伝子組換え規制・生物多様性条約・倫理審査基準 (ord=5) -/
  | BioethicsRegulation
  /-- 目標形質の優先順位・育種目標・選抜基準の方針 (ord=4) -/
  | BreedingObjectivePolicy
  /-- ゲノム選抜モデル・量的形質座位解析手法の選択 (ord=3) -/
  | SimulationModelPolicy
  /-- 遺伝子型・環境相互作用・表現型発現の推論モデル (ord=2) -/
  | PhenotypeExpressionModel
  /-- 世代進行・形質固定確率・育種年限の予測仮説 (ord=1) -/
  | GenerationPredictionHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .GeneticFundamentalLaw => 6
  | .BioethicsRegulation => 5
  | .BreedingObjectivePolicy => 4
  | .SimulationModelPolicy => 3
  | .PhenotypeExpressionModel => 2
  | .GenerationPredictionHypothesis => 1

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
  bottom := .GenerationPredictionHypothesis
  nontrivial := ⟨.GeneticFundamentalLaw, .GenerationPredictionHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨6, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- GeneticFundamentalLaw
  | .s437_p01 | .s437_p02 => .GeneticFundamentalLaw
  -- BioethicsRegulation
  | .s437_p03 | .s437_p04 | .s437_p05 => .BioethicsRegulation
  -- BreedingObjectivePolicy
  | .s437_p06 | .s437_p07 | .s437_p08 => .BreedingObjectivePolicy
  -- SimulationModelPolicy
  | .s437_p09 | .s437_p10 | .s437_p11 => .SimulationModelPolicy
  -- PhenotypeExpressionModel
  | .s437_p12 | .s437_p13 | .s437_p14 => .PhenotypeExpressionModel
  -- GenerationPredictionHypothesis
  | .s437_p15 | .s437_p16 | .s437_p17 | .s437_p18 => .GenerationPredictionHypothesis

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

end TestCoverage.S437
