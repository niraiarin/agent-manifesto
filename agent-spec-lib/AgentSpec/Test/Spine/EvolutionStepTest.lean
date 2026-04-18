import AgentSpec.Spine.EvolutionStep

/-!
# AgentSpec.Test.Spine.EvolutionStepTest: EvolutionStep type class の behavior test

Day 3 hole-driven: `transition` member のみを持つ minimal type class の
基本性質を Unit instance で検証。
-/

namespace AgentSpec.Test.Spine.EvolutionStep

open AgentSpec.Spine
open AgentSpec.Spine.EvolutionStep

/-! ### Unit instance の transition 動作 -/

/-- Unit の任意 transition が成立 (dummy instance: 全 True) -/
example : EvolutionStep.transition () () := trivial

/-! ### TransitionReflexive property の Unit instance での充足 -/

/-- Unit instance は反射性を満たす -/
example : TransitionReflexive Unit := fun _ => trivial

/-! ### TransitionTransitive property の Unit instance での充足 -/

/-- Unit instance は推移性を満たす -/
example : TransitionTransitive Unit := fun _ _ _ _ _ => trivial

/-! ### type class instance 解決 -/

/-- EvolutionStep Unit instance が解決される -/
example : EvolutionStep Unit := inferInstance

end AgentSpec.Test.Spine.EvolutionStep
