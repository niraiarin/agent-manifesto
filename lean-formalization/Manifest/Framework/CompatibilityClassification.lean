import Manifest.Framework.DanglingDetection
import Manifest.Evolution

/-!
# Axiomatic DAG Framework — Compatibility Classification Decision Procedure

Issue #301 (G4 of #296): Decision procedure that automatically classifies
manifest diffs into CompatibilityClass.

Given a diff (list of atomic changes to a manifesto DAG), this module computes
the overall CompatibilityClass by:
1. Classifying each atomic change using NodeKind.minCompatibility
2. Taking the join (supremum) of all atomic classifications

This connects the DAG framework (G1-G3) to the existing Evolution.lean
algebraic structure on CompatibilityClass.

## Design

- `AtomicDiff`: 6 kinds of atomic changes (add/remove/modify node, promote node,
  add/remove dependency)
- `classifyAtomicDiff`: maps each atomic diff to a CompatibilityClass
- `ManifestDiff`: abbreviation for `List AtomicDiff`
- `classifyDiff`: foldl with join over atomic classifications

## Correctness Properties

- Empty diff is conservative extension (identity of join)
- Singleton diff equals the atomic classification
- Any diff containing a breaking atomic diff is breaking (top-element dominance)
- Classification is monotone (appending diffs can only increase severity)
- Consistency with NodeKind.minCompatibility for remove/modify/promote
-/

namespace Manifest.Framework

open Manifest

-- ============================================================
-- AtomicDiff: atomic changes to a manifest DAG
-- ============================================================

/-- Types of atomic changes to a manifest DAG.
    Each variant carries enough information to determine
    the CompatibilityClass of the change. -/
inductive AtomicDiff where
  /-- Adding a new node of the given kind. -/
  | addNode (kind : NodeKind)
  /-- Removing an existing node of the given kind. -/
  | removeNode (kind : NodeKind)
  /-- Modifying an existing node (content change, same kind). -/
  | modifyNode (kind : NodeKind)
  /-- Changing a node's kind (e.g., assumption -> derived).
      `src` is the original kind, `tgt` is the new kind. -/
  | promoteNode (src tgt : NodeKind)
  /-- Adding a new dependency edge. -/
  | addDependency
  /-- Removing an existing dependency edge. -/
  | removeDependency
  deriving BEq, Repr

-- ============================================================
-- Classification of individual atomic diffs
-- ============================================================

/-- Classify a single atomic diff into a CompatibilityClass.

    Rules:
    - Adding a non-axiom node is conservative (pure extension)
    - Adding an axiom is breaking (new foundational premise)
    - Removing/modifying a node uses NodeKind.minCompatibility
      (at least as severe as the node kind dictates)
    - Promoting a node: severity determined by the target kind
    - Adding a dependency edge is conservative
    - Removing a dependency edge is compatible (may change derived results) -/
def classifyAtomicDiff : AtomicDiff → CompatibilityClass
  | .addNode .axiom      => .breakingChange
  | .addNode .constraint => .conservativeExtension
  | .addNode .assumption => .conservativeExtension
  | .addNode .derived    => .conservativeExtension
  | .removeNode k        => k.minCompatibility
  | .modifyNode k        => k.minCompatibility
  | .promoteNode _ tgt   => tgt.minCompatibility
  | .addDependency       => .conservativeExtension
  | .removeDependency    => .compatibleChange

-- ============================================================
-- ManifestDiff and decision procedure
-- ============================================================

/-- A manifest diff is a list of atomic changes. -/
abbrev ManifestDiff := List AtomicDiff

/-- Classify a composite diff by taking the join of all atomic classifications.
    The join lattice ensures the most restrictive classification dominates.
    conservativeExtension is the identity element of join (lattice bottom). -/
def classifyDiff (diff : ManifestDiff) : CompatibilityClass :=
  diff.foldl (fun acc d => acc.join (classifyAtomicDiff d)) .conservativeExtension

-- ============================================================
-- Correctness: atomic classification
-- ============================================================

/-- Adding an axiom node is always breaking. -/
theorem add_axiom_is_breaking :
    classifyAtomicDiff (.addNode .axiom) = .breakingChange := by rfl

/-- Removing an axiom node is always breaking. -/
theorem remove_axiom_is_breaking :
    classifyAtomicDiff (.removeNode .axiom) = .breakingChange := by rfl

/-- Modifying an axiom node is always breaking. -/
theorem modify_axiom_is_breaking :
    classifyAtomicDiff (.modifyNode .axiom) = .breakingChange := by rfl

/-- Adding a derived node is conservative. -/
theorem add_derived_is_conservative :
    classifyAtomicDiff (.addNode .derived) = .conservativeExtension := by rfl

/-- Modifying a derived node is conservative. -/
theorem modify_derived_is_conservative :
    classifyAtomicDiff (.modifyNode .derived) = .conservativeExtension := by rfl

/-- Adding a dependency edge is conservative. -/
theorem add_dependency_is_conservative :
    classifyAtomicDiff .addDependency = .conservativeExtension := by rfl

/-- Removing a dependency edge is compatible change. -/
theorem remove_dependency_is_compatible :
    classifyAtomicDiff .removeDependency = .compatibleChange := by rfl

-- ============================================================
-- Consistency with NodeKind.minCompatibility
-- ============================================================

/-- classifyAtomicDiff is consistent with NodeKind.minCompatibility for removal. -/
theorem classify_remove_consistent (k : NodeKind) :
    classifyAtomicDiff (.removeNode k) = k.minCompatibility := by
  cases k <;> rfl

/-- classifyAtomicDiff is consistent with NodeKind.minCompatibility for modification. -/
theorem classify_modify_consistent (k : NodeKind) :
    classifyAtomicDiff (.modifyNode k) = k.minCompatibility := by
  cases k <;> rfl

/-- classifyAtomicDiff is consistent with NodeKind.minCompatibility for promotion. -/
theorem classify_promote_consistent (src tgt : NodeKind) :
    classifyAtomicDiff (.promoteNode src tgt) = tgt.minCompatibility := by
  cases tgt <;> rfl

-- ============================================================
-- Correctness: composite classification
-- ============================================================

/-- Empty diff is classified as conservativeExtension (identity element). -/
theorem empty_diff_is_conservative :
    classifyDiff ([] : ManifestDiff) = .conservativeExtension := by rfl

/-- Singleton diff classification equals the atomic classification.
    conservativeExtension is the identity of join. -/
theorem singleton_diff_classification (d : AtomicDiff) :
    classifyDiff [d] = classifyAtomicDiff d := by
  simp [classifyDiff, List.foldl]
  cases d with
  | addNode k => cases k <;> rfl
  | removeNode k => cases k <;> rfl
  | modifyNode k => cases k <;> rfl
  | promoteNode s t => cases t <;> rfl
  | addDependency => rfl
  | removeDependency => rfl

-- ============================================================
-- Monotonicity: appending diffs can only increase severity
-- ============================================================

/-- Appending a single diff can only increase (or maintain) severity.
    Proof: acc ≤ acc.join c for all c, by cases on the 3x3 lattice. -/
theorem classify_snoc_ge (diff : ManifestDiff) (d : AtomicDiff) :
    classifyDiff diff ≤ classifyDiff (diff ++ [d]) := by
  simp [classifyDiff, List.foldl_append, List.foldl]
  generalize diff.foldl (fun acc d => acc.join (classifyAtomicDiff d))
    CompatibilityClass.conservativeExtension = acc
  show acc.join (acc.join (classifyAtomicDiff d)) = acc.join (classifyAtomicDiff d)
  cases acc <;> cases (classifyAtomicDiff d) <;> rfl

-- ============================================================
-- Breaking dominance
-- ============================================================

/-- Helper: foldl starting from breakingChange always yields breakingChange.
    Once the accumulator reaches the top of the lattice, it stays there. -/
private theorem foldl_from_breaking (ds : List AtomicDiff) :
    ds.foldl (fun a x => a.join (classifyAtomicDiff x))
      CompatibilityClass.breakingChange = .breakingChange := by
  induction ds with
  | nil => rfl
  | cons hd tl ih =>
    simp [List.foldl, breaking_change_dominates]
    exact ih

/-- Generalized: if d ∈ ds and classifyAtomicDiff d = breakingChange,
    then foldl from any accumulator yields breakingChange. -/
private theorem foldl_has_breaking (acc : CompatibilityClass) (ds : List AtomicDiff)
    (d : AtomicDiff) (hmem : d ∈ ds) (hbreak : classifyAtomicDiff d = .breakingChange) :
    ds.foldl (fun a x => a.join (classifyAtomicDiff x)) acc = .breakingChange := by
  induction ds generalizing acc with
  | nil => exact absurd hmem List.not_mem_nil
  | cons hd tl ih =>
    simp [List.foldl]
    cases hmem with
    | head =>
      -- In this case hd is unified with d by List.Mem.head
      rw [hbreak]
      have : acc.join CompatibilityClass.breakingChange = .breakingChange := by
        cases acc <;> rfl
      rw [this]
      exact foldl_from_breaking tl
    | tail _ htl =>
      exact ih (acc.join (classifyAtomicDiff hd)) htl

/-- If any atomic diff in the manifest diff classifies as breakingChange,
    the overall diff classification is breakingChange.
    Proof: breakingChange is the top element of the join lattice,
    so once reached in foldl, the accumulator stays at breakingChange. -/
theorem breaking_in_diff_is_breaking (diff : ManifestDiff) (d : AtomicDiff)
    (hmem : d ∈ diff) (hbreak : classifyAtomicDiff d = .breakingChange) :
    classifyDiff diff = .breakingChange :=
  foldl_has_breaking .conservativeExtension diff d hmem hbreak

-- ============================================================
-- Concrete test cases (computational verification via rfl)
-- ============================================================

/-- Test: adding two derived nodes is conservative. -/
example : classifyDiff [.addNode .derived, .addNode .derived]
    = .conservativeExtension := by rfl

/-- Test: adding a derived node and a constraint node is conservative. -/
example : classifyDiff [.addNode .derived, .addNode .constraint]
    = .conservativeExtension := by rfl

/-- Test: adding a derived node then removing a dependency is compatible. -/
example : classifyDiff [.addNode .derived, .removeDependency]
    = .compatibleChange := by rfl

/-- Test: any diff containing axiom addition is breaking. -/
example : classifyDiff [.addNode .derived, .addNode .axiom, .addDependency]
    = .breakingChange := by rfl

/-- Test: modifying an axiom makes the whole diff breaking. -/
example : classifyDiff [.addNode .derived, .modifyNode .axiom]
    = .breakingChange := by rfl

/-- Test: removing an axiom makes the whole diff breaking. -/
example : classifyDiff [.removeDependency, .removeNode .axiom]
    = .breakingChange := by rfl

/-- Test: promoting assumption to axiom is breaking. -/
example : classifyDiff [.promoteNode .assumption .axiom]
    = .breakingChange := by rfl

/-- Test: promoting constraint to derived is conservative. -/
example : classifyDiff [.promoteNode .constraint .derived]
    = .conservativeExtension := by rfl

/-- Test: mixed compatible changes stay compatible. -/
example : classifyDiff [.modifyNode .constraint, .removeDependency, .modifyNode .assumption]
    = .compatibleChange := by rfl

/-- Test: empty diff is conservative. -/
example : classifyDiff ([] : ManifestDiff) = .conservativeExtension := by rfl

/-- Issue #290 test: adding a partial-order axiom (new foundational axiom) is breaking.
    The half-order axiom proposed in #290 would be a new axiom-level node,
    requiring breakingChange classification per the decision procedure. -/
example : classifyDiff [.addNode .axiom]  -- #290: 半順序公理の追加
    = .breakingChange := by rfl

end Manifest.Framework
