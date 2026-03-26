/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **OrbitalSafetyInvariant** (ord=4): 衛星軌道の衝突回避・電波干渉防止に関する絶対不変条件 [C1, C2]
- **RegulatoryCompliancePolicy** (ord=3): ITU周波数規制・国際条約・ライセンス条件への適合要件 [C3, C4]
- **SchedulingOptimizationPolicy** (ord=2): スループット最大化・優先度付きキュー・時間窓配分の方針 [C5, H1, H2]
- **TrafficPredictionHypothesis** (ord=1): 通信需要パターン・障害予測・容量見積もりに関する推論仮説 [H3, H4, H5, H6]
-/

namespace TestCoverage.S441

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s441_p01
  | s441_p02
  | s441_p03
  | s441_p04
  | s441_p05
  | s441_p06
  | s441_p07
  | s441_p08
  | s441_p09
  | s441_p10
  | s441_p11
  | s441_p12
  | s441_p13
  | s441_p14
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s441_p01 => []
  | .s441_p02 => []
  | .s441_p03 => [.s441_p01, .s441_p02]
  | .s441_p04 => [.s441_p01]
  | .s441_p05 => [.s441_p02]
  | .s441_p06 => [.s441_p04, .s441_p05]
  | .s441_p07 => [.s441_p04]
  | .s441_p08 => [.s441_p05]
  | .s441_p09 => [.s441_p06, .s441_p07]
  | .s441_p10 => [.s441_p07]
  | .s441_p11 => [.s441_p08]
  | .s441_p12 => [.s441_p09, .s441_p10]
  | .s441_p13 => [.s441_p11]
  | .s441_p14 => [.s441_p12, .s441_p13]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 衛星軌道の衝突回避・電波干渉防止に関する絶対不変条件 (ord=4) -/
  | OrbitalSafetyInvariant
  /-- ITU周波数規制・国際条約・ライセンス条件への適合要件 (ord=3) -/
  | RegulatoryCompliancePolicy
  /-- スループット最大化・優先度付きキュー・時間窓配分の方針 (ord=2) -/
  | SchedulingOptimizationPolicy
  /-- 通信需要パターン・障害予測・容量見積もりに関する推論仮説 (ord=1) -/
  | TrafficPredictionHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .OrbitalSafetyInvariant => 4
  | .RegulatoryCompliancePolicy => 3
  | .SchedulingOptimizationPolicy => 2
  | .TrafficPredictionHypothesis => 1

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
  bottom := .TrafficPredictionHypothesis
  nontrivial := ⟨.OrbitalSafetyInvariant, .TrafficPredictionHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- OrbitalSafetyInvariant
  | .s441_p01 | .s441_p02 | .s441_p03 => .OrbitalSafetyInvariant
  -- RegulatoryCompliancePolicy
  | .s441_p04 | .s441_p05 | .s441_p06 => .RegulatoryCompliancePolicy
  -- SchedulingOptimizationPolicy
  | .s441_p07 | .s441_p08 | .s441_p09 => .SchedulingOptimizationPolicy
  -- TrafficPredictionHypothesis
  | .s441_p10 | .s441_p11 | .s441_p12 | .s441_p13 | .s441_p14 => .TrafficPredictionHypothesis

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

end TestCoverage.S441
