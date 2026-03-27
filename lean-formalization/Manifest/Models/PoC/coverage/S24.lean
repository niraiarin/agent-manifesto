/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **safety_constraint** (ord=5): 車両安全に関わる制約。整備不良による事故防止 [C1, C2]
- **vehicle_postulate** (ord=4): 車両工学の前提。部品劣化モデルとセンサーデータ [C3, H1]
- **maintenance_principle** (ord=2): 整備計画の原則。コストと安全のバランス [C4, C5, H2]
- **scheduling_hypothesis** (ord=0): スケジューリングの仮説。運用データで調整 [H3, H4, H5]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | brake_system_priority
  | recall_compliance
  | obd_data_availability
  | component_degradation_model
  | cost_optimization_target
  | preventive_vs_reactive_ratio
  | oil_change_interval
  | tire_wear_prediction
  | seasonal_maintenance_window
  | parts_inventory_forecast
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .brake_system_priority => []
  | .recall_compliance => []
  | .obd_data_availability => []
  | .component_degradation_model => []
  | .cost_optimization_target => []
  | .preventive_vs_reactive_ratio => []
  | .oil_change_interval => []
  | .tire_wear_prediction => []
  | .seasonal_maintenance_window => []
  | .parts_inventory_forecast => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 車両安全に関わる制約。整備不良による事故防止 (ord=5) -/
  | safety_constraint
  /-- 車両工学の前提。部品劣化モデルとセンサーデータ (ord=4) -/
  | vehicle_postulate
  /-- 整備計画の原則。コストと安全のバランス (ord=2) -/
  | maintenance_principle
  /-- スケジューリングの仮説。運用データで調整 (ord=0) -/
  | scheduling_hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .safety_constraint => 5
  | .vehicle_postulate => 4
  | .maintenance_principle => 2
  | .scheduling_hypothesis => 0

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
  bottom := .scheduling_hypothesis
  nontrivial := ⟨.safety_constraint, .scheduling_hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- safety_constraint
  | .brake_system_priority | .recall_compliance => .safety_constraint
  -- vehicle_postulate
  | .obd_data_availability | .component_degradation_model => .vehicle_postulate
  -- maintenance_principle
  | .cost_optimization_target | .preventive_vs_reactive_ratio | .parts_inventory_forecast => .maintenance_principle
  -- scheduling_hypothesis
  | .oil_change_interval | .tire_wear_prediction | .seasonal_maintenance_window => .scheduling_hypothesis

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
