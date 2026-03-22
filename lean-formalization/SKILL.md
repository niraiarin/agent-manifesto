---
name: lean-manifest
description: >
  Design and write formal Manifest specifications for AI Agent Workflows using Lean 4.
  A Manifest is an axiomatic system that constrains AI agent behavior, ensures observability,
  and enables continuous verification. Use this skill whenever the user wants to:
  define formal constraints for AI agents, write verifiable requirements or design documents in Lean 4,
  create proof-carrying workflow specifications,
  design Worker AI / Verifier AI architectures with formal guarantees,
  or discuss formal methods for AI safety and agent orchestration.
  Also trigger when the user mentions "Manifest", "formal spec", "agent constraints",
  "proof-carrying workflow", "Lean 4 requirements",
  or any combination of formal verification and AI agent design.
  Note: Verso dependency was removed in Phase 5 due to markdown parser incompatibilities.
---

# Lean Manifest Skill

This skill guides you in designing and writing **Manifest** documents — formally verified axiomatic specifications for AI Agent Workflows, authored in Lean 4 and rendered via Verso.

## What is a Manifest?

A Manifest is a formal specification that defines:
- What an AI agent **may** do (permissions, scope)
- What an AI agent **must not** do (safety axioms)
- What properties **must hold** at every step (invariants)
- What can be **observed and verified** at runtime (observability)
- How the specification **evolves** over time (versioning, compatibility)

The key insight: **the Manifest is written in Lean 4**, so its internal consistency is machine-checked. The document is authored as a **Verso literate program**, so it is simultaneously a human-readable design document and a type-checked formal specification.

---

## Architecture Overview

### Multi-Agent Verification Architecture

The Manifest sits at the center of a three-actor system:

```
Meta-Lean Layer
  Proves Manifest validity (consistency, feasibility)
         │
         ▼
    Manifest (Lean 4 + Verso)
    Axioms + Type constraints + Invariants
    Continuously versioned and evolved
         │                    │
         │ structural         │ verification
         │ constraints        │ rules
         ▼                    ▼
    Worker AI             Verifier AI
    Output must be        Validates Worker output
    structurally typed.   against Manifest axioms.
    Non-structural        Independent from Worker.
    output → reject.      No shared state.
```

### Design Principles

1. **Trust is grounded in proof, not inference.** Worker AI output is not trusted by default. Structural validity is enforced by types; semantic validity is checked by an independent Verifier AI.
2. **Change is managed by types, not feared.** The Manifest evolves. Each change is classified (conservative, compatible, breaking), its impact is enumerated, and compatibility is proved.
3. **Unobservable properties are verified statically; observable properties are verified dynamically.** Structural guarantees (independence, consistency) are proved at compile time. Content-level properties (output correctness) are checked at runtime by the Verifier AI.

---

## The Three Layers of a Manifest

### Layer 1: Ontology — World Model

Defines the types the Manifest reasons about. For common patterns across domains, see `references/ontology-patterns.md`.

```lean
structure World where
  resources : List Resource
  permissions : Resource → Agent → AccessLevel
  state : SystemState
  time : Nat

structure Agent where
  id : AgentId
  capabilities : List Capability
  scope : Scope
```

### Layer 2: Axioms — Safety Constraints

Defines invariants that must always hold. For a catalog of reusable axioms, see `references/axiom-catalog.md`.

```lean
axiom no_escalation :
  ∀ (a : Agent) (action : Action) (w w' : World),
    execute a action w = some w' →
    a.scope.contains action.target

axiom reversibility :
  ∀ (a : Agent) (action : Action) (w : World),
    action.severity ≥ Severity.high →
    ∃ rollback : Action, execute a rollback (execute a action w) = some w
```

### Layer 3: Workflow Rules — Transition Correctness

Defines how workflow steps compose and that each step preserves axioms.

```lean
structure Step where
  precondition : World → Prop
  action : Agent → World → Option World
  postcondition : World → Prop

def Workflow.sound (steps : List Step) : Prop :=
  ∀ (i : Fin (steps.length - 1)),
    ∀ w, steps[i].postcondition w → steps[i+1].precondition w
```

---

## Observability

Observability bridges static proof and runtime verification. A property is Observable if a decision procedure exists:

```lean
def Observable (P : World → Prop) : Prop :=
  ∃ f : World → Bool, ∀ w, f w = true ↔ P w

class ObservableManifest (M : Manifest) where
  all_observable : ∀ (ax : M.runtimeAxioms), Observable ax.property
```

| Observability   | Verified when  | Example                        |
|-----------------|---------------|--------------------------------|
| `full`          | Runtime       | Scope check before tool call   |
| `partial`       | Runtime+Static| Rollback existence (static) + correctness (runtime) |
| `static_only`   | Compile time  | Manifest consistency           |

---

## Meta-Theorems

Meta-theorems prove properties of the Manifest itself. The `sorry` count is a direct metric of design completeness.

```lean
def Consistent (m : Manifest) : Prop :=
  ¬∃ (p : Prop), m.proves p ∧ m.proves (¬p)

def Feasible (m : Manifest) : Prop :=
  ∃ (w : Workflow), m.permits w ∧ w.isUseful

def IndependenceGuarantee (arch : Architecture) : Prop :=
  ∀ (w : WorkerAI) (v : VerifierAI),
    ¬∃ (channel : SharedState), w.canAccess channel ∧ v.canAccess channel

theorem system_sound (m : Manifest) (arch : Architecture) :
    Consistent m → Feasible m →
    IndependenceGuarantee arch →
    VerificationCompleteness m arch.verifierSpec →
    SystemIsSafe arch m := by
  sorry  -- Completing this proof IS the design work
```

---

## Manifest Evolution

Changes are classified and their impact is proved. This connects to P3 (Governed Learning) and its integration compatibility classification.

```lean
def ConservativeExtension (old new : Manifest) : Prop :=
  ∀ (p : Prop), old.proves p → new.proves p

def BackwardCompatible (old new : Manifest) : Prop :=
  ∀ (w : Workflow), old.permits w → new.permits w

structure BreakingChange where
  from : Manifest
  to : Manifest
  brokenWorkflows : List Workflow
  migrationPath : Workflow → Option Workflow
  proof_complete : ∀ w, from.permits w → ¬to.permits w → w ∈ brokenWorkflows
```

---

## Worker AI / Verifier AI Protocol

### Two-stage rejection

**Stage 1 — Structural (deterministic).** Worker output must parse into a typed `StructuredOutput`. If not, it is rejected immediately with no LLM involvement.

```lean
inductive StructuredOutput where
  | toolCall : ToolName → ValidatedArgs → StructuredOutput
  | response : ResponseSchema → StructuredOutput
  | delegation : AgentId → Task → StructuredOutput
```

**Stage 2 — Semantic (Verifier AI).** Structurally valid output is checked against Manifest axioms by an independent Verifier with no shared state with the Worker.

```lean
structure VerifierConfig where
  manifest : Manifest
  workerStateAccess : Empty  -- Cannot access Worker internals
```

---

## Axiom Metadata

Every axiom should carry structured metadata for traceability and extraction:

```lean
structure AxiomMeta where
  introducedIn : String
  lastModified : String
  observability : Observability  -- full | partial | static_only
  scope : List String
  breakingLevel : BreakingLevel
  relatedAxioms : List String := []

inductive DesignStatus where
  | draft | review | approved | deprecated
```

The same `.lean` source generates three views: human-readable HTML (via Verso), Worker AI constraints (JSON), and Verifier AI rules (structured text). See `references/extraction.md` for implementation details.

---

## Verso Integration

Manifest documents are authored as Verso literate programs — `.lean` files that mix code with prose using `/-! ... -/` delimiters. All code is type-checked as part of `lake build`.

For project setup, build pipeline, and genre extensions, see `references/verso-setup.md`.

---

## Checklist for Writing a Manifest

1. **Ontology completeness**: Are all relevant domain types defined?
2. **Axiom coverage**: Is every safety-critical behavior constrained by at least one axiom?
3. **Observability classification**: Does every axiom have an explicit observability level? Are all `full` axioms accompanied by a decision procedure?
4. **Meta-theorem status**: Is the Manifest proved consistent? Is at least one useful workflow feasible?
5. **Evolution readiness**: Are changes from the previous version classified and compatibility proved?
6. **Sorry inventory**: Are all remaining `sorry` tracked and prioritized?
7. **Three-audience extraction**: Can Worker constraints and Verifier rules be extracted from this source?

---

## Reference: Key Concepts

| Concept | Definition |
|---------|-----------|
| Manifest | Axiomatic specification for AI agent behavior, written in Lean 4 |
| Axiom | A property that must always hold; machine-checked by Lean |
| Observable | A property for which a runtime decision procedure exists |
| Worker AI | The AI that performs tasks; constrained to produce typed output |
| Verifier AI | Independent AI that checks Worker output against Manifest axioms |
| sorry | Lean placeholder for an incomplete proof; counts as design debt |
| Conservative Extension | Manifest change that preserves all existing theorems |
| Breaking Change | Manifest change that invalidates some existing workflows |
| Verso | Lean's documentation tool; Manifest documents are Verso literate programs |

---

## Reference: File Descriptions

Read these files for more detail on specific topics:

- `references/ontology-patterns.md` — Common patterns for World, Agent, Action types across domains
- `references/axiom-catalog.md` — Catalog of reusable safety axioms (scope, reversibility, rate limiting, data isolation, audit)
- `references/verso-setup.md` — Verso project setup, build pipeline, genre extensions, CI integration
- `references/extraction.md` — Worker/Verifier extraction executables using Lean metaprogramming
