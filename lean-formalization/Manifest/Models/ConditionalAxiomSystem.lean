import Manifest.EpistemicLayer

/-!
# 条件付き公理体系（生成済み）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。

手動で編集しないでください。仮定の変更は Assumptions/ 以下で行い、
再生成してください。

## 層構造

- **foundation** (ord=2): 覆らない前提 (T, E) [C1]
- **derived** (ord=1): 前提から導出 (P, L, D8) [H1]
- **applied** (ord=0): 環境依存の設計判断 (D) [H2]
-/

namespace Manifest.Models

open Manifest
open Manifest.EpistemicLayer

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 覆らない前提 (T, E) (ord=2) -/
  | foundation
  /-- 前提から導出 (P, L, D8) (ord=1) -/
  | derived
  /-- 環境依存の設計判断 (D) (ord=0) -/
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
  nontrivial := ⟨.foundation, .applied, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨2, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- foundation
  | .t1 | .t2 | .t3 | .t4 | .t5 | .t6 | .t7 | .t8 | .e1 | .e2 => .foundation
  -- derived
  | .p1 | .p2 | .p3 | .p4 | .p5 | .p6 | .l1 | .l2 | .l3 | .l4 | .l5 | .l6 | .d8 => .derived
  -- applied
  | .d1 | .d2 | .d3 | .d4 | .d5 | .d6 | .d7 | .d9 | .d10 | .d11 | .d12 | .d13 | .d14 => .applied

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
