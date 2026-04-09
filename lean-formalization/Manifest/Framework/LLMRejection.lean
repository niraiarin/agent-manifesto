import Manifest.Framework.DanglingDetection

/-!
# Worker/Verifier Separation Architecture — Soundness

Issue #300 (G3 of #296): Formalize the Worker/Verifier separation architecture.

## Architecture

- **Worker** (LLM inference): generates candidates. No correctness guarantee.
- **Verifier** (independent check, P2): accepts or rejects candidates.
- **Soundness**: Verifier PASS implies specification conformance.

This models the core P2 (Cognitive Separation of Concerns) principle:
the entity that generates a candidate must not be the one that verifies it (E1).

## Connection to G2 (Dangling Detection)

Dangling dependencies (detected by G2) represent "known unknowns" — nodes
whose dependencies reference non-existent graph entries. These are natural
triggers for Worker candidate generation: the Worker proposes a resolution,
and the Verifier checks it against the specification.

## Epistemic Source Mapping

- `CandidateSource.human` → EpistemicSource.humanDecision (T6 authority)
- `CandidateSource.llm` → EpistemicSource.llmInference (needs verification)
-/

namespace Manifest.Framework

open Manifest

-- ============================================================
-- Core Types
-- ============================================================

/-- A specification that candidates must satisfy.
    Wraps a predicate over the candidate type. -/
structure Spec (α : Type) where
  satisfies : α → Prop

/-- Origin of a candidate: human decision or LLM inference.
    Maps to EpistemicSource (Models/Assumptions/EpistemicLayer.lean). -/
inductive CandidateSource where
  /-- Human-originated. Accepted under T6 authority. -/
  | human
  /-- LLM-generated. Requires independent verification (P2). -/
  | llm
  deriving BEq, Repr, DecidableEq

/-- A candidate value tagged with its epistemic source. -/
structure Candidate (α : Type) where
  value : α
  source : CandidateSource
  deriving Repr

/-- Result of verification: pass or reject with reason. -/
inductive VerificationResult where
  | pass
  | reject (reason : String)
  deriving Repr

-- ============================================================
-- Worker/Verifier Architecture
-- ============================================================

/-- The Worker/Verifier separation architecture.
    Worker generates candidates (no correctness guarantee).
    Verifier independently checks candidates against the spec.
    Soundness: verify pass implies spec satisfaction. -/
structure WorkerVerifier (α : Type) where
  spec : Spec α
  verify : Candidate α → VerificationResult
  /-- Core soundness property: verification pass implies specification conformance. -/
  soundness : ∀ c : Candidate α, verify c = .pass → spec.satisfies c.value

-- ============================================================
-- Candidate Construction Helpers
-- ============================================================

/-- Create a human-sourced candidate. -/
def Candidate.fromHuman (v : α) : Candidate α :=
  { value := v, source := .human }

/-- Create an LLM-sourced candidate. -/
def Candidate.fromLLM (v : α) : Candidate α :=
  { value := v, source := .llm }

/-- Predicate: candidate requires verification (LLM-sourced). -/
def Candidate.needsVerification (c : Candidate α) : Bool :=
  c.source == .llm

-- ============================================================
-- Theorem 1: Source-independent soundness
-- ============================================================

/-- Soundness holds regardless of candidate source.
    Whether a candidate is human-sourced or LLM-sourced,
    if the verifier passes it, the spec is satisfied. -/
theorem soundness_source_independent (wv : WorkerVerifier α)
    (v : α) (s : CandidateSource)
    (h : wv.verify { value := v, source := s } = .pass) :
    wv.spec.satisfies v := by
  exact wv.soundness { value := v, source := s } h

-- ============================================================
-- Theorem 2: Rejected candidates are excluded
-- ============================================================

/-- A rejected candidate does not receive a soundness guarantee.
    This is a logical tautology (rejection ≠ pass), but makes explicit
    that the architecture provides no guarantee for rejected candidates. -/
theorem rejection_excludes (wv : WorkerVerifier α)
    (c : Candidate α) (reason : String)
    (h : wv.verify c = .reject reason) :
    wv.verify c ≠ .pass := by
  rw [h]; intro h'; exact VerificationResult.noConfusion h'

-- ============================================================
-- Theorem 3: Human candidates and soundness
-- ============================================================

/-- Human-sourced candidates that pass verification satisfy the spec.
    Even though T6 grants humans authority, verification still applies. -/
theorem human_pass_satisfies (wv : WorkerVerifier α) (v : α)
    (h : wv.verify (Candidate.fromHuman v) = .pass) :
    wv.spec.satisfies v := by
  exact wv.soundness (Candidate.fromHuman v) h

/-- LLM-sourced candidates that pass verification satisfy the spec.
    This is the primary use case: Worker generates, Verifier validates. -/
theorem llm_pass_satisfies (wv : WorkerVerifier α) (v : α)
    (h : wv.verify (Candidate.fromLLM v) = .pass) :
    wv.spec.satisfies v := by
  exact wv.soundness (Candidate.fromLLM v) h

-- ============================================================
-- Theorem 4: Composition of WorkerVerifiers
-- ============================================================

/-- Compose two specs into a conjunction spec. -/
def Spec.conj (s1 s2 : Spec α) : Spec α :=
  { satisfies := fun v => s1.satisfies v ∧ s2.satisfies v }

/-- A verifier for the conjunction of two specs.
    Both individual verifiers must pass. -/
def WorkerVerifier.compose (wv1 wv2 : WorkerVerifier α) : WorkerVerifier α :=
  { spec := wv1.spec.conj wv2.spec
    verify := fun c =>
      match wv1.verify c, wv2.verify c with
      | .pass, .pass => .pass
      | .reject r, _ => .reject r
      | _, .reject r => .reject r
    soundness := by
      intro c h
      -- h says the composed verify returned pass
      -- This means both wv1.verify and wv2.verify returned pass
      simp [Spec.conj]
      constructor
      · -- wv1 soundness
        have : wv1.verify c = .pass := by
          revert h; cases h1 : wv1.verify c <;> cases h2 : wv2.verify c <;> simp_all
        exact wv1.soundness c this
      · -- wv2 soundness
        have : wv2.verify c = .pass := by
          revert h; cases h1 : wv1.verify c <;> cases h2 : wv2.verify c <;> simp_all
        exact wv2.soundness c this }

/-- Composed verification pass implies both individual specs are satisfied. -/
theorem compose_soundness (wv1 wv2 : WorkerVerifier α)
    (c : Candidate α)
    (h : (wv1.compose wv2).verify c = .pass) :
    wv1.spec.satisfies c.value ∧ wv2.spec.satisfies c.value := by
  exact (wv1.compose wv2).soundness c h

-- ============================================================
-- Theorem 5: Connection to Dangling Detection (G2)
-- ============================================================

/-- A dangling dependency is a natural trigger for candidate generation.
    When a graph has dangling deps, the Worker should generate candidates
    to resolve them. This type captures that workflow. -/
structure DanglingResolution (α : Type) [BEq α] where
  /-- The graph with dangling dependencies. -/
  graph : AcyclicGraph α
  /-- The dangling (node, dep) pairs to resolve. -/
  danglingPairs : List (α × α)
  /-- Each pair in danglingPairs is actually dangling. -/
  pairs_are_dangling : danglingPairs = graph.danglingDeps

/-- A resolution candidate for a single dangling dependency.
    The candidate proposes a new node to fill the missing dependency. -/
structure ResolutionCandidate (α : Type) where
  /-- The missing dependency id being resolved. -/
  missingId : α
  /-- The proposed node to add. -/
  proposed : Node α
  /-- The proposed node's id matches the missing dependency. -/
  id_matches : proposed.id = missingId

/-- Spec for resolution candidates: the proposed node must have the correct id. -/
def resolutionSpec (α : Type) [BEq α] [DecidableEq α] (missingId : α) : Spec (ResolutionCandidate α) :=
  { satisfies := fun rc => rc.proposed.id = missingId }

/-- If a resolution candidate passes verification against the resolution spec,
    its proposed node id matches the missing dependency. -/
theorem resolution_soundness [BEq α] [DecidableEq α]
    (missingId : α)
    (wv : WorkerVerifier (ResolutionCandidate α))
    (hwv : wv.spec = resolutionSpec α missingId)
    (c : Candidate (ResolutionCandidate α))
    (h : wv.verify c = .pass) :
    c.value.proposed.id = missingId := by
  have hs := wv.soundness c h
  rw [hwv] at hs
  exact hs

-- ============================================================
-- Theorem 6: Monotonicity — adding verified candidates preserves existing soundness
-- ============================================================

/-- A spec that is trivially satisfied by all values. -/
def Spec.trivial (α : Type) : Spec α :=
  { satisfies := fun _ => True }

/-- The trivial spec is satisfied by any value. -/
theorem trivial_satisfied (v : α) : (Spec.trivial α).satisfies v :=
  trivial

/-- Strengthening: if a candidate satisfies a stronger spec,
    it satisfies any weaker spec. -/
theorem spec_weakening {α : Type}
    (strong weak : Spec α)
    (h_weaker : ∀ v, strong.satisfies v → weak.satisfies v)
    (v : α) (h : strong.satisfies v) :
    weak.satisfies v := by
  exact h_weaker v h

/-- A WorkerVerifier can be weakened to a less demanding spec
    while preserving soundness. -/
def WorkerVerifier.weaken (wv : WorkerVerifier α) (weak : Spec α)
    (h_weaker : ∀ v, wv.spec.satisfies v → weak.satisfies v) : WorkerVerifier α :=
  { spec := weak
    verify := wv.verify
    soundness := fun c hpass => h_weaker c.value (wv.soundness c hpass) }

/-- Weakening preserves the verification function. -/
theorem weaken_preserves_verify (wv : WorkerVerifier α) (weak : Spec α)
    (h : ∀ v, wv.spec.satisfies v → weak.satisfies v)
    (c : Candidate α) :
    (wv.weaken weak h).verify c = wv.verify c := by
  rfl

-- ============================================================
-- Theorem 7: CandidateSource classification is decidable and exhaustive
-- ============================================================

/-- Every candidate is either human-sourced or LLM-sourced (exhaustive). -/
theorem source_exhaustive (s : CandidateSource) :
    s = .human ∨ s = .llm := by
  cases s
  · left; rfl
  · right; rfl

/-- BEq on CandidateSource agrees with DecidableEq. -/
private theorem CandidateSource.beq_eq_decide (a b : CandidateSource) :
    (a == b) = decide (a = b) := by
  cases a <;> cases b <;> rfl

/-- needsVerification correctly classifies LLM candidates. -/
theorem needs_verification_iff_llm (c : Candidate α) :
    c.needsVerification = true ↔ c.source = .llm := by
  constructor
  · intro h
    simp [Candidate.needsVerification, CandidateSource.beq_eq_decide] at h
    exact h
  · intro h
    simp [Candidate.needsVerification, CandidateSource.beq_eq_decide, h]

-- ============================================================
-- NodeKind integration: assumption nodes are verification targets
-- ============================================================

/-- Assumption nodes in a graph are natural targets for Worker/Verifier.
    They represent uncertain premises that need evidence.
    After invalidation (AcyclicGraph.invalidate), affected nodes become
    assumptions — creating demand for Worker candidates. -/
theorem invalidated_nodes_need_verification [BEq α] [DecidableEq α]
    (g : AcyclicGraph α) (id : α)
    (n : Node α) (_hn : n ∈ g.invalidate id)
    (hk : n.kind = .assumption) :
    NodeKind.minCompatibility n.kind = .compatibleChange := by
  rw [hk]; rfl

/-- The number of assumption nodes after invalidation is bounded by graph size. -/
theorem invalidation_assumption_bound [BEq α] [DecidableEq α]
    (g : AcyclicGraph α) (id : α) :
    (g.invalidate id).length = g.nodes.length := by
  exact invalidate_preserves_length g id

end Manifest.Framework
