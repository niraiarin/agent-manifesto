/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **SafetyConstraint** (ord=4): 作業員安全・積荷崩壊防止に関する絶対安全制約 [C1, C2]
- **OperationalCompliance** (ord=3): 税関・検疫・危険物規制への適合要件 [C3, C4]
- **OptimizationPolicy** (ord=2): 荷役順序・クレーン割当・保管場所割当の最適化方針 [C5, H1, H2, H3]
- **DemandHypothesis** (ord=1): 船便スケジュール変動・需要量予測に関する仮説 [H4, H5, H6]
-/

namespace TestCoverage.S309

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s309_p01
  | s309_p02
  | s309_p03
  | s309_p04
  | s309_p05
  | s309_p06
  | s309_p07
  | s309_p08
  | s309_p09
  | s309_p10
  | s309_p11
  | s309_p12
  | s309_p13
  | s309_p14
  | s309_p15
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s309_p01 => []
  | .s309_p02 => []
  | .s309_p03 => [.s309_p01]
  | .s309_p04 => [.s309_p02]
  | .s309_p05 => [.s309_p03, .s309_p04]
  | .s309_p06 => [.s309_p03]
  | .s309_p07 => [.s309_p04]
  | .s309_p08 => [.s309_p05, .s309_p06]
  | .s309_p09 => [.s309_p07, .s309_p08]
  | .s309_p10 => [.s309_p06]
  | .s309_p11 => [.s309_p07]
  | .s309_p12 => [.s309_p08]
  | .s309_p13 => [.s309_p09, .s309_p10]
  | .s309_p14 => [.s309_p11, .s309_p12]
  | .s309_p15 => [.s309_p13, .s309_p14]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 作業員安全・積荷崩壊防止に関する絶対安全制約 (ord=4) -/
  | SafetyConstraint
  /-- 税関・検疫・危険物規制への適合要件 (ord=3) -/
  | OperationalCompliance
  /-- 荷役順序・クレーン割当・保管場所割当の最適化方針 (ord=2) -/
  | OptimizationPolicy
  /-- 船便スケジュール変動・需要量予測に関する仮説 (ord=1) -/
  | DemandHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .SafetyConstraint => 4
  | .OperationalCompliance => 3
  | .OptimizationPolicy => 2
  | .DemandHypothesis => 1

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
  bottom := .DemandHypothesis
  nontrivial := ⟨.SafetyConstraint, .DemandHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- SafetyConstraint
  | .s309_p01 | .s309_p02 => .SafetyConstraint
  -- OperationalCompliance
  | .s309_p03 | .s309_p04 | .s309_p05 => .OperationalCompliance
  -- OptimizationPolicy
  | .s309_p06 | .s309_p07 | .s309_p08 | .s309_p09 => .OptimizationPolicy
  -- DemandHypothesis
  | .s309_p10 | .s309_p11 | .s309_p12 | .s309_p13 | .s309_p14 | .s309_p15 => .DemandHypothesis

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

end TestCoverage.S309
