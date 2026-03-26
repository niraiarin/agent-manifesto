/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **heritage** (ord=3): 文化財保護の法的・倫理的原則。不可侵。 [C2, C3]
- **practice** (ord=2): 修復師の判断と記録手順。専門知識に基づく。 [C1, C4]
- **analysis** (ord=1): AI分析手法の設計判断。技術進歩で改善可能。 [H1, H2, H3]
- **hyp** (ord=0): 未検証の仮説。実物での検証が必要。 [H1, H2]
-/

namespace Scenario286

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | her1
  | her2
  | her3
  | prc1
  | prc2
  | prc3
  | anl1
  | anl2
  | anl3
  | anl4
  | hyp1
  | hyp2
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .her1 => []
  | .her2 => []
  | .her3 => []
  | .prc1 => [.her1]
  | .prc2 => [.her1, .her2]
  | .prc3 => [.prc1, .prc2]
  | .anl1 => [.her2, .prc2]
  | .anl2 => [.her3, .prc2]
  | .anl3 => [.prc1, .prc3]
  | .anl4 => [.anl1, .anl2]
  | .hyp1 => [.anl1, .anl4]
  | .hyp2 => [.anl2, .anl3]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 文化財保護の法的・倫理的原則。不可侵。 (ord=3) -/
  | heritage
  /-- 修復師の判断と記録手順。専門知識に基づく。 (ord=2) -/
  | practice
  /-- AI分析手法の設計判断。技術進歩で改善可能。 (ord=1) -/
  | analysis
  /-- 未検証の仮説。実物での検証が必要。 (ord=0) -/
  | hyp
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .heritage => 3
  | .practice => 2
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
  nontrivial := ⟨.heritage, .hyp, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- heritage
  | .her1 | .her2 | .her3 => .heritage
  -- practice
  | .prc1 | .prc2 | .prc3 => .practice
  -- analysis
  | .anl1 | .anl2 | .anl3 | .anl4 => .analysis
  -- hyp
  | .hyp1 | .hyp2 => .hyp

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

end Scenario286
