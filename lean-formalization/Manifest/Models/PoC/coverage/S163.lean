/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **safetyRegulation** (ord=4): 消防法・バリアフリー法等の法的義務 [C1]
- **stationTopology** (ord=3): 駅構造の物理的制約と通路接続 [C2, H1]
- **accessibilityPolicy** (ord=2): 障害者・高齢者への経路案内ポリシー [C3, H2]
- **congestionModel** (ord=1): 混雑度推定と動的経路切替 [H3, H4]
- **personalPreference** (ord=0): ユーザー個人の好みと学習 [H5]
-/

namespace TestScenario.S163

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | emergencyEvacRoute
  | barrierFreeObligation
  | platformConnectivity
  | elevatorLocation
  | gatePassageWidth
  | wheelchairRoute
  | visualGuidance
  | signLanguageSupport
  | peakHourReroute
  | realTimeDensity
  | transferTimeEstimate
  | preferredExit
  | walkSpeedAdapt
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .emergencyEvacRoute => []
  | .barrierFreeObligation => []
  | .platformConnectivity => [.emergencyEvacRoute]
  | .elevatorLocation => [.barrierFreeObligation]
  | .gatePassageWidth => [.emergencyEvacRoute]
  | .wheelchairRoute => [.barrierFreeObligation, .elevatorLocation]
  | .visualGuidance => [.platformConnectivity]
  | .signLanguageSupport => [.wheelchairRoute]
  | .peakHourReroute => [.platformConnectivity, .gatePassageWidth]
  | .realTimeDensity => [.peakHourReroute]
  | .transferTimeEstimate => [.platformConnectivity, .realTimeDensity]
  | .preferredExit => [.peakHourReroute, .transferTimeEstimate]
  | .walkSpeedAdapt => [.realTimeDensity]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 消防法・バリアフリー法等の法的義務 (ord=4) -/
  | safetyRegulation
  /-- 駅構造の物理的制約と通路接続 (ord=3) -/
  | stationTopology
  /-- 障害者・高齢者への経路案内ポリシー (ord=2) -/
  | accessibilityPolicy
  /-- 混雑度推定と動的経路切替 (ord=1) -/
  | congestionModel
  /-- ユーザー個人の好みと学習 (ord=0) -/
  | personalPreference
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .safetyRegulation => 4
  | .stationTopology => 3
  | .accessibilityPolicy => 2
  | .congestionModel => 1
  | .personalPreference => 0

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
  bottom := .personalPreference
  nontrivial := ⟨.safetyRegulation, .personalPreference, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- safetyRegulation
  | .emergencyEvacRoute | .barrierFreeObligation => .safetyRegulation
  -- stationTopology
  | .platformConnectivity | .elevatorLocation | .gatePassageWidth => .stationTopology
  -- accessibilityPolicy
  | .wheelchairRoute | .visualGuidance | .signLanguageSupport => .accessibilityPolicy
  -- congestionModel
  | .peakHourReroute | .realTimeDensity | .transferTimeEstimate => .congestionModel
  -- personalPreference
  | .preferredExit | .walkSpeedAdapt => .personalPreference

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

end TestScenario.S163
