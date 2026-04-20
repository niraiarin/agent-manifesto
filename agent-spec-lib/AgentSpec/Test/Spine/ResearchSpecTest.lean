import AgentSpec.Spine.ResearchSpec
import AgentSpec.Spine.State

/-!
# AgentSpec.Test.Spine.ResearchSpecTest: ResearchSpec Hoare 4-arg spec の behavior test

Day 53 GA-S11 Hoare-style 4-arg post spec。polymorphic `ResearchSpec (State Input Output : Type)`
の構築 + helper + Day 51 LifeCyclePhase / Nat / Unit での instantiation 検証。
-/

namespace AgentSpec.Test.Spine.ResearchSpec

open AgentSpec.Spine

/-! ### 基本構築 (polymorphic) -/

/-- Nat-Nat-Nat の simple spec: input < 10 なら output = input + 1 -/
example : ResearchSpec Nat Nat Nat :=
  { pre := fun _ i => i < 10,
    post := fun _ i o _ => o = i + 1 }

/-- Unit-Unit-Unit の vacuous spec -/
example : ResearchSpec Unit Unit Unit :=
  { pre := fun _ _ => True,
    post := fun _ _ _ _ => True }

/-! ### trivial / unsatisfiable fixture -/

/-- trivial は常に pre=True / post=True -/
example : (ResearchSpec.trivial (State := Nat) (Input := Nat) (Output := Nat)).pre 0 0 := trivial

/-- unsatisfiable は pre=False -/
example :
    ¬ (ResearchSpec.unsatisfiable (State := Nat) (Input := Nat) (Output := Nat)).pre 0 0 :=
  fun h => h

/-! ### Satisfies (Hoare triple 判定) -/

/-- trivial spec は全状態遷移を satisfy -/
example :
    (ResearchSpec.trivial : ResearchSpec Nat Nat Nat).Satisfies 0 0 0 1 :=
  fun _ => trivial

/-- unsatisfiable spec は pre が False なので vacuously satisfy -/
example :
    (ResearchSpec.unsatisfiable : ResearchSpec Nat Nat Nat).Satisfies 0 0 0 0 :=
  fun h => h.elim

/-- 具体 spec の Satisfies: input=5 → output=6、pre (5<10) 満たせば post 成立 -/
example :
    let spec : ResearchSpec Nat Nat Nat :=
      { pre := fun _ i => i < 10,
        post := fun _ i o _ => o = i + 1 }
    spec.Satisfies 0 5 6 0 :=
  fun _ => rfl

/-! ### strengthenPre / weakenPost (compositional) -/

/-- strengthenPre: pre に追加条件 AND -/
example :
    ((ResearchSpec.trivial : ResearchSpec Nat Nat Nat).strengthenPre
      (fun _ i => i > 0)).pre 0 5 :=
  ⟨trivial, by decide⟩

/-- strengthenPre は元の pre を satisfy する場合のみ pre を satisfy -/
example :
    ¬ ((ResearchSpec.trivial : ResearchSpec Nat Nat Nat).strengthenPre
      (fun _ i => i > 10)).pre 0 5 := by
  intro h
  have : (5 : Nat) > 10 := h.2
  omega

/-- weakenPost: post に alternative を OR -/
example :
    let base : ResearchSpec Nat Nat Nat :=
      { pre := fun _ _ => True, post := fun _ _ _ _ => False }
    (base.weakenPost (fun _ _ _ _ => True)).post 0 0 0 0 := Or.inr trivial

/-! ### Day 51 State 型との instantiation (polymorphic の実用例) -/

/-- ResearchSpec LifeCyclePhase Nat Nat の具体 instantiation -/
example : ResearchSpec LifeCyclePhase Nat Nat :=
  { pre := fun phase _ => phase.isActive,
    post := fun _ _ _ phase' => phase'.isTerminal ∨ phase'.isActive }

/-- LifeCyclePhase spec で Proposed (not active) は pre を満たさない -/
example :
    let spec : ResearchSpec LifeCyclePhase Nat Nat :=
      { pre := fun phase _ => phase.isActive,
        post := fun _ _ _ _ => True }
    ¬ spec.pre .Proposed 0 := by simp [LifeCyclePhase.isActive]

/-- LifeCyclePhase spec で Implementing (active) は pre を満たす -/
example :
    let spec : ResearchSpec LifeCyclePhase Nat Nat :=
      { pre := fun phase _ => phase.isActive,
        post := fun _ _ _ _ => True }
    spec.pre .Implementing 0 := by simp [LifeCyclePhase.isActive]

end AgentSpec.Test.Spine.ResearchSpec
