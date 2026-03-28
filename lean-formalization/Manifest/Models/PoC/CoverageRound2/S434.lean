/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **BiologicalGrowthInvariant** (ord=4): 作物の生育ステージ・積算温度・生物学的成熟限界 [C1, C2]
- **MarketQualityStandard** (ord=3): 出荷品質基準・糖度・硬度・外観規格 [C3, C4]
- **HarvestSchedulingPolicy** (ord=2): 収穫作業計画・労働力配分・機械使用スケジュール [C5, H1, H2]
- **WeatherForecastHypothesis** (ord=1): 気象予報・降雨確率・気温変動の予測仮説 [H3, H4, H5]
-/

namespace TestCoverage.S434

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s434_p01
  | s434_p02
  | s434_p03
  | s434_p04
  | s434_p05
  | s434_p06
  | s434_p07
  | s434_p08
  | s434_p09
  | s434_p10
  | s434_p11
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s434_p01 => []
  | .s434_p02 => []
  | .s434_p03 => [.s434_p01]
  | .s434_p04 => [.s434_p02]
  | .s434_p05 => [.s434_p03, .s434_p04]
  | .s434_p06 => [.s434_p03]
  | .s434_p07 => [.s434_p04]
  | .s434_p08 => [.s434_p05, .s434_p06]
  | .s434_p09 => [.s434_p06]
  | .s434_p10 => [.s434_p07, .s434_p09]
  | .s434_p11 => [.s434_p08, .s434_p10]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 作物の生育ステージ・積算温度・生物学的成熟限界 (ord=4) -/
  | BiologicalGrowthInvariant
  /-- 出荷品質基準・糖度・硬度・外観規格 (ord=3) -/
  | MarketQualityStandard
  /-- 収穫作業計画・労働力配分・機械使用スケジュール (ord=2) -/
  | HarvestSchedulingPolicy
  /-- 気象予報・降雨確率・気温変動の予測仮説 (ord=1) -/
  | WeatherForecastHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .BiologicalGrowthInvariant => 4
  | .MarketQualityStandard => 3
  | .HarvestSchedulingPolicy => 2
  | .WeatherForecastHypothesis => 1

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
  bottom := .WeatherForecastHypothesis
  nontrivial := ⟨.BiologicalGrowthInvariant, .WeatherForecastHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- BiologicalGrowthInvariant
  | .s434_p01 | .s434_p02 => .BiologicalGrowthInvariant
  -- MarketQualityStandard
  | .s434_p03 | .s434_p04 | .s434_p05 => .MarketQualityStandard
  -- HarvestSchedulingPolicy
  | .s434_p06 | .s434_p07 | .s434_p08 => .HarvestSchedulingPolicy
  -- WeatherForecastHypothesis
  | .s434_p09 | .s434_p10 | .s434_p11 => .WeatherForecastHypothesis

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

end TestCoverage.S434
