/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **legal_standard** (ord=3): 環境基準法・騒音規制法に基づく測定基準。法的拘束力あり [C1, C2]
- **acoustic_model** (ord=2): 音響伝搬モデル・周波数分析の物理的知見 [C4, H1, H3]
- **measurement** (ord=1): センサー設置・キャリブレーション・レポート生成の運用方針 [C3, C5, H5]
- **prediction** (ord=0): 騒音源特定・影響範囲予測の未検証推論 [H6, H7]
-/

namespace NoisePollution

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | law_db_limit
  | law_time_zone
  | law_report_fmt
  | acou_propagation
  | acou_freq_weight
  | acou_reflection
  | acou_source_sep
  | meas_sensor_place
  | meas_calibration
  | meas_continuous
  | meas_alert
  | pred_source_id
  | pred_impact_map
  | pred_trend
  | pred_mitigation
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .law_db_limit => []
  | .law_time_zone => []
  | .law_report_fmt => []
  | .acou_propagation => []
  | .acou_freq_weight => [.law_db_limit]
  | .acou_reflection => [.acou_propagation]
  | .acou_source_sep => [.acou_propagation, .acou_freq_weight]
  | .meas_sensor_place => [.law_db_limit, .acou_propagation]
  | .meas_calibration => [.law_report_fmt]
  | .meas_continuous => [.law_time_zone, .meas_sensor_place]
  | .meas_alert => [.law_db_limit, .acou_freq_weight]
  | .pred_source_id => [.acou_source_sep, .meas_continuous]
  | .pred_impact_map => [.acou_reflection, .meas_sensor_place]
  | .pred_trend => [.pred_source_id, .pred_impact_map]
  | .pred_mitigation => [.pred_impact_map, .law_db_limit]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 環境基準法・騒音規制法に基づく測定基準。法的拘束力あり (ord=3) -/
  | legal_standard
  /-- 音響伝搬モデル・周波数分析の物理的知見 (ord=2) -/
  | acoustic_model
  /-- センサー設置・キャリブレーション・レポート生成の運用方針 (ord=1) -/
  | measurement
  /-- 騒音源特定・影響範囲予測の未検証推論 (ord=0) -/
  | prediction
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .legal_standard => 3
  | .acoustic_model => 2
  | .measurement => 1
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
  nontrivial := ⟨.legal_standard, .prediction, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- legal_standard
  | .law_db_limit | .law_time_zone | .law_report_fmt => .legal_standard
  -- acoustic_model
  | .acou_propagation | .acou_freq_weight | .acou_reflection | .acou_source_sep => .acoustic_model
  -- measurement
  | .meas_sensor_place | .meas_calibration | .meas_continuous | .meas_alert => .measurement
  -- prediction
  | .pred_source_id | .pred_impact_map | .pred_trend | .pred_mitigation => .prediction

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

end NoisePollution
