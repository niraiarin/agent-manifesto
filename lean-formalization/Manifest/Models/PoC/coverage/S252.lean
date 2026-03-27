/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **craft** (ord=2): 職人の権威と工房の伝統に関わる不可侵の前提。 [C1, C2, C4]
- **engineering** (ord=1): 科学的手法に基づく支援技術。精度向上に応じて改善可能。 [C3, H1, H2]
- **hypothesis** (ord=0): 効果が未検証の仮説。実験で確認が必要。 [H3]
-/

namespace Scenario252

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | cra1
  | cra2
  | cra3
  | eng1
  | eng2
  | eng3
  | eng4
  | hyp1
  | hyp2
  | hyp3
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .cra1 => []
  | .cra2 => []
  | .cra3 => []
  | .eng1 => [.cra1]
  | .eng2 => [.cra2]
  | .eng3 => [.cra1, .cra2]
  | .eng4 => [.eng1, .eng2]
  | .hyp1 => [.cra3]
  | .hyp2 => [.eng1, .hyp1]
  | .hyp3 => [.eng4]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 職人の権威と工房の伝統に関わる不可侵の前提。 (ord=2) -/
  | craft
  /-- 科学的手法に基づく支援技術。精度向上に応じて改善可能。 (ord=1) -/
  | engineering
  /-- 効果が未検証の仮説。実験で確認が必要。 (ord=0) -/
  | hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .craft => 2
  | .engineering => 1
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
  nontrivial := ⟨.craft, .hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨2, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- craft
  | .cra1 | .cra2 | .cra3 => .craft
  -- engineering
  | .eng1 | .eng2 | .eng3 | .eng4 => .engineering
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

end Scenario252
