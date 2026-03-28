/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **LegalZoningInvariant** (ord=4): 都市計画法・建築基準法に基づく絶対的用途地域制約。いかなる開発計画も違反不可 [C1, C2]
- **EnvironmentalProtectionPolicy** (ord=3): 環境影響評価・緑地保全・水源保護の行政指導方針 [C3, H1]
- **InfrastructureCapacityRule** (ord=2): 上下水道・道路容量・電力供給の許容量に基づく開発規模上限推論 [C4, H2, H3]
- **DevelopmentFeasibilityHypothesis** (ord=1): 市場需要・投資収益性・地価動向に関する開発実現可能性仮説 [C5, H4, H5, H6]
-/

namespace TestCoverage.S451

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s451_p01
  | s451_p02
  | s451_p03
  | s451_p04
  | s451_p05
  | s451_p06
  | s451_p07
  | s451_p08
  | s451_p09
  | s451_p10
  | s451_p11
  | s451_p12
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s451_p01 => []
  | .s451_p02 => []
  | .s451_p03 => [.s451_p01, .s451_p02]
  | .s451_p04 => [.s451_p01]
  | .s451_p05 => [.s451_p02, .s451_p03]
  | .s451_p06 => [.s451_p04]
  | .s451_p07 => [.s451_p04, .s451_p05]
  | .s451_p08 => [.s451_p06, .s451_p07]
  | .s451_p09 => [.s451_p06]
  | .s451_p10 => [.s451_p07, .s451_p08]
  | .s451_p11 => [.s451_p09]
  | .s451_p12 => [.s451_p10, .s451_p11]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 都市計画法・建築基準法に基づく絶対的用途地域制約。いかなる開発計画も違反不可 (ord=4) -/
  | LegalZoningInvariant
  /-- 環境影響評価・緑地保全・水源保護の行政指導方針 (ord=3) -/
  | EnvironmentalProtectionPolicy
  /-- 上下水道・道路容量・電力供給の許容量に基づく開発規模上限推論 (ord=2) -/
  | InfrastructureCapacityRule
  /-- 市場需要・投資収益性・地価動向に関する開発実現可能性仮説 (ord=1) -/
  | DevelopmentFeasibilityHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .LegalZoningInvariant => 4
  | .EnvironmentalProtectionPolicy => 3
  | .InfrastructureCapacityRule => 2
  | .DevelopmentFeasibilityHypothesis => 1

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
  bottom := .DevelopmentFeasibilityHypothesis
  nontrivial := ⟨.LegalZoningInvariant, .DevelopmentFeasibilityHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- LegalZoningInvariant
  | .s451_p01 | .s451_p02 | .s451_p03 => .LegalZoningInvariant
  -- EnvironmentalProtectionPolicy
  | .s451_p04 | .s451_p05 => .EnvironmentalProtectionPolicy
  -- InfrastructureCapacityRule
  | .s451_p06 | .s451_p07 | .s451_p08 => .InfrastructureCapacityRule
  -- DevelopmentFeasibilityHypothesis
  | .s451_p09 | .s451_p10 | .s451_p11 | .s451_p12 => .DevelopmentFeasibilityHypothesis

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

end TestCoverage.S451
