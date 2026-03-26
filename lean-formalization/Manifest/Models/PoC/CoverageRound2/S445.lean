/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **ContractualObligationInvariant** (ord=4): SLA契約条件・ペナルティ条項・最低保証水準の絶対不変条件 [C1, C2]
- **MonitoringDetectionPolicy** (ord=3): リアルタイム監視・閾値アラート・エスカレーション手順の方針 [C3, H1]
- **PredictiveAnalyticsPolicy** (ord=2): 機械学習による違反予測・異常検知・根本原因分析の運用方針 [C4, H2, H3]
- **RemediationHypothesis** (ord=1): 自動修復アクション・リソース再配分・フェイルオーバー効果の仮説 [C5, H4, H5, H6, H7]
-/

namespace TestCoverage.S445

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s445_p01
  | s445_p02
  | s445_p03
  | s445_p04
  | s445_p05
  | s445_p06
  | s445_p07
  | s445_p08
  | s445_p09
  | s445_p10
  | s445_p11
  | s445_p12
  | s445_p13
  | s445_p14
  | s445_p15
  | s445_p16
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s445_p01 => []
  | .s445_p02 => [.s445_p01]
  | .s445_p03 => [.s445_p01]
  | .s445_p04 => [.s445_p02, .s445_p03]
  | .s445_p05 => [.s445_p03]
  | .s445_p06 => [.s445_p04]
  | .s445_p07 => [.s445_p05, .s445_p06]
  | .s445_p08 => [.s445_p06, .s445_p07]
  | .s445_p09 => [.s445_p05]
  | .s445_p10 => [.s445_p06]
  | .s445_p11 => [.s445_p07, .s445_p09]
  | .s445_p12 => [.s445_p10]
  | .s445_p13 => [.s445_p08, .s445_p11]
  | .s445_p14 => [.s445_p12, .s445_p13]
  | .s445_p15 => [.s445_p11, .s445_p12]
  | .s445_p16 => [.s445_p14, .s445_p15]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- SLA契約条件・ペナルティ条項・最低保証水準の絶対不変条件 (ord=4) -/
  | ContractualObligationInvariant
  /-- リアルタイム監視・閾値アラート・エスカレーション手順の方針 (ord=3) -/
  | MonitoringDetectionPolicy
  /-- 機械学習による違反予測・異常検知・根本原因分析の運用方針 (ord=2) -/
  | PredictiveAnalyticsPolicy
  /-- 自動修復アクション・リソース再配分・フェイルオーバー効果の仮説 (ord=1) -/
  | RemediationHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .ContractualObligationInvariant => 4
  | .MonitoringDetectionPolicy => 3
  | .PredictiveAnalyticsPolicy => 2
  | .RemediationHypothesis => 1

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
  bottom := .RemediationHypothesis
  nontrivial := ⟨.ContractualObligationInvariant, .RemediationHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- ContractualObligationInvariant
  | .s445_p01 | .s445_p02 => .ContractualObligationInvariant
  -- MonitoringDetectionPolicy
  | .s445_p03 | .s445_p04 => .MonitoringDetectionPolicy
  -- PredictiveAnalyticsPolicy
  | .s445_p05 | .s445_p06 | .s445_p07 | .s445_p08 => .PredictiveAnalyticsPolicy
  -- RemediationHypothesis
  | .s445_p09 | .s445_p10 | .s445_p11 | .s445_p12 | .s445_p13 | .s445_p14 | .s445_p15 | .s445_p16 => .RemediationHypothesis

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

end TestCoverage.S445
