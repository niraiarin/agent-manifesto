/-! # AgentSpec.Manifest.Ontology (Week 3 Day 74-80、Manifest 移植)

新基盤 Manifest 移植 Phase 1。GA-I7 (b) 再定義方針:
lean-formalization/Manifest/Ontology.lean の必要 subset を AgentSpec.Manifest
namespace で再定義 (Lake cross-project require は避ける)。

## Scope progression

- Day 74 PoC: T1 session_bounded のみ → AgentId/SessionId opaque + Session + SessionStatus + Time + World skeleton (sessions + time)
- Day 80 拡張: T1 残 2 axiom (no_cross_session_memory + session_no_shared_state) → StructureId/WorldHash opaque + Severity/AgentRole/AuditEntry/ContextWindow/Action/Agent + canTransition opaque + World に auditLog 追加 (compatible change: Inhabited instance update 含む)
- Day 83 拡張: T2 (structure_persists / structure_accumulates) → Epoch abbrev + StructureKind/Structure + validTransition def + World に structures + epoch 追加
- Day 84 拡張: T3 (context_contribution_nonuniform) → PrecisionLevel + Task + ContextItem opaque + precisionContribution opaque。T4 (output_nondeterministic) は既存 dependency のみで追加なし。
- Day 85 拡張: T5 (no_improvement_without_feedback x2) + T6 (human_resource_authority + resource_revocable) → FeedbackKind/FeedbackTarget/Feedback + ProcessId opaque + ResourceId opaque + ResourceKind/ResourceAllocation + World に feedbacks + allocations + structureImproved def + processImproved opaque + isHuman def
- Day 86 拡張: T7 (resource_finite + sequential_exceeds_component) + T8 (task_has_precision theorem) → globalResourceBound opaque + executionDuration opaque
- Day 89 拡張: E1 (verification_requires_independence + shared_bias_reduces_detection) + E2 (capability_risk_coscaling) + E3 (confidence_is_self_description) → Confidence/Output structure + generates/verifies/sharesInternalState/actionSpaceSize/riskExposure/worldOutput opaque
- Week 3-4: P1-P6 (theorem) + L1-L6 + V1-V7 + D1-D18
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

/-- Context window (Day 80 capacity + Day 110 used + invariant 拡張、T3 完全版)。 -/
structure ContextWindow where
  capacity     : Nat
  used         : Nat := 0
  capacity_pos : capacity > 0 := by omega
  used_le_cap  : used ≤ capacity := by omega
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

/-! ## Day 85 拡張: T5 (Feedback) + T6 (Resource) 用 dependency -/

/-- ProcessId opaque (T5 process improvement target)。 -/
opaque ProcessId : Type

instance : Repr ProcessId := ⟨fun _ _ => "«ProcessId»"⟩

/-- ResourceId opaque (T6 resource allocation 識別)。 -/
opaque ResourceId : Type

instance : Repr ResourceId := ⟨fun _ _ => "«ResourceId»"⟩

/-- T5 control loop の三要素 (測定 → 比較 → 調整)。 -/
inductive FeedbackKind where
  | measurement
  | comparison
  | adjustment
  deriving BEq, Repr

/-- Feedback の対象。Structure (T5 backward compat) と Process (#316 meta)。 -/
inductive FeedbackTarget where
  | structure (id : StructureId)
  | process   (id : ProcessId)
  deriving Repr

/-- Feedback unit (measurement → comparison → adjustment loop)。 -/
structure Feedback where
  kind      : FeedbackKind
  source    : AgentId
  target    : FeedbackTarget
  timestamp : Time
  deriving Repr

/-- T7 由来 resource 種別。 -/
inductive ResourceKind where
  | computation
  | dataAccess
  | executionPermission
  | time
  | energy
  deriving BEq, Repr

/-- Resource allocation (T6 grantedBy human + T7 amount 有限)。 -/
structure ResourceAllocation where
  resource    : ResourceId
  kind        : ResourceKind
  amount      : Nat
  grantedBy   : AgentId
  grantedTo   : AgentId
  validFrom   : Time
  validUntil  : Option Time
  deriving Repr

/-- World (Day 74 sessions/time + Day 80 auditLog + Day 83 structures/epoch + Day 85 feedbacks/allocations)。

    既存 Manifest の 7 fields と整合 (feedbacks + allocations は T5/T6 axiom 用)。 -/
structure World where
  sessions    : List Session
  time        : Time
  auditLog    : List AuditEntry
  structures  : List Structure
  epoch       : Epoch
  feedbacks   : List Feedback
  allocations : List ResourceAllocation
  deriving Repr

instance : Inhabited World := ⟨⟨[], 0, [], [], 0, [], []⟩⟩

/-- State transition relation (T₀ opaque、session_no_shared_state で必要)。 -/
opaque canTransition (agent : Agent) (action : Action) (w w' : World) : Prop

/-- Valid transition: w → w' が何らかの agent + action 経由で可能。 -/
def validTransition (w w' : World) : Prop :=
  ∃ (agent : Agent) (action : Action), canTransition agent action w w'

/-! ## Day 84 拡張: T3 用 dependency -/

/-- Precision level: T8 由来、Task の要求精度 (千分率)。required > 0 不変式。 -/
structure PrecisionLevel where
  required     : Nat
  required_pos : required > 0 := by omega
  deriving Repr

/-- Task: a goal + its constraints (T3 contextBudget + T7 resourceBudget + T8 precisionRequired)。 -/
structure Task where
  description       : String
  precisionRequired : PrecisionLevel
  contextBudget     : Nat
  resourceBudget    : Nat
  deriving Repr

/-- Context window 内の単一 item。T3 で context が有限 → bounded。 -/
opaque ContextItem : Type

instance : Repr ContextItem := ⟨fun _ _ => "«ContextItem»"⟩

/-- Precision contribution: ContextItem が Task の精度に寄与する量。
    Task 別に異なる (information theory: not all info is equally relevant)。 -/
opaque precisionContribution : ContextItem → Task → Nat

/-! ## Day 85 拡張: T5 後半 (structureImproved / processImproved / isHuman) -/

/-- T5 で参照する structureImproved def (lastModifiedAt の単調増加で観測)。 -/
def structureImproved (w w' : World) : Prop :=
  ∃ (s' : Structure),
    s' ∈ w'.structures ∧
    ((∀ (s : Structure), s ∈ w.structures → s.id = s'.id → s.lastModifiedAt < s'.lastModifiedAt)
    ∨ (¬∃ (s : Structure), s ∈ w.structures ∧ s.id = s'.id))

/-- T5 process 版 (opaque、ProcessId と process-level quality は型で表現できないため)。 -/
opaque processImproved : ProcessId → World → World → Prop

/-- T6 で参照する isHuman 判定 (Agent.role == .human)。 -/
def isHuman (agent : Agent) : Prop :=
  agent.role = AgentRole.human

/-! ## Day 86 拡張: T7 用 dependency -/

/-- 全 World 共通の resource bound (T7、Phase 2+ で domain-specific に concretize)。 -/
opaque globalResourceBound : Nat

/-- Task 実行に要する時間 (T7b、opaque)。 -/
opaque executionDuration : Task → Nat

/-! ## Day 89 拡張: E1-E3 用 dependency -/

/-- Confidence (T4 由来、output の確率的解釈の self-description)。 -/
structure Confidence where
  value : Float
  deriving Repr

/-- Agent output (T4 反映、result + confidence)。 -/
structure Output (α : Type) where
  result     : α
  confidence : Confidence
  deriving Repr

instance : Inhabited Confidence := ⟨⟨0.0⟩⟩
instance : Inhabited (Output Nat) := ⟨⟨0, default⟩⟩

/-- Action 生成 predicate (E1 で使用、opaque)。 -/
opaque generates (agent : Agent) (action : Action) (w : World) : Prop

/-- Action verification predicate (E1 で使用、opaque)。 -/
opaque verifies (agent : Agent) (action : Action) (w : World) : Prop

/-- 内部状態共有 predicate (E1 sharesInternalState、opaque)。 -/
opaque sharesInternalState (a b : Agent) : Prop

/-- Action space size (E2 capability、opaque)。 -/
opaque actionSpaceSize (agent : Agent) (w : World) : Nat

/-- Risk exposure (E2、opaque)。 -/
opaque riskExposure (agent : Agent) (w : World) : Nat

/-- World output (E3 で使用、output extraction、opaque)。 -/
opaque worldOutput (w : World) : Output Nat

/-! ## Day 91 拡張: P1b 用 dependency (ObservableDesign 由来) -/

/-- Risk materialization (P1b、opaque)。 -/
opaque riskMaterialized (agent : Agent) (w : World) : Prop

/-- Trust level (P1b、opaque、Phase 4 で Observable 化予定)。 -/
opaque trustLevel (agent : Agent) (w : World) : Nat

/-- Trust 毀損 axiom (P1b 依存、ObservableDesign.lean line 307 由来)。
    action space 拡大後 risk 顕在化で trust 低下、信頼の非対称性 (蓄積漸進・毀損急激)。 -/
axiom trust_decreases_on_materialized_risk :
  ∀ (agent : Agent) (w w' : World),
    actionSpaceSize agent w < actionSpaceSize agent w' →
    riskMaterialized agent w' →
    trustLevel agent w' < trustLevel agent w

/-! ## Day 93 拡張: P3 用 dependency (CompatibilityClass + KnowledgeIntegration) -/

/-- P3 core: knowledge integration の互換性分類。 -/
inductive CompatibilityClass where
  | conservativeExtension
  | compatibleChange
  | breakingChange
  deriving BEq, Repr

/-- Knowledge integration event (P3 で使用)。 -/
structure KnowledgeIntegration where
  before        : World
  after         : World
  compatibility : CompatibilityClass
  deriving Repr

/-! ## Day 94 拡張: P4+P5 用 dependency (ObservableDesign 由来) -/

/-- Degradation level (P4、opaque、Phase 4 で Observable 化予定)。 -/
opaque degradationLevel (w : World) : Nat

/-- Structure interpretation predicate (P5、agent が structure 解釈で action 生成)。 -/
opaque interpretsStructure
  (agent : Agent) (st : Structure) (action : Action) (w : World) : Prop

/-- P4b axiom: degradation level 全射 (劣化は連続スペクトル、binary でなく gradient)。 -/
axiom degradation_level_surjective :
  ∀ (n : Nat), ∃ (w : World), degradationLevel w = n

/-- P5 axiom: 同一 structure に対する interpretation は非決定的 (T4 由来 design 公理)。 -/
axiom interpretation_nondeterminism :
  ∃ (agent : Agent) (st : Structure) (action₁ action₂ : Action) (w : World),
    interpretsStructure agent st action₁ w ∧
    interpretsStructure agent st action₂ w ∧
    action₁ ≠ action₂

/-! ## Day 95 拡張: P6 用 dependency (TaskStrategy + strategyFeasible) -/

/-- Task execution strategy (P6 で使用、3 軸 = T3+T7+T8 制約)。 -/
structure TaskStrategy where
  task               : Task
  contextUsage       : Nat
  resourceUsage      : Nat
  achievedPrecision  : Nat
  deriving Repr

/-- Strategy feasibility: T3 + T7 + T8 制約を同時に満たす。 -/
def strategyFeasible (s : TaskStrategy) (agent : Agent) : Prop :=
  s.contextUsage ≤ agent.contextWindow.capacity ∧
  s.resourceUsage ≤ s.task.resourceBudget ∧
  s.achievedPrecision ≥ s.task.precisionRequired.required

/-! ## Day 96 拡張: D4 用 dependency (DevelopmentPhase L1-L6 系列カバー) -/

/-- Development phase (D4 の progressive self-application、L1-L6 系列対応)。
    safety=L1, verification=P2, observability=P4, governance=P3, equilibrium=投資+動的調整。 -/
inductive DevelopmentPhase where
  | safety
  | verification
  | observability
  | governance
  | equilibrium
  deriving BEq, Repr

/-- Inter-phase dependency: 後続 phase は先行 phase 完了後のみ開始可。 -/
def phaseDependency : DevelopmentPhase → DevelopmentPhase → Prop
  | .verification,  .safety        => True
  | .observability, .verification  => True
  | .governance,    .observability => True
  | .equilibrium,   .governance    => True
  | _,              _              => False

/-! ## Day 97 拡張: V 系列用 dependency (V index 7 opaque + 2 predicate def) -/

/-- V1: Skill quality (World ごとに測定)。 -/
opaque skillQuality (w : World) : Nat

/-- V2: Context efficiency。 -/
opaque contextEfficiency (w : World) : Nat

/-- V3: Output quality。 -/
opaque outputQuality (w : World) : Nat

/-- V4: Gate pass rate。 -/
opaque gatePassRate (w : World) : Nat

/-- V5: Proposal accuracy。 -/
opaque proposalAccuracy (w : World) : Nat

/-- V6: Knowledge structure quality。 -/
opaque knowledgeStructureQuality (w : World) : Nat

/-- V7: Task design efficiency。 -/
opaque taskDesignEfficiency (w : World) : Nat

/-- Tradeoff existence: m₁ 改善時に m₂ 劣化する世界対が存在 (Pareto 不可能性は含意せず)。 -/
def TradeoffExists (m₁ m₂ : World → Nat) : Prop :=
  ∃ w w', m₁ w < m₁ w' ∧ m₂ w' < m₂ w

/-- Goodhart vulnerability: 真指標 m に対する近似 approx が乖離可能 (1 点一致でも全体乖離あり)。 -/
def GoodhartVulnerable (m : World → Nat) : Prop :=
  ∀ (approx : World → Nat),
    (∃ w, approx w = m w) →
    ∃ w', approx w' ≠ m w'

/-! ## Day 99 拡張: V batch 2 用 dependency (investment cycle + system health) -/

/-- Investment level (Section 6 投資サイクル、opaque)。 -/
opaque investmentLevel (w : World) : Nat

/-- Collaborative value (Section 6 均衡、agent-human 協働価値、opaque)。 -/
opaque collaborativeValue (w : World) : Nat

/-- Trust increment bound (1 step で増加できる trust の上限、漸進蓄積の非対称性)。 -/
opaque trustIncrementBound : Nat

/-- System health: 全 V index が threshold 以上 (一律閾値版、Phase 4 由来)。 -/
def systemHealthy (threshold : Nat) (w : World) : Prop :=
  skillQuality w ≥ threshold ∧
  contextEfficiency w ≥ threshold ∧
  outputQuality w ≥ threshold ∧
  gatePassRate w ≥ threshold ∧
  proposalAccuracy w ≥ threshold ∧
  knowledgeStructureQuality w ≥ threshold ∧
  taskDesignEfficiency w ≥ threshold

/-! ## Day 101 拡張: D3 observability conditions -/

/-- Detection mode (D3 observability の検出形式区別、Run 41 由来)。 -/
inductive DetectionMode where
  | humanReadable
  | structurallyQueryable
  deriving BEq, Repr

/-- D3 observability 3 条件 + structurallyQueryable 検出形式 (default)。 -/
structure ObservabilityConditions where
  measurable            : Bool
  degradationDetectable : Bool
  detectionMode         : DetectionMode := .structurallyQueryable
  improvementVerifiable : Bool
  deriving BEq, Repr

/-- 真に optimization 可能な variable: 全 3 条件 + structurallyQueryable detection。 -/
def effectivelyOptimizable (c : ObservabilityConditions) : Prop :=
  c.measurable = true ∧ c.degradationDetectable = true ∧
  c.detectionMode = .structurallyQueryable ∧ c.improvementVerifiable = true

/-! ## Day 105 拡張: D5 SpecLayer + TestKind + D6 DesignStage -/

/-- D5: 三層表現 (formal spec → acceptance test → implementation)。 -/
inductive SpecLayer where
  | formalSpec
  | acceptanceTest
  | implementation
  deriving BEq, Repr

/-- D5: テスト分類 (T4 confluence、structural=決定、behavioral=確率)。 -/
inductive TestKind where
  | structural
  | behavioral
  deriving BEq, Repr

/-- D5: 三層の order (formal=0 → test=1 → impl=2)。 -/
def specLayerOrder : SpecLayer → Nat
  | .formalSpec      => 0
  | .acceptanceTest  => 1
  | .implementation  => 2

/-- D5: structural test は決定論的、behavioral は確率的 (T4)。 -/
def testDeterministic : TestKind → Bool
  | .structural => true
  | .behavioral => false

/-- D6: 三段設計 stages (boundary → mitigation → variable)。 -/
inductive DesignStage where
  | identifyBoundary
  | designMitigation
  | defineVariable
  deriving BEq, Repr, DecidableEq

/-- D6: 三段設計 order。 -/
def designStageOrder : DesignStage → Nat
  | .identifyBoundary  => 0
  | .designMitigation  => 1
  | .defineVariable    => 2

/-! ## Day 106 拡張: D1 + d6_fixed + D11 用 dependency -/

/-- L1-L6 boundary identifier (D1+D6 で使用)。 -/
inductive BoundaryId where
  | ethicsSafety
  | ontological
  | resource
  | actionSpace
  | platform
  | architecturalConvention
  deriving BEq, Repr

/-- Boundary layer (3 分類: fixed=L1+L2 / investmentVariable=L3+L4 / environmental=L5+L6)。 -/
inductive BoundaryLayer where
  | fixed
  | investmentVariable
  | environmental
  deriving BEq, Repr

/-- Boundary id → layer mapping。 -/
def boundaryLayer : BoundaryId → BoundaryLayer
  | .ethicsSafety            => .fixed
  | .ontological             => .fixed
  | .resource                => .investmentVariable
  | .actionSpace             => .investmentVariable
  | .platform                => .environmental
  | .architecturalConvention => .environmental

/-- D1: Enforcement layer (structural=最強 / procedural=中 / normative=弱、P5 由来)。 -/
inductive EnforcementLayer where
  | structural
  | procedural
  | normative
  deriving BEq, Repr

/-- Enforcement strength (structural=3 / procedural=2 / normative=1)。 -/
def EnforcementLayer.strength : EnforcementLayer → Nat
  | .structural => 3
  | .procedural => 2
  | .normative  => 1

/-- 最低必要 enforcement layer (boundary 種別に応じて)。 -/
def minimumEnforcement : BoundaryLayer → EnforcementLayer
  | .fixed              => .structural
  | .investmentVariable => .procedural
  | .environmental      => .normative

/-- D11: Enforcement layer 別 context cost (structural=0 / procedural=1 / normative=2、強い enforcement ほど低コスト)。 -/
def contextCost : EnforcementLayer → Nat
  | .structural => 0
  | .procedural => 1
  | .normative  => 2

/-! ## Day 107 拡張: D2 verification independence (E1 + P2) -/

/-- D2: 4 条件 (context separation + framing + execution automaticity + evaluator independence)。 -/
structure VerificationIndependence where
  contextSeparated      : Bool
  framingIndependent    : Bool
  executionAutomatic    : Bool
  evaluatorIndependent  : Bool
  deriving BEq, Repr

/-- 検証 risk 4 段 (critical=L1 関連 / high=構造変更 / moderate=通常 / low=docs)。 -/
inductive VerificationRisk where
  | critical
  | high
  | moderate
  | low
  deriving BEq, Repr

/-- Risk 別 必要条件数 (critical=4 / high=3 / moderate=2 / low=1)。 -/
def requiredConditions : VerificationRisk → Nat
  | .critical => 4
  | .high     => 3
  | .moderate => 2
  | .low      => 1

/-- 4 条件中の充足数。 -/
def satisfiedConditions (vi : VerificationIndependence) : Nat :=
  (if vi.contextSeparated then 1 else 0) +
  (if vi.framingIndependent then 1 else 0) +
  (if vi.executionAutomatic then 1 else 0) +
  (if vi.evaluatorIndependent then 1 else 0)

/-- 検証充足: 充足 ≥ 必要。 -/
def sufficientVerification
    (vi : VerificationIndependence) (risk : VerificationRisk) : Prop :=
  satisfiedConditions vi ≥ requiredConditions risk

/-! ## Day 108 拡張: D9 SelfGoverning typeclass + DesignPrinciple -/

/-- D9 core: 任意の type が compatibility classification + per-element 判定可能と表明する typeclass。 -/
class SelfGoverning (α : Type) where
  classificationExhaustive :
    ∀ (c : CompatibilityClass),
      c = .conservativeExtension ∨ c = .compatibleChange ∨ c = .breakingChange
  canClassifyUpdate : α → CompatibilityClass → Prop

/-- SelfGoverning type の update は常に 3 分類のいずれか。 -/
theorem governed_update_classified {α : Type} [inst : SelfGoverning α]
    (_witness : α) (c : CompatibilityClass) :
    c = .conservativeExtension ∨ c = .compatibleChange ∨ c = .breakingChange :=
  inst.classificationExhaustive c

/-- CompatibilityClass 自体が SelfGoverning (自己参照基盤、Day 93 移植 type の self-application)。 -/
instance : SelfGoverning CompatibilityClass where
  classificationExhaustive := by intro c; cases c <;> simp
  canClassifyUpdate _ _ := True

/-- D1-D18 を value として列挙 (D9 self-application のため)。 -/
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
  | d15_harnessEngineering
  | d16_informationRelevance
  | d17_deductiveDesignWorkflow
  | d18_multiAgentCoordination
  deriving BEq, Repr

/-- DesignPrinciple は SelfGoverning (D1-D9 自身も governed update に従う、D9 self-application)。 -/
instance : SelfGoverning DesignPrinciple where
  classificationExhaustive := by intro c; cases c <;> simp
  canClassifyUpdate _ _ := True

/-- DesignPrinciple update event (compatibility classification 必須 + rationale)。 -/
structure DesignPrincipleUpdate where
  principle     : DesignPrinciple
  compatibility : CompatibilityClass
  hasRationale  : Bool
  deriving Repr

/-- Governed update predicate (rationale 必須)。 -/
def governedPrincipleUpdate (u : DesignPrincipleUpdate) : Prop :=
  u.hasRationale = true

/-! ## Day 109 拡張: D15d ComputationStep + marginalReturn -/

/-- Computation step (chain-of-thought 単位 / tool call、resource consume + precision contribution)。 -/
structure ComputationStep where
  item     : ContextItem
  cost     : Nat
  cost_pos : cost > 0 := by omega
  deriving Repr

/-- Marginal precision return (0 = waste computation、saturation point の根拠)。 -/
def marginalReturn (step : ComputationStep) (task : Task) : Nat :=
  precisionContribution step.item task

/-! ## Day 110 拡張: context_finite theorem (T3 ContextWindow 拡張由来) -/

/-- T3: agent context window は finite (capacity > 0 + used ≤ capacity、structure invariant 由来)。 -/
theorem context_finite :
  ∀ (agent : Agent),
    agent.contextWindow.capacity > 0 ∧
    agent.contextWindow.used ≤ agent.contextWindow.capacity := by
  intro agent
  exact ⟨agent.contextWindow.capacity_pos, agent.contextWindow.used_le_cap⟩

/-! ## Day 113 拡張: D13 PropositionId dependency graph -/

/-- Proposition categories used by D13 impact propagation. -/
inductive PropositionCategory where
  | constraint
  | empiricalPostulate
  | principle
  | boundary
  | designTheorem
  | hypothesis
  deriving BEq, Repr

/-- Proposition identifier. Enumerates named propositions in the Manifest. -/
inductive PropositionId where
  | t1 | t2 | t3 | t4 | t5 | t6 | t7 | t8
  | e1 | e2
  | p1 | p2 | p3 | p4 | p5 | p6
  | l1 | l2 | l3 | l4 | l5 | l6
  | d1 | d2 | d3 | d4 | d5 | d6 | d7 | d8 | d9 | d10 | d11 | d12 | d13 | d14
  | d15 | d16 | d17 | d18
  | v1 | v2 | v3 | v4 | v5 | v6 | v7
  deriving BEq, Repr

/-- Returns the category of a proposition. -/
def PropositionId.category : PropositionId → PropositionCategory
  | .t1 | .t2 | .t3 | .t4 | .t5 | .t6 | .t7 | .t8 => .constraint
  | .e1 | .e2 => .empiricalPostulate
  | .p1 | .p2 | .p3 | .p4 | .p5 | .p6 => .principle
  | .l1 | .l2 | .l3 | .l4 | .l5 | .l6 => .boundary
  | .d1 | .d2 | .d3 | .d4 | .d5 | .d6 | .d7 | .d8
  | .d9 | .d10 | .d11 | .d12 | .d13 | .d14
  | .d15 | .d16 | .d17 | .d18 => .designTheorem
  | .v1 | .v2 | .v3 | .v4 | .v5 | .v6 | .v7 => .boundary

/-- Returns the direct dependencies of a proposition. -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .t1 | .t2 | .t3 | .t4 | .t5 | .t6 | .t7 | .t8 => []
  | .e1 => [.t4]
  | .e2 => []
  | .p1 => [.e2]
  | .p2 => [.t4, .e1]
  | .p3 => [.t1, .t2]
  | .p4 => [.t5, .t7]
  | .p5 => [.t4]
  | .p6 => [.t3, .t7, .t8]
  | .l1 => [.p1, .t6]
  | .l2 => [.t1, .t3, .t4]
  | .l3 => [.t6, .t7]
  | .l4 => [.t6, .p1, .d8]
  | .l5 => []
  | .l6 => [.t6, .p3]
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
  | .d15 => [.t3, .t4, .t5, .t6, .t7, .t8, .p6]
  | .d16 => [.t3, .t7, .t8]
  | .d17 => [.t5, .t6, .e1, .p3, .d2, .d3, .d5, .d9, .d13]
  | .d18 => [.t3, .t7, .d12]
  | .v1 => [.l2, .l5]
  | .v2 => [.l2, .l3]
  | .v3 => [.l1, .l4]
  | .v4 => [.l6, .l4]
  | .v5 => [.l4, .l6]
  | .v6 => [.l2]
  | .v7 => [.l3, .l6]

/-- A proposition directly depends on another proposition. -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

/-- T (constraints) are root nodes: they depend on nothing. -/
theorem constraints_are_roots :
  ∀ (p : PropositionId),
    p.category = .constraint → p.dependencies = [] := by
  intro p hp; cases p <;> simp [PropositionId.category] at hp <;> rfl

/-! ## Day 119 拡張: StructureKind.priority + PropositionCategory.strength (Framework AcyclicGraph 系 unblock) -/

/-- Priority of StructureKind. Reflects the partial order from manifesto Section 8.
    manifest > designConvention > skill > test > document. -/
def StructureKind.priority : StructureKind → Nat
  | .manifest          => 5
  | .designConvention  => 4
  | .skill             => 3
  | .test              => 2
  | .document          => 1

/-- Dependency between structures. Structure a depends on structure b (b has higher priority). -/
def structureDependsOn (a b : Structure) : Prop :=
  a.kind.priority < b.kind.priority

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

/-- Epistemological strength ordering of PropositionCategory.
    T > E > P. L and D are below P. -/
def PropositionCategory.strength : PropositionCategory → Nat
  | .constraint         => 5
  | .empiricalPostulate => 4
  | .principle          => 3
  | .boundary           => 2
  | .designTheorem      => 1
  | .hypothesis         => 0

/-- Dependencies follow descending epistemological strength.
    If proposition A depends on B, then B.strength ≥ A.strength. -/
axiom dependency_respects_strength :
  ∀ (a b : PropositionId),
    propositionDependsOn a b = true →
    b.category.strength ≥ a.category.strength

/-! ## Day 122 拡張: reachableVia (Procedure 前提、Section 8 dependency chain) -/

/-- Structure s' directly depends on Structure s (reverse edge). -/
def isDirectDependent (s' s : Structure) : Prop :=
  s.id ∈ s'.dependencies

/-- Reachability of impact propagation: changes to s reach target.
    Defined inductively as a transitive closure. -/
inductive reachableVia (w : World) (s : Structure) : Structure → Prop where
  | direct : ∀ t, t ∈ w.structures → isDirectDependent t s →
             reachableVia w s t
  | trans  : ∀ mid t, reachableVia w s mid → t ∈ w.structures →
             isDirectDependent t mid → reachableVia w s t

/-- In an empty World, nothing is reachable. -/
theorem empty_world_no_reach :
  ∀ (s t : Structure),
    ¬reachableVia ⟨[], 0, [], [], 0, [], []⟩ s t := by
  intro s t h
  cases h with
  | direct _ hm _ => simp at hm
  | trans _ _ _ hm _ => simp at hm

/-- A Structure with no dependencies has no direct dependents. -/
theorem no_dependencies_no_direct_dependent :
  ∀ (s' s : Structure),
    s'.dependencies = [] → ¬isDirectDependent s' s := by
  intro s' s hempty hdep
  simp [isDirectDependent, hempty] at hdep

/-- reachableVia is transitive. -/
theorem reachableVia_trans :
  ∀ (w : World) (s mid t : Structure),
    reachableVia w s mid → reachableVia w mid t → reachableVia w s t := by
  intro w s mid t hsm hmt
  induction hmt with
  | direct t' ht'mem ht'dep =>
    exact reachableVia.trans mid t' hsm ht'mem ht'dep
  | trans mid' t' _ ht'mem ht'dep ih =>
    exact reachableVia.trans mid' t' ih ht'mem ht'dep

end AgentSpec.Manifest
