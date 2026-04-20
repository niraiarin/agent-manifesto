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
    reason := .Superseded (.Hypothesis { claim := "successor", rationale := AgentSpec.Spine.Rationale.trivial }) }

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
            (.Hypothesis { claim := "successor", rationale := AgentSpec.Spine.Rationale.trivial }) =
          { entity := .Hypothesis Hypothesis.trivial,
            reason := .Superseded (.Hypothesis { claim := "successor", rationale := AgentSpec.Spine.Rationale.trivial }) } := rfl

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
        RetiredEntity.superseded h (.Hypothesis { claim := "next", rationale := AgentSpec.Spine.Rationale.trivial }),
        RetiredEntity.obsolete h,
        RetiredEntity.withdrawn h ]
    allRetired.length = 4 := rfl

/-! ### Day 14 deprecated fixture 動作確認 (linter A-Minimal、Q4 案 C rfl preference 維持)

Day 14 D1 linter A-Minimal 実装で追加された `@[deprecated]` 付き fixture
(refutedTrivialDeprecated / supersededTrivialDeprecated / obsoleteTrivialDeprecated /
withdrawnTrivialDeprecated) が Inhabited / mk' / accessor で引き続き rfl 動作することを確認。

`set_option linter.deprecated false in` で warning を抑制 (test 用途、build PASS 維持)。
Day 11 Subagent I3 教訓継続適用 (cycle 内学習 transfer 3 度目、Day 11-14 = 4 Day 連続
rfl preference 維持)。 -/

set_option linter.deprecated false in
/-- Refuted deprecated fixture: entity が trivial -/
example : RetiredEntity.refutedTrivialDeprecated.entity = ResearchEntity.trivial := rfl

set_option linter.deprecated false in
/-- Refuted deprecated fixture: reason が Refuted Failure.trivial -/
example : RetiredEntity.refutedTrivialDeprecated.reason = .Refuted Failure.trivial := rfl

set_option linter.deprecated false in
/-- Superseded deprecated fixture: entity が trivial -/
example : RetiredEntity.supersededTrivialDeprecated.entity = ResearchEntity.trivial := rfl

set_option linter.deprecated false in
/-- Superseded deprecated fixture: reason が Superseded trivial -/
example : RetiredEntity.supersededTrivialDeprecated.reason =
          .Superseded ResearchEntity.trivial := rfl

set_option linter.deprecated false in
/-- Obsolete deprecated fixture: reason が Obsolete -/
example : RetiredEntity.obsoleteTrivialDeprecated.reason = .Obsolete := rfl

set_option linter.deprecated false in
/-- Withdrawn deprecated fixture: reason が Withdrawn -/
example : RetiredEntity.withdrawnTrivialDeprecated.reason = .Withdrawn := rfl

set_option linter.deprecated false in
/-- whyRetired accessor on deprecated fixture -/
example : RetiredEntity.refutedTrivialDeprecated.whyRetired = .Refuted Failure.trivial := rfl

set_option linter.deprecated false in
/-- Day 14 deprecated fixture 4 variant を List 集約 (既存 4 variant List 集約との対称性) -/
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

/-- 同一 Obsolete RetirementReason の等号判定 -/
example : (RetirementReason.Obsolete) = (RetirementReason.Obsolete) := by decide

/-- Obsolete と Withdrawn の不等号判定 -/
example : RetirementReason.Obsolete ≠ RetirementReason.Withdrawn := by decide

/-- 同一 RetiredEntity の等号判定 -/
example :
    ({entity := ResearchEntity.trivial, reason := RetirementReason.Obsolete} : RetiredEntity) =
    ({entity := ResearchEntity.trivial, reason := RetirementReason.Obsolete} : RetiredEntity) :=
  by decide

/-- reason 違いの不等号判定 -/
example :
    ({entity := ResearchEntity.trivial, reason := RetirementReason.Obsolete} : RetiredEntity) ≠
    ({entity := ResearchEntity.trivial, reason := RetirementReason.Withdrawn} : RetiredEntity) :=
  by decide

end AgentSpec.Test.Provenance.RetiredEntity
