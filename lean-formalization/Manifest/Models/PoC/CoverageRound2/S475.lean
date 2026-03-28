/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **BudgetAndSLAInvariant** (ord=4): 予算上限・SLA保証・ガバナンス要件の絶対条件 [C1, C2]
- **ResourceAllocationPolicy** (ord=3): リソース使用率・リザーブドインスタンス・スポット活用ポリシー [C3, C4]
- **OptimizationStrategyPolicy** (ord=2): ライトサイジング・アイドルリソース廃棄・タグ管理の方針 [H1, H2, H3]
- **CostForecastHypothesis** (ord=1): 使用量トレンドと季節変動を考慮したコスト予測仮説 [H4, H5, H6]
-/

namespace TestCoverage.S475

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s475_p01
  | s475_p02
  | s475_p03
  | s475_p04
  | s475_p05
  | s475_p06
  | s475_p07
  | s475_p08
  | s475_p09
  | s475_p10
  | s475_p11
  | s475_p12
  | s475_p13
  | s475_p14
  | s475_p15
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s475_p01 => []
  | .s475_p02 => []
  | .s475_p03 => [.s475_p01, .s475_p02]
  | .s475_p04 => [.s475_p01]
  | .s475_p05 => [.s475_p02]
  | .s475_p06 => [.s475_p04, .s475_p05]
  | .s475_p07 => [.s475_p04]
  | .s475_p08 => [.s475_p05]
  | .s475_p09 => [.s475_p06, .s475_p07]
  | .s475_p10 => [.s475_p07]
  | .s475_p11 => [.s475_p08]
  | .s475_p12 => [.s475_p09, .s475_p10]
  | .s475_p13 => [.s475_p10, .s475_p11]
  | .s475_p14 => [.s475_p07, .s475_p09]
  | .s475_p15 => [.s475_p06]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 予算上限・SLA保証・ガバナンス要件の絶対条件 (ord=4) -/
  | BudgetAndSLAInvariant
  /-- リソース使用率・リザーブドインスタンス・スポット活用ポリシー (ord=3) -/
  | ResourceAllocationPolicy
  /-- ライトサイジング・アイドルリソース廃棄・タグ管理の方針 (ord=2) -/
  | OptimizationStrategyPolicy
  /-- 使用量トレンドと季節変動を考慮したコスト予測仮説 (ord=1) -/
  | CostForecastHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .BudgetAndSLAInvariant => 4
  | .ResourceAllocationPolicy => 3
  | .OptimizationStrategyPolicy => 2
  | .CostForecastHypothesis => 1

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
  bottom := .CostForecastHypothesis
  nontrivial := ⟨.BudgetAndSLAInvariant, .CostForecastHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- BudgetAndSLAInvariant
  | .s475_p01 | .s475_p02 | .s475_p03 => .BudgetAndSLAInvariant
  -- ResourceAllocationPolicy
  | .s475_p04 | .s475_p05 | .s475_p06 | .s475_p15 => .ResourceAllocationPolicy
  -- OptimizationStrategyPolicy
  | .s475_p07 | .s475_p08 | .s475_p09 | .s475_p14 => .OptimizationStrategyPolicy
  -- CostForecastHypothesis
  | .s475_p10 | .s475_p11 | .s475_p12 | .s475_p13 => .CostForecastHypothesis

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

end TestCoverage.S475
