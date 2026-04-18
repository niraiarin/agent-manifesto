import AgentSpec.Spine.EvolutionStep

/-!
# AgentSpec.Test.Spine.EvolutionStepTest: EvolutionStep type class の behavior test

Day 3 hole-driven (transition 2-arg) → **Day 8 で B4 4-arg post に refactor**
(Q4 案 A: transition : (pre : S) → (input : Hypothesis) → (output : Verdict) → (post : S) → Prop)。
新 4-arg signature の test と legacy property の test を両方検証。
-/

namespace AgentSpec.Test.Spine.EvolutionStep

open AgentSpec.Spine
open AgentSpec.Spine.EvolutionStep
open AgentSpec.Process (Hypothesis)
open AgentSpec.Provenance (Verdict)

/-! ### Day 8: 新 B4 4-arg post transition の Unit instance での動作 -/

/-- Unit の 4-arg transition が成立 (任意の Hypothesis/Verdict ペアで True) -/
example : EvolutionStep.transition () Hypothesis.trivial Verdict.trivial () := trivial

/-- proven verdict + trivial hypothesis でも成立 -/
example : EvolutionStep.transition () Hypothesis.trivial Verdict.proven () := trivial

/-- refuted verdict + 任意 hypothesis でも成立 (Unit dummy) -/
example : EvolutionStep.transition ()
            { claim := "test" } Verdict.refuted () := trivial

/-! ### transitionLegacy (Day 1-7 互換、existential で derive) -/

/-- Unit の transitionLegacy も成立 (existential witness は trivial Hypothesis/Verdict) -/
example : EvolutionStep.transitionLegacy () () :=
  ⟨Hypothesis.trivial, Verdict.trivial, trivial⟩

/-! ### TransitionReflexive property (Day 8 で transitionLegacy ベース) -/

/-- Unit instance は反射性を満たす (existential witness 提供) -/
example : TransitionReflexive Unit :=
  fun _ => ⟨Hypothesis.trivial, Verdict.trivial, trivial⟩

/-! ### TransitionTransitive property (Day 8 で transitionLegacy ベース) -/

/-- Unit instance は推移性を満たす (existential witness 提供) -/
example : TransitionTransitive Unit :=
  fun _ _ _ _ _ => ⟨Hypothesis.trivial, Verdict.trivial, trivial⟩

/-! ### type class instance 解決 -/

/-- EvolutionStep Unit instance が解決される (Day 8 refactor 後も継続) -/
example : EvolutionStep Unit := inferInstance

/-- Decidable instance が解決される (Day 8 で 4-arg signature 対応) -/
example : Decidable (EvolutionStep.transition () Hypothesis.trivial Verdict.trivial ()) :=
  inferInstance

/-- decide で transition の真偽判定 -/
example : decide (EvolutionStep.transition () Hypothesis.trivial Verdict.trivial ()) = true := rfl

end AgentSpec.Test.Spine.EvolutionStep
