import AgentSpec.Manifest.D

/-! # AgentSpec.Manifest.EvolveSkill (Week 3 Day 115)

Formal evaluation of the `/evolve` skill against the Manifest lifecycle and
design constraints. This is an axiom-free, self-contained porting slice: the
workflow and compatibility helpers used by the source module are encoded here
as definitional extensions, while shared D2/D3/D9 structures are reused from
`AgentSpec.Manifest.D`.
-/

namespace AgentSpec.Manifest
namespace EvolveSkill

/-! ## Workflow and evolution subset -/

/-- Learning lifecycle phases used by `/evolve`. -/
inductive LearningPhase where
  | observation
  | hypothesizing
  | verification
  | judging
  | integration
  | retirement
  deriving BEq, Repr, DecidableEq

/-- Valid lifecycle transitions, including verifier and judge loopbacks. -/
def validPhaseTransition : LearningPhase → LearningPhase → Prop
  | .observation,   .hypothesizing => True
  | .hypothesizing, .verification  => True
  | .verification,  .judging       => True
  | .judging,       .integration   => True
  | .judging,       .hypothesizing => True
  | .verification,  .integration   => True
  | .integration,   .retirement    => True
  | .verification,  .hypothesizing => True
  | .verification,  .observation   => True
  | .retirement,    .observation   => True
  | _,              _              => False

/-- Knowledge lifecycle status. -/
inductive KnowledgeStatus where
  | observed
  | hypothesized
  | verified
  | integrated
  | retired
  deriving BEq, Repr, DecidableEq

/-- Knowledge item flowing through the lifecycle. -/
structure KnowledgeItem where
  status : KnowledgeStatus
  targetStructure : StructureId
  compatibility : CompatibilityClass
  independentlyVerified : Bool
  deriving Repr

/-- Valid knowledge-state transitions. -/
def validKnowledgeTransition : KnowledgeStatus → KnowledgeStatus → Prop
  | .observed,     .hypothesized => True
  | .hypothesized, .verified     => True
  | .verified,     .integrated   => True
  | .integrated,   .retired      => True
  | .verified,     .hypothesized => True
  | .verified,     .observed     => True
  | _,             _             => False

/-- Integration gate: independent verification, verified status, epoch bump for breaking changes. -/
def integrationGateCondition
    (ki : KnowledgeItem) (w_before w_after : World) : Prop :=
  ki.independentlyVerified = true ∧
  ki.status = .verified ∧
  (ki.compatibility = .breakingChange → w_before.epoch < w_after.epoch)

/-- Integrated breaking changes are retirement candidates. -/
def retirementCandidate (ki : KnowledgeItem) : Prop :=
  ki.status = .integrated ∧ ki.compatibility = .breakingChange

/-- Verification is required before integration. -/
theorem integration_requires_verification :
  ¬validKnowledgeTransition .observed .integrated ∧
  ¬validKnowledgeTransition .hypothesized .integrated := by
  constructor <;> simp [validKnowledgeTransition]

/-- Compatibility join: the most restrictive classification dominates. -/
def compatibilityJoin (c₁ c₂ : CompatibilityClass) : CompatibilityClass :=
  match c₁, c₂ with
  | .conservativeExtension, .conservativeExtension => .conservativeExtension
  | .conservativeExtension, .compatibleChange      => .compatibleChange
  | .conservativeExtension, .breakingChange        => .breakingChange
  | .compatibleChange,      .conservativeExtension => .compatibleChange
  | .compatibleChange,      .compatibleChange      => .compatibleChange
  | .compatibleChange,      .breakingChange        => .breakingChange
  | .breakingChange,        _                      => .breakingChange

/-- Breaking change dominates compatibility composition. -/
theorem breaking_change_dominates :
  ∀ (c : CompatibilityClass),
    compatibilityJoin CompatibilityClass.breakingChange c = .breakingChange := by
  intro c
  cases c <;> rfl

/-! ## `/evolve` domain -/

/-- `/evolve` agent roles. -/
inductive EvolveAgent where
  | observer
  | hypothesizer
  | verifier
  | judge
  | integrator
  deriving BEq, Repr, DecidableEq

/-- `/evolve` phases. -/
inductive EvolvePhase where
  | observe
  | hypothesize
  | verify
  | judge
  | integrate
  | retire
  deriving BEq, Repr, DecidableEq

/-- `/evolve` phase to Manifest learning phase. -/
def toWorkflowPhase : EvolvePhase → LearningPhase
  | .observe     => .observation
  | .hypothesize => .hypothesizing
  | .verify      => .verification
  | .judge       => .judging
  | .integrate   => .integration
  | .retire      => .retirement

/-- Responsible agent for each phase. -/
def phaseAgent : EvolvePhase → EvolveAgent
  | .observe     => .observer
  | .hypothesize => .hypothesizer
  | .verify      => .verifier
  | .judge       => .judge
  | .integrate   => .integrator
  | .retire      => .integrator

/-- Manifest compliance properties expressed by `/evolve`. -/
inductive ComplianceProperty where
  | lifecycleAlignment
  | verificationSeparation
  | humanApproval
  | compatibilityRequired
  | observabilityFirst
  | selfApplication
  | retirementDual
  deriving BEq, Repr, DecidableEq

/-! ## Lifecycle alignment -/

/-- `/evolve` phase order aligns with the learning lifecycle. -/
theorem phase_order_aligns_with_workflow :
  validPhaseTransition (toWorkflowPhase .observe) (toWorkflowPhase .hypothesize) ∧
  validPhaseTransition (toWorkflowPhase .hypothesize) (toWorkflowPhase .verify) ∧
  validPhaseTransition (toWorkflowPhase .verify) (toWorkflowPhase .judge) ∧
  validPhaseTransition (toWorkflowPhase .judge) (toWorkflowPhase .integrate) ∧
  validPhaseTransition (toWorkflowPhase .verify) (toWorkflowPhase .integrate) ∧
  validPhaseTransition (toWorkflowPhase .integrate) (toWorkflowPhase .retire) := by
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩ <;> trivial

/-- Full `/evolve` cycle matches the workflow phases. -/
theorem evolve_full_cycle_matches_workflow :
  (toWorkflowPhase .observe = .observation) ∧
  (toWorkflowPhase .hypothesize = .hypothesizing) ∧
  (toWorkflowPhase .verify = .verification) ∧
  (toWorkflowPhase .judge = .judging) ∧
  (toWorkflowPhase .integrate = .integration) ∧
  (toWorkflowPhase .retire = .retirement) := by
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩ <;> rfl

/-- Every phase has an assigned agent. -/
theorem all_phases_have_agents :
  ∀ (p : EvolvePhase), ∃ (a : EvolveAgent), phaseAgent p = a := by
  intro p
  exact ⟨phaseAgent p, rfl⟩

/-- All five agent roles are used. -/
theorem all_agents_used :
  (∃ p, phaseAgent p = .observer) ∧
  (∃ p, phaseAgent p = .hypothesizer) ∧
  (∃ p, phaseAgent p = .verifier) ∧
  (∃ p, phaseAgent p = .judge) ∧
  (∃ p, phaseAgent p = .integrator) := by
  refine ⟨⟨.observe, rfl⟩, ⟨.hypothesize, rfl⟩, ⟨.verify, rfl⟩, ⟨.judge, rfl⟩, ⟨.integrate, rfl⟩⟩

/-! ## Verification independence -/

/-- `/evolve` verifier independence profile: context separation only. -/
def evolveVerifierProfile : VerificationIndependence :=
  { contextSeparated := true
    framingIndependent := false
    executionAutomatic := false
    evaluatorIndependent := false }

/-- `/evolve` verifier is sufficient for low risk. -/
theorem evolve_verifier_sufficient_for_low :
  sufficientVerification evolveVerifierProfile .low := by
  simp [sufficientVerification, satisfiedConditions, evolveVerifierProfile, requiredConditions]

/-- `/evolve` verifier is insufficient for moderate risk. -/
theorem evolve_verifier_insufficient_for_moderate :
  ¬sufficientVerification evolveVerifierProfile .moderate := by
  simp [sufficientVerification, satisfiedConditions, evolveVerifierProfile, requiredConditions]

/-- `/evolve` verifier is insufficient for high risk. -/
theorem evolve_verifier_insufficient_for_high :
  ¬sufficientVerification evolveVerifierProfile .high := by
  simp [sufficientVerification, satisfiedConditions, evolveVerifierProfile, requiredConditions]

/-- `/evolve` verifier is insufficient for critical risk. -/
theorem evolve_verifier_insufficient_for_critical :
  ¬sufficientVerification evolveVerifierProfile .critical := by
  simp [sufficientVerification, satisfiedConditions, evolveVerifierProfile, requiredConditions]

/-! ## Gates, compatibility, and retirement -/

/-- Integration gate exposes independent verification and verified status. -/
theorem integration_gate_structure :
  ∀ (ki : KnowledgeItem) (w_before w_after : World),
    integrationGateCondition ki w_before w_after →
    ki.independentlyVerified = true ∧ ki.status = .verified := by
  intro ki _ _ ⟨h_iv, h_status, _⟩
  exact ⟨h_iv, h_status⟩

/-- Verification bypass is impossible. -/
theorem evolve_no_verification_bypass :
  ¬validKnowledgeTransition .observed .integrated ∧
  ¬validKnowledgeTransition .hypothesized .integrated :=
  integration_requires_verification

/-- Conservative strategy is closed under conservative joins. -/
theorem conservative_strategy_safe :
  compatibilityJoin CompatibilityClass.conservativeExtension .conservativeExtension =
    .conservativeExtension := by
  rfl

/-- Breaking change propagates through joins. -/
theorem breaking_change_propagates :
  ∀ (c : CompatibilityClass),
    compatibilityJoin CompatibilityClass.breakingChange c = .breakingChange :=
  breaking_change_dominates

/-- Retirement basis is dual. -/
inductive RetirementBasis where
  | formal
  | policy
  deriving BEq, Repr, DecidableEq

/-- Formal and policy retirement bases are distinct. -/
theorem retirement_criteria_dual :
  RetirementBasis.formal ≠ RetirementBasis.policy := by
  intro h
  cases h

/-- Formal retirement matches the workflow retirement candidate predicate. -/
theorem formal_retirement_matches_workflow :
  ∀ (ki : KnowledgeItem),
    retirementCandidate ki →
    ki.status = .integrated ∧ ki.compatibility = .breakingChange := by
  intro ki h
  exact h

/-! ## Self-application -/

/-- `/evolve` components governed by D9. -/
inductive EvolveComponent where
  | skill
  | observerAgent
  | hypothesizerAgent
  | integratorAgent
  | verifierAgent
  | judgeAgent
  | hooks
  deriving BEq, Repr, DecidableEq

instance : SelfGoverning EvolveComponent where
  classificationExhaustive := by intro c; cases c <;> simp
  canClassifyUpdate _ _ := True

/-- All `/evolve` components are enumerated. -/
theorem all_components_enumerated :
  ∀ (c : EvolveComponent),
    c = .skill ∨ c = .observerAgent ∨ c = .hypothesizerAgent ∨
    c = .integratorAgent ∨ c = .verifierAgent ∨ c = .judgeAgent ∨ c = .hooks := by
  intro c
  cases c <;> simp

/-- Observation is first. -/
theorem observability_first :
  toWorkflowPhase .observe = .observation := by rfl

/-- Verification can precede integration. -/
theorem verification_precedes_integration :
  validPhaseTransition (toWorkflowPhase .verify) (toWorkflowPhase .integrate) := by
  trivial

/-! ## Hypotheses, deferrals, and loopbacks -/

/-- `/evolve` declared hypotheses. -/
inductive EvolveHypothesis where
  | h1_teams_natural
  | h2_four_agents
  | h3_metrics_adequate
  | h4_conservative_first
  | h5_one_per_session
  | h6_cost_efficiency
  deriving BEq, Repr, DecidableEq

/-- All hypotheses are enumerated. -/
theorem all_hypotheses_enumerated :
  ∀ (h : EvolveHypothesis),
    h = .h1_teams_natural ∨ h = .h2_four_agents ∨
    h = .h3_metrics_adequate ∨ h = .h4_conservative_first ∨
    h = .h5_one_per_session ∨ h = .h6_cost_efficiency := by
  intro h
  cases h <;> simp

/-- Hypothesis count is six. -/
theorem hypothesis_count :
  [EvolveHypothesis.h1_teams_natural,
   .h2_four_agents, .h3_metrics_adequate,
   .h4_conservative_first, .h5_one_per_session,
   .h6_cost_efficiency].length = 6 := by rfl

/-- Valid deferral reasons. -/
inductive DeferralReason where
  | resourceExhaustion
  | dependencyBlocked
  | actionSpaceExceeded
  deriving BEq, Repr, DecidableEq

/-- Deferral lifecycle status. -/
inductive DeferralStatus where
  | open
  | resolved
  | abandoned
  deriving BEq, Repr, DecidableEq

/-- Deferral requires one of the valid justifications. -/
theorem deferral_requires_justification :
  ∀ (r : DeferralReason),
    r = .resourceExhaustion ∨ r = .dependencyBlocked ∨ r = .actionSpaceExceeded := by
  intro r
  cases r <;> simp

/-- Untracked forward reference violates D3 observability. -/
theorem untracked_forward_reference_violates_d3 :
  ¬effectivelyOptimizable ⟨true, true, .humanReadable, true⟩ :=
  d3_human_readable_insufficient

/-- Deferral status is exhaustive. -/
theorem deferral_status_exhaustive :
  ∀ (s : DeferralStatus),
    s = .open ∨ s = .resolved ∨ s = .abandoned := by
  intro s
  cases s <;> simp

/-- FAIL root cause classification. -/
inductive FailRootCause where
  | observationError
  | hypothesisError
  | assumptionError
  | preconditionError
  deriving BEq, Repr, DecidableEq

/-- Loopback target by root cause. -/
def loopbackTarget : FailRootCause → Option EvolvePhase
  | .observationError  => some .observe
  | .hypothesisError   => some .hypothesize
  | .assumptionError   => some .hypothesize
  | .preconditionError => none

/-- Loopback budget parameter. -/
structure LoopbackBudget where
  maxRetries : Nat
  deriving BEq, Repr

/-- Loopback targets are valid transitions from verification. -/
theorem loopback_target_valid_transition :
  ∀ (cause : FailRootCause) (phase : EvolvePhase),
    loopbackTarget cause = some phase →
    validPhaseTransition (toWorkflowPhase .verify) (toWorkflowPhase phase) := by
  intro cause phase h
  cases cause <;> simp [loopbackTarget] at h <;> subst h <;>
    simp [toWorkflowPhase, validPhaseTransition]

/-- Loopback target determines an agent. -/
theorem loopback_agent_determined :
  ∀ (cause : FailRootCause) (phase : EvolvePhase),
    loopbackTarget cause = some phase →
    ∃ (a : EvolveAgent), phaseAgent phase = a := by
  intro cause phase h
  cases cause <;> simp [loopbackTarget] at h <;> subst h <;> exact ⟨_, rfl⟩

/-- Observation error loops to Observer. -/
theorem observation_error_loops_to_observer :
  loopbackTarget .observationError = some .observe ∧
  phaseAgent .observe = .observer := by
  constructor <;> rfl

/-- Hypothesis error loops to Hypothesizer. -/
theorem hypothesis_error_loops_to_hypothesizer :
  loopbackTarget .hypothesisError = some .hypothesize ∧
  phaseAgent .hypothesize = .hypothesizer := by
  constructor <;> rfl

/-- Precondition error does not loop back automatically. -/
theorem precondition_error_no_loopback :
  loopbackTarget .preconditionError = none := by rfl

/-- Loopback budget is a parameter. -/
theorem loopback_budget_is_parameter :
  ∀ (n : Nat), (⟨n⟩ : LoopbackBudget).maxRetries = n := by
  intro n
  rfl

/-- Judge failure loops to Hypothesizer. -/
theorem judge_fail_loops_to_hypothesizer :
  validPhaseTransition (toWorkflowPhase .judge) (toWorkflowPhase .hypothesize) ∧
  phaseAgent .hypothesize = .hypothesizer := by
  constructor
  · trivial
  · rfl

/-! ## Composite compliance theorem -/

/-- `/evolve` satisfies the structural compliance subset encoded here. -/
theorem evolve_skill_compliant :
  (validPhaseTransition (toWorkflowPhase .observe) (toWorkflowPhase .hypothesize) ∧
   validPhaseTransition (toWorkflowPhase .hypothesize) (toWorkflowPhase .verify) ∧
   validPhaseTransition (toWorkflowPhase .verify) (toWorkflowPhase .judge) ∧
   validPhaseTransition (toWorkflowPhase .judge) (toWorkflowPhase .integrate) ∧
   validPhaseTransition (toWorkflowPhase .verify) (toWorkflowPhase .integrate) ∧
   validPhaseTransition (toWorkflowPhase .integrate) (toWorkflowPhase .retire)) ∧
  ((∃ p, phaseAgent p = EvolveAgent.observer) ∧
   (∃ p, phaseAgent p = EvolveAgent.hypothesizer) ∧
   (∃ p, phaseAgent p = EvolveAgent.verifier) ∧
   (∃ p, phaseAgent p = EvolveAgent.judge) ∧
   (∃ p, phaseAgent p = EvolveAgent.integrator)) ∧
  sufficientVerification evolveVerifierProfile .low ∧
  (¬validKnowledgeTransition .observed .integrated ∧
   ¬validKnowledgeTransition .hypothesized .integrated) ∧
  (toWorkflowPhase .observe = .observation) := by
  refine ⟨?_, ?_, ?_, ?_, ?_⟩
  · exact phase_order_aligns_with_workflow
  · exact all_agents_used
  · exact evolve_verifier_sufficient_for_low
  · exact evolve_no_verification_bypass
  · rfl

end EvolveSkill
end AgentSpec.Manifest
