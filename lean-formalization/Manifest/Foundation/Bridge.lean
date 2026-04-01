import Manifest.Foundation.Probability
import Manifest.Axioms

/-!
# Bridge: Softmax Foundation → Manifest Axiom System

Connects the mathematical foundation (softmax probability theory) to the
manifest's abstract transition system (canTransition).

## Derivation Chain (Traceability)

```
[R1] Kolmogorov (1933) → Mathlib PMF
[R2] Gao & Pavel (2017) → softmax_full_support (Foundation/Probability.lean)
[R3] Jang et al. (2017) → categorical sampling model
  ↓
[Bridge Axiom 1] tokenWorld_is_transition
  "Selecting a token with positive softmax probability produces a
   valid state transition to the world determined by that token."
[Bridge Axiom 2] distinct_tokens_distinct_worlds
  "Different tokens produce different world states (injectivity)."
  ↓
T4 (output_nondeterministic) — now a theorem
```

## Epistemic Status of Bridge Axioms

The bridge axioms are **architectural axioms**: they describe how the
LLM's sampling mechanism maps to the abstract transition system.

- Bridge Axiom 1: "softmax probability > 0 implies transition is possible"
  — This is a **modeling decision**: we define canTransition to include
  all outcomes that the LLM can produce with nonzero probability.
  Grounded in [R3] (Gumbel-Softmax categorical sampling).

- Bridge Axiom 2: "different tokens produce different worlds"
  — This is a **structural property** of autoregressive generation:
  appending different tokens to the same context creates distinguishable
  output states. Grounded in the injectivity of token embedding.

These bridge axioms are **more fundamental** than T4 because they describe
the mechanism (sampling from softmax distribution) rather than the consequence
(nondeterministic output). T4 follows as a corollary.
-/

namespace Manifest.Foundation

open Manifest

/-!
## Bridge Axiom 1: Sampling Induces Transition

If a token `v` has positive probability under the softmax distribution
(i.e., softmax(z/τ)_v > 0), then there exists a world state `w'` such that
the agent can transition from `w` to `w'` by selecting token `v`.

This axiom connects the probability-theoretic concept (positive probability)
to the transition-theoretic concept (canTransition).

Reference: [R3] Jang et al. (2017). The Gumbel-Max trick shows that
sampling from Categorical(softmax(z/τ)) produces token v with probability
softmax(z/τ)_v. If this probability is positive, the sampling event is possible,
and the corresponding transition is realizable.
-/

/-!
## Bridge Axiom 2: Distinct Tokens Produce Distinct Worlds

Different tokens, when selected as the next output, produce distinguishable
world states. This captures the injectivity of the token-to-world mapping:
if token v₁ ≠ v₂, then the world after generating v₁ differs from the world
after generating v₂.

This is a structural property of autoregressive generation: the generated
token is part of the output (appended to the sequence), so different tokens
produce observably different outputs, hence different world states.
-/

/-- A token-to-world mapping: given an agent, action, current world, and a sampled
    token, produces the resulting world state.

    This captures the autoregressive generation step: selecting token v in context
    (agent, action, w) deterministically produces a specific next world state.
    The nondeterminism comes from the token selection (softmax sampling),
    not from the world-production step.

    Reference: Autoregressive generation — each token selection deterministically
    extends the output sequence. -/
opaque tokenWorld {V : Type} [Fintype V]
    (agent : Agent) (action : Action) (w : World) (v : V) : World

/-- [Axiom Card]
    Layer: Γ \ T₀ (Architecture-derived)
    Content: The world produced by selecting a token is a valid transition target.
          tokenWorld is consistent with canTransition.
    Basis: The autoregressive generation step (select token → produce output)
          is a valid state transition in the abstract model.
    Source: LLM architecture (decoder step)
    Refutation condition: If token selection does not constitute a state transition. -/
axiom tokenWorld_is_transition
    {V : Type} [Fintype V] [Nonempty V]
    (agent : Agent) (action : Action) (w : World)
    (z : Logits V) (τ : ℝ) (hτ : τ > 0) (v : V) :
    softmax z τ hτ v > 0 →
    canTransition agent action w (tokenWorld agent action w v)

/-- [Axiom Card]
    Layer: Γ \ T₀ (Architecture-derived)
    Content: Different tokens produce different world states.
          If v₁ ≠ v₂, then tokenWorld(v₁) ≠ tokenWorld(v₂).
    Basis: In autoregressive generation, the selected token is appended to the
          output sequence. Different tokens produce different sequences,
          hence observably different world states (the output text differs).
    Source: Injectivity of token embedding in the output sequence.
    Refutation condition: If distinct tokens map to identical outputs
          (e.g., perfect synonyms at the token level). -/
axiom distinct_tokens_distinct_worlds
    {V : Type} [Fintype V]
    (agent : Agent) (action : Action) (w : World)
    (v₁ v₂ : V) (hne : v₁ ≠ v₂) :
    tokenWorld agent action w v₁ ≠ tokenWorld agent action w v₂

/-!
## Derivation of T4

T4 (`output_nondeterministic`) follows from:
1. softmax_full_support: τ > 0 → all tokens have positive probability
2. sampling_induces_transition: positive probability → transition exists
3. The vocabulary has at least 2 tokens

We derive a **weaker but sufficient** version that matches the shape of T4.
-/

/-- T4 derived from softmax foundation + bridge axioms.

    [Derivation Card]
    Previously: axiom output_nondeterministic (T₀, Natural-science-derived)
    Now: theorem derived from softmax_full_support + sampling_induces_transition
    Derivation:
      1. By softmax_full_support [R2], every token has P > 0
      2. By sampling_induces_transition [R3], each such token induces a transition
      3. Two distinct tokens (vocabulary size ≥ 2) induce two transitions
      4. These transitions may target different worlds (nondeterminism)
    Source: manifesto.md T4 "Different outputs may be produced for the same input"

    Note: This derivation uses 3 bridge axioms which replace 1 T4 axiom.
    The axiom count increases (+2), but the axioms are now grounded in
    LLM architecture (softmax sampling, token-to-world mapping) rather
    than being an abstract claim about nondeterminism.

    Bridge axioms are **more fundamental** because they describe the
    mechanism. T4 is a **consequence** of how LLMs generate output. -/
theorem output_nondeterministic_from_softmax
    {V : Type} [Fintype V] [Nonempty V]
    (agent : Agent) (action : Action) (w : World)
    (z : Logits V) (τ : ℝ) (hτ : τ > 0)
    (v₁ v₂ : V) (hne : v₁ ≠ v₂) :
    ∃ (w₁ w₂ : World),
      canTransition agent action w w₁ ∧
      canTransition agent action w w₂ ∧
      w₁ ≠ w₂ := by
  refine ⟨tokenWorld agent action w v₁, tokenWorld agent action w v₂, ?_, ?_, ?_⟩
  · exact tokenWorld_is_transition agent action w z τ hτ v₁ (softmax_full_support z τ hτ v₁)
  · exact tokenWorld_is_transition agent action w z τ hτ v₂ (softmax_full_support z τ hτ v₂)
  · exact distinct_tokens_distinct_worlds agent action w v₁ v₂ hne

end Manifest.Foundation
