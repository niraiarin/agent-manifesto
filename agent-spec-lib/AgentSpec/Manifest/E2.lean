import AgentSpec.Manifest.Ontology

/-! # AgentSpec.Manifest.E2 (Week 3 Day 89)

E2 Capability Increase Is Inseparable from Risk Increase — 1 axiom (capability-risk coscaling)。
-/

namespace AgentSpec.Manifest

/-- E2.1: action space 拡大は risk exposure 拡大を伴う (free capability 不可)。 -/
axiom capability_risk_coscaling :
  ∀ (agent : Agent) (w w' : World),
    actionSpaceSize agent w < actionSpaceSize agent w' →
    riskExposure agent w < riskExposure agent w'

end AgentSpec.Manifest
