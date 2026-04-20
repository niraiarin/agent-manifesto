import AgentSpec.Process.Hypothesis

/-!
# AgentSpec.Test.Process.HypothesisTest: Hypothesis structure の behavior test

Day 6 hole-driven: structure 構築 + accessor + DecidableEq の基本性質を検証。
Day 45 (2026-04-21) breaking: rationale が Option String → Rationale 必須化。
全 fixture で Rationale.trivial を明示 (GA-S8 必須化方針)。
-/

namespace AgentSpec.Test.Process.Hypothesis

open AgentSpec.Process
open AgentSpec.Spine (Rationale)

/-! ### 構築と field projection (Day 45: rationale 必須化) -/

/-- claim + Rationale.trivial で構築 (最小ケース) -/
example : Hypothesis := { claim := "Phase 0 完了", rationale := Rationale.trivial }

/-- claim + 意味ある Rationale 指定で構築 -/
example : Hypothesis :=
  { claim := "Spine 4 type class 完備",
    rationale := Rationale.ofText "Day 4 で達成" 80 }

/-- claim field の取り出し -/
example :
    ({claim := "test", rationale := Rationale.trivial} : Hypothesis).claim = "test" := rfl

/-- rationale trivial の取り出し -/
example :
    ({claim := "test", rationale := Rationale.trivial} : Hypothesis).rationale =
    Rationale.trivial := rfl

/-- rationale ofText 指定時 -/
example :
    ({claim := "test", rationale := Rationale.ofText "reason" 50} : Hypothesis).rationale =
    Rationale.ofText "reason" 50 := rfl

/-! ### Smart constructor -/

/-- mk' で claim + Rationale を簡潔に構築 (Day 45 signature 更新) -/
example : Hypothesis.mk' "claim" (Rationale.ofText "rationale" 40) =
          { claim := "claim", rationale := Rationale.ofText "rationale" 40 } := rfl

/-- ofClaimWithText で旧 API 風に構築 (confidence 0 固定、非推奨) -/
example : Hypothesis.ofClaimWithText "c" "r" =
          { claim := "c", rationale := Rationale.ofText "r" 0 } := rfl

/-! ### trivial fixture (Day 45: rationale = Rationale.trivial) -/

example : Hypothesis.trivial.claim = "trivial" := rfl

example : Hypothesis.trivial.rationale = Rationale.trivial := rfl

/-! ### DecidableEq / Inhabited / Repr -/

/-- 同一値同士の等価性 -/
example :
    ({claim := "a", rationale := Rationale.trivial} : Hypothesis) =
    ({claim := "a", rationale := Rationale.trivial} : Hypothesis) := by decide

/-- 異なる claim の不等 -/
example :
    ({claim := "a", rationale := Rationale.trivial} : Hypothesis) ≠
    ({claim := "b", rationale := Rationale.trivial} : Hypothesis) := by decide

/-- 同 claim でも rationale 違いは不等 (GA-S8 型強制の実証) -/
example :
    ({claim := "c", rationale := Rationale.trivial} : Hypothesis) ≠
    ({claim := "c", rationale := Rationale.ofText "evidence" 10} : Hypothesis) := by decide

/-- Inhabited instance 解決 -/
example : Inhabited Hypothesis := inferInstance

/-- DecidableEq instance 解決 -/
example : DecidableEq Hypothesis := inferInstance

end AgentSpec.Test.Process.Hypothesis
