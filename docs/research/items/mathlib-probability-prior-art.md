# Prior Art: Mathlib Probability Infrastructure for LLM Axiom Derivation

**Date**: 2026-04-01
**Status**: Step 0b (Prior Art Research)
**Goal**: Assess Mathlib's probability/measure/order infrastructure for deriving T4, T5, T3, T1, E1, E2 as theorems from mathematical foundations.

---

## 1. Mathlib Probability Module Map (as of v4.29.0)

### 1.1 Directory Structure (`Mathlib/Probability/`)

```
Probability/
├── BorelCantelli.lean
├── CDF.lean
├── CentralLimitTheorem.lean
├── CondVar.lean
├── ConditionalExpectation.lean
├── ConditionalProbability.lean
├── Density.lean
├── HasLaw.lean
├── HasLawExists.lean
├── IdentDistrib.lean
├── IdentDistribIndep.lean
├── Notation.lean
├── ProductMeasure.lean
├── StrongLaw.lean
├── UniformOn.lean
├── Combinatorics/
├── Decision/Risk/
├── Distributions/           ← Exponential, Gamma, Gaussian, Geometric, Pareto, Poisson, Uniform
├── Independence/             ← IndepFun, IndepSet, iIndepFun, iIndepSet, conditional variants
├── Kernel/                   ← Markov kernels, composition, disintegration, Ionescu-Tulcea
│   ├── Basic.lean
│   ├── CompProdEqIff.lean
│   ├── CondDistrib.lean
│   ├── Condexp.lean
│   ├── Defs.lean
│   ├── Integral.lean
│   ├── Invariance.lean
│   ├── Irreducible.lean
│   ├── MeasurableIntegral.lean
│   ├── MeasurableLIntegral.lean
│   ├── Posterior.lean
│   ├── Proper.lean
│   ├── RadonNikodym.lean
│   ├── Representation.lean
│   ├── SetIntegral.lean
│   ├── WithDensity.lean
│   ├── Category/
│   ├── Composition/
│   ├── Disintegration/
│   └── IonescuTulcea/
├── Martingale/
├── Moments/
├── ProbabilityMassFunction/  ← PMF type, monad, constructions, binomial
└── Process/
```

### 1.2 Key Types and Definitions

| Concept | Mathlib Path | Type / Definition |
|---------|-------------|-------------------|
| PMF | `Mathlib.Probability.ProbabilityMassFunction.Basic` | `PMF α := {f : α → ℝ≥0∞ // HasSum f 1}` |
| PMF.pure | `...ProbabilityMassFunction.Monad` | Single value with prob 1 |
| PMF.bind | `...ProbabilityMassFunction.Monad` | Sequential sampling (monad) |
| PMF.ofFintype | `...ProbabilityMassFunction.Constructions` | From `f : α → ENNReal` with `∑ a, f a = 1` |
| PMF.normalize | `...ProbabilityMassFunction.Constructions` | `f a * (∑ x, f x)⁻¹` |
| PMF.bernoulli | `...ProbabilityMassFunction.Constructions` | Bernoulli on `Bool` |
| PMF.toMeasure | `...ProbabilityMassFunction.Basic` | PMF → Measure (probability measure) |
| Measure.toPMF | `...ProbabilityMassFunction.Basic` | Measure → PMF (on countable α) |
| ProbabilityMeasure | `Mathlib.MeasureTheory.Measure.ProbabilityMeasure` | Subtype of measures with `μ univ = 1` |
| IsProbabilityMeasure | `Mathlib.MeasureTheory.Measure.MeasureSpace` | Typeclass for probability measures |
| Cond probability | `Mathlib.Probability.ConditionalProbability` | `μ[|s] := (μ s)⁻¹ • μ.restrict s` |
| Bayes' theorem | `Mathlib.Probability.ConditionalProbability` | `μ[t|s] = (μ s)⁻¹ * μ[s|t] * (μ t)` |
| IndepFun | `Mathlib.Probability.Independence.Basic` | `f ⟂ᵢ[μ] g` — σ-algebra independence |
| iIndepFun | `Mathlib.Probability.Independence.Basic` | Family independence |
| CondIndepFun | `Mathlib.Probability.Independence.Basic` | Conditional independence |
| Kernel | `Mathlib.Probability.Kernel.Defs` | Markov kernel α → Measure β |
| Kernel.comp | `Mathlib.Probability.Kernel.Composition` | `η ∘ₖ κ` composition |
| Kernel.compProd | `Mathlib.Probability.Kernel.Composition` | `κ ⊗ₖ η` composition-product |
| condExp | `Mathlib.MeasureTheory.Function.ConditionalExpectation.Basic` | `μ[Y | m]` |
| Variance | `Mathlib.Probability.Moments` | `variance X P` |
| MGF | `Mathlib.Probability.Moments` | Moment generating function |
| Expectation | `Mathlib.Probability.Notation` | `P[X] = ∫ a, X a ∂P` |

### 1.3 Distributions Available

| Distribution | Module Path |
|-------------|-------------|
| Gaussian | `Mathlib.Probability.Distributions.Gaussian` |
| Uniform | `Mathlib.Probability.Distributions.Uniform` |
| Exponential | `Mathlib.Probability.Distributions.Exponential` |
| Gamma | `Mathlib.Probability.Distributions.Gamma` |
| Geometric | `Mathlib.Probability.Distributions.Geometric` |
| Pareto | `Mathlib.Probability.Distributions.Pareto` |
| Poisson | `Mathlib.Probability.Distributions.Poisson` |
| Bernoulli | `Mathlib.Probability.ProbabilityMassFunction.Constructions` (PMF.bernoulli) |
| Binomial | `Mathlib.Probability.ProbabilityMassFunction.Binomial` |

### 1.4 Entropy (Status: Partially Available)

| Item | Location | Status |
|------|----------|--------|
| Binary entropy `binEntropy` | `Mathlib.Analysis.SpecialFunctions.BinaryEntropy` | **Available** — `p * log p⁻¹ + (1-p) * log (1-p)⁻¹` |
| Q-ary entropy `qaryEntropy` | Same | **Available** — `p * log (q-1) + binEntropy p` |
| Shannon entropy (general) | PFR project (teorth/pfr) | **NOT yet in Mathlib** — ported PR pending |
| KL divergence | Mathlib (definition only) | **Definition exists**, few properties ported |
| Kernel entropy | PFR → future Mathlib | **NOT yet in Mathlib** |
| Mutual information | PFR project | **NOT yet in Mathlib** |

**Key insight**: The PFR project formalized extensive Shannon entropy theory but most has NOT been merged into Mathlib yet. Only `binEntropy`/`qaryEntropy` and KL divergence definition are in Mathlib.

### 1.5 Measure Theory Infrastructure

| Item | Module Path |
|------|-------------|
| Radon-Nikodym | `Mathlib.MeasureTheory.Measure.Decomposition.RadonNikodym` |
| Lebesgue decomposition | `Mathlib.MeasureTheory.Measure.Decomposition.Lebesgue` |
| Conditional expectation | `Mathlib.MeasureTheory.Function.ConditionalExpectation.Basic` |
| Fubini's theorem | `Mathlib.MeasureTheory.Integral.Prod` |
| Product measures | `Mathlib.MeasureTheory.Measure.Prod` |
| Disintegration theorem | `Mathlib.Probability.Kernel.Disintegration.StandardBorel` |

### 1.6 Order Theory Infrastructure

| Item | Module Path |
|------|-------------|
| Monotone / StrictMono | `Mathlib.Order.Monotone.Basic` |
| GaloisConnection | `Mathlib.Order.GaloisConnection.Defs` — `∀ a b, l a ≤ b ↔ a ≤ u b` |
| GaloisInsertion | Same — `l ∘ u = id` |
| Lattice | `Mathlib.Order.Lattice` |
| CompleteLattice | `Mathlib.Order.ConditionallyCompleteLattice.Basic` |
| Closure operators | `Mathlib.Order.Closure` |

**Key theorems for E2**: `GaloisConnection.monotone_l`, `GaloisConnection.monotone_u`, `GaloisInsertion.strictMono_u`, `GaloisCoinsertion.strictMono_l`.

### 1.7 Finset / Fintype Infrastructure

| Item | Module Path |
|------|-------------|
| Finset | `Mathlib.Data.Finset.Basic` |
| Fintype | `Mathlib.Data.Fintype.Basic` |
| BigOperators `∑` | `Mathlib.Algebra.BigOperators` |
| Finset.sum | `Mathlib.Data.Finset.Sum` |

---

## 2. Projects Using Mathlib for Probability

### 2.1 Statistical Learning Theory (YuanheZ/lean-stat-learning-theory)

- **Paper**: arXiv:2602.02285 (Feb 2026)
- **Scale**: ~30,000 lines, 865 theorems, ~1,000 new lemmas
- **Built on Mathlib**: Core measure theory, topology, probability
- **Built from scratch**: Gaussian Lipschitz concentration, Dudley's entropy integral, empirical process theory, sub-Gaussian bounds
- **Method**: 500 hours human-AI collaboration (Claude Code)
- **Relevance to us**: Demonstrates that substantial probability formalization on top of Mathlib is feasible at month-scale

### 2.2 PFR Project (teorth/pfr)

- **Author**: Terence Tao et al.
- **Content**: Polynomial Freiman-Ruzsa conjecture proof
- **Shannon entropy**: Complete formalization for finite-valued random variables
- **Status**: Thousands of lines of entropy lemmas, probability kernel results, Ruzsa calculus being ported to Mathlib
- **Relevance to us**: Once merged, provides Shannon entropy `H(X)`, conditional entropy `H(X|Y)`, mutual information `I(X;Y)`, chain rules — directly useful for T3 derivation

### 2.3 SampCert (leanprover/SampCert)

- **Author**: Lean/AWS team
- **Content**: Verified differential privacy
- **Status**: Deployed in AWS Clean Rooms (production)
- **Mathlib usage**: Heavy — Fourier analysis, measure theory, probability, number theory, topology
- **Probability monad**: Custom simple probability monad for DP mechanisms
- **Relevance to us**: Pattern for building verified stochastic systems on Mathlib. Demonstrates lakefile integration at scale

### 2.4 VCVio (dtumad/VCV-io)

- **Content**: Verified cryptographic proofs
- **Probability monad**: `SPMF := OptionT PMF` (subdistributions via Mathlib's PMF)
- **Key pattern**: `evalDist` embeds computations into SPMF using uniform distributions
- **Nondeterminism**: Oracle-based nondeterminism with `OracleComp spec α`
- **Relevance to us**: **Directly relevant to T4**. Pattern for formalizing nondeterministic computation as probability distributions over outputs

### 2.5 Lean-QuantumInfo (Timeroot/Lean-QuantumInfo)

- **Content**: Quantum information theory — 13,992 lines, 1,059 theorems, 248 definitions
- **Goal**: Shannon/von Neumann entropy, relative entropy, channel capacity
- **Status**: Approaching proof of Generalized Quantum Stein's Lemma (Oct 2025)
- **Mathlib**: Heavy use; contributes snippets back upstream
- **Relevance to us**: Information-theoretic formalization patterns; entropy definitions over finite types

---

## 3. Axiom-by-Axiom Derivation Strategy with Mathlib

### 3.1 T4 (output_nondeterministic) — Probability Theory

**Current axiom**: `∃ agent action w w₁ w₂, canTransition agent action w w₁ ∧ canTransition agent action w w₂ ∧ w₁ ≠ w₂`

**Mathlib approach**: Model the transition as a probability distribution.
- Define `transitionDist : Agent → Action → World → PMF World` using `PMF.ofFintype`
- T4 becomes: "there exists a transition distribution whose support has cardinality > 1"
- `PMF.support_nonempty` ensures at least one outcome
- The nondeterminism follows from `|p.support| ≥ 2`

**Key Mathlib modules needed**:
- `Mathlib.Probability.ProbabilityMassFunction.Basic` (PMF, support)
- `Mathlib.Probability.ProbabilityMassFunction.Constructions` (ofFintype)
- `Mathlib.Data.Finset.Card` (cardinality)

**Gap**: Softmax is NOT in Mathlib. We would need to define:
```lean
def softmax (logits : Fin n → ℝ) : PMF (Fin n) :=
  PMF.ofFintype (fun i => exp (logits i) / ∑ j, exp (logits j)) (by ...)
```
The proof obligation `∑ i, exp (logits i) / ∑ j, exp (logits j) = 1` is straightforward with Mathlib's `exp` and `Finset.sum` infrastructure.

**VCVio pattern**: Use `SPMF := OptionT PMF` if we want to model failure/timeout.

### 3.2 T5 (no_improvement_without_feedback) — Control Theory

**Current axiom**: `∀ w w', structureImproved w w' → ∃ f, f ∈ w'.feedbacks ∧ ...`

**Mathlib approach**: No direct control theory in Mathlib. However, the mathematical essence is:
- Define a metric/observable on structures (using `Mathlib.Order.Monotone.Basic`)
- Feedback = information channel (Markov kernel from observation to structure)
- Improvement = decrease in distance to goal
- Without feedback kernel, the process is a martingale (no drift toward improvement)

**Key Mathlib modules needed**:
- `Mathlib.Probability.Martingale` — martingale theory, optional stopping theorem
- `Mathlib.Probability.Kernel.Defs` — Markov kernels for feedback channels
- `Mathlib.Order.Monotone.Basic` — monotone improvement functions

**Formalization idea**:
```lean
-- A process without feedback is a martingale (no expected improvement)
-- With feedback, it can be a supermartingale (expected improvement)
theorem no_improvement_without_feedback_from_martingale :
  ∀ (X : ℕ → Ω → ℝ) (μ : Measure Ω) [IsProbabilityMeasure μ],
    Martingale X (⊥ : Filtration ℕ (MeasurableSpace Ω)) μ →
    ¬ ∃ (n : ℕ), 0 < n ∧ μ[X n] < μ[X 0]
```
The trivial filtration `⊥` = no information = no feedback. Martingale property prevents systematic improvement.

**Gap**: Need to bridge "structural improvement" (domain concept) to "supermartingale convergence" (mathematical concept). This is a modeling gap, not a Mathlib gap.

### 3.3 T3 (context_contribution_nonuniform) — Information Theory

**Current axiom**: `∀ task, task.precisionRequired.required > 0 → ∃ item, precisionContribution item task = 0`

**Mathlib approach**: This is fundamentally an information-theoretic statement.
- Context items = random variables providing information about the task
- Precision contribution = mutual information `I(item; task_output)`
- T3 says: in any finite set of information sources, some have zero mutual information with the target

**Key Mathlib modules needed**:
- `Mathlib.Analysis.SpecialFunctions.BinaryEntropy` (entropy basics)
- PFR's Shannon entropy (when merged) for `H(X)`, `I(X;Y)`
- `Mathlib.Probability.Independence.Basic` — `IndepFun` for zero-MI items
- `Mathlib.Data.Fintype.Basic` — finite context sets

**Formalization idea**:
```lean
-- If item is independent of task_output, its mutual information is zero
-- IndepFun item task_output μ → I(item; task_output) = 0
-- By pigeonhole on finite context, not all can have nonzero MI
```

**Gap**: Shannon entropy / mutual information are NOT yet in Mathlib mainline. Options:
1. Wait for PFR merge (uncertain timeline)
2. Import teorth/pfr directly as a Lake dependency
3. Define minimal entropy/MI ourselves (feasible for finite types)

### 3.4 T1 (session_bounded / session_isolation) — Process Model

**Current axiom**: `session_bounded` (see Axioms.lean)

**Mathlib approach**: This is essentially a product measure / independence statement.
- Sessions = independent probability spaces
- No shared state = `IndepFun session₁ session₂ μ`
- Session isolation = product measure factorization

**Key Mathlib modules needed**:
- `Mathlib.Probability.Independence.Basic` — `IndepFun`, `iIndepFun`
- `Mathlib.Probability.ProductMeasure` — product measure construction
- `Mathlib.MeasureTheory.Measure.Prod` — product measure theory

**Formalization idea**:
```lean
-- Sessions are modeled as independent components of a product space
-- session_isolated ↔ joint measure = product of marginals
theorem session_isolation_from_independence :
  iIndepFun (fun i => session i) μ →
  ∀ i j, i ≠ j → ∀ (s : Set State) (t : Set State),
    μ (session i ⁻¹' s ∩ session j ⁻¹' t) = μ (session i ⁻¹' s) * μ (session j ⁻¹' t)
```

**Gap**: Minimal. Mathlib's independence infrastructure is comprehensive.

### 3.5 E1 (verification_requires_independence) — Statistical Testing Theory

**Current axiom**: `∀ gen ver action w, generates gen action w → verifies ver action w → gen.id ≠ ver.id ∧ ¬sharesInternalState gen ver`

**Mathlib approach**: Model as hypothesis testing with correlated vs independent verifiers.
- Shared internal state → correlated errors → reduced detection power
- Independent verifiers → Type I/II error rates multiply (improve)

**Key Mathlib modules needed**:
- `Mathlib.Probability.Independence.Basic` — `IndepFun` for independent verifiers
- `Mathlib.Probability.ConditionalProbability` — conditional detection rates
- `Mathlib.Probability.CondVar` — conditional variance

**Formalization idea**:
```lean
-- Detection power of correlated verifiers is bounded by individual power
-- Detection power of independent verifiers multiplies
-- If verifier shares bias with generator, P(detect | error) ≤ P(detect_indep | error)
theorem independence_improves_detection :
  ∀ (gen_bias ver_bias : Ω → Bool) (μ : Measure Ω) [IsProbabilityMeasure μ],
    IndepFun gen_bias ver_bias μ →
    μ[{ω | ver_bias ω = true} | {ω | gen_bias ω = true}] =
    μ {ω | ver_bias ω = true}
-- vs correlated case where conditional probability differs
```

**Gap**: Need to formalize "detection power" and "bias correlation". Mathlib has the probability tools; the modeling bridge is domain-specific.

### 3.6 E2 (capability_risk_coscaling) — Order Theory

**Current axiom**: `∀ agent w w', actionSpaceSize agent w < actionSpaceSize agent w' → riskExposure agent w < riskExposure agent w'`

**Mathlib approach**: This is a strict monotonicity statement. Model as:
- `actionSpaceSize` and `riskExposure` form a Galois connection or strictly monotone map
- E2 = `StrictMono riskOfCapability` where `riskOfCapability` maps action space size to risk

**Key Mathlib modules needed**:
- `Mathlib.Order.Monotone.Basic` — `StrictMono`, `Monotone`
- `Mathlib.Order.GaloisConnection.Defs` — if we want the adjoint structure
- `Mathlib.Order.Lattice` — if action spaces form a lattice

**Formalization idea**:
```lean
-- E2 is exactly StrictMono applied to the risk-capability function
-- If we define risk as a function of capability:
def riskOfCapability : ℕ → ℝ := sorry -- monotone by E2

-- Then E2 is: StrictMono riskOfCapability
-- Which Mathlib defines as: ∀ a b, a < b → f a < f b
```

**Gap**: Minimal. Mathlib's `StrictMono` is exactly our axiom's shape. The question is whether we want to DERIVE this from a richer model (e.g., prove that expanding an action space strictly increases the set of reachable bad states).

---

## 4. Integration Configuration

### 4.1 Lakefile Configuration

Current project uses `leanprover/lean4:v4.25.0`. Mathlib master is at `v4.29.0`.

To add Mathlib:
```toml
# lakefile.toml (recommended format)
[package]
name = "agent-manifest"

[[require]]
name = "mathlib"
scope = "leanprover-community"
```

Or in the existing `lakefile.lean`:
```lean
import Lake
open Lake DSL

package «agent-manifest» where
  leanOptions := #[]

require mathlib from git
  "https://github.com/leanprover-community/mathlib4" @ "master"

lean_lib «Manifest» where
  srcDir := "."
```

**Critical**: Must sync `lean-toolchain` to Mathlib's version:
```bash
curl https://raw.githubusercontent.com/leanprover-community/mathlib4/master/lean-toolchain -o lean-toolchain
```

### 4.2 Build Performance

- `lake exe cache get` downloads prebuilt Mathlib oleans (~3-5 GB)
- Without cache, full Mathlib build takes 1-4 hours
- Import specific modules (not `import Mathlib`) to limit compile scope:
  ```lean
  import Mathlib.Probability.ProbabilityMassFunction.Basic
  import Mathlib.Order.Monotone.Basic
  ```

### 4.3 Coexistence Strategy

- Existing 64 axioms + 359 theorems remain untouched
- New `Manifest/MathFoundations/` directory for Mathlib-dependent derivations
- Bridge theorems connect `MathFoundations` definitions to existing `Manifest` types
- Axioms become theorems in the `MathFoundations` layer; remain axioms in the `Manifest` layer for backward compatibility

---

## 5. Gap Analysis Summary

| Axiom | Mathlib Coverage | Gap | Effort Estimate |
|-------|-----------------|-----|-----------------|
| T4 (nondeterministic) | PMF, support, Fintype — **good** | Softmax definition (small) | Low |
| T5 (feedback) | Martingale, kernels — **partial** | Control-theory bridge to martingale theory | Medium |
| T3 (nonuniform) | Independence, binEntropy — **partial** | Shannon entropy / MI not in Mathlib yet | Medium-High |
| T1 (session isolation) | IndepFun, product measure — **good** | Minimal | Low |
| E1 (verification independence) | IndepFun, cond prob, Bayes — **good** | Detection power modeling | Medium |
| E2 (capability-risk) | StrictMono, Galois — **good** | Minimal (already the right shape) | Low |

### Critical Dependencies

1. **Shannon entropy**: The biggest gap. Options ranked by preference:
   - (a) Import `teorth/pfr` as a Lake dependency (immediate, battle-tested)
   - (b) Define minimal `H(X)` and `I(X;Y)` for `Fintype` ourselves (~200 lines)
   - (c) Wait for PFR → Mathlib merge (uncertain timeline)

2. **Softmax**: Must define ourselves. ~50 lines using `Mathlib.Analysis.SpecialFunctions.Log.Basic` and `Real.exp`.

3. **Lean toolchain upgrade**: `v4.25.0` → `v4.29.0` required. May cause breakage in existing 359 theorems.

---

## 6. Recommended Approach

### Phase 1: Low-Hanging Fruit (E2, T1, T4)
- Add Mathlib dependency
- Derive E2 using `StrictMono` (nearly trivial)
- Derive T1 using `iIndepFun` and product measures
- Derive T4 using `PMF` with custom softmax

### Phase 2: Independence-Based (E1)
- Model detection power using conditional probability
- Derive E1 from independence → uncorrelated detection

### Phase 3: Information Theory (T3, T5)
- Either import PFR or define minimal entropy
- Derive T3 from mutual information / independence
- Derive T5 from martingale theory (no-free-lunch argument)

---

## Sources

- [Mathlib PMF.Basic docs](https://leanprover-community.github.io/mathlib4_docs/Mathlib/Probability/ProbabilityMassFunction/Basic.html)
- [Mathlib PMF.Constructions docs](https://leanprover-community.github.io/mathlib4_docs/Mathlib/Probability/ProbabilityMassFunction/Constructions.html)
- [Mathlib Independence.Basic docs](https://leanprover-community.github.io/mathlib4_docs/Mathlib/Probability/Independence/Basic.html)
- [Mathlib ConditionalProbability docs](https://leanprover-community.github.io/mathlib4_docs/Mathlib/Probability/ConditionalProbability.html)
- [Mathlib Order.Monotone.Basic docs](https://leanprover-community.github.io/mathlib4_docs/Mathlib/Order/Monotone/Basic.html)
- [Mathlib Order.GaloisConnection.Defs docs](https://leanprover-community.github.io/mathlib4_docs/Mathlib/Order/GaloisConnection/Defs.html)
- [Mathlib BinaryEntropy docs](https://leanprover-community.github.io/mathlib4_docs/Mathlib/Analysis/SpecialFunctions/BinaryEntropy.html)
- [Mathlib Radon-Nikodym docs](https://leanprover-community.github.io/mathlib4_docs/Mathlib/MeasureTheory/Measure/Decomposition/RadonNikodym.html)
- [Mathlib ConditionalExpectation docs](https://leanprover-community.github.io/mathlib4_docs/Mathlib/MeasureTheory/Function/ConditionalExpectation/Basic.html)
- [Basic probability in Mathlib (blog)](https://leanprover-community.github.io/blog/posts/basic-probability-in-mathlib/)
- [Markov kernels in Mathlib (arXiv:2510.04070)](https://arxiv.org/html/2510.04070v1)
- [Mathematics in Mathlib overview](https://leanprover-community.github.io/mathlib-overview.html)
- [Statistical Learning Theory in Lean 4 (arXiv:2602.02285)](https://arxiv.org/abs/2602.02285)
- [lean-stat-learning-theory (GitHub)](https://github.com/YuanheZ/lean-stat-learning-theory)
- [PFR project (GitHub)](https://github.com/teorth/pfr)
- [PFR Blueprint](https://teorth.github.io/pfr/)
- [SampCert: Verified Differential Privacy (GitHub)](https://github.com/leanprover/SampCert)
- [VCVio: Formalized Cryptography (GitHub)](https://github.com/dtumad/VCV-io)
- [Lean-QuantumInfo (GitHub)](https://github.com/Timeroot/Lean-QuantumInfo)
- [Quantum Stein's Lemma formalization (arXiv:2510.08672)](https://arxiv.org/abs/2510.08672)
- [Using Mathlib4 as a dependency (wiki)](https://github.com/leanprover-community/mathlib4/wiki/Using-mathlib4-as-a-dependency)
- [Mathlib4 GitHub](https://github.com/leanprover-community/mathlib4)
- [Mathlib4 lean-toolchain](https://github.com/leanprover-community/mathlib4/blob/master/lean-toolchain)
