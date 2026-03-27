/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **environmental** (ord=3): 極地環境の物理的制約と野生動物保護規制。変更不可。 [C1, C2, C4]
- **communication** (ord=2): 通信・帯域に関する制約。インフラ依存。 [C3]
- **planning** (ord=1): 研究チームとAIが協調する飛行・観測計画。 [C5, H1, H2]
- **hypothesis** (ord=0): 検証が必要な技術的仮説。 [H3]
-/

namespace Scenario197

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | env1
  | env2
  | env3
  | env4
  | com1
  | com2
  | pln1
  | pln2
  | pln3
  | pln4
  | pln5
  | hyp1
  | hyp2
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .env1 => []
  | .env2 => []
  | .env3 => []
  | .env4 => [.env1]
  | .com1 => []
  | .com2 => [.env3]
  | .pln1 => [.env1, .env3]
  | .pln2 => [.env4, .com2]
  | .pln3 => [.com1, .com2]
  | .pln4 => [.env2, .pln1]
  | .pln5 => [.pln2, .pln3]
  | .hyp1 => [.env1, .pln1]
  | .hyp2 => [.pln2, .pln5]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 極地環境の物理的制約と野生動物保護規制。変更不可。 (ord=3) -/
  | environmental
  /-- 通信・帯域に関する制約。インフラ依存。 (ord=2) -/
  | communication
  /-- 研究チームとAIが協調する飛行・観測計画。 (ord=1) -/
  | planning
  /-- 検証が必要な技術的仮説。 (ord=0) -/
  | hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .environmental => 3
  | .communication => 2
  | .planning => 1
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
  nontrivial := ⟨.environmental, .hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- environmental
  | .env1 | .env2 | .env3 | .env4 => .environmental
  -- communication
  | .com1 | .com2 => .communication
  -- planning
  | .pln1 | .pln2 | .pln3 | .pln4 | .pln5 => .planning
  -- hypothesis
  | .hyp1 | .hyp2 => .hypothesis

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

end Scenario197
