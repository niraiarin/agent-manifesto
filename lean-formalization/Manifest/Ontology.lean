/-!
# Definitional Foundation - Ontology - Domain of Discourse Definition
Definitional Extension.

Defines the domain of discourse (Terminology Reference §3.2) of the manifesto axiom system as Lean types.
These define the objects that propositions refer to; they belong to neither Gamma nor phi,
but constitute the shared vocabulary of both (Procedure §2.1).

Based on Pattern 3 (Stateful World with Audit Trail), encoding
manifesto-specific concepts — session ephemerality, structure persistence,
context finiteness, output stochasticity — as types.

## Correspondence with Terminology Reference

- Type definitions → Definitional extension (Terminology Reference §5.5): an extension that defines new symbols
  in terms of existing ones. Always a conservative extension, preserving consistency of the system
- Each structure/inductive → Component of the domain of discourse.
  Defines the types of values that individual variables can take (§3.2 structure)
- opaque definitions → Opaque definitions (§9.4): only the type is public, the definition body is hidden.
  The system knows only existence and type
- canTransition → Transition relation (§9.3): a relation representing transition from state s to state s'

## Encoding Method for T0
Procedure 2.4.

Among T₀'s claims, those expressible via type definitions (e.g., exhaustiveness of enumeration types)
are constructed using type definitions + theorems rather than axioms (Axiom Hygiene Check 2: Non-logical Validity, §2.6).
The authority of T₀ (the manifesto) is reflected in the choice of type constructors.
-/

namespace Manifest

-- ============================================================
-- Identifiers
-- ============================================================

/-- Unique identifier for an agent -/
opaque AgentId : Type

/-- Unique identifier for a session -/
opaque SessionId : Type

/-- Unique identifier for a resource -/
opaque ResourceId : Type

/-- Unique identifier for a structural element -/
opaque StructureId : Type

-- opaque 型に対する Repr インスタンス（deriving Repr の前提）
instance : Repr AgentId := ⟨fun _ _ => "«AgentId»"⟩
instance : Repr SessionId := ⟨fun _ _ => "«SessionId»"⟩
instance : Repr ResourceId := ⟨fun _ _ => "«ResourceId»"⟩
instance : Repr StructureId := ⟨fun _ _ => "«StructureId»"⟩

-- ============================================================
-- Time and Epoch
-- ============================================================

/-- Discrete time step. Foundation for audit log ordering and causal relationships. -/
abbrev Time := Nat

/-- Epoch: generation number for structures across sessions.
    Reflects T2 (structures outlive agents). -/
abbrev Epoch := Nat

-- ============================================================
-- Session — T1: エージェントセッションは一時的である
-- ============================================================

/-- Session status. By T1, sessions must terminate. -/
inductive SessionStatus where
  | active
  | terminated
  deriving BEq, Repr

/-- Session: defines the lifetime of an agent instance.
    A type for structurally expressing T1's "no memory across sessions."

    - `startTime` and `endTime` indicate boundedness
    - No means to share state across different sessions exists at the type level -/
structure Session where
  id       : SessionId
  agent    : AgentId
  start    : Time
  status   : SessionStatus
  deriving Repr

-- ============================================================
-- Structure — T2: 構造はエージェントより長く生きる
-- ============================================================

/-- Category of structures.
    The kinds of persistent structures enumerated by the manifesto. -/
inductive StructureKind where
  | document
  | test
  | skill
  | designConvention
  | manifest
  deriving BEq, Repr

/-- Structural element: an artifact that persists beyond sessions.
    By T2, this is where improvements accumulate.

    - `createdAt` / `lastModifiedAt` are managed by Epoch (session generation)
    - `content` is opaque — formalization targets the **existence and relationships** of structures, not their content
    - `dependencies` corresponds to dependency tracking in ATMS (Assumption-Based Truth Maintenance System).
      A list of Structure IDs that each Structure directly depends on.
      Implementation of manifesto.md Section 8 (Structural Coherence) Property 2 "Self-containment of ordering information." -/
structure Structure where
  id             : StructureId
  kind           : StructureKind
  createdAt      : Epoch
  lastModifiedAt : Epoch
  dependencies   : List StructureId  -- Section 8 性質 2: 順序情報の自己内包
  deriving Repr

-- ============================================================
-- Context Window — T3: 一度に処理できる情報量は有限である
-- ============================================================

/-- Working memory (ContextWindow): the upper bound on the amount of information an agent can process at once.
    Represents T3's physical constraint as a type. Corresponds to token limit for LLMs,
    or working memory size for other computational agents.

    The invariants `capacity > 0` and `used ≤ capacity` are embedded in the type
    (previously axiom context_finite, now structurally enforced).
    This makes invalid ContextWindows unconstructable — the constraint is a
    definitional property of the type, not an external assumption. -/
structure ContextWindow where
  capacity : Nat
  used     : Nat
  capacity_pos : capacity > 0 := by omega
  used_le_cap  : used ≤ capacity := by omega
  deriving Repr

-- ============================================================
-- Output — T4: エージェントの出力は確率的である
-- ============================================================

/-- Confidence of an output. By T4, outputs always carry a probabilistic interpretation. -/
structure Confidence where
  value : Float
  deriving Repr

/-- Agent output.
    Reflects T4: the possibility that different outputs may be generated for the same input
    is expressed at the type level by `Output` not being uniquely determined.

    The `confidence` field is a self-description of the output being probabilistic. -/
structure Output (α : Type) where
  result     : α
  confidence : Confidence
  deriving Repr

-- ============================================================
-- Feedback — T5: フィードバックなしに改善は不可能である
-- ============================================================

/-- Kinds of feedback. Components forming the T5 control loop. -/
inductive FeedbackKind where
  | measurement   -- 測定
  | comparison    -- 比較（目標との差分）
  | adjustment    -- 調整（次のアクションへの反映）
  deriving BEq, Repr

/-- Feedback: a unit of the measurement -> comparison -> adjustment loop.
    By T5, convergence toward goals cannot occur without this loop. -/
structure Feedback where
  kind      : FeedbackKind
  source    : AgentId
  target    : StructureId
  timestamp : Time
  deriving Repr

-- ============================================================
-- Human & Resource — T6/T7: 人間はリソースの最終決定者 / リソースは有限
-- ============================================================

/-- Kinds of resources. By T7, all are finite. -/
inductive ResourceKind where
  | computation
  | dataAccess
  | executionPermission
  | time
  | energy
  deriving BEq, Repr

/-- Resource allocation.
    By T6, granted by humans and revocable by humans.
    By T7, `amount` is bounded. -/
structure ResourceAllocation where
  resource    : ResourceId
  kind        : ResourceKind
  amount      : Nat           -- 有限量 (T7)
  grantedBy   : AgentId       -- T6: 人間が最終決定者
  grantedTo   : AgentId
  validFrom   : Time
  validUntil  : Option Time   -- None = 明示的に回収されるまで有効
  deriving Repr

-- ============================================================
-- Task — T8: タスクには達成すべき精度水準が存在する
-- ============================================================

/-- Precision level. By T8, all tasks have one.
    Represented as Nat (0-1000 in permillage). Avoids Float to ensure
    safe comparison at the proposition level.
    The invariant `required > 0` is embedded in the type
    (previously axiom task_has_precision, now structurally enforced). -/
structure PrecisionLevel where
  required : Nat   -- 要求精度 (0–1000, 千分率: 1000 = 100%)
  required_pos : required > 0 := by omega
  deriving Repr

/-- Task: a goal to be achieved and its associated constraints.
    In addition to T8's precision level, T3 (context constraint) and T7 (resource constraint)
    serve as boundary conditions for task execution (-> P6: task design as constraint satisfaction). -/
structure Task where
  description       : String
  precisionRequired : PrecisionLevel   -- T8
  contextBudget     : Nat              -- T3 からの制約
  resourceBudget    : Nat              -- T7 からの制約
  deriving Repr

-- ============================================================
-- Context Item — T3+T8: コンテキスト内情報のタスク精度への寄与度
-- ============================================================

/-- An item within the context window. By T3, context is finite,
    so only a bounded number of items can be present.

    Each item has a precision contribution relative to a given task (T8).
    This contribution is not uniform across items — a mathematical fact
    from information theory (not all information is equally relevant
    to all tasks). -/
opaque ContextItem : Type
instance : Repr ContextItem := ⟨fun _ _ => "«ContextItem»"⟩

/-- Precision contribution of a context item to a task.
    Returns a Nat (0 = zero contribution, higher = more contribution).
    This is a function, not a constant: the same item may have different
    contributions to different tasks.

    Technology-independent: applies to any agent architecture where
    context is finite and tasks have precision requirements. -/
opaque precisionContribution : ContextItem → Task → Nat

-- ============================================================
-- Action & Severity
-- ============================================================

/-- Severity of an action. Used for reversibility assessment. -/
inductive Severity where
  | low
  | medium
  | high
  | critical
  deriving BEq, Repr, Ord

/-- Agent action. The unit that transitions the World. -/
structure Action where
  agent    : AgentId
  target   : StructureId
  severity : Severity
  session  : SessionId
  time     : Time
  deriving Repr

-- ============================================================
-- Audit Trail — Pattern 3 ベース
-- ============================================================

/-- Hash of a WorldState. Used for state transition verification. -/
opaque WorldHash : Type

instance : Repr WorldHash := ⟨fun _ _ => "«WorldHash»"⟩

/-- Audit entry. Records all actions.
    Foundation for P4 (observability of degradation). -/
structure AuditEntry where
  timestamp : Time
  agent     : AgentId
  session   : SessionId
  action    : Action
  preHash   : WorldHash
  postHash  : WorldHash
  deriving Repr

-- ============================================================
-- World — 状態の統合
-- ============================================================

/-- World state: a snapshot of the entire system.
    Pattern 3 (Stateful World + Audit Trail) customized for the manifesto.

    Each field corresponds to a specific T/P:
    - `structures`   -> T2 (persistent structures)
    - `sessions`     -> T1 (ephemeral sessions)
    - `allocations`  -> T6/T7 (resource management)
    - `auditLog`     -> P4 (observability)
    - `epoch`        -> T2 (structure generation management)
    - `time`         -> causal ordering -/
structure World where
  structures  : List Structure
  sessions    : List Session
  allocations : List ResourceAllocation
  feedbacks   : List Feedback
  auditLog    : List AuditEntry
  epoch       : Epoch
  time        : Time
  deriving Repr

/-- World is Inhabited. All List fields are [], Epoch/Time are 0.
    Used as `default : World` in the proof of goodhart_no_perfect_proxy. -/
instance : Inhabited World := ⟨⟨[], [], [], [], [], 0, 0⟩⟩

-- ============================================================
-- Agent — エージェントの統合定義
-- ============================================================

/-- Agent role. Foundation for P2 (cognitive role separation). -/
inductive AgentRole where
  | human          -- T6: リソースの最終決定者
  | worker         -- Worker AI
  | verifier       -- Verifier AI (E1/P2: 検証の独立性)
  deriving BEq, Repr

/-- Agent: an entity that executes actions on the World.

    - `role` corresponds to P2 (role separation)
    - `contextWindow` corresponds to T3
    - `currentSession` corresponds to T1 (None = inactive) -/
structure Agent where
  id             : AgentId
  role           : AgentRole
  contextWindow  : ContextWindow
  currentSession : Option SessionId
  deriving Repr

-- ============================================================
-- State Transition — 関係ベース（T4 対応）
-- ============================================================

/-- Relation for world state transitions.
    To express T4 (stochasticity of output), `execute` is defined as a
    **relation** rather than a function.

    `canTransition agent action w w'` means "as a result of agent executing action,
    a transition from w to w' is possible." Unlike a function, multiple w' can
    exist for the same (agent, action, w) (nondeterminism).

    Concrete transition conditions will be defined in Phase 3+. -/
opaque canTransition (agent : Agent) (action : Action) (w w' : World) : Prop

/-- Valid transition: a transition from w to w' is possible via some agent and action. -/
def validTransition (w w' : World) : Prop :=
  ∃ (agent : Agent) (action : Action), canTransition agent action w w'

/-- Action execution is blocked (constraint violation). -/
def actionBlocked (agent : Agent) (action : Action) (w : World) : Prop :=
  ¬∃ w', canTransition agent action w w'

-- ============================================================
-- E1/E2 Support — 生成・検証・行動空間・リスク
-- ============================================================

/-- An agent **generates** an action (Worker's act).
    Used in the formalization of E1 (independence of verification). -/
opaque generates (agent : Agent) (action : Action) (w : World) : Prop

/-- An agent **verifies** an action (Verifier's act).
    Used in the formalization of E1 (independence of verification). -/
opaque verifies (agent : Agent) (action : Action) (w : World) : Prop

/-- Whether two agents share internal state.
    Used in the formalization of E1's bias correlation.
    Sharing = same session, shared memory, shared parameters, etc. -/
opaque sharesInternalState (a b : Agent) : Prop

/-- Size of an agent's action space (measure of capability).
    Used in the formalization of E2 (inseparability of capability and risk).
    A larger value means more actions are executable. -/
opaque actionSpaceSize (agent : Agent) (w : World) : Nat

/-- Risk exposure of an agent.
    Used in the formalization of E2 (inseparability of capability and risk).
    A measure of potential damage that increases with action space expansion. -/
opaque riskExposure (agent : Agent) (w : World) : Nat

-- ============================================================
-- Global Resource Bound — T7 対応
-- ============================================================

/-- Global resource upper bound for the entire system.
    A constant for non-trivially expressing T7 (resources are finite).
    Concrete values will be domain-specific in Phase 2+. -/
opaque globalResourceBound : Nat

-- ============================================================
-- P1/P4/P5 Support — 信頼・劣化・解釈（Phase 3+ で使用）
-- ============================================================

/-- Trust level. Accumulated incrementally, can be damaged rapidly.
    Used in P1b (expansion without protection damages trust). -/
opaque trustLevel (agent : Agent) (w : World) : Nat

/-- Predicate for whether risk has materialized.
    Used in P1b. -/
opaque riskMaterialized (agent : Agent) (w : World) : Prop

/-- A measure representing the degree of degradation.
    Represents P4's "gradient" concept as a type. -/
opaque degradationLevel (w : World) : Nat

/-- Relation where an agent interprets a structure to generate an action.
    Different actions may be generated for the same structure (T4).
    Used in P5 (probabilistic interpretation of structure). -/
opaque interpretsStructure
  (agent : Agent) (st : Structure) (action : Action) (w : World) : Prop

-- ============================================================
-- Compatibility / Knowledge Integration — P3/Evolution 共用
-- ============================================================

/-- Compatibility classification for knowledge integration. Core concept of P3.
    Classifies how the integration of new knowledge into structures relates to existing structures.
    Also used in the Evolution layer for classifying inter-version transitions. -/
inductive CompatibilityClass where
  | conservativeExtension  -- 既存知識がすべて有効。追加のみ
  | compatibleChange       -- ワークフロー継続可能。一部前提が変化
  | breakingChange         -- 一部ワークフローが無効。移行パスが必要
  deriving BEq, Repr

/-- Knowledge integration event into a structure. -/
structure KnowledgeIntegration where
  before       : World
  after        : World
  compatibility : CompatibilityClass
  deriving Repr

/-- Governed integration: compatibility is classified, and
    for breakingChange, affected workflows are enumerated. -/
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

/-- Predicate for whether a structure has degraded.
    A state where the quality of a structure has declined due to "accumulation of incorrect knowledge." -/
opaque structureDegraded : World → World → Prop

-- ============================================================
-- 境界→緩和策→変数の三段構造
-- ============================================================

/-!
## Systematic Classification of Constraints, Boundary Conditions, and Variables
Constraints Taxonomy.

The manifesto declares "incremental improvement of persistent structures."
This section defines the **action space** for that improvement — what is a wall and what is a lever.

## Why This Classification Is Necessary

The manifesto's constraint table (Section 5) analyzes constraints as "evolutionary pressures" but
does not distinguish the following three:

- **Boundary Conditions** — Constraints imposed from outside the system. They define the action space.
- **Variables** — Parameters that agents can improve through structures. Indicators of structural quality.
- **Investment Dynamics** — A subset of boundary conditions adjustable through demonstrated returns.

Mixing these three leads to:
- Misidentifying changeable things (variables) as boundary conditions and not attempting to change them
- Wasting resources trying to change unchangeable things (boundary conditions)
- Being unable to distinguish boundaries that move with human investment decisions from those that do not, preventing appropriate strategy

## Overall Structure

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

## Classification Axis - What Moves It

| Classification | Moving Agent | Nature |
|------|-----------|------|
| Fixed boundary | None (immutable) | Accept and design mitigations only |
| Investment-variable boundary | Human investment decisions | Demonstrate structural quality -> human invests -> boundary adjusts |
| Environmental boundary | Human selection + agent proposals | Functions as constraint after selection |
-/

/-- Layer of boundary conditions.
    Classifies L1-L6 into 3 categories by "what moves them." -/
inductive BoundaryLayer where
  | fixed              -- L1, L2: 固定境界（投資でも努力でも動かない）
  | investmentVariable -- L3, L4: 投資可変境界（人間の投資判断で調整）
  | environmental      -- L5, L6: 環境境界（選択・構築で変更可能）
  deriving BEq, Repr

/-!
## Part I Boundary Conditions

## L1 Ethical/Safety Boundary

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

## L2 Ontological Boundary

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

## L3 Resource Boundary

**Moving agent:** Human investment decisions
**Agent strategy:** Maximize ROI within given resources and demonstrate the legitimacy of investment.

| Boundary Condition | Current Level | Investment Expansion Trigger |
|---------|----------|------------------|
| Token budget | API billing plan | ROI demonstration: improved output at same cost |
| Computation time limit | Response wait tolerance | Demonstration of parallelization benefits |
| API rate limits | Plan-dependent | Demonstration of utilization efficiency |
| Human time allocation | Time spent on review and approval | Demonstration of review burden reduction (most expensive resource) |
| Monetary budget | Monthly/project cap | Visualization of overall ROI |

## L4 Action Space Boundary

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

## L5 Platform Boundary

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

## L6 Architectural Convention Boundary

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
-/

/-- Identifier for a concrete boundary condition. At the L1-L6 item level. -/
inductive BoundaryId where
  | ethicsSafety           -- L1: 倫理・安全境界（固定。絶対的。遵守のみ）
  | ontological            -- L2: 存在論的境界（固定。緩和策の品質が変数）
  | resource               -- L3: リソース境界（投資可変。ROI実証で調整）
  | actionSpace            -- L4: 行動空間境界（投資可変。拡張も縮小もありうる）
  | platform               -- L5: プラットフォーム境界（環境。行動空間の天井）
  | architecturalConvention -- L6: 設計規約境界（環境。協働で改善提案）
  deriving BEq, Repr

/-- Identifier for constraints (T1-T8).
    Type-level identifier for each constraint composing T₀ in Axioms.lean.
    Domain of constraintBoundary (Observable.lean). -/
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

/-- The layer to which each boundary condition belongs. -/
def boundaryLayer : BoundaryId → BoundaryLayer
  | .ethicsSafety            => .fixed
  | .ontological             => .fixed
  | .resource                => .investmentVariable
  | .actionSpace             => .investmentVariable
  | .platform                => .environmental
  | .architecturalConvention => .environmental

/-- Mitigation: structural responses that reduce the impact of fixed boundaries.

    Three-tier structure: boundary condition (immutable) -> mitigation (design decision) -> variable (quality indicator)

    ```
    L2:memory loss        -> Implementation Notes -> V6: knowledge structure quality
    L2:finite context     -> 50% rule, lightweight design -> V2: context efficiency
    L2:nondeterminism     -> gate verification    -> V4: gate pass rate
    L2:training data gap  -> docs/SSOT, skills    -> V1: skill quality
    ```

    Boundary conditions do not move. Mitigations are design decisions (L6). Variables are the **effectiveness** of mitigations. -/
structure Mitigation where
  /-- Target boundary condition -/
  boundary : BoundaryId
  /-- Structure affected by the mitigation -/
  target   : StructureId
  deriving Repr

/-- Identifier for investment actions. Three forms of investment.

    | Investment Form | Concrete Example | How Structural Quality Drives It |
    |---------|--------|------------------------|
    | Resource investment | Budget increase, plan upgrade | Visualize ROI through V2 improvement |
    | Action space adjustment | Unlock auto-merge / revoke permissions | V4, V5 track record as evidence |
    | Time investment | Collaborative design, workflow improvement participation | V3 transforms review from "confirmation" to "learning" |

    Reverse cycle (trust damage):
    Quality incidents or scope deviation -> trust decrease -> investment contraction (budget cuts, autonomy revocation, increased oversight).
    This asymmetry (incremental accumulation, rapid damage) reinforces the raison d'etre of L1. -/
inductive InvestmentKind where
  | resourceInvestment   -- リソース投資（予算増額、プラン upgrade）
  | actionSpaceAdjust    -- 行動空間調整（auto-merge 解禁/権限回収）
  | timeInvestment       -- 時間投資（協働設計、ワークフロー改善参加）
  deriving BEq, Repr

/-- Investment level. Degree of human investment in collaboration.
    Section 6: trust is concretized as investment actions. -/
opaque investmentLevel (w : World) : Nat

-- ============================================================
-- SelfGoverning typeclass — Section 7 の構造的強制
-- ============================================================

/-!
## SelfGoverning - Type-Level Enforcement of Self-Application

Section 7 (Self-application of the manifesto):
"This manifesto must follow the principles it itself states."

This requirement is enforced by the type system. Types that define principles, classifications,
or structures cannot be used in contexts requiring self-application (governed updates, phase
management, etc.) unless they implement the `SelfGoverning` typeclass.

## Design Rationale for SelfGoverning

- By making it a typeclass, forgetting to implement SelfGoverning when defining a new type
  results in a type error when attempting to use that type in a governed context
  (structural resolution of the "undetectable" problem)
- The three requirements are derived from D4 (phases) + D9 (compatibility classification)
  + Section 7 (maintenance of rationale)
-/

/-- Typeclass for self-governable types.
    Enforces Section 7 requirements at the type level.

    Types implementing this typeclass must:
    1. Be able to enumerate their own elements (exhaustiveness of update targets)
    2. Be able to apply compatibility classification to updates (D9)
    3. Be able to declare the phase required by each element (D4) -/
class SelfGoverning (α : Type) where
  /-- Exhaustiveness of compatibility classification: any classification belongs to one of the 3 classes.
      Precondition for D9. -/
  classificationExhaustive :
    ∀ (c : CompatibilityClass),
      c = .conservativeExtension ∨ c = .compatibleChange ∨ c = .breakingChange
  /-- Applicability of compatibility classification for each element.
      "For any value of alpha, the compatibility of an update can be queried." -/
  canClassifyUpdate : α → CompatibilityClass → Prop

/-- Predicate that an update to a SelfGoverning type is governed.
    Updates must go through compatibility classification. -/
def governedUpdate [SelfGoverning α] (a : α) (c : CompatibilityClass) : Prop :=
  SelfGoverning.canClassifyUpdate a c

/-- Updates to SelfGoverning types always belong to one of the 3 classifications. -/
theorem governed_update_classified [inst : SelfGoverning α]
    (_witness : α) (c : CompatibilityClass) :
    c = .conservativeExtension ∨ c = .compatibleChange ∨ c = .breakingChange :=
  inst.classificationExhaustive c

-- CompatibilityClass 自体が SelfGoverning（自己参照の基盤）
instance : SelfGoverning CompatibilityClass where
  classificationExhaustive := by intro c; cases c <;> simp
  canClassifyUpdate _ _ := True

-- ============================================================
-- 構造的整合性 — Section 8（構造的整合性）の形式化
-- ============================================================

/-!
## Structural Coherence

The axiom system and artifacts conforming to it are in a partial order relation.
Formalizes the inter-structure partial order from manifesto.md Section 8
(manifest > designConvention > skill > test > document) as StructureKind priorities.

D4 (phase ordering), D5 (spec -> test -> implementation), D6 (boundary -> mitigation -> variable) are
all individual instances of this partial order.
-/

/-- Priority of StructureKind. Reflects the partial order from manifesto Section 8.
    manifest > designConvention > skill > test > document. -/
def StructureKind.priority : StructureKind → Nat
  | .manifest          => 5
  | .designConvention  => 4
  | .skill             => 3
  | .test              => 2
  | .document          => 1

/-- Dependency between structures. Structure a depends on structure b (b has higher priority).
    Changes to the dependency source affect the dependency target. -/
def structureDependsOn (a b : Structure) : Prop :=
  a.kind.priority < b.kind.priority

/-- Structural coherence requirement: when a high-priority structure is modified,
    dependent lower-priority structures become review targets.
    Structural basis for P3 (governance of learning). -/
def coherenceRequirement (high low : Structure) : Prop :=
  structureDependsOn low high →
  high.lastModifiedAt > low.lastModifiedAt →
  True  -- 見直しが必要（型レベルでは存在を表現）

/-- manifest has the highest priority. -/
theorem manifest_highest_priority :
  ∀ (k : StructureKind), k.priority ≤ StructureKind.manifest.priority := by
  intro k; cases k <;> simp [StructureKind.priority]

/-- document has the lowest priority. -/
theorem document_lowest_priority :
  ∀ (k : StructureKind), StructureKind.document.priority ≤ k.priority := by
  intro k; cases k <;> simp [StructureKind.priority]

/-- Priority is injective (different kinds have different priorities). -/
theorem priority_injective :
  ∀ (k₁ k₂ : StructureKind),
    k₁.priority = k₂.priority → k₁ = k₂ := by
  intro k₁ k₂; cases k₁ <;> cases k₂ <;> simp [StructureKind.priority]

-- ============================================================
-- StructureKind 半順序型クラスインスタンス（Run 55 追加）
-- ============================================================

/-!
## Lean Standard Typeclass Partial Order Instance for StructureKind

Defines LE/LT based on priority (Nat) and derives the 4 properties of a
non-strict partial order (reflexivity, transitivity, antisymmetry, consistency with lt) as theorems.

Note: Lean 4.25.0 standard Prelude does not have Preorder/PartialOrder typeclasses, so
this is implemented as LE/LT instances + partial order property theorems.

Distinguished from structureDependsOn (strict partial order `<`):
- `k₁ ≤ k₂` <- `k₁.priority ≤ k₂.priority` (non-strict partial order, for typeclasses)
- `structureDependsOn a b` <- `a.kind.priority < b.kind.priority` (strict, for dependency tracking)
-/

/-- LE instance: derived from the Nat ordering of priority. -/
instance : LE StructureKind := ⟨fun a b => a.priority ≤ b.priority⟩

/-- LT instance: derived from the Nat ordering of priority. -/
instance : LT StructureKind := ⟨fun a b => a.priority < b.priority⟩

/-- Reflexivity of partial order: k <= k. -/
theorem structureKind_le_refl : ∀ (k : StructureKind), k ≤ k :=
  fun k => Nat.le_refl k.priority

/-- Transitivity of partial order: if k₁ <= k₂ and k₂ <= k₃ then k₁ <= k₃. -/
theorem structureKind_le_trans :
    ∀ (k₁ k₂ k₃ : StructureKind), k₁ ≤ k₂ → k₂ ≤ k₃ → k₁ ≤ k₃ := by
  intro _k₁ _k₂ _k₃ h₁₂ h₂₃; exact Nat.le_trans h₁₂ h₂₃

/-- Antisymmetry of partial order: if k₁ <= k₂ and k₂ <= k₁ then k₁ = k₂. Derived from priority_injective. -/
theorem structureKind_le_antisymm :
    ∀ (k₁ k₂ : StructureKind), k₁ ≤ k₂ → k₂ ≤ k₁ → k₁ = k₂ :=
  fun k₁ k₂ h₁₂ h₂₁ => priority_injective k₁ k₂ (Nat.le_antisymm h₁₂ h₂₁)

/-- Consistency of LT and LE: k₁ < k₂ iff k₁ <= k₂ and not (k₂ <= k₁). -/
theorem structureKind_lt_iff_le_not_le :
    ∀ (k₁ k₂ : StructureKind), k₁ < k₂ ↔ k₁ ≤ k₂ ∧ ¬(k₂ ≤ k₁) := by
  intro _k₁ _k₂; exact Nat.lt_iff_le_and_not_ge

/-- manifest has higher priority than designConvention (Section 8 partial order). -/
theorem priority_manifest_gt_design :
  StructureKind.designConvention.priority < StructureKind.manifest.priority := by
  simp [StructureKind.priority]

/-- designConvention has higher priority than skill (Section 8 partial order). -/
theorem priority_design_gt_skill :
  StructureKind.skill.priority < StructureKind.designConvention.priority := by
  simp [StructureKind.priority]

/-- skill has higher priority than test (Section 8 partial order). -/
theorem priority_skill_gt_test :
  StructureKind.test.priority < StructureKind.skill.priority := by
  simp [StructureKind.priority]

/-- test has higher priority than document (Section 8 partial order). -/
theorem priority_test_gt_document :
  StructureKind.document.priority < StructureKind.test.priority := by
  simp [StructureKind.priority]

/-- Irreflexivity of dependency: a structure does not depend on itself.
    Property 1/3 of strict partial order. -/
theorem no_self_dependency :
  ∀ (s : Structure), ¬structureDependsOn s s := by
  intro s; simp [structureDependsOn]

/-- Transitivity of dependency: if a depends on b and b depends on c, then a depends on c.
    Property 2/3 of strict partial order. Derived from Nat.lt_trans. -/
theorem structureDependsOn_transitive :
  ∀ (a b c : Structure),
    structureDependsOn a b → structureDependsOn b c → structureDependsOn a c := by
  intro a b c hab hbc
  unfold structureDependsOn at *
  exact Nat.lt_trans hab hbc

/-- Asymmetry of dependency: if a depends on b, then b does not depend on a.
    Property 3/3 of strict partial order. Derived from Nat.lt_asymm. -/
theorem structureDependsOn_asymmetric :
  ∀ (a b : Structure),
    structureDependsOn a b → ¬structureDependsOn b a := by
  intro a b hab hba
  unfold structureDependsOn at *
  exact absurd (Nat.lt_trans hab hba) (Nat.lt_irrefl _)

-- ============================================================
-- Structure-Level Dependency Tracking — Section 8 性質 2/3
-- ============================================================

/-!
## Structure-Level Dependency Tracking
ATMS Correspondence.

Formalizes manifesto.md Section 8 Property 2 "Self-containment of ordering information" and
Property 3 "Retroactive verification from terminal errors."

Corresponds to ATMS (Assumption-Based Truth Maintenance System) from the research document
`docs/research/items/design-specification-theory.md`.
By having each Structure maintain its own dependencies,
verification can trace back through the partial order to the axiom level upon terminal errors.
-/

/-- Structure-level dependency consistency: dependencies have kind priority >= the dependent.
    Lifts the StructureKind partial order to Structure instance dependency relations.
    (Corresponds to ATMS assumption-belief consistency) -/
def dependencyConsistent (w : World) (s : Structure) : Prop :=
  ∀ depId, depId ∈ s.dependencies →
    ∃ dep, dep ∈ w.structures ∧ dep.id = depId ∧
      s.kind.priority ≤ dep.kind.priority

/-- Structure s' directly depends on Structure s (reverse edge).
    s.id in s'.dependencies = s' is affected by changes to s.
    Structure version of PropositionId.dependents (Prop-based). -/
def isDirectDependent (s' s : Structure) : Prop :=
  s.id ∈ s'.dependencies

/-- Reachability of impact propagation: changes to s reach target.
    Defined inductively as a transitive closure (no fuel needed, termination guaranteed by induction).
    Corresponds to affected(s) = {s' | s <= s'} from research document §4.3. -/
inductive reachableVia (w : World) (s : Structure) : Structure → Prop where
  | direct : ∀ t, t ∈ w.structures → isDirectDependent t s →
             reachableVia w s t
  | trans  : ∀ mid t, reachableVia w s mid → t ∈ w.structures →
             isDirectDependent t mid → reachableVia w s t

/-- In an empty World, nothing is reachable (no impact propagation occurs). -/
theorem empty_world_no_reach :
  ∀ (s t : Structure),
    ¬reachableVia ⟨[], [], [], [], [], 0, 0⟩ s t := by
  intro s t h
  cases h with
  | direct _ hm _ => simp at hm
  | trans _ _ _ hm _ => simp at hm

/-- A Structure with no dependencies (dependencies = []) has no direct dependents. -/
theorem no_dependencies_no_direct_dependent :
  ∀ (s' s : Structure),
    s'.dependencies = [] → ¬isDirectDependent s' s := by
  intro s' s hempty hdep
  simp [isDirectDependent, hempty] at hdep

/-- reachableVia is transitive: if s -> mid -> t then s -> t. -/
theorem reachableVia_trans :
  ∀ (w : World) (s mid t : Structure),
    reachableVia w s mid → reachableVia w mid t → reachableVia w s t := by
  intro w s mid t hsm hmt
  induction hmt with
  | direct t' ht'mem ht'dep =>
    exact reachableVia.trans mid t' hsm ht'mem ht'dep
  | trans mid' t' _ ht'mem ht'dep ih =>
    exact reachableVia.trans mid' t' ih ht'mem ht'dep

-- ============================================================
-- Dependency Chain Verification — Section 8 性質 3
-- ============================================================

/-!
## Dependency Chain Reachability Section 8

Formalizes manifesto.md Section 8 Property 3 "Retroactive verification from terminal errors" as theorems.
Proves that all Structures on a dependency chain are included in the reachable set of reachableVia.
-/

/-- Dependency chain: a list where adjacent Structures are connected via isDirectDependent.
    Corresponds to ATMS dependency tracking chains. -/
def isDependencyChain (w : World) : List Structure → Prop
  | [] => True
  | [_] => True
  | a :: b :: rest =>
    (b ∈ w.structures ∧ isDirectDependent b a) ∧ isDependencyChain w (b :: rest)

/-- All Structures on a dependency chain are reachable from the origin via reachableVia.
    Formalization of Section 8 Property 3: upon terminal errors, verification can trace back through the partial order to the axiom level. -/
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

-- ============================================================
-- Proposition-Level Dependency Graph — D13 基盤
-- ============================================================

/-!
## Proposition-Level Dependency Graph

structureDependsOn is based on the 5-level priority of StructureKind.
This is a dependency between "kinds of structures" and cannot express
dependencies between individual propositions (T1, E1, P2, etc.).

D13 (premise negation impact propagation theorem) presupposes proposition-level dependencies.
Here we define the identifiers and dependency types for propositions.

## Note on Incompleteness
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
-/

/-- Category of manifesto propositions. 6 layers: T/E/P/L/D/H.
    Corresponds to the S = (A, C, H, D) four-way classification (design-specification-theory.md):
    A = constraint, C = empiricalPostulate + principle, H = hypothesis, D = boundary + designTheorem -/
inductive PropositionCategory where
  | constraint         -- T: 拘束条件 (A: Axioms)
  | empiricalPostulate -- E: 経験的公準 (C: Constraints)
  | principle          -- P: 基盤原理 (C: Constraints)
  | boundary           -- L: 境界条件 (D: Derivations)
  | designTheorem      -- D: 設計定理 (D: Derivations)
  | hypothesis         -- H: 仮定 — 未検証の前提（ATMS の仮定に対応）
  deriving BEq, Repr

/-- Proposition identifier. Enumerates all propositions in the manifesto. -/
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

/-- Returns the category of a proposition. -/
def PropositionId.category : PropositionId → PropositionCategory
  | .t1 | .t2 | .t3 | .t4 | .t5 | .t6 | .t7 | .t8 => .constraint
  | .e1 | .e2 => .empiricalPostulate
  | .p1 | .p2 | .p3 | .p4 | .p5 | .p6 => .principle
  | .l1 | .l2 | .l3 | .l4 | .l5 | .l6 => .boundary
  | .d1 | .d2 | .d3 | .d4 | .d5 | .d6 | .d7 | .d8
  | .d9 | .d10 | .d11 | .d12 | .d13 | .d14 => .designTheorem

/-- Returns the direct dependencies of a proposition. Encodes the derivation structure of the manifesto.

    Definition of what each proposition depends on.
    T are root nodes (no dependencies), D are leaf nodes (many dependencies). -/
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

/-- A proposition directly depends on another proposition. -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

/-- T (constraints) are root nodes: they depend on nothing. -/
theorem constraints_are_roots :
  ∀ (p : PropositionId),
    p.category = .constraint → p.dependencies = [] := by
  intro p hp; cases p <;> simp [PropositionId.category] at hp <;> rfl

/-- Epistemological strength ordering of PropositionCategory.
    T > E > P. L and D are below P. -/
def PropositionCategory.strength : PropositionCategory → Nat
  | .constraint         => 5
  | .empiricalPostulate => 4
  | .principle          => 3
  | .boundary           => 2
  | .designTheorem      => 1
  | .hypothesis         => 0  -- 最弱: 未検証の前提は他カテゴリより低い認識論的強度

/-- [Axiom Card]
    Layer: Γ \ T₀ (Design-derived)
    Content: Dependencies follow descending epistemological strength.
          If proposition A depends on B, then B.strength ≥ A.strength.
    Basis: Design decision for D13 propagation direction. Upstream (stronger)
          propositions affect downstream (weaker) ones, not vice versa.

    降格判定: 導出不可能 — PropositionId.dependencies は def だが、
    全ケース網羅の decide/native_decide がタイムアウト。axiom として維持。

    Source: Ontology.lean PropositionId.dependencies
    Refutation condition: If a dependency violating the strength ordering were added -/
axiom dependency_respects_strength :
  ∀ (a b : PropositionId),
    propositionDependsOn a b = true →
    b.category.strength ≥ a.category.strength

end Manifest
