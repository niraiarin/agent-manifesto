/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **runtime** (ord=0): Hook execution engine, event dispatch, I/O protocol, session lifecycle, plugin environment [PD-050, PD-051, PD-052, PD-053, PD-054, PD-055, PD-056, PD-057, PD-058, PD-059, PD-060, PD-061, PD-062, PD-063, PD-064, PD-065, PD-066, PD-067, PD-069, PD-070, PD-071, PD-072, PD-073, PD-074, PD-075, PD-076, PD-078, PD-079, PD-080, PD-103, PD-105, PD-106, PD-107, PD-108, PD-109, PD-110, PD-111, PD-220, PD-221, PD-222, PD-223, PD-224, PD-225, PD-226, PD-227, PD-228, PD-229, PD-244, PD-245, PD-250, PD-251, PD-252, PD-253, PD-254, PD-269, PD-287, PD-288, PD-289, PD-290, PD-291, PD-293, PD-297, PD-298, PD-335, PD-336, PD-339, PD-342, PD-343, PD-346, PD-348, PD-350]
- **safety** (ord=1): Permission model, sandbox enforcement, security scanning, settings protection, operation guards [PD-001, PD-004, PD-005, PD-016, PD-125, PD-135, PD-139, PD-189, PD-194, PD-195, PD-196, PD-197, PD-198, PD-199, PD-230, PD-231, PD-232, PD-233, PD-234, PD-235, PD-236, PD-237, PD-238, PD-239, PD-240, PD-241, PD-242, PD-243, PD-255, PD-256, PD-257, PD-258, PD-259, PD-260, PD-261, PD-262, PD-263, PD-268, PD-278, PD-292, PD-295, PD-299, PD-304, PD-316, PD-329, PD-337, PD-338, PD-358, PD-360, PD-362, PD-363, PD-364]
- **verification** (ord=2): Multi-agent review, confidence scoring, test coverage, SDK verification, plugin validation [PD-129, PD-140, PD-141, PD-144, PD-150, PD-151, PD-152, PD-153, PD-154, PD-155, PD-156, PD-157, PD-158, PD-159, PD-160, PD-161, PD-162, PD-172, PD-185, PD-186, PD-187, PD-188, PD-202, PD-203, PD-204, PD-205, PD-206, PD-207, PD-208, PD-209, PD-210, PD-264, PD-265, PD-266, PD-271, PD-279]
- **workflow** (ord=3): Git workflow, CI/CD automation, issue management, dev environment, feature development [PD-002, PD-006, PD-007, PD-008, PD-009, PD-010, PD-011, PD-012, PD-013, PD-015, PD-018, PD-019, PD-020, PD-025, PD-026, PD-028, PD-030, PD-128, PD-131, PD-132, PD-143, PD-163, PD-164, PD-165, PD-166, PD-167, PD-168, PD-170, PD-171, PD-174, PD-175, PD-176, PD-177, PD-178, PD-179, PD-180, PD-181, PD-182, PD-183, PD-184, PD-190, PD-191, PD-192, PD-193, PD-267, PD-270, PD-300, PD-301, PD-302, PD-303, PD-305, PD-306, PD-307, PD-308, PD-309, PD-310, PD-311, PD-312, PD-313, PD-314, PD-315, PD-317, PD-318, PD-319, PD-320, PD-321, PD-322, PD-323, PD-324, PD-325, PD-326, PD-327, PD-328, PD-330, PD-349, PD-355, PD-356, PD-357, PD-359, PD-361, PD-365, PD-366]
- **orchestration** (ord=4): Agent definition, delegation, isolation, MCP integration, observability, distributed tracing [PD-003, PD-024, PD-119, PD-120, PD-121, PD-122, PD-123, PD-124, PD-137, PD-142, PD-169, PD-173, PD-272, PD-273, PD-274, PD-275, PD-276, PD-277, PD-282, PD-283, PD-284, PD-285, PD-286, PD-294, PD-296, PD-340, PD-341, PD-344, PD-347]
- **learning** (ord=5): Memory management, skill architecture, command system, skill authoring [PD-014, PD-027, PD-029, PD-112, PD-113, PD-114, PD-115, PD-116, PD-117, PD-118, PD-138, PD-280, PD-281]
- **domain** (ord=6): Plugin ecosystem, structure, composition, local configuration [PD-017, PD-021, PD-022, PD-023, PD-068, PD-077, PD-100, PD-101, PD-102, PD-104, PD-126, PD-127, PD-130, PD-133, PD-134, PD-136, PD-200, PD-201, PD-345]
-/

namespace Manifest.Models.Instances.AnthropicsClaudeCode

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | contextManagement
  | hookCodingPatterns
  | hookEventTypes
  | hookIoProtocol
  | hookRuleMatching
  | pluginEnvironment
  | sessionLifecycle
  | cicdPermissions
  | credentialSecurity
  | managedSettings
  | permissionModel
  | sandboxEnforcement
  | securityScanHooks
  | strictSettings
  | toolPermissions
  | multiAgentReview
  | pluginValidation
  | reviewAgentScope
  | reviewConfidenceScoring
  | reviewPhaseOrder
  | sdkVerification
  | testCoverageStrategy
  | typeDesignReview
  | cicdAutomation
  | devEnvironment
  | featureDevWorkflow
  | gitWorkflow
  | issueLabelingWorkflow
  | issueLifecycleManagement
  | issueTemplates
  | loopPatterns
  | sdkSetupWorkflow
  | agentDefinition
  | agentObservability
  | distributedTracing
  | mcpIntegration
  | parallelAgentSearch
  | subagentIsolation
  | commandSystem
  | memoryManagement
  | skillArchitecture
  | skillAuthoring
  | pluginComposition
  | pluginEcosystem
  | pluginLocalConfig
  | pluginStructure
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .contextManagement => []
  | .hookCodingPatterns => [.hookIoProtocol]
  | .hookEventTypes => []
  | .hookIoProtocol => [.hookEventTypes]
  | .hookRuleMatching => [.hookEventTypes]
  | .pluginEnvironment => [.hookEventTypes]
  | .sessionLifecycle => [.hookEventTypes]
  | .cicdPermissions => [.permissionModel]
  | .credentialSecurity => [.permissionModel]
  | .managedSettings => [.permissionModel]
  | .permissionModel => []
  | .sandboxEnforcement => [.permissionModel]
  | .securityScanHooks => []
  | .strictSettings => [.managedSettings]
  | .toolPermissions => [.permissionModel]
  | .multiAgentReview => [.agentDefinition]
  | .pluginValidation => [.pluginStructure]
  | .reviewAgentScope => [.multiAgentReview]
  | .reviewConfidenceScoring => [.multiAgentReview]
  | .reviewPhaseOrder => [.multiAgentReview]
  | .sdkVerification => [.testCoverageStrategy]
  | .testCoverageStrategy => []
  | .typeDesignReview => []
  | .cicdAutomation => [.gitWorkflow]
  | .devEnvironment => []
  | .featureDevWorkflow => [.gitWorkflow]
  | .gitWorkflow => []
  | .issueLabelingWorkflow => []
  | .issueLifecycleManagement => [.issueLabelingWorkflow]
  | .issueTemplates => [.issueLifecycleManagement]
  | .loopPatterns => []
  | .sdkSetupWorkflow => []
  | .agentDefinition => []
  | .agentObservability => [.agentDefinition]
  | .distributedTracing => [.agentObservability]
  | .mcpIntegration => [.agentDefinition]
  | .parallelAgentSearch => [.agentDefinition]
  | .subagentIsolation => [.agentDefinition]
  | .commandSystem => []
  | .memoryManagement => []
  | .skillArchitecture => [.commandSystem]
  | .skillAuthoring => [.skillArchitecture]
  | .pluginComposition => [.pluginStructure]
  | .pluginEcosystem => []
  | .pluginLocalConfig => [.pluginStructure]
  | .pluginStructure => [.pluginEcosystem]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- Hook execution engine, event dispatch, I/O protocol, session lifecycle, plugin environment (ord=0) -/
  | runtime
  /-- Permission model, sandbox enforcement, security scanning, settings protection, operation guards (ord=1) -/
  | safety
  /-- Multi-agent review, confidence scoring, test coverage, SDK verification, plugin validation (ord=2) -/
  | verification
  /-- Git workflow, CI/CD automation, issue management, dev environment, feature development (ord=3) -/
  | workflow
  /-- Agent definition, delegation, isolation, MCP integration, observability, distributed tracing (ord=4) -/
  | orchestration
  /-- Memory management, skill architecture, command system, skill authoring (ord=5) -/
  | learning
  /-- Plugin ecosystem, structure, composition, local configuration (ord=6) -/
  | domain
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .runtime => 0
  | .safety => 1
  | .verification => 2
  | .workflow => 3
  | .orchestration => 4
  | .learning => 5
  | .domain => 6

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
  bottom := .runtime
  nontrivial := ⟨.domain, .runtime, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨6, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- runtime
  | .contextManagement | .hookCodingPatterns | .hookEventTypes | .hookIoProtocol | .hookRuleMatching | .pluginEnvironment | .sessionLifecycle => .runtime
  -- safety
  | .cicdPermissions | .credentialSecurity | .managedSettings | .permissionModel | .sandboxEnforcement | .securityScanHooks | .strictSettings | .toolPermissions => .safety
  -- verification
  | .multiAgentReview | .pluginValidation | .reviewAgentScope | .reviewConfidenceScoring | .reviewPhaseOrder | .sdkVerification | .testCoverageStrategy | .typeDesignReview => .verification
  -- workflow
  | .cicdAutomation | .devEnvironment | .featureDevWorkflow | .gitWorkflow | .issueLabelingWorkflow | .issueLifecycleManagement | .issueTemplates | .loopPatterns | .sdkSetupWorkflow => .workflow
  -- orchestration
  | .agentDefinition | .agentObservability | .distributedTracing | .mcpIntegration | .parallelAgentSearch | .subagentIsolation => .orchestration
  -- learning
  | .commandSystem | .memoryManagement | .skillArchitecture | .skillAuthoring => .learning
  -- domain
  | .pluginComposition | .pluginEcosystem | .pluginLocalConfig | .pluginStructure => .domain

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

end Manifest.Models.Instances.AnthropicsClaudeCode
