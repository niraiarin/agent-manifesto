import Mathlib.Order.Monotone.Basic
import Manifest.Ontology

/-!
# Mathematical Foundation: Risk Theory for Capability-Risk Co-scaling

Grounds E2 (`capability_risk_coscaling`) in established risk/security theory.

## Derivation Chain (Traceability)

```
[R21] Manadhata & Wing (2011) "A Formal Model for a System's Attack Surface"
  — Attack surface monotonicity: capability ⊃ → attack surface ⊃
[R22] Saltzer & Schroeder (1975) "The Protection of Information in Computer Systems"
  — Principle of Least Privilege: minimizing capability minimizes risk
[R23] Dennis & Van Horn (1966) "Programming Semantics for Multiprogrammed Computations"
  — Capability model: capability set = set of possible actions
```

## Mathematical Core

E2 asserts that `riskExposure` is strictly monotone in `actionSpaceSize`:

  `actionSpaceSize agent w < actionSpaceSize agent w' → riskExposure agent w < riskExposure agent w'`

This is precisely the mathematical definition of `StrictMono` (Mathlib):
a function f is strictly monotone if `a < b → f a < f b`.

The security-theoretic grounding [R21]:
- Each new capability (action space entry) enables at least one additional
  adversarial execution trace
- Additional adversarial traces strictly increase the attack surface metric
- Attack surface metric is a monotone function of the capability set size

This is not a statistical claim but an **order-theoretic property**:
the mapping from capability sets to risk levels preserves strict ordering.
-/

namespace Manifest.Foundation

open Manifest

/-!
## Capability-Risk Monotonicity

The core mathematical fact is that any function mapping capability (action space size)
to risk (exposure) that satisfies E2's axiom is a strictly monotone function.

We prove this equivalence and derive properties that follow from strict monotonicity.
-/

/-- E2's axiom is equivalent to stating that riskExposure (viewed as a function of
    actionSpaceSize) is strictly monotone.

    Reference: [R21] Manadhata & Wing (2011)
    "If system A has a larger attack surface than system B, then A allows
    a larger number of adversarial execution traces."

    This is a direct consequence of the definition of StrictMono in Mathlib:
    `StrictMono f ↔ ∀ a b, a < b → f a < f b` -/
theorem capability_risk_is_strict_mono
    (f_risk : Nat → Nat)
    (h : ∀ a b : Nat, a < b → f_risk a < f_risk b) :
    StrictMono f_risk :=
  h

/-- Strict monotonicity implies that equal risk requires equal capability.
    Contrapositive of E2: if risk levels are equal, capability levels must be equal.

    Security interpretation [R22]: if two configurations have the same risk profile,
    they must have the same capability level (no "free capability"). -/
theorem equal_risk_implies_equal_capability
    (f_risk : Nat → Nat)
    (h_mono : StrictMono f_risk)
    (a b : Nat)
    (h_eq : f_risk a = f_risk b) :
    a = b := by
  by_contra h_ne
  rcases Nat.lt_or_gt_of_ne h_ne with h_lt | h_gt
  · exact absurd h_eq (ne_of_lt (h_mono h_lt))
  · exact absurd h_eq (ne_of_gt (h_mono h_gt))

/-- Strict monotonicity implies injectivity: different capability levels
    produce different risk levels.

    Security interpretation [R23]: distinct capability sets are distinguishable
    by their risk profiles. There is no "risk-equivalent" pair of distinct
    capability levels. -/
theorem capability_risk_injective
    (f_risk : Nat → Nat)
    (h_mono : StrictMono f_risk) :
    Function.Injective f_risk :=
  StrictMono.injective h_mono

/-- Capability reduction (least privilege) strictly reduces risk.

    Reference: [R22] Saltzer & Schroeder (1975), Principle of Least Privilege.
    "Every program and every user of the system should operate using the
    least set of privileges necessary to complete the job."

    Mathematical form: if we can accomplish the task with fewer capabilities,
    the risk is strictly lower. -/
theorem least_privilege_reduces_risk
    (f_risk : Nat → Nat)
    (h_mono : StrictMono f_risk)
    (current minimal : Nat)
    (h_less : minimal < current) :
    f_risk minimal < f_risk current :=
  h_mono h_less

end Manifest.Foundation
