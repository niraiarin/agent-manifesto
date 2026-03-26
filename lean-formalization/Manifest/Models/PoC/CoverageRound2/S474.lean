/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **SafetyAndRegulatoryInvariant** (ord=3): 水道法・建築基準法・漏水事故防止の安全絶対条件 [C1, C2, C3]
- **InspectionAndPriorityPolicy** (ord=2): 劣化指標測定・点検頻度・修繕優先度付けポリシー [C4, C5, H1, H2]
- **DegradationModelHypothesis** (ord=1): 配管材質・年数・使用条件による劣化進行予測仮説 [H3, H4, H5]
-/

namespace TestCoverage.S474

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s474_p01
  | s474_p02
  | s474_p03
  | s474_p04
  | s474_p05
  | s474_p06
  | s474_p07
  | s474_p08
  | s474_p09
  | s474_p10
  | s474_p11
  | s474_p12
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s474_p01 => []
  | .s474_p02 => []
  | .s474_p03 => [.s474_p01, .s474_p02]
  | .s474_p04 => [.s474_p01]
  | .s474_p05 => [.s474_p02]
  | .s474_p06 => [.s474_p03, .s474_p04]
  | .s474_p07 => [.s474_p05, .s474_p06]
  | .s474_p08 => [.s474_p04]
  | .s474_p09 => [.s474_p06]
  | .s474_p10 => [.s474_p07, .s474_p08]
  | .s474_p11 => [.s474_p09, .s474_p10]
  | .s474_p12 => [.s474_p06, .s474_p07]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 水道法・建築基準法・漏水事故防止の安全絶対条件 (ord=3) -/
  | SafetyAndRegulatoryInvariant
  /-- 劣化指標測定・点検頻度・修繕優先度付けポリシー (ord=2) -/
  | InspectionAndPriorityPolicy
  /-- 配管材質・年数・使用条件による劣化進行予測仮説 (ord=1) -/
  | DegradationModelHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .SafetyAndRegulatoryInvariant => 3
  | .InspectionAndPriorityPolicy => 2
  | .DegradationModelHypothesis => 1

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
  bottom := .DegradationModelHypothesis
  nontrivial := ⟨.SafetyAndRegulatoryInvariant, .DegradationModelHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- SafetyAndRegulatoryInvariant
  | .s474_p01 | .s474_p02 | .s474_p03 => .SafetyAndRegulatoryInvariant
  -- InspectionAndPriorityPolicy
  | .s474_p04 | .s474_p05 | .s474_p06 | .s474_p07 | .s474_p12 => .InspectionAndPriorityPolicy
  -- DegradationModelHypothesis
  | .s474_p08 | .s474_p09 | .s474_p10 | .s474_p11 => .DegradationModelHypothesis

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

end TestCoverage.S474
