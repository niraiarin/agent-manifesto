/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **environmental_regulation** (ord=4): 海洋汚染防止法・国際海事条約に基づく法的制約 [C1, C2]
- **monitoring_standard** (ord=3): 汚染物質検出基準・測定精度・校正要件 [C3, C4, H1]
- **detection_method** (ord=2): 検出アルゴリズム・データフュージョン・空間分析 [C5, H2]
- **operational_config** (ord=1): 運用設定・アラート・レポート・ログ管理 [C6, H3]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | marpol_compliance
  | pollution_reporting_obligation
  | contaminant_detection_limit
  | sensor_accuracy_requirement
  | baseline_water_quality_model
  | oil_spill_detection_algorithm
  | multi_sensor_fusion_method
  | spatial_interpolation_model
  | alert_priority_classification
  | buoy_maintenance_schedule
  | data_archive_retention
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .marpol_compliance => []
  | .pollution_reporting_obligation => []
  | .contaminant_detection_limit => []
  | .sensor_accuracy_requirement => []
  | .baseline_water_quality_model => []
  | .oil_spill_detection_algorithm => []
  | .multi_sensor_fusion_method => []
  | .spatial_interpolation_model => []
  | .alert_priority_classification => []
  | .buoy_maintenance_schedule => []
  | .data_archive_retention => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 海洋汚染防止法・国際海事条約に基づく法的制約 (ord=4) -/
  | environmental_regulation
  /-- 汚染物質検出基準・測定精度・校正要件 (ord=3) -/
  | monitoring_standard
  /-- 検出アルゴリズム・データフュージョン・空間分析 (ord=2) -/
  | detection_method
  /-- 運用設定・アラート・レポート・ログ管理 (ord=1) -/
  | operational_config
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .environmental_regulation => 4
  | .monitoring_standard => 3
  | .detection_method => 2
  | .operational_config => 1

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
  bottom := .operational_config
  nontrivial := ⟨.environmental_regulation, .operational_config, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- environmental_regulation
  | .marpol_compliance | .pollution_reporting_obligation => .environmental_regulation
  -- monitoring_standard
  | .contaminant_detection_limit | .sensor_accuracy_requirement | .baseline_water_quality_model => .monitoring_standard
  -- detection_method
  | .oil_spill_detection_algorithm | .multi_sensor_fusion_method | .spatial_interpolation_model => .detection_method
  -- operational_config
  | .alert_priority_classification | .buoy_maintenance_schedule | .data_archive_retention => .operational_config

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
