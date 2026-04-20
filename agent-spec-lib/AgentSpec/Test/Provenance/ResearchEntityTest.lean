import AgentSpec.Provenance.ResearchEntity

/-!
# AgentSpec.Test.Provenance.ResearchEntityTest: ResearchEntity 4 constructor の behavior test

Day 9 Q3 案 A 4 constructor (Hypothesis / Failure / Evolution / Handoff embed) と
Q4 案 A Mapping 関数 (Process side `.toEntity` method) の検証。
-/

namespace AgentSpec.Test.Provenance.ResearchEntity

open AgentSpec.Provenance
open AgentSpec.Process

/-! ### 4 constructor 構築 (既存 Process type embed) -/

example : ResearchEntity := .Hypothesis Hypothesis.trivial
example : ResearchEntity := .Failure Failure.trivial
example : ResearchEntity := .Evolution Evolution.trivial
example : ResearchEntity := .Handoff HandoffChain.trivialHandoff

/-! ### Q4 案 A Mapping: Process side `.toEntity` method (dot notation) -/

/-- Hypothesis.toEntity dot notation 利用 -/
example : Hypothesis.trivial.toEntity = ResearchEntity.Hypothesis Hypothesis.trivial := rfl

/-- Failure.toEntity dot notation 利用 -/
example : Failure.trivial.toEntity = ResearchEntity.Failure Failure.trivial := rfl

/-- Evolution.toEntity dot notation 利用 -/
example : Evolution.trivial.toEntity = ResearchEntity.Evolution Evolution.trivial := rfl

/-- Handoff.toEntity dot notation 利用 -/
example : HandoffChain.trivialHandoff.toEntity = ResearchEntity.Handoff HandoffChain.trivialHandoff := rfl

/-! ### isXxx Bool 判定 helper -/

example : ResearchEntity.isHypothesis (.Hypothesis Hypothesis.trivial) = true := rfl
example : ResearchEntity.isHypothesis (.Failure Failure.trivial) = false := rfl

example : ResearchEntity.isFailure (.Failure Failure.trivial) = true := rfl
example : ResearchEntity.isFailure (.Hypothesis Hypothesis.trivial) = false := rfl

example : ResearchEntity.isEvolution (.Evolution Evolution.trivial) = true := rfl
example : ResearchEntity.isEvolution (.Hypothesis Hypothesis.trivial) = false := rfl

example : ResearchEntity.isHandoff (.Handoff HandoffChain.trivialHandoff) = true := rfl
example : ResearchEntity.isHandoff (.Hypothesis Hypothesis.trivial) = false := rfl

/-! ### trivial fixture -/

example : ResearchEntity.trivial = ResearchEntity.Hypothesis Hypothesis.trivial := rfl
example : ResearchEntity.trivial.isHypothesis = true := rfl

/-! ### Inhabited / Repr / DecidableEq (Day 39 で Evolution DecidableEq 後の連鎖解消) -/

example : Inhabited ResearchEntity := inferInstance

/-- Day 39: Evolution DecidableEq (Day 38) 後、ResearchEntity も DecidableEq derive 可能 -/
example : DecidableEq ResearchEntity := inferInstance

/-- 同一 Hypothesis variant の等号判定 -/
example :
    (ResearchEntity.Hypothesis Hypothesis.trivial) =
    (ResearchEntity.Hypothesis Hypothesis.trivial) := by decide

/-- 異なる variant の不等号判定 (Hypothesis vs Failure) -/
example :
    ResearchEntity.Hypothesis Hypothesis.trivial ≠
    ResearchEntity.Failure Failure.trivial := by decide

/-- 同一 Evolution variant の等号判定 (recursive payload DecidableEq の連鎖確認) -/
example :
    ResearchEntity.Evolution (.refineWith (.initial Hypothesis.trivial) { claim := "x" }) =
    ResearchEntity.Evolution (.refineWith (.initial Hypothesis.trivial) { claim := "x" }) :=
  by decide

/-- 異なる Evolution chain の不等号判定 -/
example :
    ResearchEntity.Evolution (.initial { claim := "a" }) ≠
    ResearchEntity.Evolution (.initial { claim := "b" }) := by decide

/-! ### Cross-process embed: Process 4 type 全てが ResearchEntity に embed 可能 -/

/-- Process 4 type を ResearchEntity の List として表現 -/
example : List ResearchEntity := [
  Hypothesis.trivial.toEntity,
  Failure.trivial.toEntity,
  Evolution.trivial.toEntity,
  HandoffChain.trivialHandoff.toEntity
]

/-- 4 type の一覧が長さ 4 -/
example : ([
  Hypothesis.trivial.toEntity,
  Failure.trivial.toEntity,
  Evolution.trivial.toEntity,
  HandoffChain.trivialHandoff.toEntity
] : List ResearchEntity).length = 4 := rfl

end AgentSpec.Test.Provenance.ResearchEntity
