import AgentSpec.Manifest.Ontology

/-! # AgentSpec.Manifest.T7 (Week 3 Day 86、Manifest 移植)

T7 Resources for Task Execution Are Finite — 2 axiom (resource bound + sequential time)。
-/

namespace AgentSpec.Manifest

/-- T7.1: 全 resource allocation の合計は global bound 以下。

    Source: manifesto.md T7 "Resources are finite" -/
axiom resource_finite :
  ∀ (w : World),
    (w.allocations.map (·.amount)).foldl (· + ·) 0 ≤ globalResourceBound

/-- T7.2: 逐次実行時間は加算的 (sequential composition の time monotonicity)。

    Source: manifesto.md T7 "Sequential execution time exceeds either component" -/
axiom sequential_exceeds_component :
  ∀ (t1 t2 : Task),
    executionDuration t1 > 0 →
    executionDuration t2 > 0 →
    executionDuration t1 + executionDuration t2 > executionDuration t1 ∧
    executionDuration t1 + executionDuration t2 > executionDuration t2

end AgentSpec.Manifest
