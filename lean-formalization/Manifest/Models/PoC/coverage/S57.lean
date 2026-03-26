/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **resource** (ord=3): 水資源・法規制に関する不変条件 [C1, C6]
- **cropSafety** (ord=2): 作物保全に関する制約 [C2, C3]
- **planning** (ord=1): 灌漑計画の運用方針 [C4, C5, H2, H3]
- **optimization** (ord=0): AIが自律的に最適化する制御戦略 [H1, H4, H5]
-/

namespace SmartIrrigation

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | res1
  | res2
  | crop1
  | crop2
  | crop3
  | plan1
  | plan2
  | plan3
  | plan4
  | opt1
  | opt2
  | opt3
  | opt4
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .res1 => []
  | .res2 => []
  | .crop1 => [.res1]
  | .crop2 => []
  | .crop3 => [.res2]
  | .plan1 => [.crop1]
  | .plan2 => [.crop1, .res1]
  | .plan3 => [.crop2]
  | .plan4 => [.crop3]
  | .opt1 => [.plan1]
  | .opt2 => [.res1, .plan2]
  | .opt3 => [.plan1, .plan3]
  | .opt4 => [.plan4]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 水資源・法規制に関する不変条件 (ord=3) -/
  | resource
  /-- 作物保全に関する制約 (ord=2) -/
  | cropSafety
  /-- 灌漑計画の運用方針 (ord=1) -/
  | planning
  /-- AIが自律的に最適化する制御戦略 (ord=0) -/
  | optimization
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .resource => 3
  | .cropSafety => 2
  | .planning => 1
  | .optimization => 0

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
  bottom := .optimization
  nontrivial := ⟨.resource, .optimization, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- resource
  | .res1 | .res2 => .resource
  -- cropSafety
  | .crop1 | .crop2 | .crop3 => .cropSafety
  -- planning
  | .plan1 | .plan2 | .plan3 | .plan4 => .planning
  -- optimization
  | .opt1 | .opt2 | .opt3 | .opt4 => .optimization

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

end SmartIrrigation
