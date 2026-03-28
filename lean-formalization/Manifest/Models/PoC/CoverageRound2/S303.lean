/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **GridStabilityInvariant** (ord=3): 電力網の周波数・電圧安定性に関する絶対不変条件 [C1, C2]
- **BalancingPolicy** (ord=2): 需給バランス・再生可能エネルギー優先・負荷制御の方針 [C3, C4, H1, H2]
- **ForecastHypothesis** (ord=1): 需要予測・発電量推定に関する統計的仮説 [C5, H3, H4]
-/

namespace TestCoverage.S303

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s303_p01
  | s303_p02
  | s303_p03
  | s303_p04
  | s303_p05
  | s303_p06
  | s303_p07
  | s303_p08
  | s303_p09
  | s303_p10
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s303_p01 => []
  | .s303_p02 => []
  | .s303_p03 => [.s303_p01, .s303_p02]
  | .s303_p04 => [.s303_p01]
  | .s303_p05 => [.s303_p02]
  | .s303_p06 => [.s303_p03, .s303_p04]
  | .s303_p07 => [.s303_p04]
  | .s303_p08 => [.s303_p05]
  | .s303_p09 => [.s303_p06, .s303_p07]
  | .s303_p10 => [.s303_p08, .s303_p09]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 電力網の周波数・電圧安定性に関する絶対不変条件 (ord=3) -/
  | GridStabilityInvariant
  /-- 需給バランス・再生可能エネルギー優先・負荷制御の方針 (ord=2) -/
  | BalancingPolicy
  /-- 需要予測・発電量推定に関する統計的仮説 (ord=1) -/
  | ForecastHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .GridStabilityInvariant => 3
  | .BalancingPolicy => 2
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
  nontrivial := ⟨.GridStabilityInvariant, .ForecastHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- GridStabilityInvariant
  | .s303_p01 | .s303_p02 | .s303_p03 => .GridStabilityInvariant
  -- BalancingPolicy
  | .s303_p04 | .s303_p05 | .s303_p06 => .BalancingPolicy
  -- ForecastHypothesis
  | .s303_p07 | .s303_p08 | .s303_p09 | .s303_p10 => .ForecastHypothesis

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

end TestCoverage.S303
