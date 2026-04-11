import Manifest.Ontology

/-!
# Mathematical Foundation - Information Theory for Non-uniform Context Contribution

Grounds T3 (`context_contribution_nonuniform`) in information theory.

## Derivation Chain - Traceability

```
[R51] Shannon (1948) "A Mathematical Theory of Communication"
  — Information content varies across symbols in any non-trivial source
[R52] Tishby, Pereira & Bialek (1999) "The Information Bottleneck Method"
  — Relevance of information is task-dependent; compression must discard
    irrelevant information, implying non-uniform contribution
```

## Mathematical Core

T3 asserts: for any task with positive precision requirement, there exists
a context item with zero precision contribution.

The information-theoretic grounding:
- In any finite information set, the mutual information between each item
  and a specific task objective varies (Shannon 1948)
- Some items are irrelevant to the task: their mutual information with the
  task is zero (or negligible)
- The Information Bottleneck (Tishby 1999) formalizes this: optimal compression
  preserves task-relevant information and discards the rest
- Therefore: for any non-trivial task, irrelevant context items exist

This is a T₀ (natural-science) constraint. The Foundation theorems below
prove consequences of the axiom, not derivations of it.
-/

namespace Manifest.Foundation

open Manifest

/-!
## Non-uniform Contribution Properties

The existence of zero-contribution items implies that context is not
uniformly valuable — some items can be removed without loss.
-/

/-- If a zero-contribution item exists (T3), then the context contains
    at least one item that could be removed without reducing precision.

    Reference: [R52] Tishby (1999) — the information bottleneck compresses
    input by discarding items with zero mutual information to the task.

    Bridge: directly derives from `context_contribution_nonuniform` axiom. -/
theorem removable_context_exists
    (h_t3 : ∀ (task : Task), task.precisionRequired.required > 0 →
      ∃ (item : ContextItem), precisionContribution item task = 0)
    (task : Task)
    (h_pos : task.precisionRequired.required > 0) :
    ∃ (item : ContextItem), precisionContribution item task = 0 :=
  h_t3 task h_pos

/-- Non-uniform contribution implies that context quality matters more
    than context quantity: adding irrelevant items does not help.

    Reference: [R51] Shannon (1948) — adding zero-entropy symbols to a
    message does not increase its information content.

    This theorem shows that for any two tasks with positive precision
    requirements, zero-contribution items exist for both (independently). -/
theorem zero_contribution_per_task
    (h_t3 : ∀ (task : Task), task.precisionRequired.required > 0 →
      ∃ (item : ContextItem), precisionContribution item task = 0)
    (task₁ task₂ : Task)
    (h1 : task₁.precisionRequired.required > 0)
    (h2 : task₂.precisionRequired.required > 0) :
    (∃ (item : ContextItem), precisionContribution item task₁ = 0) ∧
    (∃ (item : ContextItem), precisionContribution item task₂ = 0) :=
  ⟨h_t3 task₁ h1, h_t3 task₂ h2⟩

end Manifest.Foundation
