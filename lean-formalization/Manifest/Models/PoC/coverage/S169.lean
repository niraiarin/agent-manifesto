/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **hydrologicPrinciple** (ord=4): 河川水理学・海洋潮汐の基本法則 [C1]
- **sedimentTransport** (ord=3): 堆積物輸送の物理モデルと経験式 [C2, H1]
- **monitoringInfra** (ord=2): 観測機器配置と測定プロトコル [H2, H3]
- **floodRiskAssess** (ord=1): 洪水リスク評価と浚渫優先度決定 [H4, C3]
- **reportSchedule** (ord=0): 定期報告サイクルと異常通知閾値 [H5]
-/

namespace TestScenario.S169

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | massConservation
  | tidalForcing
  | salinityGradient
  | bedloadFormula
  | suspendedLoadCalc
  | flocculationModel
  | bathymetrySurvey
  | turbidityProbe
  | adcpDeployment
  | channelNarrowingDetect
  | dredgePriority
  | stormSurgeOverlay
  | monthlyTrendReport
  | anomalyAlert
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .massConservation => []
  | .tidalForcing => []
  | .salinityGradient => []
  | .bedloadFormula => [.massConservation]
  | .suspendedLoadCalc => [.massConservation, .tidalForcing]
  | .flocculationModel => [.salinityGradient, .suspendedLoadCalc]
  | .bathymetrySurvey => [.bedloadFormula]
  | .turbidityProbe => [.suspendedLoadCalc]
  | .adcpDeployment => [.tidalForcing, .bathymetrySurvey]
  | .channelNarrowingDetect => [.bathymetrySurvey, .bedloadFormula]
  | .dredgePriority => [.channelNarrowingDetect, .flocculationModel]
  | .stormSurgeOverlay => [.tidalForcing, .channelNarrowingDetect]
  | .monthlyTrendReport => [.turbidityProbe, .channelNarrowingDetect]
  | .anomalyAlert => [.dredgePriority, .stormSurgeOverlay]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 河川水理学・海洋潮汐の基本法則 (ord=4) -/
  | hydrologicPrinciple
  /-- 堆積物輸送の物理モデルと経験式 (ord=3) -/
  | sedimentTransport
  /-- 観測機器配置と測定プロトコル (ord=2) -/
  | monitoringInfra
  /-- 洪水リスク評価と浚渫優先度決定 (ord=1) -/
  | floodRiskAssess
  /-- 定期報告サイクルと異常通知閾値 (ord=0) -/
  | reportSchedule
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .hydrologicPrinciple => 4
  | .sedimentTransport => 3
  | .monitoringInfra => 2
  | .floodRiskAssess => 1
  | .reportSchedule => 0

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
  bottom := .reportSchedule
  nontrivial := ⟨.hydrologicPrinciple, .reportSchedule, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- hydrologicPrinciple
  | .massConservation | .tidalForcing | .salinityGradient => .hydrologicPrinciple
  -- sedimentTransport
  | .bedloadFormula | .suspendedLoadCalc | .flocculationModel => .sedimentTransport
  -- monitoringInfra
  | .bathymetrySurvey | .turbidityProbe | .adcpDeployment => .monitoringInfra
  -- floodRiskAssess
  | .channelNarrowingDetect | .dredgePriority | .stormSurgeOverlay => .floodRiskAssess
  -- reportSchedule
  | .monthlyTrendReport | .anomalyAlert => .reportSchedule

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

end TestScenario.S169
