/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **regulation** (ord=3): 環境法規・水質基準。法的拘束力を持つ不変条件 [C1, C2]
- **ecological_model** (ord=2): 生態学の確立モデル。種間関係・水質指標の科学的知見 [C4, H1, H3]
- **monitoring** (ord=1): センサー配置・サンプリング頻度・アラート閾値の運用方針 [C3, C5, H5]
- **prediction** (ord=0): AI による生態系変動予測。未検証の時系列推論 [H6, H7, H8]
-/

namespace RiverEcosystem

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | reg_water_quality
  | reg_species_protect
  | reg_reporting
  | eco_food_web
  | eco_indicator_sp
  | eco_seasonal
  | eco_pollutant
  | mon_sensor_net
  | mon_sampling
  | mon_alert
  | mon_biodiversity
  | pred_population
  | pred_water_trend
  | pred_invasion
  | pred_restoration
  | pred_climate
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .reg_water_quality => []
  | .reg_species_protect => []
  | .reg_reporting => []
  | .eco_food_web => []
  | .eco_indicator_sp => [.eco_food_web]
  | .eco_seasonal => []
  | .eco_pollutant => [.reg_water_quality]
  | .mon_sensor_net => [.reg_water_quality]
  | .mon_sampling => [.eco_seasonal, .eco_indicator_sp]
  | .mon_alert => [.reg_water_quality, .eco_pollutant]
  | .mon_biodiversity => [.reg_species_protect, .eco_food_web]
  | .pred_population => [.eco_food_web, .mon_sampling]
  | .pred_water_trend => [.mon_sensor_net, .eco_pollutant]
  | .pred_invasion => [.eco_indicator_sp, .mon_biodiversity]
  | .pred_restoration => [.pred_population, .pred_water_trend, .reg_reporting]
  | .pred_climate => [.eco_seasonal, .pred_water_trend]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 環境法規・水質基準。法的拘束力を持つ不変条件 (ord=3) -/
  | regulation
  /-- 生態学の確立モデル。種間関係・水質指標の科学的知見 (ord=2) -/
  | ecological_model
  /-- センサー配置・サンプリング頻度・アラート閾値の運用方針 (ord=1) -/
  | monitoring
  /-- AI による生態系変動予測。未検証の時系列推論 (ord=0) -/
  | prediction
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .regulation => 3
  | .ecological_model => 2
  | .monitoring => 1
  | .prediction => 0

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
  bottom := .prediction
  nontrivial := ⟨.regulation, .prediction, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- regulation
  | .reg_water_quality | .reg_species_protect | .reg_reporting => .regulation
  -- ecological_model
  | .eco_food_web | .eco_indicator_sp | .eco_seasonal | .eco_pollutant => .ecological_model
  -- monitoring
  | .mon_sensor_net | .mon_sampling | .mon_alert | .mon_biodiversity => .monitoring
  -- prediction
  | .pred_population | .pred_water_trend | .pred_invasion | .pred_restoration | .pred_climate => .prediction

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

end RiverEcosystem
