/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **RegulatoryCapitalInvariant** (ord=5): Basel III自己資本規制・CVA/DVA計上の絶対遵守要件 [C1, C2]
- **MarketRiskFramework** (ord=4): FRTB・VaR/ES計算・リスク感応度測定の規制枠組み [C3, C4]
- **PricingModelPolicy** (ord=3): ブラック・ショールズ・モンテカルロ法選択と校正方針 [C5, C6]
- **VolatilitySurfaceModel** (ord=2): インプライドボラティリティ・スキューのモデル化推論 [H1, H2, H3]
- **MarketScenarioHypothesis** (ord=1): ストレスシナリオ・テールリスクに関する予測仮説 [H4, H5]
-/

namespace TestCoverage.S482

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s482_p01
  | s482_p02
  | s482_p03
  | s482_p04
  | s482_p05
  | s482_p06
  | s482_p07
  | s482_p08
  | s482_p09
  | s482_p10
  | s482_p11
  | s482_p12
  | s482_p13
  | s482_p14
  | s482_p15
  | s482_p16
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s482_p01 => []
  | .s482_p02 => []
  | .s482_p03 => [.s482_p01, .s482_p02]
  | .s482_p04 => [.s482_p01]
  | .s482_p05 => [.s482_p03]
  | .s482_p06 => [.s482_p04, .s482_p05]
  | .s482_p07 => [.s482_p04]
  | .s482_p08 => [.s482_p06]
  | .s482_p09 => [.s482_p07]
  | .s482_p10 => [.s482_p08]
  | .s482_p11 => [.s482_p09, .s482_p10]
  | .s482_p12 => [.s482_p09, .s482_p10, .s482_p11]
  | .s482_p13 => [.s482_p09]
  | .s482_p14 => [.s482_p10]
  | .s482_p15 => [.s482_p13, .s482_p14]
  | .s482_p16 => [.s482_p11, .s482_p15]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- Basel III自己資本規制・CVA/DVA計上の絶対遵守要件 (ord=5) -/
  | RegulatoryCapitalInvariant
  /-- FRTB・VaR/ES計算・リスク感応度測定の規制枠組み (ord=4) -/
  | MarketRiskFramework
  /-- ブラック・ショールズ・モンテカルロ法選択と校正方針 (ord=3) -/
  | PricingModelPolicy
  /-- インプライドボラティリティ・スキューのモデル化推論 (ord=2) -/
  | VolatilitySurfaceModel
  /-- ストレスシナリオ・テールリスクに関する予測仮説 (ord=1) -/
  | MarketScenarioHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .RegulatoryCapitalInvariant => 5
  | .MarketRiskFramework => 4
  | .PricingModelPolicy => 3
  | .VolatilitySurfaceModel => 2
  | .MarketScenarioHypothesis => 1

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
  bottom := .MarketScenarioHypothesis
  nontrivial := ⟨.RegulatoryCapitalInvariant, .MarketScenarioHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- RegulatoryCapitalInvariant
  | .s482_p01 | .s482_p02 | .s482_p03 => .RegulatoryCapitalInvariant
  -- MarketRiskFramework
  | .s482_p04 | .s482_p05 | .s482_p06 => .MarketRiskFramework
  -- PricingModelPolicy
  | .s482_p07 | .s482_p08 => .PricingModelPolicy
  -- VolatilitySurfaceModel
  | .s482_p09 | .s482_p10 | .s482_p11 | .s482_p12 => .VolatilitySurfaceModel
  -- MarketScenarioHypothesis
  | .s482_p13 | .s482_p14 | .s482_p15 | .s482_p16 => .MarketScenarioHypothesis

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

end TestCoverage.S482
