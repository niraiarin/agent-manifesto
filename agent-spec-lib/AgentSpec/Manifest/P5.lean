import AgentSpec.Manifest.T4

/-! # AgentSpec.Manifest.P5 (Week 3 Day 94)

P5 Probabilistic Interpretation of Structure — 1 theorem (T4 由来、interpretation 非決定性)。
-/

namespace AgentSpec.Manifest

/-- P5: 同一 structure の interpretation は非決定的 (interpretation_nondeterminism 直接)。

    Robust 設計は perfect compliance を仮定せず、interpretation variance に対する
    resilience を維持すべし。 -/
theorem structure_interpretation_nondeterministic :
  ∃ (agent : Agent) (st : Structure) (action₁ action₂ : Action) (w : World),
    interpretsStructure agent st action₁ w ∧
    interpretsStructure agent st action₂ w ∧
    action₁ ≠ action₂ :=
  interpretation_nondeterminism

end AgentSpec.Manifest
