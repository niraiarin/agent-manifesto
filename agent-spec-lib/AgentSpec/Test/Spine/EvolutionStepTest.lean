import AgentSpec.Spine.EvolutionStep

/-!
# AgentSpec.Test.Spine.EvolutionStepTest: EvolutionStep type class の behavior test

Day 3 hole-driven (transition 2-arg) → **Day 8 で B4 4-arg post に refactor**
(Q4 案 A: transition : (pre : S) → (input : Hypothesis) → (output : Verdict) → (post : S) → Prop)。
**Day 16 で transitionLegacy @[deprecated] 付与 + TransitionReflexive/Transitive を 4-arg 直接展開に refactor**
(Section 2.15 Day 9+ 繰り延べ課題 A-Compact 解消、cycle 内学習 transfer 2 段階別分野転用実例)。
**Day 17 で transitionLegacy 完全削除 A-Standard 完遂** (breaking change、`since := "2026-04-19"` 履行、
Section 2.15 Day 9+ 9 セッション繰り延べ課題完全解消、段階的 deprecation → removal 工学的 best practice 完遂)。

Day 17 で transitionLegacy 利用 example 3 件全削除 (既存 Day 8 から 1 件 + Day 16 新規 2 件)、
新 signature 直接展開 proof 2 件 (Day 16 新規) は保持。example 13→10 (-3)。
Day 11 Subagent I3 教訓継続適用 (cycle 内学習 transfer 6 度目、Day 11-17 = **7 Day 連続**
rfl preference 維持の記録更新): 全 example で rfl preference 維持。
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
            { claim := "test", rationale := AgentSpec.Spine.Rationale.trivial } Verdict.refuted () := trivial

/-! ### TransitionReflexive property (Day 16 で 4-arg signature 直接展開に refactor、Day 17 transitionLegacy 削除後も継続) -/

/-- Unit instance は反射性を満たす (existential witness 提供) -/
example : TransitionReflexive Unit :=
  fun _ => ⟨Hypothesis.trivial, Verdict.trivial, trivial⟩

/-! ### TransitionTransitive property (Day 16 で 4-arg signature 直接展開に refactor、Day 17 transitionLegacy 削除後も継続) -/

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

/-! ### Day 16 新規 → Day 17 保持: 新 signature 直接展開 proof (transitionLegacy 非経由) -/

/-- Day 16 追加 → Day 17 保持: 新 signature 直接展開 TransitionReflexive で refuted witness -/
example : TransitionReflexive Unit :=
  fun _ => ⟨{ claim := "direct", rationale := AgentSpec.Spine.Rationale.trivial }, Verdict.refuted, trivial⟩

/-- Day 16 追加 → Day 17 保持: 新 signature 直接展開 TransitionTransitive で proven chain witness -/
example : TransitionTransitive Unit :=
  fun _ _ _ _ _ => ⟨Hypothesis.trivial, Verdict.proven, trivial⟩

end AgentSpec.Test.Spine.EvolutionStep
