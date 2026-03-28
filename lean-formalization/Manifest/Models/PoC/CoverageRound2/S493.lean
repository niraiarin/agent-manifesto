/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **SafetyAndLegal** (ord=3): 駐車場安全基準・道路交通法・消防法に基づく不変条件 [C1, C2]
- **OperationalPolicy** (ord=2): 料金設定・時間制限・優先レーン割り当てに関する運用ポリシー [C3, H1, H2]
- **OptimizationHeuristic** (ord=1): 需要予測・動的価格調整・誘導案内に関する最適化ヒューリスティック [H3, H4]
-/

namespace TestCoverage.S493

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s493_p01
  | s493_p02
  | s493_p03
  | s493_p04
  | s493_p05
  | s493_p06
  | s493_p07
  | s493_p08
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s493_p01 => []
  | .s493_p02 => [.s493_p01]
  | .s493_p03 => [.s493_p01]
  | .s493_p04 => [.s493_p02]
  | .s493_p05 => [.s493_p03, .s493_p04]
  | .s493_p06 => [.s493_p03]
  | .s493_p07 => [.s493_p05]
  | .s493_p08 => [.s493_p06, .s493_p07]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 駐車場安全基準・道路交通法・消防法に基づく不変条件 (ord=3) -/
  | SafetyAndLegal
  /-- 料金設定・時間制限・優先レーン割り当てに関する運用ポリシー (ord=2) -/
  | OperationalPolicy
  /-- 需要予測・動的価格調整・誘導案内に関する最適化ヒューリスティック (ord=1) -/
  | OptimizationHeuristic
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .SafetyAndLegal => 3
  | .OperationalPolicy => 2
  | .OptimizationHeuristic => 1

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
  bottom := .OptimizationHeuristic
  nontrivial := ⟨.SafetyAndLegal, .OptimizationHeuristic, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- SafetyAndLegal
  | .s493_p01 | .s493_p02 => .SafetyAndLegal
  -- OperationalPolicy
  | .s493_p03 | .s493_p04 | .s493_p05 => .OperationalPolicy
  -- OptimizationHeuristic
  | .s493_p06 | .s493_p07 | .s493_p08 => .OptimizationHeuristic

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

end TestCoverage.S493
