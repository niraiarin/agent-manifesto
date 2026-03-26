/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **resident_safety_constraint** (ord=5): 入居者の生命・尊厳の保護。絶対的制約 [C1, C2]
- **privacy_postulate** (ord=4): プライバシー・個人情報保護の前提 [C3, C4]
- **care_principle** (ord=3): 介護の原則。人間の介護者との協働 [C5, C6, H1]
- **monitoring_boundary** (ord=2): 見守りの境界条件。センサーと判定基準 [C7, H2, H3]
- **alert_hypothesis** (ord=0): アラート設定の仮説。運用で調整 [H4, H5]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | fall_detection_immediate
  | dignity_preservation
  | camera_placement_consent
  | data_retention_policy
  | staff_notification_protocol
  | human_verification_required
  | sensor_coverage_map
  | nighttime_monitoring_mode
  | wandering_alert_threshold
  | vital_sign_anomaly_level
  | emergency_call_trigger
  | family_notification_rule
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .fall_detection_immediate => []
  | .dignity_preservation => []
  | .camera_placement_consent => []
  | .data_retention_policy => []
  | .staff_notification_protocol => []
  | .human_verification_required => []
  | .sensor_coverage_map => []
  | .nighttime_monitoring_mode => []
  | .wandering_alert_threshold => []
  | .vital_sign_anomaly_level => []
  | .emergency_call_trigger => []
  | .family_notification_rule => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 入居者の生命・尊厳の保護。絶対的制約 (ord=5) -/
  | resident_safety_constraint
  /-- プライバシー・個人情報保護の前提 (ord=4) -/
  | privacy_postulate
  /-- 介護の原則。人間の介護者との協働 (ord=3) -/
  | care_principle
  /-- 見守りの境界条件。センサーと判定基準 (ord=2) -/
  | monitoring_boundary
  /-- アラート設定の仮説。運用で調整 (ord=0) -/
  | alert_hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .resident_safety_constraint => 5
  | .privacy_postulate => 4
  | .care_principle => 3
  | .monitoring_boundary => 2
  | .alert_hypothesis => 0

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
  bottom := .alert_hypothesis
  nontrivial := ⟨.resident_safety_constraint, .alert_hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- resident_safety_constraint
  | .fall_detection_immediate | .dignity_preservation | .emergency_call_trigger => .resident_safety_constraint
  -- privacy_postulate
  | .camera_placement_consent | .data_retention_policy => .privacy_postulate
  -- care_principle
  | .staff_notification_protocol | .human_verification_required | .family_notification_rule => .care_principle
  -- monitoring_boundary
  | .sensor_coverage_map | .nighttime_monitoring_mode => .monitoring_boundary
  -- alert_hypothesis
  | .wandering_alert_threshold | .vital_sign_anomaly_level => .alert_hypothesis

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
