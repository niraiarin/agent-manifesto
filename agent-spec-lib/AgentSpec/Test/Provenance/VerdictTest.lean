import AgentSpec.Provenance.Verdict

/-!
# AgentSpec.Test.Provenance.VerdictTest: Verdict 3 variant の behavior test

Day 8 hole-driven (Q3 案 A): 3 variant inductive (proven/refuted/inconclusive) の
基本性質を検証。
-/

namespace AgentSpec.Test.Provenance.Verdict

open AgentSpec.Provenance

/-! ### 3 variant 構築 -/

example : Verdict := .proven
example : Verdict := .refuted
example : Verdict := .inconclusive

/-! ### isProven / isRefuted / isInconclusive 判定 -/

example : Verdict.isProven .proven = true := rfl
example : Verdict.isProven .refuted = false := rfl
example : Verdict.isProven .inconclusive = false := rfl

example : Verdict.isRefuted .refuted = true := rfl
example : Verdict.isRefuted .proven = false := rfl

example : Verdict.isInconclusive .inconclusive = true := rfl
example : Verdict.isInconclusive .proven = false := rfl

/-! ### trivial fixture -/

example : Verdict.trivial = Verdict.inconclusive := rfl
example : Verdict.trivial.isInconclusive = true := rfl

/-! ### DecidableEq / Inhabited -/

/-- 同 variant 同士の等価性 -/
example : (Verdict.proven : Verdict) = .proven := by decide

/-- 異 variant の不等 -/
example : (Verdict.proven : Verdict) ≠ .refuted := by decide
example : (Verdict.refuted : Verdict) ≠ .inconclusive := by decide

/-- DecidableEq instance 解決 -/
example : DecidableEq Verdict := inferInstance

/-- Inhabited instance 解決 -/
example : Inhabited Verdict := inferInstance

end AgentSpec.Test.Provenance.Verdict
