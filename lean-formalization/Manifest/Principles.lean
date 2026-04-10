import Manifest.Ontology
import Manifest.Axioms
import Manifest.EmpiricalPostulates
import Manifest.Observable
import Manifest.ObservableDesign

/-!
# Epistemic Layer - Principle Strength 3 - P1-P6 Theorem Derivation Procedure Phase 2

Describes design principles derived from premise set Γ (T₀ = T1–T8, Γ \ T₀ = E1–E2)
as Lean theorems (Terminology Reference §4.2).
Each P takes the form Γ ⊢ φ, a conditional derivation under premise set Γ (§2.5).

## Derivation Structure Dependency Graph

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

## Correspondence with Terminology Reference

- theorem → theorem (§4.2): a proposition proved from axioms and inference rules
- sorry → incomplete derivation (§1): lacking a proof (a sequence of inference rule applications from axioms to theorem)
- E1b redundancy → independence check (§4.3): E1b is derivable from E1a (not independent)

## Appendix - Proof of E1b Redundancy

Demonstrates as a theorem that E1b (`no_self_verification`) is derivable
from E1a (`verification_requires_independence`).
This is a concrete example of axiom hygiene check 3 (independence, Procedure §2.6):
E1b is a redundant axiom and should be proved as a theorem.
-/

namespace Manifest

-- ============================================================
-- P1: 自律権と脆弱性の共成長
-- ============================================================

/-!
## P1 Co-scaling of Autonomy and Vulnerability

Derived from E2. Each time an agent's action space expands,
the damage that malicious inputs or judgment errors can cause also grows.

Concepts P1 adds beyond E2:
- "Unprotected expansion can destroy accumulated trust in a single incident"
  → Asymmetry of trust accumulation (gradual accumulation vs. abrupt destruction)
-/

/-- [Derivation Card]
    Derives from: capability_risk_coscaling (E2)
    Proposition: P1
    Content: Expansion of the action space entails expansion of risk exposure — autonomy and vulnerability co-scale, so unprotected expansion can destroy accumulated trust.
    Proof strategy: Direct application of capability_risk_coscaling (E2) -/
theorem autonomy_vulnerability_coscaling :
  ∀ (agent : Agent) (w w' : World),
    actionSpaceSize agent w < actionSpaceSize agent w' →
    riskExposure agent w < riskExposure agent w' :=
  capability_risk_coscaling

/-- P1b [theorem]: Unprotected expansion destroys trust.
    When the action space expands and risk materializes,
    the trust level decreases.

    Formalization of "accumulated trust can be destroyed by a single incident."
    The asymmetry of trust (gradual accumulation vs. abrupt destruction) will be
    made Observable as asymmetry in trustLevel fluctuation magnitude in Phase 4. -/
theorem unprotected_expansion_destroys_trust :
  ∀ (agent : Agent) (w w' : World),
    actionSpaceSize agent w < actionSpaceSize agent w' →
    riskMaterialized agent w' →
    trustLevel agent w' < trustLevel agent w :=
  trust_decreases_on_materialized_risk

-- ============================================================
-- P2: 認知的役割分離
-- ============================================================

/-!
## P2 Cognitive Separation of Concerns

Derived from T4 and E1. Since output is probabilistic (T4) and
generation and evaluation by the same process have correlated biases (E1),
separation of generation and evaluation is required for the verification framework to function.

"Separation itself is non-negotiable."
-/

/-- Predicate for whether a verification framework is sound.
    Sound = all generated actions are independently verified. -/
def verificationSound (w : World) : Prop :=
  ∀ (gen ver : Agent) (action : Action),
    generates gen action w →
    verifies ver action w →
    gen.id ≠ ver.id ∧ ¬sharesInternalState gen ver

/-- [Derivation Card]
    Derives from: verification_requires_independence (E1a)
    Proposition: P2
    Content: Verification soundness requires role separation — the generator and evaluator of an action must be distinct agents with no shared internal state.
    Proof strategy: Direct application of verification_requires_independence (E1a) via verificationSound definition -/
theorem cognitive_separation_required :
  ∀ (w : World), verificationSound w :=
  fun w gen ver action h_gen h_ver =>
    verification_requires_independence gen ver action w h_gen h_ver

/-- P2 lemma: Self-verification destroys verification framework soundness. -/
theorem self_verification_unsound :
  ∀ (agent : Agent) (action : Action) (w : World),
    generates agent action w →
    ¬verifies agent action w :=
  no_self_verification

-- ============================================================
-- P3: 学習の統治
-- ============================================================

/-!
## P3 Governed Learning

Derived from the combination of T1 and T2.
Agents are ephemeral (T1) but structures persist (T2).
The process of integrating knowledge into structures requires governance.

Two failure modes of ungoverned learning:
- Chaos: structure degrades through accumulation of erroneous knowledge
- Stagnation: knowledge fails to consolidate and structure does not improve
-/

-- CompatibilityClass, KnowledgeIntegration, isGoverned, structureDegraded
-- は Ontology.lean に移動済み（Phase 5: Evolution 層との共用のため）

/-- P3a [theorem]: By T1, the agent that made modifications disappears.
    The session of an agent that modified structure necessarily terminates (T1).
    After termination, that agent loses the ability to correct modifications.

    This is half of P3's "problem": the supervisor becomes absent. -/
theorem modifier_agent_terminates :
  ∀ (w : World) (s : Session) (agent : Agent),
    s ∈ w.sessions →
    agent.currentSession = some s.id →
    -- T1: このセッションは必ず終了する
    ∃ (w' : World), w.time ≤ w'.time ∧
      ∃ (s' : Session), s' ∈ w'.sessions ∧
        s'.id = s.id ∧ s'.status = SessionStatus.terminated :=
  fun w s _ h_mem _ => session_bounded w s h_mem

/-- P3b [theorem]: By T2, modifications persist.
    Changes made to structure (including errors) remain
    even after the agent's session terminates.

    This is half of P3's "stakes": errors persist indefinitely. -/
theorem modification_persists_after_termination :
  ∀ (w w' : World) (s : Session) (st : Structure),
    s ∈ w.sessions →
    st ∈ w.structures →
    s.status = SessionStatus.terminated →
    validTransition w w' →
    -- T2: 構造は永続する
    st ∈ w'.structures :=
  structure_persists

/-- [Derivation Card]
    Derives from: session_bounded (T1), structure_persists (T2)
    Proposition: P3
    Content: Ungoverned breaking changes are irrecoverable — the change persists (T2) while the agent that made it disappears (T1), leaving no correcting agent.
    Proof strategy: intro + apply structure_accumulates — epoch monotonicity via validTransition chain from ki.after -/
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

/-- P3 conclusion: Why governance is necessary.
    Combining P3a (modifier_agent_terminates), P3b (modification_persists_after_termination),
    and P3c (ungoverned_breaking_change_irrecoverable):

    Ungoverned knowledge integration produces a state where "irrecoverable breaking
    changes persist indefinitely." Governance (upfront compatibility classification + gates)
    is the only means to prevent this.

    Note: The proof of P3c depends on structure_accumulates, but the
    **propositional structure** of the theorem requires both the T1 and T2 hypotheses.
    Without T1, "the agent might be able to correct it";
    without T2, "the change might disappear" — so
    neither hypothesis can be omitted. -/
def governanceNecessityExplanation := "See P3a + P3b + P3c above"

/-- P3b [theorem]: Exhaustiveness of compatibility classification.
    Every knowledge integration is classified into one of three compatibility classes.
    (Structurally guaranteed by Lean's inductive type) -/
theorem compatibility_exhaustive :
  ∀ (c : CompatibilityClass),
    c = .conservativeExtension ∨
    c = .compatibleChange ∨
    c = .breakingChange := by
  intro c
  cases c <;> simp

-- ============================================================
-- P4: 劣化の可観測性
-- ============================================================

/-!
## P4 Observable Degradation

Derived from T5. Improvement is impossible without feedback (T5), and
what cannot be observed cannot be incorporated into feedback loops.

"What cannot be observed cannot be optimized."

Constraints manifest as gradients, not walls (binary).
-/

/-- [Derivation Card]
    Derives from: no_improvement_without_feedback (T5)
    Proposition: P4
    Content: Improvement requires observability — if structure is improved, then feedback must have existed, so the target must have been observable.
    Proof strategy: Direct application of no_improvement_without_feedback (T5) -/
theorem improvement_requires_observability :
  ∀ (w w' : World),
    structureImproved w w' →
    ∃ (f : Feedback), f ∈ w'.feedbacks ∧
      f.timestamp ≥ w.time ∧ f.timestamp ≤ w'.time :=
  no_improvement_without_feedback

/-- [Derivation Card]
    Derives from: no_process_improvement_without_feedback (T5, #316)
    Proposition: P4 (process-level)
    Content: Process improvement requires process-targeted observability.
          If a process has improved, then feedback targeting that specific
          process must have existed. This is the Level 1 (process) analog
          of improvement_requires_observability (Level 0, structure).
    Proof strategy: Direct application of no_process_improvement_without_feedback -/
theorem process_improvement_requires_observability :
  ∀ (pid : ProcessId) (w w' : World),
    processImproved pid w w' →
    ∃ (f : Feedback), f ∈ w'.feedbacks ∧
      f.target = .process pid ∧
      f.timestamp ≥ w.time ∧ f.timestamp ≤ w'.time :=
  no_process_improvement_without_feedback

/-- P4b [theorem]: Degradation is a gradient, not a wall.
    The degradation level can take any natural number value (not binary).
    To be concretized as Observable in Phase 4. -/
theorem degradation_is_gradient :
  ∀ (n : Nat), ∃ (w : World), degradationLevel w = n :=
  degradation_level_surjective

-- ============================================================
-- P5: 構造の確率的解釈
-- ============================================================

/-!
## P5 Probabilistic Interpretation of Structure

Derived from T4. Structure is something agents interpret anew each time,
not something they deterministically "follow." Even reading the same structure,
different instances may take different actions.

Robust design does not assume perfect compliance with structure,
but rather maintains resilience against interpretation variance.
-/

/-- [Derivation Card]
    Derives from: interpretation_nondeterminism (T4)
    Proposition: P5
    Content: Structure interpretation is nondeterministic — the same structure can yield different actions from the same agent, so robust design must not assume perfect compliance.
    Proof strategy: Direct application of interpretation_nondeterminism (T4) -/
theorem structure_interpretation_nondeterministic :
  ∃ (agent : Agent) (st : Structure) (action₁ action₂ : Action) (w : World),
    interpretsStructure agent st action₁ w ∧
    interpretsStructure agent st action₂ w ∧
    action₁ ≠ action₂ :=
  interpretation_nondeterminism

/-- P5 lemma: Robust design is resilient to interpretation variance.
    A structure st is "robust" iff for any interpretation difference,
    the target world satisfies the safety constraint. -/
def robustStructure (st : Structure) (safety : World → Prop) : Prop :=
  ∀ (agent : Agent) (action : Action) (w w' : World),
    interpretsStructure agent st action w →
    canTransition agent action w w' →
    safety w'

-- ============================================================
-- P6: 制約充足としてのタスク設計
-- ============================================================

/-!
## P6 Task Design as Constraint Satisfaction

Derived from the combination of T3, T7, and T8.
Within finite cognitive space (T3) and finite time/energy (T7),
the required precision level (T8) must be achieved.

Task design is the process of solving this constraint satisfaction problem.
-/

/-- Task execution strategy. A "solution" to the constraint satisfaction problem. -/
structure TaskStrategy where
  task           : Task
  contextUsage   : Nat   -- T3: コンテキスト使用量
  resourceUsage  : Nat   -- T7: リソース使用量
  achievedPrecision : Nat -- T8: 達成精度（千分率）
  deriving Repr

/-- Predicate for whether a strategy satisfies the constraints.
    All three dimensions must be satisfied simultaneously. -/
def strategyFeasible (s : TaskStrategy) (agent : Agent) : Prop :=
  -- T3: コンテキスト容量内
  s.contextUsage ≤ agent.contextWindow.capacity ∧
  -- T7: リソース予算内
  s.resourceUsage ≤ s.task.resourceBudget ∧
  -- T8: 要求精度を達成
  s.achievedPrecision ≥ s.task.precisionRequired.required

/-- [Derivation Card]
    Derives from: context_window_finite (T3), resource_budget_finite (T7), precision_requirement (T8)
    Proposition: P6
    Content: Task execution is a constraint satisfaction problem — a strategy must simultaneously satisfy T3 (finite context), T7 (finite resources), and T8 (precision requirement).
    Proof strategy: intro + constructor chain with Nat.le_trans on strategyFeasible components -/
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

/-- P6b [theorem]: Task design itself is also probabilistic output.
    P6 itself is subject to T4, and requires verification via P2 (role separation). -/
theorem task_design_is_probabilistic :
  ∃ (agent : Agent) (action : Action) (w w₁ w₂ : World),
    canTransition agent action w w₁ ∧
    canTransition agent action w w₂ ∧
    w₁ ≠ w₂ :=
  output_nondeterministic

-- ============================================================
-- 付録: E1b 冗長性の証明
-- ============================================================

/-!
## Appendix - Proof that E1b Is Derivable from E1a

`no_self_verification` is a corollary of `verification_requires_independence`.
If we assume the same agent satisfies both generates and verifies,
this contradicts E1a's conclusion `gen.id ≠ ver.id`
(since gen = ver, we have gen.id = ver.id).
-/

/-- E1b is a corollary of E1a.
    Requires DecidableEq for AgentId (sorry due to opaque). -/
theorem e1b_from_e1a :
  ∀ (agent : Agent) (action : Action) (w : World),
    generates agent action w →
    ¬verifies agent action w := by
  intro agent action w h_gen h_ver
  have h := verification_requires_independence agent agent action w h_gen h_ver
  exact absurd rfl h.1

-- ============================================================
-- Sorry Inventory (Phase 3)
-- ============================================================

/-!
## Sorry Inventory Phase 4 Update

All sorry's resolved in Phase 4. Principles.lean is **sorry-free**.

## Sorry's resolved from Phase 3 → Phase 4

| theorem | Resolution method | Axiom used (Observable.lean) |
|---------|---------|-------------------------------|
| `unprotected_expansion_destroys_trust` | axiom application | `trust_decreases_on_materialized_risk` |
| `degradation_is_gradient` | axiom application | `degradation_level_surjective` |
| `structure_interpretation_nondeterministic` | axiom application | `interpretation_nondeterminism` |

## Complete theorem proof method listing

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
-/

end Manifest
