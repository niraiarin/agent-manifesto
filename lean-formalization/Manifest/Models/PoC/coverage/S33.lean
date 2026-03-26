/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **food_safety_law** (ord=4): 食品衛生法・アレルゲン表示義務に基づく法的制約 [C1, C2]
- **detection_standard** (ord=3): 検出精度・感度基準と検証プロトコル [C3, C4, H1]
- **operational_protocol** (ord=2): 検査運用手順・サンプリング方法・判定フロー [C5, C6, H2]
- **reporting_config** (ord=1): レポート形式・通知設定・ログ管理 [C7, H3]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | mandatory_allergen_list
  | labeling_obligation
  | detection_sensitivity_threshold
  | false_negative_tolerance
  | cross_contamination_model
  | sampling_frequency
  | human_review_gate
  | sensor_calibration_schedule
  | alert_escalation_rule
  | batch_traceability_log
  | recall_trigger_threshold
  | regulatory_report_format
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .mandatory_allergen_list => []
  | .labeling_obligation => []
  | .detection_sensitivity_threshold => []
  | .false_negative_tolerance => []
  | .cross_contamination_model => []
  | .sampling_frequency => []
  | .human_review_gate => []
  | .sensor_calibration_schedule => []
  | .alert_escalation_rule => []
  | .batch_traceability_log => []
  | .recall_trigger_threshold => []
  | .regulatory_report_format => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 食品衛生法・アレルゲン表示義務に基づく法的制約 (ord=4) -/
  | food_safety_law
  /-- 検出精度・感度基準と検証プロトコル (ord=3) -/
  | detection_standard
  /-- 検査運用手順・サンプリング方法・判定フロー (ord=2) -/
  | operational_protocol
  /-- レポート形式・通知設定・ログ管理 (ord=1) -/
  | reporting_config
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .food_safety_law => 4
  | .detection_standard => 3
  | .operational_protocol => 2
  | .reporting_config => 1

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
  bottom := .reporting_config
  nontrivial := ⟨.food_safety_law, .reporting_config, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- food_safety_law
  | .mandatory_allergen_list | .labeling_obligation => .food_safety_law
  -- detection_standard
  | .detection_sensitivity_threshold | .false_negative_tolerance | .cross_contamination_model => .detection_standard
  -- operational_protocol
  | .sampling_frequency | .human_review_gate | .sensor_calibration_schedule => .operational_protocol
  -- reporting_config
  | .alert_escalation_rule | .batch_traceability_log | .recall_trigger_threshold | .regulatory_report_format => .reporting_config

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
