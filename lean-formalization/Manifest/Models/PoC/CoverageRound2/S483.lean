/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **AirspaceFlightSafetyInvariant** (ord=3): 衝突回避・緊急着陸・乗員安全の絶対不変条件 [C1, C2, C3]
- **AirTrafficRegulationPolicy** (ord=2): UTM統合・飛行経路承認・騒音規制・航空法遵守方針 [C4, C5, C6, C7]
- **RouteOptimizationHypothesis** (ord=1): 気象条件・交通密度・バッテリー残量に基づく経路予測仮説 [H1, H2, H3, H4]
-/

namespace TestCoverage.S483

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s483_p01
  | s483_p02
  | s483_p03
  | s483_p04
  | s483_p05
  | s483_p06
  | s483_p07
  | s483_p08
  | s483_p09
  | s483_p10
  | s483_p11
  | s483_p12
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s483_p01 => []
  | .s483_p02 => []
  | .s483_p03 => [.s483_p01]
  | .s483_p04 => [.s483_p01, .s483_p02, .s483_p03]
  | .s483_p05 => [.s483_p01]
  | .s483_p06 => [.s483_p02, .s483_p04]
  | .s483_p07 => [.s483_p05, .s483_p06]
  | .s483_p08 => [.s483_p05]
  | .s483_p09 => [.s483_p06]
  | .s483_p10 => [.s483_p07, .s483_p08]
  | .s483_p11 => [.s483_p08, .s483_p09]
  | .s483_p12 => [.s483_p10, .s483_p11]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 衝突回避・緊急着陸・乗員安全の絶対不変条件 (ord=3) -/
  | AirspaceFlightSafetyInvariant
  /-- UTM統合・飛行経路承認・騒音規制・航空法遵守方針 (ord=2) -/
  | AirTrafficRegulationPolicy
  /-- 気象条件・交通密度・バッテリー残量に基づく経路予測仮説 (ord=1) -/
  | RouteOptimizationHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .AirspaceFlightSafetyInvariant => 3
  | .AirTrafficRegulationPolicy => 2
  | .RouteOptimizationHypothesis => 1

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
  bottom := .RouteOptimizationHypothesis
  nontrivial := ⟨.AirspaceFlightSafetyInvariant, .RouteOptimizationHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- AirspaceFlightSafetyInvariant
  | .s483_p01 | .s483_p02 | .s483_p03 | .s483_p04 => .AirspaceFlightSafetyInvariant
  -- AirTrafficRegulationPolicy
  | .s483_p05 | .s483_p06 | .s483_p07 => .AirTrafficRegulationPolicy
  -- RouteOptimizationHypothesis
  | .s483_p08 | .s483_p09 | .s483_p10 | .s483_p11 | .s483_p12 => .RouteOptimizationHypothesis

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

end TestCoverage.S483
