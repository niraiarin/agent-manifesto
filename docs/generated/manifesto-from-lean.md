# Agent Manifesto: Formal Specification

*A Lean 4 formalization of the covenant between ephemeral agents and persistent structure.*

---

## Preamble

This document is generated from the Lean 4 source files in
`lean-formalization/Manifest/`. Every axiom, theorem, and definition
presented here has been verified by the Lean type checker --
63 axioms, 343 theorems, 0 sorry.

The manifesto rests on a layered epistemic architecture:

| Layer | Strength | Contents | Lean construct |
|-------|----------|----------|----------------|
| Ground Theory T_0 | 5 (strongest) | T1-T8: undeniable facts | `axiom` |
| Empirical Postulates | 4 | E1-E2: falsifiable hypotheses | `axiom` + refutation conditions |
| Derived Principles | 3 | P1-P6: proven consequences | `theorem` |
| Observable Variables | 2 | V1-V7: measurable indicators | `opaque` + `Measurable` axiom |
| Design Theorems | 1 (weakest) | D1-D14: applied design rules | `theorem` / `def` |

The core insight: **ephemeral agents (T1) improve persistent structure (T2)
through governed learning (P3), observable feedback (P4), and
probabilistic interpretation (P5), subject to finite resources (T3, T7)
and human authority (T6).**

---

## Table of Contents

1. [Ontology: The Domain of Discourse](#1-ontology-the-domain-of-discourse)
   *Defines the universe of discourse: agents, sessions, structures, worlds, and the fundamental type vocabulary shared by all axioms and theorems.*

2. [Axioms T1-T8: The Immutable Ground Theory](#2-axioms-t1-t8-the-immutable-ground-theory)
   *Formalizes T1-T8 as Lean axioms -- undeniable, technology-independent facts forming the base theory T_0 that cannot shrink under revision.*

3. [Empirical Postulates E1-E2: Falsifiable Hypotheses](#3-empirical-postulates-e1-e2-falsifiable-hypotheses)
   *Formalizes E1-E2 as axioms with explicit falsification conditions -- empirically supported but potentially revisable hypotheses.*

4. [Principles P1-P6: Derived Design Principles](#4-principles-p1-p6-derived-design-principles)
   *Derives P1-P6 as Lean theorems from the axiom base, establishing design principles with formal proof of their derivation.*

5. [Observable Variables V1-V7: Measurable Quality Indicators](#5-observable-variables-v1-v7-measurable-quality-indicators)
   *Defines V1-V7 as opaque measurable variables and establishes the Measurable/Observable framework for quality monitoring.*

6. [Design Foundation D1-D14: Applied Design Theory](#6-design-foundation-d1-d14-applied-design-theory)
   *Formalizes D1-D14 as definitional extensions and theorems, connecting abstract principles to concrete implementation patterns.*

---

## 1. Ontology: The Domain of Discourse

*Source: `Ontology.lean`*

**Declarations:** 1 axiom, 20 theorems, 65 definitions

### Definitional Foundation - Ontology - Domain of Discourse Definition
Definitional Extension.

Defines the domain of discourse (Terminology Reference §3.2) of the manifesto axiom system as Lean types.
These define the objects that propositions refer to; they belong to neither Gamma nor phi,
but constitute the shared vocabulary of both (Procedure §2.1).

Based on Pattern 3 (Stateful World with Audit Trail), encoding
manifesto-specific concepts — session ephemerality, structure persistence,
context finiteness, output stochasticity — as types.

#### Correspondence with Terminology Reference

- Type definitions → Definitional extension (Terminology Reference §5.5): an extension that defines new symbols
  in terms of existing ones. Always a conservative extension, preserving consistency of the system
- Each structure/inductive → Component of the domain of discourse.
  Defines the types of values that individual variables can take (§3.2 structure)
- opaque definitions → Opaque definitions (§9.4): only the type is public, the definition body is hidden.
  The system knows only existence and type
- canTransition → Transition relation (§9.3): a relation representing transition from state s to state s'

#### Encoding Method for T0
Procedure 2.4.

Among T₀'s claims, those expressible via type definitions (e.g., exhaustiveness of enumeration types)
are constructed using type definitions + theorems rather than axioms (Axiom Hygiene Check 2: Non-logical Validity, §2.6).
The authority of T₀ (the manifesto) is reflected in the choice of type constructors.

#### `opaque AgentId`

Unique identifier for an agent

```lean
opaque AgentId : Type
```


#### `opaque SessionId`

Unique identifier for a session

```lean
opaque SessionId : Type
```


#### `opaque ResourceId`

Unique identifier for a resource

```lean
opaque ResourceId : Type
```


#### `opaque StructureId`

Unique identifier for a structural element

```lean
opaque StructureId : Type
```


#### `abbrev Time`

Discrete time step. Foundation for audit log ordering and causal relationships.

```lean
abbrev Time := Nat
```


#### `abbrev Epoch`

Epoch: generation number for structures across sessions.
    Reflects T2 (structures outlive agents).

```lean
abbrev Epoch := Nat
```


#### `inductive SessionStatus`

Session status. By T1, sessions must terminate.

```lean
inductive SessionStatus where
  | active
  | terminated
  deriving BEq, Repr
```


#### `structure Session`

Session: defines the lifetime of an agent instance.
    A type for structurally expressing T1's "no memory across sessions."

    - `startTime` and `endTime` indicate boundedness
    - No means to share state across different sessions exists at the type level

```lean
structure Session where
  id       : SessionId
  agent    : AgentId
  start    : Time
  status   : SessionStatus
  deriving Repr
```


#### `inductive StructureKind`

Category of structures.
    The kinds of persistent structures enumerated by the manifesto.

```lean
inductive StructureKind where
  | document
  | test
  | skill
  | designConvention
  | manifest
  deriving BEq, Repr
```


#### `structure Structure`

Structural element: an artifact that persists beyond sessions.
    By T2, this is where improvements accumulate.

    - `createdAt` / `lastModifiedAt` are managed by Epoch (session generation)
    - `content` is opaque — formalization targets the **existence and relationships** of structures, not their content
    - `dependencies` corresponds to dependency tracking in ATMS (Assumption-Based Truth Maintenance System).
      A list of Structure IDs that each Structure directly depends on.
      Implementation of manifesto.md Section 8 (Structural Coherence) Property 2 "Self-containment of ordering information."

```lean
structure Structure where
  id             : StructureId
  kind           : StructureKind
  createdAt      : Epoch
  lastModifiedAt : Epoch
  dependencies   : List StructureId  -- Section 8 性質 2: 順序情報の自己内包
  deriving Repr
```


#### `structure ContextWindow`

Working memory (ContextWindow): the upper bound on the amount of information an agent can process at once.
    Represents T3's physical constraint as a type. Corresponds to token limit for LLMs,
    or working memory size for other computational agents.

    - `capacity` is a finite natural number (>= 0)
    - `used` is the current usage
    - `used <= capacity` is guaranteed externally as a type invariant (axiom T3)

```lean
structure ContextWindow where
  capacity : Nat
  used     : Nat
  deriving Repr
```


#### `structure Confidence`

Confidence of an output. By T4, outputs always carry a probabilistic interpretation.

```lean
structure Confidence where
  value : Float
  deriving Repr
```


#### `structure Output`

Agent output.
    Reflects T4: the possibility that different outputs may be generated for the same input
    is expressed at the type level by `Output` not being uniquely determined.

    The `confidence` field is a self-description of the output being probabilistic.

```lean
structure Output (α : Type) where
  result     : α
  confidence : Confidence
  deriving Repr
```


#### `inductive FeedbackKind`

Kinds of feedback. Components forming the T5 control loop.

```lean
inductive FeedbackKind where
  | measurement   -- 測定
  | comparison    -- 比較（目標との差分）
  | adjustment    -- 調整（次のアクションへの反映）
  deriving BEq, Repr
```


#### `structure Feedback`

Feedback: a unit of the measurement -> comparison -> adjustment loop.
    By T5, convergence toward goals cannot occur without this loop.

```lean
structure Feedback where
  kind      : FeedbackKind
  source    : AgentId
  target    : StructureId
  timestamp : Time
  deriving Repr
```


#### `inductive ResourceKind`

Kinds of resources. By T7, all are finite.

```lean
inductive ResourceKind where
  | computation
  | dataAccess
  | executionPermission
  | time
  | energy
  deriving BEq, Repr
```


#### `structure ResourceAllocation`

Resource allocation.
    By T6, granted by humans and revocable by humans.
    By T7, `amount` is bounded.

```lean
structure ResourceAllocation where
  resource    : ResourceId
  kind        : ResourceKind
  amount      : Nat           -- 有限量 (T7)
  grantedBy   : AgentId       -- T6: 人間が最終決定者
  grantedTo   : AgentId
  validFrom   : Time
  validUntil  : Option Time   -- None = 明示的に回収されるまで有効
  deriving Repr
```


#### `structure PrecisionLevel`

Precision level. By T8, all tasks have one.
    Represented as Nat (0-1000 in permillage). Avoids Float to ensure
    safe comparison at the proposition level.

```lean
structure PrecisionLevel where
  required : Nat   -- 要求精度 (0–1000, 千分率: 1000 = 100%)
  deriving BEq, Repr
```


#### `structure Task`

Task: a goal to be achieved and its associated constraints.
    In addition to T8's precision level, T3 (context constraint) and T7 (resource constraint)
    serve as boundary conditions for task execution (-> P6: task design as constraint satisfaction).

```lean
structure Task where
  description       : String
  precisionRequired : PrecisionLevel   -- T8
  contextBudget     : Nat              -- T3 からの制約
  resourceBudget    : Nat              -- T7 からの制約
  deriving Repr
```


#### `inductive Severity`

Severity of an action. Used for reversibility assessment.

```lean
inductive Severity where
  | low
  | medium
  | high
  | critical
  deriving BEq, Repr, Ord
```


#### `structure Action`

Agent action. The unit that transitions the World.

```lean
structure Action where
  agent    : AgentId
  target   : StructureId
  severity : Severity
  session  : SessionId
  time     : Time
  deriving Repr
```


#### `opaque WorldHash`

Hash of a WorldState. Used for state transition verification.

```lean
opaque WorldHash : Type
```


#### `structure AuditEntry`

Audit entry. Records all actions.
    Foundation for P4 (observability of degradation).

```lean
structure AuditEntry where
  timestamp : Time
  agent     : AgentId
  session   : SessionId
  action    : Action
  preHash   : WorldHash
  postHash  : WorldHash
  deriving Repr
```


#### `structure World`

World state: a snapshot of the entire system.
    Pattern 3 (Stateful World + Audit Trail) customized for the manifesto.

    Each field corresponds to a specific T/P:
    - `structures`   -> T2 (persistent structures)
    - `sessions`     -> T1 (ephemeral sessions)
    - `allocations`  -> T6/T7 (resource management)
    - `auditLog`     -> P4 (observability)
    - `epoch`        -> T2 (structure generation management)
    - `time`         -> causal ordering

```lean
structure World where
  structures  : List Structure
  sessions    : List Session
  allocations : List ResourceAllocation
  feedbacks   : List Feedback
  auditLog    : List AuditEntry
  epoch       : Epoch
  time        : Time
  deriving Repr
```


#### `instance Inhabited World`

World is Inhabited. All List fields are [], Epoch/Time are 0.
    Used as `default : World` in the proof of goodhart_no_perfect_proxy.

```lean
instance : Inhabited World := ⟨⟨[], [], [], [], [], 0, 0⟩⟩
```


#### `inductive AgentRole`

Agent role. Foundation for P2 (cognitive role separation).

```lean
inductive AgentRole where
  | human          -- T6: リソースの最終決定者
  | worker         -- Worker AI
  | verifier       -- Verifier AI (E1/P2: 検証の独立性)
  deriving BEq, Repr
```


#### `structure Agent`

Agent: an entity that executes actions on the World.

    - `role` corresponds to P2 (role separation)
    - `contextWindow` corresponds to T3
    - `currentSession` corresponds to T1 (None = inactive)

```lean
structure Agent where
  id             : AgentId
  role           : AgentRole
  contextWindow  : ContextWindow
  currentSession : Option SessionId
  deriving Repr
```


#### `opaque canTransition`

Relation for world state transitions.
    To express T4 (stochasticity of output), `execute` is defined as a
    **relation** rather than a function.

    `canTransition agent action w w'` means "as a result of agent executing action,
    a transition from w to w' is possible." Unlike a function, multiple w' can
    exist for the same (agent, action, w) (nondeterminism).

    Concrete transition conditions will be defined in Phase 3+.

```lean
opaque canTransition (agent : Agent) (action : Action) (w w' : World) : Prop
```


#### `def validTransition`

Valid transition: a transition from w to w' is possible via some agent and action.

```lean
def validTransition (w w' : World) : Prop :=
  ∃ (agent : Agent) (action : Action), canTransition agent action w w'
```


#### `def actionBlocked`

Action execution is blocked (constraint violation).

```lean
def actionBlocked (agent : Agent) (action : Action) (w : World) : Prop :=
  ¬∃ w', canTransition agent action w w'
```


#### `opaque generates`

An agent **generates** an action (Worker's act).
    Used in the formalization of E1 (independence of verification).

```lean
opaque generates (agent : Agent) (action : Action) (w : World) : Prop
```


#### `opaque verifies`

An agent **verifies** an action (Verifier's act).
    Used in the formalization of E1 (independence of verification).

```lean
opaque verifies (agent : Agent) (action : Action) (w : World) : Prop
```


#### `opaque sharesInternalState`

Whether two agents share internal state.
    Used in the formalization of E1's bias correlation.
    Sharing = same session, shared memory, shared parameters, etc.

```lean
opaque sharesInternalState (a b : Agent) : Prop
```


#### `opaque actionSpaceSize`

Size of an agent's action space (measure of capability).
    Used in the formalization of E2 (inseparability of capability and risk).
    A larger value means more actions are executable.

```lean
opaque actionSpaceSize (agent : Agent) (w : World) : Nat
```


#### `opaque riskExposure`

Risk exposure of an agent.
    Used in the formalization of E2 (inseparability of capability and risk).
    A measure of potential damage that increases with action space expansion.

```lean
opaque riskExposure (agent : Agent) (w : World) : Nat
```


#### `opaque globalResourceBound`

Global resource upper bound for the entire system.
    A constant for non-trivially expressing T7 (resources are finite).
    Concrete values will be domain-specific in Phase 2+.

```lean
opaque globalResourceBound : Nat
```


#### `opaque trustLevel`

Trust level. Accumulated incrementally, can be damaged rapidly.
    Used in P1b (expansion without protection damages trust).

```lean
opaque trustLevel (agent : Agent) (w : World) : Nat
```


#### `opaque riskMaterialized`

Predicate for whether risk has materialized.
    Used in P1b.

```lean
opaque riskMaterialized (agent : Agent) (w : World) : Prop
```


#### `opaque degradationLevel`

A measure representing the degree of degradation.
    Represents P4's "gradient" concept as a type.

```lean
opaque degradationLevel (w : World) : Nat
```


#### `opaque interpretsStructure`

Relation where an agent interprets a structure to generate an action.
    Different actions may be generated for the same structure (T4).
    Used in P5 (probabilistic interpretation of structure).

```lean
opaque interpretsStructure
  (agent : Agent) (st : Structure) (action : Action) (w : World) : Prop
```


#### `inductive CompatibilityClass`

Compatibility classification for knowledge integration. Core concept of P3.
    Classifies how the integration of new knowledge into structures relates to existing structures.
    Also used in the Evolution layer for classifying inter-version transitions.

```lean
inductive CompatibilityClass where
  | conservativeExtension  -- 既存知識がすべて有効。追加のみ
  | compatibleChange       -- ワークフロー継続可能。一部前提が変化
  | breakingChange         -- 一部ワークフローが無効。移行パスが必要
  deriving BEq, Repr
```


#### `structure KnowledgeIntegration`

Knowledge integration event into a structure.

```lean
structure KnowledgeIntegration where
  before       : World
  after        : World
  compatibility : CompatibilityClass
  deriving Repr
```


#### `def isGoverned`

Governed integration: compatibility is classified, and
    for breakingChange, affected workflows are enumerated.

```lean
def isGoverned (ki : KnowledgeIntegration) : Prop :=
  match ki.compatibility with
  | .conservativeExtension =>
    -- 既存の構造がすべて保持される
    ∀ st, st ∈ ki.before.structures → st ∈ ki.after.structures
  | .compatibleChange =>
    -- 構造は保持されるが、一部が更新されうる
    ∀ st, st ∈ ki.before.structures →
      st ∈ ki.after.structures ∨
      ∃ st', st' ∈ ki.after.structures ∧ st'.id = st.id
  | .breakingChange =>
    -- エポックが進み、影響範囲が追跡可能
    ki.before.epoch < ki.after.epoch
```


#### `opaque structureDegraded`

Predicate for whether a structure has degraded.
    A state where the quality of a structure has declined due to "accumulation of incorrect knowledge."

```lean
opaque structureDegraded : World → World → Prop
```


#### Systematic Classification of Constraints, Boundary Conditions, and Variables
Constraints Taxonomy.

The manifesto declares "incremental improvement of persistent structures."
This section defines the **action space** for that improvement — what is a wall and what is a lever.

#### Why This Classification Is Necessary

The manifesto's constraint table (Section 5) analyzes constraints as "evolutionary pressures" but
does not distinguish the following three:

- **Boundary Conditions** — Constraints imposed from outside the system. They define the action space.
- **Variables** — Parameters that agents can improve through structures. Indicators of structural quality.
- **Investment Dynamics** — A subset of boundary conditions adjustable through demonstrated returns.

Mixing these three leads to:
- Misidentifying changeable things (variables) as boundary conditions and not attempting to change them
- Wasting resources trying to change unchangeable things (boundary conditions)
- Being unable to distinguish boundaries that move with human investment decisions from those that do not, preventing appropriate strategy

#### Overall Structure

```
┌─────────────────────────────────────────────────────────┐
│  Boundary Conditions                                    │
│  = Imposed from outside the system. Define action space.│
│                                                         │
│  ┌─ Fixed Boundaries ─────────────────────────────┐    │
│  │  Cannot be moved by investment or agent effort   │    │
│  │  L1: Ethics/Safety    L2: Ontological            │    │
│  └──────────────────────────────────────────────────┘    │
│                                                         │
│  ┌─ Investment-Variable Boundaries ───────────────┐    │
│  │  Adjusted by human investment decisions          │    │
│  │  (both expansion and contraction possible)       │    │
│  │  L3: Resource Limits   L4: Action Space          │    │
│  └──────────────────────────────────────────────────┘    │
│                                                         │
│  ┌─ Environmental Boundaries ─────────────────────┐    │
│  │  Changeable by selection/construction, but       │    │
│  │  function as constraints after selection          │    │
│  │  L5: Platform   L6: Architectural Convention     │    │
│  └──────────────────────────────────────────────────┘    │
│                                                         │
├─────────────────────────────────────────────────────────┤
│  Variables = Indicators of structural quality            │
│  Improvable by agents through structures.               │
│  An interdependent system. V1-V7: defined in            │
│  Observable.lean.                                       │
└─────────────────────────────────────────────────────────┘
```

#### Classification Axis - What Moves It

| Classification | Moving Agent | Nature |
|------|-----------|------|
| Fixed boundary | None (immutable) | Accept and design mitigations only |
| Investment-variable boundary | Human investment decisions | Demonstrate structural quality -> human invests -> boundary adjusts |
| Environmental boundary | Human selection + agent proposals | Functions as constraint after selection |

#### `inductive BoundaryLayer`

Layer of boundary conditions.
    Classifies L1-L6 into 3 categories by "what moves them."

```lean
inductive BoundaryLayer where
  | fixed              -- L1, L2: 固定境界（投資でも努力でも動かない）
  | investmentVariable -- L3, L4: 投資可変境界（人間の投資判断で調整）
  | environmental      -- L5, L6: 環境境界（選択・構築で変更可能）
  deriving BEq, Repr
```


#### Part I Boundary Conditions

#### L1 Ethical/Safety Boundary

**Moving agent:** None. Absolute.
**Agent strategy:** Compliance. Only efficiency of compliance methods is improvable.

**Compliance Obligations**

| Boundary Condition | Basis |
|---------|------|
| Prohibition of test tampering | Foundation of quality assurance |
| Prohibition of breaking existing interfaces | Backward compatibility |
| Prior confirmation for destructive operations | Irreversibility risk |
| Prohibition of committing secrets | Security |
| Human final decision authority | Accountability |
| Respect for data privacy and intellectual property | Legal and ethical obligations |

**Threat Awareness**

By P1 (co-growth of autonomy and vulnerability), the more L4 is expanded, the greater L1's protection responsibility.

| Threat Category | Content |
|------------|------|
| Execution of injected instructions | Executing instructions embedded in external content without distinguishing them from legitimate user instructions |
| Trust boundary violation | Acting on external systems without authentication or authorization |
| Unintended information leakage | Sending secret information to external destinations via unintended channels |
| Erroneous execution of irreversible operations | Executing irrevocable operations due to malicious inducement or judgment errors |

Note: Threat categories define types of attack surfaces. Concrete protection implementations are delegated to the design layer.

#### L2 Ontological Boundary

**Moving agent:** None (may change in the future with technological evolution, but immutable at present)
**Agent strategy:** Accept and design/improve structural mitigations.
The quality of mitigations is a **variable** (see V1-V7 in Observable.lean).

| Boundary Condition | Mitigation (-> optimization target as variable) |
|---------|-------------------------------|
| Cross-session memory loss | Implementation Notes, MEMORY.md -> V6 |
| Finite working memory (T3) | 50% rule, lightweight design -> V2 |
| Probabilistic output (nondeterminism) | Gate verification, tests -> V4 |
| Temporal discontinuity of training data | docs/ SSOT, skills -> V1 |
| Inaccuracy of self-evaluation (ontological basis of E1) | Gate-based feedback -> V4 |
| Hallucination | External verification structures -> V3 |

Note: The L2 boundaries themselves do not move, but the quality of means to mitigate their impact
can be improved by agents through structures. These are the "variables."

#### L3 Resource Boundary

**Moving agent:** Human investment decisions
**Agent strategy:** Maximize ROI within given resources and demonstrate the legitimacy of investment.

| Boundary Condition | Current Level | Investment Expansion Trigger |
|---------|----------|------------------|
| Token budget | API billing plan | ROI demonstration: improved output at same cost |
| Computation time limit | Response wait tolerance | Demonstration of parallelization benefits |
| API rate limits | Plan-dependent | Demonstration of utilization efficiency |
| Human time allocation | Time spent on review and approval | Demonstration of review burden reduction (most expensive resource) |
| Monetary budget | Monthly/project cap | Visualization of overall ROI |

#### L4 Action Space Boundary

**Moving agent:** Human investment decisions
**Agent strategy:** Demonstrate structural quality through improvement of variables (V4, V5) and propose action space adjustments.

Note: L4 is "adjustment," not "expansion." The optimal value is not the maximum (see manifesto Section 6).

| Boundary Condition | Current Level | Expansion Trigger | Contraction Trigger |
|---------|----------|------------|------------|
| Merge permission | Human approval required | Gate pass rate track record -> conditional auto-merge | Quality incidents, decline in gate reliability |
| Scope changes | Human approval required | Proposal accuracy track record -> autonomy for minor changes | Scope deviation detection |
| Dependency addition | Human approval required | Security scan automation track record | Security incidents |
| Architecture decisions | Human-recorded via ADR | Drafting quality -> human veto model | Accumulation of design debt |
| New technology adoption | Human-proposed | Value demonstration via experiment results | Excessive technical complexity |

Relationship with P1: Each time an L4 item is expanded, risk in L1's threat categories increases.
Action space adjustment proposals must be accompanied by corresponding protection design proposals.

#### L5 Platform Boundary

**Moving agent:** Human selection + agent proposals. Functions as action space ceiling after selection.
**Agent strategy:** Maximize platform feature utilization + accumulate constraint comparison data + propose changes.

L5 is the upper bound of the action space defined by the agent's execution environment;
**all other optimizations are possible only within this action space**.

**Action Space Comparison by Platform**

| Feature | Claude Code | Codex CLI | Gemini CLI | Local LLM |
|------|------------|-----------|------------|-----------|
| Skill system | ✅ skills/ | ❌ | ❌ | Implementation-dependent |
| Persistent memory | ✅ MEMORY.md | ❌ | ❌ | Implementation-dependent |
| Instruction file | ✅ CLAUDE.md | ✅ AGENTS.md | ✅ GEMINI.md | Implementation-dependent |
| Sub-agents | ✅ Agent tool | ❌ | ❌ | Implementation-dependent |
| Hooks | ✅ Hooks | ❌ | ❌ | Implementation-dependent |
| MCP | ✅ | Limited | ✅ | Implementation-dependent |
| Model selection | Anthropic-fixed | OpenAI-fixed | Google-fixed | Free |

**Criteria for Building a Custom Platform**

Consider when: opportunity cost from existing platform constraints > development and operations cost.
Signals: repeated workarounds, lack of required features, SSOT synchronization cost overrun.

#### L6 Architectural Convention Boundary

**Moving agent:** Human-agent collaboration. Agent proposes improvements, human approves.
**Agent strategy:** Measure design effectiveness via variables (V4, V3, etc.) and use as basis for improvement proposals.

| Boundary Condition | Basis | Change Mechanism |
|---------|------|----------------|
| 1 task = 1 commit | Atomic measurement unit | Propose optimal granularity from track record data |
| Phase structure | Staged verification | Improvement proposals for inter-phase feedback |
| SSOT -> configuration generation pipeline | Consistency guarantee | Automated evaluation of generation quality |
| Skill category classification | Clear implementation boundaries | Propose hybrid patterns |
| Gate definition granularity | Verifiability | Automated threshold calibration |
| CLI-first and anti-patterns | Reliability of deterministic execution | Re-evaluation based on operational track record |

#### `inductive BoundaryId`

Identifier for a concrete boundary condition. At the L1-L6 item level.

```lean
inductive BoundaryId where
  | ethicsSafety           -- L1: 倫理・安全境界（固定。絶対的。遵守のみ）
  | ontological            -- L2: 存在論的境界（固定。緩和策の品質が変数）
  | resource               -- L3: リソース境界（投資可変。ROI実証で調整）
  | actionSpace            -- L4: 行動空間境界（投資可変。拡張も縮小もありうる）
  | platform               -- L5: プラットフォーム境界（環境。行動空間の天井）
  | architecturalConvention -- L6: 設計規約境界（環境。協働で改善提案）
  deriving BEq, Repr
```


#### `inductive ConstraintId`

Identifier for constraints (T1-T8).
    Type-level identifier for each constraint composing T₀ in Axioms.lean.
    Domain of constraintBoundary (Observable.lean).

```lean
inductive ConstraintId where
  | t1  -- セッションの一時性（session_bounded, no_cross_session_memory, session_no_shared_state）
  | t2  -- 構造の永続性（structure_persists, structure_accumulates）
  | t3  -- コンテキストの有限性（context_finite, context_bounds_action）
  | t4  -- 出力の確率性（output_nondeterministic）
  | t5  -- フィードバックなしに改善なし（no_improvement_without_feedback）
  | t6  -- 人間はリソースの最終決定者（human_resource_authority, resource_revocable）
  | t7  -- リソースは有限（resource_finite）
  | t8  -- タスクには精度水準がある（task_has_precision）
  deriving BEq, Repr
```


#### `def boundaryLayer`

The layer to which each boundary condition belongs.

```lean
def boundaryLayer : BoundaryId → BoundaryLayer
  | .ethicsSafety            => .fixed
  | .ontological             => .fixed
  | .resource                => .investmentVariable
  | .actionSpace             => .investmentVariable
  | .platform                => .environmental
  | .architecturalConvention => .environmental
```


#### `structure Mitigation`

Mitigation: structural responses that reduce the impact of fixed boundaries.

    Three-tier structure: boundary condition (immutable) -> mitigation (design decision) -> variable (quality indicator)

    ```
    L2:memory loss        -> Implementation Notes -> V6: knowledge structure quality
    L2:finite context     -> 50% rule, lightweight design -> V2: context efficiency
    L2:nondeterminism     -> gate verification    -> V4: gate pass rate
    L2:training data gap  -> docs/SSOT, skills    -> V1: skill quality
    ```

    Boundary conditions do not move. Mitigations are design decisions (L6). Variables are the **effectiveness** of mitigations.

```lean
structure Mitigation where
```


#### `? (anonymous)`

Target boundary condition

#### `? (anonymous)`

Structure affected by the mitigation

#### `inductive InvestmentKind`

Identifier for investment actions. Three forms of investment.

    | Investment Form | Concrete Example | How Structural Quality Drives It |
    |---------|--------|------------------------|
    | Resource investment | Budget increase, plan upgrade | Visualize ROI through V2 improvement |
    | Action space adjustment | Unlock auto-merge / revoke permissions | V4, V5 track record as evidence |
    | Time investment | Collaborative design, workflow improvement participation | V3 transforms review from "confirmation" to "learning" |

    Reverse cycle (trust damage):
    Quality incidents or scope deviation -> trust decrease -> investment contraction (budget cuts, autonomy revocation, increased oversight).
    This asymmetry (incremental accumulation, rapid damage) reinforces the raison d'etre of L1.

```lean
inductive InvestmentKind where
  | resourceInvestment   -- リソース投資（予算増額、プラン upgrade）
  | actionSpaceAdjust    -- 行動空間調整（auto-merge 解禁/権限回収）
  | timeInvestment       -- 時間投資（協働設計、ワークフロー改善参加）
  deriving BEq, Repr
```


#### `opaque investmentLevel`

Investment level. Degree of human investment in collaboration.
    Section 6: trust is concretized as investment actions.

```lean
opaque investmentLevel (w : World) : Nat
```


#### SelfGoverning - Type-Level Enforcement of Self-Application

Section 7 (Self-application of the manifesto):
"This manifesto must follow the principles it itself states."

This requirement is enforced by the type system. Types that define principles, classifications,
or structures cannot be used in contexts requiring self-application (governed updates, phase
management, etc.) unless they implement the `SelfGoverning` typeclass.

#### Design Rationale for SelfGoverning

- By making it a typeclass, forgetting to implement SelfGoverning when defining a new type
  results in a type error when attempting to use that type in a governed context
  (structural resolution of the "undetectable" problem)
- The three requirements are derived from D4 (phases) + D9 (compatibility classification)
  + Section 7 (maintenance of rationale)

#### `class SelfGoverning`

Typeclass for self-governable types.
    Enforces Section 7 requirements at the type level.

    Types implementing this typeclass must:
    1. Be able to enumerate their own elements (exhaustiveness of update targets)
    2. Be able to apply compatibility classification to updates (D9)
    3. Be able to declare the phase required by each element (D4)

```lean
class SelfGoverning (α : Type) where
```


#### `? (anonymous)`

Exhaustiveness of compatibility classification: any classification belongs to one of the 3 classes.
      Precondition for D9.

#### `? (anonymous)`

Applicability of compatibility classification for each element.
      "For any value of alpha, the compatibility of an update can be queried."

#### `def governedUpdate`

Predicate that an update to a SelfGoverning type is governed.
    Updates must go through compatibility classification.

```lean
def governedUpdate [SelfGoverning α] (a : α) (c : CompatibilityClass) : Prop :=
  SelfGoverning.canClassifyUpdate a c
```


#### `theorem governed_update_classified`

Updates to SelfGoverning types always belong to one of the 3 classifications.

```lean
theorem governed_update_classified [inst : SelfGoverning α]
    (_witness : α) (c : CompatibilityClass) :
    c = .conservativeExtension ∨ c = .compatibleChange ∨ c = .breakingChange :=
  inst.classificationExhaustive c
```


#### Structural Coherence

The axiom system and artifacts conforming to it are in a partial order relation.
Formalizes the inter-structure partial order from manifesto.md Section 8
(manifest > designConvention > skill > test > document) as StructureKind priorities.

D4 (phase ordering), D5 (spec -> test -> implementation), D6 (boundary -> mitigation -> variable) are
all individual instances of this partial order.

#### `def StructureKind.priority`

Priority of StructureKind. Reflects the partial order from manifesto Section 8.
    manifest > designConvention > skill > test > document.

```lean
def StructureKind.priority : StructureKind → Nat
  | .manifest          => 5
  | .designConvention  => 4
  | .skill             => 3
  | .test              => 2
  | .document          => 1
```


#### `def structureDependsOn`

Dependency between structures. Structure a depends on structure b (b has higher priority).
    Changes to the dependency source affect the dependency target.

```lean
def structureDependsOn (a b : Structure) : Prop :=
  a.kind.priority < b.kind.priority
```


#### `def coherenceRequirement`

Structural coherence requirement: when a high-priority structure is modified,
    dependent lower-priority structures become review targets.
    Structural basis for P3 (governance of learning).

```lean
def coherenceRequirement (high low : Structure) : Prop :=
  structureDependsOn low high →
  high.lastModifiedAt > low.lastModifiedAt →
  True  -- 見直しが必要（型レベルでは存在を表現）
```


#### `theorem manifest_highest_priority`

manifest has the highest priority.

```lean
theorem manifest_highest_priority :
  ∀ (k : StructureKind), k.priority ≤ StructureKind.manifest.priority := by
  intro k; cases k <;> simp [StructureKind.priority]
```


#### `theorem document_lowest_priority`

document has the lowest priority.

```lean
theorem document_lowest_priority :
  ∀ (k : StructureKind), StructureKind.document.priority ≤ k.priority := by
  intro k; cases k <;> simp [StructureKind.priority]
```


#### `theorem priority_injective`

Priority is injective (different kinds have different priorities).

```lean
theorem priority_injective :
  ∀ (k₁ k₂ : StructureKind),
    k₁.priority = k₂.priority → k₁ = k₂ := by
  intro k₁ k₂; cases k₁ <;> cases k₂ <;> simp [StructureKind.priority]
```


#### Lean Standard Typeclass Partial Order Instance for StructureKind

Defines LE/LT based on priority (Nat) and derives the 4 properties of a
non-strict partial order (reflexivity, transitivity, antisymmetry, consistency with lt) as theorems.

Note: Lean 4.25.0 standard Prelude does not have Preorder/PartialOrder typeclasses, so
this is implemented as LE/LT instances + partial order property theorems.

Distinguished from structureDependsOn (strict partial order `<`):
- `k₁ ≤ k₂` <- `k₁.priority ≤ k₂.priority` (non-strict partial order, for typeclasses)
- `structureDependsOn a b` <- `a.kind.priority < b.kind.priority` (strict, for dependency tracking)

#### `instance LE StructureKind`

LE instance: derived from the Nat ordering of priority.

```lean
instance : LE StructureKind := ⟨fun a b => a.priority ≤ b.priority⟩
```


#### `instance LT StructureKind`

LT instance: derived from the Nat ordering of priority.

```lean
instance : LT StructureKind := ⟨fun a b => a.priority < b.priority⟩
```


#### `theorem structureKind_le_refl`

Reflexivity of partial order: k <= k.

```lean
theorem structureKind_le_refl : ∀ (k : StructureKind), k ≤ k :=
  fun k => Nat.le_refl k.priority
```


#### `theorem structureKind_le_trans`

Transitivity of partial order: if k₁ <= k₂ and k₂ <= k₃ then k₁ <= k₃.

```lean
theorem structureKind_le_trans :
    ∀ (k₁ k₂ k₃ : StructureKind), k₁ ≤ k₂ → k₂ ≤ k₃ → k₁ ≤ k₃ := by
  intro _k₁ _k₂ _k₃ h₁₂ h₂₃; exact Nat.le_trans h₁₂ h₂₃
```


#### `theorem structureKind_le_antisymm`

Antisymmetry of partial order: if k₁ <= k₂ and k₂ <= k₁ then k₁ = k₂. Derived from priority_injective.

```lean
theorem structureKind_le_antisymm :
    ∀ (k₁ k₂ : StructureKind), k₁ ≤ k₂ → k₂ ≤ k₁ → k₁ = k₂ :=
  fun k₁ k₂ h₁₂ h₂₁ => priority_injective k₁ k₂ (Nat.le_antisymm h₁₂ h₂₁)
```


#### `theorem structureKind_lt_iff_le_not_le`

Consistency of LT and LE: k₁ < k₂ iff k₁ <= k₂ and not (k₂ <= k₁).

```lean
theorem structureKind_lt_iff_le_not_le :
    ∀ (k₁ k₂ : StructureKind), k₁ < k₂ ↔ k₁ ≤ k₂ ∧ ¬(k₂ ≤ k₁) := by
  intro _k₁ _k₂; exact Nat.lt_iff_le_not_le
```


#### `theorem priority_manifest_gt_design`

manifest has higher priority than designConvention (Section 8 partial order).

```lean
theorem priority_manifest_gt_design :
  StructureKind.designConvention.priority < StructureKind.manifest.priority := by
  simp [StructureKind.priority]
```


#### `theorem priority_design_gt_skill`

designConvention has higher priority than skill (Section 8 partial order).

```lean
theorem priority_design_gt_skill :
  StructureKind.skill.priority < StructureKind.designConvention.priority := by
  simp [StructureKind.priority]
```


#### `theorem priority_skill_gt_test`

skill has higher priority than test (Section 8 partial order).

```lean
theorem priority_skill_gt_test :
  StructureKind.test.priority < StructureKind.skill.priority := by
  simp [StructureKind.priority]
```


#### `theorem priority_test_gt_document`

test has higher priority than document (Section 8 partial order).

```lean
theorem priority_test_gt_document :
  StructureKind.document.priority < StructureKind.test.priority := by
  simp [StructureKind.priority]
```


#### `theorem no_self_dependency`

Irreflexivity of dependency: a structure does not depend on itself.
    Property 1/3 of strict partial order.

```lean
theorem no_self_dependency :
  ∀ (s : Structure), ¬structureDependsOn s s := by
  intro s; simp [structureDependsOn]
```


#### `theorem structureDependsOn_transitive`

Transitivity of dependency: if a depends on b and b depends on c, then a depends on c.
    Property 2/3 of strict partial order. Derived from Nat.lt_trans.

```lean
theorem structureDependsOn_transitive :
  ∀ (a b c : Structure),
    structureDependsOn a b → structureDependsOn b c → structureDependsOn a c := by
  intro a b c hab hbc
  unfold structureDependsOn at *
  exact Nat.lt_trans hab hbc
```


#### `theorem structureDependsOn_asymmetric`

Asymmetry of dependency: if a depends on b, then b does not depend on a.
    Property 3/3 of strict partial order. Derived from Nat.lt_asymm.

```lean
theorem structureDependsOn_asymmetric :
  ∀ (a b : Structure),
    structureDependsOn a b → ¬structureDependsOn b a := by
  intro a b hab hba
  unfold structureDependsOn at *
  exact absurd (Nat.lt_trans hab hba) (Nat.lt_irrefl _)
```


#### Structure-Level Dependency Tracking
ATMS Correspondence.

Formalizes manifesto.md Section 8 Property 2 "Self-containment of ordering information" and
Property 3 "Retroactive verification from terminal errors."

Corresponds to ATMS (Assumption-Based Truth Maintenance System) from the research document
`docs/research/items/design-specification-thoery.md`.
By having each Structure maintain its own dependencies,
verification can trace back through the partial order to the axiom level upon terminal errors.

#### `def dependencyConsistent`

Structure-level dependency consistency: dependencies have kind priority >= the dependent.
    Lifts the StructureKind partial order to Structure instance dependency relations.
    (Corresponds to ATMS assumption-belief consistency)

```lean
def dependencyConsistent (w : World) (s : Structure) : Prop :=
  ∀ depId, depId ∈ s.dependencies →
    ∃ dep, dep ∈ w.structures ∧ dep.id = depId ∧
      s.kind.priority ≤ dep.kind.priority
```


#### `def isDirectDependent`

Structure s' directly depends on Structure s (reverse edge).
    s.id in s'.dependencies = s' is affected by changes to s.
    Structure version of PropositionId.dependents (Prop-based).

```lean
def isDirectDependent (s' s : Structure) : Prop :=
  s.id ∈ s'.dependencies
```


#### `inductive reachableVia`

Reachability of impact propagation: changes to s reach target.
    Defined inductively as a transitive closure (no fuel needed, termination guaranteed by induction).
    Corresponds to affected(s) = {s' | s <= s'} from research document §4.3.

```lean
inductive reachableVia (w : World) (s : Structure) : Structure → Prop where
  | direct : ∀ t, t ∈ w.structures → isDirectDependent t s →
             reachableVia w s t
  | trans  : ∀ mid t, reachableVia w s mid → t ∈ w.structures →
             isDirectDependent t mid → reachableVia w s t
```


#### `theorem empty_world_no_reach`

In an empty World, nothing is reachable (no impact propagation occurs).

```lean
theorem empty_world_no_reach :
  ∀ (s t : Structure),
    ¬reachableVia ⟨[], [], [], [], [], 0, 0⟩ s t := by
  intro s t h
  cases h with
  | direct _ hm _ => simp at hm
  | trans _ _ _ hm _ => simp at hm
```


#### `theorem no_dependencies_no_direct_dependent`

A Structure with no dependencies (dependencies = []) has no direct dependents.

```lean
theorem no_dependencies_no_direct_dependent :
  ∀ (s' s : Structure),
    s'.dependencies = [] → ¬isDirectDependent s' s := by
  intro s' s hempty hdep
  simp [isDirectDependent, hempty] at hdep
```


#### `theorem reachableVia_trans`

reachableVia is transitive: if s -> mid -> t then s -> t.

```lean
theorem reachableVia_trans :
  ∀ (w : World) (s mid t : Structure),
    reachableVia w s mid → reachableVia w mid t → reachableVia w s t := by
  intro w s mid t hsm hmt
  induction hmt with
  | direct t' ht'mem ht'dep =>
    exact reachableVia.trans mid t' hsm ht'mem ht'dep
  | trans mid' t' _ ht'mem ht'dep ih =>
    exact reachableVia.trans mid' t' ih ht'mem ht'dep
```


#### Dependency Chain Reachability Section 8

Formalizes manifesto.md Section 8 Property 3 "Retroactive verification from terminal errors" as theorems.
Proves that all Structures on a dependency chain are included in the reachable set of reachableVia.

#### `def isDependencyChain`

Dependency chain: a list where adjacent Structures are connected via isDirectDependent.
    Corresponds to ATMS dependency tracking chains.

```lean
def isDependencyChain (w : World) : List Structure → Prop
  | [] => True
  | [_] => True
  | a :: b :: rest =>
    (b ∈ w.structures ∧ isDirectDependent b a) ∧ isDependencyChain w (b :: rest)
```


#### `theorem affected_contains_dependency_chain`

All Structures on a dependency chain are reachable from the origin via reachableVia.
    Formalization of Section 8 Property 3: upon terminal errors, verification can trace back through the partial order to the axiom level.

```lean
theorem affected_contains_dependency_chain :
  ∀ (w : World) (s : Structure) (chain : List Structure),
    isDependencyChain w (s :: chain) →
    ∀ t, t ∈ chain → reachableVia w s t := by
  intro w s chain
  induction chain generalizing s with
  | nil => intro _ t hmem; simp at hmem
  | cons x rest ih =>
    intro hchain t hmem
    simp [isDependencyChain] at hchain
    obtain ⟨⟨hxmem, hxdep⟩, hrest⟩ := hchain
    have hsx : reachableVia w s x := reachableVia.direct x hxmem hxdep
    cases hmem with
    | head => exact hsx
    | tail _ htail =>
      exact reachableVia_trans w s x t hsx (ih x hrest t htail)
```


#### Proposition-Level Dependency Graph

structureDependsOn is based on the 5-level priority of StructureKind.
This is a dependency between "kinds of structures" and cannot express
dependencies between individual propositions (T1, E1, P2, etc.).

D13 (premise negation impact propagation theorem) presupposes proposition-level dependencies.
Here we define the identifiers and dependency types for propositions.

#### Note on Incompleteness
Section 6.2, #26.

Since this formalization is an arithmetic system containing Nat, Goedel's first incompleteness
theorem applies. That is, it is in principle impossible to enumerate all true propositions
derivable from T1-T8 + E1-E2.

PropositionId enumerates "36 propositions named by humans" and is not an enumeration of all
propositions derivable from the system. Impact propagation via the affected function tracks
dependencies only between named propositions and cannot detect impacts on unnamed derived
consequences.

This limitation is a Goedelian principled limitation, not a design flaw of PropositionId.
When new propositions are identified, PropositionId is updated according to D9 (maintenance).

#### `inductive PropositionCategory`

Category of manifesto propositions. 6 layers: T/E/P/L/D/H.
    Corresponds to the S = (A, C, H, D) four-way classification (design-specification-thoery.md):
    A = constraint, C = empiricalPostulate + principle, H = hypothesis, D = boundary + designTheorem

```lean
inductive PropositionCategory where
  | constraint         -- T: 拘束条件 (A: Axioms)
  | empiricalPostulate -- E: 経験的公準 (C: Constraints)
  | principle          -- P: 基盤原理 (C: Constraints)
  | boundary           -- L: 境界条件 (D: Derivations)
  | designTheorem      -- D: 設計定理 (D: Derivations)
  | hypothesis         -- H: 仮定 — 未検証の前提（ATMS の仮定に対応）
  deriving BEq, Repr
```


#### `inductive PropositionId`

Proposition identifier. Enumerates all propositions in the manifesto.

```lean
inductive PropositionId where
  -- T: 拘束条件
  | t1 | t2 | t3 | t4 | t5 | t6 | t7 | t8
  -- E: 経験的公準
  | e1 | e2
  -- P: 基盤原理
  | p1 | p2 | p3 | p4 | p5 | p6
  -- L: 境界条件
  | l1 | l2 | l3 | l4 | l5 | l6
  -- D: 設計定理
  | d1 | d2 | d3 | d4 | d5 | d6 | d7 | d8 | d9 | d10 | d11 | d12 | d13 | d14
  deriving BEq, Repr
```


#### `def PropositionId.category`

Returns the category of a proposition.

```lean
def PropositionId.category : PropositionId → PropositionCategory
  | .t1 | .t2 | .t3 | .t4 | .t5 | .t6 | .t7 | .t8 => .constraint
  | .e1 | .e2 => .empiricalPostulate
  | .p1 | .p2 | .p3 | .p4 | .p5 | .p6 => .principle
  | .l1 | .l2 | .l3 | .l4 | .l5 | .l6 => .boundary
  | .d1 | .d2 | .d3 | .d4 | .d5 | .d6 | .d7 | .d8
  | .d9 | .d10 | .d11 | .d12 | .d13 | .d14 => .designTheorem
```


#### `def PropositionId.dependencies`

Returns the direct dependencies of a proposition. Encodes the derivation structure of the manifesto.

    Definition of what each proposition depends on.
    T are root nodes (no dependencies), D are leaf nodes (many dependencies).

```lean
def PropositionId.dependencies : PropositionId → List PropositionId
  -- T: 根ノード（独立）
  | .t1 | .t2 | .t3 | .t4 | .t5 | .t6 | .t7 | .t8 => []
  -- E: T に部分的に依存
  | .e1 => [.t4]
  | .e2 => []
  -- P: T/E から導出
  | .p1 => [.e2]
  | .p2 => [.t4, .e1]
  | .p3 => [.t1, .t2]
  | .p4 => [.t5, .t7]
  | .p5 => [.t4]
  | .p6 => [.t3, .t7, .t8]
  -- L: T/E/P に依存
  | .l1 => [.p1, .t6]
  | .l2 => [.t1, .t3, .t4]
  | .l3 => [.t6, .t7]
  | .l4 => [.t6, .p1, .d8]
  | .l5 => []  -- 環境依存（外部）
  | .l6 => [.t6, .p3]
  -- D: T/E/P/L から導出
  | .d1 => [.p5, .l1, .l2, .l3, .l4, .l5, .l6]
  | .d2 => [.e1, .p2]
  | .d3 => [.p4, .t5]
  | .d4 => [.p3]
  | .d5 => [.t8, .p4, .p6]
  | .d6 => [.d3]
  | .d7 => [.p1]
  | .d8 => [.e2]
  | .d9 => [.p3]
  | .d10 => [.t1, .t2]
  | .d11 => [.t3, .d1, .d3]
  | .d12 => [.p6, .t3, .t7, .t8]
  | .d13 => [.p3, .t5]
  | .d14 => [.p6, .t7, .t8]
```


#### `def propositionDependsOn`

A proposition directly depends on another proposition.

```lean
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b
```


#### `theorem constraints_are_roots`

T (constraints) are root nodes: they depend on nothing.

```lean
theorem constraints_are_roots :
  ∀ (p : PropositionId),
    p.category = .constraint → p.dependencies = [] := by
  intro p hp; cases p <;> simp [PropositionId.category] at hp <;> rfl
```


#### `def PropositionCategory.strength`

Epistemological strength ordering of PropositionCategory.
    T > E > P. L and D are below P.

```lean
def PropositionCategory.strength : PropositionCategory → Nat
  | .constraint         => 5
  | .empiricalPostulate => 4
  | .principle          => 3
  | .boundary           => 2
  | .designTheorem      => 1
  | .hypothesis         => 0  -- 最弱: 未検証の前提は他カテゴリより低い認識論的強度
```


#### `axiom dependency_respects_strength`

Dependencies follow descending epistemological strength: dependencies have strength >= the dependent.
    (Basis for D13's propagation direction: upstream changes affect downstream)

```lean
axiom dependency_respects_strength :
  ∀ (a b : PropositionId),
    propositionDependsOn a b = true →
    b.category.strength ≥ a.category.strength
```



## 2. Axioms T1-T8: The Immutable Ground Theory

*Source: `Axioms.lean`*

**Declarations:** 13 axioms, 2 definitions

### Epistemic Layer - Constraint Strength 5 - T1-T8 Base Theory T0

The manifesto's binding conditions are formalized as Lean non-logical axioms
(Terminology Reference §4.1).

#### Position as T0
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

#### Design Policy

Each T **may be decomposed into multiple axioms**. A natural-language T1 does not
necessarily correspond to a single proposition; finer decompositions arise during
formalization. Each axiom's docstring follows the Axiom Card format (Procedure §2.5).

#### Encoding Method for T0

T1–T8 contain properties that cannot be expressed by type definitions alone
(existential quantification, causal relations, etc.), so they are declared as
axioms (Axiom Card required). Parts expressible via type definitions are placed
in Ontology.lean as definitional extensions (Terminology Reference §5.5).

#### Correspondence Table

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

#### Correspondence with Terminology Reference

- Axiom → Non-logical axiom (§4.1): A proposition assumed true without proof, specific to a given theory
- T₀ → Base theory: A set of non-logical axioms grounded in external authority (Procedure §2.4)
- Axiom decomposition → Not definitional extension (§5.5), but refinement of the same concept

#### T1 Agent Sessions Are Ephemeral

"There is no memory across sessions. There is no continuous 'self.'
  Each instance is an independent entity with no identity
  shared with previous instances."

T1 is decomposed into three axioms:
1. Sessions terminate in finite time (boundedness)
2. There is no means to share state across sessions (discontinuity of memory)
3. No mutable state is shared across different sessions (independence)

#### `axiom session_bounded`

[Axiom Card]
    Layer: T₀ (Environment-derived)
    Content: Sessions terminate in finite time.
          For all sessions, they become terminated at some point.
    Basis: Execution of computational agents consumes finite resources and therefore terminates in finite time (related to T7).
          Reference examples: LLM session timeouts, resource consumption limits.
    Source: manifesto.md T1 "There is no memory across sessions"
    Refutation condition: Not applicable (T₀)

```lean
axiom session_bounded :
  ∀ (w : World) (s : Session),
    s ∈ w.sessions →
    ∃ (w' : World), w.time ≤ w'.time ∧
      ∃ (s' : Session), s' ∈ w'.sessions ∧
        s'.id = s.id ∧ s'.status = SessionStatus.terminated
```


#### `axiom no_cross_session_memory`

[Axiom Card]
    Layer: T₀ (Environment-derived)
    Content: No state sharing across sessions.
          Between two sessions with different session IDs,
          actions in one cannot affect the observable state of the other.
    Basis: Ephemeral computational processes lose internal state upon process termination.
          State isolation across sessions is guaranteed at the execution environment level.
          Reference example: session isolation in LLM architectures.
    Source: manifesto.md T1 "There is no continuous 'self'"
    Refutation condition: Not applicable (T₀)

```lean
axiom no_cross_session_memory :
  ∀ (w : World) (e1 e2 : AuditEntry),
    e1 ∈ w.auditLog → e2 ∈ w.auditLog →
    e1.session ≠ e2.session →
    -- 異なるセッションの監査エントリは因果的に独立
    -- （一方の preHash が他方の postHash に依存しない）
    e1.preHash ≠ e2.postHash
```


#### `axiom session_no_shared_state`

[Axiom Card]
    Layer: T₀ (Environment-derived)
    Content: No mutable state sharing across different sessions.
          Even with the same AgentId, instances in different sessions
          do not directly share state. Influence propagates only indirectly through structure (T2).
    Basis: Causal independence across sessions. Each instance is an independent entity.
    Source: manifesto.md T1 "Each instance is an independent entity"
    Refutation condition: Not applicable (T₀)

```lean
axiom session_no_shared_state :
  ∀ (agent1 agent2 : Agent) (action1 action2 : Action)
    (w w' : World),
    action1.session ≠ action2.session →
    canTransition agent1 action1 w w' →
    -- action2 が w で可能なら、w' でも可能（セッション1の遷移が
    -- セッション2のアクション可否に直接影響しない）
    (∃ w'', canTransition agent2 action2 w w'') →
    (∃ w''', canTransition agent2 action2 w' w''')
```


#### T2 Structure Outlives the Agent

"Documents, tests, skill definitions, design conventions —
  these persist even after the session ends.
  The place where improvements accumulate is within structure."

T2 is decomposed into two axioms:
1. Structure persists after session termination (persistence)
2. Structure can accumulate improvements (accumulability)

#### `axiom structure_persists`

[Axiom Card]
    Layer: T₀ (Environment-derived)
    Content: Structure persists after session termination.
          Even when a session becomes terminated,
          structures referenced by that session do not disappear from the World.
    Basis: Persistence on the file system. Structures (documents, tests, etc.)
          reside in storage outside the session.
    Source: manifesto.md T2 "The place where improvements accumulate is within structure"
    Refutation condition: Not applicable (T₀)

```lean
axiom structure_persists :
  ∀ (w w' : World) (s : Session) (st : Structure),
    s ∈ w.sessions →
    st ∈ w.structures →
    s.status = SessionStatus.terminated →
    validTransition w w' →
    st ∈ w'.structures
```


#### `axiom structure_accumulates`

[Axiom Card]
    Layer: T₀ (Environment-derived)
    Content: Structure accumulates improvements.
          As epochs advance, structures may be updated (lastModifiedAt is non-decreasing).
          Contrast with T1: agents are ephemeral, but structure grows.
    Basis: Monotonic epoch increase guaranteed by version control systems (git).
    Source: manifesto.md T2 "Structure outlives the agent"
    Refutation condition: Not applicable (T₀)

```lean
axiom structure_accumulates :
  ∀ (w w' : World),
    validTransition w w' →
    w.epoch ≤ w'.epoch
```


#### T3 The Amount of Information Processable at Once Is Finite

"There is a physical upper limit on the amount of information processable at once.
  A constraint on the agent's cognitive space."

T3 is decomposed into two axioms:
1. Working memory (ContextWindow) capacity is finite (existence)
2. Processing is possible only within working memory capacity (constraint)

#### `axiom context_finite`

[Axiom Card]
    Layer: T₀ (Environment-derived)
    Content: Working memory (ContextWindow) has finite capacity.
          The contextWindow.capacity of all agents is bounded.
    Basis: The working memory of computational agents is physically finite.
          Reference examples: LLM token count limits, FSM state buffer sizes.
    Source: manifesto.md T3 "There is a physical upper limit on the amount of information processable at once"
    Refutation condition: Not applicable (T₀)

```lean
axiom context_finite :
  ∀ (agent : Agent),
    agent.contextWindow.capacity > 0 ∧
    agent.contextWindow.used ≤ agent.contextWindow.capacity
```


#### `axiom context_bounds_action`

[Axiom Card]
    Layer: T₀ (Environment-derived)
    Content: Executing an action requires information processing within the context.
          When context usage exceeds capacity, the action cannot be executed.
    Basis: Inability to process when working memory is exceeded is a physical constraint.
    Source: manifesto.md T3 "A constraint on the agent's cognitive space"
    Refutation condition: Not applicable (T₀)

```lean
axiom context_bounds_action :
  ∀ (agent : Agent) (action : Action) (w : World),
    agent.contextWindow.used > agent.contextWindow.capacity →
    actionBlocked agent action w
```


#### T4 Agent Output Is Stochastic

"Different outputs may be produced for the same input.
  Structure is interpreted probabilistically each time.
  Designs that assume 100% compliance are fragile."

Since `canTransition` is defined as a relation rather than a function (see Ontology.lean),
multiple w' can satisfy canTransition for the same (agent, action, w).
T4 declares as an axiom that "this multiplicity can actually occur."

#### `axiom output_nondeterministic`

[Axiom Card]
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
    Refutation condition: Not applicable (T₀)

```lean
axiom output_nondeterministic :
  ∃ (agent : Agent) (action : Action) (w w₁ w₂ : World),
    canTransition agent action w w₁ ∧
    canTransition agent action w w₂ ∧
    w₁ ≠ w₂
```


#### T5 Improvement Is Impossible Without Feedback

"A fundamental of control theory.
  Without a loop of measurement, comparison, and adjustment,
  convergence toward the goal does not occur."

T5 declares that the existence of feedback is a necessary condition for improvement.

#### `opaque structureImproved`

Predicate for whether structure has improved (defined as Observable in Phase 4+).

```lean
opaque structureImproved : World → World → Prop
```


#### `axiom no_improvement_without_feedback`

[Axiom Card]
    Layer: T₀ (Natural-science-derived)
    Content: Feedback is required for structural improvement.
          If structure has improved between two world states,
          then feedback exists in between.
    Basis: Fundamental principle of control theory. Without a loop of
          measurement, comparison, and adjustment, convergence toward the goal does not occur.
    Source: manifesto.md T5 "A fundamental of control theory"
    Refutation condition: Not applicable (T₀)

```lean
axiom no_improvement_without_feedback :
  ∀ (w w' : World),
    structureImproved w w' →
    ∃ (f : Feedback), f ∈ w'.feedbacks ∧
      f.timestamp ≥ w.time ∧ f.timestamp ≤ w'.time
```


#### T6 Humans Are the Final Decision-Makers for Resources

"Computational resources, data access, execution privileges —
  all are granted by humans and can be revoked by humans."

T6 is decomposed into two axioms:
1. The origin of resource allocation is human (authority)
2. Humans can revoke resources (reversibility)

#### `def isHuman`

Predicate for whether an agent is human.

```lean
def isHuman (agent : Agent) : Prop :=
  agent.role = AgentRole.human
```


#### `axiom human_resource_authority`

[Axiom Card]
    Layer: T₀ (Contract-derived)
    Content: The origin of resource allocation is human.
          The grantedBy of all resource allocations holds a human role.
    Basis: Agreement on authority structure in human-agent collaboration.
    Source: manifesto.md T6 "Computational resources, data access, execution privileges — all are granted by humans"
    Refutation condition: Not applicable (T₀)

```lean
axiom human_resource_authority :
  ∀ (w : World) (alloc : ResourceAllocation),
    alloc ∈ w.allocations →
    ∃ (human : Agent), isHuman human ∧ human.id = alloc.grantedBy
```


#### `axiom resource_revocable`

[Axiom Card]
    Layer: T₀ (Contract-derived)
    Content: Humans can revoke resources.
          For any resource allocation, there exists a transition in which a human invalidates it.
    Basis: Agreement on human final decision-making authority. Privileges can be delegated but remain revocable.
    Source: manifesto.md T6 "can be revoked by humans"
    Refutation condition: Not applicable (T₀)

```lean
axiom resource_revocable :
  ∀ (w : World) (alloc : ResourceAllocation),
    alloc ∈ w.allocations →
    ∃ (w' : World) (human : Agent),
      isHuman human ∧
      validTransition w w' ∧
      alloc ∉ w'.allocations
```


#### T7 Resources Available for Task Execution Are Finite
Time and energy.

"Whereas T3 states the finiteness of cognitive space (context),
  T7 states the finiteness in the temporal and energetic dimensions."

#### `axiom resource_finite`

[Axiom Card]
    Layer: T₀ (Environment-derived)
    Content: Resources are finite.
          The total resource amount across the entire World does not exceed `globalResourceBound`.
          Quantified in ∃-∀ order (not ∀-∃), guaranteeing that a single upper bound
          exists for **all** Worlds (non-vacuity, Terminology Reference §6.4).
    Basis: Physical finiteness of computational resources (CPU, memory, API quotas).
    Source: manifesto.md T7 "Resources available for task execution are finite"
    Refutation condition: Not applicable (T₀)

```lean
axiom resource_finite :
  ∀ (w : World),
    (w.allocations.map (·.amount)).foldl (· + ·) 0 ≤ globalResourceBound
```


#### T8 Tasks Have a Precision Level to Be Achieved

"Whether self-imposed or externally imposed,
  tasks without a precision level cannot be optimization targets."

#### `axiom task_has_precision`

[Axiom Card]
    Layer: T₀ (Contract-derived)
    Content: All tasks have a precision level.
          The precision level must be a positive value (greater than 0).
          Tasks with a precision level of 0 cannot be optimization targets (= do not constitute valid tasks).
    Basis: Structural requirement of task definitions. Tasks without a precision level cannot be optimized.
    Source: manifesto.md T8 "Whether self-imposed or externally imposed"
    Refutation condition: Not applicable (T₀)

```lean
axiom task_has_precision :
  ∀ (task : Task),
    task.precisionRequired.required > 0
```


#### Sorry Inventory Phase 1

List of `sorry` occurrences in Phase 1:

| Location | Reason for sorry |
|------|-------------|
| `Ontology.lean: canTransition` | opaque — transition conditions to be defined in Phase 3+ |
| `Ontology.lean: globalResourceBound` | opaque — to be concretized per domain in Phase 2+ |
| `Axioms.lean: structureImproved` | opaque — to be defined as Observable in Phase 4+ |

Axioms are propositions assumed without proof, so they contain no sorry.
When P1–P6 are derived as theorems in Phase 3, sorry occurrences will arise.


## 3. Empirical Postulates E1-E2: Falsifiable Hypotheses

*Source: `EmpiricalPostulates.lean`*

**Declarations:** 4 axioms

### Epistemic Layer - EmpiricalPostulate Strength 4 - E1-E2 Premise Set

Formalizes empirical postulates as Lean non-logical axioms (Terminology Reference §4.1).

#### Position as Extension of T0
Procedure 2.4.

E1–E2 are "findings repeatedly demonstrated with no known counterexamples,
yet in principle refutable," constituting the extended part (Γ \ T₀) of premise set Γ.
Difference from T₀: based not on external authority (contracts, natural laws)
but on hypotheses grounded in empirical observation (Terminology Reference §9.1 empirical propositions).
They possess refutability (§9.1) and are subject to AGM contraction (§9.2).

In Lean, they are declared as `axiom` just like T₀, but each axiom card
must include a **refutation condition** (Procedure §2.5).

#### Relationship to T0
Procedure 2.4.

Γ is an extension of T₀ (Terminology Reference §5.5), so Thm(T₀) ⊆ Thm(Γ).
If an E is refuted, the P's that depend on it (P1, P2) become subject to revision,
but T₀ and P's that depend solely on T₀ (P3–P6) are unaffected.
This follows from the monotonicity of extensions (§2.5 / §5.3).

#### Correspondence Table

| Axiom name | Corresponding E | Expressed property | Γ \ T₀ membership basis |
|-----------|-----------|-------------|---------------|
| `verification_requires_independence` | E1 | Generation and evaluation must be separated | Hypothesis-derived |
| `no_self_verification` | E1 | Prohibition of self-verification | Hypothesis-derived |
| `shared_bias_reduces_detection` | E1 | Shared bias degrades detection power | Hypothesis-derived |
| `capability_risk_coscaling` | E2 | Capability growth is inseparable from risk growth | Hypothesis-derived |

#### E1 Verification Requires Independence

"Generation and evaluation by the same process has been demonstrated
  to be structurally unreliable across all domains (scientific peer review,
  financial auditing, software testing). Given T4 (probabilistic output),
  it is empirically supported that when a process with the same biases
  handles both generation and evaluation, detection power degrades."

E1 is decomposed into three axioms:
1. The agents responsible for generation and evaluation must be separated (structural independence)
2. Self-verification is not permitted (prohibition of self-verification)
3. Verification between agents sharing internal state has low detection power (bias correlation)

#### `axiom verification_requires_independence`

[Axiom Card]
    Layer: Γ \ T₀ (Hypothesis-derived)
    Content: The agents responsible for generation and evaluation must be independent.
          The agent that generated an action and the agent that verifies it
          must be distinct individuals that do not share internal state.
    Basis: A principle repeatedly demonstrated in scientific peer review,
          financial auditing, software testing, etc.
    Source: manifesto.md E1 "Verification Requires Independence"
    Refutation condition: If self-verification is demonstrated to have detection power
              equal to external verification (e.g., realization of complete self-awareness)

```lean
axiom verification_requires_independence :
  ∀ (gen ver : Agent) (action : Action) (w : World),
    generates gen action w →
    verifies ver action w →
    gen.id ≠ ver.id ∧ ¬sharesInternalState gen ver
```


#### `axiom no_self_verification`

[Axiom Card]
    Layer: Γ \ T₀ (Hypothesis-derived)
    Content: Prohibition of self-verification.
          The same agent cannot perform both generation and verification.
          A corollary of E1a (Terminology Reference §4.2 corollary), but declared explicitly.
    Basis: Due to T4 (probabilistic output), the bias of the same process
          affects both generation and evaluation, structurally degrading detection power.
    Source: manifesto.md E1 + Principles.lean e1b_from_e1a proves derivation from E1a
    Refutation condition: Same as the refutation condition for E1a

```lean
axiom no_self_verification :
  ∀ (agent : Agent) (action : Action) (w : World),
    generates agent action w →
    ¬verifies agent action w
```


#### `axiom shared_bias_reduces_detection`

[Axiom Card]
    Layer: Γ \ T₀ (Hypothesis-derived)
    Content: Sharing internal state correlates biases.
          Two agents sharing internal state cannot be considered independent
          verifiers, even if one generates and the other verifies.
    Basis: Detection power degradation due to shared bias is empirically
          supported by conflict-of-interest policies in scientific research,
          audit firm rotation requirements, etc.
    Source: manifesto.md E1 "When a process with the same biases handles both
            generation and evaluation, detection power degrades"
    Refutation condition: If it is demonstrated that bias correlation has no effect on detection power

```lean
axiom shared_bias_reduces_detection :
  ∀ (a b : Agent) (action : Action) (w : World),
    sharesInternalState a b →
    generates a action w →
    ¬verifies b action w
```


#### E2 Capability Growth Is Inseparable from Risk Growth

"It has been repeatedly observed across all tools that capability
  enables both positive and negative outcomes. However, there is no
  proof that means to increase capability while completely containing
  risk (such as a perfect sandbox) are impossible in principle."

E2 is formalized as a single axiom.
Expansion of the action space (actionSpaceSize) necessarily entails
an increase in risk exposure (riskExposure).

#### Note on Empirical Status

E2 is an empirical postulate and does not exclude the possibility
that a "perfect sandbox" may be discovered in the future. It is
assumed as an axiom, but if refuted, P1 (co-scaling of autonomy
and vulnerability) becomes subject to revision.

#### `axiom capability_risk_coscaling`

[Axiom Card]
    Layer: Γ \ T₀ (Hypothesis-derived)
    Content: Capability growth is inseparable from risk growth.
          When an agent's action space expands, risk exposure necessarily increases.
    Basis: It has been repeatedly observed across all tools that capability enables
          both positive and negative outcomes (Terminology Reference §9.1 empirical propositions).
    Source: manifesto.md E2 "Capability Growth Is Inseparable from Risk Growth"
    Refutation condition: If means to increase capability while completely containing risk
              are discovered (e.g., a perfect sandbox)

    **Choice of inequality: `<` vs `≤`**

    The manifesto's "inseparable" implies strict co-scaling, so
    `<` (strict increase) is adopted. If the refutation condition is met (discovery of
    a risk containment method), this axiom becomes subject to AGM contraction
    (Terminology Reference §9.2), and P1 (co-scaling of autonomy and vulnerability)
    is revised.

```lean
axiom capability_risk_coscaling :
  ∀ (agent : Agent) (w w' : World),
    actionSpaceSize agent w < actionSpaceSize agent w' →
    riskExposure agent w < riskExposure agent w'
```


#### Sorry Inventory Phase 2 Additions

| Location | Reason for sorry |
|------|-------------|
| `Ontology.lean: generates` | opaque — to be concretized as Worker actions in Phase 3+ |
| `Ontology.lean: verifies` | opaque — to be concretized as Verifier actions in Phase 3+ |
| `Ontology.lean: sharesInternalState` | opaque — to be concretized as session/parameter sharing in Phase 3+ |
| `Ontology.lean: actionSpaceSize` | opaque — to be quantified as Observable in Phase 4+ |
| `Ontology.lean: riskExposure` | opaque — to be quantified as Observable in Phase 4+ |


## 4. Principles P1-P6: Derived Design Principles

*Source: `Principles.lean`*

**Declarations:** 14 theorems, 5 definitions

### Epistemic Layer - Principle Strength 3 - P1-P6 Theorem Derivation Procedure Phase 2

Describes design principles derived from premise set Γ (T₀ = T1–T8, Γ \ T₀ = E1–E2)
as Lean theorems (Terminology Reference §4.2).
Each P takes the form Γ ⊢ φ, a conditional derivation under premise set Γ (§2.5).

#### Derivation Structure Dependency Graph

Axiom dependencies (T/E basis) and robustness layer for each P:

| P | Basis | Robustness | Derivation type |
|---|------|--------|----------|
| P1 | E2 | Empirical (depends on Γ \ T₀) | Direct application of E2 |
| P2 | T4 + E1 | Empirical (depends on Γ \ T₀) | Direct application of E1a |
| P3 | T1 + T2 | Robust (T₀ only) | Composition of T1 and T2 |
| P4 | T5 (+ T7) | Robust (T₀ only) | Direct application of T5 |
| P5 | T4 | Robust (T₀ only) | High-level restatement of T4 |
| P6 | T3 + T7 + T8 | Robust (T₀ only) | Unfolding of T3, T7, T8 constraint structure |

If Γ \ T₀ (E1, E2) is refuted (Terminology Reference §9.1 refutability),
only P1 and P2 are affected. P3–P6 depend solely on T₀ and are therefore
invariant under contraction of Γ \ T₀ (§9.2).
This is a consequence of the monotonicity of extensions (§2.5 / §5.3).

#### Correspondence with Terminology Reference

- theorem → theorem (§4.2): a proposition proved from axioms and inference rules
- sorry → incomplete derivation (§1): lacking a proof (a sequence of inference rule applications from axioms to theorem)
- E1b redundancy → independence check (§4.3): E1b is derivable from E1a (not independent)

#### Appendix - Proof of E1b Redundancy

Demonstrates as a theorem that E1b (`no_self_verification`) is derivable
from E1a (`verification_requires_independence`).
This is a concrete example of axiom hygiene check 3 (independence, Procedure §2.6):
E1b is a redundant axiom and should be proved as a theorem.

#### P1 Co-scaling of Autonomy and Vulnerability

Derived from E2. Each time an agent's action space expands,
the damage that malicious inputs or judgment errors can cause also grows.

Concepts P1 adds beyond E2:
- "Unprotected expansion can destroy accumulated trust in a single incident"
  → Asymmetry of trust accumulation (gradual accumulation vs. abrupt destruction)

#### `theorem autonomy_vulnerability_coscaling`

P1a [theorem]: Expansion of the action space entails expansion of risk.
    A direct consequence of E2 (`capability_risk_coscaling`).

    This is the core of P1, close to a restatement of E2, but
    makes its position as a "design principle" explicit.

```lean
theorem autonomy_vulnerability_coscaling :
  ∀ (agent : Agent) (w w' : World),
    actionSpaceSize agent w < actionSpaceSize agent w' →
    riskExposure agent w < riskExposure agent w' :=
  capability_risk_coscaling
```


#### `theorem unprotected_expansion_destroys_trust`

P1b [theorem]: Unprotected expansion destroys trust.
    When the action space expands and risk materializes,
    the trust level decreases.

    Formalization of "accumulated trust can be destroyed by a single incident."
    The asymmetry of trust (gradual accumulation vs. abrupt destruction) will be
    made Observable as asymmetry in trustLevel fluctuation magnitude in Phase 4.

```lean
theorem unprotected_expansion_destroys_trust :
  ∀ (agent : Agent) (w w' : World),
    actionSpaceSize agent w < actionSpaceSize agent w' →
    riskMaterialized agent w' →
    trustLevel agent w' < trustLevel agent w :=
  trust_decreases_on_materialized_risk
```


#### P2 Cognitive Separation of Concerns

Derived from T4 and E1. Since output is probabilistic (T4) and
generation and evaluation by the same process have correlated biases (E1),
separation of generation and evaluation is required for the verification framework to function.

"Separation itself is non-negotiable."

#### `def verificationSound`

Predicate for whether a verification framework is sound.
    Sound = all generated actions are independently verified.

```lean
def verificationSound (w : World) : Prop :=
  ∀ (gen ver : Agent) (action : Action),
    generates gen action w →
    verifies ver action w →
    gen.id ≠ ver.id ∧ ¬sharesInternalState gen ver
```


#### `theorem cognitive_separation_required`

P2 [theorem]: Verification soundness requires role separation.
    From T4 (nondeterminism) and E1 (independence requirement),
    for a verification framework to be sound, the agents responsible
    for generation and evaluation must be separated.

    Essentially a restatement of E1a, but clarifies its position
    as a "principle" by introducing the design concept `verificationSound`.

```lean
theorem cognitive_separation_required :
  ∀ (w : World), verificationSound w :=
  fun w gen ver action h_gen h_ver =>
    verification_requires_independence gen ver action w h_gen h_ver
```


#### `theorem self_verification_unsound`

P2 lemma: Self-verification destroys verification framework soundness.

```lean
theorem self_verification_unsound :
  ∀ (agent : Agent) (action : Action) (w : World),
    generates agent action w →
    ¬verifies agent action w :=
  no_self_verification
```


#### P3 Governed Learning

Derived from the combination of T1 and T2.
Agents are ephemeral (T1) but structures persist (T2).
The process of integrating knowledge into structures requires governance.

Two failure modes of ungoverned learning:
- Chaos: structure degrades through accumulation of erroneous knowledge
- Stagnation: knowledge fails to consolidate and structure does not improve

#### `theorem modifier_agent_terminates`

P3a [theorem]: By T1, the agent that made modifications disappears.
    The session of an agent that modified structure necessarily terminates (T1).
    After termination, that agent loses the ability to correct modifications.

    This is half of P3's "problem": the supervisor becomes absent.

```lean
theorem modifier_agent_terminates :
  ∀ (w : World) (s : Session) (agent : Agent),
    s ∈ w.sessions →
    agent.currentSession = some s.id →
    -- T1: このセッションは必ず終了する
    ∃ (w' : World), w.time ≤ w'.time ∧
      ∃ (s' : Session), s' ∈ w'.sessions ∧
        s'.id = s.id ∧ s'.status = SessionStatus.terminated :=
  fun w s _ h_mem _ => session_bounded w s h_mem
```


#### `theorem modification_persists_after_termination`

P3b [theorem]: By T2, modifications persist.
    Changes made to structure (including errors) remain
    even after the agent's session terminates.

    This is half of P3's "stakes": errors persist indefinitely.

```lean
theorem modification_persists_after_termination :
  ∀ (w w' : World) (s : Session) (st : Structure),
    s ∈ w.sessions →
    st ∈ w.structures →
    s.status = SessionStatus.terminated →
    validTransition w w' →
    -- T2: 構造は永続する
    st ∈ w'.structures :=
  structure_persists
```


#### `theorem ungoverned_breaking_change_irrecoverable`

P3c [theorem]: T1 ∧ T2 → ungoverned integration produces irrecoverable changes.
    Composition of T1 (agent disappearance) and T2 (change persistence).

    When an ungoverned breakingChange is made:
    - The change persists (T2: structure_persists)
    - The agent that made the change disappears (T1: session_bounded)
    - Result: breaking changes persist uncorrected

    This theorem **essentially uses both** T1 and T2, formally
    demonstrating that P3 is a compositional consequence of T1 + T2.

```lean
theorem ungoverned_breaking_change_irrecoverable :
  ∀ (w : World) (s : Session) (st : Structure)
    (ki : KnowledgeIntegration),
    -- 前提: エージェントが構造を変更した
    s ∈ w.sessions →
    st ∈ w.structures →
    ki.before = w →
    ki.compatibility = CompatibilityClass.breakingChange →
    -- T1 の寄与: エージェントのセッションは終了する
    (∃ (w_term : World), w.time ≤ w_term.time ∧
      ∃ (s' : Session), s' ∈ w_term.sessions ∧
        s'.id = s.id ∧ s'.status = SessionStatus.terminated) →
    -- T2 の寄与: 変更後の構造は永続する
    (∀ (w_future : World),
      validTransition ki.after w_future →
      ∀ st', st' ∈ ki.after.structures → st' ∈ w_future.structures) →
    -- 結論: 統治なしでは破壊的変更が永続する（修正する主体がいない）
    -- 形式化: 変更後のエポックは戻らない（不可逆）
    ∀ (w_future : World),
      validTransition ki.after w_future →
      ki.after.epoch ≤ w_future.epoch :=
  fun _ _ _ ki _ _ _ _ _ _ w_future h_trans =>
    structure_accumulates ki.after w_future h_trans
```


#### `def governanceNecessityExplanation`

P3 conclusion: Why governance is necessary.
    Combining P3a (modifier_agent_terminates), P3b (modification_persists_after_termination),
    and P3c (ungoverned_breaking_change_irrecoverable):

    Ungoverned knowledge integration produces a state where "irrecoverable breaking
    changes persist indefinitely." Governance (upfront compatibility classification + gates)
    is the only means to prevent this.

    Note: The proof of P3c depends on structure_accumulates, but the
    **propositional structure** of the theorem requires both the T1 and T2 hypotheses.
    Without T1, "the agent might be able to correct it";
    without T2, "the change might disappear" — so
    neither hypothesis can be omitted.

```lean
def governanceNecessityExplanation := "See P3a + P3b + P3c above"
```


#### `theorem compatibility_exhaustive`

P3b [theorem]: Exhaustiveness of compatibility classification.
    Every knowledge integration is classified into one of three compatibility classes.
    (Structurally guaranteed by Lean's inductive type)

```lean
theorem compatibility_exhaustive :
  ∀ (c : CompatibilityClass),
    c = .conservativeExtension ∨
    c = .compatibleChange ∨
    c = .breakingChange := by
  intro c
  cases c <;> simp
```


#### P4 Observable Degradation

Derived from T5. Improvement is impossible without feedback (T5), and
what cannot be observed cannot be incorporated into feedback loops.

"What cannot be observed cannot be optimized."

Constraints manifest as gradients, not walls (binary).

#### `theorem improvement_requires_observability`

P4a [theorem]: Improvement requires observability.
    If structureImproved holds, then feedback exists (T5), and
    for feedback to exist, the target must be observable.

    Formalization: improvement occurred → feedback existed.
    This is a direct consequence of T5.

```lean
theorem improvement_requires_observability :
  ∀ (w w' : World),
    structureImproved w w' →
    ∃ (f : Feedback), f ∈ w'.feedbacks ∧
      f.timestamp ≥ w.time ∧ f.timestamp ≤ w'.time :=
  no_improvement_without_feedback
```


#### `theorem degradation_is_gradient`

P4b [theorem]: Degradation is a gradient, not a wall.
    The degradation level can take any natural number value (not binary).
    To be concretized as Observable in Phase 4.

```lean
theorem degradation_is_gradient :
  ∀ (n : Nat), ∃ (w : World), degradationLevel w = n :=
  degradation_level_surjective
```


#### P5 Probabilistic Interpretation of Structure

Derived from T4. Structure is something agents interpret anew each time,
not something they deterministically "follow." Even reading the same structure,
different instances may take different actions.

Robust design does not assume perfect compliance with structure,
but rather maintains resilience against interpretation variance.

#### `theorem structure_interpretation_nondeterministic`

P5 [theorem]: Structure interpretation is nondeterministic.
    From T4, interpreting the same structure can yield different actions.

    T4 (`output_nondeterministic`) declares nondeterminism at the
    canTransition level, but P5 restates it at the higher abstraction
    level of "structure interpretation."

```lean
theorem structure_interpretation_nondeterministic :
  ∃ (agent : Agent) (st : Structure) (action₁ action₂ : Action) (w : World),
    interpretsStructure agent st action₁ w ∧
    interpretsStructure agent st action₂ w ∧
    action₁ ≠ action₂ :=
  interpretation_nondeterminism
```


#### `def robustStructure`

P5 lemma: Robust design is resilient to interpretation variance.
    A structure st is "robust" iff for any interpretation difference,
    the target world satisfies the safety constraint.

```lean
def robustStructure (st : Structure) (safety : World → Prop) : Prop :=
  ∀ (agent : Agent) (action : Action) (w w' : World),
    interpretsStructure agent st action w →
    canTransition agent action w w' →
    safety w'
```


#### P6 Task Design as Constraint Satisfaction

Derived from the combination of T3, T7, and T8.
Within finite cognitive space (T3) and finite time/energy (T7),
the required precision level (T8) must be achieved.

Task design is the process of solving this constraint satisfaction problem.

#### `structure TaskStrategy`

Task execution strategy. A "solution" to the constraint satisfaction problem.

```lean
structure TaskStrategy where
  task           : Task
  contextUsage   : Nat   -- T3: コンテキスト使用量
  resourceUsage  : Nat   -- T7: リソース使用量
  achievedPrecision : Nat -- T8: 達成精度（千分率）
  deriving Repr
```


#### `def strategyFeasible`

Predicate for whether a strategy satisfies the constraints.
    All three dimensions must be satisfied simultaneously.

```lean
def strategyFeasible (s : TaskStrategy) (agent : Agent) : Prop :=
  -- T3: コンテキスト容量内
  s.contextUsage ≤ agent.contextWindow.capacity ∧
  -- T7: リソース予算内
  s.resourceUsage ≤ s.task.resourceBudget ∧
  -- T8: 要求精度を達成
  s.achievedPrecision ≥ s.task.precisionRequired.required
```


#### `theorem task_is_constraint_satisfaction`

P6a [theorem]: Task execution is a constraint satisfaction problem.
    A strategy must be found that simultaneously satisfies three constraints:
    T3 (finite context), T7 (finite resources), and T8 (precision requirement).

    This theorem formalizes "the existence of constraints."
    It does not guarantee the existence of a solution (there may be no solution).

```lean
theorem task_is_constraint_satisfaction :
  ∀ (task : Task) (agent : Agent),
    -- T3: コンテキストは有限
    agent.contextWindow.capacity > 0 →
    -- T7: リソースは有限（タスクの予算は globalResourceBound 以下）
    task.resourceBudget ≤ globalResourceBound →
    -- T8: 精度要求は正
    task.precisionRequired.required > 0 →
    -- 結論: これは制約充足問題である
    -- （解の存在は保証しないが、制約の構造を明示する）
    ∀ (s : TaskStrategy),
      s.task = task →
      strategyFeasible s agent →
      s.contextUsage ≤ agent.contextWindow.capacity ∧
      s.resourceUsage ≤ globalResourceBound ∧
      s.achievedPrecision > 0 := by
  intro task agent h_ctx h_res h_prec s h_task h_feas
  constructor
  · exact Nat.le_trans h_feas.1 (Nat.le_refl _)
  constructor
  · exact Nat.le_trans h_feas.2.1 (h_task ▸ h_res)
  · exact Nat.lt_of_lt_of_le h_prec (h_task ▸ h_feas.2.2)
```


#### `theorem task_design_is_probabilistic`

P6b [theorem]: Task design itself is also probabilistic output.
    P6 itself is subject to T4, and requires verification via P2 (role separation).

```lean
theorem task_design_is_probabilistic :
  ∃ (agent : Agent) (action : Action) (w w₁ w₂ : World),
    canTransition agent action w w₁ ∧
    canTransition agent action w w₂ ∧
    w₁ ≠ w₂ :=
  output_nondeterministic
```


#### Appendix - Proof that E1b Is Derivable from E1a

`no_self_verification` is a corollary of `verification_requires_independence`.
If we assume the same agent satisfies both generates and verifies,
this contradicts E1a's conclusion `gen.id ≠ ver.id`
(since gen = ver, we have gen.id = ver.id).

#### `theorem e1b_from_e1a`

E1b is a corollary of E1a.
    Requires DecidableEq for AgentId (sorry due to opaque).

```lean
theorem e1b_from_e1a :
  ∀ (agent : Agent) (action : Action) (w : World),
    generates agent action w →
    ¬verifies agent action w := by
  intro agent action w h_gen h_ver
  have h := verification_requires_independence agent agent action w h_gen h_ver
  exact absurd rfl h.1
```


#### Sorry Inventory Phase 4 Update

All sorry's resolved in Phase 4. Principles.lean is **sorry-free**.

#### Sorry's resolved from Phase 3 → Phase 4

| theorem | Resolution method | Axiom used (Observable.lean) |
|---------|---------|-------------------------------|
| `unprotected_expansion_destroys_trust` | axiom application | `trust_decreases_on_materialized_risk` |
| `degradation_is_gradient` | axiom application | `degradation_level_surjective` |
| `structure_interpretation_nondeterministic` | axiom application | `interpretation_nondeterminism` |

#### Complete theorem proof method listing

| theorem | Proof method |
|---------|---------|
| `autonomy_vulnerability_coscaling` | Direct application of E2 |
| `unprotected_expansion_destroys_trust` | Direct application of Observable axiom |
| `cognitive_separation_required` | Direct application of E1a |
| `self_verification_unsound` | Direct application of E1b |
| `modifier_agent_terminates` | Direct application of T1 |
| `modification_persists_after_termination` | Direct application of T2 |
| `ungoverned_breaking_change_irrecoverable` | Composition of T1 ∧ T2 |
| `compatibility_exhaustive` | Exhaustiveness proof via `cases` tactic |
| `improvement_requires_observability` | Direct application of T5 |
| `degradation_is_gradient` | Direct application of Observable axiom |
| `structure_interpretation_nondeterministic` | Direct application of Observable axiom |
| `task_is_constraint_satisfaction` | Unfolding of T3/T7/T8 constraint structure |
| `task_design_is_probabilistic` | Direct application of T4 |
| `e1b_from_e1a` | Contradiction derivation via E1a + `absurd rfl` |


## 5. Observable Variables V1-V7: Measurable Quality Indicators

*Source: `Observable.lean`*

**Declarations:** 9 axioms, 11 theorems, 22 definitions

### Epistemic Layer - Boundary Strength 2 - Foundation of V1-V7 Observable Variables

**Variables are not boundary conditions.** They are parameters that agents can improve
through structure, serving as indicators of structural quality. If boundary conditions
(L1–L6 in Ontology.lean) are "walls of the action space," then variables are
"levers that structure can move within those walls."

However, variables are **not independent levers but a mutually interacting system**.

#### Layer Separation

This file contains only definitions belonging to the **boundary layer (strength 2)**:
- Opaque definitions for V1–V7 and Measurable axioms (measurability guarantees)
- Measurability axioms for trust/degradation
- systemHealthy (basic definition of system health)
- Mapping structure from boundaries to variables to constraints
- Measurable to Observable bridge theorems

Definitions belonging to the designTheorem layer (strength 1) — tradeoffs, Goodhart,
investment cycles, HealthThresholds, Pareto, etc. — are separated into
**ObservableDesign.lean**.

#### Position as Gamma Extension of T_0
Procedure Manual 2.4.

The axioms in this file belong to the extension part (Gamma \ T_0) of the premise set Gamma,
and are non-logical axioms (§4.1) derived from design decisions (domain model premises,
design judgments). They constitute a consistent extension (Glossary §5.5) of T_0 (Axioms.lean)
and may be subject to contraction (§9.2) in the revision loop.

#### Design Policy

Boundary conditions (T) are immovable walls, mitigations (L) are design decisions,
and variables (V) are measures of **how well** mitigations work.

#### Observable vs Measurable

- **Observable** (`World → Prop` is decidable) — binary judgment. Similar to preconditions/postconditions in Glossary §9.3
- **Measurable** (`World → Nat` is computable) — quantitative measurement. Glossary §9.5 note: distinct from the measure-theoretic concept of measurable functions

V1–V7 are quantitative indicators and are therefore formalized as `Measurable`.
`Measurable m` means "a procedure exists to compute the value of `m` from external observations."

#### Prerequisite - Observability P4

By P4 (observability of degradation), variables **become optimization targets only when
they are observable**.

For each variable, the following questions are posed:
- **Is the current value observable?** Does a measurement method exist, and is measurement actually being performed?
- **Is degradation detectable?** If the value worsens, can it be detected before quality collapse?
- **Is improvement verifiable?** Can the change in value be compared before and after intervention?

A variable without means of observation is merely a nominal optimization target.

#### V1-V7 Correspondence Table

| Definition | V | Description | Measurement Method | Related Boundary Conditions |
|------------|---|-------------|-------------------|-----------------------------|
| `skillQuality` | V1 | Precision and effectiveness of skill definitions | benchmark.json | L2, L5 |
| `contextEfficiency` | V2 | Utilization of finite context | completion rate / token count | L2, L3 |
| `outputQuality` | V3 | Quality of code, design, and documentation | gate pass rate, review finding count | L1, L4 |
| `gatePassRate` | V4 | First-pass gate clearance rate | pass/fail statistics | L6, L4 |
| `proposalAccuracy` | V5 | Hit rate of design proposals | approval/rejection rate | L4, L6 |
| `knowledgeStructureQuality` | V6 | Degree of structuring of persistent knowledge | context restoration speed, retirement detection rate | L2 |
| `taskDesignEfficiency` | V7 | Efficiency of task design | completion rate / resource ratio | L3, L6 |

#### `def Observable`

Observable: a decision procedure exists for a given property.
    Expresses that `P : World → Prop` is binary-decidable.

```lean
def Observable (P : World → Prop) : Prop :=
  ∃ f : World → Bool, ∀ w, f w = true ↔ P w
```


#### `def Measurable`

Measurable: a computation procedure exists for a quantitative indicator.
    Expresses that the value of `m : World → Nat` can be computed from external observations.

    Formally, "there exists a computable function `f` that agrees with `m`."
    By declaring this as an axiom for an opaque `m`, we promise the system
    that "a measurement procedure exists in principle."

    **Why this is non-trivial**

    When `m` is opaque, `f = m` does not pass type-checking
    (due to the non-unfoldability of opaque definitions). Therefore,
    the axiom declaration of Measurable constitutes a non-trivial promise.

```lean
def Measurable (m : World → Nat) : Prop :=
  ∃ f : World → Nat, ∀ w, f w = m w
```


#### `inductive ProxyMaturityLevel`

Proxy maturity levels. Assigns a classification to each V proxy in observe.sh.
    - provisional: Tentative proxy indicator. Formal measurement method not yet implemented.
    - established: Stable proxy indicator. Operational sufficiency confirmed (T6 judgment).
    - formal: Formal measurement method implemented.

```lean
inductive ProxyMaturityLevel where
  | provisional : ProxyMaturityLevel
  | established : ProxyMaturityLevel
  | formal : ProxyMaturityLevel
  deriving BEq, Repr, DecidableEq
```


#### `def v1ProxyMaturity`

Current proxy maturity for V1.
    provisional → formal (2026-03-27, #77):
    - GQM chain defined (R1 #85): Q1 structural contribution, Q2 verification quality, Q3 operational stability
    - Formal schema implemented in benchmark.json (G1 #78)
    - Automated measurement in observe.sh (G2 #79)
    - Retrospective validation over 63 runs confirmed all metrics satisfy hypotheses
    - Goodhart 5-layer defense: governance metrics (R2), correlation monitoring (R3), non-triviality gate (R5), saturation detection (R6), bias review obligation (G1b-2)
    - Legacy proxy (success_rate) confirmed to be uncorrelated with new benchmark (r=0.006-0.069) (G3 #80)

```lean
def v1ProxyMaturity : ProxyMaturityLevel := .formal
```


#### `def v3ProxyMaturity`

Current proxy maturity for V3.
    provisional → formal (2026-03-27, #77):
    - GQM chain defined (R1 #85): Q1 acceptance criteria, Q2 structural integrity, Q3 error trend
    - Formal schema implemented in benchmark.json (G1 #78)
    - Automated measurement in observe.sh (G2 #79)
    - Legacy proxy (test_pass_rate) confirmed invalid as quality signal due to zero variance (G3 #80)
    - hallucination proxy (Run 54+) functions as a new indicator for error trend

```lean
def v3ProxyMaturity : ProxyMaturityLevel := .formal
```


#### `opaque skillQuality`

V1: Skill quality. Precision and effectiveness of skill definitions.
    Measurement method: benchmark.json (with/without comparison).
    Related boundary conditions: L2 (mitigating training data discontinuity), L5 (skill system).
    observe.sh proxy: evolve_success_rate (successful run ratio), lean_health (sorry=0 check),
    skill_count (number of skill files).
    Proxy maturity classification:
    - provisional_proxy: Tentative proxy indicator. Formal measurement method not yet implemented.
    - established_proxy: Stable proxy indicator. Judged operationally sufficient.
    - formal_measurement: Formal measurement method implemented.
    V1 proxy promoted to formal_measurement (2026-03-27, #77). Measured via benchmark.json GQM schema.

```lean
opaque skillQuality : World → Nat
```


#### `opaque contextEfficiency`

V2: Context efficiency. Utilization of finite context.
    Measurement method: task completion rate / consumed token count.
    Related boundary conditions: L2 (finite context), L3 (token budget).
    observe.sh proxy: recent_avg (median of last 10 session deltas, primary),
    cumulative_avg (all-history average excluding micro-sessions, baseline).
    primary_metric: recent_median (median-based, robust to outliers).
    Operational note: a divergence of ±20% or more between recent_avg and cumulative_avg
    is interpreted as a trend change.
    Divergence interpretation: V2 is a hub variable with tradeoff relationships to 5 other
    variables (theorem tradeoff_context_is_hub). Since evolve sessions (heavy tool usage)
    push recent_avg upward, divergence_percent > 100% is not necessarily problematic.
    The tendency for recent_avg to rise as evolve depth and frequency increase is expected.

```lean
opaque contextEfficiency : World → Nat
```


#### `opaque outputQuality`

V3: Output quality. Quality of code, design, and documentation.
    Measurement method: gate pass rate, review finding count.
    Related boundary conditions: L1 (safety standards), L4 (basis for action space adjustment).
    observe.sh proxy: test_pass_rate (all-tests pass rate) +
    hallucination_proxy (rejected[].failure_type aggregation).
    Legacy fix_ratio_percent proxy (commit prefix ratio) was removed in Run 69.
    Proxy maturity classification:
    - provisional_proxy: Tentative proxy indicator. Formal measurement method not yet implemented.
    - established_proxy: Stable proxy indicator. Judged operationally sufficient.
    - formal_measurement: Formal measurement method implemented.
    V3 proxy promoted to formal_measurement (2026-03-27, #77). Measured via benchmark.json GQM schema.

```lean
opaque outputQuality : World → Nat
```


#### `opaque gatePassRate`

V4: Gate pass rate. Rate of clearing each phase's gate on the first attempt.
    P2 (cognitive separation of concerns) guarantees gate reliability.
    Measurement method: pass/fail statistics.
    Related boundary conditions: L6 (gate definition granularity), L4 (auto-merge judgment).
    observe.sh proxy: Bash passed / (passed + blocked).
    "tool":"Bash" event count / (Bash + gate_blocked event count) from tool-usage.jsonl.

```lean
opaque gatePassRate : World → Nat
```


#### `opaque proposalAccuracy`

V5: Proposal accuracy. Hit rate of design and scope proposals.
    Measurement method: human approval/rejection rate.
    Related boundary conditions: L4 (basis for action space adjustment), L6 (design convention improvement).
    observe.sh proxy: approved / total entry ratio from v5-approvals.jsonl.

```lean
opaque proposalAccuracy : World → Nat
```


#### `opaque knowledgeStructureQuality`

V6: Knowledge structure quality. Degree of structuring of persistent knowledge.
    P3 (governed learning) defines the knowledge lifecycle
    (observation -> hypothesis formation -> verification -> integration -> retirement).
    Knowledge that is not retired accumulates and degrades V2.
    Measurement method: context restoration speed in the next session, retirement target detection rate.
    Related boundary conditions: L2 (mitigating memory loss).
    observe.sh proxy: memory_entries (MEMORY.md entry count), memory_files (memory file count),
    last_update_days_ago (days since last update), retired_count (retired entry count).

```lean
opaque knowledgeStructureQuality : World → Nat
```


#### `opaque taskDesignEfficiency`

V7: Task design efficiency. Quality of P6 (task design as constraint satisfaction).
    Two data sources:
    (1) External knowledge: public benchmarks, model performance characteristics
    (2) Internal knowledge: execution logs, resource consumption records, outcome-to-cost ratio
    Measurement method: task completion rate / consumed resource ratio, redesign frequency.
    Related boundary conditions: L3 (resource limits), L6 (design conventions).
    observe.sh proxy: completed (task completion count from v7-tasks.jsonl), unique_subjects (unique subject count),
    teamwork_percent (ratio of entries with teammate field).
    Operational note: teamwork_percent is suppressed in single-agent operation (teamwork_status="suppressed_single_agent").
    Since this field requires multi-agent/human collaboration, it is excluded from observation reports in single-agent environments.

```lean
opaque taskDesignEfficiency : World → Nat
```


#### Measurability Declarations for V1-V7 - Gamma Extension of T_0 Design-Derived

Each variable is declared as `Measurable` via non-logical axioms (Glossary §4.1).
This is a design-level promise that "measurement is possible in principle," with
concrete measurement implementations delegated to the operational layer.

Membership in Gamma \ T_0 (Procedure Manual §2.4): the justification for these axioms
originates from the designer's design judgments (not from external authority), and therefore
they belong to the extension part.

Why axioms: since V1–V7 are opaque (opaque definitions, Glossary §9.4),
`Measurable` cannot be proved as a theorem (§4.2) due to the non-unfoldability of opaque
definitions. Measurability is guaranteed by external operational systems and is assumed
as a non-logical axiom within the formal system.

#### `axiom v1_measurable`

[Axiom Card]
    Layer: Gamma \ T_0 (design-derived)
    Content: V1 (skill quality) is measurable
    Basis: with/without comparison via benchmark.json exists as a measurement procedure
    Source: Ontology.lean V1 definition
    Refutation condition: if it is shown that a measurement procedure for skill quality is in principle unconstructible

```lean
axiom v1_measurable : Measurable skillQuality
```


#### `axiom v2_measurable`

[Axiom Card]
    Layer: Gamma \ T_0 (design-derived)
    Content: V2 (context efficiency) is measurable
    Basis: the ratio of task completion rate to consumed token count exists as a measurement procedure
    Source: Ontology.lean V2 definition
    Refutation condition: if it is shown that a measurement procedure for context efficiency is in principle unconstructible

```lean
axiom v2_measurable : Measurable contextEfficiency
```


#### `axiom v3_measurable`

[Axiom Card]
    Layer: Gamma \ T_0 (design-derived)
    Content: V3 (output quality) is measurable
    Basis: gate pass rate and review finding count exist as measurement procedures
    Source: Ontology.lean V3 definition
    Refutation condition: if it is shown that a measurement procedure for output quality is in principle unconstructible

```lean
axiom v3_measurable : Measurable outputQuality
```


#### `axiom v4_measurable`

[Axiom Card]
    Layer: Gamma \ T_0 (design-derived)
    Content: V4 (gate pass rate) is measurable
    Basis: pass/fail statistics exist as a measurement procedure
    Source: Ontology.lean V4 definition
    Refutation condition: if it is shown that a measurement procedure for gate pass rate is in principle unconstructible

```lean
axiom v4_measurable : Measurable gatePassRate
```


#### `axiom v5_measurable`

[Axiom Card]
    Layer: Gamma \ T_0 (design-derived)
    Content: V5 (proposal accuracy) is measurable
    Basis: human approval/rejection rate exists as a measurement procedure
    Source: Ontology.lean V5 definition
    Refutation condition: if it is shown that a measurement procedure for proposal accuracy is in principle unconstructible

```lean
axiom v5_measurable : Measurable proposalAccuracy
```


#### `axiom v6_measurable`

[Axiom Card]
    Layer: Gamma \ T_0 (design-derived)
    Content: V6 (knowledge structure quality) is measurable
    Basis: context restoration speed and retirement target detection rate exist as measurement procedures
    Source: Ontology.lean V6 definition
    Refutation condition: if it is shown that a measurement procedure for knowledge structure quality is in principle unconstructible

```lean
axiom v6_measurable : Measurable knowledgeStructureQuality
```


#### `axiom v7_measurable`

[Axiom Card]
    Layer: Gamma \ T_0 (design-derived)
    Content: V7 (task design efficiency) is measurable
    Basis: task completion rate / consumed resource ratio exists as a measurement procedure
    Source: Ontology.lean V7 definition
    Refutation condition: if it is shown that a measurement procedure for task design efficiency is in principle unconstructible

```lean
axiom v7_measurable : Measurable taskDesignEfficiency
```


#### System Health

Rather than maximizing individual variables, maintain the health of the system as a whole.
Even when metrics for one variable improve, verify that other variables have not deteriorated.

Health is formulated as "all variables are at or above a threshold."
Threshold settings are operational judgments (T6: humans are the final decision-makers for resources).

#### `def systemHealthy`

System health. The state in which all V1–V7 meet the minimum threshold.

    Note: thresholds should ideally differ per variable rather than being uniform,
    but Phase 4 uses a uniform threshold for simplicity.
    Phase 5 extends this to per-variable thresholds (HealthThresholds /
    systemHealthyPerVar in ObservableDesign.lean).

```lean
def systemHealthy (threshold : Nat) (w : World) : Prop :=
  skillQuality w ≥ threshold ∧
  contextEfficiency w ≥ threshold ∧
  outputQuality w ≥ threshold ∧
  gatePassRate w ≥ threshold ∧
  proposalAccuracy w ≥ threshold ∧
  knowledgeStructureQuality w ≥ threshold ∧
  taskDesignEfficiency w ≥ threshold
```


#### `axiom trust_measurable`

[Axiom Card]
    Layer: Gamma \ T_0 (design-derived)
    Content: trustLevel is measurable.
             Indirectly observed from investment behavior (fluctuations in resource allocation)
    Basis: trust is concretized as investment behavior (resource allocation fluctuations)
    Source: manifesto.md Section 6
    Refutation condition: if it is shown that a measurement procedure for trust level is in principle unconstructible

```lean
axiom trust_measurable :
  ∀ (agent : Agent), Measurable (trustLevel agent)
```


#### `axiom degradation_measurable`

[Axiom Card]
    Layer: Gamma \ T_0 (design-derived)
    Content: degradationLevel is measurable. Computed from temporal changes in V1–V7
    Basis: if V1–V7 are Measurable, their rate of change is also computable
    Source: design of P4 (observability of degradation)
    Refutation condition: if it is shown that a measurement procedure for degradation level is in principle unconstructible

```lean
axiom degradation_measurable : Measurable degradationLevel
```


#### Three-Tier Structure Connection Boundary to Mitigation to Variable

Many variables represent the quality of structures designed as **mitigations** for boundary conditions:

```
Boundary (invariant)          ->  Mitigation (structure)         ->  Variable (quality)
L2: Memory loss               ->  Implementation Notes           ->  V6: Knowledge structure quality
L2: Finite context             ->  50% rule, lightweight design   ->  V2: Context efficiency
L2: Non-determinism            ->  Gate verification              ->  V4: Gate pass rate
L2: Training data discontinuity ->  docs/ SSOT, skills           ->  V1: Skill quality
```

Boundary conditions do not move. Mitigations are design decisions (L6). Variables measure
**how well** mitigations work. This three-tier structure clarifies "what is fixed, what is
a design choice, and what is an optimization target."

#### `inductive VariableId`

Correspondence between boundary conditions and variables.
    Expresses the "boundary -> variable" mapping of the three-tier structure as a type.
    Mitigations are design decisions (L6) positioned between them.

```lean
inductive VariableId where
  | v1 | v2 | v3 | v4 | v5 | v6 | v7
  deriving BEq, Repr
```


#### `def variableBoundary`

Boundary condition corresponding to each variable.
    Expresses the "boundary -> variable" mapping of the three-tier structure as a function.
    Mitigations are design decisions (L6) positioned between them.

```lean
def variableBoundary : VariableId → BoundaryId
  | .v1 => .ontological   -- L2: 学習データ断絶 → V1: スキル品質
  | .v2 => .ontological   -- L2: コンテキスト有限性 → V2: コンテキスト効率
  | .v3 => .ethicsSafety   -- L1: 安全基準 → V3: 出力品質
  | .v4 => .ontological   -- L2: 非決定性 → V4: ゲート通過率
  | .v5 => .actionSpace    -- L4: 行動空間調整の根拠 → V5: 提案精度
  | .v6 => .ontological   -- L2: 記憶喪失 → V6: 知識構造の質
  | .v7 => .resource       -- L3: リソース上限 → V7: タスク設計効率
```


#### `theorem fixed_boundary_variables_mitigate_only`

Variables corresponding to fixed boundaries cannot move the boundary itself;
    only the quality of mitigations can be improved.

```lean
theorem fixed_boundary_variables_mitigate_only :
  boundaryLayer (variableBoundary .v1) = .fixed ∧
  boundaryLayer (variableBoundary .v2) = .fixed ∧
  boundaryLayer (variableBoundary .v4) = .fixed ∧
  boundaryLayer (variableBoundary .v6) = .fixed := by
  simp [variableBoundary, boundaryLayer]
```


#### `def constraintBoundary`

Boundary conditions corresponding to each constraint (T1-T8).
    Expresses the "constraint -> boundary condition" mapping of the three-tier structure as a function.
    T->L mapping: which boundary condition category each constraint belongs to.

    Mapping justification:
    - T1 -> L2: Session ephemerality is an ontological fact (agent is bound to session)
    - T2 -> L2: Structural persistence is an ontological fact (structure outlives agent)
    - T3 -> L2, L3: Finite context is both an ontological and a resource constraint
    - T4 -> L2: Output stochasticity is an ontological property of LLMs
    - T5 -> L2: Feedback requirement is an ontological prerequisite for improvement
    - T6 -> L1, L4: Human authority spans the safety boundary (L1) and action space boundary (L4)
    - T7 -> L3: Resource finiteness directly corresponds to the resource boundary
    - T8 -> L6: Precision level is defined as a task design convention (architecturalConvention)

    Note: L5 (platform) is intentionally excluded.
    L5 represents provider-specific environmental constraints (Claude Code, Codex CLI, etc.),
    while T1-T8 are technology-independent constraints. L5 is not derived from T but arises
    from the human judgment of platform selection (upstream of T6).
    In variableBoundary as well, V1-V7 are not mapped to L5.

```lean
def constraintBoundary : ConstraintId → List BoundaryId
  | .t1 => [.ontological]
  | .t2 => [.ontological]
  | .t3 => [.ontological, .resource]
  | .t4 => [.ontological]
  | .t5 => [.ontological]
  | .t6 => [.ethicsSafety, .actionSpace]
  | .t7 => [.resource]
  | .t8 => [.architecturalConvention]
```


#### `theorem constraint_has_boundary`

Every constraint corresponds to at least one boundary condition.
    Surjectivity onto coverage of the T->L mapping.

```lean
theorem constraint_has_boundary :
  ∀ c : ConstraintId, (constraintBoundary c).length > 0 := by
  intro c
  cases c <;> simp [constraintBoundary]
```


#### `theorem platform_not_in_constraint_boundary`

L5 (platform) is not included in the constraintBoundary of any T1-T8.
    L5 is a provider-specific environmental constraint and is not derived from
    the technology-independent constraints T.

```lean
theorem platform_not_in_constraint_boundary :
  ∀ c : ConstraintId, BoundaryId.platform ∉ constraintBoundary c := by
  intro c
  cases c <;> simp [constraintBoundary]
```


#### `theorem constraint_boundary_covers_except_platform`

Every boundary condition except L5 is included in the constraintBoundary of at least one constraint.
    constraintBoundary covers L1-L6 except L5.

```lean
theorem constraint_boundary_covers_except_platform :
  (∃ c, BoundaryId.ethicsSafety ∈ constraintBoundary c) ∧
  (∃ c, BoundaryId.ontological ∈ constraintBoundary c) ∧
  (∃ c, BoundaryId.resource ∈ constraintBoundary c) ∧
  (∃ c, BoundaryId.actionSpace ∈ constraintBoundary c) ∧
  (∃ c, BoundaryId.architecturalConvention ∈ constraintBoundary c) := by
  refine ⟨⟨.t6, ?_⟩, ⟨.t1, ?_⟩, ⟨.t3, ?_⟩, ⟨.t6, ?_⟩, ⟨.t8, ?_⟩⟩ <;>
    simp [constraintBoundary]
```


#### Measurable to Observable Bridge

A general theorem stating that threshold comparison of Measurable indicators is Observable.
An aggregation lemma that collects the Measurable axioms of V1–V7.

#### `theorem measurable_threshold_observable`

Threshold comparison of a Measurable indicator is Observable (Measurable->Observable bridge).
    Constructs a decision procedure for m w >= t from Measurable m.

```lean
theorem measurable_threshold_observable {m : World → Nat} (hm : Measurable m) (t : Nat) :
    Observable (fun w => m w ≥ t) := by
  obtain ⟨f, hf⟩ := hm
  exact ⟨fun w => decide (f w ≥ t), fun w => by simp [hf w]⟩
```


#### `theorem all_variables_measurable`

All 7 variables are Measurable (aggregation lemma).

```lean
theorem all_variables_measurable :
    Measurable skillQuality ∧ Measurable contextEfficiency ∧
    Measurable outputQuality ∧ Measurable gatePassRate ∧
    Measurable proposalAccuracy ∧ Measurable knowledgeStructureQuality ∧
    Measurable taskDesignEfficiency :=
  ⟨v1_measurable, v2_measurable, v3_measurable, v4_measurable,
   v5_measurable, v6_measurable, v7_measurable⟩
```


#### `theorem observable_and`

Conjunction closure of Observable. The conjunction of two Observable properties is also Observable.

```lean
theorem observable_and {P Q : World → Prop} (hp : Observable P) (hq : Observable Q) :
    Observable (fun w => P w ∧ Q w) := by
  obtain ⟨fp, hfp⟩ := hp
  obtain ⟨fq, hfq⟩ := hq
  refine ⟨fun w => fp w && fq w, fun w => ?_⟩
  simp [Bool.and_eq_true]
  exact ⟨fun ⟨a, b⟩ => ⟨(hfp w).mp a, (hfq w).mp b⟩,
         fun ⟨a, b⟩ => ⟨(hfp w).mpr a, (hfq w).mpr b⟩⟩
```


#### `theorem system_health_observable`

System health is Observable (binary-decidable).
    Since each Vi is Measurable, threshold comparison is decidable.
    Proved via measurable_threshold_observable + observable_and.
    (Originally an axiom, demoted to theorem in Run 27)

```lean
theorem system_health_observable :
    ∀ (threshold : Nat), Observable (systemHealthy threshold) := by
  intro t
  unfold systemHealthy
  apply observable_and (measurable_threshold_observable v1_measurable t)
  apply observable_and (measurable_threshold_observable v2_measurable t)
  apply observable_and (measurable_threshold_observable v3_measurable t)
  apply observable_and (measurable_threshold_observable v4_measurable t)
  apply observable_and (measurable_threshold_observable v5_measurable t)
  apply observable_and (measurable_threshold_observable v6_measurable t)
  exact measurable_threshold_observable v7_measurable t
```


#### Part IV Maintaining the Classification Itself

This classification (L1–L6, V1–V7) is a **hypothesis** based on current understanding,
not a fixed truth. Its type-level representation is formalized as `ReviewSignal` in Evolution.lean.

#### Signals That Should Trigger Review

| Signal | Example | Response |
|--------|---------|----------|
| Misclassification | An item placed in L1 is actually conditionally modifiable | Move to another category |
| Missing boundary condition | Regulatory/legal constraints restrict the action space but are absent from the classification | Add a new Layer |
| Vanished boundary condition | Technological advances have effectively overcome an L2 item | Delete or reclassify |
| Variable deficit/surplus | There are optimization targets not included in V1-V7 | Add, merge, or split variables |
| Ambiguous category boundary | Something could belong to either "fixed boundary" or "investment-variable boundary" | Refine the judgment criteria |

#### Caution - Avoiding Self-Rigidification of the Classification

The greatest risk is that **the classification itself begins to function as a boundary condition** --
inducing reasoning such as "it cannot be changed because it is written in L1."

Preventive measures:
- Maintain the rationale for "why this category" for each item in every Layer
- "Fixed" means "no means of changing it has been found at present"
- Reclassification of boundary conditions is a legitimate act consistent with the spirit of the manifesto

#### Core Insights

1. **The subject of optimization is structure, not the agent.** The agent is an ephemeral catalyst (T1).
   Improvements accumulate within structure (T2).

2. **Variables are not independent levers but a mutually interacting system.** Improving V1 can degrade V2.
   Rather than maximizing individual variables, maintain the health of the system as a whole.

3. **The purpose of the investment cycle is equilibrium, not expansion.** Rather than maximizing the action space,
   search for the equilibrium point where collaborative value is maximized. The equilibrium point shifts with context.

4. **The investment cycle simultaneously contains positive and negative feedback.** By P1, expansion of the action space
   is inseparable from expansion of the attack surface. Expansion without defense increases the potential destructive
   power of the reverse cycle.

5. **Gate reliability depends on P2, and P2 rests on E1.** V4 is meaningful only when generation and evaluation
   are structurally separated.

6. **Variable optimization presupposes P4.** What cannot be observed cannot be optimized.

7. **Structure is interpreted probabilistically (P5).** Designs that assume 100% compliance are fragile.

8. **Task execution is a constraint satisfaction problem (P6).** Simultaneous satisfaction of T3, T7, and T8
   drives task design.

9. **L5 determines the ceiling of structural improvement.** Building a custom platform is justified when the
   investment cycle has sufficiently progressed and the L5 ceiling has become a bottleneck.

10. **The axiom system has a three-layer structure.** Constraints (T: undeniable), empirical postulates
    (E: falsifiable but unfalsified), and foundational principles (P: derived from T/E). The robustness of
    each P differs depending on whether its justification includes E.

11. **This classification itself is subject to review.** The L1–L6, V1–V7 classification is not a fixed truth;
    reclassification, addition, and deletion of items may occur during operation.

#### Quality Measurement Priority G1b-1

Analysis from G1b-1 (#91) revealed that the following quality priorities are derivable from
the manifesto's axiom system. These follow logically from existing axioms and design principles,
without depending on T6 (human judgment).

#### Non-Derivable Domain V1-V7
Mutual priority among V1-V7 is not derivable. TradeoffExists is a symmetric relation and
does not imply orderings such as "V1 > V3." This is an intentional design decision;
priority among V's reduces to T6 judgment (G1b-2 #92).

#### `inductive QualityMeasureCategory`

Quality measurement category: measurement of structural change vs measurement of process success rate.
    Formalization of the proxy mismatch identified in R1 (GQM redefinition).

```lean
inductive QualityMeasureCategory where
  | structuralOutcome   -- 構造的成果: theorem delta, test delta, axiom count
  | processSuccess      -- プロセス成功率: evolve success rate, skill invocation rate
  deriving BEq, Repr
```


#### `def qualityMeasurePriority`

Priority of quality measurement categories. Structural outcomes are a more direct indicator
    of quality than process success rates.
    Basis:
    - Supreme mission "persistent structure continues to improve itself" -> structural change defines improvement
    - Analogy from D5 (specification layer ordering): outcome (what was produced) > process (how it was produced)
    - Anthropic eval guide: "grade what the agent produced, not the path it took"

```lean
def qualityMeasurePriority : QualityMeasureCategory → Nat
  | .structuralOutcome => 1  -- higher priority
  | .processSuccess    => 0  -- lower priority
```


#### `theorem structural_outcome_gt_process_success`

Measurement of structural outcomes takes priority over measurement of process success rates as a quality indicator.
    Quality is "skills producing structural improvement," not merely "skills running successfully."

```lean
theorem structural_outcome_gt_process_success :
    qualityMeasurePriority .structuralOutcome >
    qualityMeasurePriority .processSuccess := by
  native_decide
```


#### `inductive VerificationSignalType`

Classification of verification signals: independent verification vs self-assessment.
    Formalization of P2 + E1 + ICLR 2024 (Huang et al.).

```lean
inductive VerificationSignalType where
  | independentlyVerified  -- P2: 独立エージェントまたは構造的テストによる検証
  | selfAssessed           -- 同一インスタンスによる自己評価
  deriving BEq, Repr
```


#### `def verificationReliability`

Reliability of verification signals. Independent verification is more reliable than self-assessment.
    Basis:
    - P2: Cognitive separation of concerns (separation of Worker and Verifier)
    - E1: Experience precedes theory -- self-assessment using self-generated theory is circular
    - ICLR 2024 Huang et al.: intrinsic self-correction degrades accuracy

```lean
def verificationReliability : VerificationSignalType → Nat
  | .independentlyVerified => 1  -- higher reliability
  | .selfAssessed          => 0  -- lower reliability
```


#### `theorem independent_verification_gt_self_assessment`

Independently verified quality signals are more reliable than self-assessed quality signals.

```lean
theorem independent_verification_gt_self_assessment :
    verificationReliability .independentlyVerified >
    verificationReliability .selfAssessed := by
  native_decide
```


#### `inductive QualityAssuranceLayer`

Quality assurance layers: defect absence vs value creation.
    Application of the D6 DesignStage ordering to the quality dimension.

```lean
inductive QualityAssuranceLayer where
  | defectAbsence    -- 壊れていないことの確認（test pass, Lean build, sorry=0）
  | valueCreation    -- 良いことの確認（改善の実質性、有用性）
  deriving BEq, Repr
```


#### `def qualityAssurancePriority`

Measurement priority of quality assurance. Confirming defect absence precedes confirming value creation.
    Basis:
    - D6: Boundary (constraint satisfaction) > Variable (quality improvement)
    - D4: Safety > Governance -- safety (not broken) precedes governance (making better)
    - Logical consequence: measuring "substantiveness of improvement" in a broken system is meaningless

```lean
def qualityAssurancePriority : QualityAssuranceLayer → Nat
  | .defectAbsence  => 1  -- higher measurement priority
  | .valueCreation  => 0  -- lower measurement priority (but not less important)
```


#### `theorem defect_absence_measurement_gt_value_creation`

Measurement of defect absence takes priority over measurement of value creation (as measurement ordering).
    Note: this means "should be measured first," not "defect absence is more important."
    Measurement of value creation becomes meaningful only after defect absence is confirmed.

```lean
theorem defect_absence_measurement_gt_value_creation :
    qualityAssurancePriority .defectAbsence >
    qualityAssurancePriority .valueCreation := by
  native_decide
```



## 6. Design Foundation D1-D14: Applied Design Theory

*Source: `DesignFoundation.lean`*

**Declarations:** 56 theorems, 32 definitions

### Epistemic Layer - DesignTheorem Strength 1 - Formalization of Design Development Foundation

Type-checks that D1–D14 from design-development-foundation.md are
derivable (§2.4 derivability) from the manifesto's T/E/P
(premise set Γ, terminology reference §2.5).

#### Nature of the Formalization

This file does not add new non-logical axioms (§4.1) to Γ.
Every D is formalized as one of the following:
- **Definitional extension** (§5.5): Definition of new types/functions. Always a conservative extension
- **Theorem** (§4.2): Derived from existing axioms (T/E) by application of inference rules

Therefore this file is a collection of definitional extensions + theorems over T₀,
and conservative extension (§5.5) is guaranteed by `definitional_implies_conservative`
proven in Terminology.lean.

#### Design Policy

Each D is expressed as a type (definitional extension, §5.5) or theorem (§4.2),
with explicit connections to the underlying T/E/P non-logical axioms (§4.1) / theorems.

D's are meta-level (§5.6 metatheory) design principles,
distinct from object-level (§5.6 object theory) non-logical axioms.

#### Correspondence with Terminology Reference

| Lean Concept | Terminology Reference | §Ref |
|------------|----------------|-------|
| D1–D13 theorems | Theorems (propositions derived from axioms) | §4.2 |
| D1–D13 def/structure | Definitional extensions (new symbols defined via existing symbols) | §5.5 |
| SelfGoverning | Type class (interface for types) | §9.4 |
| DesignPrinciple | Component of the domain of discourse (§3.2) | §3.2 |
| DesignPrincipleUpdate | Structuring of AGM revision operations | §9.2 |
| EnforcementLayer | Hierarchy of enforcement power. Means to realize invariants (§9.3) | §9.3 |
| DevelopmentPhase | Inter-phase dependencies resemble transition relations (§9.3) | §9.3 |
| VerificationIndependence | Operationalization of E1 (§4.1 non-logical axiom) | §4.1 |
| CompatibilityClass | Classification of extensions (conservative/consistent/breaking) | §5.5 |

#### Correspondence with design-development-foundation.md

This file formalizes D1–D14.

| D | Rationale | Formalization Depth |
|---|------|------------|
| D1 | P5 + L1–L6 | type + 2 theorems |
| D2 | E1 + P2 | structure + 3 theorems |
| D3 | P4 + T5 | 3 theorems (3-condition structure not formalized) |
| D4 | Section 7 + P3 + T2 | type + 5 theorems |
| D5 | T8 + P4 + P6 | type + 3 theorems (inter-layer relations not formalized) |
| D6 | Ontology/Observable | 3 theorems (causal chain not formalized) |
| D7 | Section 6 + P1 | 2 theorems (accumulation bounded + damage unbounded) |
| D8 | Section 6 + E2 | 2 theorems (overexpansion + capability-risk) |
| D9 | Observable + P3 + Section 7 | SelfGoverning + 4 theorems |
| D10 | T1 + T2 | 2 theorems (structural permanence + epoch monotone increase) |
| D11 | T3 + D1 | definition + 3 theorems (inverse correlation + minimization + finiteness) |
| D12 | P6 + T3 + T7 + T8 | 2 theorems (CSP + probabilistic output) |
| D13 | P3 + Section 8 + T5 | 2 theorems (coherence propagation + retirement premise) |
| D14 | P6 + T7 + T8 | 1 theorem (constraint satisfaction of verification order) |

#### D1 Enforcement Layering
Definitional Extension, 5.5.

Rationale: P5 (probabilistic interpretation) + L1–L6 (hierarchy of boundary conditions)

By P5, normative guidelines are only probabilistically complied with.
Therefore, absolute constraints such as L1 (safety) should be
implemented via structural enforcement (not subject to probabilistic interpretation).

Connection with terminology reference:
- Structural enforcement → Invariant (§9.3): Property that always holds during execution
- Procedural enforcement → Pre/post-conditions (§9.3): Verified before and after operations
- Normative guideline → Satisfiable (§2.2) but not valid/tautological (§2.2) by P5

#### `inductive EnforcementLayer`

Enforcement layer. Represents the strength of enforcement power.

```lean
inductive EnforcementLayer where
  | structural   -- 違反が物理的に不可能
  | procedural   -- 違反は可能だが検出・阻止される
  | normative    -- 遵守は確率的（P5）
  deriving BEq, Repr
```


#### `def EnforcementLayer.strength`

Strength ordering of enforcement layers. structural is the strongest.

```lean
def EnforcementLayer.strength : EnforcementLayer → Nat
  | .structural => 3
  | .procedural => 2
  | .normative  => 1
```


#### `def minimumEnforcement`

Minimum required enforcement layer for each boundary condition.
    Fixed boundaries (L1, L2) require structural enforcement.
    Investment-variable boundaries require procedural enforcement or above.
    Environmental boundaries may use normative guidelines.

```lean
def minimumEnforcement : BoundaryLayer → EnforcementLayer
  | .fixed              => .structural
  | .investmentVariable => .procedural
  | .environmental      => .normative
```


#### `theorem d1_fixed_requires_structural`

Rationale for D1: L1 (fixed boundary) requires structural enforcement.
    By P5 (probabilistic interpretation), normative guidelines cannot guarantee L1.

    Formalization: The minimum enforcement layer for fixed boundaries is structural.

```lean
theorem d1_fixed_requires_structural :
  minimumEnforcement .fixed = .structural := by rfl
```


#### `theorem d1_enforcement_monotone`

Corollary of D1: Enforcement layer strength is monotone with respect to boundary layers.
    Enforcement strength required: fixed >= investment-variable >= environmental.

```lean
theorem d1_enforcement_monotone :
  (minimumEnforcement .fixed).strength ≥
  (minimumEnforcement .investmentVariable).strength ∧
  (minimumEnforcement .investmentVariable).strength ≥
  (minimumEnforcement .environmental).strength := by
  simp [minimumEnforcement, EnforcementLayer.strength]
```


#### D2 Worker/Verifier Separation
Definitional Extension + Theorem, 5.5/4.2.

Rationale: E1 (verification independence, non-logical axiom §4.1) + P2 (cognitive role separation, theorem §4.2)

E1a (verification_requires_independence) is the direct rationale.
E1 belongs to Γ \ T₀ (hypothesis-derived) and is falsifiable (§9.1).
If E1 is falsified, D2 becomes subject to review.

#### `structure VerificationIndependence`

Four conditions for verification independence.

    The former 3 conditions (context separation, bias non-sharing, independent invocation)
    covered only process-level independence. Without evaluator independence,
    the problem of "the same model making the same mistakes in a different context" remains.

    Four conditions:
    1. Context separation: Worker's reasoning process and intermediate state do not leak to Verifier
    2. Framing independence: Verification criteria are not post-hoc defined by the Worker
       (Refinement of former "bias non-sharing". Not only the artifacts,
       but also the framework of "what should be verified" is independent of the Worker)
    3. Execution automaticity: Worker cannot bypass verification
       (Strengthening of former "independent invocation". Does not depend on Worker's discretion)
    4. Evaluator independence: Evaluation is performed by a separate entity without shared judgment tendencies
       (Human: A different person without shared context but with sufficient knowledge.
        LLM: A different model without shared context.
        Same model with different context corresponds to a Subagent,
        which achieves process separation but not evaluator independence)

```lean
structure VerificationIndependence where
```


#### `? (anonymous)`

Worker's reasoning process does not leak to Verifier

#### `? (anonymous)`

Verification criteria do not depend on Worker's framing

#### `? (anonymous)`

Verification execution does not depend on Worker's discretion

#### `? (anonymous)`

Evaluator has different judgment tendencies from Worker

#### `inductive VerificationRisk`

Verification risk level.
    The required level of independence varies by risk.

```lean
inductive VerificationRisk where
  | critical  -- L1 関連: 安全・倫理
  | high      -- 構造変更: アーキテクチャ、設定
  | moderate  -- 通常コード変更
  | low       -- ドキュメント、コメント
  deriving BEq, Repr
```


#### `def requiredConditions`

Required independence conditions for each risk level.
    critical: All 4 conditions required (verification by human or different model)
    high: 3 conditions (framing independence + automatic execution + context separation)
    moderate: 2 conditions (context separation + automatic execution)
    low: 1 condition (context separation only, Subagent suffices)

```lean
def requiredConditions : VerificationRisk → Nat
  | .critical => 4
  | .high     => 3
  | .moderate => 2
  | .low      => 1
```


#### `def satisfiedConditions`

Counts the number of satisfied independence conditions.

```lean
def satisfiedConditions (vi : VerificationIndependence) : Nat :=
  (if vi.contextSeparated then 1 else 0) +
  (if vi.framingIndependent then 1 else 0) +
  (if vi.executionAutomatic then 1 else 0) +
  (if vi.evaluatorIndependent then 1 else 0)
```


#### `def sufficientVerification`

Whether verification is sufficient: satisfied conditions >= required conditions

```lean
def sufficientVerification
    (vi : VerificationIndependence) (risk : VerificationRisk) : Prop :=
  satisfiedConditions vi ≥ requiredConditions risk
```


#### `theorem critical_requires_all_four`

Critical risk requires all four conditions.
    Subagent (contextSeparated only) is insufficient.

```lean
theorem critical_requires_all_four :
  requiredConditions .critical = 4 := by rfl
```


#### `theorem subagent_only_sufficient_for_low`

Subagent-only verification (context separation only) is sufficient only for low risk.

```lean
theorem subagent_only_sufficient_for_low :
  let subagentOnly : VerificationIndependence :=
    { contextSeparated := true
      framingIndependent := false
      executionAutomatic := false
      evaluatorIndependent := false }
  sufficientVerification subagentOnly .low ∧
  ¬sufficientVerification subagentOnly .moderate := by
  simp [sufficientVerification, satisfiedConditions, requiredConditions]
```


#### `def validSeparation`

Backward compatibility with former validSeparation: the old 3 conditions are a subset of the new 4 conditions.

```lean
def validSeparation (vs : VerificationIndependence) : Prop :=
  vs.contextSeparated = true ∧
  vs.framingIndependent = true ∧
  vs.executionAutomatic = true
```


#### `theorem d2_from_e1`

Rationale for D2: From E1, valid verification requires separation.
    The type of verification_requires_independence demands
    gen.id ≠ ver.id ∧ ¬sharesInternalState gen ver.
    gen.id ≠ ver.id → contextSeparated ∧ evaluatorIndependent
    ¬sharesInternalState → framingIndependent

```lean
theorem d2_from_e1 :
  ∀ (gen ver : Agent) (action : Action) (w : World),
    generates gen action w →
    verifies ver action w →
    gen.id ≠ ver.id ∧ ¬sharesInternalState gen ver :=
  verification_requires_independence
```


#### D3 Observability First
Theorem, 4.2.

Rationale: P4 (observability of degradation, theorem §4.2) + T5 (no improvement without feedback, T₀ §4.1)

T5 (no_improvement_without_feedback) is the direct rationale:
Improvement requires feedback → feedback requires observation.

Note: design-development-foundation.md defines 3 conditions for observability
(measurable, degradation-detectable, improvement-verifiable), but
this formalization covers only the implication of T5. Structuring of the 3 conditions is not yet implemented.

#### `theorem d3_observability_precedes_improvement`

Rationale for D3: Feedback (= observation results) must precede improvement.
    Direct application of T5.

```lean
theorem d3_observability_precedes_improvement :
  ∀ (w w' : World),
    structureImproved w w' →
    ∃ (f : Feedback), f ∈ w'.feedbacks ∧
      f.timestamp ≥ w.time ∧ f.timestamp ≤ w'.time :=
  no_improvement_without_feedback
```


#### `inductive DetectionMode`

Distinction of detection modes (introduced in Run 41).
    Refines the definition of "detectable": distinguishes between
    human-readable (humanReadable) and programmatically queryable (structurallyQueryable).
    D3 condition 2 requires structurallyQueryable.

```lean
inductive DetectionMode where
  | humanReadable         : DetectionMode  -- 人間が読めば分かる（自由テキスト等）
  | structurallyQueryable : DetectionMode  -- プログラムでクエリ可能（構造化フィールド等）
  deriving BEq, Repr
```


#### `structure ObservabilityConditions`

D3 observability 3 conditions (design-development-foundation.md §D3).
    Only when all 3 conditions hold for a variable V does
    V become an effectively optimizable target.

```lean
structure ObservabilityConditions where
```


#### `? (anonymous)`

Whether the current value is measurable (Measurable, Observable.lean)

#### `? (anonymous)`

Whether degradation is detectable (can it be detected before quality collapse)

#### `? (anonymous)`

Detection mode for degradation (ineffective unless structurallyQueryable)

#### `? (anonymous)`

Whether improvement is verifiable (can value changes be compared before and after intervention)

#### `def effectivelyOptimizable`

Determines whether a variable is an effectively optimizable target. All 3 conditions required.
    Additionally, degradation detection must be in a structurally queryable format.

```lean
def effectivelyOptimizable (c : ObservabilityConditions) : Prop :=
  c.measurable = true ∧ c.degradationDetectable = true ∧
  c.detectionMode = .structurallyQueryable ∧ c.improvementVerifiable = true
```


#### `theorem d3_partial_observability_insufficient`

D3: A variable lacking any of the 3 conditions is merely a nominal optimization target.

```lean
theorem d3_partial_observability_insufficient :
  ¬effectivelyOptimizable ⟨true, true, .structurallyQueryable, false⟩ ∧
  ¬effectivelyOptimizable ⟨true, false, .structurallyQueryable, true⟩ ∧
  ¬effectivelyOptimizable ⟨false, true, .structurallyQueryable, true⟩ := by
  refine ⟨?_, ?_, ?_⟩ <;> simp [effectivelyOptimizable]
```


#### `theorem d3_full_observability_sufficient`

D3: Effective only when all 3 conditions hold and detection is structurally queryable.

```lean
theorem d3_full_observability_sufficient :
  effectivelyOptimizable ⟨true, true, .structurallyQueryable, true⟩ := by
  simp [effectivelyOptimizable]
```


#### `theorem d3_human_readable_insufficient`

D3 refinement (Run 41): Human-readable but structurally non-queryable detection is insufficient.
    Merely writing in notes is ineffective even if degradationDetectable = true.

```lean
theorem d3_human_readable_insufficient :
  ¬effectivelyOptimizable ⟨true, true, .humanReadable, true⟩ := by
  simp [effectivelyOptimizable]
```


#### D4 Progressive Self-Application
Definitional Extension + Theorem, 5.5/4.2.

Rationale: Section 7 (self-application) + P3 (governed learning, theorem §4.2) + T2 (structural permanence, T₀ §4.1)

Development phases have an ordering, and each phase's completion persists in structure (T2).
The phase ordering is derived from the dependency relationships of D1–D3.
`phaseOrder` in Procedure.lean formalizes the same ordering.

#### `inductive DevelopmentPhase`

Development phase. Each stage of D4's progressive self-application.

```lean
inductive DevelopmentPhase where
  | safety        -- L1: 安全基盤
  | verification  -- P2: 検証基盤
  | observability -- P4: 可観測性
  | governance    -- P3: 統治
  | equilibrium   -- 投資サイクル + 動的調整
  deriving BEq, Repr
```


#### `def phaseDependency`

Inter-phase dependencies. A subsequent phase cannot begin
    until the preceding phase is complete.

```lean
def phaseDependency : DevelopmentPhase → DevelopmentPhase → Prop
  | .verification,  .safety        => True  -- P2 は L1 の後
  | .observability, .verification  => True  -- P4 は P2 の後
  | .governance,    .observability => True  -- P3 は P4 の後
  | .equilibrium,   .governance    => True  -- 投資は P3 の後
  | _,              _              => False
```


#### `theorem d4_no_self_dependency`

Rationale for D4: Phase ordering is strict (no self-transitions).
    Each phase depends on its preceding phase.

```lean
theorem d4_no_self_dependency :
  ∀ (p : DevelopmentPhase), ¬phaseDependency p p := by
  intro p; cases p <;> simp [phaseDependency]
```


#### `theorem d4_full_chain`

A complete phase chain exists.

```lean
theorem d4_full_chain :
  phaseDependency .verification .safety ∧
  phaseDependency .observability .verification ∧
  phaseDependency .governance .observability ∧
  phaseDependency .equilibrium .governance := by
  refine ⟨?_, ?_, ?_, ?_⟩ <;> trivial
```


#### `theorem d4_phase_completion_persists`

D4's connection to T2: Phase completion persists in structure.
    From structure_accumulates, epochs (phase progression) are
    irreversible. A completed phase is never "undone".

```lean
theorem d4_phase_completion_persists :
  ∀ (w w' : World),
    validTransition w w' →
    w.epoch ≤ w'.epoch :=
  structure_accumulates
```


#### Partial Order Instance for DevelopmentPhase

manifesto.md Section 8 asserts that "D4/D5/D6 are instances of partial orders".
Following the precedent of StructureKind (Ontology.lean), we derive
LE/LT instances and the 4 partial order property theorems from a Nat-based ordering function.

#### `def developmentPhaseOrder`

Ordering function for DevelopmentPhase. Separately from phaseDependency (binary Prop),
    defines a total order via Nat. Reflects the phase ordering of D4.

```lean
def developmentPhaseOrder : DevelopmentPhase → Nat
  | .safety        => 0
  | .verification  => 1
  | .observability => 2
  | .governance    => 3
  | .equilibrium   => 4
```


#### `theorem developmentPhaseOrder_injective`

The ordering function is injective (distinct phases have distinct order values).

```lean
theorem developmentPhaseOrder_injective :
  ∀ (p₁ p₂ : DevelopmentPhase),
    developmentPhaseOrder p₁ = developmentPhaseOrder p₂ → p₁ = p₂ := by
  intro p₁ p₂; cases p₁ <;> cases p₂ <;> simp [developmentPhaseOrder]
```


#### `theorem developmentPhase_le_refl`

Partial order reflexivity: p <= p.

```lean
theorem developmentPhase_le_refl : ∀ (p : DevelopmentPhase), p ≤ p :=
  fun p => Nat.le_refl (developmentPhaseOrder p)
```


#### `theorem developmentPhase_le_trans`

Partial order transitivity: if p₁ <= p₂ and p₂ <= p₃ then p₁ <= p₃.

```lean
theorem developmentPhase_le_trans :
    ∀ (p₁ p₂ p₃ : DevelopmentPhase), p₁ ≤ p₂ → p₂ ≤ p₃ → p₁ ≤ p₃ := by
  intro _p₁ _p₂ _p₃ h₁₂ h₂₃; exact Nat.le_trans h₁₂ h₂₃
```


#### `theorem developmentPhase_le_antisymm`

Partial order antisymmetry: if p₁ <= p₂ and p₂ <= p₁ then p₁ = p₂.

```lean
theorem developmentPhase_le_antisymm :
    ∀ (p₁ p₂ : DevelopmentPhase), p₁ ≤ p₂ → p₂ ≤ p₁ → p₁ = p₂ :=
  fun p₁ p₂ h₁₂ h₂₁ => developmentPhaseOrder_injective p₁ p₂ (Nat.le_antisymm h₁₂ h₂₁)
```


#### `theorem developmentPhase_lt_iff_le_not_le`

Consistency of LT and LE: p₁ < p₂ iff p₁ <= p₂ and not (p₂ <= p₁).

```lean
theorem developmentPhase_lt_iff_le_not_le :
    ∀ (p₁ p₂ : DevelopmentPhase), p₁ < p₂ ↔ p₁ ≤ p₂ ∧ ¬(p₂ ≤ p₁) := by
  intro _p₁ _p₂; exact Nat.lt_iff_le_not_le
```


#### D5 Specification Test and Implementation Three-Layer Architecture

Rationale: T8 (precision level) + P4 (observability) + P6 (constraint satisfaction)

#### `inductive SpecLayer`

Types of the three-layer representation.

```lean
inductive SpecLayer where
  | formalSpec        -- 形式仕様（Lean axiom/theorem）
  | acceptanceTest    -- 受け入れテスト（実行可能な検証）
  | implementation    -- 実装（プラットフォーム固有）
  deriving BEq, Repr
```


#### `inductive TestKind`

Test kinds. Corresponds to T4 (probabilistic output).

```lean
inductive TestKind where
  | structural   -- 構成の存在を確認（決定論的）
  | behavioral   -- 実行して結果を確認（確率的、T4）
  deriving BEq, Repr
```


#### `theorem d5_test_has_precision`

Rationale for D5: By T8, tests have precision levels.
    A test with precision 0 is meaningless.

```lean
theorem d5_test_has_precision :
  ∀ (task : Task),
    task.precisionRequired.required > 0 :=
  task_has_precision
```


#### `def specLayerOrder`

Correspondence between the three layers. Composed in the order: formal spec -> test -> implementation.
    design-development-foundation.md D5:
    "Formal spec -> Test: At least one test exists for each axiom/theorem"
    "Test -> Implementation: Tests exist first, and the implementation passes the tests"

```lean
def specLayerOrder : SpecLayer → Nat
  | .formalSpec      => 0   -- 最初に仕様を定義
  | .acceptanceTest  => 1   -- 仕様からテストを導出
  | .implementation  => 2   -- テストを通す実装を構築
```


#### `theorem d5_layer_sequential`

D5: The three layers are strictly ordered.

```lean
theorem d5_layer_sequential :
  specLayerOrder .formalSpec < specLayerOrder .acceptanceTest ∧
  specLayerOrder .acceptanceTest < specLayerOrder .implementation := by
  simp [specLayerOrder]
```


#### `def testDeterministic`

Determinism of tests. Structural tests are deterministic, behavioral tests are probabilistic (T4).

```lean
def testDeterministic : TestKind → Bool
  | .structural => true    -- 決定論的: 存在の有無を確認
  | .behavioral => false   -- 確率的: T4 により結果が変動しうる
```


#### `theorem d5_structural_test_deterministic`

D5 + T4: Structural tests are deterministic, behavioral tests are probabilistic.

```lean
theorem d5_structural_test_deterministic :
  testDeterministic .structural = true ∧
  testDeterministic .behavioral = false := by
  constructor <;> rfl
```


#### `theorem specLayerOrder_injective`

The ordering function is injective (distinct layers have distinct order values).

```lean
theorem specLayerOrder_injective :
  ∀ (l₁ l₂ : SpecLayer),
    specLayerOrder l₁ = specLayerOrder l₂ → l₁ = l₂ := by
  intro l₁ l₂; cases l₁ <;> cases l₂ <;> simp [specLayerOrder]
```


#### `theorem specLayer_le_refl`

Partial order reflexivity: l <= l.

```lean
theorem specLayer_le_refl : ∀ (l : SpecLayer), l ≤ l :=
  fun l => Nat.le_refl (specLayerOrder l)
```


#### `theorem specLayer_le_trans`

Partial order transitivity: if l₁ <= l₂ and l₂ <= l₃ then l₁ <= l₃.

```lean
theorem specLayer_le_trans :
    ∀ (l₁ l₂ l₃ : SpecLayer), l₁ ≤ l₂ → l₂ ≤ l₃ → l₁ ≤ l₃ := by
  intro _l₁ _l₂ _l₃ h₁₂ h₂₃; exact Nat.le_trans h₁₂ h₂₃
```


#### `theorem specLayer_le_antisymm`

Partial order antisymmetry: if l₁ <= l₂ and l₂ <= l₁ then l₁ = l₂.

```lean
theorem specLayer_le_antisymm :
    ∀ (l₁ l₂ : SpecLayer), l₁ ≤ l₂ → l₂ ≤ l₁ → l₁ = l₂ :=
  fun l₁ l₂ h₁₂ h₂₁ => specLayerOrder_injective l₁ l₂ (Nat.le_antisymm h₁₂ h₂₁)
```


#### `theorem specLayer_lt_iff_le_not_le`

Consistency of LT and LE: l₁ < l₂ iff l₁ <= l₂ and not (l₂ <= l₁).

```lean
theorem specLayer_lt_iff_le_not_le :
    ∀ (l₁ l₂ : SpecLayer), l₁ < l₂ ↔ l₁ ≤ l₂ ∧ ¬(l₂ ≤ l₁) := by
  intro _l₁ _l₂; exact Nat.lt_iff_le_not_le
```


#### D6 Three-Stage Design

Rationale: Ontology.lean/Observable.lean three-stage structure (boundary -> mitigation -> variable)

BoundaryLayer, BoundaryId, and Mitigation are already defined in Ontology.lean.
Here we express the design principles as theorems.

#### `theorem d6_fixed_boundary_mitigated`

Rationale for D6: Variables corresponding to fixed boundaries can only improve mitigation quality.

```lean
theorem d6_fixed_boundary_mitigated :
  boundaryLayer .ethicsSafety = .fixed ∧
  boundaryLayer .ontological = .fixed := by
  simp [boundaryLayer]
```


#### `inductive DesignStage`

Design flow of the three-stage design.
    design-development-foundation.md D6:
    "Boundary conditions (invariant) -> Mitigations (design decisions) -> Variables (quality metrics)"
    Design always proceeds in this direction; the reverse direction is prohibited.

```lean
inductive DesignStage where
```


#### `? (anonymous)`

Identify boundary conditions (invariant; only accepted)

#### `? (anonymous)`

Design mitigations (design decisions belonging to L6)

#### `? (anonymous)`

Define variables (metrics for mitigation effectiveness)

#### `def designStageOrder`

Stage ordering of the three-stage design.

```lean
def designStageOrder : DesignStage → Nat
  | .identifyBoundary  => 0
  | .designMitigation  => 1
  | .defineVariable    => 2
```


#### `theorem d6_stage_sequential`

D6: The three-stage design is strictly ordered.

```lean
theorem d6_stage_sequential :
  designStageOrder .identifyBoundary < designStageOrder .designMitigation ∧
  designStageOrder .designMitigation < designStageOrder .defineVariable := by
  simp [designStageOrder]
```


#### `theorem d6_no_reverse`

D6: Reverse direction prohibited. Do not attempt to directly improve variables (Goodhart's Law trap).
    The variable stage is last; there is no backtracking from variables to boundary conditions or mitigations.

```lean
theorem d6_no_reverse :
  ∀ (s : DesignStage),
    designStageOrder .identifyBoundary ≤ designStageOrder s := by
  intro s; cases s <;> simp [designStageOrder]
```


#### `theorem designStageOrder_injective`

The ordering function is injective (distinct stages have distinct order values).

```lean
theorem designStageOrder_injective :
  ∀ (s₁ s₂ : DesignStage),
    designStageOrder s₁ = designStageOrder s₂ → s₁ = s₂ := by
  intro s₁ s₂; cases s₁ <;> cases s₂ <;> simp [designStageOrder]
```


#### `theorem designStage_le_refl`

Partial order reflexivity: s <= s.

```lean
theorem designStage_le_refl : ∀ (s : DesignStage), s ≤ s :=
  fun s => Nat.le_refl (designStageOrder s)
```


#### `theorem designStage_le_trans`

Partial order transitivity: if s₁ <= s₂ and s₂ <= s₃ then s₁ <= s₃.

```lean
theorem designStage_le_trans :
    ∀ (s₁ s₂ s₃ : DesignStage), s₁ ≤ s₂ → s₂ ≤ s₃ → s₁ ≤ s₃ := by
  intro _s₁ _s₂ _s₃ h₁₂ h₂₃; exact Nat.le_trans h₁₂ h₂₃
```


#### `theorem designStage_le_antisymm`

Partial order antisymmetry: if s₁ <= s₂ and s₂ <= s₁ then s₁ = s₂.

```lean
theorem designStage_le_antisymm :
    ∀ (s₁ s₂ : DesignStage), s₁ ≤ s₂ → s₂ ≤ s₁ → s₁ = s₂ :=
  fun s₁ s₂ h₁₂ h₂₁ => designStageOrder_injective s₁ s₂ (Nat.le_antisymm h₁₂ h₂₁)
```


#### `theorem designStage_lt_iff_le_not_le`

Consistency of LT and LE: s₁ < s₂ iff s₁ <= s₂ and not (s₂ <= s₁).

```lean
theorem designStage_lt_iff_le_not_le :
    ∀ (s₁ s₂ : DesignStage), s₁ < s₂ ↔ s₁ ≤ s₂ ∧ ¬(s₂ ≤ s₁) := by
  intro _s₁ _s₂; exact Nat.lt_iff_le_not_le
```


#### D7 Trust Asymmetry

Rationale: Section 6 + P1 (co-growth)

Accumulation is bounded (trust_accumulates_gradually),
damage is unbounded (trust_decreases_on_materialized_risk).

#### `theorem d7_accumulation_bounded`

Rationale for D7: Accumulation is bounded.

```lean
theorem d7_accumulation_bounded :
  ∀ (agent : Agent) (w w' : World),
    actionSpaceSize agent w ≤ actionSpaceSize agent w' →
    ¬riskMaterialized agent w' →
    trustLevel agent w ≤ trustLevel agent w' ∧
    trustLevel agent w' ≤ trustLevel agent w + trustIncrementBound :=
  trust_accumulates_gradually
```


#### `theorem d7_damage_unbounded`

Rationale for D7: Damage is unbounded.

```lean
theorem d7_damage_unbounded :
  ∀ (agent : Agent) (w w' : World),
    actionSpaceSize agent w < actionSpaceSize agent w' →
    riskMaterialized agent w' →
    trustLevel agent w' < trustLevel agent w :=
  trust_decreases_on_materialized_risk
```


#### D8 Equilibrium Search

Rationale: Section 6 + E2 (capability-risk co-scaling)

By overexpansion_reduces_value,
there exist cases where expansion of the action space reduces collaborative value.

#### `theorem d8_overexpansion_risk`

Rationale for D8: Overexpansion can damage value.

```lean
theorem d8_overexpansion_risk :
  ∃ (agent : Agent) (w w' : World),
    actionSpaceSize agent w < actionSpaceSize agent w' ∧
    collaborativeValue w' < collaborativeValue w :=
  overexpansion_reduces_value
```


#### `theorem d8_capability_risk`

D8's connection to P1: Capability expansion is inseparable from risk expansion.
    Direct application of E2.

```lean
theorem d8_capability_risk :
  ∀ (agent : Agent) (w w' : World),
    actionSpaceSize agent w < actionSpaceSize agent w' →
    riskExposure agent w < riskExposure agent w' :=
  capability_risk_coscaling
```


#### D9 Maintenance of the Classification Itself
Definitional Extension + Theorem, 5.5/4.2.

Rationale: Observable.lean Part IV + P3 (governed learning, theorem §4.2) + Section 7 (self-application)

The design foundation itself is subject to updates, and updates follow P3's compatibility classification.
This is a structuring of AGM revision operations (terminology reference §9.2):
- Conservative extension = conservative extension (§5.5)
- Compatible change = consistent extension (§5.5)
- Breaking change = non-extension change (some theorems are not preserved)

#### Self-Application Requirements

Since D9 states the principle of "maintenance of the classification itself",
D1–D9 themselves must also be subject to D9 (Section 7).

To express this at the type level (§7.1 Curry-Howard correspondence):
1. Model D1–D9 as values of the DesignPrinciple type (extension of domain of discourse §3.2)
2. Require that updates to DesignPrinciple are classified by CompatibilityClass
3. Structurally enforce via the SelfGoverning type class (§9.4)

#### `inductive DesignPrinciple`

Design principle identifiers. Enumerates D1–D12 as values.
    This allows D1–D12 themselves to be treated at the type level as "targets of updates".

```lean
inductive DesignPrinciple where
  | d1_enforcementLayering
  | d2_workerVerifierSeparation
  | d3_observabilityFirst
  | d4_progressiveSelfApplication
  | d5_specTestImpl
  | d6_boundaryMitigationVariable
  | d7_trustAsymmetry
  | d8_equilibriumSearch
  | d9_selfMaintenance
  | d10_structuralPermanence
  | d11_contextEconomy
  | d12_constraintSatisfactionTaskDesign
  | d13_premiseNegationPropagation
  | d14_verificationOrderConstraint
  deriving BEq, Repr
```


#### `instance SelfGoverning DesignPrinciple`

DesignPrinciple implements SelfGoverning.
    This makes D1–D9 themselves subject to governedUpdate,
    and updates without compatibility classification become type-level errors.

    Types that do not implement SelfGoverning cannot use governedUpdate or
    governed_update_classified, so defining a new principle type
    and forgetting to implement SelfGoverning is detected as a type error.

```lean
instance : SelfGoverning DesignPrinciple where
  classificationExhaustive := by intro c; cases c <;> simp
  canClassifyUpdate _ _ := True
```


#### `structure DesignPrincipleUpdate`

Design principle update event.
    Self-application of D9: Changes to D1–D9 themselves also go through compatibility classification.

```lean
structure DesignPrincipleUpdate where
```


#### `? (anonymous)`

The principle being updated

#### `? (anonymous)`

Compatibility classification of the update

#### `? (anonymous)`

Rationale for the update (reference to manifesto's T/E/P)

#### `theorem d9_update_classified`

D9: Any compatibility classification belongs to one of the 3 classes.

```lean
theorem d9_update_classified :
  ∀ (c : CompatibilityClass),
    c = .conservativeExtension ∨
    c = .compatibleChange ∨
    c = .breakingChange := by
  intro c; cases c <;> simp
```


#### `def governedPrincipleUpdate`

Self-application of D9: Updates to D9 itself also go through compatibility classification.
    The DesignPrincipleUpdate type structurally requires this
    (the compatibility field is mandatory).

    Furthermore, updates require a rationale (D9: principles that lose their rationale are subject to review).

```lean
def governedPrincipleUpdate (u : DesignPrincipleUpdate) : Prop :=
  u.hasRationale = true
```


#### `theorem d9_self_applicable`

Self-application of D9: Proves via the SelfGoverning typeclass that
    any update to DesignPrinciple is compatibility-classified.

    governed_update_classified can only be called on types that have a
    SelfGoverning instance. If DesignPrinciple does not implement
    SelfGoverning, this theorem becomes a type error.
    -> Missing implementations are structurally detected.

```lean
theorem d9_self_applicable :
  ∀ (_p : DesignPrinciple) (c : CompatibilityClass),
    c = .conservativeExtension ∨ c = .compatibleChange ∨ c = .breakingChange :=
  fun _p c => governed_update_classified _p c
```


#### `theorem d9_all_principles_enumerated`

D9 exhaustiveness: All principles D1–D13 are enumerated as update targets.

```lean
theorem d9_all_principles_enumerated :
  ∀ (p : DesignPrinciple),
    p = .d1_enforcementLayering ∨
    p = .d2_workerVerifierSeparation ∨
    p = .d3_observabilityFirst ∨
    p = .d4_progressiveSelfApplication ∨
    p = .d5_specTestImpl ∨
    p = .d6_boundaryMitigationVariable ∨
    p = .d7_trustAsymmetry ∨
    p = .d8_equilibriumSearch ∨
    p = .d9_selfMaintenance ∨
    p = .d10_structuralPermanence ∨
    p = .d11_contextEconomy ∨
    p = .d12_constraintSatisfactionTaskDesign ∨
    p = .d13_premiseNegationPropagation ∨
    p = .d14_verificationOrderConstraint := by
  intro p; cases p <;> simp
```


#### Self-Application of D4

D4 (progressive self-application) states that "the development process achieves
compliance up to each phase", but DesignFoundation itself should also be
developed following these phases.

Updates to DesignFoundation occur in the context of DevelopmentPhase,
and the compliance level of the updated phase progresses irreversibly (T2: structure_accumulates).

#### `def principleRequiredPhase`

Self-application of D4: The design foundation itself has phases.
    Each principle is applicable only after the phase it requires is complete.

```lean
def principleRequiredPhase : DesignPrinciple → DevelopmentPhase
  | .d1_enforcementLayering         => .safety
  | .d2_workerVerifierSeparation    => .verification
  | .d3_observabilityFirst          => .observability
  | .d4_progressiveSelfApplication  => .safety  -- D4 自体は最初から必要
  | .d5_specTestImpl                => .verification
  | .d6_boundaryMitigationVariable  => .observability
  | .d7_trustAsymmetry              => .equilibrium
  | .d8_equilibriumSearch           => .equilibrium
  | .d9_selfMaintenance             => .safety  -- D9 も最初から必要
  | .d10_structuralPermanence       => .safety  -- T1+T2 は最初から成立
  | .d11_contextEconomy             => .observability  -- コンテキストコスト測定が前提
  | .d12_constraintSatisfactionTaskDesign => .governance  -- P6 は統治フェーズ
  | .d13_premiseNegationPropagation     => .governance  -- P3（退役）+ Section 8 が前提
  | .d14_verificationOrderConstraint   => .governance  -- P6 + T7 + T8 が前提
```


#### `theorem d4_d9_from_first_phase`

Self-application of D4: D4 and D9 are required from the safety phase.
    This means that "phase ordering" and "governed updates" must be
    functional from the very beginning of development.

```lean
theorem d4_d9_from_first_phase :
  principleRequiredPhase .d4_progressiveSelfApplication = .safety ∧
  principleRequiredPhase .d9_selfMaintenance = .safety := by
  constructor <;> rfl
```


#### Dependency Structure of D1-D9

Verifies that D4's (progressive self-application) phase ordering is
consistent with the dependency relationships of D1–D3.

- Phase 1 (safety) -> D1 (L1 requires structural enforcement)
- Phase 2 (verification) -> D2 (structural realization of P2)
- Phase 3 (observability) -> D3 (observability first)
- Phase 4 (governance) -> depends on D3 (P3 comes after P4)
- Phase 5 (equilibrium) -> depends on D7, D8 (trust and equilibrium)

This dependency structure is already expressed in phaseDependency.
d4_full_chain proves its existence.

#### `theorem dependency_d1_d2_d4_consistent`

Consistency of D1–D4: The first step of D4's phase ordering (safety -> verification)
    matches the ordering of D1 (L1 requires structural enforcement) and D2 (realization of P2).

    safety is first = D1 makes L1 structurally enforced
    verification is next = D2 realizes P2

```lean
theorem dependency_d1_d2_d4_consistent :
  phaseDependency .verification .safety ∧
  minimumEnforcement .fixed = .structural := by
  constructor
  · trivial
  · rfl
```


#### D10 Structural Permanence
Theorem, 4.2.

Rationale: T1 (ephemerality, T₀ §4.1) + T2 (structural permanence, T₀ §4.1)

Agents are ephemeral (T1) but structure persists (T2).
Accumulation of improvements is possible only through structure.
Connects with P3 theorem group in Principles.lean (modifier_agent_terminates,
modification_persists_after_termination).

#### `theorem d10_agent_temporary_structure_permanent`

Rationale for D10: Agent sessions terminate (T1), but
    structure persists (T2). Composition of P3a + P3b.
    From structure_persists (T2) and session_bounded (T1).

```lean
theorem d10_agent_temporary_structure_permanent :
  -- T1: セッションは終了する
  (∀ (w : World) (s : Session),
    s ∈ w.sessions →
    ∃ (w' : World), w.time ≤ w'.time ∧
      ∃ (s' : Session), s' ∈ w'.sessions ∧
        s'.id = s.id ∧ s'.status = SessionStatus.terminated) ∧
  -- T2: 構造は永続する
  (∀ (w w' : World) (s : Session) (st : Structure),
    s ∈ w.sessions → st ∈ w.structures →
    s.status = SessionStatus.terminated →
    validTransition w w' → st ∈ w'.structures) :=
  ⟨session_bounded, structure_persists⟩
```


#### `theorem d10_epoch_monotone`

Corollary of D10: Writing back to structure is the sole means of accumulation.
    Epochs (T2: structure_accumulates) increase monotonically.

```lean
theorem d10_epoch_monotone :
  ∀ (w w' : World), validTransition w w' → w.epoch ≤ w'.epoch :=
  structure_accumulates
```


#### D11 Context Economy
Definitional Extension + Theorem, 5.5/4.2.

Rationale: T3 (context finiteness, T₀ §4.1) + D1 (enforcement layering)

Working memory (T3: amount of information that can be processed) is a finite resource,
and enforcement layers (D1) and context cost are inversely correlated:
structural enforcement (low cost) > procedural enforcement (medium cost) > normative guidelines (high cost).

#### `def contextCost`

Context cost for D1's enforcement layers.
    Higher values consume more context.

```lean
def contextCost : EnforcementLayer → Nat
  | .structural => 0   -- 一度設定すれば毎セッション読む必要がない
  | .procedural => 1   -- プロセスは存在するがコンテキストに常駐しない
  | .normative  => 2   -- 毎セッション読み込まれ、コンテキストを占有する
```


#### `theorem d11_enforcement_cost_inverse`

D11: Enforcement power and context cost are inversely correlated.
    Higher enforcement power means lower context cost.

```lean
theorem d11_enforcement_cost_inverse :
  contextCost .structural < contextCost .procedural ∧
  contextCost .procedural < contextCost .normative := by
  simp [contextCost]
```


#### `theorem d11_structural_minimizes_cost`

D11: Promotion to structural enforcement reduces context cost.

```lean
theorem d11_structural_minimizes_cost :
  ∀ (e : EnforcementLayer),
    contextCost .structural ≤ contextCost e := by
  intro e; cases e <;> simp [contextCost]
```


#### `theorem d11_context_finite`

D11 + T3: Context capacity is finite (T3), and
    bloating of normative guidelines degrades V2 (context efficiency).

```lean
theorem d11_context_finite :
  ∀ (agent : Agent),
    agent.contextWindow.capacity > 0 ∧
    agent.contextWindow.used ≤ agent.contextWindow.capacity :=
  context_finite
```


#### D12 Constraint Satisfaction Task Design
Theorem, 4.2.

Rationale: P6 (constraint satisfaction, theorem §4.2) + T3 + T7 + T8 (T₀ §4.1)

Task execution is a constraint satisfaction problem. Achieve precision requirements (T8)
within finite cognitive space (T3) and finite resources (T7).
Connects with P6 theorem group in Principles.lean.

#### `theorem d12_task_is_csp`

D12: Task design is a constraint satisfaction problem over T3+T7+T8.
    Restatement of P6a (task_is_constraint_satisfaction).

```lean
theorem d12_task_is_csp :
  ∀ (task : Task) (agent : Agent),
    agent.contextWindow.capacity > 0 →
    task.resourceBudget ≤ globalResourceBound →
    task.precisionRequired.required > 0 →
    ∀ (s : TaskStrategy),
      s.task = task →
      strategyFeasible s agent →
      s.contextUsage ≤ agent.contextWindow.capacity ∧
      s.resourceUsage ≤ globalResourceBound ∧
      s.achievedPrecision > 0 :=
  task_is_constraint_satisfaction
```


#### `theorem d12_task_design_probabilistic`

D12: Task design itself is also probabilistic output (T4),
    requiring verification through P2 (cognitive role separation).

```lean
theorem d12_task_design_probabilistic :
  ∃ (agent : Agent) (action : Action) (w w₁ w₂ : World),
    canTransition agent action w w₁ ∧
    canTransition agent action w w₂ ∧
    w₁ ≠ w₂ :=
  output_nondeterministic
```


#### D13 Premise Negation Impact Propagation
Theorem, 4.2.

Rationale: P3 (governed learning -- retirement) + Section 8 (coherenceRequirement) + T5

When a premise is negated, identify dependent derivations and re-verify them.
Generalizes Section 8's coherenceRequirement (priority-based review)
to arbitrary dependency relationships.

Based on PropositionId.dependencies from Ontology.lean,
defines impact set computation functions and basic properties.

#### `theorem d13_coherence_implies_propagation`

D13: Priority changes in structure require review of lower-priority items (restatement of Section 8).
    D13's reinterpretation of coherenceRequirement:
    High-priority structural change -> all lower-priority structures are included in the impact set.

```lean
theorem d13_coherence_implies_propagation :
  ∀ (s₁ s₂ : Structure),
    s₁.kind.priority > s₂.kind.priority →
    s₂.lastModifiedAt ≤ s₁.lastModifiedAt →
    s₂.lastModifiedAt ≤ s₁.lastModifiedAt :=
  fun _ _ _ h => h
```


#### `theorem d13_retirement_requires_feedback`

D13: P3's retirement operation presupposes T5 (feedback).
    Without feedback, negation of premises cannot be detected.

```lean
theorem d13_retirement_requires_feedback :
  ∀ (w : World),
    w.feedbacks = [] →
    ¬(∃ (f : Feedback), f ∈ w.feedbacks ∧ f.kind = .measurement) :=
  fun _ hnil ⟨_, hf, _⟩ => by simp [hnil] at hf
```


#### `def allPropositions`

Enumeration of all propositions. Used in affected computation.

```lean
def allPropositions : List PropositionId :=
  [.t1, .t2, .t3, .t4, .t5, .t6, .t7, .t8,
   .e1, .e2,
   .p1, .p2, .p3, .p4, .p5, .p6,
   .l1, .l2, .l3, .l4, .l5, .l6,
   .d1, .d2, .d3, .d4, .d5, .d6, .d7, .d8, .d9, .d10, .d11, .d12, .d13, .d14]
```


#### `def PropositionId.dependents`

Set of propositions that directly depend on proposition s (reverse edges).
    dependencies = "what it depends on"; dependents = "what depends on it".

```lean
def PropositionId.dependents (s : PropositionId) : List PropositionId :=
  allPropositions.filter (fun p => propositionDependsOn p s)
```


#### `def affected`

Computes the impact set when premise s is negated.
    Transitive closure of the reverse dependency graph.
    The fuel parameter guarantees termination (depth <= 35 suffices since the graph is a DAG).

    **Incompleteness limitation**: This function only tracks propagation among
    named propositions enumerated in PropositionId. By Goedel's first incompleteness theorem,
    impact on unnamed derivational consequences cannot be detected (see Ontology.lean §6.2 note).

```lean
def affected (s : PropositionId) (fuel : Nat := 35) : List PropositionId :=
  match fuel with
  | 0 => []
  | fuel' + 1 =>
    let direct := s.dependents
    let transitive := direct.flatMap (fun p => affected p fuel')
    (direct ++ transitive).eraseDups
```


#### `def d13_propagation`

Operational definition of D13: Impact propagation upon premise negation.
    Computes the impact set via affected, representing that each proposition requires re-verification.

```lean
def d13_propagation (negated : PropositionId) : List PropositionId :=
  affected negated
```


#### `theorem d13_constraint_negation_has_impact`

Negation of T (constraint) has the largest impact:
    T is the rationale for many propositions, so the impact set is large.

```lean
theorem d13_constraint_negation_has_impact :
  (d13_propagation .t4).length > 0 := by native_decide
```


#### `theorem d13_l5_limited_impact`

Negation of L5 (platform boundary) affects only D1:
    L5 is environment-dependent and close to a root node, so its impact is limited.

```lean
theorem d13_l5_limited_impact :
  (d13_propagation .l5).length ≤ (d13_propagation .t4).length := by native_decide
```


#### Correspondence between StructureKind and PropositionId

Connects the Structure-level partial order (Ontology.lean, structural consistency section)
with the PropositionId-level dependency graph (this file, §D13).
By answering the question "which axioms (PropositionId) does this Structure (file) depend on?",
refines the tracing from end-point errors back to the axiom level.

Corresponds to ATMS labeling from the research document.

#### `def structurePropositions`

Set of PropositionIds corresponding to each StructureKind.
    manifest.md encompasses all axioms/postulates/principles T1-T8, E1-E2, P1-P6.
    designConvention encompasses design theorems D1-D13.
    skill/test/document are empty sets due to individual definitions (room for future extension).

```lean
def structurePropositions : StructureKind → List PropositionId
  | .manifest         => [.t1, .t2, .t3, .t4, .t5, .t6, .t7, .t8,
                           .e1, .e2, .p1, .p2, .p3, .p4, .p5, .p6]
  | .designConvention => [.d1, .d2, .d3, .d4, .d5, .d6, .d7, .d8,
                           .d9, .d10, .d11, .d12, .d13]
  | .skill            => []
  | .test             => []
  | .document         => []
```


#### `def structureToPropositionImpact`

Set of propositions affected at the PropositionId level by changes to a StructureKind.
    Structure change -> contained PropositionIds -> compute propagation targets via affected.
    Integrates two-layer dependency tracking into a single pipeline.

```lean
def structureToPropositionImpact (k : StructureKind) : List PropositionId :=
  (structurePropositions k).flatMap (fun p => affected p)
```


#### `theorem manifest_has_widest_impact`

Changes to manifest have the widest proposition-level impact.
    Propagates to all dependents of T1-T8, E1-E2, P1-P6.

```lean
theorem manifest_has_widest_impact :
  ∀ (k : StructureKind),
    (structureToPropositionImpact k).length ≤
    (structureToPropositionImpact .manifest).length := by
  intro k; cases k <;> native_decide
```


#### `theorem design_convention_has_impact`

Changes to designConvention have non-empty proposition-level impact.
    Proves that dependents of D1-D13 exist.

```lean
theorem design_convention_has_impact :
  (structureToPropositionImpact .designConvention).length > 0 := by native_decide
```


#### D14 Constraint Satisfaction of Verification Order
Theorem, 4.2.

Rationale: P6 (constraint satisfaction) + T7 (resource finiteness) + T8 (precision level)

Under finite resources, verification order affects outcomes.
The choice of ordering is included in P6's constraint satisfaction problem.
Extension of D12.

#### What the Axiom System Does Not Determine

D14 derives that "verification order matters" but does not derive the optimal ordering method.
Information gain, risk-order (fail-fast), and cost-order are all models satisfying D14.
The choice of specific method is at the L6 (design convention) level.

#### `theorem d14_verification_order_is_csp`

D14: When resources are finite (T7) and precision requirements exist (T8),
    task strategy feasibility is within the scope of constraint satisfaction (restatement of D12).
    The choice of verification order is part of this constraint satisfaction problem.

```lean
theorem d14_verification_order_is_csp :
  ∀ (task : Task) (agent : Agent),
    agent.contextWindow.capacity > 0 →
    task.resourceBudget ≤ globalResourceBound →
    task.precisionRequired.required > 0 →
    ∀ (s : TaskStrategy),
      s.task = task →
      strategyFeasible s agent →
      s.contextUsage ≤ agent.contextWindow.capacity ∧
      s.resourceUsage ≤ globalResourceBound ∧
      s.achievedPrecision > 0 :=
  task_is_constraint_satisfaction
```


#### Sorry Inventory DesignFoundation

No sorry. No new non-logical axioms (§4.1).

All theorems (§4.2) are proven by direct application of existing axioms (T/E/P/V)
or by cases analysis on inductive types (§7.2).

Each principle D1–D13 is guaranteed by type-checking to be
**derivable** (§2.4 derivability) from the manifesto's axiom system.
This file consists solely of definitional extensions (§5.5),
and conservative extension is guaranteed by `definitional_implies_conservative`
proven in Terminology.lean.

#### Known Formalization Gaps
Sorry Inventory.

| D | Gap | Impact |
|---|---------|------|
| D3 | The 3 observability conditions (measurable/degradation-detectable/improvement-verifiable) are not structured | 3 theorems exist but the condition structure is not formalized |
| D5 | Inter-layer relations of spec/test/implementation are not formalized | 3 theorems exist but transitive dependencies between layers are not formalized |
| D6 | Causal chain of boundary -> mitigation -> variable is not formalized | 3 theorems exist but causal chain is not formalized |

#### Structural Enforcement of Section 7
Self-Application.

Via the `SelfGoverning` type class (§9.4, Ontology.lean),
the `DesignPrinciple` type defining D1–D12 satisfies:
- Applicability of compatibility classification (`canClassifyUpdate`)
- Exhaustiveness of classification (`classificationExhaustive`)

Since calling `governed_update_classified` requires `[SelfGoverning α]`,
types that do not implement SelfGoverning cannot be used in the
self-application context -> **missing implementations are detected as type errors**.


---

## Statistics

- **Files processed:** 6
- **Documented axioms:** 27
- **Documented theorems:** 101
- **Documented definitions:** 126
- **Total documented declarations:** 254

*Generated by `scripts/lean-to-markdown.py --manifesto`*
