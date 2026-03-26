/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **legal** (ord=3): 国際法・国内法の法的枠組みと先住民の権利。 [C1, C2, C4]
- **observation** (ord=2): 衛星・ドローンの観測インフラと制約。 [C3, C5]
- **detection** (ord=1): AI検出アルゴリズムの設計判断。データで改善可能。 [H1, H2, H3]
- **hyp** (ord=0): 未検証の仮説。実フィールドで検証が必要。 [H1, H2]
-/

namespace Scenario289

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | leg1
  | leg2
  | leg3
  | leg4
  | obs1
  | obs2
  | obs3
  | det1
  | det2
  | det3
  | det4
  | det5
  | hyp1
  | hyp2
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .leg1 => []
  | .leg2 => []
  | .leg3 => []
  | .leg4 => [.leg1, .leg3]
  | .obs1 => [.leg2]
  | .obs2 => [.leg1]
  | .obs3 => [.obs1, .obs2]
  | .det1 => [.obs1, .obs3]
  | .det2 => [.leg2, .leg4, .obs2]
  | .det3 => [.obs2, .obs3]
  | .det4 => [.det1, .det3]
  | .det5 => [.det2, .det4]
  | .hyp1 => [.det1, .det4]
  | .hyp2 => [.det2, .det5]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 国際法・国内法の法的枠組みと先住民の権利。 (ord=3) -/
  | legal
  /-- 衛星・ドローンの観測インフラと制約。 (ord=2) -/
  | observation
  /-- AI検出アルゴリズムの設計判断。データで改善可能。 (ord=1) -/
  | detection
  /-- 未検証の仮説。実フィールドで検証が必要。 (ord=0) -/
  | hyp
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .legal => 3
  | .observation => 2
  | .detection => 1
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
  nontrivial := ⟨.legal, .hyp, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- legal
  | .leg1 | .leg2 | .leg3 | .leg4 => .legal
  -- observation
  | .obs1 | .obs2 | .obs3 => .observation
  -- detection
  | .det1 | .det2 | .det3 | .det4 | .det5 => .detection
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

end Scenario289
