import AgentSpec.Spine.EvolutionStep

/-!
# AgentSpec.Test.Spine.EvolutionStepTest: EvolutionStep type class の behavior test

Day 3 hole-driven (transition 2-arg) → **Day 8 で B4 4-arg post に refactor**
(Q4 案 A: transition : (pre : S) → (input : Hypothesis) → (output : Verdict) → (post : S) → Prop)。
**Day 16 で transitionLegacy @[deprecated] 付与 + TransitionReflexive/Transitive を 4-arg 直接展開に refactor**
(Section 2.15 Day 9+ 繰り延べ課題 A-Compact 解消、cycle 内学習 transfer 2 段階別分野転用実例)。

新 4-arg signature の test と deprecated transitionLegacy の test を両方検証。
Day 11 Subagent I3 教訓継続適用 (cycle 内学習 transfer 5 度目、Day 11-16 = **6 Day 連続**
rfl preference 維持の記録更新): 全 example で rfl preference 維持、
set_option linter.deprecated false in で warning 抑制のみ。
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

/-! ### transitionLegacy (Day 1-7 互換、existential で derive、Day 16 で @[deprecated] 付与) -/

set_option linter.deprecated false in
/-- Unit の transitionLegacy も成立 (existential witness は trivial Hypothesis/Verdict)、
    Day 16 で @[deprecated] 付与のため warning 抑制で動作継続確認 -/
example : EvolutionStep.transitionLegacy () () :=
  ⟨Hypothesis.trivial, Verdict.trivial, trivial⟩

/-! ### TransitionReflexive property (Day 16 で 4-arg signature 直接展開に refactor) -/

/-- Unit instance は反射性を満たす (existential witness 提供、Day 16 後も proof 形式は同じ) -/
example : TransitionReflexive Unit :=
  fun _ => ⟨Hypothesis.trivial, Verdict.trivial, trivial⟩

/-! ### TransitionTransitive property (Day 16 で 4-arg signature 直接展開に refactor) -/

/-- Unit instance は推移性を満たす (existential witness 提供、Day 16 後も proof 形式は同じ) -/
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

/-! ### Day 16 新規: @[deprecated] 付与 transitionLegacy の動作確認 + 新 signature 直接展開確認 -/

set_option linter.deprecated false in
/-- Day 16: deprecated 付与 transitionLegacy が Inhabited 的に構築可能 -/
example : EvolutionStep.transitionLegacy () () :=
  ⟨Hypothesis.trivial, Verdict.proven, trivial⟩

set_option linter.deprecated false in
/-- Day 16: deprecated 付与 transitionLegacy で refuted verdict witness も成立 -/
example : EvolutionStep.transitionLegacy () () :=
  ⟨{ claim := "test-deprecation" }, Verdict.refuted, trivial⟩

/-- Day 16: 新 signature 直接展開 TransitionReflexive で refuted witness (transitionLegacy 非経由) -/
example : TransitionReflexive Unit :=
  fun _ => ⟨{ claim := "direct" }, Verdict.refuted, trivial⟩

/-- Day 16: 新 signature 直接展開 TransitionTransitive で proven chain witness -/
example : TransitionTransitive Unit :=
  fun _ _ _ _ _ => ⟨Hypothesis.trivial, Verdict.proven, trivial⟩

end AgentSpec.Test.Spine.EvolutionStep
