/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **EnvironmentalSafetyInvariant** (ord=6): 海洋環境保護・船舶安全・潜水作業規制の絶対不変条件 [C1]
- **InternationalLegalInvariant** (ord=5): 国連海洋法条約・各国EEZ・排他的経済水域の法的制約 [C2]
- **CableIntegrityPolicy** (ord=4): ケーブル損傷検知・絶縁抵抗管理・光損失測定の監視方針 [C3, H1]
- **MaintenanceSchedulePolicy** (ord=3): 予防保全周期・修理船運航・部品在庫管理の運用方針 [C4, H2]
- **RepairCostOptimizationPolicy** (ord=2): 修理コスト最小化・リスク優先度・保険管理の最適化方針 [C5, H3]
- **LifecyclePredictionHypothesis** (ord=1): ケーブル寿命予測・劣化モデル・更新タイミングに関する仮説 [H4]
-/

namespace TestCoverage.S447

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s447_p01
  | s447_p02
  | s447_p03
  | s447_p04
  | s447_p05
  | s447_p06
  | s447_p07
  | s447_p08
  | s447_p09
  | s447_p10
  | s447_p11
  | s447_p12
  | s447_p13
  | s447_p14
  | s447_p15
  | s447_p16
  | s447_p17
  | s447_p18
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s447_p01 => []
  | .s447_p02 => [.s447_p01]
  | .s447_p03 => [.s447_p01]
  | .s447_p04 => [.s447_p02, .s447_p03]
  | .s447_p05 => [.s447_p03, .s447_p04]
  | .s447_p06 => [.s447_p03]
  | .s447_p07 => [.s447_p04, .s447_p06]
  | .s447_p08 => [.s447_p06, .s447_p07]
  | .s447_p09 => [.s447_p06]
  | .s447_p10 => [.s447_p07, .s447_p09]
  | .s447_p11 => [.s447_p09, .s447_p10]
  | .s447_p12 => [.s447_p05]
  | .s447_p13 => [.s447_p08, .s447_p12]
  | .s447_p14 => [.s447_p11]
  | .s447_p15 => [.s447_p13, .s447_p14]
  | .s447_p16 => [.s447_p15]
  | .s447_p17 => [.s447_p16]
  | .s447_p18 => [.s447_p15, .s447_p17]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 海洋環境保護・船舶安全・潜水作業規制の絶対不変条件 (ord=6) -/
  | EnvironmentalSafetyInvariant
  /-- 国連海洋法条約・各国EEZ・排他的経済水域の法的制約 (ord=5) -/
  | InternationalLegalInvariant
  /-- ケーブル損傷検知・絶縁抵抗管理・光損失測定の監視方針 (ord=4) -/
  | CableIntegrityPolicy
  /-- 予防保全周期・修理船運航・部品在庫管理の運用方針 (ord=3) -/
  | MaintenanceSchedulePolicy
  /-- 修理コスト最小化・リスク優先度・保険管理の最適化方針 (ord=2) -/
  | RepairCostOptimizationPolicy
  /-- ケーブル寿命予測・劣化モデル・更新タイミングに関する仮説 (ord=1) -/
  | LifecyclePredictionHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .EnvironmentalSafetyInvariant => 6
  | .InternationalLegalInvariant => 5
  | .CableIntegrityPolicy => 4
  | .MaintenanceSchedulePolicy => 3
  | .RepairCostOptimizationPolicy => 2
  | .LifecyclePredictionHypothesis => 1

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
  bottom := .LifecyclePredictionHypothesis
  nontrivial := ⟨.EnvironmentalSafetyInvariant, .LifecyclePredictionHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨6, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- EnvironmentalSafetyInvariant
  | .s447_p01 => .EnvironmentalSafetyInvariant
  -- InternationalLegalInvariant
  | .s447_p02 => .InternationalLegalInvariant
  -- CableIntegrityPolicy
  | .s447_p03 | .s447_p04 | .s447_p05 => .CableIntegrityPolicy
  -- MaintenanceSchedulePolicy
  | .s447_p06 | .s447_p07 | .s447_p08 => .MaintenanceSchedulePolicy
  -- RepairCostOptimizationPolicy
  | .s447_p09 | .s447_p10 | .s447_p11 => .RepairCostOptimizationPolicy
  -- LifecyclePredictionHypothesis
  | .s447_p12 | .s447_p13 | .s447_p14 | .s447_p15 | .s447_p16 | .s447_p17 | .s447_p18 => .LifecyclePredictionHypothesis

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

end TestCoverage.S447
