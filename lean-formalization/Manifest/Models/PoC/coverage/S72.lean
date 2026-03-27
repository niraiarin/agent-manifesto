/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **revenue_constraint** (ord=4): 収益管理の不変制約（法規制・契約上限・最低料金） [C1, C2]
- **demand_postulate** (ord=3): 需要予測の前提となる統計的・市場的仮定 [C3, H1]
- **pricing_principle** (ord=2): 価格決定の原則（公平性・透明性・競争力） [C4, C5, H2]
- **adjustment_design** (ord=1): 価格調整の実装レベルの設計判断 [H3, H4, H5]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | prop_abdd49
  | OTA_cdaaaf
  | prop_3c7a9f
  | prop_9c403d
  | prop_fc7690
  | prop_eb27c1
  | prop_62cdb6
  | prop_175104
  | prop_3b3160
  | prop_9ac64b
  | prop_5119d5
  | prop_e53603
  | prop_fb0eac
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .prop_abdd49 => []
  | .OTA_cdaaaf => []
  | .prop_3c7a9f => []
  | .prop_9c403d => []
  | .prop_fc7690 => []
  | .prop_eb27c1 => []
  | .prop_62cdb6 => []
  | .prop_175104 => []
  | .prop_3b3160 => []
  | .prop_9ac64b => []
  | .prop_5119d5 => []
  | .prop_e53603 => []
  | .prop_fb0eac => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 収益管理の不変制約（法規制・契約上限・最低料金） (ord=4) -/
  | revenue_constraint
  /-- 需要予測の前提となる統計的・市場的仮定 (ord=3) -/
  | demand_postulate
  /-- 価格決定の原則（公平性・透明性・競争力） (ord=2) -/
  | pricing_principle
  /-- 価格調整の実装レベルの設計判断 (ord=1) -/
  | adjustment_design
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .revenue_constraint => 4
  | .demand_postulate => 3
  | .pricing_principle => 2
  | .adjustment_design => 1

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
  bottom := .adjustment_design
  nontrivial := ⟨.revenue_constraint, .adjustment_design, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- revenue_constraint
  | .prop_abdd49 | .OTA_cdaaaf | .prop_3c7a9f => .revenue_constraint
  -- demand_postulate
  | .prop_9c403d | .prop_fc7690 | .prop_eb27c1 => .demand_postulate
  -- pricing_principle
  | .prop_62cdb6 | .prop_175104 | .prop_3b3160 => .pricing_principle
  -- adjustment_design
  | .prop_9ac64b | .prop_5119d5 | .prop_e53603 | .prop_fb0eac => .adjustment_design

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
