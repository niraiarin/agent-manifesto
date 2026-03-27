/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **grid_safety_constraint** (ord=5): 電力系統の安全制約。停電防止・周波数維持は絶対 [C1, C2]
- **physical_postulate** (ord=4): 物理法則・電力工学の前提 [C3, H1]
- **regulatory_principle** (ord=3): 電力市場規制と運用ルール [C4, C5]
- **forecast_boundary** (ord=2): 予測モデルの境界条件 [C6, H2, H3]
- **tuning_hypothesis** (ord=0): パラメータ調整の仮説。実運用データで検証 [H4, H5, H6]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | frequency_stability
  | blackout_prevention
  | kirchhoff_laws
  | thermal_limits
  | market_clearing_rules
  | renewable_priority_dispatch
  | weather_dependency
  | demand_seasonality
  | solar_forecast_accuracy
  | wind_ramp_prediction
  | ev_charging_impact
  | reserve_margin_calculation
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .frequency_stability => []
  | .blackout_prevention => []
  | .kirchhoff_laws => []
  | .thermal_limits => []
  | .market_clearing_rules => []
  | .renewable_priority_dispatch => []
  | .weather_dependency => []
  | .demand_seasonality => []
  | .solar_forecast_accuracy => []
  | .wind_ramp_prediction => []
  | .ev_charging_impact => []
  | .reserve_margin_calculation => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 電力系統の安全制約。停電防止・周波数維持は絶対 (ord=5) -/
  | grid_safety_constraint
  /-- 物理法則・電力工学の前提 (ord=4) -/
  | physical_postulate
  /-- 電力市場規制と運用ルール (ord=3) -/
  | regulatory_principle
  /-- 予測モデルの境界条件 (ord=2) -/
  | forecast_boundary
  /-- パラメータ調整の仮説。実運用データで検証 (ord=0) -/
  | tuning_hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .grid_safety_constraint => 5
  | .physical_postulate => 4
  | .regulatory_principle => 3
  | .forecast_boundary => 2
  | .tuning_hypothesis => 0

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
  bottom := .tuning_hypothesis
  nontrivial := ⟨.grid_safety_constraint, .tuning_hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- grid_safety_constraint
  | .frequency_stability | .blackout_prevention => .grid_safety_constraint
  -- physical_postulate
  | .kirchhoff_laws | .thermal_limits => .physical_postulate
  -- regulatory_principle
  | .market_clearing_rules | .renewable_priority_dispatch => .regulatory_principle
  -- forecast_boundary
  | .weather_dependency | .demand_seasonality => .forecast_boundary
  -- tuning_hypothesis
  | .solar_forecast_accuracy | .wind_ramp_prediction | .ev_charging_impact | .reserve_margin_calculation => .tuning_hypothesis

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
