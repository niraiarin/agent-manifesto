import AgentSpec.Process.HandoffChain

/-!
# AgentSpec.Test.Process.HandoffChainTest: Handoff + HandoffChain の behavior test

Day 7 hole-driven (Q4 案 A): HandoffChain 単独 test。
LearningCycle / Observable との Spine 統合 test は Day 8+ で別 test file
(Spine と Process の責務分離、Q4 案 A 確定方針)。
-/

namespace AgentSpec.Test.Process.HandoffChain

open AgentSpec.Process

/-! ### Handoff structure 構築 -/

/-- 任意の agent ペアと payload で Handoff 構築 -/
example : Handoff :=
  { fromAgent := "alice", toAgent := "bob", payload := "session-data" }

/-- field projection -/
example : ({fromAgent := "a", toAgent := "b", payload := "p"} : Handoff).fromAgent = "a" := rfl

example : ({fromAgent := "a", toAgent := "b", payload := "p"} : Handoff).toAgent = "b" := rfl

example : ({fromAgent := "a", toAgent := "b", payload := "p"} : Handoff).payload = "p" := rfl

/-! ### trivialHandoff fixture -/

example : HandoffChain.trivialHandoff.fromAgent = "agent-1" := rfl
example : HandoffChain.trivialHandoff.toAgent = "agent-2" := rfl
example : HandoffChain.trivialHandoff.payload = "trivial-payload" := rfl

/-! ### HandoffChain 構築 (empty / cons) -/

/-- empty chain -/
example : HandoffChain := .empty

/-- 1 handoff の chain -/
example : HandoffChain := .cons HandoffChain.trivialHandoff .empty

/-- 2 handoff の chain -/
example : HandoffChain :=
  .cons
    { fromAgent := "a", toAgent := "b", payload := "p1" }
    (.cons { fromAgent := "b", toAgent := "c", payload := "p2" } .empty)

/-! ### length recursive def -/

/-- empty の length = 0 -/
example : HandoffChain.length .empty = 0 := rfl

/-- 1 handoff の length = 1 -/
example : HandoffChain.length (.cons HandoffChain.trivialHandoff .empty) = 1 := rfl

/-- 2 handoff の length = 2 -/
example : HandoffChain.length
    (.cons HandoffChain.trivialHandoff
      (.cons HandoffChain.trivialHandoff .empty)) = 2 := rfl

/-! ### append (末尾追加) -/

/-- empty.append h = cons h empty -/
example : HandoffChain.append .empty HandoffChain.trivialHandoff =
          .cons HandoffChain.trivialHandoff .empty := rfl

/-- 1 chain.append h で length が 1 増える -/
example : (HandoffChain.append (.cons HandoffChain.trivialHandoff .empty)
              HandoffChain.trivialHandoff).length = 2 := rfl

/-! ### trivial fixture -/

example : HandoffChain.trivial = HandoffChain.empty := rfl
example : HandoffChain.trivial.length = 0 := rfl

/-! ### DecidableEq / Inhabited -/

/-- Handoff DecidableEq -/
example : ({fromAgent := "a", toAgent := "b", payload := "p"} : Handoff) =
          ({fromAgent := "a", toAgent := "b", payload := "p"} : Handoff) := by decide

/-- Handoff の不等 -/
example : ({fromAgent := "a", toAgent := "b", payload := "p"} : Handoff) ≠
          ({fromAgent := "x", toAgent := "b", payload := "p"} : Handoff) := by decide

example : Inhabited Handoff := inferInstance
example : Inhabited HandoffChain := inferInstance

end AgentSpec.Test.Process.HandoffChain
