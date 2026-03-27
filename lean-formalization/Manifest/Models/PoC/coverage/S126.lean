/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **HealthSafetyThreshold** (ord=3): 健康影響に関する法定基準値。WHO/環境省の基準 [C1, C2]
- **SensorInfrastructure** (ord=2): センサーネットワークの物理的・技術的制約 [C3, C4, H1]
- **PredictionModel** (ord=1): 予測モデルの設計選択。精度と速度のトレードオフ [C5, H2, H3, H4]
- **AlertTuning** (ord=0): 警報パラメータの調整。運用経験で最適化 [H5, H6]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s126_p01
  | s126_p02
  | s126_p03
  | s126_p04
  | s126_p05
  | s126_p06
  | s126_p07
  | s126_p08
  | s126_p09
  | s126_p10
  | s126_p11
  | s126_p12
  | s126_p13
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s126_p01 => []
  | .s126_p02 => []
  | .s126_p03 => [.s126_p01]
  | .s126_p04 => [.s126_p01, .s126_p02]
  | .s126_p05 => [.s126_p02]
  | .s126_p06 => [.s126_p03]
  | .s126_p07 => [.s126_p04]
  | .s126_p08 => [.s126_p03, .s126_p05]
  | .s126_p09 => [.s126_p04]
  | .s126_p10 => [.s126_p06]
  | .s126_p11 => [.s126_p07]
  | .s126_p12 => [.s126_p08, .s126_p09]
  | .s126_p13 => [.s126_p10, .s126_p11]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 健康影響に関する法定基準値。WHO/環境省の基準 (ord=3) -/
  | HealthSafetyThreshold
  /-- センサーネットワークの物理的・技術的制約 (ord=2) -/
  | SensorInfrastructure
  /-- 予測モデルの設計選択。精度と速度のトレードオフ (ord=1) -/
  | PredictionModel
  /-- 警報パラメータの調整。運用経験で最適化 (ord=0) -/
  | AlertTuning
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .HealthSafetyThreshold => 3
  | .SensorInfrastructure => 2
  | .PredictionModel => 1
  | .AlertTuning => 0

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
  bottom := .AlertTuning
  nontrivial := ⟨.HealthSafetyThreshold, .AlertTuning, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- HealthSafetyThreshold
  | .s126_p01 | .s126_p02 => .HealthSafetyThreshold
  -- SensorInfrastructure
  | .s126_p03 | .s126_p04 | .s126_p05 => .SensorInfrastructure
  -- PredictionModel
  | .s126_p06 | .s126_p07 | .s126_p08 | .s126_p09 => .PredictionModel
  -- AlertTuning
  | .s126_p10 | .s126_p11 | .s126_p12 | .s126_p13 => .AlertTuning

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
