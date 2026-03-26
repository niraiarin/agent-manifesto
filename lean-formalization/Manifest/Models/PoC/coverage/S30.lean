/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **sla_constraint** (ord=5): SLA・可用性の制約。コスト削減でサービス品質を犠牲にしない [C1, C2]
- **infrastructure_postulate** (ord=4): クラウドインフラの前提。マルチクラウド・料金体系 [C3, C4, H1]
- **optimization_principle** (ord=2): コスト最適化の原則。自動化とガバナンスのバランス [C5, H2, H3]
- **sizing_hypothesis** (ord=0): サイジング・リザベーションの仮説。利用実績で調整 [H4, H5, H6]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | availability_guarantee
  | disaster_recovery_rpo
  | multi_cloud_strategy
  | pricing_model_awareness
  | auto_scaling_policy
  | cost_anomaly_detection
  | rightsizing_recommendation
  | reserved_instance_ratio
  | spot_instance_tolerance
  | budget_alert_threshold
  | idle_resource_cleanup
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .availability_guarantee => []
  | .disaster_recovery_rpo => []
  | .multi_cloud_strategy => []
  | .pricing_model_awareness => []
  | .auto_scaling_policy => []
  | .cost_anomaly_detection => []
  | .rightsizing_recommendation => []
  | .reserved_instance_ratio => []
  | .spot_instance_tolerance => []
  | .budget_alert_threshold => []
  | .idle_resource_cleanup => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- SLA・可用性の制約。コスト削減でサービス品質を犠牲にしない (ord=5) -/
  | sla_constraint
  /-- クラウドインフラの前提。マルチクラウド・料金体系 (ord=4) -/
  | infrastructure_postulate
  /-- コスト最適化の原則。自動化とガバナンスのバランス (ord=2) -/
  | optimization_principle
  /-- サイジング・リザベーションの仮説。利用実績で調整 (ord=0) -/
  | sizing_hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .sla_constraint => 5
  | .infrastructure_postulate => 4
  | .optimization_principle => 2
  | .sizing_hypothesis => 0

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
  bottom := .sizing_hypothesis
  nontrivial := ⟨.sla_constraint, .sizing_hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- sla_constraint
  | .availability_guarantee | .disaster_recovery_rpo => .sla_constraint
  -- infrastructure_postulate
  | .multi_cloud_strategy | .pricing_model_awareness => .infrastructure_postulate
  -- optimization_principle
  | .auto_scaling_policy | .cost_anomaly_detection | .budget_alert_threshold => .optimization_principle
  -- sizing_hypothesis
  | .rightsizing_recommendation | .reserved_instance_ratio | .spot_instance_tolerance | .idle_resource_cleanup => .sizing_hypothesis

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
