/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **safety_constraint** (ord=6): 人命に関わる予測下限保証 [C1]
- **institutional_rule** (ord=5): 気象庁・自治体との制度的整合 [C3, C4]
- **forecast_standard** (ord=4): 予測品質・リードタイム基準 [C2, C5]
- **data_pipeline** (ord=3): 入力データ・前処理の方式 [H2]
- **ensemble_config** (ord=2): アンサンブル構成・統計処理の選択 [H1, H4]
- **physics_model** (ord=1): 物理モデル・非線形効果の仮説 [H3]
-/

namespace StormSurgePrediction

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | no_underpredict
  | mayor_authority
  | jma_consistency
  | lead_time_6h
  | uncertainty_band
  | gpv_initial
  | tide_gauge_feed
  | upper_percentile
  | bootstrap_ci
  | nonlinear_coupling
  | wave_setup_effect
  | surge_wind_drag
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .no_underpredict => []
  | .mayor_authority => [.no_underpredict]
  | .jma_consistency => [.no_underpredict]
  | .lead_time_6h => [.no_underpredict, .jma_consistency]
  | .uncertainty_band => [.no_underpredict]
  | .gpv_initial => [.jma_consistency]
  | .tide_gauge_feed => [.lead_time_6h]
  | .upper_percentile => [.uncertainty_band, .gpv_initial]
  | .bootstrap_ci => [.uncertainty_band]
  | .nonlinear_coupling => [.gpv_initial, .tide_gauge_feed]
  | .wave_setup_effect => [.nonlinear_coupling]
  | .surge_wind_drag => [.nonlinear_coupling, .upper_percentile]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 人命に関わる予測下限保証 (ord=6) -/
  | safety_constraint
  /-- 気象庁・自治体との制度的整合 (ord=5) -/
  | institutional_rule
  /-- 予測品質・リードタイム基準 (ord=4) -/
  | forecast_standard
  /-- 入力データ・前処理の方式 (ord=3) -/
  | data_pipeline
  /-- アンサンブル構成・統計処理の選択 (ord=2) -/
  | ensemble_config
  /-- 物理モデル・非線形効果の仮説 (ord=1) -/
  | physics_model
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .safety_constraint => 6
  | .institutional_rule => 5
  | .forecast_standard => 4
  | .data_pipeline => 3
  | .ensemble_config => 2
  | .physics_model => 1

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
  bottom := .physics_model
  nontrivial := ⟨.safety_constraint, .physics_model, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨6, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- safety_constraint
  | .no_underpredict => .safety_constraint
  -- institutional_rule
  | .mayor_authority | .jma_consistency => .institutional_rule
  -- forecast_standard
  | .lead_time_6h | .uncertainty_band => .forecast_standard
  -- data_pipeline
  | .gpv_initial | .tide_gauge_feed => .data_pipeline
  -- ensemble_config
  | .upper_percentile | .bootstrap_ci => .ensemble_config
  -- physics_model
  | .nonlinear_coupling | .wave_setup_effect | .surge_wind_drag => .physics_model

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

end StormSurgePrediction
