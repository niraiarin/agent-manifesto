import Manifest.EpistemicLayer

/-!
# 条件付き公理体系（生成済み）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。

手動で編集しないでください。仮定の変更は Assumptions/ 以下で行い、
再生成してください。

## 層構造

- **constraint** (ord=5): 否定不可能な構造的事実。公理系の核 [C1, H2]
- **empiricalPostulate** (ord=4): 反例が知られていないが覆りうる知見 [C4, H3]
- **principle** (ord=3): T/Eから導出される設計原理 [C2, H4]
- **boundary** (ord=2): 原理の具体的適用としての境界条件 [C3, C5, H5]
- **designTheorem** (ord=1): 境界条件・原理から導出される設計定理 [H6]
- **hypothesis** (ord=0): 未検証の仮説。現行36命題には未使用 [H9]
-/

namespace Manifest.Models

open Manifest
open Manifest.EpistemicLayer

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 否定不可能な構造的事実。公理系の核 (ord=5) -/
  | constraint
  /-- 反例が知られていないが覆りうる知見 (ord=4) -/
  | empiricalPostulate
  /-- T/Eから導出される設計原理 (ord=3) -/
  | principle
  /-- 原理の具体的適用としての境界条件 (ord=2) -/
  | boundary
  /-- 境界条件・原理から導出される設計定理 (ord=1) -/
  | designTheorem
  /-- 未検証の仮説。現行36命題には未使用 (ord=0) -/
  | hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .constraint => 5
  | .empiricalPostulate => 4
  | .principle => 3
  | .boundary => 2
  | .designTheorem => 1
  | .hypothesis => 0

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

/-- 全命題の層分類。各ケースの根拠は Assumptions に記録。 -/
def classify : PropositionId → ConcreteLayer
  -- constraint
  | .t1 | .t2 | .t3 | .t4 | .t5 | .t6 | .t7 | .t8 => .constraint
  -- empiricalPostulate
  | .e1 | .e2 => .empiricalPostulate
  -- principle
  | .p1 | .p2 | .p3 | .p4 | .p5 | .p6 => .principle
  -- boundary
  | .l1 | .l2 | .l3 | .l4 | .l5 | .l6 | .d8 => .boundary
  -- designTheorem
  | .d1 | .d2 | .d3 | .d4 | .d5 | .d6 | .d7 | .d9 | .d10 | .d11 | .d12 | .d13 | .d14 => .designTheorem

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

-- ============================================================
-- 5. LayerAssignment
-- ============================================================

/-- 生成されたモデルに基づく LayerAssignment。 -/
def generatedAssignment : LayerAssignment ConcreteLayer where
  assign := classify
  monotone := classify_monotone
  bounded := ⟨5, fun d => by cases d <;> simp [classify, ConcreteLayer.ord, EpistemicLayerClass.ord]⟩

end Manifest.Models
