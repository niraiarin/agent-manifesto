import Manifest.Ontology

/-!
# Epistemic Layer - EmpiricalPostulate Strength 4 - E1-E2 Premise Set

Formalizes empirical postulates as Lean non-logical axioms (Terminology Reference §4.1).

## Position as Extension of T0
Procedure 2.4.

E1–E2 are "findings repeatedly demonstrated with no known counterexamples,
yet in principle refutable," constituting the extended part (Γ \ T₀) of premise set Γ.
Difference from T₀: based not on external authority (contracts, natural laws)
but on hypotheses grounded in empirical observation (Terminology Reference §9.1 empirical propositions).
They possess refutability (§9.1) and are subject to AGM contraction (§9.2).

In Lean, they are declared as `axiom` just like T₀, but each axiom card
must include a **refutation condition** (Procedure §2.5).

## Relationship to T0
Procedure 2.4.

Γ is an extension of T₀ (Terminology Reference §5.5), so Thm(T₀) ⊆ Thm(Γ).
If an E is refuted, the P's that depend on it (P1, P2) become subject to revision,
but T₀ and P's that depend solely on T₀ (P3–P6) are unaffected.
This follows from the monotonicity of extensions (§2.5 / §5.3).

## Correspondence Table

| Axiom name | Corresponding E | Expressed property | Γ \ T₀ membership basis |
|-----------|-----------|-------------|---------------|
| `verification_requires_independence` | E1 | Generation and evaluation must be separated | Hypothesis-derived |
| `no_self_verification` | E1 | Prohibition of self-verification | Hypothesis-derived |
| `shared_bias_reduces_detection` | E1 | Shared bias degrades detection power | Hypothesis-derived |
| `capability_risk_coscaling` | E2 | Capability growth is inseparable from risk growth | Hypothesis-derived |
-/

namespace Manifest

-- ============================================================
-- E1: 検証には独立性が必要である
-- ============================================================

/-!
## E1 Verification Requires Independence

"Generation and evaluation by the same process has been demonstrated
  to be structurally unreliable across all domains (scientific peer review,
  financial auditing, software testing). Given T4 (probabilistic output),
  it is empirically supported that when a process with the same biases
  handles both generation and evaluation, detection power degrades."

E1 is decomposed into three axioms:
1. The agents responsible for generation and evaluation must be separated (structural independence)
2. Self-verification is not permitted (prohibition of self-verification)
3. Verification between agents sharing internal state has low detection power (bias correlation)
-/

/-- [Axiom Card]
    Layer: Γ \ T₀ (Hypothesis-derived)
    Content: The agents responsible for generation and evaluation must be independent.
          The agent that generated an action and the agent that verifies it
          must be distinct individuals that do not share internal state.
    Basis: A principle repeatedly demonstrated in scientific peer review,
          financial auditing, software testing, etc.
    Source: manifesto.md E1 "Verification Requires Independence"
    Refutation condition: If self-verification is demonstrated to have detection power
              equal to external verification (e.g., realization of complete self-awareness) -/
axiom verification_requires_independence :
  ∀ (gen ver : Agent) (action : Action) (w : World),
    generates gen action w →
    verifies ver action w →
    gen.id ≠ ver.id ∧ ¬sharesInternalState gen ver

/-- [Axiom Card]
    Layer: Γ \ T₀ (Hypothesis-derived)
    Content: Prohibition of self-verification.
          The same agent cannot perform both generation and verification.
          A corollary of E1a (Terminology Reference §4.2 corollary), but declared explicitly.
    Basis: Due to T4 (probabilistic output), the bias of the same process
          affects both generation and evaluation, structurally degrading detection power.
    Source: manifesto.md E1 + Principles.lean e1b_from_e1a proves derivation from E1a
    Refutation condition: Same as the refutation condition for E1a -/
axiom no_self_verification :
  ∀ (agent : Agent) (action : Action) (w : World),
    generates agent action w →
    ¬verifies agent action w

/-- [Axiom Card]
    Layer: Γ \ T₀ (Hypothesis-derived)
    Content: Sharing internal state correlates biases.
          Two agents sharing internal state cannot be considered independent
          verifiers, even if one generates and the other verifies.
    Basis: Detection power degradation due to shared bias is empirically
          supported by conflict-of-interest policies in scientific research,
          audit firm rotation requirements, etc.
    Source: manifesto.md E1 "When a process with the same biases handles both
            generation and evaluation, detection power degrades"
    Refutation condition: If it is demonstrated that bias correlation has no effect on detection power -/
axiom shared_bias_reduces_detection :
  ∀ (a b : Agent) (action : Action) (w : World),
    sharesInternalState a b →
    generates a action w →
    ¬verifies b action w

-- ============================================================
-- E2: 能力の増大はリスクの増大と不可分である
-- ============================================================

/-!
## E2 Capability Growth Is Inseparable from Risk Growth

"It has been repeatedly observed across all tools that capability
  enables both positive and negative outcomes. However, there is no
  proof that means to increase capability while completely containing
  risk (such as a perfect sandbox) are impossible in principle."

E2 is formalized as a single axiom.
Expansion of the action space (actionSpaceSize) necessarily entails
an increase in risk exposure (riskExposure).

## Note on Empirical Status

E2 is an empirical postulate and does not exclude the possibility
that a "perfect sandbox" may be discovered in the future. It is
assumed as an axiom, but if refuted, P1 (co-scaling of autonomy
and vulnerability) becomes subject to revision.
-/

/-- [Axiom Card]
    Layer: Γ \ T₀ (Hypothesis-derived)
    Content: Capability growth is inseparable from risk growth.
          When an agent's action space expands, risk exposure necessarily increases.
    Basis: Attack surface monotonicity — each additional capability enables at least
          one additional adversarial execution trace, strictly increasing the attack
          surface metric (order-theoretic property, not statistical claim).
    Source: manifesto.md E2 "Capability Growth Is Inseparable from Risk Growth"
    Refutation condition: If means to increase capability while completely containing risk
              are discovered (e.g., a perfect sandbox)

    Mathematical grounding (Foundation/RiskTheory.lean):
      [R21] Manadhata & Wing (2011) "A Formal Model for a System's Attack Surface"
            — Attack surface monotonicity: capability ⊃ → attack surface ⊃
      [R22] Saltzer & Schroeder (1975) "The Protection of Information in Computer Systems"
            — Principle of Least Privilege: minimizing capability minimizes risk
      [R23] Dennis & Van Horn (1966) "Programming Semantics for Multiprogrammed Computations"
            — Capability model: capability set = set of possible actions
      Formally proven (Foundation/RiskTheory.lean):
        capability_risk_is_strict_mono, equal_risk_implies_equal_capability,
        capability_risk_injective, least_privilege_reduces_risk (0 sorry)
      Bridge (EmpiricalPostulates.lean):
        e2_equal_risk_equal_capability — contrapositive of E2 on actual opaque functions
      Derivation: [R21] attack surface monotonicity → StrictMono (Mathlib)
                  → E2 is precisely the StrictMono property of the risk function
                  → e2_equal_risk_equal_capability bridges to opaque riskExposure/actionSpaceSize

    降格判定: 導出不可能 — actionSpaceSize, riskExposure が共に opaque のため、
    型定義から StrictMono 関係を導出できない。axiom として維持、根拠は上記で検証済み。

    **Choice of inequality: `<` vs `≤`**

    The manifesto's "inseparable" implies strict co-scaling, so
    `<` (strict increase) is adopted. If the refutation condition is met (discovery of
    a risk containment method), this axiom becomes subject to AGM contraction
    (Terminology Reference §9.2), and P1 (co-scaling of autonomy and vulnerability)
    is revised. -/
axiom capability_risk_coscaling :
  ∀ (agent : Agent) (w w' : World),
    actionSpaceSize agent w < actionSpaceSize agent w' →
    riskExposure agent w < riskExposure agent w'

/-- E2 bridge: equal risk exposure implies equal action space size.
    Contrapositive of capability_risk_coscaling — if two worlds have
    the same risk exposure for an agent, they must have the same
    action space size. No "free capability" is possible.

    Bridges Foundation/RiskTheory.lean's abstract StrictMono theorems
    to the actual opaque functions used in E2.

    Reference: [R22] Saltzer & Schroeder (1975) -/
theorem e2_equal_risk_equal_capability (agent : Agent) (w w' : World)
    (h_eq : riskExposure agent w = riskExposure agent w') :
    actionSpaceSize agent w = actionSpaceSize agent w' :=
  match Nat.lt_or_ge (actionSpaceSize agent w) (actionSpaceSize agent w'),
        Nat.lt_or_ge (actionSpaceSize agent w') (actionSpaceSize agent w) with
  | Or.inl h_lt, _ => absurd h_eq (Nat.ne_of_lt (capability_risk_coscaling agent w w' h_lt))
  | _, Or.inl h_gt => absurd (h_eq.symm) (Nat.ne_of_lt (capability_risk_coscaling agent w' w h_gt))
  | Or.inr h_ge, Or.inr h_ge' => Nat.le_antisymm h_ge' h_ge

-- ============================================================
-- Sorry Inventory (Phase 2)
-- ============================================================

/-!
## Sorry Inventory Phase 2 Additions

| Location | Reason for sorry |
|------|-------------|
| `Ontology.lean: generates` | opaque — to be concretized as Worker actions in Phase 3+ |
| `Ontology.lean: verifies` | opaque — to be concretized as Verifier actions in Phase 3+ |
| `Ontology.lean: sharesInternalState` | opaque — to be concretized as session/parameter sharing in Phase 3+ |
| `Ontology.lean: actionSpaceSize` | opaque — to be quantified as Observable in Phase 4+ |
| `Ontology.lean: riskExposure` | opaque — to be quantified as Observable in Phase 4+ |
-/

end Manifest
