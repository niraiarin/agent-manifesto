/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **InfrastructureSafetyInvariant** (ord=3): 地下埋設物・電力線との離隔・工事安全に関する絶対不変条件 [C1, C2]
- **RouteOptimizationPolicy** (ord=2): 最短経路・コスト最小化・既存インフラ活用の敷設計画方針 [C3, H1, H2]
- **DemandForecastHypothesis** (ord=1): 通信需要分布・将来拡張・帯域利用率に関する予測仮説 [C4, H3, H4]
-/

namespace TestCoverage.S442

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s442_p01
  | s442_p02
  | s442_p03
  | s442_p04
  | s442_p05
  | s442_p06
  | s442_p07
  | s442_p08
  | s442_p09
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s442_p01 => []
  | .s442_p02 => [.s442_p01]
  | .s442_p03 => [.s442_p01]
  | .s442_p04 => [.s442_p02, .s442_p03]
  | .s442_p05 => [.s442_p03]
  | .s442_p06 => [.s442_p03]
  | .s442_p07 => [.s442_p04, .s442_p06]
  | .s442_p08 => [.s442_p05]
  | .s442_p09 => [.s442_p07, .s442_p08]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 地下埋設物・電力線との離隔・工事安全に関する絶対不変条件 (ord=3) -/
  | InfrastructureSafetyInvariant
  /-- 最短経路・コスト最小化・既存インフラ活用の敷設計画方針 (ord=2) -/
  | RouteOptimizationPolicy
  /-- 通信需要分布・将来拡張・帯域利用率に関する予測仮説 (ord=1) -/
  | DemandForecastHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .InfrastructureSafetyInvariant => 3
  | .RouteOptimizationPolicy => 2
  | .DemandForecastHypothesis => 1

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
  bottom := .DemandForecastHypothesis
  nontrivial := ⟨.InfrastructureSafetyInvariant, .DemandForecastHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- InfrastructureSafetyInvariant
  | .s442_p01 | .s442_p02 => .InfrastructureSafetyInvariant
  -- RouteOptimizationPolicy
  | .s442_p03 | .s442_p04 | .s442_p05 => .RouteOptimizationPolicy
  -- DemandForecastHypothesis
  | .s442_p06 | .s442_p07 | .s442_p08 | .s442_p09 => .DemandForecastHypothesis

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

end TestCoverage.S442
