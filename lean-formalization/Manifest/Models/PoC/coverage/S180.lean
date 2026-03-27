/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **PhysicsConstraint** (ord=5): 半導体物理の基本法則。プロセスノードに依存しない不変制約 [C1]
- **ProcessRule** (ord=4): ファウンドリのプロセスデザインルール。製造仕様に基づく [C2, H1]
- **DesignMethodology** (ord=3): 設計手法・EDAツールフローの選択 [C3, H2]
- **CheckAlgorithm** (ord=2): DRCアルゴリズムの設計選択 [C4, H3]
- **PerformanceHypothesis** (ord=1): チェック性能に関する未検証の仮説 [C5, H4, H5]
-/

namespace TestCoverage.S180

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s180_p01
  | s180_p02
  | s180_p03
  | s180_p04
  | s180_p05
  | s180_p06
  | s180_p07
  | s180_p08
  | s180_p09
  | s180_p10
  | s180_p11
  | s180_p12
  | s180_p13
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s180_p01 => []
  | .s180_p02 => [.s180_p01]
  | .s180_p03 => [.s180_p01]
  | .s180_p04 => [.s180_p01]
  | .s180_p05 => [.s180_p02]
  | .s180_p06 => [.s180_p02, .s180_p03]
  | .s180_p07 => [.s180_p05]
  | .s180_p08 => [.s180_p05, .s180_p06]
  | .s180_p09 => [.s180_p06]
  | .s180_p10 => [.s180_p07]
  | .s180_p11 => [.s180_p08]
  | .s180_p12 => [.s180_p09]
  | .s180_p13 => [.s180_p07, .s180_p10]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 半導体物理の基本法則。プロセスノードに依存しない不変制約 (ord=5) -/
  | PhysicsConstraint
  /-- ファウンドリのプロセスデザインルール。製造仕様に基づく (ord=4) -/
  | ProcessRule
  /-- 設計手法・EDAツールフローの選択 (ord=3) -/
  | DesignMethodology
  /-- DRCアルゴリズムの設計選択 (ord=2) -/
  | CheckAlgorithm
  /-- チェック性能に関する未検証の仮説 (ord=1) -/
  | PerformanceHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .PhysicsConstraint => 5
  | .ProcessRule => 4
  | .DesignMethodology => 3
  | .CheckAlgorithm => 2
  | .PerformanceHypothesis => 1

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
  bottom := .PerformanceHypothesis
  nontrivial := ⟨.PhysicsConstraint, .PerformanceHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- PhysicsConstraint
  | .s180_p01 => .PhysicsConstraint
  -- ProcessRule
  | .s180_p02 | .s180_p03 | .s180_p04 => .ProcessRule
  -- DesignMethodology
  | .s180_p05 | .s180_p06 => .DesignMethodology
  -- CheckAlgorithm
  | .s180_p07 | .s180_p08 | .s180_p09 => .CheckAlgorithm
  -- PerformanceHypothesis
  | .s180_p10 | .s180_p11 | .s180_p12 | .s180_p13 => .PerformanceHypothesis

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

end TestCoverage.S180
