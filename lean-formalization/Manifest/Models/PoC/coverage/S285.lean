/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **geophysics** (ord=4): 地球物理学的制約。太陽-地球間の電磁相互作用の法則。 [C3, C4]
- **gridSafety** (ord=3): 送電網の保護と安全基準。物理的限界で規定。 [C2]
- **operations** (ord=2): 電力系統運用者が設定する運用パラメータ。 [C1, C5]
- **prediction** (ord=1): GIC予測モデルの設計判断。観測データで改善可能。 [H1, H2, H3]
- **hyp** (ord=0): 未検証の仮説。磁気嵐イベントで検証が必要。 [H4]
-/

namespace Scenario285

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | geo1
  | geo2
  | geo3
  | gs1
  | gs2
  | ops1
  | ops2
  | ops3
  | prd1
  | prd2
  | prd3
  | prd4
  | prd5
  | prd6
  | hyp1
  | hyp2
  | hyp3
  | hyp4
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .geo1 => []
  | .geo2 => []
  | .geo3 => []
  | .gs1 => [.geo1]
  | .gs2 => [.geo2, .geo3]
  | .ops1 => [.gs1]
  | .ops2 => [.gs1, .gs2]
  | .ops3 => [.ops1, .ops2]
  | .prd1 => [.geo1, .geo2]
  | .prd2 => [.gs1, .gs2]
  | .prd3 => [.geo2, .geo3]
  | .prd4 => [.prd1, .prd3]
  | .prd5 => [.prd2, .prd4]
  | .prd6 => [.ops3, .prd1]
  | .hyp1 => [.ops2, .prd4]
  | .hyp2 => [.prd5, .prd6]
  | .hyp3 => [.hyp1]
  | .hyp4 => [.hyp2, .hyp3]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 地球物理学的制約。太陽-地球間の電磁相互作用の法則。 (ord=4) -/
  | geophysics
  /-- 送電網の保護と安全基準。物理的限界で規定。 (ord=3) -/
  | gridSafety
  /-- 電力系統運用者が設定する運用パラメータ。 (ord=2) -/
  | operations
  /-- GIC予測モデルの設計判断。観測データで改善可能。 (ord=1) -/
  | prediction
  /-- 未検証の仮説。磁気嵐イベントで検証が必要。 (ord=0) -/
  | hyp
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .geophysics => 4
  | .gridSafety => 3
  | .operations => 2
  | .prediction => 1
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
  nontrivial := ⟨.geophysics, .hyp, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- geophysics
  | .geo1 | .geo2 | .geo3 => .geophysics
  -- gridSafety
  | .gs1 | .gs2 => .gridSafety
  -- operations
  | .ops1 | .ops2 | .ops3 => .operations
  -- prediction
  | .prd1 | .prd2 | .prd3 | .prd4 | .prd5 | .prd6 => .prediction
  -- hyp
  | .hyp1 | .hyp2 | .hyp3 | .hyp4 => .hyp

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

end Scenario285
