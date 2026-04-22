import AgentSpec.Manifest.Ontology

/-! # AgentSpec.Manifest.E3 (Week 3 Day 89)

E3 Confidence Is a Self-Description — 1 axiom (confidence は output と独立に変動可)。
-/

namespace AgentSpec.Manifest

/-- E3.1: 同一 result でも confidence が異なる遷移が存在 (confidence は output 真値と直結しない)。 -/
axiom confidence_is_self_description :
  ∃ (agent : Agent) (action : Action) (w w₁ w₂ : World),
    canTransition agent action w w₁ ∧
    canTransition agent action w w₂ ∧
    (worldOutput w₁).result = (worldOutput w₂).result ∧
    (worldOutput w₁).confidence ≠ (worldOutput w₂).confidence

end AgentSpec.Manifest
