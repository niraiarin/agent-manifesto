import Manifest.EpistemicLayer

/-!
# PoC A - Three Layer Manual Implementation

実装形態の比較のためのベースライン。
生成ツールが出力すべき「正解」を確認する。

3 層: foundation (T,E) / derived (P,L) / applied (D)
-/

namespace Manifest.Models.PoC.ThreeLayer

open Manifest
open Manifest.EpistemicLayer

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 3 層の認識論的層。 -/
inductive ConcreteLayer where
  | foundation  -- T, E: 覆らない前提
  | derived     -- P, L: 前提から導出
  | applied     -- D: 環境依存の設計判断
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
  nontrivial := ⟨.foundation, .applied, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨2, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の 3 層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- T: foundation
  | .t1 | .t2 | .t3 | .t4 | .t5 | .t6 | .t7 | .t8 => .foundation
  -- E: foundation
  | .e1 | .e2 => .foundation
  -- P: derived
  | .p1 | .p2 | .p3 | .p4 | .p5 | .p6 => .derived
  -- L: derived
  | .l1 | .l2 | .l3 | .l4 | .l5 | .l6 => .derived
  -- D: applied（d8 は l4 への依存により derived に昇格）
  | .d8 => .derived
  | .d1 | .d2 | .d3 | .d4 | .d5 | .d6 | .d7
  | .d9 | .d10 | .d11 | .d12 | .d13 | .d14 => .applied

-- ============================================================
-- 4. classify_monotone
-- ============================================================

/-- 単調性チェック: 特定ペア。 -/
private def checkMonotone (a b : PropositionId) : Bool :=
  if propositionDependsOn a b then
    decide (ConcreteLayer.ord (classify b) ≥ ConcreteLayer.ord (classify a))
  else true

/-- 全 PropositionId。 -/
private def allProps : List PropositionId :=
  [.t1, .t2, .t3, .t4, .t5, .t6, .t7, .t8,
   .e1, .e2,
   .p1, .p2, .p3, .p4, .p5, .p6,
   .l1, .l2, .l3, .l4, .l5, .l6,
   .d1, .d2, .d3, .d4, .d5, .d6, .d7, .d8,
   .d9, .d10, .d11, .d12, .d13, .d14]

/-- 全ペアの単調性。 -/
private def allMonotone : Bool :=
  allProps.all fun a => allProps.all fun b => checkMonotone a b

/-- classify は依存関係の単調性を尊重する。
    native_decide で全ペアを計算検証。 -/
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
-- 6. LayerAssignment との接続
-- ============================================================

/-- 3 層モデルに基づく LayerAssignment。 -/
def threeLayerAssignment : ManifestoLayerAssignment ConcreteLayer where
  assign := classify
  monotone := classify_monotone
  bounded := ⟨2, fun d => by cases d <;> simp [classify, ConcreteLayer.ord, EpistemicLayerClass.ord]⟩

end Manifest.Models.PoC.ThreeLayer
