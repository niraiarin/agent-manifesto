/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **tradition** (ord=3): 蔵の伝統と杜氏の権威に関わる不可侵の前提。 [C1, C2, C3]
- **compliance** (ord=2): 酒税法と食品安全基準に基づく法的制約。 [C4, C5]
- **fermentation** (ord=1): 発酵管理と分析手法の設計判断。技術進歩に応じて改善可能。 [H1, H2, H4]
- **hypothesis** (ord=0): 未検証の仮説。醸造実験で検証が必要。 [H3]
-/

namespace Scenario256

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | tra1
  | tra2
  | tra3
  | com1
  | com2
  | com3
  | fer1
  | fer2
  | fer3
  | fer4
  | fer5
  | hyp1
  | hyp2
  | hyp3
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .tra1 => []
  | .tra2 => []
  | .tra3 => []
  | .com1 => [.tra1]
  | .com2 => [.tra1, .tra2]
  | .com3 => [.com1, .com2]
  | .fer1 => [.tra3, .com1]
  | .fer2 => [.tra2]
  | .fer3 => [.com1, .fer1]
  | .fer4 => [.fer1, .fer2]
  | .fer5 => [.com3, .fer4]
  | .hyp1 => [.com2]
  | .hyp2 => [.fer4, .hyp1]
  | .hyp3 => [.fer3, .fer5]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 蔵の伝統と杜氏の権威に関わる不可侵の前提。 (ord=3) -/
  | tradition
  /-- 酒税法と食品安全基準に基づく法的制約。 (ord=2) -/
  | compliance
  /-- 発酵管理と分析手法の設計判断。技術進歩に応じて改善可能。 (ord=1) -/
  | fermentation
  /-- 未検証の仮説。醸造実験で検証が必要。 (ord=0) -/
  | hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .tradition => 3
  | .compliance => 2
  | .fermentation => 1
  | .hypothesis => 0

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
  bottom := .hypothesis
  nontrivial := ⟨.tradition, .hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- tradition
  | .tra1 | .tra2 | .tra3 => .tradition
  -- compliance
  | .com1 | .com2 | .com3 => .compliance
  -- fermentation
  | .fer1 | .fer2 | .fer3 | .fer4 | .fer5 => .fermentation
  -- hypothesis
  | .hyp1 | .hyp2 | .hyp3 => .hypothesis

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

end Scenario256
