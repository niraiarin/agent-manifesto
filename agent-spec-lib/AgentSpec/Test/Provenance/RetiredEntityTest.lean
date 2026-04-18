import AgentSpec.Provenance.RetiredEntity

/-!
# AgentSpec.Test.Provenance.RetiredEntityTest: RetiredEntity + RetirementReason の behavior test

Day 12 Q1 A-Minimal + Q3 案 A + Q4 案 A: RetiredEntity (separate structure) +
RetirementReason (4 variant inductive、Refuted/Superseded/Obsolete/Withdrawn) の検証。

Day 11 Subagent I3 教訓を反映: rfl preference 維持 (simp tactic は最小限)。
-/

namespace AgentSpec.Test.Provenance.RetiredEntity

open AgentSpec.Provenance
open AgentSpec.Process

/-! ### `RetirementReason` 4 variant 構築 -/

/-- Refuted variant: Failure 経由退役 -/
example : RetirementReason := .Refuted Failure.trivial

/-- Superseded variant: 後継 entity 参照 -/
example : RetirementReason := .Superseded ResearchEntity.trivial

/-- Obsolete variant: payload なし -/
example : RetirementReason := .Obsolete

/-- Withdrawn variant: payload なし -/
example : RetirementReason := .Withdrawn

/-- Inhabited instance 解決 -/
example : Inhabited RetirementReason := inferInstance

/-! ### `RetiredEntity` 直接構築 -/

/-- 直接構築: Hypothesis entity の Obsolete 退役 -/
example : RetiredEntity :=
  { entity := .Hypothesis Hypothesis.trivial, reason := .Obsolete }

/-- 直接構築: Failure entity の Refuted 退役 (Failure 経由パターン) -/
example : RetiredEntity :=
  { entity := .Failure Failure.trivial,
    reason := .Refuted Failure.trivial }

/-- 直接構築: Hypothesis entity の Superseded 退役 (後継 Hypothesis) -/
example : RetiredEntity :=
  { entity := .Hypothesis Hypothesis.trivial,
    reason := .Superseded (.Hypothesis { claim := "successor" }) }

/-- field projection: entity -/
example : ({entity := .Hypothesis Hypothesis.trivial,
             reason := .Obsolete} : RetiredEntity).entity =
          .Hypothesis Hypothesis.trivial := rfl

/-- field projection: reason -/
example : ({entity := ResearchEntity.trivial,
             reason := .Withdrawn} : RetiredEntity).reason =
          .Withdrawn := rfl

/-- Inhabited instance 解決 -/
example : Inhabited RetiredEntity := inferInstance

/-! ### Smart constructor (5 種) -/

/-- mk' 汎用 smart constructor -/
example : RetiredEntity.mk' ResearchEntity.trivial .Obsolete =
          { entity := ResearchEntity.trivial, reason := .Obsolete } := rfl

/-- refuted smart constructor (Failure 経由) -/
example : RetiredEntity.refuted (.Hypothesis Hypothesis.trivial) Failure.trivial =
          { entity := .Hypothesis Hypothesis.trivial,
            reason := .Refuted Failure.trivial } := rfl

/-- superseded smart constructor (後継参照) -/
example : RetiredEntity.superseded (.Hypothesis Hypothesis.trivial)
            (.Hypothesis { claim := "successor" }) =
          { entity := .Hypothesis Hypothesis.trivial,
            reason := .Superseded (.Hypothesis { claim := "successor" }) } := rfl

/-- obsolete smart constructor -/
example : RetiredEntity.obsolete ResearchEntity.trivial =
          { entity := ResearchEntity.trivial, reason := .Obsolete } := rfl

/-- withdrawn smart constructor -/
example : RetiredEntity.withdrawn ResearchEntity.trivial =
          { entity := ResearchEntity.trivial, reason := .Withdrawn } := rfl

/-! ### `trivial` fixture + `whyRetired` accessor -/

/-- trivial fixture: trivial Hypothesis entity の Obsolete 退役 -/
example : RetiredEntity.trivial.entity = ResearchEntity.trivial := rfl
example : RetiredEntity.trivial.reason = .Obsolete := rfl

/-- whyRetired accessor: reason 抽出 (alias) -/
example : RetiredEntity.trivial.whyRetired = .Obsolete := rfl

/-- whyRetired smart constructor 後の reason 抽出 -/
example : (RetiredEntity.refuted ResearchEntity.trivial Failure.trivial).whyRetired =
          .Refuted Failure.trivial := rfl

/-! ### Day 6 Failure 経由パターンと Day 12 Refuted variant の整合性 -/

/-- Failure 経由退役の構築可能性 (案 C 利点吸収の確認) -/
example :
    let f := Failure.refuted "hyp-1" "no evidence"
    let r := RetiredEntity.refuted (.Hypothesis Hypothesis.trivial) f
    r.reason = .Refuted f := rfl

/-! ### 4 variant 全種類の RetiredEntity を List で集約 (内部規範 layer 横断 transfer 7 段階目) -/

/-- 4 variant 全種類を List で同時保持 (Day 11 PROV-O triple set 統合パターンの拡張) -/
example :
    let h := ResearchEntity.trivial
    let allRetired : List RetiredEntity :=
      [ RetiredEntity.refuted h Failure.trivial,
        RetiredEntity.superseded h (.Hypothesis { claim := "next" }),
        RetiredEntity.obsolete h,
        RetiredEntity.withdrawn h ]
    allRetired.length = 4 := rfl

end AgentSpec.Test.Provenance.RetiredEntity
