import Manifest.Ontology

/-!
# Mathematical Foundation - Control Theory for Feedback-Driven Improvement

Theoretical grounding for T5 (`no_improvement_without_feedback`).

## Derivation Chain - Traceability

```
[R41] Francis & Wonham (1976) "The Internal Model Principle of Control Theory"
  — A regulator can track a reference signal only if it contains
    a model of the signal generator (requires feedback)
[R42] Cover & Thomas (1991) "Elements of Information Theory" Ch. 2
  — Data Processing Inequality: post-processing cannot increase information
  — Without new information (feedback), no improvement in estimate is possible
```

## Mathematical Core

T5 asserts: `structureImproved w w' → ∃ feedback in [w.time, w'.time]`

The control-theoretic grounding:
- Improvement = reduction of error between current state and goal
- Error reduction requires information about the current error (measurement)
- Without feedback, the system operates open-loop: no new information enters
- Data Processing Inequality: processing the same data cannot create new information
- Therefore: no feedback → no new information → no error reduction → no improvement

T5 is a T₀ (natural-science) constraint. Bridge theorems that reference
the T5 declaration are placed in Axioms.lean. This file provides abstract
timestamp interval properties used in those bridges.
-/

namespace Manifest.Foundation

open Manifest

/-- Feedback timestamps in nested intervals: if a timestamp is in [t₁, t₂]
    and t₂ ≤ t₃, then the timestamp is also in [t₁, t₃].

    Reference: [R41] Francis & Wonham (1976) — continuous feedback over
    an interval implies feedback over any super-interval. -/
theorem feedback_interval_widen
    (ts t₁ t₂ t₃ : Nat)
    (h_ge : ts ≥ t₁) (h_le : ts ≤ t₂) (h_ext : t₂ ≤ t₃) :
    ts ≥ t₁ ∧ ts ≤ t₃ :=
  ⟨h_ge, Nat.le_trans h_le h_ext⟩

end Manifest.Foundation
