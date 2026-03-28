/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **PhysicalNetworkLaw** (ord=7): シャノン容量定理・電磁干渉法規・周波数割当の物理法則 [C1, C2]
- **TelecomRegulation** (ord=6): 電気通信事業法・総務省周波数管理規制・SLA法的義務 [C3, C4]
- **QoSGuaranteeStandard** (ord=5): 遅延・ジッタ・パケットロス率の品質保証基準 [C5, C6]
- **TrafficManagementPolicy** (ord=4): トラフィッククラス優先度・輻輳制御・ルーティングポリシー [C7, H1]
- **ResourceAllocationPolicy** (ord=3): 帯域幅割当アルゴリズム・動的再配分・利用率目標 [H2, H3]
- **PredictiveOptimizationModel** (ord=2): トラフィック需要予測・ボトルネック特定の推論モデル [H4, H5, H6]
- **AdaptiveLearningHypothesis** (ord=1): 利用パターン学習・自律的最適化に関する適応仮説 [H7, H8]
-/

namespace TestCoverage.S440

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s440_p01
  | s440_p02
  | s440_p03
  | s440_p04
  | s440_p05
  | s440_p06
  | s440_p07
  | s440_p08
  | s440_p09
  | s440_p10
  | s440_p11
  | s440_p12
  | s440_p13
  | s440_p14
  | s440_p15
  | s440_p16
  | s440_p17
  | s440_p18
  | s440_p19
  | s440_p20
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s440_p01 => []
  | .s440_p02 => []
  | .s440_p03 => [.s440_p01]
  | .s440_p04 => [.s440_p02]
  | .s440_p05 => [.s440_p03, .s440_p04]
  | .s440_p06 => [.s440_p03]
  | .s440_p07 => [.s440_p04]
  | .s440_p08 => [.s440_p06, .s440_p07]
  | .s440_p09 => [.s440_p05]
  | .s440_p10 => [.s440_p06, .s440_p09]
  | .s440_p11 => [.s440_p08, .s440_p10]
  | .s440_p12 => [.s440_p09]
  | .s440_p13 => [.s440_p10]
  | .s440_p14 => [.s440_p11, .s440_p12]
  | .s440_p15 => [.s440_p12]
  | .s440_p16 => [.s440_p13]
  | .s440_p17 => [.s440_p14, .s440_p15]
  | .s440_p18 => [.s440_p15]
  | .s440_p19 => [.s440_p16, .s440_p18]
  | .s440_p20 => [.s440_p17, .s440_p19]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- シャノン容量定理・電磁干渉法規・周波数割当の物理法則 (ord=7) -/
  | PhysicalNetworkLaw
  /-- 電気通信事業法・総務省周波数管理規制・SLA法的義務 (ord=6) -/
  | TelecomRegulation
  /-- 遅延・ジッタ・パケットロス率の品質保証基準 (ord=5) -/
  | QoSGuaranteeStandard
  /-- トラフィッククラス優先度・輻輳制御・ルーティングポリシー (ord=4) -/
  | TrafficManagementPolicy
  /-- 帯域幅割当アルゴリズム・動的再配分・利用率目標 (ord=3) -/
  | ResourceAllocationPolicy
  /-- トラフィック需要予測・ボトルネック特定の推論モデル (ord=2) -/
  | PredictiveOptimizationModel
  /-- 利用パターン学習・自律的最適化に関する適応仮説 (ord=1) -/
  | AdaptiveLearningHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .PhysicalNetworkLaw => 7
  | .TelecomRegulation => 6
  | .QoSGuaranteeStandard => 5
  | .TrafficManagementPolicy => 4
  | .ResourceAllocationPolicy => 3
  | .PredictiveOptimizationModel => 2
  | .AdaptiveLearningHypothesis => 1

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
  bottom := .AdaptiveLearningHypothesis
  nontrivial := ⟨.PhysicalNetworkLaw, .AdaptiveLearningHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨7, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- PhysicalNetworkLaw
  | .s440_p01 | .s440_p02 => .PhysicalNetworkLaw
  -- TelecomRegulation
  | .s440_p03 | .s440_p04 | .s440_p05 => .TelecomRegulation
  -- QoSGuaranteeStandard
  | .s440_p06 | .s440_p07 | .s440_p08 => .QoSGuaranteeStandard
  -- TrafficManagementPolicy
  | .s440_p09 | .s440_p10 | .s440_p11 => .TrafficManagementPolicy
  -- ResourceAllocationPolicy
  | .s440_p12 | .s440_p13 | .s440_p14 => .ResourceAllocationPolicy
  -- PredictiveOptimizationModel
  | .s440_p15 | .s440_p16 | .s440_p17 => .PredictiveOptimizationModel
  -- AdaptiveLearningHypothesis
  | .s440_p18 | .s440_p19 | .s440_p20 => .AdaptiveLearningHypothesis

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

end TestCoverage.S440
