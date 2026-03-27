/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **physical_law** (ord=5): 物理法則・化学法則に基づく不変制約 [C1]
- **safety_constraint** (ord=4): 安全に関する絶対的制約 [C2]
- **accuracy_requirement** (ord=3): 精度・信頼性に関する要件 [C3, H1]
- **domain_rule** (ord=2): 対象領域の運用ルール [C4, C5]
- **implementation_choice** (ord=1): 実装手法の選択 [H3, H4]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | prop_7f6630
  | prop_94524a
  | prop_104185
  | prop_d07ffe
  | prop_90d1e0
  | GHS_d4f7d4
  | prop_3d827d
  | DFTBLYPG_d80a1f
  | NEB_bce94a
  | ML_a2085f
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .prop_7f6630 => []
  | .prop_94524a => []
  | .prop_104185 => []
  | .prop_d07ffe => []
  | .prop_90d1e0 => []
  | .GHS_d4f7d4 => []
  | .prop_3d827d => []
  | .DFTBLYPG_d80a1f => []
  | .NEB_bce94a => []
  | .ML_a2085f => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 物理法則・化学法則に基づく不変制約 (ord=5) -/
  | physical_law
  /-- 安全に関する絶対的制約 (ord=4) -/
  | safety_constraint
  /-- 精度・信頼性に関する要件 (ord=3) -/
  | accuracy_requirement
  /-- 対象領域の運用ルール (ord=2) -/
  | domain_rule
  /-- 実装手法の選択 (ord=1) -/
  | implementation_choice
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .physical_law => 5
  | .safety_constraint => 4
  | .accuracy_requirement => 3
  | .domain_rule => 2
  | .implementation_choice => 1

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
  bottom := .implementation_choice
  nontrivial := ⟨.physical_law, .implementation_choice, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- physical_law
  | .prop_7f6630 | .prop_94524a => .physical_law
  -- safety_constraint
  | .prop_104185 => .safety_constraint
  -- accuracy_requirement
  | .prop_d07ffe | .prop_90d1e0 => .accuracy_requirement
  -- domain_rule
  | .GHS_d4f7d4 | .prop_3d827d => .domain_rule
  -- implementation_choice
  | .DFTBLYPG_d80a1f | .NEB_bce94a | .ML_a2085f => .implementation_choice

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
