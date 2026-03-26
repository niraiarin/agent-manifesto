/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **SpectrumRegulationInvariant** (ord=3): 総務省・ITU電波規則・免許条件・混信防止の絶対不変条件 [C1, C2, C3]
- **AllocationOptimizationPolicy** (ord=2): 干渉最小化・スペクトル効率・動的周波数再使用の最適化方針 [C4, C5, H1, H2]
- **UsagePatternHypothesis** (ord=1): 周波数利用パターン・需要予測・二次利用可能性に関する仮説 [C6, H3, H4, H5]
-/

namespace TestCoverage.S446

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s446_p01
  | s446_p02
  | s446_p03
  | s446_p04
  | s446_p05
  | s446_p06
  | s446_p07
  | s446_p08
  | s446_p09
  | s446_p10
  | s446_p11
  | s446_p12
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s446_p01 => []
  | .s446_p02 => [.s446_p01]
  | .s446_p03 => [.s446_p01]
  | .s446_p04 => [.s446_p02]
  | .s446_p05 => [.s446_p03]
  | .s446_p06 => [.s446_p04]
  | .s446_p07 => [.s446_p05, .s446_p06]
  | .s446_p08 => [.s446_p04]
  | .s446_p09 => [.s446_p06, .s446_p08]
  | .s446_p10 => [.s446_p07]
  | .s446_p11 => [.s446_p09, .s446_p10]
  | .s446_p12 => [.s446_p09, .s446_p11]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 総務省・ITU電波規則・免許条件・混信防止の絶対不変条件 (ord=3) -/
  | SpectrumRegulationInvariant
  /-- 干渉最小化・スペクトル効率・動的周波数再使用の最適化方針 (ord=2) -/
  | AllocationOptimizationPolicy
  /-- 周波数利用パターン・需要予測・二次利用可能性に関する仮説 (ord=1) -/
  | UsagePatternHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .SpectrumRegulationInvariant => 3
  | .AllocationOptimizationPolicy => 2
  | .UsagePatternHypothesis => 1

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
  bottom := .UsagePatternHypothesis
  nontrivial := ⟨.SpectrumRegulationInvariant, .UsagePatternHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- SpectrumRegulationInvariant
  | .s446_p01 | .s446_p02 | .s446_p03 => .SpectrumRegulationInvariant
  -- AllocationOptimizationPolicy
  | .s446_p04 | .s446_p05 | .s446_p06 | .s446_p07 => .AllocationOptimizationPolicy
  -- UsagePatternHypothesis
  | .s446_p08 | .s446_p09 | .s446_p10 | .s446_p11 | .s446_p12 => .UsagePatternHypothesis

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

end TestCoverage.S446
