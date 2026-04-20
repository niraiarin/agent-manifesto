import AgentSpec.Spine.ResearchNode

/-!
# AgentSpec.Test.Spine.ResearchNodeTest: ResearchNode 7 constructor umbrella の behavior test

Day 54 GA-S1 ResearchNode umbrella。7 constructor (Survey/Gap/Hypothesis/Decomposition/
Implementation/Failure/Retired) + Rationale 必須化 + kind/rationale/isTerminal/isGenerative
accessor の検証。
-/

namespace AgentSpec.Test.Spine.ResearchNode

open AgentSpec.Spine

/-! ### 7 constructor 構築 (全 Rationale 必須化) -/

example : ResearchNode := .Survey "先行研究調査" Rationale.trivial
example : ResearchNode := .Gap "Gap X を特定" Rationale.trivial
example : ResearchNode := .Hypothesis "claim-1" Rationale.trivial
example : ResearchNode :=
  .Decomposition "parent-1" ["child-a", "child-b"] Rationale.trivial
example : ResearchNode :=
  .Implementation "target-1" "artifact-x" Rationale.trivial
example : ResearchNode := .Failure "反証された" Rationale.trivial
example : ResearchNode := .Retired "陳腐化" Rationale.trivial

/-! ### DecidableEq / Inhabited / Repr -/

example : DecidableEq ResearchNode := inferInstance
example : Inhabited ResearchNode := inferInstance

/-- 同一 Survey は等号判定 -/
example :
    (ResearchNode.Survey "t" Rationale.trivial) =
    (ResearchNode.Survey "t" Rationale.trivial) := by decide

/-- 異 variant は不等号判定 -/
example :
    (ResearchNode.Survey "t" Rationale.trivial) ≠
    (ResearchNode.Gap "t" Rationale.trivial) := by decide

/-- payload 違いは不等号判定 -/
example :
    (ResearchNode.Hypothesis "a" Rationale.trivial) ≠
    (ResearchNode.Hypothesis "b" Rationale.trivial) := by decide

/-- rationale 違いは不等号判定 (GA-S8 型強制の実証) -/
example :
    (ResearchNode.Hypothesis "same"
      (Rationale.ofText "evidence-A" 50)) ≠
    (ResearchNode.Hypothesis "same"
      (Rationale.ofText "evidence-B" 50)) := by decide

/-! ### trivial fixture -/

example : ResearchNode.trivial = .Survey "" Rationale.trivial := rfl
example : ResearchNode.trivial.kind = .Survey := rfl
example : ResearchNode.trivial.rationale = Rationale.trivial := rfl

/-! ### kind accessor (ontological tag) -/

example : (ResearchNode.Survey "t" Rationale.trivial).kind = .Survey := rfl
example : (ResearchNode.Gap "d" Rationale.trivial).kind = .Gap := rfl
example : (ResearchNode.Hypothesis "c" Rationale.trivial).kind = .Hypothesis := rfl
example :
    (ResearchNode.Decomposition "p" [] Rationale.trivial).kind =
    .Decomposition := rfl
example :
    (ResearchNode.Implementation "t" "a" Rationale.trivial).kind =
    .Implementation := rfl
example : (ResearchNode.Failure "r" Rationale.trivial).kind = .Failure := rfl
example : (ResearchNode.Retired "c" Rationale.trivial).kind = .Retired := rfl

/-! ### rationale accessor (total、全 constructor 必須) -/

example :
    (ResearchNode.Survey "t" (Rationale.ofText "why" 80)).rationale =
    Rationale.ofText "why" 80 := rfl

example :
    (ResearchNode.Decomposition "p" ["c"] (Rationale.ofText "breakdown" 50)).rationale =
    Rationale.ofText "breakdown" 50 := rfl

/-! ### isTerminal / isGenerative 判定 (5+2 分類) -/

example : (ResearchNode.Survey "t" Rationale.trivial).isTerminal = false := rfl
example : (ResearchNode.Gap "d" Rationale.trivial).isTerminal = false := rfl
example : (ResearchNode.Hypothesis "c" Rationale.trivial).isTerminal = false := rfl
example : (ResearchNode.Failure "r" Rationale.trivial).isTerminal = true := rfl
example : (ResearchNode.Retired "c" Rationale.trivial).isTerminal = true := rfl

example : (ResearchNode.Survey "t" Rationale.trivial).isGenerative = true := rfl
example :
    (ResearchNode.Decomposition "p" [] Rationale.trivial).isGenerative = true := rfl
example :
    (ResearchNode.Implementation "t" "a" Rationale.trivial).isGenerative = true := rfl
example : (ResearchNode.Failure "r" Rationale.trivial).isGenerative = false := rfl
example : (ResearchNode.Retired "c" Rationale.trivial).isGenerative = false := rfl

/-! ### ResearchNodeKind enum の DecidableEq / Inhabited -/

example : DecidableEq ResearchNodeKind := inferInstance
example : Inhabited ResearchNodeKind := inferInstance

example : ResearchNodeKind.Survey ≠ ResearchNodeKind.Gap := by decide
example : ResearchNodeKind.Failure ≠ ResearchNodeKind.Retired := by decide

/-! ### 全 7 node kind の List 集約 (umbrella 完全性の実証) -/

/-- 7 kind 全てを List で同時保持可能、umbrella 型としての完全性確認 -/
example :
    let r := Rationale.trivial
    let allNodes : List ResearchNode :=
      [ .Survey "s" r,
        .Gap "g" r,
        .Hypothesis "h" r,
        .Decomposition "p" ["c"] r,
        .Implementation "t" "a" r,
        .Failure "f" r,
        .Retired "c" r ]
    allNodes.length = 7 := rfl

end AgentSpec.Test.Spine.ResearchNode
