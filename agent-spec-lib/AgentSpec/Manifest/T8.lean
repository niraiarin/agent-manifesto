import AgentSpec.Manifest.Ontology

/-! # AgentSpec.Manifest.T8 (Week 3 Day 86、Manifest 移植)

T8 Tasks Have a Precision Level — theorem (axiom ではなく PrecisionLevel.required_pos 由来)。

T1-T7 は axiom 13 件で構成、T8 は型強制 (PrecisionLevel structure の required_pos
invariant) で derive 可能 → axiom 不要、theorem として記録。
-/

namespace AgentSpec.Manifest

/-- T8.1: 全 Task の precisionRequired.required > 0。

    Source: manifesto.md T8 "Tasks have a precision level"
    Derivation: PrecisionLevel.required_pos invariant が structure に embed 済。 -/
theorem task_has_precision :
  ∀ (task : Task),
    task.precisionRequired.required > 0 := by
  intro task
  exact task.precisionRequired.required_pos

end AgentSpec.Manifest
