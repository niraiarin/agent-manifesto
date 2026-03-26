/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **ExamIntegrityInvariant** (ord=2): 試験の公正性・受験者のプライバシー・差別禁止の絶対要件 [C1, C2, C3]
- **ProctoringSurveillanceHypothesis** (ord=1): 視線追跡・キーストローク解析・環境音検知による不正推論 [C4, C5, C6, H1, H2, H3, H4]
-/

namespace TestCoverage.S486

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s486_p01
  | s486_p02
  | s486_p03
  | s486_p04
  | s486_p05
  | s486_p06
  | s486_p07
  | s486_p08
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s486_p01 => []
  | .s486_p02 => []
  | .s486_p03 => [.s486_p01, .s486_p02]
  | .s486_p04 => [.s486_p01]
  | .s486_p05 => [.s486_p02]
  | .s486_p06 => [.s486_p03, .s486_p04]
  | .s486_p07 => [.s486_p05, .s486_p06]
  | .s486_p08 => [.s486_p06, .s486_p07]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 試験の公正性・受験者のプライバシー・差別禁止の絶対要件 (ord=2) -/
  | ExamIntegrityInvariant
  /-- 視線追跡・キーストローク解析・環境音検知による不正推論 (ord=1) -/
  | ProctoringSurveillanceHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .ExamIntegrityInvariant => 2
  | .ProctoringSurveillanceHypothesis => 1

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
  bottom := .ProctoringSurveillanceHypothesis
  nontrivial := ⟨.ExamIntegrityInvariant, .ProctoringSurveillanceHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨2, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- ExamIntegrityInvariant
  | .s486_p01 | .s486_p02 | .s486_p03 => .ExamIntegrityInvariant
  -- ProctoringSurveillanceHypothesis
  | .s486_p04 | .s486_p05 | .s486_p06 | .s486_p07 | .s486_p08 => .ProctoringSurveillanceHypothesis

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

end TestCoverage.S486
