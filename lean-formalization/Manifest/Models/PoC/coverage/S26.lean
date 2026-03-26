/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **compliance_constraint** (ord=5): 法規制・契約上の制約。輸出管理・品質基準 [C1, C2]
- **logistics_postulate** (ord=4): 物流・在庫管理の前提条件 [C3, C4, H1]
- **optimization_principle** (ord=2): 最適化の設計原則。コスト・リードタイム・リスクのバランス [C5, C6, H2]
- **parameter_hypothesis** (ord=0): 最適化パラメータの仮説。実運用で調整 [H3, H4, H5]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | export_control_compliance
  | quality_standard_adherence
  | lead_time_variability
  | multi_tier_supplier_visibility
  | safety_stock_policy
  | single_source_risk_mitigation
  | reorder_point_calculation
  | demand_forecast_horizon
  | transport_mode_selection
  | disruption_scenario_modeling
  | customs_clearance_time
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .export_control_compliance => []
  | .quality_standard_adherence => []
  | .lead_time_variability => []
  | .multi_tier_supplier_visibility => []
  | .safety_stock_policy => []
  | .single_source_risk_mitigation => []
  | .reorder_point_calculation => []
  | .demand_forecast_horizon => []
  | .transport_mode_selection => []
  | .disruption_scenario_modeling => []
  | .customs_clearance_time => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 法規制・契約上の制約。輸出管理・品質基準 (ord=5) -/
  | compliance_constraint
  /-- 物流・在庫管理の前提条件 (ord=4) -/
  | logistics_postulate
  /-- 最適化の設計原則。コスト・リードタイム・リスクのバランス (ord=2) -/
  | optimization_principle
  /-- 最適化パラメータの仮説。実運用で調整 (ord=0) -/
  | parameter_hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .compliance_constraint => 5
  | .logistics_postulate => 4
  | .optimization_principle => 2
  | .parameter_hypothesis => 0

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
  bottom := .parameter_hypothesis
  nontrivial := ⟨.compliance_constraint, .parameter_hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- compliance_constraint
  | .export_control_compliance | .quality_standard_adherence => .compliance_constraint
  -- logistics_postulate
  | .lead_time_variability | .multi_tier_supplier_visibility | .customs_clearance_time => .logistics_postulate
  -- optimization_principle
  | .safety_stock_policy | .single_source_risk_mitigation | .disruption_scenario_modeling => .optimization_principle
  -- parameter_hypothesis
  | .reorder_point_calculation | .demand_forecast_horizon | .transport_mode_selection => .parameter_hypothesis

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
