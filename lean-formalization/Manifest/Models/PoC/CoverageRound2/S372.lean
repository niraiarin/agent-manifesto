/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **CapitalPreservation** (ord=5): 自己資本比率規制・最大損失限度の絶対遵守 [C1, C2]
- **RegulatoryHedgeAccounting** (ord=4): IFRS9・ASC815ヘッジ会計適格要件 [C3]
- **HedgeEffectivenessPolicy** (ord=3): ヘッジ有効性測定・リバランス頻度の方針 [C4, H1]
- **ExposureMeasurementModel** (ord=2): 通貨エクスポージャー計算・VaRモデルの推論 [H2, H3]
- **MarketPredictionHypothesis** (ord=1): 為替レート変動・相関係数に関する予測仮説 [H4, H5]
-/

namespace TestCoverage.S372

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s372_p01
  | s372_p02
  | s372_p03
  | s372_p04
  | s372_p05
  | s372_p06
  | s372_p07
  | s372_p08
  | s372_p09
  | s372_p10
  | s372_p11
  | s372_p12
  | s372_p13
  | s372_p14
  | s372_p15
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s372_p01 => []
  | .s372_p02 => []
  | .s372_p03 => [.s372_p01, .s372_p02]
  | .s372_p04 => [.s372_p01]
  | .s372_p05 => [.s372_p03]
  | .s372_p06 => [.s372_p04]
  | .s372_p07 => [.s372_p05, .s372_p06]
  | .s372_p08 => [.s372_p06, .s372_p07]
  | .s372_p09 => [.s372_p06]
  | .s372_p10 => [.s372_p07]
  | .s372_p11 => [.s372_p09, .s372_p10]
  | .s372_p12 => [.s372_p09]
  | .s372_p13 => [.s372_p10]
  | .s372_p14 => [.s372_p12, .s372_p13]
  | .s372_p15 => [.s372_p11, .s372_p14]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 自己資本比率規制・最大損失限度の絶対遵守 (ord=5) -/
  | CapitalPreservation
  /-- IFRS9・ASC815ヘッジ会計適格要件 (ord=4) -/
  | RegulatoryHedgeAccounting
  /-- ヘッジ有効性測定・リバランス頻度の方針 (ord=3) -/
  | HedgeEffectivenessPolicy
  /-- 通貨エクスポージャー計算・VaRモデルの推論 (ord=2) -/
  | ExposureMeasurementModel
  /-- 為替レート変動・相関係数に関する予測仮説 (ord=1) -/
  | MarketPredictionHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .CapitalPreservation => 5
  | .RegulatoryHedgeAccounting => 4
  | .HedgeEffectivenessPolicy => 3
  | .ExposureMeasurementModel => 2
  | .MarketPredictionHypothesis => 1

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
  bottom := .MarketPredictionHypothesis
  nontrivial := ⟨.CapitalPreservation, .MarketPredictionHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- CapitalPreservation
  | .s372_p01 | .s372_p02 | .s372_p03 => .CapitalPreservation
  -- RegulatoryHedgeAccounting
  | .s372_p04 | .s372_p05 => .RegulatoryHedgeAccounting
  -- HedgeEffectivenessPolicy
  | .s372_p06 | .s372_p07 | .s372_p08 => .HedgeEffectivenessPolicy
  -- ExposureMeasurementModel
  | .s372_p09 | .s372_p10 | .s372_p11 => .ExposureMeasurementModel
  -- MarketPredictionHypothesis
  | .s372_p12 | .s372_p13 | .s372_p14 | .s372_p15 => .MarketPredictionHypothesis

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

end TestCoverage.S372
