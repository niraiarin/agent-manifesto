/-! # AgentSpec.Manifest.Ontology (Week 3 Day 74-80、Manifest 移植)

新基盤 Manifest 移植 Phase 1。GA-I7 (b) 再定義方針:
lean-formalization/Manifest/Ontology.lean の必要 subset を AgentSpec.Manifest
namespace で再定義 (Lake cross-project require は避ける)。

## Scope progression

- Day 74 PoC: T1 session_bounded のみ → AgentId/SessionId opaque + Session + SessionStatus + Time + World skeleton (sessions + time)
- Day 80 拡張: T1 残 2 axiom (no_cross_session_memory + session_no_shared_state) → StructureId/WorldHash opaque + Severity/AgentRole/AuditEntry/ContextWindow/Action/Agent + canTransition opaque + World に auditLog 追加 (compatible change: Inhabited instance update 含む)
- Day 83 拡張: T2 (structure_persists / structure_accumulates) → Epoch abbrev + StructureKind/Structure + validTransition def + World に structures + epoch 追加
- Week 3-4: T3-T8 + P1-P6 順次
-/

namespace AgentSpec.Manifest

/-- Agent identifier (opaque per T1: agent identity is irrelevant to type-level
    reasoning about session boundedness). -/
opaque AgentId : Type

instance : Repr AgentId := ⟨fun _ _ => "«AgentId»"⟩

/-- Session identifier (opaque per T1). -/
opaque SessionId : Type

instance : Repr SessionId := ⟨fun _ _ => "«SessionId»"⟩

/-- Logical clock for state ordering (Lamport-style monotonic). -/
abbrev Time : Type := Nat

/-- Session status. By T1, sessions must reach `terminated` in finite time. -/
inductive SessionStatus where
  | active
  | terminated
  deriving BEq, Repr

/-- Session: ephemeral instance with finite lifetime (T1 grounding).

    Identical to lean-formalization/Manifest/Ontology.lean Session structure,
    re-defined here per GA-I7 (b). -/
structure Session where
  id     : SessionId
  agent  : AgentId
  start  : Time
  status : SessionStatus
  deriving Repr

/-! ## Day 80 拡張: T1 残 2 axiom 用 dependency -/

/-- Structure identifier (opaque per T2)、Day 80 では Action.target 用に必要。 -/
opaque StructureId : Type

instance : Repr StructureId := ⟨fun _ _ => "«StructureId»"⟩

/-- Severity of an action. T1 では使われないが Action.severity 必須。 -/
inductive Severity where
  | low
  | medium
  | high
  | critical
  deriving BEq, Repr

/-- Agent action: state transition の単位。session_no_shared_state で必要。 -/
structure Action where
  agent    : AgentId
  target   : StructureId
  severity : Severity
  session  : SessionId
  time     : Time
  deriving Repr

/-- Hash of a WorldState. AuditEntry の preHash/postHash で使用。 -/
opaque WorldHash : Type

instance : Repr WorldHash := ⟨fun _ _ => "«WorldHash»"⟩

/-- Audit entry: no_cross_session_memory で必要 (preHash/postHash 因果独立性)。 -/
structure AuditEntry where
  timestamp : Time
  agent     : AgentId
  session   : SessionId
  action    : Action
  preHash   : WorldHash
  postHash  : WorldHash
  deriving Repr

/-- Agent role (P2 cognitive role separation)。Agent.role で必要。 -/
inductive AgentRole where
  | human
  | worker
  | verifier
  deriving BEq, Repr

/-- Context window minimal (Day 80 では capacity のみ、T3 完全版は後続 Day)。 -/
structure ContextWindow where
  capacity : Nat
  deriving Repr

/-- Agent: state transition を実行する entity。session_no_shared_state で必要。 -/
structure Agent where
  id             : AgentId
  role           : AgentRole
  contextWindow  : ContextWindow
  currentSession : Option SessionId
  deriving Repr

/-! ## Day 83 拡張: T2 用 dependency -/

/-- Epoch (T2 構造世代管理、append-only 論理時計、Lamport-style monotonic)。 -/
abbrev Epoch : Type := Nat

/-- StructureKind (manifest 列挙の persistent structure 種別)。 -/
inductive StructureKind where
  | document
  | test
  | skill
  | designConvention
  | manifest
  deriving BEq, Repr

/-- Structure: T2 で永続化する artifact (session を超えて生き残る)。

    `dependencies` は ATMS (Assumption-Based Truth Maintenance System) 流の
    依存追跡、Section 8 性質 2「順序情報の自己内包」を実装。 -/
structure Structure where
  id             : StructureId
  kind           : StructureKind
  createdAt      : Epoch
  lastModifiedAt : Epoch
  dependencies   : List StructureId
  deriving Repr

/-- World (Day 74 sessions/time + Day 80 auditLog + Day 83 structures/epoch)。

    既存 Manifest の World は 7 fields だが、Day 83 までで T1+T2 5 axiom に
    必要な sessions/time/auditLog/structures/epoch の 5 field。残 2 field
    (allocations/feedbacks) は T6/T7 着手時 (P 系列) に追加予定. -/
structure World where
  sessions   : List Session
  time       : Time
  auditLog   : List AuditEntry
  structures : List Structure
  epoch      : Epoch
  deriving Repr

instance : Inhabited World := ⟨⟨[], 0, [], [], 0⟩⟩

/-- State transition relation (T₀ opaque、session_no_shared_state で必要)。 -/
opaque canTransition (agent : Agent) (action : Action) (w w' : World) : Prop

/-- Valid transition: w → w' が何らかの agent + action 経由で可能。 -/
def validTransition (w w' : World) : Prop :=
  ∃ (agent : Agent) (action : Action), canTransition agent action w w'

end AgentSpec.Manifest
