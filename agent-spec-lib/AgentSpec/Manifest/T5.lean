import AgentSpec.Manifest.Ontology

/-! # AgentSpec.Manifest.T5 (Week 3 Day 85、Manifest 移植)

T5 Improvement Is Impossible Without Feedback — 2 axiom (#316 で Process 版追加)。

## Theoretical grounding (T₀ environment constraint)

- 制御理論 Internal Model Principle + Data Processing Inequality
- 外部入力なしに収束は起こらない (closed system では無理)
-/

namespace AgentSpec.Manifest

/-- T5.1: 構造改善には feedback が必須。

    Source: manifesto.md T5 "Without a loop of measurement, comparison, and adjustment, convergence does not occur" -/
axiom no_improvement_without_feedback :
  ∀ (w w' : World),
    structureImproved w w' →
    ∃ (f : Feedback), f ∈ w'.feedbacks ∧
      f.timestamp ≥ w.time ∧ f.timestamp ≤ w'.time

/-- T5.2: process 改善 (#316 meta) にも同じ control loop が必要。 -/
axiom no_process_improvement_without_feedback :
  ∀ (pid : ProcessId) (w w' : World),
    processImproved pid w w' →
    ∃ (f : Feedback), f ∈ w'.feedbacks ∧
      f.target = .process pid ∧
      f.timestamp ≥ w.time ∧ f.timestamp ≤ w'.time

end AgentSpec.Manifest
