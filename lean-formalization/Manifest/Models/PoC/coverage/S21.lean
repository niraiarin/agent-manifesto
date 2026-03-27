/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **market_constraint** (ord=5): 金融規制・法的制約。変更不可 [C1, C2]
- **data_postulate** (ord=4): 市場データ取得の前提。外部取引所APIに依存 [C3, H1]
- **analysis_principle** (ord=2): 分析ロジックの設計原則。変更可能だが影響大 [C4, C5, H2]
- **display_hypothesis** (ord=0): UI表示の仮説。ユーザーフィードバックで変更 [H3, H4, H5]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | regulatory_compliance
  | no_insider_trading_facilitation
  | realtime_data_available
  | api_latency_under_100ms
  | technical_indicator_accuracy
  | anomaly_detection_threshold
  | chart_refresh_rate
  | color_scheme_for_alerts
  | dashboard_layout
  | risk_warning_display
  | historical_data_retention
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .regulatory_compliance => []
  | .no_insider_trading_facilitation => []
  | .realtime_data_available => []
  | .api_latency_under_100ms => []
  | .technical_indicator_accuracy => []
  | .anomaly_detection_threshold => []
  | .chart_refresh_rate => []
  | .color_scheme_for_alerts => []
  | .dashboard_layout => []
  | .risk_warning_display => []
  | .historical_data_retention => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 金融規制・法的制約。変更不可 (ord=5) -/
  | market_constraint
  /-- 市場データ取得の前提。外部取引所APIに依存 (ord=4) -/
  | data_postulate
  /-- 分析ロジックの設計原則。変更可能だが影響大 (ord=2) -/
  | analysis_principle
  /-- UI表示の仮説。ユーザーフィードバックで変更 (ord=0) -/
  | display_hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .market_constraint => 5
  | .data_postulate => 4
  | .analysis_principle => 2
  | .display_hypothesis => 0

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
  bottom := .display_hypothesis
  nontrivial := ⟨.market_constraint, .display_hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- market_constraint
  | .regulatory_compliance | .no_insider_trading_facilitation | .risk_warning_display => .market_constraint
  -- data_postulate
  | .realtime_data_available | .api_latency_under_100ms | .historical_data_retention => .data_postulate
  -- analysis_principle
  | .technical_indicator_accuracy | .anomaly_detection_threshold => .analysis_principle
  -- display_hypothesis
  | .chart_refresh_rate | .color_scheme_for_alerts | .dashboard_layout => .display_hypothesis

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
