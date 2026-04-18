import AgentSpec.Spine.Edge

/-!
# AgentSpec.Test.Spine.EdgeTest: Edge.lean の behavior test

Week 2 Day 2: hole-driven signature に対する最小 behavior assertion。
Day 1 で確立した Section 10.2 パターン #6 (sorry/axiom 0) 準拠。

## カバーする Gap / 原則

- **GA-S4** (Edge Type Inductive): EdgeKind の 6 variant + Edge structure の DecidableEq
- **GA-I9** (テストカバレッジ): Spine 層 Edge の behavior assertion
-/

namespace AgentSpec.Test.Spine.Edge

open AgentSpec.Spine

/-! ### EdgeKind の 6 variant DecidableEq -/

/-- 同一 variant は等しい -/
example : EdgeKind.wasDerivedFrom = EdgeKind.wasDerivedFrom := by decide

/-- 異なる variant は等しくない -/
example : EdgeKind.wasDerivedFrom ≠ EdgeKind.refutes := by decide

/-- 全 6 variant の DecidableEq 確認 -/
example : ([EdgeKind.wasDerivedFrom, EdgeKind.refines, EdgeKind.refutes,
            EdgeKind.blocks, EdgeKind.relates, EdgeKind.wasReplacedBy].length) = 6 := by decide

/-! ### Edge structure -/

/-- 同一 from/to/kind の Edge は等しい -/
example : ({src :=FolgeID.root, dst :=FolgeID.root.child (Sum.inl 1),
            kind := EdgeKind.wasDerivedFrom : Edge}) =
          ({src :=FolgeID.root, dst :=FolgeID.root.child (Sum.inl 1),
            kind := EdgeKind.wasDerivedFrom : Edge}) := by decide

/-- 異なる kind の Edge は等しくない -/
example : ({src :=FolgeID.root, dst :=FolgeID.root,
            kind := EdgeKind.refines : Edge}) ≠
          ({src :=FolgeID.root, dst :=FolgeID.root,
            kind := EdgeKind.refutes : Edge}) := by decide

/-! ### Edge.isSelfLoop -/

/-- root → root は self-loop -/
example : ({src :=FolgeID.root, dst :=FolgeID.root,
            kind := EdgeKind.relates : Edge}).isSelfLoop = true := by decide

/-- root → root.child は self-loop ではない -/
example : ({src :=FolgeID.root, dst :=FolgeID.root.child (Sum.inl 1),
            kind := EdgeKind.wasDerivedFrom : Edge}).isSelfLoop = false := by decide

/-! ### Edge.reverse -/

/-- reverse は from/to を交換し kind を維持 -/
example :
    ({src :=FolgeID.root, dst :=FolgeID.root.child (Sum.inl 1),
      kind := EdgeKind.wasDerivedFrom : Edge}).reverse =
    ({src :=FolgeID.root.child (Sum.inl 1), dst :=FolgeID.root,
      kind := EdgeKind.wasDerivedFrom : Edge} : Edge) := by decide

/-- reverse の reverse は元に戻る (involutivity, refines) -/
example :
    let e : Edge := {src :=FolgeID.root, dst :=FolgeID.root.child (Sum.inl 1),
                     kind := EdgeKind.refines}
    e.reverse.reverse = e := by decide

/-- involutivity: wasDerivedFrom -/
example :
    let e : Edge := {src :=FolgeID.root, dst :=FolgeID.root.child (Sum.inl 1),
                     kind := EdgeKind.wasDerivedFrom}
    e.reverse.reverse = e := by decide

/-- involutivity: refutes -/
example :
    let e : Edge := {src :=FolgeID.root, dst :=FolgeID.root.child (Sum.inl 1),
                     kind := EdgeKind.refutes}
    e.reverse.reverse = e := by decide

/-- involutivity: blocks -/
example :
    let e : Edge := {src :=FolgeID.root, dst :=FolgeID.root.child (Sum.inl 1),
                     kind := EdgeKind.blocks}
    e.reverse.reverse = e := by decide

/-- involutivity: relates -/
example :
    let e : Edge := {src :=FolgeID.root, dst :=FolgeID.root.child (Sum.inl 1),
                     kind := EdgeKind.relates}
    e.reverse.reverse = e := by decide

/-- involutivity: wasReplacedBy -/
example :
    let e : Edge := {src :=FolgeID.root, dst :=FolgeID.root.child (Sum.inl 1),
                     kind := EdgeKind.wasReplacedBy}
    e.reverse.reverse = e := by decide

/-! ### Inhabited instance -/

/-- Inhabited instance が存在する -/
example : Inhabited Edge := inferInstance

/-- Inhabited instance が存在する (EdgeKind) -/
example : Inhabited EdgeKind := inferInstance

end AgentSpec.Test.Spine.Edge
