import AgentSpec.Manifest.Ontology

/-! # AgentSpec.Manifest.T6 (Week 3 Day 85、Manifest 移植)

T6 Humans Are the Final Decision-Makers for Resources — 2 axiom (contract-derived)。

## Theoretical grounding (T₀ contract constraint)

- 人間最終決定権の合意。委譲可能だが取消可能。
-/

namespace AgentSpec.Manifest

/-- T6.1: 全 resource allocation は人間 grantedBy。

    Source: manifesto.md T6 "Humans are the final decision-makers for resources" -/
axiom human_resource_authority :
  ∀ (w : World) (alloc : ResourceAllocation),
    alloc ∈ w.allocations →
    ∃ (human : Agent), isHuman human ∧ human.id = alloc.grantedBy

/-- T6.2: 人間は resource を取消可能。

    Source: manifesto.md T6 "can be revoked by humans" -/
axiom resource_revocable :
  ∀ (w : World) (alloc : ResourceAllocation),
    alloc ∈ w.allocations →
    ∃ (w' : World) (human : Agent),
      isHuman human ∧
      validTransition w w' ∧
      alloc ∉ w'.allocations

end AgentSpec.Manifest
