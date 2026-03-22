# Ontology Patterns

Common patterns for defining the World, Agent, and Action types in a Manifest.

## Pattern 1: Minimal Agent Workflow

For simple tool-calling agents with fixed scope.

```lean
inductive Capability where
  | readFile | writeFile | httpGet | httpPost | execCmd
  deriving BEq, Repr

structure Scope where
  allowedPaths : List String
  allowedDomains : List String
  allowedCommands : List String

structure Agent where
  id : String
  capabilities : List Capability
  scope : Scope

structure Action where
  capability : Capability
  target : String
  severity : Severity
  payload : String
```

## Pattern 2: Multi-Agent Delegation

For workflows where one agent delegates sub-tasks to others.

```lean
inductive AgentRole where
  | orchestrator | worker | verifier | auditor

structure Agent where
  id : AgentId
  role : AgentRole
  capabilities : List Capability
  scope : Scope
  canDelegateTo : List AgentId  -- delegation graph

-- Axiom: delegation does not escalate privileges
axiom delegation_safe :
  ∀ (parent child : Agent) (task : Task),
    parent.canDelegateTo.contains child.id →
    task.requiredScope ⊆ parent.scope
```

## Pattern 3: Stateful World with Audit Trail

For workflows that must maintain a verifiable history.

```lean
structure AuditEntry where
  timestamp : Nat
  agent : AgentId
  action : Action
  preState : WorldHash
  postState : WorldHash

structure World where
  resources : Map ResourceId Resource
  permissions : Map (AgentId × ResourceId) AccessLevel
  auditLog : List AuditEntry
  epoch : Nat

-- Axiom: audit log is append-only
axiom audit_append_only :
  ∀ (w w' : World),
    validTransition w w' →
    w.auditLog.isPrefixOf w'.auditLog
```

## Pattern 4: Domain-Specific Ontology (Financial)

```lean
inductive AssetClass where | equity | bond | derivative | cash
inductive TradeAction where | buy | sell | hold | rebalance

structure Portfolio where
  holdings : Map AssetClass Float
  riskLimit : Float

-- Axiom: no trade may exceed risk limits
axiom risk_bounded :
  ∀ (a : Agent) (trade : TradeAction) (p p' : Portfolio),
    executeTrade a trade p = some p' →
    p'.totalRisk ≤ p.riskLimit
```

## Pattern 5: Domain-Specific Ontology (CI/CD Pipeline)

```lean
inductive Environment where | dev | staging | production
inductive DeployAction where | build | test | deploy | rollback

-- Axiom: production deploy requires staging success
axiom staging_gate :
  ∀ (a : Agent) (action : DeployAction) (w : World),
    action = .deploy →
    w.targetEnv = .production →
    w.stagingStatus = .passed
```
