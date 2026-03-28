/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **axiom** (ord=1): Layer axiom [auto]
- **postulate** (ord=0): Layer postulate [auto]
-/

namespace TestScenario.S85

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | a1
  | b1
  | c1
  | d1
  | e1
  | f1
  | g1
  | h1
  | i1
  | j1
  | k1
  | l1
  | m1
  | n1
  | p1
  | q1
  | r1
  | s1
  | t1
  | u1
  | a2
  | b2
  | c2
  | d2
  | e2
  | f2
  | g2
  | h2
  | i2
  | j2
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .a1 => []
  | .b1 => [.a1]
  | .c1 => []
  | .d1 => [.b1, .c1]
  | .e1 => [.b1]
  | .f1 => [.d1]
  | .g1 => [.a1, .d1]
  | .h1 => []
  | .i1 => [.a1, .c1, .e1]
  | .j1 => [.c1, .g1]
  | .k1 => [.a1, .b1, .c1, .h1, .i1]
  | .l1 => [.a1, .d1, .e1, .f1, .j1]
  | .m1 => [.h1]
  | .n1 => [.j1]
  | .p1 => [.a1, .i1, .j1, .l1, .n1]
  | .q1 => [.b1, .g1, .i1, .k1]
  | .r1 => [.e1, .f1, .j1, .m1, .n1, .q1]
  | .s1 => [.b1, .c1, .i1, .j1, .p1]
  | .t1 => [.a1, .m1, .r1]
  | .u1 => [.d1, .i1, .n1, .q1, .r1]
  | .a2 => [.c1, .e1, .n1, .p1, .q1]
  | .b2 => [.c1, .i1, .j1, .n1, .r1, .s1, .a2]
  | .c2 => [.f1, .h1, .i1, .q1, .r1]
  | .d2 => [.d1, .e1, .k1, .l1, .n1, .q1, .b2]
  | .e2 => [.a1, .c1, .d1, .h1, .i1, .k1, .l1, .m1, .n1, .q1, .a2, .b2]
  | .f2 => [.b1, .i1, .l1, .c2, .e2]
  | .g2 => [.a1, .i1, .j1, .k1, .m1, .n1, .p1]
  | .h2 => [.c1, .d1, .f1, .j1, .l1, .m1, .p1, .t1]
  | .i2 => [.d1, .e1, .h1, .k1, .l1, .m1, .q1, .s1, .b2, .d2]
  | .j2 => [.c1, .f1, .g1, .h1, .k1, .n1, .s1, .t1, .u1, .a2, .d2, .g2, .i2]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- Layer axiom (ord=1) -/
  | axiom
  /-- Layer postulate (ord=0) -/
  | postulate
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .axiom => 1
  | .postulate => 0

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
  bottom := .postulate
  nontrivial := ⟨.axiom, .postulate, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨1, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- axiom
  | .a1 | .b1 | .c1 | .d1 | .e1 | .f1 | .g1 | .h1 | .i1 | .j1 | .k1 | .l1 | .m1 | .n1 | .p1 => .axiom
  -- postulate
  | .q1 | .r1 | .s1 | .t1 | .u1 | .a2 | .b2 | .c2 | .d2 | .e2 | .f2 | .g2 | .h2 | .i2 | .j2 => .postulate

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

end TestScenario.S85
