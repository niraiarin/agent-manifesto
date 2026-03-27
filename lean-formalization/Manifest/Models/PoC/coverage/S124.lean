/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **BusinessConstraint** (ord=2): 事業運営上の不変前提。経営判断で設定された制約 [C1, C2, C3]
- **DemandModel** (ord=1): 需要予測モデルの設計選択。データに基づき更新 [C4, C5, H1, H2, H3]
- **OperationalTuning** (ord=0): 運用パラメータの微調整。日常的に変動する [H4, H5]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s124_p01
  | s124_p02
  | s124_p03
  | s124_p04
  | s124_p05
  | s124_p06
  | s124_p07
  | s124_p08
  | s124_p09
  | s124_p10
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s124_p01 => []
  | .s124_p02 => []
  | .s124_p03 => []
  | .s124_p04 => [.s124_p01]
  | .s124_p05 => [.s124_p02]
  | .s124_p06 => [.s124_p01, .s124_p03]
  | .s124_p07 => [.s124_p02, .s124_p03]
  | .s124_p08 => [.s124_p04]
  | .s124_p09 => [.s124_p05, .s124_p06]
  | .s124_p10 => [.s124_p07]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 事業運営上の不変前提。経営判断で設定された制約 (ord=2) -/
  | BusinessConstraint
  /-- 需要予測モデルの設計選択。データに基づき更新 (ord=1) -/
  | DemandModel
  /-- 運用パラメータの微調整。日常的に変動する (ord=0) -/
  | OperationalTuning
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .BusinessConstraint => 2
  | .DemandModel => 1
  | .OperationalTuning => 0

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
  bottom := .OperationalTuning
  nontrivial := ⟨.BusinessConstraint, .OperationalTuning, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨2, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- BusinessConstraint
  | .s124_p01 | .s124_p02 | .s124_p03 => .BusinessConstraint
  -- DemandModel
  | .s124_p04 | .s124_p05 | .s124_p06 | .s124_p07 => .DemandModel
  -- OperationalTuning
  | .s124_p08 | .s124_p09 | .s124_p10 => .OperationalTuning

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

end Manifest.Models
