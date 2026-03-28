/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **WorkerSafetyInvariant** (ord=5): 作業者の身体的安全に関わる不変制約。すべての自動化判断より優先 [C1]
- **ProductQualityCompliance** (ord=4): 製品規格・品質基準への準拠。ISO/業界標準に基づく [C2, H1]
- **ProductionPolicy** (ord=3): 生産スケジュール・ライン運用ポリシー。工場マネジメント判断 [C3, H2]
- **ThroughputOptimization** (ord=2): スループット・OEE最大化のための最適化ルール。データ駆動で調整 [C4, H3, H4]
- **PredictiveMaintenanceHypothesis** (ord=1): 機器故障予測・予防保全タイミングの仮説。センサーデータで継続更新 [H5, H6]
-/

namespace TestCoverage.S404

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s404_p01
  | s404_p02
  | s404_p03
  | s404_p04
  | s404_p05
  | s404_p06
  | s404_p07
  | s404_p08
  | s404_p09
  | s404_p10
  | s404_p11
  | s404_p12
  | s404_p13
  | s404_p14
  | s404_p15
  | s404_p16
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s404_p01 => []
  | .s404_p02 => [.s404_p01]
  | .s404_p03 => [.s404_p01]
  | .s404_p04 => [.s404_p02, .s404_p03]
  | .s404_p05 => [.s404_p02]
  | .s404_p06 => [.s404_p03]
  | .s404_p07 => [.s404_p04]
  | .s404_p08 => [.s404_p05]
  | .s404_p09 => [.s404_p06]
  | .s404_p10 => [.s404_p07]
  | .s404_p11 => [.s404_p08, .s404_p09]
  | .s404_p12 => [.s404_p08]
  | .s404_p13 => [.s404_p09]
  | .s404_p14 => [.s404_p10, .s404_p11]
  | .s404_p15 => [.s404_p12, .s404_p13]
  | .s404_p16 => [.s404_p14]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 作業者の身体的安全に関わる不変制約。すべての自動化判断より優先 (ord=5) -/
  | WorkerSafetyInvariant
  /-- 製品規格・品質基準への準拠。ISO/業界標準に基づく (ord=4) -/
  | ProductQualityCompliance
  /-- 生産スケジュール・ライン運用ポリシー。工場マネジメント判断 (ord=3) -/
  | ProductionPolicy
  /-- スループット・OEE最大化のための最適化ルール。データ駆動で調整 (ord=2) -/
  | ThroughputOptimization
  /-- 機器故障予測・予防保全タイミングの仮説。センサーデータで継続更新 (ord=1) -/
  | PredictiveMaintenanceHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .WorkerSafetyInvariant => 5
  | .ProductQualityCompliance => 4
  | .ProductionPolicy => 3
  | .ThroughputOptimization => 2
  | .PredictiveMaintenanceHypothesis => 1

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
  bottom := .PredictiveMaintenanceHypothesis
  nontrivial := ⟨.WorkerSafetyInvariant, .PredictiveMaintenanceHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- WorkerSafetyInvariant
  | .s404_p01 => .WorkerSafetyInvariant
  -- ProductQualityCompliance
  | .s404_p02 | .s404_p03 | .s404_p04 => .ProductQualityCompliance
  -- ProductionPolicy
  | .s404_p05 | .s404_p06 | .s404_p07 => .ProductionPolicy
  -- ThroughputOptimization
  | .s404_p08 | .s404_p09 | .s404_p10 | .s404_p11 => .ThroughputOptimization
  -- PredictiveMaintenanceHypothesis
  | .s404_p12 | .s404_p13 | .s404_p14 | .s404_p15 | .s404_p16 => .PredictiveMaintenanceHypothesis

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

end TestCoverage.S404
