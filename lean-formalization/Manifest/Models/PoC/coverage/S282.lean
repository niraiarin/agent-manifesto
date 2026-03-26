/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **regulation** (ord=3): 食品衛生法に基づく法的基準。変更には法改正が必要。 [C1]
- **procedure** (ord=2): 検査手順と品質保証プロセス。検査員の権限で設定。 [C2, C3]
- **analysis** (ord=1): AIの分析アルゴリズムと判定ロジック。データで改善可能。 [C4, H1, H2, H3]
- **hyp** (ord=0): 未検証の仮説。実データで検証が必要。 [H2, H3]
-/

namespace Scenario282

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | reg1
  | reg2
  | proc1
  | proc2
  | proc3
  | anl1
  | anl2
  | anl3
  | anl4
  | anl5
  | hyp1
  | hyp2
  | hyp3
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .reg1 => []
  | .reg2 => []
  | .proc1 => [.reg1]
  | .proc2 => [.reg1]
  | .proc3 => [.reg2, .proc1]
  | .anl1 => [.reg1, .proc2]
  | .anl2 => [.proc1]
  | .anl3 => [.anl1, .anl2]
  | .anl4 => [.proc2, .proc3]
  | .anl5 => [.reg2, .anl4]
  | .hyp1 => [.anl2, .anl3]
  | .hyp2 => [.anl4]
  | .hyp3 => [.anl5, .hyp1]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 食品衛生法に基づく法的基準。変更には法改正が必要。 (ord=3) -/
  | regulation
  /-- 検査手順と品質保証プロセス。検査員の権限で設定。 (ord=2) -/
  | procedure
  /-- AIの分析アルゴリズムと判定ロジック。データで改善可能。 (ord=1) -/
  | analysis
  /-- 未検証の仮説。実データで検証が必要。 (ord=0) -/
  | hyp
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .regulation => 3
  | .procedure => 2
  | .analysis => 1
  | .hyp => 0

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
  bottom := .hyp
  nontrivial := ⟨.regulation, .hyp, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- regulation
  | .reg1 | .reg2 => .regulation
  -- procedure
  | .proc1 | .proc2 | .proc3 => .procedure
  -- analysis
  | .anl1 | .anl2 | .anl3 | .anl4 | .anl5 => .analysis
  -- hyp
  | .hyp1 | .hyp2 | .hyp3 => .hyp

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

end Scenario282
