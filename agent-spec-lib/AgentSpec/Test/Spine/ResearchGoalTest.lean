import AgentSpec.Spine.ResearchGoal

/-!
# AgentSpec.Test.Spine.ResearchGoalTest: ResearchGoal + ResearchContext の behavior test

Day 55 GA-S10 研究目的 + Sub-Issue 間 context 伝搬。2 structure の構築 + smart constructor +
inheritFrom helper + isRoot / addAssumption / addConstraint の検証。
-/

namespace AgentSpec.Test.Spine.ResearchGoal

open AgentSpec.Spine

/-! ### ResearchGoal 構築 -/

example : ResearchGoal :=
  { title := "Lean 形式化",
    description := "agent-spec-lib 全 GA を Lean 型で表現",
    rationale := Rationale.trivial }

example : ResearchGoal := ResearchGoal.ofTitle "T" "D"
example : ResearchGoal := ResearchGoal.mk' "T" "D" (Rationale.ofText "motivation" 70)

example : ResearchGoal.trivial.title = "" := rfl
example : (ResearchGoal.ofTitle "t" "d").title = "t" := rfl
example : (ResearchGoal.ofTitle "t" "d").description = "d" := rfl
example : (ResearchGoal.mk' "t" "d" (Rationale.ofText "r" 50)).rationale =
          Rationale.ofText "r" 50 := rfl

/-! ### ResearchGoal DecidableEq / Inhabited -/

example : DecidableEq ResearchGoal := inferInstance
example : Inhabited ResearchGoal := inferInstance

example : (ResearchGoal.ofTitle "a" "b") = (ResearchGoal.ofTitle "a" "b") := by decide
example : (ResearchGoal.ofTitle "a" "b") ≠ (ResearchGoal.ofTitle "a" "c") := by decide

/-- 同 title/description でも rationale 違いは不等号 (GA-S8 型強制実証) -/
example :
    (ResearchGoal.mk' "t" "d" Rationale.trivial) ≠
    (ResearchGoal.mk' "t" "d" (Rationale.ofText "r" 10)) := by decide

/-! ### ResearchContext 構築 (root / child) -/

example : ResearchContext :=
  { parentGoalId := none,
    assumptions := ["Lean 4.29.0", "Mathlib available"],
    constraints := ["sorry 0", "axiom minimal"],
    rationale := Rationale.trivial }

example : ResearchContext := ResearchContext.root [] [] Rationale.trivial
example : ResearchContext := ResearchContext.child "parent-1" ["a"] ["c"] Rationale.trivial
example : ResearchContext := ResearchContext.trivial

/-! ### ResearchContext fields projection -/

example :
    (ResearchContext.root ["a1"] ["c1"] Rationale.trivial).assumptions = ["a1"] := rfl
example :
    (ResearchContext.child "p" [] [] Rationale.trivial).parentGoalId = some "p" := rfl

/-! ### isRoot 判定 -/

example : ResearchContext.trivial.isRoot = true := rfl
example : (ResearchContext.root [] [] Rationale.trivial).isRoot = true := rfl
example : (ResearchContext.child "p" [] [] Rationale.trivial).isRoot = false := rfl

/-! ### inheritFrom helper (Sub-Issue 間伝搬) -/

/-- parent context の assumptions/constraints を継承、rationale のみ上書き -/
example :
    let parent := ResearchContext.root ["a1", "a2"] ["c1"]
                    (Rationale.ofText "parent-reason" 80)
    let child := parent.inheritFrom "parent-goal-1"
                    (Rationale.ofText "child-reason" 60)
    child.parentGoalId = some "parent-goal-1" ∧
    child.assumptions = ["a1", "a2"] ∧
    child.constraints = ["c1"] ∧
    child.rationale = Rationale.ofText "child-reason" 60 :=
  ⟨rfl, rfl, rfl, rfl⟩

/-- 継承後は parent と同 assumptions (Sub-Issue 間伝搬の実証) -/
example :
    let parent := ResearchContext.root ["Lean 4.29.0"] ["sorry 0"] Rationale.trivial
    let child := parent.inheritFrom "p1" Rationale.trivial
    parent.assumptions = child.assumptions ∧ parent.constraints = child.constraints :=
  ⟨rfl, rfl⟩

/-- 継承 child は isRoot = false -/
example :
    let parent := ResearchContext.root [] [] Rationale.trivial
    let child := parent.inheritFrom "p1" Rationale.trivial
    child.isRoot = false := rfl

/-! ### addAssumption / addConstraint helper -/

example :
    (ResearchContext.root [] [] Rationale.trivial).addAssumption "new-a" =
    ResearchContext.root ["new-a"] [] Rationale.trivial := rfl

example :
    (ResearchContext.root ["a"] [] Rationale.trivial).addAssumption "b" =
    ResearchContext.root ["a", "b"] [] Rationale.trivial := rfl

example :
    (ResearchContext.root [] [] Rationale.trivial).addConstraint "c1" =
    ResearchContext.root [] ["c1"] Rationale.trivial := rfl

/-! ### DecidableEq / Inhabited (Context) -/

example : DecidableEq ResearchContext := inferInstance
example : Inhabited ResearchContext := inferInstance

example :
    ResearchContext.root [] [] Rationale.trivial =
    ResearchContext.root [] [] Rationale.trivial := by decide

example :
    ResearchContext.root ["a"] [] Rationale.trivial ≠
    ResearchContext.root ["b"] [] Rationale.trivial := by decide

end AgentSpec.Test.Spine.ResearchGoal
