/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **safety** (ord=0): Non-negotiable safety constraints: path validation, injection prevention, TOCTOU protection, sandbox enforcement, secret scanning [PD-006, PD-007, PD-008, PD-010, PD-011, PD-012, PD-014, PD-042, PD-043, PD-044, PD-108, PD-109, PD-110, PD-112, PD-113, PD-122, PD-131, PD-136, PD-137, PD-265, PD-275, PD-276, PD-310, PD-317, PD-321, PD-347, PD-400, PD-424, PD-454, PD-558]
- **permission** (ord=1): Configurable permission system: modes, rule cascade, classifier, enterprise policy, audit trail [PD-005, PD-100, PD-101, PD-104, PD-105, PD-106, PD-115, PD-116, PD-118, PD-120, PD-126, PD-134, PD-138, PD-153, PD-170, PD-182, PD-208, PD-237, PD-290, PD-550]
- **tool** (ord=2): Core tool interface, validation, execution model, result handling, concurrency safety [PD-001, PD-002, PD-003, PD-016, PD-019, PD-020, PD-021, PD-024, PD-026, PD-027, PD-028, PD-030, PD-034, PD-035, PD-036, PD-038, PD-039, PD-178, PD-280, PD-343, PD-361, PD-367, PD-368, PD-369, PD-380, PD-381, PD-472, PD-519, PD-556]
- **orchestration** (ord=3): Multi-agent teams, worktree isolation, task lifecycle, plan mode governance [PD-050, PD-052, PD-054, PD-055, PD-056, PD-057, PD-059, PD-061, PD-062, PD-065, PD-067, PD-069, PD-070, PD-071, PD-350, PD-391, PD-402, PD-403, PD-407, PD-408, PD-505]
- **conversation** (ord=4): Query loop, state management, compaction, context composition, settings cascade [PD-169, PD-174, PD-175, PD-200, PD-202, PD-203, PD-204, PD-205, PD-213, PD-229, PD-234, PD-240, PD-261, PD-281, PD-340, PD-345, PD-349, PD-362, PD-363, PD-365, PD-366, PD-374, PD-375, PD-392, PD-393, PD-396, PD-397, PD-405, PD-406, PD-455, PD-500, PD-502, PD-503, PD-504, PD-507, PD-530, PD-543, PD-546, PD-552, PD-590]
- **extension** (ord=5): Plugin system, hooks, MCP integration, skills, commands, output styles [PD-150, PD-155, PD-159, PD-160, PD-161, PD-163, PD-185, PD-186, PD-250, PD-251, PD-271, PD-272, PD-285, PD-288, PD-289, PD-294, PD-370, PD-371, PD-372, PD-373, PD-376, PD-377, PD-390, PD-394, PD-395, PD-401, PD-506, PD-549, PD-557]
- **observability** (ord=6): Memory consolidation, telemetry, cost tracking, analytics, diagnostics [PD-032, PD-166, PD-209, PD-210, PD-211, PD-228, PD-264, PD-277, PD-341, PD-342, PD-344, PD-346, PD-364, PD-410, PD-434, PD-435, PD-508, PD-513, PD-522, PD-523, PD-534, PD-542]
-/

namespace Manifest.Models.Instances.ClaudeCodeCLI

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | denyShortCircuit
  | multiLayerSecurity
  | pathTraversalDetection
  | uncPathBlocking
  | dangerousPathProtection
  | toctouPrevention
  | sandboxEnforcement
  | secretScanning
  | bashAstParsing
  | permissionModes
  | ruleCascade
  | denyWins
  | autoModeClassifier
  | enterprisePolicy
  | permissionAuditTrail
  | hookPermissionOverride
  | toolInterface
  | failClosedDefaults
  | deterministicValidation
  | resultBounding
  | bashBackgrounding
  | featureGatedTools
  | hierarchicalTeams
  | executionBackends
  | fileMailbox
  | planApprovalGate
  | worktreeIsolation
  | shutdownProtocol
  | taskDependencyTracking
  | immutableAppState
  | queryLoopRecovery
  | multiLayerCompaction
  | cacheSafeForking
  | layeredSystemPrompt
  | settingsCascade
  | gracefulShutdown
  | pluginArchitecture
  | hookSystem
  | mcpTransportAbstraction
  | mcpConfigCascade
  | commandAggregation
  | skillExecution
  | pluginDependencyResolution
  | autoMemoryTaxonomy
  | dreamConsolidation
  | costTracking
  | telemetrySpans
  | queryCorrelation
  | analyticsSinks
  | deepLinkValidation
  | unicodeSanitization
  | ruleShadowingDetection
  | toolSearchStrategy
  | toolResultPairing
  | perToolPersistence
  | toolPoolDedup
  | sessionResume
  | cronSchedulerLock
  | apiResilience
  | contextOverflowRecovery
  | asyncConcurrencyPrimitives
  | startupSequence
  | rateLimitManagement
  | voiceModeGating
  | cronTaskLifecycle
  | marketplaceReconciliation
  | proxyAndPreconnect
  | activityTracking
  | advisorCostTracking
  | eventUploading
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .denyShortCircuit => []
  | .multiLayerSecurity => []
  | .pathTraversalDetection => []
  | .uncPathBlocking => []
  | .dangerousPathProtection => []
  | .toctouPrevention => []
  | .sandboxEnforcement => []
  | .secretScanning => []
  | .bashAstParsing => []
  | .permissionModes => []
  | .ruleCascade => []
  | .denyWins => [.ruleCascade]
  | .autoModeClassifier => [.permissionModes]
  | .enterprisePolicy => [.ruleCascade]
  | .permissionAuditTrail => [.denyWins]
  | .hookPermissionOverride => [.denyWins]
  | .toolInterface => []
  | .failClosedDefaults => [.toolInterface]
  | .deterministicValidation => [.toolInterface]
  | .resultBounding => [.toolInterface]
  | .bashBackgrounding => [.toolInterface]
  | .featureGatedTools => [.toolInterface]
  | .hierarchicalTeams => []
  | .executionBackends => [.hierarchicalTeams]
  | .fileMailbox => [.hierarchicalTeams]
  | .planApprovalGate => [.hierarchicalTeams]
  | .worktreeIsolation => [.hierarchicalTeams]
  | .shutdownProtocol => [.fileMailbox]
  | .taskDependencyTracking => [.hierarchicalTeams]
  | .immutableAppState => []
  | .queryLoopRecovery => [.immutableAppState]
  | .multiLayerCompaction => [.queryLoopRecovery]
  | .cacheSafeForking => [.queryLoopRecovery]
  | .layeredSystemPrompt => [.immutableAppState]
  | .settingsCascade => []
  | .gracefulShutdown => []
  | .pluginArchitecture => []
  | .hookSystem => []
  | .mcpTransportAbstraction => []
  | .mcpConfigCascade => [.mcpTransportAbstraction]
  | .commandAggregation => []
  | .skillExecution => [.pluginArchitecture]
  | .pluginDependencyResolution => [.pluginArchitecture]
  | .autoMemoryTaxonomy => []
  | .dreamConsolidation => [.autoMemoryTaxonomy]
  | .costTracking => []
  | .telemetrySpans => []
  | .queryCorrelation => []
  | .analyticsSinks => [.telemetrySpans]
  | .deepLinkValidation => []
  | .unicodeSanitization => []
  | .ruleShadowingDetection => [.denyWins]
  | .toolSearchStrategy => [.failClosedDefaults]
  | .toolResultPairing => [.deterministicValidation]
  | .perToolPersistence => [.resultBounding]
  | .toolPoolDedup => []
  | .sessionResume => [.worktreeIsolation]
  | .cronSchedulerLock => []
  | .apiResilience => [.queryLoopRecovery]
  | .contextOverflowRecovery => [.queryLoopRecovery]
  | .asyncConcurrencyPrimitives => []
  | .startupSequence => []
  | .rateLimitManagement => []
  | .voiceModeGating => [.pluginArchitecture]
  | .cronTaskLifecycle => []
  | .marketplaceReconciliation => [.pluginDependencyResolution]
  | .proxyAndPreconnect => []
  | .activityTracking => []
  | .advisorCostTracking => [.costTracking]
  | .eventUploading => [.analyticsSinks]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- Non-negotiable safety constraints: path validation, injection prevention, TOCTOU protection, sandbox enforcement, secret scanning (ord=0) -/
  | safety
  /-- Configurable permission system: modes, rule cascade, classifier, enterprise policy, audit trail (ord=1) -/
  | permission
  /-- Core tool interface, validation, execution model, result handling, concurrency safety (ord=2) -/
  | tool
  /-- Multi-agent teams, worktree isolation, task lifecycle, plan mode governance (ord=3) -/
  | orchestration
  /-- Query loop, state management, compaction, context composition, settings cascade (ord=4) -/
  | conversation
  /-- Plugin system, hooks, MCP integration, skills, commands, output styles (ord=5) -/
  | extension
  /-- Memory consolidation, telemetry, cost tracking, analytics, diagnostics (ord=6) -/
  | observability
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .safety => 0
  | .permission => 1
  | .tool => 2
  | .orchestration => 3
  | .conversation => 4
  | .extension => 5
  | .observability => 6

/-- 認識論的層構造の typeclass（スタンドアロン版）。 -/
class EpistemicLayerClass (α : Type) where
  ord : α → Nat
  bottom : α
  nontrivial : ∃ (a b : α), ord a ≠ ord b
  ord_injective : ∀ (a b : α), ord a = ord b → a = b
  ord_bounded : ∃ (n : Nat), ∀ (a : α), ord a ≤ n
  bottom_minimum : ∀ (a : α), ord bottom ≤ ord a

instance : EpistemicLayerClass ConcreteLayer where
  ord := ConcreteLayer.ord
  bottom := .safety
  nontrivial := ⟨.observability, .safety, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨6, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- safety
  | .denyShortCircuit | .multiLayerSecurity | .pathTraversalDetection | .uncPathBlocking | .dangerousPathProtection | .toctouPrevention | .sandboxEnforcement | .secretScanning | .bashAstParsing | .deepLinkValidation | .unicodeSanitization => .safety
  -- permission
  | .permissionModes | .ruleCascade | .denyWins | .autoModeClassifier | .enterprisePolicy | .permissionAuditTrail | .hookPermissionOverride | .ruleShadowingDetection => .permission
  -- tool
  | .toolInterface | .failClosedDefaults | .deterministicValidation | .resultBounding | .bashBackgrounding | .featureGatedTools | .toolSearchStrategy | .toolResultPairing | .perToolPersistence | .toolPoolDedup => .tool
  -- orchestration
  | .hierarchicalTeams | .executionBackends | .fileMailbox | .planApprovalGate | .worktreeIsolation | .shutdownProtocol | .taskDependencyTracking | .sessionResume | .cronSchedulerLock => .orchestration
  -- conversation
  | .immutableAppState | .queryLoopRecovery | .multiLayerCompaction | .cacheSafeForking | .layeredSystemPrompt | .settingsCascade | .gracefulShutdown | .apiResilience | .contextOverflowRecovery | .asyncConcurrencyPrimitives | .startupSequence => .conversation
  -- extension
  | .pluginArchitecture | .hookSystem | .mcpTransportAbstraction | .mcpConfigCascade | .commandAggregation | .skillExecution | .pluginDependencyResolution | .rateLimitManagement | .voiceModeGating | .cronTaskLifecycle | .marketplaceReconciliation => .extension
  -- observability
  | .autoMemoryTaxonomy | .dreamConsolidation | .costTracking | .telemetrySpans | .queryCorrelation | .analyticsSinks | .proxyAndPreconnect | .activityTracking | .advisorCostTracking | .eventUploading => .observability

-- ============================================================
-- 4. 証明
-- ============================================================

/-- classify は依存関係の単調性を尊重する。 -/
theorem classify_monotone :
    ∀ (a b : PropositionId),
      propositionDependsOn a b = true →
      ConcreteLayer.ord (classify b) ≥ ConcreteLayer.ord (classify a) := by
  intro a b h; cases a <;> cases b <;> revert h <;> native_decide

/-- classify は全域関数。 -/
theorem classify_total :
    ∀ (p : PropositionId), ∃ (l : ConcreteLayer), classify p = l :=
  fun p => ⟨classify p, rfl⟩

end Manifest.Models.Instances.ClaudeCodeCLI
