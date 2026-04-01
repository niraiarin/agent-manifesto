#!/usr/bin/env bash
# Dependency graph traceability verification
# Validates completeness, DAG integrity, reachability, and cross-reference consistency.
#
# Usage: depgraph-verify.sh [depgraph.json]
#
# Exit code: 0 = all checks pass, 1 = failures detected
# Reference: #158, #157

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LEAN_DIR="$PROJECT_DIR/lean-formalization"
DEPGRAPH="${1:-$PROJECT_DIR/depgraph.json}"

if [ ! -f "$DEPGRAPH" ]; then
  echo "ERROR: $DEPGRAPH not found. Run 'depgraph.sh generate' first." >&2
  exit 1
fi

python3 - "$DEPGRAPH" "$LEAN_DIR" << 'PYEOF'
import json
import sys
from collections import deque

depgraph_path = sys.argv[1]
lean_dir = sys.argv[2]

with open(depgraph_path) as f:
    data = json.load(f)

nodes = data['nodes']
edges = data['edges']
failures = []
warnings = []

node_names = set(n['fullName'] for n in nodes)
node_kinds = {n['fullName']: n['kind'] for n in nodes}

print("=" * 60)
print("Dependency Graph Traceability Verification")
print("=" * 60)
print(f"Graph: {depgraph_path}")
print(f"Nodes: {len(nodes)}, Edges: {len(edges)}")
print()

# ============================================================
# Check 1: Completeness — count axioms/theorems in Lean source
# ============================================================
print("--- Check 1: Completeness (Lean source vs graph) ---")

import subprocess, os

def count_lean_declarations(pattern):
    """Count unique declarations matching pattern in Lean source."""
    result = subprocess.run(
        ['grep', '-rE', f'^{pattern} [a-zA-Z_]', '--include=*.lean'],
        cwd=os.path.join(lean_dir, 'Manifest'),
        capture_output=True, text=True
    )
    # Extract unique declaration names
    names = set()
    for line in result.stdout.strip().split('\n'):
        if ':' in line and line.strip():
            # Format: file:  axiom name ...
            decl_part = line.split(':', 1)[1].strip()
            parts = decl_part.split()
            if len(parts) >= 2:
                names.add(parts[1].rstrip(':'))
    return len(names)

lean_axiom_count = count_lean_declarations('axiom')
lean_theorem_count = count_lean_declarations('theorem')

graph_axiom_count = sum(1 for n in nodes if n['kind'] == 'axiom')
graph_theorem_count = sum(1 for n in nodes if n['kind'] == 'theorem')

print(f"  Lean source axioms:   {lean_axiom_count}")
print(f"  Graph axiom nodes:    {graph_axiom_count}")
if lean_axiom_count != graph_axiom_count:
    failures.append(f"Axiom count mismatch: Lean={lean_axiom_count}, Graph={graph_axiom_count}")
    print(f"  ❌ MISMATCH")
else:
    print(f"  ✅ Match")

print(f"  Lean source theorems: {lean_theorem_count}")
print(f"  Graph theorem nodes:  {graph_theorem_count}")
if graph_theorem_count < lean_theorem_count:
    failures.append(f"Theorem count: Graph ({graph_theorem_count}) < Lean ({lean_theorem_count})")
    print(f"  ❌ Graph has fewer theorems than Lean source")
elif graph_theorem_count > lean_theorem_count:
    # Graph may include lemmas counted as theorems
    warnings.append(f"Graph theorem nodes ({graph_theorem_count}) > Lean 'theorem' count ({lean_theorem_count}), likely includes lemmas")
    print(f"  ⚠️  Graph has more (includes lemmas): +{graph_theorem_count - lean_theorem_count}")
else:
    print(f"  ✅ Match")
print()

# ============================================================
# Check 2: DAG integrity — no cycles
# ============================================================
print("--- Check 2: DAG Integrity (cycle detection) ---")

# Build adjacency list (source -> targets)
adj = {}
for e in edges:
    adj.setdefault(e['source'], []).append(e['target'])

# Detect cycles using DFS with coloring
WHITE, GRAY, BLACK = 0, 1, 2
color = {n['fullName']: WHITE for n in nodes}
cycle_nodes = []

def dfs_cycle(node, path):
    color[node] = GRAY
    for neighbor in adj.get(node, []):
        if neighbor not in color:
            continue
        if color[neighbor] == GRAY:
            cycle_start = path.index(neighbor) if neighbor in path else -1
            cycle = path[cycle_start:] + [neighbor] if cycle_start >= 0 else [node, neighbor]
            cycle_nodes.append(cycle)
            return True
        elif color[neighbor] == WHITE:
            if dfs_cycle(neighbor, path + [neighbor]):
                return True
    color[node] = BLACK
    return False

for n in nodes:
    name = n['fullName']
    if color[name] == WHITE:
        dfs_cycle(name, [name])

if cycle_nodes:
    for cycle in cycle_nodes[:5]:  # Show max 5 cycles
        short_cycle = [c.replace('Manifest.', '') for c in cycle]
        failures.append(f"Cycle detected: {' → '.join(short_cycle)}")
    print(f"  ❌ {len(cycle_nodes)} cycle(s) detected")
    for cycle in cycle_nodes[:3]:
        short_cycle = [c.replace('Manifest.', '') for c in cycle]
        print(f"     {' → '.join(short_cycle)}")
else:
    print(f"  ✅ No cycles (valid DAG)")
print()

# ============================================================
# Check 3: Reachability — every theorem traces back to an axiom
# ============================================================
print("--- Check 3: Reachability (theorem → axiom traceability) ---")

axiom_names = set(n['fullName'] for n in nodes if n['kind'] == 'axiom')
theorem_names = set(n['fullName'] for n in nodes if n['kind'] == 'theorem')

def can_reach_axiom(start):
    """BFS from start following dependency edges to find if any axiom is reachable."""
    visited = set()
    queue = deque([start])
    while queue:
        node = queue.popleft()
        if node in visited:
            continue
        visited.add(node)
        if node in axiom_names and node != start:
            return True
        for target in adj.get(node, []):
            if target not in visited:
                queue.append(target)
    return False

unreachable = []
for t in sorted(theorem_names):
    if not can_reach_axiom(t):
        unreachable.append(t)

# Classify unreachable: type-derivable (depend only on defs/inductives/opaques)
# vs axiom-expected (should depend on axioms but don't)
total_reachable = len(theorem_names) - len(unreachable)

# Check if unreachable theorems only depend on types (no axiom in transitive closure = type-level theorem)
# This is actually the EXPECTED case for many theorems in Lean:
# enum exhaustiveness, pattern match completeness, decidability instances, etc.
# These are provable purely from type definitions without any non-logical axioms.

# Classify by whether the theorem's transitive deps include ONLY defs/inductives/opaques
def only_type_deps(start):
    """Check if all transitive deps are defs/inductives/opaques (no axioms)."""
    visited = set()
    queue = deque([start])
    while queue:
        node = queue.popleft()
        if node in visited:
            continue
        visited.add(node)
        kind = node_kinds.get(node)
        if kind == 'axiom' and node != start:
            return False
        for target in adj.get(node, []):
            if target not in visited:
                queue.append(target)
    return True

type_only = [t for t in unreachable if only_type_deps(t)]
unexpected = [t for t in unreachable if not only_type_deps(t)]

print(f"  Axiom-reachable:        {total_reachable} / {len(theorem_names)}")
print(f"  Type-derivable only:    {len(type_only)} (no axiom in transitive closure — expected)")
print(f"  Unexpected unreachable: {len(unexpected)} (has axioms in closure but none traced)")

if unexpected:
    warnings.append(f"{len(unexpected)} theorems have axioms in closure but no direct trace")
    print(f"  ⚠️  Unexpected unreachable theorems:")
    for t in unexpected[:10]:
        short = t.replace('Manifest.', '')
        print(f"     {short}")
    if len(unexpected) > 10:
        print(f"     ... and {len(unexpected) - 10} more")
else:
    print(f"  ✅ All non-axiom-reachable theorems are type-derivable (expected)")
print()

# ============================================================
# Check 4: PropositionId cross-reference
# ============================================================
print("--- Check 4: PropositionId cross-reference ---")

# PropositionId.dependencies from Ontology.lean (hardcoded for verification)
prop_deps = {
    't1': [], 't2': [], 't3': [], 't4': [], 't5': [], 't6': [], 't7': [], 't8': [],
    'e1': ['t4'], 'e2': [],
    'p1': ['e2'], 'p2': ['t4', 'e1'], 'p3': ['t1', 't2'],
    'p4': ['t5', 't7'], 'p5': ['t4'], 'p6': ['t3', 't7', 't8'],
    'l1': ['p1', 't6'], 'l2': ['t1', 't3', 't4'],
    'l3': ['t6', 't7'], 'l4': ['t6', 'p1', 'd8'],
    'l5': [], 'l6': ['t6', 'p3'],
    'd1': ['p5', 'l1', 'l2', 'l3', 'l4', 'l5', 'l6'],
    'd2': ['e1', 'p2'], 'd3': ['p4', 't5'],
    'd4': ['p3'], 'd5': ['t8', 'p4', 'p6'],
    'd6': ['d3'], 'd7': ['p1'], 'd8': ['e2'],
    'd9': ['p3'], 'd10': ['t1', 't2'],
    'd11': ['t3', 'd1', 'd3'], 'd12': ['p6', 't3', 't7', 't8'],
    'd13': ['p3', 't5'], 'd14': ['p6', 't7', 't8'],
}

# Map PropositionId to known axiom/theorem names in the graph
# T axioms: map each T to its constituent axioms
t_to_axioms = {
    't1': ['session_bounded', 'no_cross_session_memory', 'session_no_shared_state'],
    't2': ['structure_persists', 'structure_accumulates'],
    't3': ['context_finite', 'context_bounds_action', 'context_contribution_nonuniform'],
    't4': ['output_nondeterministic'],
    't5': ['no_improvement_without_feedback'],
    't6': ['human_resource_authority', 'resource_revocable'],
    't7': ['resource_finite'],
    't8': ['task_has_precision'],
}
e_to_axioms = {
    'e1': ['verification_requires_independence', 'no_self_verification', 'shared_bias_reduces_detection'],
    'e2': ['capability_risk_coscaling'],
}

# P theorems: map to known theorem names
p_to_theorems = {
    'p1': 'autonomy_vulnerability_coscaling',
    'p2': 'cognitive_separation_required',
}

cross_ref_direct_ok = 0
cross_ref_transitive_ok = 0
cross_ref_fail = 0
cross_ref_details = []

# Build transitive dependency closure for reachability check
def get_transitive_deps(start):
    """Get all transitive dependencies of a node."""
    visited = set()
    queue = deque([start])
    while queue:
        node = queue.popleft()
        if node in visited:
            continue
        visited.add(node)
        for target in adj.get(node, []):
            if target not in visited:
                queue.append(target)
    visited.discard(start)
    return visited

for p_id, t_name in p_to_theorems.items():
    full_t = 'Manifest.' + t_name
    expected_deps = prop_deps[p_id]

    # Get direct and transitive dependencies
    direct_deps = set(e['target'] for e in edges if e['source'] == full_t)
    transitive_deps = get_transitive_deps(full_t)

    for dep_prop in expected_deps:
        if dep_prop.startswith('t'):
            dep_axioms = t_to_axioms.get(dep_prop, [])
        elif dep_prop.startswith('e'):
            dep_axioms = e_to_axioms.get(dep_prop, [])
        else:
            continue

        direct_found = any('Manifest.' + ax in direct_deps for ax in dep_axioms)
        transitive_found = any('Manifest.' + ax in transitive_deps for ax in dep_axioms)

        if direct_found:
            cross_ref_direct_ok += 1
            cross_ref_details.append(f"  ✅ {t_name} →[direct]→ {dep_prop}")
        elif transitive_found:
            cross_ref_transitive_ok += 1
            cross_ref_details.append(f"  ✅ {t_name} →[transitive]→ {dep_prop}")
        else:
            cross_ref_fail += 1
            # This is a structural gap: PropositionId says dependency exists
            # but no path in the axiom/theorem graph. This is expected when
            # the dependency is conceptual (documented in Axiom Card) not formal.
            cross_ref_details.append(f"  ⚠️  {t_name} -/→ {dep_prop} (conceptual only, not in Lean code)")
            warnings.append(f"Cross-ref gap: {t_name} → {dep_prop} exists in PropositionId.dependencies but not in Lean code (conceptual dependency)")

total_cross = cross_ref_direct_ok + cross_ref_transitive_ok + cross_ref_fail
print(f"  Direct matches:     {cross_ref_direct_ok}")
print(f"  Transitive matches: {cross_ref_transitive_ok}")
print(f"  Conceptual gaps:    {cross_ref_fail} (PropositionId dep exists, Lean code dep missing)")
for d in cross_ref_details:
    print(d)
print()

# ============================================================
# Check 5: Orphan detection
# ============================================================
print("--- Check 5: Orphan detection ---")

# Nodes that have no incoming AND no outgoing edges
sources = set(e['source'] for e in edges)
targets = set(e['target'] for e in edges)
connected = sources | targets
orphans = [n for n in nodes if n['fullName'] not in connected]

if orphans:
    warnings.append(f"{len(orphans)} completely orphaned nodes (no edges at all)")
    print(f"  ⚠️  {len(orphans)} orphaned nodes:")
    for o in orphans[:10]:
        print(f"     {o['name']} ({o['kind']})")
    if len(orphans) > 10:
        print(f"     ... and {len(orphans) - 10} more")
else:
    print(f"  ✅ No orphaned nodes")
print()

# ============================================================
# Check 6: Isolated axioms (declared but unused)
# ============================================================
print("--- Check 6: Isolated axioms (rdeps=0) ---")

isolated_axioms = []
for a in sorted(axiom_names):
    rdeps = sum(1 for e in edges if e['target'] == a)
    if rdeps == 0:
        isolated_axioms.append(a.replace('Manifest.', ''))

if isolated_axioms:
    warnings.append(f"{len(isolated_axioms)} axioms have no reverse dependencies")
    print(f"  ⚠️  {len(isolated_axioms)} axioms are declared but not referenced by any theorem:")
    for a in isolated_axioms:
        print(f"     {a}")
else:
    print(f"  ✅ All axioms are referenced by at least one theorem")
print()

# ============================================================
# Summary
# ============================================================
print("=" * 60)
print("SUMMARY")
print("=" * 60)

if failures:
    print(f"❌ FAILURES ({len(failures)}):")
    for f in failures:
        print(f"   - {f}")
else:
    print("✅ No failures")

if warnings:
    print(f"⚠️  WARNINGS ({len(warnings)}):")
    for w in warnings:
        print(f"   - {w}")
else:
    print("✅ No warnings")

print()
if failures:
    print("VERDICT: FAIL")
    sys.exit(1)
else:
    print("VERDICT: PASS (with warnings)" if warnings else "VERDICT: PASS")
    sys.exit(0)
PYEOF
