import AgentSpec.Process.Hypothesis

/-!
# AgentSpec.Test.Process.HypothesisTest: Hypothesis structure の behavior test

Day 6 hole-driven: structure 構築 + accessor + DecidableEq の基本性質を検証。
-/

namespace AgentSpec.Test.Process.Hypothesis

open AgentSpec.Process

/-! ### 構築と field projection -/

/-- claim のみ指定で構築 (rationale はデフォルト none) -/
example : Hypothesis := { claim := "Phase 0 完了" }

/-- claim + rationale 指定で構築 -/
example : Hypothesis := { claim := "Spine 4 type class 完備", rationale := some "Day 4 で達成" }

/-- claim field の取り出し -/
example : ({claim := "test"} : Hypothesis).claim = "test" := rfl

/-- rationale デフォルト = none -/
example : ({claim := "test"} : Hypothesis).rationale = none := rfl

/-- rationale 指定時 -/
example : ({claim := "test", rationale := some "reason"} : Hypothesis).rationale = some "reason" := rfl

/-! ### Smart constructor -/

/-- mk' で claim + rationale を簡潔に構築 -/
example : Hypothesis.mk' "claim" "rationale" =
          { claim := "claim", rationale := some "rationale" } := rfl

/-! ### trivial fixture -/

/-- trivial hypothesis の claim -/
example : Hypothesis.trivial.claim = "trivial" := rfl

/-- trivial hypothesis の rationale (デフォルト none) -/
example : Hypothesis.trivial.rationale = none := rfl

/-! ### DecidableEq / Inhabited / Repr -/

/-- 同一値同士の等価性 -/
example : ({claim := "a"} : Hypothesis) = ({claim := "a"} : Hypothesis) := by decide

/-- 異なる claim の不等 -/
example : ({claim := "a"} : Hypothesis) ≠ ({claim := "b"} : Hypothesis) := by decide

/-- Inhabited instance 解決 -/
example : Inhabited Hypothesis := inferInstance

/-- DecidableEq instance 解決 -/
example : DecidableEq Hypothesis := inferInstance

end AgentSpec.Test.Process.Hypothesis
