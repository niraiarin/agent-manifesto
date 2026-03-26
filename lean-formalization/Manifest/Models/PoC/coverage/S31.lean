/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **physical_law** (ord=4): 物理法則・軌道力学に基づく不変の制約 [C1, C2]
- **sensor_calibration** (ord=3): センサーの較正基準と精度保証 [C3, H1]
- **analysis_policy** (ord=2): 画像解析アルゴリズムの選定・パラメータ方針 [C4, C5, H2]
- **operational_config** (ord=1): 運用上の設定・閾値・レポート形式 [C6, H3]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | orbital_mechanics_invariant
  | spectral_band_definition
  | radiometric_calibration
  | atmospheric_correction_model
  | change_detection_algorithm
  | classification_taxonomy
  | minimum_resolution_threshold
  | cloud_masking_strategy
  | revisit_frequency_target
  | alert_threshold_config
  | report_format_standard
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .orbital_mechanics_invariant => []
  | .spectral_band_definition => []
  | .radiometric_calibration => []
  | .atmospheric_correction_model => []
  | .change_detection_algorithm => []
  | .classification_taxonomy => []
  | .minimum_resolution_threshold => []
  | .cloud_masking_strategy => []
  | .revisit_frequency_target => []
  | .alert_threshold_config => []
  | .report_format_standard => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 物理法則・軌道力学に基づく不変の制約 (ord=4) -/
  | physical_law
  /-- センサーの較正基準と精度保証 (ord=3) -/
  | sensor_calibration
  /-- 画像解析アルゴリズムの選定・パラメータ方針 (ord=2) -/
  | analysis_policy
  /-- 運用上の設定・閾値・レポート形式 (ord=1) -/
  | operational_config
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .physical_law => 4
  | .sensor_calibration => 3
  | .analysis_policy => 2
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
  nontrivial := ⟨.physical_law, .operational_config, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- physical_law
  | .orbital_mechanics_invariant | .spectral_band_definition => .physical_law
  -- sensor_calibration
  | .radiometric_calibration | .atmospheric_correction_model => .sensor_calibration
  -- analysis_policy
  | .change_detection_algorithm | .classification_taxonomy | .minimum_resolution_threshold => .analysis_policy
  -- operational_config
  | .cloud_masking_strategy | .revisit_frequency_target | .alert_threshold_config | .report_format_standard => .operational_config

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
