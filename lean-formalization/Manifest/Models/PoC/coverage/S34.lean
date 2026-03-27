/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **traffic_regulation** (ord=4): 道路交通法・信号制御の法的制約 [C1, C2]
- **safety_constraint** (ord=3): 安全性の数値基準と緊急車両対応 [C3, H1]
- **optimization_model** (ord=2): 信号タイミング最適化アルゴリズムとパラメータ [C4, C5, H2]
- **operational_tuning** (ord=1): 時間帯別調整・天候対応・モニタリング設定 [C6, H3]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | minimum_green_duration
  | pedestrian_phase_requirement
  | emergency_vehicle_preemption
  | collision_avoidance_clearance
  | flow_optimization_objective
  | cycle_length_bounds
  | adaptive_algorithm_selection
  | peak_hour_profile
  | weather_adjustment_factor
  | sensor_health_monitoring
  | dashboard_refresh_rate
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .minimum_green_duration => []
  | .pedestrian_phase_requirement => []
  | .emergency_vehicle_preemption => []
  | .collision_avoidance_clearance => []
  | .flow_optimization_objective => []
  | .cycle_length_bounds => []
  | .adaptive_algorithm_selection => []
  | .peak_hour_profile => []
  | .weather_adjustment_factor => []
  | .sensor_health_monitoring => []
  | .dashboard_refresh_rate => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 道路交通法・信号制御の法的制約 (ord=4) -/
  | traffic_regulation
  /-- 安全性の数値基準と緊急車両対応 (ord=3) -/
  | safety_constraint
  /-- 信号タイミング最適化アルゴリズムとパラメータ (ord=2) -/
  | optimization_model
  /-- 時間帯別調整・天候対応・モニタリング設定 (ord=1) -/
  | operational_tuning
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .traffic_regulation => 4
  | .safety_constraint => 3
  | .optimization_model => 2
  | .operational_tuning => 1

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
  bottom := .operational_tuning
  nontrivial := ⟨.traffic_regulation, .operational_tuning, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- traffic_regulation
  | .minimum_green_duration | .pedestrian_phase_requirement => .traffic_regulation
  -- safety_constraint
  | .emergency_vehicle_preemption | .collision_avoidance_clearance => .safety_constraint
  -- optimization_model
  | .flow_optimization_objective | .cycle_length_bounds | .adaptive_algorithm_selection => .optimization_model
  -- operational_tuning
  | .peak_hour_profile | .weather_adjustment_factor | .sensor_health_monitoring | .dashboard_refresh_rate => .operational_tuning

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
