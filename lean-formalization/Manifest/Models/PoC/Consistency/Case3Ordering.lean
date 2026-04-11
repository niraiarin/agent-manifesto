import Manifest.EpistemicLayer

/-!
# Case 3: Ordering Contradiction

子の `LayerAssignment ChildProp ChildLayer` の `monotone` 条件が、
親の `ManifestoLayerAssignment L` の順序と不整合になるケースを構成する。

## 矛盾の構造

親の `DependencyGraph PropositionId` は `propositionDependsOn` で定義され、
例えば D1 は P1 に依存する（D1 → P1、P1 の ord ≥ D1 の ord）。

子プロジェクトが親の命題の一部を再利用しつつ、依存方向を逆転させた
`DependencyGraph` を定義すると、両方の `LayerAssignment` が局所的に valid でも
合成すると順序矛盾が生じる。

## 検出パターン

- **静的検出**: 可能 — 子が `PropositionId` を直接再利用する場合、
  2 つの `DependencyGraph PropositionId` instance が競合し Lean がエラー
- **動的検出**: 子が独自の命題型を使う場合、instance-manifest.json の
  axiom_to_config マッピングを比較して順序の逆転を検出
- **自動化分類**: 静的検出は deterministic、動的検出は bounded
-/

namespace Manifest.Models.PoC.Consistency.Case3

open Manifest
open Manifest.EpistemicLayer

-- ============================================================
-- 1. 子の命題型（親の PropositionId とは別）
-- ============================================================

/-- 子の命題型。親の命題の一部に対応するが、独自の型として定義。
    親の依存: D1 → P5（D1 は P5 に依存、Ontology.lean:1145）。
    子は逆方向の依存を定義する。 -/
inductive ChildProp where
  | childP5  -- 親の P5 に対応する意図
  | childD1  -- 親の D1 に対応する意図
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. 子の DependencyGraph（親と逆方向）
-- ============================================================

/-- 子の依存グラフ: childP5 が childD1 に依存する（P5 → D1）。
    親では D1 → P5（D1 は P5 に依存）なので、方向が逆。 -/
instance : DependencyGraph ChildProp where
  dependsOn := fun a b => match a, b with
    | .childP5, .childD1 => true  -- P5 → D1: 親とは逆方向
    | _, _ => false

-- ============================================================
-- 3. 子の層構造
-- ============================================================

/-- 子の 2 層構造。 -/
inductive ChildLayer where
  | high  -- ord = 1
  | low   -- ord = 0
  deriving BEq, Repr, DecidableEq

def ChildLayer.ord : ChildLayer → Nat
  | .high => 1
  | .low => 0

instance : EpistemicLayerClass ChildLayer where
  ord := ChildLayer.ord
  bottom := .low
  nontrivial := ⟨.high, .low, by simp [ChildLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ChildLayer.ord]
  ord_bounded := ⟨1, fun a => by cases a <;> simp [ChildLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ChildLayer.ord]

-- ============================================================
-- 4. 子の LayerAssignment（局所的に valid）
-- ============================================================

/-- 子の分類: childD1 は high（依存先なので monotone を満たすため）。
    childP5 は low（childD1 に依存するので、依存先 ≥ 依存元を満たす）。 -/
def childClassify : ChildProp → ChildLayer
  | .childP5 => .low    -- 依存元: ord = 0
  | .childD1 => .high   -- 依存先: ord = 1 ≥ 0 ✓

theorem childClassify_monotone :
    ∀ (a b : ChildProp),
      DependencyGraph.dependsOn a b = true →
      EpistemicLayerClass.ord (childClassify b) ≥ EpistemicLayerClass.ord (childClassify a) := by
  intro a b h
  cases a <;> cases b <;> simp [DependencyGraph.dependsOn] at h <;>
    simp [childClassify, ChildLayer.ord, EpistemicLayerClass.ord]

/-- 子の LayerAssignment は局所的に valid。 -/
def childAssignment : LayerAssignment ChildProp ChildLayer where
  assign := childClassify
  monotone := childClassify_monotone
  bounded := ⟨1, fun d => by cases d <;> simp [childClassify, ChildLayer.ord, EpistemicLayerClass.ord]⟩

-- ============================================================
-- 5. 親の依存方向の確認
-- ============================================================

/-- 親の依存グラフでは D1 は P5 に依存する（D1 → P5）。
    Ontology.lean:1145: `.d1 => [.p5, .l1, .l2, .l3, .l4, .l5, .l6]` -/
theorem parent_d1_depends_p5 :
    propositionDependsOn .d1 .p5 = true := by native_decide

/-- 親の依存グラフでは P5 は D1 に依存しない。 -/
theorem parent_p5_not_depends_d1 :
    propositionDependsOn .p5 .d1 = false := by native_decide

-- ============================================================
-- 6. 矛盾の構成
-- ============================================================

/-- 親子の命題対応。 -/
structure OrderMapping where
  toParent : ChildProp → PropositionId

/-- 対応: childP5 → P5, childD1 → D1。 -/
def mapping : OrderMapping where
  toParent
    | .childP5 => .p5
    | .childD1 => .d1

/-- 順序矛盾の定理:
    子では childP5 → childD1（P5 が D1 に依存）だが、
    親では D1 → P5（D1 が P5 に依存）。
    同じ命題ペアに対して依存方向が逆転している。 -/
theorem ordering_contradiction :
    -- 子: childP5 は childD1 に依存する
    DependencyGraph.dependsOn ChildProp.childP5 ChildProp.childD1 = true ∧
    -- 親: P5 は D1 に依存しない（逆に D1 が P5 に依存する）
    propositionDependsOn (.p5 : PropositionId) .d1 = false ∧
    propositionDependsOn (.d1 : PropositionId) .p5 = true ∧
    -- 対応: childP5 ↔ P5, childD1 ↔ D1
    mapping.toParent .childP5 = .p5 ∧
    mapping.toParent .childD1 = .d1 := by
  refine ⟨rfl, ?_, ?_, rfl, rfl⟩ <;> native_decide

/-- 順序逆転の形式的表現:
    mapping で対応する命題ペアにおいて、子と親で依存方向が逆。
    これを「False ではないが不整合」として検出する。

    Note: これは `False` の導出ではなく、「同じ命題ペアに対して
    依存方向が異なる」という **不整合の証拠** である。
    Case 1/2 と異なり、論理的矛盾ではなく構造的不整合。 -/
def orderingInconsistency : Prop :=
  ∃ (c1 c2 : ChildProp),
    DependencyGraph.dependsOn c1 c2 = true ∧
    propositionDependsOn (mapping.toParent c1) (mapping.toParent c2) = false ∧
    propositionDependsOn (mapping.toParent c2) (mapping.toParent c1) = true

theorem orderingInconsistency_witness : orderingInconsistency :=
  ⟨.childP5, .childD1, rfl, by native_decide, by native_decide⟩

-- ============================================================
-- 7. 要約
-- ============================================================

/-- 検出メカニズム:
    1. OrderMapping（親子の命題対応）が定義されていれば
    2. 依存方向の逆転は deterministic に検出可能
    3. mapping.toParent で対応を解決し、dependsOn の方向を比較するだけ
    4. これは manifest-trace 拡張でスクリプト化可能（dynamic detection） -/
def _detectionPattern : String :=
  "ordering_inconsistency: deterministic check via OrderMapping + dependsOn comparison"

end Manifest.Models.PoC.Consistency.Case3
