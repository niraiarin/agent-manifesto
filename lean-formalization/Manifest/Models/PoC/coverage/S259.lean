/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **oceanography** (ord=3): 海洋物理と氷山力学の法則に基づく制約。 [C2, C3]
- **maritime** (ord=2): 航行安全と国際規格に基づく制約。 [C1, C4]
- **tracking** (ord=1): 追跡・予測手法の設計判断。技術進歩に応じて改善可能。 [H1, H2]
- **hypothesis** (ord=0): 未検証の仮説。運用データで検証が必要。 [H3]
-/

namespace Scenario259

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | ocn1
  | ocn2
  | ocn3
  | mar1
  | mar2
  | trk1
  | trk2
  | trk3
  | trk4
  | hyp1
  | hyp2
  | hyp3
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .ocn1 => []
  | .ocn2 => []
  | .ocn3 => []
  | .mar1 => []
  | .mar2 => [.mar1]
  | .trk1 => [.ocn1, .ocn3]
  | .trk2 => [.ocn2]
  | .trk3 => [.trk1, .trk2]
  | .trk4 => [.ocn1, .mar2]
  | .hyp1 => [.mar2, .trk3]
  | .hyp2 => [.trk4]
  | .hyp3 => [.hyp1, .hyp2]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 海洋物理と氷山力学の法則に基づく制約。 (ord=3) -/
  | oceanography
  /-- 航行安全と国際規格に基づく制約。 (ord=2) -/
  | maritime
  /-- 追跡・予測手法の設計判断。技術進歩に応じて改善可能。 (ord=1) -/
  | tracking
  /-- 未検証の仮説。運用データで検証が必要。 (ord=0) -/
  | hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .oceanography => 3
  | .maritime => 2
  | .tracking => 1
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
  nontrivial := ⟨.oceanography, .hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- oceanography
  | .ocn1 | .ocn2 | .ocn3 => .oceanography
  -- maritime
  | .mar1 | .mar2 => .maritime
  -- tracking
  | .trk1 | .trk2 | .trk3 | .trk4 => .tracking
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

end Scenario259
