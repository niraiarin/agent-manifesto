import AgentSpec.Manifest.Ontology

/-! # AgentSpec.Manifest.E1 (Week 3 Day 89)

E1 Verification Requires Independence — 2 axiom (verification 独立性 + 共有 bias)。
-/

namespace AgentSpec.Manifest

/-- E1.1: verification 実行 agent は generation agent と独立 (異 id + 内部状態非共有)。 -/
axiom verification_requires_independence :
  ∀ (gen ver : Agent) (action : Action) (w : World),
    generates gen action w →
    verifies ver action w →
    gen.id ≠ ver.id ∧ ¬sharesInternalState gen ver

/-- E1.2: 内部状態共有時、verifier は generator の action を verify できない (bias zero detection)。 -/
axiom shared_bias_reduces_detection :
  ∀ (a b : Agent) (action : Action) (w : World),
    sharesInternalState a b →
    generates a action w →
    ¬verifies b action w

end AgentSpec.Manifest
