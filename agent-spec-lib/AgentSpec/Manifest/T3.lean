import AgentSpec.Manifest.Ontology

/-! # AgentSpec.Manifest.T3 (Week 3 Day 84、Manifest 移植)

T3 Context Window Is Finite — context_contribution_nonuniform axiom (1/1)。

## Axiom Card

- **Layer**: T₀ (Environment-derived)
- **Content**: Not all context items contribute equally to all tasks。Task に対して
  precision 寄与 0 の item が必ず存在 (information theory consequence)。
- **Theoretical grounding**: [R*] Shannon (1948) "A Mathematical Theory of Communication"
  — 情報量とエントロピー、relevance の非均一性。

## 降格判定

導出不可能 — `precisionContribution` が opaque のため、寄与の non-uniformity を
型から導出できない。axiom として維持。
-/

namespace AgentSpec.Manifest

/-- T3.1: Context contribution is non-uniform across items.

    Source: manifesto.md T3 "A finite amount of information ... can only be processed at once"
    Refutation condition: If all information contributes equally to all tasks
    (contradicts information theory). -/
axiom context_contribution_nonuniform :
  ∀ (task : Task),
    task.precisionRequired.required > 0 →
    ∃ (item : ContextItem),
      precisionContribution item task = 0

end AgentSpec.Manifest
