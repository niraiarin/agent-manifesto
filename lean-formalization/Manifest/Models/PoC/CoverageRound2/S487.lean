/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **WaterResourceInvariant** (ord=5): 地下水枯渇・生態系破壊を防ぐ取水量の絶対上限 [C1]
- **RegulatoryWaterRightPolicy** (ord=4): 河川法・農業用水権・環境影響評価への適合要件 [C2, C3]
- **IrrigationSchedulePolicy** (ord=3): 作物の水ストレス回避・省水効率・施肥連携の灌漑方針 [C4, C5]
- **SoilMoistureModel** (ord=2): 土壌水分・蒸発散量・根域分布のモデル推論 [H1, H2, H3]
- **YieldPredictionHypothesis** (ord=1): 収量・品質・病害リスクに関する予測仮説 [H4, H5, H6]
-/

namespace TestCoverage.S487

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s487_p01
  | s487_p02
  | s487_p03
  | s487_p04
  | s487_p05
  | s487_p06
  | s487_p07
  | s487_p08
  | s487_p09
  | s487_p10
  | s487_p11
  | s487_p12
  | s487_p13
  | s487_p14
  | s487_p15
  | s487_p16
  | s487_p17
  | s487_p18
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s487_p01 => []
  | .s487_p02 => [.s487_p01]
  | .s487_p03 => [.s487_p01]
  | .s487_p04 => [.s487_p01]
  | .s487_p05 => [.s487_p03, .s487_p04]
  | .s487_p06 => [.s487_p02]
  | .s487_p07 => [.s487_p05]
  | .s487_p08 => [.s487_p06, .s487_p07]
  | .s487_p09 => [.s487_p06]
  | .s487_p10 => [.s487_p07]
  | .s487_p11 => [.s487_p08, .s487_p09]
  | .s487_p12 => [.s487_p09, .s487_p10, .s487_p11]
  | .s487_p13 => [.s487_p09]
  | .s487_p14 => [.s487_p10]
  | .s487_p15 => [.s487_p11, .s487_p13]
  | .s487_p16 => [.s487_p13, .s487_p14]
  | .s487_p17 => [.s487_p14, .s487_p15]
  | .s487_p18 => [.s487_p16, .s487_p17]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 地下水枯渇・生態系破壊を防ぐ取水量の絶対上限 (ord=5) -/
  | WaterResourceInvariant
  /-- 河川法・農業用水権・環境影響評価への適合要件 (ord=4) -/
  | RegulatoryWaterRightPolicy
  /-- 作物の水ストレス回避・省水効率・施肥連携の灌漑方針 (ord=3) -/
  | IrrigationSchedulePolicy
  /-- 土壌水分・蒸発散量・根域分布のモデル推論 (ord=2) -/
  | SoilMoistureModel
  /-- 収量・品質・病害リスクに関する予測仮説 (ord=1) -/
  | YieldPredictionHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .WaterResourceInvariant => 5
  | .RegulatoryWaterRightPolicy => 4
  | .IrrigationSchedulePolicy => 3
  | .SoilMoistureModel => 2
  | .YieldPredictionHypothesis => 1

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
  bottom := .YieldPredictionHypothesis
  nontrivial := ⟨.WaterResourceInvariant, .YieldPredictionHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- WaterResourceInvariant
  | .s487_p01 | .s487_p02 => .WaterResourceInvariant
  -- RegulatoryWaterRightPolicy
  | .s487_p03 | .s487_p04 | .s487_p05 => .RegulatoryWaterRightPolicy
  -- IrrigationSchedulePolicy
  | .s487_p06 | .s487_p07 | .s487_p08 => .IrrigationSchedulePolicy
  -- SoilMoistureModel
  | .s487_p09 | .s487_p10 | .s487_p11 | .s487_p12 => .SoilMoistureModel
  -- YieldPredictionHypothesis
  | .s487_p13 | .s487_p14 | .s487_p15 | .s487_p16 | .s487_p17 | .s487_p18 => .YieldPredictionHypothesis

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

end TestCoverage.S487
