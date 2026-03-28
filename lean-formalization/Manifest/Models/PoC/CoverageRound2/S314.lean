/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **food_safety_invariant** (ord=3): 食品安全・回収手順の絶対要件 [C1, C2, C3, C6]
- **traceability_model** (ord=2): 追跡・記録・照会の技術モデル [C1, C4, C5, H1]
- **adoption_hypothesis** (ord=1): 普及・活用に関する仮説 [H2, H3, H4]
-/

namespace TestCoverage.S314

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s314_p01
  | s314_p02
  | s314_p03
  | s314_p04
  | s314_p05
  | s314_p06
  | s314_p07
  | s314_p08
  | s314_p09
  | s314_p10
  | s314_p11
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s314_p01 => []
  | .s314_p02 => [.s314_p01]
  | .s314_p03 => [.s314_p02]
  | .s314_p04 => [.s314_p01]
  | .s314_p05 => [.s314_p01]
  | .s314_p06 => [.s314_p05]
  | .s314_p07 => [.s314_p05]
  | .s314_p08 => [.s314_p02, .s314_p05]
  | .s314_p09 => [.s314_p07]
  | .s314_p10 => [.s314_p06, .s314_p09]
  | .s314_p11 => [.s314_p04, .s314_p08]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 食品安全・回収手順の絶対要件 (ord=3) -/
  | food_safety_invariant
  /-- 追跡・記録・照会の技術モデル (ord=2) -/
  | traceability_model
  /-- 普及・活用に関する仮説 (ord=1) -/
  | adoption_hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .food_safety_invariant => 3
  | .traceability_model => 2
  | .adoption_hypothesis => 1

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
  bottom := .adoption_hypothesis
  nontrivial := ⟨.food_safety_invariant, .adoption_hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- food_safety_invariant
  | .s314_p01 | .s314_p02 | .s314_p03 | .s314_p04 => .food_safety_invariant
  -- traceability_model
  | .s314_p05 | .s314_p06 | .s314_p07 | .s314_p08 => .traceability_model
  -- adoption_hypothesis
  | .s314_p09 | .s314_p10 | .s314_p11 => .adoption_hypothesis

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

end TestCoverage.S314
