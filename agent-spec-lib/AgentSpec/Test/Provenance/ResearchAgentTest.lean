import AgentSpec.Provenance.ResearchAgent
import AgentSpec.Provenance.ResearchEntity

/-!
# AgentSpec.Test.Provenance.ResearchAgentTest: ResearchAgent + Role + toEntity の behavior test

Day 10 Q3 案 A (structure ResearchAgent + inductive Role 3 variant) と
Q4 案 A 同パターン (Mapping を ResearchEntity.lean 内に配置) の検証。
-/

namespace AgentSpec.Test.Provenance.ResearchAgent

open AgentSpec.Provenance

/-! ### Role 3 variant 構築 -/

example : Role := .Researcher
example : Role := .Reviewer
example : Role := .Verifier

/-! ### ResearchAgent 構築 -/

example : ResearchAgent :=
  { identity := "alice", role := .Researcher }

example : ResearchAgent :=
  { identity := "bob", role := .Reviewer }

example : ResearchAgent :=
  { identity := "verifier-1", role := .Verifier }

/-! ### field projection -/

example : ({identity := "a", role := .Researcher} : ResearchAgent).identity = "a" := rfl
example : ({identity := "a", role := .Researcher} : ResearchAgent).role = .Researcher := rfl

/-! ### Smart constructor mkXxx -/

example : ResearchAgent.mkResearcher "alice" =
          { identity := "alice", role := .Researcher } := rfl

example : ResearchAgent.mkReviewer "bob" =
          { identity := "bob", role := .Reviewer } := rfl

example : ResearchAgent.mkVerifier "v1" =
          { identity := "v1", role := .Verifier } := rfl

/-! ### isResearcher / isReviewer / isVerifier 判定 -/

example : (ResearchAgent.mkResearcher "a").isResearcher = true := rfl
example : (ResearchAgent.mkResearcher "a").isReviewer = false := rfl

example : (ResearchAgent.mkReviewer "a").isReviewer = true := rfl
example : (ResearchAgent.mkReviewer "a").isResearcher = false := rfl

example : (ResearchAgent.mkVerifier "a").isVerifier = true := rfl
example : (ResearchAgent.mkVerifier "a").isResearcher = false := rfl

/-! ### trivial fixture -/

example : ResearchAgent.trivial =
          { identity := "trivial-agent", role := .Researcher } := rfl

example : ResearchAgent.trivial.isResearcher = true := rfl

/-! ### DecidableEq / Inhabited (Role + ResearchAgent) -/

example : (Role.Researcher : Role) = .Researcher := by decide
example : (Role.Researcher : Role) ≠ .Reviewer := by decide

example : ResearchAgent.mkResearcher "a" = ResearchAgent.mkResearcher "a" := by decide

example : ResearchAgent.mkResearcher "a" ≠ ResearchAgent.mkResearcher "b" := by decide

example : DecidableEq Role := inferInstance
example : DecidableEq ResearchAgent := inferInstance
example : Inhabited ResearchAgent := inferInstance

/-! ### toEntity Mapping (Day 10 ResearchEntity 5 constructor 拡張) -/

example : ResearchAgent.trivial.toEntity = ResearchEntity.Agent ResearchAgent.trivial := rfl

example : (ResearchAgent.mkResearcher "alice").toEntity =
          ResearchEntity.Agent (ResearchAgent.mkResearcher "alice") := rfl

/-! ### ResearchEntity.isAgent 判定 (Day 10 拡張) -/

example : ResearchEntity.isAgent (.Agent ResearchAgent.trivial) = true := rfl
example : ResearchEntity.isAgent (.Hypothesis AgentSpec.Process.Hypothesis.trivial) = false := rfl

end AgentSpec.Test.Provenance.ResearchAgent
