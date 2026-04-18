import AgentSpec.Provenance.ResearchActivity

/-!
# AgentSpec.Test.Provenance.ResearchActivityTest: ResearchActivity 5 variant の behavior test

Day 9: 02-data-provenance §4.1 PROV-O 5 variant (investigate / decompose / refine /
verify / retire) と verify variant の Hypothesis/Verdict 連携 (Day 8 EvolutionStep
B4 4-arg post 整合) の検証。
-/

namespace AgentSpec.Test.Provenance.ResearchActivity

open AgentSpec.Provenance
open AgentSpec.Process

/-! ### 5 variant 構築 -/

example : ResearchActivity := .investigate
example : ResearchActivity := .decompose
example : ResearchActivity := .refine
example : ResearchActivity := .retire

/-- verify variant は Hypothesis + Verdict payload (Day 8 EvolutionStep B4 4-arg post 整合) -/
example : ResearchActivity := .verify Hypothesis.trivial Verdict.trivial

/-- verify variant: proven verdict のケース -/
example : ResearchActivity := .verify { claim := "test" } Verdict.proven

/-- verify variant: refuted verdict のケース -/
example : ResearchActivity := .verify Hypothesis.trivial Verdict.refuted

/-! ### isVerify / isRetire 判定 -/

example : ResearchActivity.isVerify (.verify Hypothesis.trivial Verdict.proven) = true := rfl
example : ResearchActivity.isVerify .investigate = false := rfl
example : ResearchActivity.isVerify .retire = false := rfl

example : ResearchActivity.isRetire .retire = true := rfl
example : ResearchActivity.isRetire .investigate = false := rfl
example : ResearchActivity.isRetire (.verify Hypothesis.trivial Verdict.proven) = false := rfl

/-! ### trivial fixture -/

example : ResearchActivity.trivial = ResearchActivity.investigate := rfl
example : ResearchActivity.trivial.isVerify = false := rfl

/-! ### DecidableEq / Inhabited -/

/-- 同 variant 同士の等価性 (payload なし variants) -/
example : (ResearchActivity.investigate : ResearchActivity) = .investigate := by decide

/-- 異 variant の不等 -/
example : (ResearchActivity.investigate : ResearchActivity) ≠ .decompose := by decide

/-- verify variant の DecidableEq (payload Hypothesis + Verdict 含む) -/
example : ResearchActivity.verify Hypothesis.trivial Verdict.proven =
          ResearchActivity.verify Hypothesis.trivial Verdict.proven := by decide

/-- verify variant の不等 (Verdict 違い) -/
example : ResearchActivity.verify Hypothesis.trivial Verdict.proven ≠
          ResearchActivity.verify Hypothesis.trivial Verdict.refuted := by decide

/-- DecidableEq instance 解決 -/
example : DecidableEq ResearchActivity := inferInstance

/-- Inhabited instance 解決 -/
example : Inhabited ResearchActivity := inferInstance

/-! ### Day 8 EvolutionStep B4 4-arg post との整合検証

verify variant が EvolutionStep の transition signature と完全に対応することを示す。
EvolutionStep.transition : (pre : S) → (input : Hypothesis) → (output : Verdict) → (post : S) → Prop
ResearchActivity.verify : (input : Hypothesis) → (output : Verdict) → ResearchActivity

Day 10+ で EvolutionStep の transition を ResearchActivity.verify として PROV mapping する path 確立。 -/

/-- 同一 Hypothesis + Verdict から ResearchActivity.verify を構築できる -/
example (h : Hypothesis) (v : Verdict) : ResearchActivity := .verify h v

end AgentSpec.Test.Provenance.ResearchActivity
