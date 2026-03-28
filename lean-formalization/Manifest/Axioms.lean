import Manifest.Ontology

/-!
# Epistemic Layer - Constraint Strength 5 - T1-T8 Base Theory T0

The manifesto's binding conditions are formalized as Lean non-logical axioms
(Terminology Reference §4.1).

## Position as T0
Procedure 2.4.

T1–T8 are "undeniable, technology-independent facts" that constitute
the base theory T₀ (the set of axioms that do not shrink under revision loops).
Basis for T₀ membership:
- T1–T3, T7: Environment-derived (hardware constraints, physical limits of computational resources)
- T4: Natural-science-derived (nondeterminism inherent in the generation process)
- T5: Natural-science-derived (fundamental principle of control theory)
- T6: Contract-derived (authority structure based on agreement with humans)
- T8: Contract-derived (structural requirements of task definitions)

By declaring them as Lean `axiom`s, they are incorporated into the type system
as propositions assumed without proof (Terminology Reference §4.1, non-logical axioms).

## Design Policy

Each T **may be decomposed into multiple axioms**. A natural-language T1 does not
necessarily correspond to a single proposition; finer decompositions arise during
formalization. Each axiom's docstring follows the Axiom Card format (Procedure §2.5).

## Encoding Method for T0

T1–T8 contain properties that cannot be expressed by type definitions alone
(existential quantification, causal relations, etc.), so they are declared as
axioms (Axiom Card required). Parts expressible via type definitions are placed
in Ontology.lean as definitional extensions (Terminology Reference §5.5).

## Correspondence Table

| axiom name | Corresponding T | Property expressed | T₀ membership basis |
|-----------|-----------|-------------|------------|
| `session_bounded` | T1 | Sessions terminate in finite time | Environment-derived |
| `no_cross_session_memory` | T1 | No state sharing across sessions | Environment-derived |
| `session_no_shared_state` | T1 | No mutable state sharing across sessions | Environment-derived |
| `structure_persists` | T2 | Structure persists after session termination | Environment-derived |
| `structure_accumulates` | T2 | Improvements accumulate in structure | Environment-derived |
| `context_finite` | T3 | Working memory (processable information) is finite | Environment-derived |
| `context_bounds_action` | T3 | Processing is possible only within context capacity | Environment-derived |
| `output_nondeterministic` | T4 | Different outputs possible for the same input | Natural-science-derived |
| `no_improvement_without_feedback` | T5 | No improvement without feedback loop | Natural-science-derived |
| `human_resource_authority` | T6 | Humans are the final decision-makers for resources | Contract-derived |
| `resource_revocable` | T6 | Humans can revoke resources | Contract-derived |
| `resource_finite` | T7 | Resources are finite | Environment-derived |
| `task_has_precision` | T8 | Tasks have a precision level | Contract-derived |

## Correspondence with Terminology Reference

- Axiom → Non-logical axiom (§4.1): A proposition assumed true without proof, specific to a given theory
- T₀ → Base theory: A set of non-logical axioms grounded in external authority (Procedure §2.4)
- Axiom decomposition → Not definitional extension (§5.5), but refinement of the same concept
-/

namespace Manifest

-- ============================================================
-- T1: エージェントセッションは一時的である
-- ============================================================

/-!
## T1 Agent Sessions Are Ephemeral

"There is no memory across sessions. There is no continuous 'self.'
  Each instance is an independent entity with no identity
  shared with previous instances."

T1 is decomposed into three axioms:
1. Sessions terminate in finite time (boundedness)
2. There is no means to share state across sessions (discontinuity of memory)
3. No mutable state is shared across different sessions (independence)
-/

/-- [Axiom Card]
    Layer: T₀ (Environment-derived)
    Content: Sessions terminate in finite time.
          For all sessions, they become terminated at some point.
    Basis: Execution of computational agents consumes finite resources and therefore terminates in finite time (related to T7).
          Reference examples: LLM session timeouts, resource consumption limits.
    Source: manifesto.md T1 "There is no memory across sessions"
    Refutation condition: Not applicable (T₀) -/
axiom session_bounded :
  ∀ (w : World) (s : Session),
    s ∈ w.sessions →
    ∃ (w' : World), w.time ≤ w'.time ∧
      ∃ (s' : Session), s' ∈ w'.sessions ∧
        s'.id = s.id ∧ s'.status = SessionStatus.terminated

/-- [Axiom Card]
    Layer: T₀ (Environment-derived)
    Content: No state sharing across sessions.
          Between two sessions with different session IDs,
          actions in one cannot affect the observable state of the other.
    Basis: Ephemeral computational processes lose internal state upon process termination.
          State isolation across sessions is guaranteed at the execution environment level.
          Reference example: session isolation in LLM architectures.
    Source: manifesto.md T1 "There is no continuous 'self'"
    Refutation condition: Not applicable (T₀) -/
axiom no_cross_session_memory :
  ∀ (w : World) (e1 e2 : AuditEntry),
    e1 ∈ w.auditLog → e2 ∈ w.auditLog →
    e1.session ≠ e2.session →
    -- 異なるセッションの監査エントリは因果的に独立
    -- （一方の preHash が他方の postHash に依存しない）
    e1.preHash ≠ e2.postHash

/-- [Axiom Card]
    Layer: T₀ (Environment-derived)
    Content: No mutable state sharing across different sessions.
          Even with the same AgentId, instances in different sessions
          do not directly share state. Influence propagates only indirectly through structure (T2).
    Basis: Causal independence across sessions. Each instance is an independent entity.
    Source: manifesto.md T1 "Each instance is an independent entity"
    Refutation condition: Not applicable (T₀) -/
axiom session_no_shared_state :
  ∀ (agent1 agent2 : Agent) (action1 action2 : Action)
    (w w' : World),
    action1.session ≠ action2.session →
    canTransition agent1 action1 w w' →
    -- action2 が w で可能なら、w' でも可能（セッション1の遷移が
    -- セッション2のアクション可否に直接影響しない）
    (∃ w'', canTransition agent2 action2 w w'') →
    (∃ w''', canTransition agent2 action2 w' w''')

-- ============================================================
-- T2: 構造はエージェントより長く生きる
-- ============================================================

/-!
## T2 Structure Outlives the Agent

"Documents, tests, skill definitions, design conventions —
  these persist even after the session ends.
  The place where improvements accumulate is within structure."

T2 is decomposed into two axioms:
1. Structure persists after session termination (persistence)
2. Structure can accumulate improvements (accumulability)
-/

/-- [Axiom Card]
    Layer: T₀ (Environment-derived)
    Content: Structure persists after session termination.
          Even when a session becomes terminated,
          structures referenced by that session do not disappear from the World.
    Basis: Persistence on the file system. Structures (documents, tests, etc.)
          reside in storage outside the session.
    Source: manifesto.md T2 "The place where improvements accumulate is within structure"
    Refutation condition: Not applicable (T₀) -/
axiom structure_persists :
  ∀ (w w' : World) (s : Session) (st : Structure),
    s ∈ w.sessions →
    st ∈ w.structures →
    s.status = SessionStatus.terminated →
    validTransition w w' →
    st ∈ w'.structures

/-- [Axiom Card]
    Layer: T₀ (Environment-derived)
    Content: Structure accumulates improvements.
          As epochs advance, structures may be updated (lastModifiedAt is non-decreasing).
          Contrast with T1: agents are ephemeral, but structure grows.
    Basis: Monotonic epoch increase guaranteed by version control systems (git).
    Source: manifesto.md T2 "Structure outlives the agent"
    Refutation condition: Not applicable (T₀) -/
axiom structure_accumulates :
  ∀ (w w' : World),
    validTransition w w' →
    w.epoch ≤ w'.epoch

-- ============================================================
-- T3: 一度に処理できる情報量は有限である
-- ============================================================

/-!
## T3 The Amount of Information Processable at Once Is Finite

"There is a physical upper limit on the amount of information processable at once.
  A constraint on the agent's cognitive space."

T3 is decomposed into two axioms:
1. Working memory (ContextWindow) capacity is finite (existence)
2. Processing is possible only within working memory capacity (constraint)
-/

/-- [Axiom Card]
    Layer: T₀ (Environment-derived)
    Content: Working memory (ContextWindow) has finite capacity.
          The contextWindow.capacity of all agents is bounded.
    Basis: The working memory of computational agents is physically finite.
          Reference examples: LLM token count limits, FSM state buffer sizes.
    Source: manifesto.md T3 "There is a physical upper limit on the amount of information processable at once"
    Refutation condition: Not applicable (T₀) -/
axiom context_finite :
  ∀ (agent : Agent),
    agent.contextWindow.capacity > 0 ∧
    agent.contextWindow.used ≤ agent.contextWindow.capacity

/-- [Axiom Card]
    Layer: T₀ (Environment-derived)
    Content: Executing an action requires information processing within the context.
          When context usage exceeds capacity, the action cannot be executed.
    Basis: Inability to process when working memory is exceeded is a physical constraint.
    Source: manifesto.md T3 "A constraint on the agent's cognitive space"
    Refutation condition: Not applicable (T₀) -/
axiom context_bounds_action :
  ∀ (agent : Agent) (action : Action) (w : World),
    agent.contextWindow.used > agent.contextWindow.capacity →
    actionBlocked agent action w

-- ============================================================
-- T4: エージェントの出力は確率的である
-- ============================================================

/-!
## T4 Agent Output Is Stochastic

"Different outputs may be produced for the same input.
  Structure is interpreted probabilistically each time.
  Designs that assume 100% compliance are fragile."

Since `canTransition` is defined as a relation rather than a function (see Ontology.lean),
multiple w' can satisfy canTransition for the same (agent, action, w).
T4 declares as an axiom that "this multiplicity can actually occur."
-/

/-- [Axiom Card]
    Layer: T₀ (Natural-science-derived)
    Content: Nondeterminism of output. For the same agent, action, and world state,
          different transition targets may exist.
    Basis: Nondeterminism inherent in the agent's generation process. Multiple sources —
          sampling (temperature parameter), non-associativity of floating-point arithmetic,
          irreversibility of branching in autoregressive generation — enable different outputs
          for the same input. Even at temperature=0, floating-point-level nondeterminism may persist.
    Source: manifesto.md T4 "Different outputs may be produced for the same input"

    Since `canTransition` is defined as a relation (Prop),
    it is not constrained by Lean's function determinism and can naturally express nondeterminism.
    Refutation condition: Not applicable (T₀) -/
axiom output_nondeterministic :
  ∃ (agent : Agent) (action : Action) (w w₁ w₂ : World),
    canTransition agent action w w₁ ∧
    canTransition agent action w w₂ ∧
    w₁ ≠ w₂

-- ============================================================
-- T5: フィードバックなしに改善は不可能である
-- ============================================================

/-!
## T5 Improvement Is Impossible Without Feedback

"A fundamental of control theory.
  Without a loop of measurement, comparison, and adjustment,
  convergence toward the goal does not occur."

T5 declares that the existence of feedback is a necessary condition for improvement.
-/

/-- Predicate for whether structure has improved (defined as Observable in Phase 4+). -/
opaque structureImproved : World → World → Prop

/-- [Axiom Card]
    Layer: T₀ (Natural-science-derived)
    Content: Feedback is required for structural improvement.
          If structure has improved between two world states,
          then feedback exists in between.
    Basis: Fundamental principle of control theory. Without a loop of
          measurement, comparison, and adjustment, convergence toward the goal does not occur.
    Source: manifesto.md T5 "A fundamental of control theory"
    Refutation condition: Not applicable (T₀) -/
axiom no_improvement_without_feedback :
  ∀ (w w' : World),
    structureImproved w w' →
    ∃ (f : Feedback), f ∈ w'.feedbacks ∧
      f.timestamp ≥ w.time ∧ f.timestamp ≤ w'.time

-- ============================================================
-- T6: 人間はリソースの最終決定者である
-- ============================================================

/-!
## T6 Humans Are the Final Decision-Makers for Resources

"Computational resources, data access, execution privileges —
  all are granted by humans and can be revoked by humans."

T6 is decomposed into two axioms:
1. The origin of resource allocation is human (authority)
2. Humans can revoke resources (reversibility)
-/

/-- Predicate for whether an agent is human. -/
def isHuman (agent : Agent) : Prop :=
  agent.role = AgentRole.human

/-- [Axiom Card]
    Layer: T₀ (Contract-derived)
    Content: The origin of resource allocation is human.
          The grantedBy of all resource allocations holds a human role.
    Basis: Agreement on authority structure in human-agent collaboration.
    Source: manifesto.md T6 "Computational resources, data access, execution privileges — all are granted by humans"
    Refutation condition: Not applicable (T₀) -/
axiom human_resource_authority :
  ∀ (w : World) (alloc : ResourceAllocation),
    alloc ∈ w.allocations →
    ∃ (human : Agent), isHuman human ∧ human.id = alloc.grantedBy

/-- [Axiom Card]
    Layer: T₀ (Contract-derived)
    Content: Humans can revoke resources.
          For any resource allocation, there exists a transition in which a human invalidates it.
    Basis: Agreement on human final decision-making authority. Privileges can be delegated but remain revocable.
    Source: manifesto.md T6 "can be revoked by humans"
    Refutation condition: Not applicable (T₀) -/
axiom resource_revocable :
  ∀ (w : World) (alloc : ResourceAllocation),
    alloc ∈ w.allocations →
    ∃ (w' : World) (human : Agent),
      isHuman human ∧
      validTransition w w' ∧
      alloc ∉ w'.allocations

-- ============================================================
-- T7: タスク遂行に利用可能なリソースは有限である
-- ============================================================

/-!
## T7 Resources Available for Task Execution Are Finite
Time and energy.

"Whereas T3 states the finiteness of cognitive space (context),
  T7 states the finiteness in the temporal and energetic dimensions."
-/

/-- [Axiom Card]
    Layer: T₀ (Environment-derived)
    Content: Resources are finite.
          The total resource amount across the entire World does not exceed `globalResourceBound`.
          Quantified in ∃-∀ order (not ∀-∃), guaranteeing that a single upper bound
          exists for **all** Worlds (non-vacuity, Terminology Reference §6.4).
    Basis: Physical finiteness of computational resources (CPU, memory, API quotas).
    Source: manifesto.md T7 "Resources available for task execution are finite"
    Refutation condition: Not applicable (T₀) -/
axiom resource_finite :
  ∀ (w : World),
    (w.allocations.map (·.amount)).foldl (· + ·) 0 ≤ globalResourceBound

-- ============================================================
-- T8: タスクには達成すべき精度水準が存在する
-- ============================================================

/-!
## T8 Tasks Have a Precision Level to Be Achieved

"Whether self-imposed or externally imposed,
  tasks without a precision level cannot be optimization targets."
-/

/-- [Axiom Card]
    Layer: T₀ (Contract-derived)
    Content: All tasks have a precision level.
          The precision level must be a positive value (greater than 0).
          Tasks with a precision level of 0 cannot be optimization targets (= do not constitute valid tasks).
    Basis: Structural requirement of task definitions. Tasks without a precision level cannot be optimized.
    Source: manifesto.md T8 "Whether self-imposed or externally imposed"
    Refutation condition: Not applicable (T₀) -/
axiom task_has_precision :
  ∀ (task : Task),
    task.precisionRequired.required > 0

-- ============================================================
-- Sorry Inventory
-- ============================================================

/-!
## Sorry Inventory Phase 1

List of `sorry` occurrences in Phase 1:

| Location | Reason for sorry |
|------|-------------|
| `Ontology.lean: canTransition` | opaque — transition conditions to be defined in Phase 3+ |
| `Ontology.lean: globalResourceBound` | opaque — to be concretized per domain in Phase 2+ |
| `Axioms.lean: structureImproved` | opaque — to be defined as Observable in Phase 4+ |

Axioms are propositions assumed without proof, so they contain no sorry.
When P1–P6 are derived as theorems in Phase 3, sorry occurrences will arise.
-/

end Manifest
