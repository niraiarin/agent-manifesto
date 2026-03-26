/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **FinancialConstraint** (ord=4): 投資上限・負債比率上限・最低ROI閾値に関する財務的絶対制約 [C1, C2]
- **StrategicAlignment** (ord=3): 事業戦略・中期計画・ESG目標への整合要件 [C3, C4]
- **EvaluationPolicy** (ord=2): NPV・IRR・回収期間・リスク調整リターンに基づく評価方針 [C5, H1, H2]
- **ForecastHypothesis** (ord=1): 需要予測・コスト削減効果・技術陳腐化リスクに関する予測仮説 [H3, H4, H5, H6]
-/

namespace TestCoverage.S424

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s424_p01
  | s424_p02
  | s424_p03
  | s424_p04
  | s424_p05
  | s424_p06
  | s424_p07
  | s424_p08
  | s424_p09
  | s424_p10
  | s424_p11
  | s424_p12
  | s424_p13
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s424_p01 => []
  | .s424_p02 => []
  | .s424_p03 => [.s424_p01]
  | .s424_p04 => [.s424_p02]
  | .s424_p05 => [.s424_p03, .s424_p04]
  | .s424_p06 => [.s424_p03]
  | .s424_p07 => [.s424_p04]
  | .s424_p08 => [.s424_p06, .s424_p07]
  | .s424_p09 => [.s424_p06]
  | .s424_p10 => [.s424_p07]
  | .s424_p11 => [.s424_p09]
  | .s424_p12 => [.s424_p10]
  | .s424_p13 => [.s424_p11, .s424_p12]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 投資上限・負債比率上限・最低ROI閾値に関する財務的絶対制約 (ord=4) -/
  | FinancialConstraint
  /-- 事業戦略・中期計画・ESG目標への整合要件 (ord=3) -/
  | StrategicAlignment
  /-- NPV・IRR・回収期間・リスク調整リターンに基づく評価方針 (ord=2) -/
  | EvaluationPolicy
  /-- 需要予測・コスト削減効果・技術陳腐化リスクに関する予測仮説 (ord=1) -/
  | ForecastHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .FinancialConstraint => 4
  | .StrategicAlignment => 3
  | .EvaluationPolicy => 2
  | .ForecastHypothesis => 1

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
  bottom := .ForecastHypothesis
  nontrivial := ⟨.FinancialConstraint, .ForecastHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- FinancialConstraint
  | .s424_p01 | .s424_p02 => .FinancialConstraint
  -- StrategicAlignment
  | .s424_p03 | .s424_p04 | .s424_p05 => .StrategicAlignment
  -- EvaluationPolicy
  | .s424_p06 | .s424_p07 | .s424_p08 => .EvaluationPolicy
  -- ForecastHypothesis
  | .s424_p09 | .s424_p10 | .s424_p11 | .s424_p12 | .s424_p13 => .ForecastHypothesis

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

end TestCoverage.S424
