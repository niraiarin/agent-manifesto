/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **InfrastructureConstraint** (ord=2): 送電設備の物理的制約と電力供給義務。変更不可 [C1, C2, C3]
- **PredictionModel** (ord=1): 着雪予測モデルの設計選択。気象データと運用実績に基づく [C4, C5, H1, H2, H3]
- **OperationalHypothesis** (ord=0): 運用効率に関する未検証仮説 [H4, H5]
-/

namespace TestCoverage.S187

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s187_p01
  | s187_p02
  | s187_p03
  | s187_p04
  | s187_p05
  | s187_p06
  | s187_p07
  | s187_p08
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s187_p01 => []
  | .s187_p02 => []
  | .s187_p03 => [.s187_p01]
  | .s187_p04 => [.s187_p01, .s187_p02]
  | .s187_p05 => [.s187_p02]
  | .s187_p06 => [.s187_p03]
  | .s187_p07 => [.s187_p04, .s187_p05]
  | .s187_p08 => [.s187_p03, .s187_p05]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 送電設備の物理的制約と電力供給義務。変更不可 (ord=2) -/
  | InfrastructureConstraint
  /-- 着雪予測モデルの設計選択。気象データと運用実績に基づく (ord=1) -/
  | PredictionModel
  /-- 運用効率に関する未検証仮説 (ord=0) -/
  | OperationalHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .InfrastructureConstraint => 2
  | .PredictionModel => 1
  | .OperationalHypothesis => 0

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
  bottom := .OperationalHypothesis
  nontrivial := ⟨.InfrastructureConstraint, .OperationalHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨2, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- InfrastructureConstraint
  | .s187_p01 | .s187_p02 => .InfrastructureConstraint
  -- PredictionModel
  | .s187_p03 | .s187_p04 | .s187_p05 => .PredictionModel
  -- OperationalHypothesis
  | .s187_p06 | .s187_p07 | .s187_p08 => .OperationalHypothesis

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

end TestCoverage.S187
