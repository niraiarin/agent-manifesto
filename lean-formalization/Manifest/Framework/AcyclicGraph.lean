import Manifest.Framework.NodeKind

/-!
# Axiomatic DAG Framework — Acyclic Graph

Issue #298 (G1 of #296): Unified acyclic graph type that abstracts over
the three existing dependency implementations:

1. PropositionId.dependencies (proposition-level, Ontology.lean)
2. Structure.dependencies (structure-level, Ontology.lean)
3. depgraph.json (Lean definition-level, generated)

## Design

The graph is parameterized by a node type `α` with decidable equality.
Acyclicity is enforced by requiring a topological ordering function
(each node has a `level` such that dependencies have strictly lower level).

This is equivalent to the well-founded ordering approach but more
computationally tractable for decision procedures.
-/

namespace Manifest.Framework

open Manifest

-- ============================================================
-- Core Graph Types
-- ============================================================

/-- A node in the DAG with its kind, level, and direct dependencies. -/
structure Node (α : Type) where
  id : α
  kind : NodeKind
  level : Nat          -- topological level (0 = root, higher = more derived)
  deps : List α        -- direct dependencies (must have lower level)
  deriving Repr

/-- An acyclic graph: a list of nodes with a well-formedness invariant. -/
structure AcyclicGraph (α : Type) [BEq α] where
  nodes : List (Node α)
  /-- All dependency references resolve to nodes in the graph. -/
  deps_resolve : ∀ n, n ∈ nodes → ∀ d, d ∈ n.deps →
    ∃ m, m ∈ nodes ∧ (m.id == d) = true
  /-- Dependencies have strictly lower level (enforces acyclicity). -/
  level_decreasing : ∀ n, n ∈ nodes → ∀ d, d ∈ n.deps →
    ∀ m, m ∈ nodes → (m.id == d) = true → m.level < n.level

-- ============================================================
-- Operations
-- ============================================================

/-- Find a node by id. -/
def AcyclicGraph.findNode [BEq α] (g : AcyclicGraph α) (id : α) : Option (Node α) :=
  g.nodes.find? (fun n => n.id == id)

/-- Get all root nodes (level = 0, no dependencies). -/
def AcyclicGraph.roots [BEq α] (g : AcyclicGraph α) : List (Node α) :=
  g.nodes.filter (fun n => n.deps.isEmpty)

/-- Get direct dependents of a node (nodes that list this id in their deps). -/
def AcyclicGraph.directDependents [BEq α] (g : AcyclicGraph α) (id : α) : List (Node α) :=
  g.nodes.filter (fun n => n.deps.any (· == id))

-- ============================================================
-- Invalidation (D13 impact propagation)
-- ============================================================

/-- Compute the set of nodes affected by invalidating a given node.
    Uses BFS over the reverse edges (dependents).
    Fuel = nodes.length + 1 to guarantee at least one iteration
    (fixes empty graph case where fuel=0 skipped processing). -/
def AcyclicGraph.affected [BEq α] (g : AcyclicGraph α) (id : α) : List α :=
  let rec go (fuel : Nat) (queue : List α) (visited : List α) : List α :=
    match fuel, queue with
    | 0, _ => visited
    | _, [] => visited
    | fuel + 1, q :: qs =>
      if visited.any (· == q) then go fuel qs visited
      else
        let dependents := (g.directDependents q).map (·.id)
        go fuel (qs ++ dependents) (visited ++ [q])
  go (g.nodes.length + 1) [id] []

-- ============================================================
-- Dangling Dependency Detection (Issue #299)
-- ============================================================

/-- Check if any node has a dependency that doesn't resolve to a node in the graph.
    This is the complement of deps_resolve — a computational check. -/
def AcyclicGraph.hasDanglingDeps [BEq α] (g : AcyclicGraph α) : Bool :=
  g.nodes.any fun n =>
    n.deps.any fun d =>
      !(g.nodes.any fun m => m.id == d)

-- ============================================================
-- Theorems
-- ============================================================

/-- Acyclicity: no node can depend on itself.
    Proof: level_decreasing gives n.level < n.level, contradicting irreflexivity. -/
theorem acyclic_no_self_dep [BEq α] (g : AcyclicGraph α)
    (n : Node α) (hn : n ∈ g.nodes)
    (hd : n.id ∈ n.deps) (heq : (n.id == n.id) = true) : False := by
  have h := g.level_decreasing n hn n.id hd n hn heq
  exact absurd h (Nat.lt_irrefl _)

-- ============================================================
-- Invalidation: mark affected nodes
-- ============================================================

/-- Invalidate a node and all its transitive dependents.
    Returns a list of nodes where affected ones have kind set to `assumption`
    (the most uncertain kind), signaling they need re-verification.

    Note: Returns List (Node α) rather than AcyclicGraph α because
    reconstructing the invariants (deps_resolve, level_decreasing)
    after kind mutation requires the original proofs, which are preserved
    since only `kind` changes (not `level` or `deps`). -/
def AcyclicGraph.invalidate [BEq α] [DecidableEq α]
    (g : AcyclicGraph α) (id : α) : List (Node α) :=
  let affectedIds := g.affected id
  g.nodes.map fun n =>
    if affectedIds.any (· == n.id) then { n with kind := .assumption }
    else n

/-- Invalidation preserves graph size (no nodes added or removed). -/
theorem invalidate_preserves_length [BEq α] [DecidableEq α]
    (g : AcyclicGraph α) (id : α) :
    (g.invalidate id).length = g.nodes.length := by
  simp [AcyclicGraph.invalidate, List.length_map]

-- Note: "source ∈ affected" is computationally true (fuel = nodes.length + 1 ≥ 1
-- ensures at least one BFS iteration processes the source). A formal proof requires
-- induction on the fuel-bounded go function, which is deferred to avoid sorry/axiom.
-- The property can be verified by #eval on concrete instances.

-- ============================================================
-- Multi-level integration examples
-- ============================================================

/-- Build a Node from a PropositionId (Level 1: proposition-level dependencies).
    Level is derived from category strength (inverted: higher strength = lower level). -/
def propositionNode (p : PropositionId) : Node PropositionId :=
  { id := p
    kind := toNodeKind p.category
    level := 5 - p.category.strength  -- invert: constraint(5) → level 0, hypothesis(0) → level 5
    deps := p.dependencies }

/-- Build a Node from a Structure (Level 2: structure-level dependencies).
    Demonstrates that Structure.dependencies maps to AcyclicGraph. -/
def structureNode (s : Structure) : Node StructureId :=
  { id := s.id
    kind := .derived  -- structures are derived artifacts
    level := s.kind.priority  -- use existing StructureKind priority as level
    deps := s.dependencies }

/-- The three levels of dependency tracking map to AcyclicGraph:
    1. PropositionId.dependencies → propositionNode → AcyclicGraph PropositionId
    2. Structure.dependencies → structureNode → AcyclicGraph StructureId
    3. depgraph.json → (external, same schema) → AcyclicGraph String
    All three share: Node type + deps_resolve + level_decreasing invariants. -/
theorem three_levels_share_structure :
  -- Level 1: PropositionId constraints are roots (level 0)
  (propositionNode .t1).level = 0 ∧
  -- Level 1: Design theorems are derived (level 4)
  (propositionNode .d1).level = 4 ∧
  -- Level 2: structureNode preserves kind priority
  ∀ (s : Structure), (structureNode s).level = s.kind.priority := by
  exact ⟨rfl, rfl, fun _ => rfl⟩

end Manifest.Framework
