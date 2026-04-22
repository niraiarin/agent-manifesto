import AgentSpec.Manifest.Ontology

/-! # AgentSpec.Manifest.T4 (Week 3 Day 84、Manifest 移植)

T4 Agent Output Is Stochastic — output_nondeterministic axiom (1/1)。

## Axiom Card

- **Layer**: T₀ (Environment-derived)
- **Content**: 同一 input から異なる output が生じ得る (probabilistic interpretation)。
- **Refutation condition**: 全 LLM が deterministic-only generation に switch
  (temperature=0 + 浮動小数 nondeterminism なし)。

## 降格判定

導出不可能 — `canTransition` が opaque のため、同一前提からの異なる遷移を型から
導出できない。axiom として維持。

依存追加なし (Day 80 で Agent/Action/canTransition、Day 83 で World 拡張済)。
-/

namespace AgentSpec.Manifest

/-- T4.1: Output is non-deterministic — same input may yield different outputs。

    Source: manifesto.md T4 "Different outputs may be produced for the same input" -/
axiom output_nondeterministic :
  ∃ (agent : Agent) (action : Action) (w w₁ w₂ : World),
    canTransition agent action w w₁ ∧
    canTransition agent action w w₂ ∧
    w₁ ≠ w₂

end AgentSpec.Manifest
