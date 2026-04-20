import AgentSpec.Provenance.RetiredEntity

/-!
# AgentSpec.Test.Provenance.RetiredEntityTest: RetiredEntity + RetirementReason の behavior test

Day 12 Q1 A-Minimal + Q3 案 A + Q4 案 A: RetiredEntity (separate structure) +
RetirementReason (4 variant inductive、Refuted/Superseded/Obsolete/Withdrawn) の検証。
Day 48 (2026-04-21) breaking: rationale : Rationale 必須化 (GA-S8 B-2 4/4 完了)。

Day 11 Subagent I3 教訓を反映: rfl preference 維持 (simp tactic は最小限)。
-/

namespace AgentSpec.Test.Provenance.RetiredEntity

open AgentSpec.Provenance
open AgentSpec.Process
open AgentSpec.Spine (Rationale)

/-! ### `RetirementReason` 4 variant 構築 -/

example : RetirementReason := .Refuted Failure.trivial
example : RetirementReason := .Superseded ResearchEntity.trivial
example : RetirementReason := .Obsolete
example : RetirementReason := .Withdrawn

example : Inhabited RetirementReason := inferInstance

/-! ### `RetiredEntity` 直接構築 (Day 48: rationale 必須) -/

example : RetiredEntity :=
  { entity := .Hypothesis Hypothesis.trivial, reason := .Obsolete,
    rationale := Rationale.trivial }

example : RetiredEntity :=
  { entity := .Failure Failure.trivial,
    reason := .Refuted Failure.trivial,
    rationale := Rationale.trivial }

example : RetiredEntity :=
  { entity := .Hypothesis Hypothesis.trivial,
    reason := .Superseded (.Hypothesis { claim := "successor", rationale := Rationale.trivial }),
    rationale := Rationale.trivial }

/-- field projection: entity -/
example : ({entity := .Hypothesis Hypothesis.trivial,
             reason := .Obsolete,
             rationale := Rationale.trivial} : RetiredEntity).entity =
          .Hypothesis Hypothesis.trivial := rfl

/-- field projection: reason -/
example : ({entity := ResearchEntity.trivial,
             reason := .Withdrawn,
             rationale := Rationale.trivial} : RetiredEntity).reason =
          .Withdrawn := rfl

example : Inhabited RetiredEntity := inferInstance

/-! ### Smart constructor (Day 48 signature 更新: rationale 引数必須) -/

example : RetiredEntity.mk' ResearchEntity.trivial .Obsolete Rationale.trivial =
          { entity := ResearchEntity.trivial, reason := .Obsolete,
            rationale := Rationale.trivial } := rfl

example : RetiredEntity.refuted (.Hypothesis Hypothesis.trivial) Failure.trivial Rationale.trivial =
          { entity := .Hypothesis Hypothesis.trivial,
            reason := .Refuted Failure.trivial,
            rationale := Rationale.trivial } := rfl

example : RetiredEntity.superseded (.Hypothesis Hypothesis.trivial)
            (.Hypothesis { claim := "successor", rationale := Rationale.trivial })
            Rationale.trivial =
          { entity := .Hypothesis Hypothesis.trivial,
            reason := .Superseded (.Hypothesis { claim := "successor", rationale := Rationale.trivial }),
            rationale := Rationale.trivial } := rfl

example : RetiredEntity.obsolete ResearchEntity.trivial Rationale.trivial =
          { entity := ResearchEntity.trivial, reason := .Obsolete,
            rationale := Rationale.trivial } := rfl

example : RetiredEntity.withdrawn ResearchEntity.trivial Rationale.trivial =
          { entity := ResearchEntity.trivial, reason := .Withdrawn,
            rationale := Rationale.trivial } := rfl

/-! ### `trivial` fixture + `whyRetired` accessor -/

example : RetiredEntity.trivial.entity = ResearchEntity.trivial := rfl
example : RetiredEntity.trivial.reason = .Obsolete := rfl
example : RetiredEntity.trivial.rationale = Rationale.trivial := rfl

example : RetiredEntity.trivial.whyRetired = .Obsolete := rfl

example : (RetiredEntity.refuted ResearchEntity.trivial Failure.trivial Rationale.trivial).whyRetired =
          .Refuted Failure.trivial := rfl

/-! ### Day 6 Failure 経由パターンと Day 12 Refuted variant の整合性 -/

example :
    let f := Failure.refuted "hyp-1" "no evidence" Rationale.trivial
    let r := RetiredEntity.refuted (.Hypothesis Hypothesis.trivial) f Rationale.trivial
    r.reason = .Refuted f := rfl

/-! ### 4 variant 全種類の RetiredEntity を List で集約 (Day 48 rationale 必須引数反映) -/

example :
    let h := ResearchEntity.trivial
    let r := Rationale.trivial
    let allRetired : List RetiredEntity :=
      [ RetiredEntity.refuted h Failure.trivial r,
        RetiredEntity.superseded h (.Hypothesis { claim := "next", rationale := r }) r,
        RetiredEntity.obsolete h r,
        RetiredEntity.withdrawn h r ]
    allRetired.length = 4 := rfl

/-! ### Day 14 deprecated fixture 動作確認 (linter A-Minimal、Day 48 rationale 反映) -/

set_option linter.deprecated false in
example : RetiredEntity.refutedTrivialDeprecated.entity = ResearchEntity.trivial := rfl

set_option linter.deprecated false in
example : RetiredEntity.refutedTrivialDeprecated.reason = .Refuted Failure.trivial := rfl

set_option linter.deprecated false in
example : RetiredEntity.supersededTrivialDeprecated.entity = ResearchEntity.trivial := rfl

set_option linter.deprecated false in
example : RetiredEntity.supersededTrivialDeprecated.reason =
          .Superseded ResearchEntity.trivial := rfl

set_option linter.deprecated false in
example : RetiredEntity.obsoleteTrivialDeprecated.reason = .Obsolete := rfl

set_option linter.deprecated false in
example : RetiredEntity.withdrawnTrivialDeprecated.reason = .Withdrawn := rfl

set_option linter.deprecated false in
example : RetiredEntity.refutedTrivialDeprecated.whyRetired = .Refuted Failure.trivial := rfl

set_option linter.deprecated false in
example :
    let allDeprecated : List RetiredEntity :=
      [ RetiredEntity.refutedTrivialDeprecated,
        RetiredEntity.supersededTrivialDeprecated,
        RetiredEntity.obsoleteTrivialDeprecated,
        RetiredEntity.withdrawnTrivialDeprecated ]
    allDeprecated.length = 4 := rfl

/-! ### Day 40: DecidableEq cascade (Day 39 ResearchEntity 連鎖解消) -/

example : DecidableEq RetirementReason := inferInstance
example : DecidableEq RetiredEntity := inferInstance

example : (RetirementReason.Obsolete) = (RetirementReason.Obsolete) := by decide
example : RetirementReason.Obsolete ≠ RetirementReason.Withdrawn := by decide

example :
    ({entity := ResearchEntity.trivial, reason := RetirementReason.Obsolete,
      rationale := Rationale.trivial} : RetiredEntity) =
    ({entity := ResearchEntity.trivial, reason := RetirementReason.Obsolete,
      rationale := Rationale.trivial} : RetiredEntity) :=
  by decide

example :
    ({entity := ResearchEntity.trivial, reason := RetirementReason.Obsolete,
      rationale := Rationale.trivial} : RetiredEntity) ≠
    ({entity := ResearchEntity.trivial, reason := RetirementReason.Withdrawn,
      rationale := Rationale.trivial} : RetiredEntity) :=
  by decide

/-- Day 48: 同 entity / reason でも rationale 違いは不等 (GA-S8 型強制の実証) -/
example :
    ({entity := ResearchEntity.trivial, reason := RetirementReason.Obsolete,
      rationale := Rationale.trivial} : RetiredEntity) ≠
    ({entity := ResearchEntity.trivial, reason := RetirementReason.Obsolete,
      rationale := Rationale.ofText "legal compliance" 90} : RetiredEntity) :=
  by decide

end AgentSpec.Test.Provenance.RetiredEntity
