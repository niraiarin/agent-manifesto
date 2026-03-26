/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **privacy_ethics** (ord=4): プライバシー保護・同意取得・倫理ガイドラインの法的制約 [C1, C2]
- **recognition_standard** (ord=3): 感情認識精度基準・文化的バイアス補正 [C3, C4, H1]
- **model_design** (ord=2): 認識モデル設計・特徴量抽出・分類手法 [C5, H2]
- **deployment_config** (ord=1): デプロイ設定・閾値調整・ログ管理 [C6, H3]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | informed_consent_requirement
  | data_anonymization_standard
  | recognition_accuracy_baseline
  | cultural_bias_mitigation
  | valence_arousal_model
  | feature_extraction_pipeline
  | classifier_architecture
  | real_time_latency_target
  | confidence_threshold_setting
  | audio_retention_policy
  | fallback_behavior_config
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .informed_consent_requirement => []
  | .data_anonymization_standard => []
  | .recognition_accuracy_baseline => []
  | .cultural_bias_mitigation => []
  | .valence_arousal_model => []
  | .feature_extraction_pipeline => []
  | .classifier_architecture => []
  | .real_time_latency_target => []
  | .confidence_threshold_setting => []
  | .audio_retention_policy => []
  | .fallback_behavior_config => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- プライバシー保護・同意取得・倫理ガイドラインの法的制約 (ord=4) -/
  | privacy_ethics
  /-- 感情認識精度基準・文化的バイアス補正 (ord=3) -/
  | recognition_standard
  /-- 認識モデル設計・特徴量抽出・分類手法 (ord=2) -/
  | model_design
  /-- デプロイ設定・閾値調整・ログ管理 (ord=1) -/
  | deployment_config
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .privacy_ethics => 4
  | .recognition_standard => 3
  | .model_design => 2
  | .deployment_config => 1

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
  bottom := .deployment_config
  nontrivial := ⟨.privacy_ethics, .deployment_config, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- privacy_ethics
  | .informed_consent_requirement | .data_anonymization_standard => .privacy_ethics
  -- recognition_standard
  | .recognition_accuracy_baseline | .cultural_bias_mitigation | .valence_arousal_model => .recognition_standard
  -- model_design
  | .feature_extraction_pipeline | .classifier_architecture | .real_time_latency_target => .model_design
  -- deployment_config
  | .confidence_threshold_setting | .audio_retention_policy | .fallback_behavior_config => .deployment_config

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
