/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **electoral_law** (ord=4): 選挙法・政治資金規正法・報道規制に基づく法的制約 [C1, C2]
- **methodological_rigor** (ord=3): 統計的手法の厳密性・サンプリング基準・バイアス補正 [C3, C4, H1]
- **analysis_framework** (ord=2): 分析フレームワーク・可視化方針・予測モデル [C5, C6, H2]
- **presentation_config** (ord=1): 表示設定・更新頻度・レポート形式 [C7, H3]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | election_silence_period
  | political_neutrality_obligation
  | sampling_methodology
  | margin_of_error_standard
  | demographic_weighting_model
  | sentiment_analysis_framework
  | prediction_model_selection
  | geographic_breakdown_method
  | confidence_interval_display
  | update_frequency_setting
  | media_embargo_compliance_check
  | historical_comparison_view
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .election_silence_period => []
  | .political_neutrality_obligation => []
  | .sampling_methodology => []
  | .margin_of_error_standard => []
  | .demographic_weighting_model => []
  | .sentiment_analysis_framework => []
  | .prediction_model_selection => []
  | .geographic_breakdown_method => []
  | .confidence_interval_display => []
  | .update_frequency_setting => []
  | .media_embargo_compliance_check => []
  | .historical_comparison_view => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 選挙法・政治資金規正法・報道規制に基づく法的制約 (ord=4) -/
  | electoral_law
  /-- 統計的手法の厳密性・サンプリング基準・バイアス補正 (ord=3) -/
  | methodological_rigor
  /-- 分析フレームワーク・可視化方針・予測モデル (ord=2) -/
  | analysis_framework
  /-- 表示設定・更新頻度・レポート形式 (ord=1) -/
  | presentation_config
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .electoral_law => 4
  | .methodological_rigor => 3
  | .analysis_framework => 2
  | .presentation_config => 1

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
  bottom := .presentation_config
  nontrivial := ⟨.electoral_law, .presentation_config, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- electoral_law
  | .election_silence_period | .political_neutrality_obligation => .electoral_law
  -- methodological_rigor
  | .sampling_methodology | .margin_of_error_standard | .demographic_weighting_model => .methodological_rigor
  -- analysis_framework
  | .sentiment_analysis_framework | .prediction_model_selection | .geographic_breakdown_method => .analysis_framework
  -- presentation_config
  | .confidence_interval_display | .update_frequency_setting | .media_embargo_compliance_check | .historical_comparison_view => .presentation_config

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
