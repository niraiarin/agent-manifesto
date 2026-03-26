/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **GeologicalConstraint** (ord=3): 地質学的・物理的制約。地下構造に依存し変更不可 [C1, C2]
- **OperationalBoundary** (ord=2): プラント運用の安全・効率基準 [C3, C4, H1]
- **OptimizationStrategy** (ord=1): 発電効率の最適化戦略。データに基づき調整 [C5, H2, H3]
- **PredictiveModel** (ord=0): 予測モデルの仮説。運用データで検証が必要 [H4]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s123_p01
  | s123_p02
  | s123_p03
  | s123_p04
  | s123_p05
  | s123_p06
  | s123_p07
  | s123_p08
  | s123_p09
  | s123_p10
  | s123_p11
  | s123_p12
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s123_p01 => []
  | .s123_p02 => []
  | .s123_p03 => [.s123_p01]
  | .s123_p04 => [.s123_p01, .s123_p02]
  | .s123_p05 => [.s123_p02]
  | .s123_p06 => [.s123_p03]
  | .s123_p07 => [.s123_p04]
  | .s123_p08 => [.s123_p03, .s123_p05]
  | .s123_p09 => [.s123_p06]
  | .s123_p10 => [.s123_p07]
  | .s123_p11 => [.s123_p08, .s123_p09]
  | .s123_p12 => [.s123_p04]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 地質学的・物理的制約。地下構造に依存し変更不可 (ord=3) -/
  | GeologicalConstraint
  /-- プラント運用の安全・効率基準 (ord=2) -/
  | OperationalBoundary
  /-- 発電効率の最適化戦略。データに基づき調整 (ord=1) -/
  | OptimizationStrategy
  /-- 予測モデルの仮説。運用データで検証が必要 (ord=0) -/
  | PredictiveModel
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .GeologicalConstraint => 3
  | .OperationalBoundary => 2
  | .OptimizationStrategy => 1
  | .PredictiveModel => 0

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
  bottom := .PredictiveModel
  nontrivial := ⟨.GeologicalConstraint, .PredictiveModel, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- GeologicalConstraint
  | .s123_p01 | .s123_p02 => .GeologicalConstraint
  -- OperationalBoundary
  | .s123_p03 | .s123_p04 | .s123_p05 => .OperationalBoundary
  -- OptimizationStrategy
  | .s123_p06 | .s123_p07 | .s123_p08 | .s123_p12 => .OptimizationStrategy
  -- PredictiveModel
  | .s123_p09 | .s123_p10 | .s123_p11 => .PredictiveModel

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

end Manifest.Models
