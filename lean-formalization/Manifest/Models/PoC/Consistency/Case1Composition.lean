import Manifest.EpistemicLayer

/-!
# Case 1: Composition Contradiction

子が親の axiom を局所的に満たすが、子の定理の合成が親の定理と矛盾するケースを構成する。

## 矛盾の構造

子プロジェクトは局所的に well-formed な `EpistemicLayerClass` と `LayerAssignment` を持つ。
しかし子の命題の「意味」が親の命題と矛盾する場合、Lean の型レベルでは検出されない。
矛盾は `PropositionMapping`（親子の命題対応）と `interprets`（命題の意味論）を
明示的に宣言して初めて検出可能になる。

## 検出パターン

- **静的検出**: 不可能（異なる型上の命題は Lean の型チェックで衝突しない）
- **動的検出**: PropositionMapping を instance-manifest.json に記述し、
  manifest-trace 拡張で cross-reference check を行う
- **手動検出**: 命題の意味論的対応（interprets）は人間が宣言する必要がある
-/

namespace Manifest.Models.PoC.Consistency.Case1

open Manifest
open Manifest.EpistemicLayer

-- ============================================================
-- 1. 子プロジェクトの層構造（局所的に valid）
-- ============================================================

/-- 子プロジェクトの 2 層構造。 -/
inductive ChildLayer where
  | core      -- 不変の前提
  | practice  -- 実践的判断
  deriving BEq, Repr, DecidableEq

def ChildLayer.ord : ChildLayer → Nat
  | .core => 1
  | .practice => 0

instance : EpistemicLayerClass ChildLayer where
  ord := ChildLayer.ord
  bottom := .practice
  nontrivial := ⟨.core, .practice, by simp [ChildLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ChildLayer.ord]
  ord_bounded := ⟨1, fun a => by cases a <;> simp [ChildLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ChildLayer.ord]

-- ============================================================
-- 2. 子の命題型と依存グラフ
-- ============================================================

/-- 子プロジェクトの命題。 -/
inductive ChildProp where
  | stability   -- 「構造は安定を目指す」
  | noAccum     -- 「改善は蓄積しない」（親 T3 と矛盾する意図）
  deriving BEq, Repr, DecidableEq

instance : DependencyGraph ChildProp where
  dependsOn := fun a b => match a, b with
    | .noAccum, .stability => true
    | _, _ => false

-- ============================================================
-- 3. 子の LayerAssignment（局所的に valid）
-- ============================================================

def childClassify : ChildProp → ChildLayer
  | .stability => .core
  | .noAccum => .practice

theorem childClassify_monotone :
    ∀ (a b : ChildProp),
      DependencyGraph.dependsOn a b = true →
      EpistemicLayerClass.ord (childClassify b) ≥ EpistemicLayerClass.ord (childClassify a) := by
  intro a b h
  cases a <;> cases b <;> simp [DependencyGraph.dependsOn] at h <;>
    simp [childClassify, ChildLayer.ord, EpistemicLayerClass.ord]

/-- 子の LayerAssignment は局所的に well-formed。lake build は成功する。 -/
def childAssignment : LayerAssignment ChildProp ChildLayer where
  assign := childClassify
  monotone := childClassify_monotone
  bounded := ⟨1, fun d => by cases d <;> simp [childClassify, ChildLayer.ord, EpistemicLayerClass.ord]⟩

-- ============================================================
-- 4. 矛盾の構成（意味論レベル）
-- ============================================================

/-- 親子間の命題対応。brownfield Phase 4 で人間が宣言する。 -/
structure PropositionMapping (Child : Type) where
  /-- 子の命題が親のどの命題に対応するか。 -/
  mapToParent : Child → Option PropositionId

/-- 対応関係の例: noAccum は T3 に対応。 -/
def exampleMapping : PropositionMapping ChildProp where
  mapToParent
    | .noAccum => some .t3
    | .stability => none

/-- 命題の意味論的内容を Prop として表す。
    これは人間が定義する（judgmental）。 -/
class Interprets (P : Type) where
  meaning : P → Prop

/-- 子の noAccum: 「いかなる性質も保持されない」。
    親の T3 (self_improvement): 「改善が蓄積する構造が存在する」と矛盾する。 -/
instance : Interprets ChildProp where
  meaning
    | .stability => True
    | .noAccum => ∀ (p : Prop), ¬p  -- 極端な否定（矛盾を明確にするため）

/-- 親の T3 から導出される帰結の Prop 表現。 -/
def parent_t3_meaning : Prop := ∃ (_ : Prop), True

/-- 矛盾の証明:
    子の noAccum の意味と親の T3 の意味が同時に成立すると False。 -/
theorem composition_contradiction
    (h_child : Interprets.meaning ChildProp.noAccum)
    (_h_parent : parent_t3_meaning) : False := by
  simp [Interprets.meaning] at h_child
  exact h_child True trivial

-- ============================================================
-- 5. 要約: なぜ型レベルで検出できないか
-- ============================================================

/-- childAssignment が well-formed であることの再確認。
    型レベルでは何の問題もない — 矛盾は意味論レベルにのみ存在する。 -/
example : LayerAssignment ChildProp ChildLayer := childAssignment

end Manifest.Models.PoC.Consistency.Case1
