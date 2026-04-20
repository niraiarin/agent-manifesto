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

/-! ### Day 42: payload 付き 3 variant (provenWith / refutedWith / inconclusiveDueTo) -/

/-- payload variant 直接構築 -/
example : Verdict := .provenWith "Q.E.D. via induction on n"
example : Verdict := .refutedWith "counter-example: n = 0"
example : Verdict := .inconclusiveDueTo "depends on CSLib upgrade"

/-- isProven は provenWith も true と判定 (family 判定) -/
example : (Verdict.provenWith "evidence").isProven = true := rfl
example : (Verdict.provenWith "x").isRefuted = false := rfl

/-- isRefuted は refutedWith も true と判定 -/
example : (Verdict.refutedWith "counter").isRefuted = true := rfl
example : (Verdict.refutedWith "x").isProven = false := rfl

/-- isInconclusive は inconclusiveDueTo も true と判定 -/
example : (Verdict.inconclusiveDueTo "reason").isInconclusive = true := rfl
example : (Verdict.inconclusiveDueTo "x").isProven = false := rfl

/-- payload accessor: nullary は none -/
example : Verdict.payload .proven = none := rfl
example : Verdict.payload .refuted = none := rfl
example : Verdict.payload .inconclusive = none := rfl

/-- payload accessor: payload variant は some -/
example : Verdict.payload (.provenWith "e") = some "e" := rfl
example : Verdict.payload (.refutedWith "c") = some "c" := rfl
example : Verdict.payload (.inconclusiveDueTo "r") = some "r" := rfl

/-- DecidableEq: nullary と payload variant の区別 -/
example : (Verdict.refuted) ≠ (.refutedWith "any") := by decide

/-- DecidableEq: payload 違いの不等号判定 -/
example : (Verdict.refutedWith "a") ≠ (.refutedWith "b") := by decide

/-- DecidableEq: 同一 payload の等号判定 -/
example : (Verdict.provenWith "same") = (.provenWith "same") := by decide

end AgentSpec.Test.Provenance.Verdict
