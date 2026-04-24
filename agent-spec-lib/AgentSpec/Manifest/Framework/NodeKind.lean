import AgentSpec.Manifest.Ontology

/-!
# Axiomatic DAG Framework - Node Kind Ontology

Issue #297 (G5 of #296): 4 classification of DAG nodes.

Maps to existing Lean types:
- PropositionCategory (Ontology.lean): 6-way classification by epistemological strength
- EpistemicSource (EpistemicLayer.lean): human vs LLM origin

This file defines `NodeKind`, a 4-way classification by mutability and origin,
complementary to (not replacing) the existing types.

## Ontology

| NodeKind | Mutability | Origin | CompatibilityClass on change |
|----------|-----------|--------|------------------------------|
| axiom    | immutable (by convention) | foundational | breaking |
| constraint | mutable (environment change) | external | compatible or breaking |
| assumption | mutable (refutation) | human or LLM | compatible |
| derived  | computed (from above 3) | deduction | conservative or compatible |

## Mapping to PropositionCategory

| PropositionCategory | NodeKind | Rationale |
|--------------------|----------|-----------|
| constraint (T)     | axiom    | T1-T8 are foundational, change is breaking |
| empiricalPostulate (E) | constraint | E1-E2 are empirically grounded, refutable |
| principle (P)      | constraint | P1-P6 are design constraints |
| boundary (L)       | derived  | L1-L6 are derived from T+E+P |
| designTheorem (D)  | derived  | D1-D18 are derived from T+E+P+L |
| hypothesis (H)     | assumption | Explicitly tracked uncertain premises |
-/

namespace AgentSpec.Manifest.Framework

open Manifest

/-- 4-way classification of DAG nodes by mutability and origin.
    Complementary to PropositionCategory (strength-based) and
    EpistemicSource (origin-based). -/
inductive NodeKind where
  /-- Foundational premise. Change is always breaking.
      Corresponds to T1-T8 in the manifesto. -/
  | axiom
  /-- External condition. Mutable by environment change.
      Corresponds to E1-E2, P1-P6 (empirically grounded constraints). -/
  | constraint
  /-- Uncertain premise with explicit tracking.
      Human-originated (C-type) or LLM-inferred (H-type).
      Refutable by evidence. -/
  | assumption
  /-- Logically derived from axioms, constraints, and assumptions.
      Corresponds to L1-L6, D1-D18, and all theorems. -/
  | derived
  deriving BEq, Repr, DecidableEq

/-- NodeKind has a natural ordering by mutability:
    axiom (least mutable) < constraint < assumption < derived (most dependent). -/
def NodeKind.mutabilityOrd : NodeKind → Nat
  | .axiom      => 0  -- immutable by convention
  | .constraint => 1  -- mutable by environment
  | .assumption => 2  -- mutable by refutation
  | .derived    => 3  -- recomputed from dependencies

/-- The CompatibilityClass required when modifying a node of this kind. -/
def NodeKind.minCompatibility : NodeKind → CompatibilityClass
  | .axiom      => .breakingChange
  | .constraint => .compatibleChange
  | .assumption => .compatibleChange
  | .derived    => .conservativeExtension

/-- Axiom modification is always breaking change. -/
theorem axiom_change_is_breaking :
  NodeKind.minCompatibility .axiom = .breakingChange := by rfl

/-- Derived node addition is conservative extension. -/
theorem derived_addition_is_conservative :
  NodeKind.minCompatibility .derived = .conservativeExtension := by rfl

/-- Mutability ordering: axiom is least mutable. -/
theorem axiom_least_mutable :
  ∀ k : NodeKind, NodeKind.mutabilityOrd .axiom ≤ NodeKind.mutabilityOrd k := by
  intro k; cases k <;> simp [NodeKind.mutabilityOrd]

/-- Map PropositionCategory to NodeKind. -/
def toNodeKind : PropositionCategory → NodeKind
  | .constraint         => .axiom       -- T: foundational
  | .empiricalPostulate => .constraint  -- E: empirically grounded
  | .principle          => .constraint  -- P: design constraints
  | .boundary           => .derived     -- L: derived from T+E+P
  | .designTheorem      => .derived     -- D: derived from all above
  | .hypothesis         => .assumption  -- H: uncertain premises

/-- The highest-strength category (constraint/T) maps to the least mutable kind (axiom). -/
theorem highest_strength_least_mutable :
  (toNodeKind .constraint).mutabilityOrd = 0 := by rfl

/-- The lowest-strength category (hypothesis/H) maps to assumption kind. -/
theorem lowest_strength_is_assumption :
  (toNodeKind .hypothesis).mutabilityOrd = 2 := by rfl

/-- Derived categories (boundary/L, designTheorem/D) map to the most dependent kind. -/
theorem derived_categories_most_dependent :
  (toNodeKind .boundary).mutabilityOrd = 3 ∧
  (toNodeKind .designTheorem).mutabilityOrd = 3 := by
  exact ⟨rfl, rfl⟩

-- ============================================================
-- D4/D5/D6 re-classification under NodeKind ontology
-- (Issue #297 experiment 3)
-- ============================================================

/-!
## D4-D5-D6 as instances of the partial order

D4, D5, D6 are design theorems (PropositionCategory.designTheorem) that each
define a specific ordering relation. Under the NodeKind ontology, they are all
`derived` nodes — logically derived from axioms and constraints.

The key insight: D4/D5/D6 are **individual instances** of the same abstract
property — a partial order on heterogeneous entities. The half-order axiom (#290)
would unify them under a single principle.

| Principle | Domain | Ordering | NodeKind of ordered entities |
|-----------|--------|----------|----------------------------|
| D4 | Development phases | safety → verification → observability → governance → dynamic | derived (phases are derived from T+E+P) |
| D5 | Artifact layers | specification → test → implementation | derived (artifacts are derived) |
| D6 | Constraint layers | boundary → mitigation → variable | mixed (boundary=derived, variable=derived) |
-/

/-- D4/D5/D6 are all design theorems, hence `derived` under NodeKind. -/
theorem d4_d5_d6_are_derived :
  toNodeKind .designTheorem = .derived := by rfl

/-- D4/D5/D6 being derived means their modification is conservative extension.
    Adding new ordering relations does not break existing ones. -/
theorem ordering_extension_is_conservative :
  NodeKind.minCompatibility (toNodeKind .designTheorem) = .conservativeExtension := by rfl

/-- The entities ordered by D4/D5/D6 span multiple NodeKinds.
    D4 orders phases (derived from T+E+P constraints).
    D5 orders spec→test→impl (all derived artifacts).
    D6 orders boundary→mitigation→variable (all derived).
    A unifying half-order axiom (#290) would be a new axiom-level node,
    requiring breaking change classification. -/
theorem unifying_axiom_is_breaking :
  NodeKind.minCompatibility .axiom = .breakingChange := by rfl

end AgentSpec.Manifest.Framework
