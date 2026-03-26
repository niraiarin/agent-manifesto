/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **cultural_heritage_law** (ord=4): 文化財保護法・修復原則（ヴェネツィア憲章）。可逆性・真正性 [C1, C2]
- **structural_principle** (ord=3): 伝統構法の力学原理。木組み・石積みの構造力学 [C3, H1]
- **material_knowledge** (ord=2): 伝統材料の特性。木材樹種・漆喰配合・金属加工 [H2, H3]
- **restoration_plan** (ord=1): 修復工法の選定・工程計画 [H4, H5]
- **assessment** (ord=0): 劣化度推定・優先度判定の仮説 [H6]
-/

namespace TestScenario.S266

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | cl1
  | cl2
  | sp1
  | sp2
  | mk1
  | mk2
  | mk3
  | rp1
  | rp2
  | as1
  | as2
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .cl1 => []
  | .cl2 => []
  | .sp1 => [.cl1]
  | .sp2 => []
  | .mk1 => [.sp1, .sp2]
  | .mk2 => [.cl2]
  | .mk3 => [.sp1]
  | .rp1 => [.mk1, .cl1]
  | .rp2 => [.mk2, .mk3]
  | .as1 => [.rp1]
  | .as2 => [.mk1, .rp2]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 文化財保護法・修復原則（ヴェネツィア憲章）。可逆性・真正性 (ord=4) -/
  | cultural_heritage_law
  /-- 伝統構法の力学原理。木組み・石積みの構造力学 (ord=3) -/
  | structural_principle
  /-- 伝統材料の特性。木材樹種・漆喰配合・金属加工 (ord=2) -/
  | material_knowledge
  /-- 修復工法の選定・工程計画 (ord=1) -/
  | restoration_plan
  /-- 劣化度推定・優先度判定の仮説 (ord=0) -/
  | assessment
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .cultural_heritage_law => 4
  | .structural_principle => 3
  | .material_knowledge => 2
  | .restoration_plan => 1
  | .assessment => 0

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
  bottom := .assessment
  nontrivial := ⟨.cultural_heritage_law, .assessment, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- cultural_heritage_law
  | .cl1 | .cl2 => .cultural_heritage_law
  -- structural_principle
  | .sp1 | .sp2 => .structural_principle
  -- material_knowledge
  | .mk1 | .mk2 | .mk3 => .material_knowledge
  -- restoration_plan
  | .rp1 | .rp2 => .restoration_plan
  -- assessment
  | .as1 | .as2 => .assessment

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

end TestScenario.S266
