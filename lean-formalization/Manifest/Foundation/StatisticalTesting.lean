import Manifest.Ontology

/-!
# Mathematical Foundation - Statistical Testing for Verification Independence

Theoretical grounding for E1 (`verification_requires_independence`,
`no_self_verification`, `shared_bias_reduces_detection`).

## Derivation Chain - Traceability

```
[R61] Neyman & Pearson (1933) "On the Problem of the Most Efficient Tests"
  — Independent testing maximizes detection power; correlated tests
    have strictly lower power than independent tests
[R62] Podsakoff et al. (2003) "Common Method Biases in Behavioral Research"
  — Shared method/source biases inflate correlations and reduce
    the ability to detect true effects (common method variance)
[R63] AICPA / ISA 610 — Auditing standards requiring auditor independence
  — Professional auditing standards codify the empirical observation
    that self-review compromises audit quality
```

## Mathematical Core

E1 asserts three related properties:
1. Generator and verifier must be distinct and not share internal state
2. Self-verification is prohibited (derivable from 1 — see `e1b_from_e1a`)
3. Shared internal state degrades detection power

The statistical grounding:
- In hypothesis testing (Neyman-Pearson), test power depends on the
  independence of the test statistic from the null hypothesis generation
- When the same process generates and evaluates, the test statistic is
  correlated with the generation process (common method variance)
- This correlation reduces power: P(detect error | same process) <
  P(detect error | independent process)

E1 axioms are Γ\T₀ (hypothesis-derived) — they are empirical observations
supported by extensive evidence across domains (peer review, auditing,
software testing) but are not physical laws.
-/

namespace Manifest.Foundation

open Manifest

/-!
## Independence and Detection

Abstract properties of independent verification, expressed without
reference to the specific E1 axiom declarations.
-/

/-- If a property requires two distinct agents (id₁ ≠ id₂), then
    a single agent cannot satisfy both roles simultaneously.

    This is the logical core of why self-verification fails:
    an agent's id always equals itself.

    Reference: [R61] Neyman & Pearson (1933) — the test must be
    independent of the hypothesis-generating process. -/
theorem self_id_not_distinct (id : AgentId) : ¬(id ≠ id) :=
  fun h => h rfl

/-- Independence is symmetric: if A does not share state with B,
    then B does not share state with A.

    Reference: [R62] Podsakoff (2003) — common method variance is
    symmetric between source and evaluator. -/
theorem independence_symmetric
    (h_sym : ∀ (a b : Agent), sharesInternalState a b → sharesInternalState b a)
    (a b : Agent)
    (h_not : ¬sharesInternalState a b) :
    ¬sharesInternalState b a :=
  fun h => h_not (h_sym b a h)

end Manifest.Foundation
