/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **StructuralSafety** (ord=3): 船体構造の安全基準。IMO規則・船級協会規格に準拠 [C1, C2]
- **HydrodynamicLaw** (ord=2): 流体力学に基づく設計原則。物理法則として不変 [C3, H1]
- **DesignTradeoff** (ord=1): コスト・性能・製造性のトレードオフ判断 [C4, C5, H2]
- **OptimizationHypothesis** (ord=0): 最適化アルゴリズムの有効性に関する仮説 [H3, H4]
-/

namespace TestCoverage.S143

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s143_p01
  | s143_p02
  | s143_p03
  | s143_p04
  | s143_p05
  | s143_p06
  | s143_p07
  | s143_p08
  | s143_p09
  | s143_p10
  | s143_p11
  | s143_p12
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s143_p01 => []
  | .s143_p02 => []
  | .s143_p03 => []
  | .s143_p04 => [.s143_p01]
  | .s143_p05 => [.s143_p02]
  | .s143_p06 => [.s143_p01, .s143_p03]
  | .s143_p07 => [.s143_p04]
  | .s143_p08 => [.s143_p05]
  | .s143_p09 => [.s143_p04, .s143_p06]
  | .s143_p10 => [.s143_p07]
  | .s143_p11 => [.s143_p08, .s143_p09]
  | .s143_p12 => [.s143_p07, .s143_p10]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 船体構造の安全基準。IMO規則・船級協会規格に準拠 (ord=3) -/
  | StructuralSafety
  /-- 流体力学に基づく設計原則。物理法則として不変 (ord=2) -/
  | HydrodynamicLaw
  /-- コスト・性能・製造性のトレードオフ判断 (ord=1) -/
  | DesignTradeoff
  /-- 最適化アルゴリズムの有効性に関する仮説 (ord=0) -/
  | OptimizationHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .StructuralSafety => 3
  | .HydrodynamicLaw => 2
  | .DesignTradeoff => 1
  | .OptimizationHypothesis => 0

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
  bottom := .OptimizationHypothesis
  nontrivial := ⟨.StructuralSafety, .OptimizationHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- StructuralSafety
  | .s143_p01 | .s143_p02 | .s143_p03 => .StructuralSafety
  -- HydrodynamicLaw
  | .s143_p04 | .s143_p05 | .s143_p06 => .HydrodynamicLaw
  -- DesignTradeoff
  | .s143_p07 | .s143_p08 | .s143_p09 => .DesignTradeoff
  -- OptimizationHypothesis
  | .s143_p10 | .s143_p11 | .s143_p12 => .OptimizationHypothesis

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

end TestCoverage.S143
