/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **tradition** (ord=2): 伝統技法と師匠の権限に関わる不可侵の前提。 [C1, C2, C3]
- **method** (ord=1): 技術記録・支援の手法。技術進歩に応じて改善可能。 [C4, H1, H2]
- **hypothesis** (ord=0): 効果が未検証の仮説。実地テストで確認が必要。 [H3]
-/

namespace Scenario194

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | trad1
  | trad2
  | trad3
  | trad4
  | meth1
  | meth2
  | meth3
  | meth4
  | hyp1
  | hyp2
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .trad1 => []
  | .trad2 => []
  | .trad3 => []
  | .trad4 => [.trad1]
  | .meth1 => [.trad1, .trad2]
  | .meth2 => [.trad3, .trad4]
  | .meth3 => [.trad2]
  | .meth4 => [.meth1, .meth2]
  | .hyp1 => [.trad1, .meth1]
  | .hyp2 => [.meth2, .meth4]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 伝統技法と師匠の権限に関わる不可侵の前提。 (ord=2) -/
  | tradition
  /-- 技術記録・支援の手法。技術進歩に応じて改善可能。 (ord=1) -/
  | method
  /-- 効果が未検証の仮説。実地テストで確認が必要。 (ord=0) -/
  | hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .tradition => 2
  | .method => 1
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
  ord_bounded := ⟨2, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- tradition
  | .trad1 | .trad2 | .trad3 | .trad4 => .tradition
  -- method
  | .meth1 | .meth2 | .meth3 | .meth4 => .method
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

end Scenario194
