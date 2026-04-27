import Mathlib.Probability.ProbabilityMassFunction.Basic
import Mathlib.Probability.ProbabilityMassFunction.Constructions
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import AgentSpec.Manifest.Ontology

/-!
# Mathematical Foundation - Probability Theory for LLM Output

Grounds T4 (`output_nondeterministic`) in established probability theory.

## Derivation Chain - Traceability

```
[R1] Kolmogorov (1933): Probability axioms
  → Mathlib: PMF α (HasSum f 1)
[R2] Gao & Pavel (2017, arXiv:1704.00805): Softmax properties
  → softmax_pos: τ > 0 → ∀ i, softmax(z/τ)_i > 0
[R3] Jang et al. (2017, ICLR, arXiv:1611.01144): Gumbel-Softmax
  → Categorical sampling from softmax distribution
```

## Key Theorem

`softmax_full_support`: For temperature τ > 0, softmax assigns strictly
positive probability to all elements, hence sampling can produce any element.
This grounds T4: same input (logits z) can yield different outputs (tokens).

## Design Decision

We use `Finset` and `NNReal` rather than full measure theory, following the
approach of infotheo (Affeldt et al., JAR 2014) for finite discrete probability.
This is sufficient for LLM token distributions over finite vocabularies.
-/

namespace AgentSpec.Manifest.Foundation

/-- A finite vocabulary (token set). Abstractly, any nonempty Fintype. -/
class Vocabulary (V : Type) extends Fintype V where
  [nonempty : Nonempty V]

attribute [instance] Vocabulary.nonempty

/-- Logits: raw scores output by the model before softmax normalization.
    Corresponds to the pre-activation values z_i in the transformer's output layer. -/
def Logits (V : Type) [Fintype V] := V → ℝ

/-- Softmax function: maps logits to a probability distribution over vocabulary V.
    softmax(z/τ)_i = exp(z_i/τ) / Σ_j exp(z_j/τ)

    Reference: [R2] Gao & Pavel (2017), Definition 1.
    Properties: (1) output is in the probability simplex Δ_|V|,
    (2) for τ > 0, all components are strictly positive. -/
noncomputable def softmax {V : Type} [Fintype V] [Nonempty V]
    (z : Logits V) (τ : ℝ) (_hτ : τ > 0) : V → ℝ :=
  fun v => Real.exp (z v / τ) / (∑ w : V, Real.exp (z w / τ))

/-- The denominator of softmax is strictly positive (sum of exponentials). -/
theorem softmax_denom_pos {V : Type} [Fintype V] [Nonempty V]
    (z : Logits V) (τ : ℝ) (_hτ : τ > 0) :
    (∑ w : V, Real.exp (z w / τ)) > 0 := by
  apply Finset.sum_pos
  · intro v _
    exact Real.exp_pos _
  · exact Finset.univ_nonempty

/-- Each component of softmax is strictly positive.
    Reference: [R2] Gao & Pavel (2017), Proposition 1.
    Key property: τ > 0 → exp(z_i/τ) > 0 → softmax_i > 0. -/
theorem softmax_pos {V : Type} [Fintype V] [Nonempty V]
    (z : Logits V) (τ : ℝ) (hτ : τ > 0) (v : V) :
    softmax z τ hτ v > 0 := by
  unfold softmax
  apply div_pos
  · exact Real.exp_pos _
  · exact softmax_denom_pos z τ hτ

/-- Softmax components sum to 1 (defines a valid probability distribution).
    Reference: [R1] Kolmogorov normalization axiom. -/
theorem softmax_sum_one {V : Type} [Fintype V] [Nonempty V]
    (z : Logits V) (τ : ℝ) (hτ : τ > 0) :
    (∑ v : V, softmax z τ hτ v) = 1 := by
  unfold softmax
  simp_rw [div_eq_mul_inv]
  rw [← Finset.sum_mul]
  exact mul_inv_cancel₀ (ne_of_gt (softmax_denom_pos z τ hτ))

/-- The softmax distribution has full support: every token has nonzero probability.
    This is the mathematical core of T4 (output_nondeterministic).

    Reference: [R2] Gao & Pavel (2017), Corollary of Proposition 1.
    When τ > 0, the softmax function maps any logit vector to the interior
    of the probability simplex (all probabilities strictly positive).

    Consequence: For any two distinct tokens v₁ ≠ v₂, both have positive
    probability, so sampling can produce either — output is nondeterministic. -/
theorem softmax_full_support {V : Type} [Fintype V] [Nonempty V]
    (z : Logits V) (τ : ℝ) (hτ : τ > 0) :
    ∀ v : V, softmax z τ hτ v > 0 :=
  softmax_pos z τ hτ

/-- If the vocabulary has at least 2 elements and softmax has full support,
    then there exist two distinct tokens with positive probability.
    This is the existential form of nondeterminism. -/
theorem nondeterministic_output {V : Type} [Fintype V] [Nonempty V]
    (z : Logits V) (τ : ℝ) (hτ : τ > 0)
    (h_vocab : ∃ v₁ v₂ : V, v₁ ≠ v₂) :
    ∃ v₁ v₂ : V, v₁ ≠ v₂ ∧ softmax z τ hτ v₁ > 0 ∧ softmax z τ hτ v₂ > 0 := by
  obtain ⟨v₁, v₂, hne⟩ := h_vocab
  exact ⟨v₁, v₂, hne, softmax_pos z τ hτ v₁, softmax_pos z τ hτ v₂⟩

end AgentSpec.Manifest.Foundation
