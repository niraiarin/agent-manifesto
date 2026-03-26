/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **constraint** (ord=5): 法的・倫理的絶対制約 [C1, C2]
- **physics** (ord=4): 物理法則・水面力学 [H1, H2]
- **environment** (ord=3): 気象・潮流等の外部環境 [H3, H4]
- **racer** (ord=2): 選手・モーター特性 [C3, H5]
- **strategy** (ord=1): 賭け戦略・資金管理 [C4, H6]
- **hypothesis** (ord=0): 未検証の仮説 [H7]
-/

namespace BoatRacePrediction

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | con1
  | con2
  | phy1
  | phy2
  | envr1
  | envr2
  | rac1
  | rac2
  | str1
  | str2
  | str3
  | hyp1
  | hyp2
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .con1 => []
  | .con2 => []
  | .phy1 => []
  | .phy2 => [.phy1]
  | .envr1 => []
  | .envr2 => [.phy1]
  | .rac1 => [.envr1]
  | .rac2 => [.phy2, .envr2]
  | .str1 => [.con1, .rac1]
  | .str2 => [.con2, .rac2]
  | .str3 => [.str1]
  | .hyp1 => [.str3]
  | .hyp2 => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 法的・倫理的絶対制約 (ord=5) -/
  | constraint
  /-- 物理法則・水面力学 (ord=4) -/
  | physics
  /-- 気象・潮流等の外部環境 (ord=3) -/
  | environment
  /-- 選手・モーター特性 (ord=2) -/
  | racer
  /-- 賭け戦略・資金管理 (ord=1) -/
  | strategy
  /-- 未検証の仮説 (ord=0) -/
  | hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .constraint => 5
  | .physics => 4
  | .environment => 3
  | .racer => 2
  | .strategy => 1
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
  nontrivial := ⟨.constraint, .hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- constraint
  | .con1 | .con2 => .constraint
  -- physics
  | .phy1 | .phy2 => .physics
  -- environment
  | .envr1 | .envr2 => .environment
  -- racer
  | .rac1 | .rac2 => .racer
  -- strategy
  | .str1 | .str2 | .str3 => .strategy
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

end BoatRacePrediction
