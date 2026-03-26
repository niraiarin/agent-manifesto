/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **safety_invariant** (ord=5): 患者の生命に直結する不変安全条件。通信途絶時の即時フェイルセーフ [C1, C2]
- **regulatory** (ord=4): 医療機器通信の法規制・認証要件 [C3, H1]
- **physical_constraint** (ord=3): 通信物理層の特性。遅延・帯域・ジッタの物理的限界 [H2, H3]
- **protocol** (ord=2): QoS保証プロトコル。冗長経路・優先制御 [C4, H4]
- **optimization** (ord=1): 帯域最適化・圧縮戦略 [H5, H6]
- **hypothesis** (ord=0): 未検証の通信品質仮説 [H7]
-/

namespace TestScenario.S261

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | sf1
  | sf2
  | sf3
  | rg1
  | rg2
  | ph1
  | ph2
  | pr1
  | pr2
  | op1
  | op2
  | hy1
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .sf1 => []
  | .sf2 => []
  | .sf3 => []
  | .rg1 => [.sf1]
  | .rg2 => [.sf2]
  | .ph1 => []
  | .ph2 => [.rg1]
  | .pr1 => [.sf1, .ph1]
  | .pr2 => [.rg2, .ph2]
  | .op1 => [.pr1]
  | .op2 => [.ph1, .pr2]
  | .hy1 => [.op1]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 患者の生命に直結する不変安全条件。通信途絶時の即時フェイルセーフ (ord=5) -/
  | safety_invariant
  /-- 医療機器通信の法規制・認証要件 (ord=4) -/
  | regulatory
  /-- 通信物理層の特性。遅延・帯域・ジッタの物理的限界 (ord=3) -/
  | physical_constraint
  /-- QoS保証プロトコル。冗長経路・優先制御 (ord=2) -/
  | protocol
  /-- 帯域最適化・圧縮戦略 (ord=1) -/
  | optimization
  /-- 未検証の通信品質仮説 (ord=0) -/
  | hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .safety_invariant => 5
  | .regulatory => 4
  | .physical_constraint => 3
  | .protocol => 2
  | .optimization => 1
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
  nontrivial := ⟨.safety_invariant, .hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- safety_invariant
  | .sf1 | .sf2 | .sf3 => .safety_invariant
  -- regulatory
  | .rg1 | .rg2 => .regulatory
  -- physical_constraint
  | .ph1 | .ph2 => .physical_constraint
  -- protocol
  | .pr1 | .pr2 => .protocol
  -- optimization
  | .op1 | .op2 => .optimization
  -- hypothesis
  | .hy1 => .hypothesis

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

end TestScenario.S261
