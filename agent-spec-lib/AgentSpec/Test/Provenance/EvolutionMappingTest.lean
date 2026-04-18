import AgentSpec.Provenance.EvolutionMapping

/-!
# AgentSpec.Test.Provenance.EvolutionMappingTest: transitionToActivity の behavior test

Day 10 Q4 案 A: free function `transitionToActivity (h : Hypothesis) (v : Verdict) : ResearchActivity := .verify h v`
の動作検証。Day 8 EvolutionStep B4 4-arg post と Day 9 ResearchActivity.verify の連携 path 確認。
-/

namespace AgentSpec.Test.Provenance.EvolutionMapping

open AgentSpec.Provenance
open AgentSpec.Process

/-! ### transitionToActivity 基本動作 -/

/-- Hypothesis + proven Verdict → ResearchActivity.verify -/
example : transitionToActivity Hypothesis.trivial Verdict.proven =
          ResearchActivity.verify Hypothesis.trivial Verdict.proven := rfl

/-- Hypothesis + refuted Verdict → ResearchActivity.verify (refuted variant) -/
example : transitionToActivity Hypothesis.trivial Verdict.refuted =
          ResearchActivity.verify Hypothesis.trivial Verdict.refuted := rfl

/-- Hypothesis + inconclusive Verdict → ResearchActivity.verify (inconclusive variant) -/
example : transitionToActivity Hypothesis.trivial Verdict.inconclusive =
          ResearchActivity.verify Hypothesis.trivial Verdict.inconclusive := rfl

/-! ### 任意 Hypothesis でも動作 -/

example : transitionToActivity { claim := "test", rationale := some "evidence" } Verdict.proven =
          ResearchActivity.verify { claim := "test", rationale := some "evidence" } Verdict.proven := rfl

/-! ### isVerify が transitionToActivity の結果に対して true -/

/-- transitionToActivity の出力は常に verify variant -/
example : (transitionToActivity Hypothesis.trivial Verdict.proven).isVerify = true := rfl

example : (transitionToActivity Hypothesis.trivial Verdict.refuted).isVerify = true := rfl

/-! ### Day 8 EvolutionStep B4 4-arg post との連携 path 確認 -/

/-- transitionToActivity が EvolutionStep transition の (input, output) と直接対応する -/
example : ∀ (h : Hypothesis) (v : Verdict),
    transitionToActivity h v = ResearchActivity.verify h v := by
  intros _ _; rfl

/-- 任意の Hypothesis/Verdict ペアで Activity 化可能 (universal property) -/
example (h : Hypothesis) (v : Verdict) : ResearchActivity := transitionToActivity h v

end AgentSpec.Test.Provenance.EvolutionMapping
