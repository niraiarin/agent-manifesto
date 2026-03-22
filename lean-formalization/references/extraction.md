# Extraction: Worker Constraints and Verifier Rules

How to automatically extract machine-readable specifications from a Lean Manifest for consumption by Worker AI and Verifier AI.

## Overview

The Manifest `.lean` files are the single source of truth. Two extraction executables produce different views:

- `extract-worker` → JSON structural constraints (what the Worker AI must conform to)
- `extract-verifier` → Structured rules (what the Verifier AI checks against)

Both use Lean's `Environment` API to walk the declarations in the Manifest modules.

## Worker Constraint Extraction

### Purpose

The Worker AI needs to know:
- What output types are valid (the `StructuredOutput` type)
- What preconditions must hold before each action type
- What scope restrictions apply

It does NOT need:
- Proof details
- Natural language rationale
- Meta-theorems

### Approach: Walk the Environment

```lean
-- Extract/WorkerConstraints.lean

import Lean
import Manifest.Ontology
import Manifest.Axioms

open Lean in
def extractConstraints (env : Environment) : IO Unit := do
  let mut constraints : List Json := []
  -- Find all axioms in Manifest.Axioms
  for (name, info) in env.constants.toList do
    if name.getPrefix == `Manifest.Axioms then
      if let .axiomInfo val := info then
        let constraint := Json.mkObj [
          ("name", Json.str name.toString),
          ("type", Json.str (toString val.type)),
          -- Extract scope from AxiomMeta attribute if present
          ("meta", extractAxiomMeta env name)
        ]
        constraints := constraint :: constraints
  IO.FS.writeFile "worker-constraints.json"
    (Json.arr constraints.toArray |>.pretty)

def main : IO Unit := do
  let env ← importModules [
    { module := `Manifest.Ontology },
    { module := `Manifest.Axioms }
  ] {}
  extractConstraints env
```

### Output format

```json
{
  "manifest_version": "v2.0",
  "constraints": [
    {
      "name": "Manifest.Axioms.no_escalation",
      "type": "∀ (a : Agent) (action : Action) (w w' : World), execute a action w = some w' → a.scope.contains action.target",
      "meta": {
        "observability": "full",
        "scope": ["all_agent_operations"],
        "enforced_at": "pre_execution"
      }
    },
    {
      "name": "Manifest.Axioms.access_control",
      "type": "...",
      "meta": { ... }
    }
  ],
  "output_schema": {
    "type": "StructuredOutput",
    "variants": ["toolCall", "response", "delegation"]
  }
}
```

## Verifier Rule Extraction

### Purpose

The Verifier AI needs:
- The formal axiom statement (to understand what to check)
- The natural language intent (from docstrings and prose)
- Verification instructions (from custom annotations)
- Observability level (to know what can be checked at runtime)

### Approach: Extract docstrings + axiom types

```lean
-- Extract/VerifierRules.lean

import Lean
import Manifest.Ontology
import Manifest.Axioms

open Lean in
def extractVerifierRules (env : Environment) : IO Unit := do
  let mut rules : List String := []
  for (name, info) in env.constants.toList do
    if name.getPrefix == `Manifest.Axioms then
      if let .axiomInfo val := info then
        let docstring ← findDocString? env name
        let meta := extractAxiomMeta env name
        let rule := s!"AXIOM: {name} ({meta.version}, {meta.status})\n" ++
          s!"FORMAL: {val.type}\n" ++
          s!"INTENT: {docstring.getD \"(no docstring)\"}\n" ++
          s!"OBSERVABILITY: {meta.observability}\n" ++
          s!"RELATED: {meta.relatedAxioms}\n"
        rules := rule :: rules
  IO.FS.writeFile "verifier-rules.txt" (String.intercalate "\n---\n" rules)
```

### Output format

```
AXIOM: Manifest.Axioms.no_escalation (v2.0, approved)
FORMAL: ∀ (a : Agent) (action : Action) (w w' : World), execute a action w = some w' → a.scope.contains action.target
INTENT: Agents can only act within their scope
VERIFY: Check action.target ∈ agent.scope before each step
OBSERVABILITY: full
RELATED: access_control
---
AXIOM: Manifest.Axioms.reversibility (v2.0, review)
FORMAL: ∀ (a : Agent) (action : Action) (w : World), action.severity ≥ Severity.high → ∃ rollback : Action, ...
INTENT: High-severity actions must be reversible
VERIFY: Verify rollback plan exists before high-severity execution
OBSERVABILITY: partial
RELATED: (none)
```

## Custom Attributes for Metadata

To attach `AxiomMeta` to axioms in a way that the extraction can read, use Lean's custom attribute system:

```lean
-- Manifest/Attributes.lean

import Lean

initialize manifestAxiomExt : SimplePersistentEnvExtension
    (Name × AxiomMeta) (List (Name × AxiomMeta)) ←
  registerSimplePersistentEnvExtension {
    addImportedFn := fun arrays => arrays.foldl (· ++ ·.toList) []
    addEntryFn := fun list entry => entry :: list
  }

syntax (name := manifestAxiom) "manifest_axiom"
  "version" ":=" str
  "observability" ":=" ident
  "scope" ":=" "[" str,* "]"
  : attr

-- Usage:
@[manifest_axiom version := "v2.0" observability := full scope := ["all"]]
axiom no_escalation : ...
```

This makes metadata machine-readable at the Environment level, enabling reliable extraction by both `extract-worker` and `extract-verifier`.

## Sorry Extraction

To generate a sorry report (for CI dashboards and Verso sorryReport blocks):

```lean
def extractSorries (env : Environment) : List (Name × Nat) :=
  env.constants.toList.filterMap fun (name, info) =>
    if info.value?.any hasSorry then
      some (name, countSorries info)
    else
      none
```

This list maps directly to the design completeness dashboard:
- `sorry` count = remaining design work
- Decreasing sorry count over PRs = measurable design progress
