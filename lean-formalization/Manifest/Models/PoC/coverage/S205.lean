/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **physics** (ord=4): 太陽物理の基本法則 [H1, H2]
- **observation** (ord=3): 観測データ・衛星依存 [C1, H3]
- **model** (ord=2): 予測モデル・パラメータ [C2, H4, H5]
- **operation** (ord=1): 運用方針・警報閾値 [C3, H6]
- **hypothesis** (ord=0): 未検証の仮説 [H7]
-/

namespace SolarWindPrediction

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | phys1
  | phys2
  | obs1
  | obs2
  | obs3
  | mod1
  | mod2
  | mod3
  | opr1
  | opr2
  | hyp1
  | hyp2
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .phys1 => []
  | .phys2 => []
  | .obs1 => []
  | .obs2 => [.phys1]
  | .obs3 => [.phys2]
  | .mod1 => [.phys1, .obs1]
  | .mod2 => [.obs2, .obs3]
  | .mod3 => [.phys2]
  | .opr1 => [.mod1]
  | .opr2 => [.mod2, .mod3]
  | .hyp1 => [.opr1]
  | .hyp2 => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 太陽物理の基本法則 (ord=4) -/
  | physics
  /-- 観測データ・衛星依存 (ord=3) -/
  | observation
  /-- 予測モデル・パラメータ (ord=2) -/
  | model
  /-- 運用方針・警報閾値 (ord=1) -/
  | operation
  /-- 未検証の仮説 (ord=0) -/
  | hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .physics => 4
  | .observation => 3
  | .model => 2
  | .operation => 1
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
  nontrivial := ⟨.physics, .hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- physics
  | .phys1 | .phys2 => .physics
  -- observation
  | .obs1 | .obs2 | .obs3 => .observation
  -- model
  | .mod1 | .mod2 | .mod3 => .model
  -- operation
  | .opr1 | .opr2 => .operation
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

end SolarWindPrediction
