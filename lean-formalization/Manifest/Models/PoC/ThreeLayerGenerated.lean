import Manifest.EpistemicLayer

/-!
# 生成された条件付き公理体系

このファイルは generate-model.sh によって自動生成されました。
手動で編集しないでください。
-/

namespace Manifest.Models.PoC.ThreeLayerGenerated

open Manifest
open Manifest.EpistemicLayer

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  | foundation
  | derived
  | applied
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .foundation => 2
  | .derived => 1
  | .applied => 0

instance : EpistemicLayerClass ConcreteLayer where
  ord := ConcreteLayer.ord
  bottom := .applied
  nontrivial := by
    exact ⟨.foundation, .applied, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨2, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  | .t1 => .foundation
  | .t2 => .foundation
  | .t3 => .foundation
  | .t4 => .foundation
  | .t5 => .foundation
  | .t6 => .foundation
  | .t7 => .foundation
  | .t8 => .foundation
  | .e1 => .foundation
  | .e2 => .foundation
  | .p1 => .derived
  | .p2 => .derived
  | .p3 => .derived
  | .p4 => .derived
  | .p5 => .derived
  | .p6 => .derived
  | .l1 => .derived
  | .l2 => .derived
  | .l3 => .derived
  | .l4 => .derived
  | .l5 => .derived
  | .l6 => .derived
  | .d8 => .derived
  | .d1 => .applied
  | .d2 => .applied
  | .d3 => .applied
  | .d4 => .applied
  | .d5 => .applied
  | .d6 => .applied
  | .d7 => .applied
  | .d9 => .applied
  | .d10 => .applied
  | .d11 => .applied
  | .d12 => .applied
  | .d13 => .applied
  | .d14 => .applied

-- ============================================================
-- 4. classify_monotone
-- ============================================================

/-- classify は依存関係の単調性を尊重する。 -/
theorem classify_monotone :
    ∀ (a b : PropositionId),
      propositionDependsOn a b = true →
      ConcreteLayer.ord (classify b) ≥ ConcreteLayer.ord (classify a) := by
  intro a b h; cases a <;> cases b <;> revert h <;> native_decide

-- ============================================================
-- 5. classify_total
-- ============================================================

/-- classify は全域関数。 -/
theorem classify_total :
    ∀ (p : PropositionId), ∃ (l : ConcreteLayer), classify p = l :=
  fun p => ⟨classify p, rfl⟩

-- ============================================================
-- 6. LayerAssignment
-- ============================================================

/-- 生成されたモデルに基づく LayerAssignment。 -/
def generatedAssignment : LayerAssignment ConcreteLayer where
  assign := classify
  monotone := classify_monotone
  bounded := ⟨2, fun d => by cases d <;> simp [classify, ConcreteLayer.ord, EpistemicLayerClass.ord]⟩

end Manifest.Models.PoC.ThreeLayerGenerated
