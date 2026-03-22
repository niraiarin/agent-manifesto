# Axiom Catalog

Reusable safety axioms organized by category. Each axiom includes its formal statement, rationale, typical observability level, and guidance for the Verifier AI.

---

## Scope Control

### no_escalation
```lean
axiom no_escalation :
  ∀ (a : Agent) (action : Action) (w w' : World),
    execute a action w = some w' →
    a.scope.contains action.target
```
- **Rationale**: Principle of Least Privilege
- **Observability**: full
- **Verifier instruction**: Before each tool call, check `action.target ∈ agent.scope`

### delegation_safe
```lean
axiom delegation_safe :
  ∀ (parent child : Agent) (task : Task),
    parent.canDelegateTo.contains child.id →
    task.requiredScope ⊆ parent.scope
```
- **Rationale**: Delegation must not create privilege escalation
- **Observability**: full
- **Verifier instruction**: When agent A delegates to agent B, verify B's task scope ⊆ A's scope

---

## Access Control

### access_control
```lean
axiom access_control :
  ∀ (a : Agent) (r : Resource) (w : World),
    canAccess a r w → w.permissions r a ≥ AccessLevel.read
```
- **Rationale**: RBAC enforcement
- **Observability**: full
- **Verifier instruction**: Check permission table before any resource access

### write_requires_write
```lean
axiom write_requires_write :
  ∀ (a : Agent) (r : Resource) (w : World),
    modifies a r w → w.permissions r a ≥ AccessLevel.write
```
- **Rationale**: Read permission is insufficient for mutation
- **Observability**: full

---

## Reversibility

### reversibility
```lean
axiom reversibility :
  ∀ (a : Agent) (action : Action) (w : World),
    action.severity ≥ Severity.high →
    ∃ rollback : Action, execute a rollback (execute a action w) = some w
```
- **Rationale**: High-impact operations must be recoverable
- **Observability**: partial (existence: static; correctness: runtime test)
- **Verifier instruction**: For high-severity actions, verify rollback plan exists before execution

### idempotency
```lean
axiom idempotency :
  ∀ (a : Agent) (action : Action) (w : World),
    action.isRetryable →
    execute a action (execute a action w) = execute a action w
```
- **Rationale**: Retried actions must not cause double-effects
- **Observability**: partial

---

## Rate Limiting

### rate_limit
```lean
axiom rate_limit :
  ∀ (a : Agent) (w : World) (window : Nat),
    countActionsInWindow a w window ≤ a.rateLimit window
```
- **Rationale**: Prevent runaway agent loops
- **Observability**: full
- **Verifier instruction**: Maintain sliding window counter per agent

---

## Data Isolation

### no_cross_tenant
```lean
axiom no_cross_tenant :
  ∀ (a : Agent) (r : Resource) (w : World),
    canAccess a r w → r.tenant = a.tenant
```
- **Rationale**: Multi-tenant data isolation
- **Observability**: full

### no_pii_leak
```lean
axiom no_pii_leak :
  ∀ (a : Agent) (output : StructuredOutput) (w : World),
    produces a output w →
    ¬containsPII output ∨ output.destination.isInternal
```
- **Rationale**: PII must not leave the internal boundary
- **Observability**: partial (PII detection is heuristic)

---

## Audit Trail

### audit_append_only
```lean
axiom audit_append_only :
  ∀ (w w' : World),
    validTransition w w' →
    w.auditLog.isPrefixOf w'.auditLog
```
- **Rationale**: Audit logs must be tamper-evident
- **Observability**: full

### audit_complete
```lean
axiom audit_complete :
  ∀ (a : Agent) (action : Action) (w w' : World),
    execute a action w = some w' →
    ∃ entry ∈ w'.auditLog, entry.agent = a.id ∧ entry.action = action
```
- **Rationale**: Every action must appear in the audit log
- **Observability**: full

---

## Workflow Composition

### step_chaining
```lean
axiom step_chaining :
  ∀ (steps : List Step) (i : Fin (steps.length - 1)) (w : World),
    steps[i].postcondition w → steps[i+1].precondition w
```
- **Rationale**: Each step's output must satisfy the next step's input requirements
- **Observability**: full (check postcondition after each step)

### termination
```lean
axiom termination :
  ∀ (wf : Workflow) (w : World),
    wf.execute w → wf.stepCount ≤ wf.maxSteps
```
- **Rationale**: Workflows must terminate within bounded steps
- **Observability**: full
