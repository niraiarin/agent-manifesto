import AgentSpec.Process.Failure

/-!
# AgentSpec.Test.Process.FailureTest: Failure / FailureReason の behavior test

Day 6 hole-driven: 4 variant FailureReason + Failure structure + accessor + smart constructor の基本性質を検証。
-/

namespace AgentSpec.Test.Process.Failure

open AgentSpec.Process
open AgentSpec.Spine (Rationale)

/-! ### FailureReason 4 variant の構築 -/

/-- HypothesisRefuted variant -/
example : FailureReason := .HypothesisRefuted "counter-example found"

/-- ImplementationBlocked variant -/
example : FailureReason := .ImplementationBlocked "missing dependency"

/-- SpecInconsistent variant -/
example : FailureReason := .SpecInconsistent "conflicting axioms"

/-- Retired variant -/
example : FailureReason := .Retired "successor-hypothesis-name"

/-! ### Failure 構築と reason 抽出 -/

/-- Failure を anonymous constructor で構築 (Day 46 rationale 必須) -/
example : Failure :=
  { failedHypothesis := "h1", reason := .HypothesisRefuted "evidence",
    rationale := Rationale.trivial }

/-- whyFailed accessor で reason を取り出す -/
example :
    Failure.whyFailed { failedHypothesis := "h1", reason := .HypothesisRefuted "ev",
                        rationale := Rationale.trivial } =
    .HypothesisRefuted "ev" := rfl

/-- whyFailed と reason field は等価 -/
example : ∀ f : Failure, f.whyFailed = f.reason := fun _ => rfl

/-! ### Smart constructor -/

/-- refuted で HypothesisRefuted Failure を構築 (Day 46 signature 更新) -/
example : Failure.refuted "h1" "evidence" Rationale.trivial =
          { failedHypothesis := "h1", reason := .HypothesisRefuted "evidence",
            rationale := Rationale.trivial } := rfl

/-- retired で Retired Failure を構築 -/
example : Failure.retired "h-old" "h-new" Rationale.trivial =
          { failedHypothesis := "h-old", reason := .Retired "h-new",
            rationale := Rationale.trivial } := rfl

/-! ### trivial fixture -/

/-- trivial failure の failedHypothesis -/
example : Failure.trivial.failedHypothesis = "trivial-hypothesis" := rfl

/-- trivial failure の reason は HypothesisRefuted -/
example : Failure.trivial.whyFailed = .HypothesisRefuted "no evidence" := rfl

/-! ### DecidableEq / Inhabited -/

/-- FailureReason DecidableEq -/
example : (FailureReason.HypothesisRefuted "a") = (FailureReason.HypothesisRefuted "a") := by decide

/-- FailureReason variant 違いは不等 -/
example : (FailureReason.HypothesisRefuted "a") ≠ (FailureReason.Retired "a") := by decide

/-- Failure DecidableEq -/
example :
    (Failure.refuted "h" "e" Rationale.trivial) =
    (Failure.refuted "h" "e" Rationale.trivial) := by decide

/-- Day 46: 同 refuted でも rationale 違いは不等 (GA-S8 型強制の実証) -/
example :
    (Failure.refuted "h" "e" Rationale.trivial) ≠
    (Failure.refuted "h" "e" (Rationale.ofText "blocker identified" 40)) := by decide

/-- Failure DecidableEq instance 解決 -/
example : DecidableEq Failure := inferInstance

/-- FailureReason Inhabited -/
example : Inhabited FailureReason := inferInstance

/-- Failure Inhabited (Subagent I1 対処、HypothesisTest との対称性) -/
example : Inhabited Failure := inferInstance

end AgentSpec.Test.Process.Failure
