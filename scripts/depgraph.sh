#!/usr/bin/env bash
# Fine-grained dependency graph query tool
# Usage:
#   depgraph.sh generate              — Generate depgraph.json from Lean
#   depgraph.sh stats                  — Show graph statistics
#   depgraph.sh deps <name>            — Show what <name> depends on (reverse trace)
#   depgraph.sh rdeps <name>           — Show what depends on <name> (forward trace)
#   depgraph.sh impact <name>          — Transitive forward trace (all affected)
#   depgraph.sh axioms                 — List all axioms
#   depgraph.sh dot [--axiom-theorem]  — Output DOT format graph
#
# Reference: #158, #157

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LEAN_DIR="$PROJECT_DIR/lean-formalization"
DEPGRAPH="$PROJECT_DIR/depgraph.json"

cmd_generate() {
  echo "Generating dependency graph..." >&2
  cd "$LEAN_DIR"
  export PATH="$HOME/.elan/bin:$PATH"
  lake exe extractdeps > "$DEPGRAPH"
  echo "Written to $DEPGRAPH" >&2
  python3 -c "
import json
with open('$DEPGRAPH') as f:
    data = json.load(f)
print(f'Nodes: {len(data[\"nodes\"])}')
print(f'Edges: {len(data[\"edges\"])}')
kinds = {}
for n in data['nodes']:
    k = n['kind']
    kinds[k] = kinds.get(k, 0) + 1
for k, v in sorted(kinds.items(), key=lambda x: -x[1]):
    print(f'  {k}: {v}')
"
}

cmd_stats() {
  python3 -c "
import json
with open('$DEPGRAPH') as f:
    data = json.load(f)
nodes = data['nodes']
edges = data['edges']
print(f'Total nodes: {len(nodes)}')
print(f'Total edges: {len(edges)}')
print()
kinds = {}
for n in nodes:
    k = n['kind']
    kinds[k] = kinds.get(k, 0) + 1
print('By kind:')
for k, v in sorted(kinds.items(), key=lambda x: -x[1]):
    print(f'  {k}: {v}')

# Find roots (no incoming edges) and leaves (no outgoing edges)
sources = set(e['source'] for e in edges)
targets = set(e['target'] for e in edges)
all_names = set(n['fullName'] for n in nodes)
roots = all_names - targets
leaves = all_names - sources
print(f'\nRoots (no dependencies): {len(roots)}')
print(f'Leaves (nothing depends on them): {len(leaves)}')

# Axioms with most dependents
axiom_names = set(n['fullName'] for n in nodes if n['kind'] == 'axiom')
axiom_dep_count = {}
for a in axiom_names:
    count = sum(1 for e in edges if e['target'] == a)
    axiom_dep_count[a] = count
print('\nMost-depended-on axioms:')
for name, count in sorted(axiom_dep_count.items(), key=lambda x: -x[1])[:10]:
    short = name.replace('Manifest.', '')
    print(f'  {short}: {count} dependents')
"
}

cmd_deps() {
  local name="$1"
  python3 -c "
import json, sys
with open('$DEPGRAPH') as f:
    data = json.load(f)

name = '$name'
# Find matching node (partial match)
matches = [n for n in data['nodes'] if name in n['fullName'] or name in n['name']]
if not matches:
    print(f'No node matching \"{name}\"', file=sys.stderr)
    sys.exit(1)
if len(matches) > 1:
    exact = [m for m in matches if m['name'] == name or m['fullName'] == 'Manifest.' + name]
    if exact:
        matches = exact
    else:
        print(f'Ambiguous: {[m[\"name\"] for m in matches[:10]]}', file=sys.stderr)
        sys.exit(1)

target = matches[0]['fullName']
deps = [(e['target'], e['edgeKind']) for e in data['edges'] if e['source'] == target]

# Look up kinds
node_kinds = {n['fullName']: n['kind'] for n in data['nodes']}
print(f'{matches[0][\"name\"]} ({node_kinds.get(target, \"?\")}) depends on:')
for dep, ek in sorted(set(deps)):
    short = dep.replace('Manifest.', '')
    kind = node_kinds.get(dep, '?')
    print(f'  [{ek}] {short} ({kind})')
print(f'\nTotal: {len(set(deps))} dependencies')
"
}

cmd_rdeps() {
  local name="$1"
  python3 -c "
import json, sys
with open('$DEPGRAPH') as f:
    data = json.load(f)

name = '$name'
matches = [n for n in data['nodes'] if name in n['fullName'] or name in n['name']]
if not matches:
    print(f'No node matching \"{name}\"', file=sys.stderr)
    sys.exit(1)
if len(matches) > 1:
    exact = [m for m in matches if m['name'] == name or m['fullName'] == 'Manifest.' + name]
    if exact:
        matches = exact
    else:
        print(f'Ambiguous: {[m[\"name\"] for m in matches[:10]]}', file=sys.stderr)
        sys.exit(1)

target = matches[0]['fullName']
rdeps = [(e['source'], e['edgeKind']) for e in data['edges'] if e['target'] == target]

node_kinds = {n['fullName']: n['kind'] for n in data['nodes']}
print(f'What depends on {matches[0][\"name\"]} ({node_kinds.get(target, \"?\")}):')
for dep, ek in sorted(set(rdeps)):
    short = dep.replace('Manifest.', '')
    kind = node_kinds.get(dep, '?')
    print(f'  [{ek}] {short} ({kind})')
print(f'\nTotal: {len(set(rdeps))} reverse dependencies')
"
}

cmd_impact() {
  local name="$1"
  python3 -c "
import json, sys
from collections import deque

with open('$DEPGRAPH') as f:
    data = json.load(f)

name = '$name'
matches = [n for n in data['nodes'] if name in n['fullName'] or name in n['name']]
if not matches:
    print(f'No node matching \"{name}\"', file=sys.stderr)
    sys.exit(1)
if len(matches) > 1:
    exact = [m for m in matches if m['name'] == name or m['fullName'] == 'Manifest.' + name]
    if exact:
        matches = exact
    else:
        print(f'Ambiguous: {[m[\"name\"] for m in matches[:10]]}', file=sys.stderr)
        sys.exit(1)

root = matches[0]['fullName']

# Build adjacency list (target -> list of sources that depend on it)
rdep_map = {}
for e in data['edges']:
    rdep_map.setdefault(e['target'], []).append(e['source'])

# BFS transitive closure
visited = set()
queue = deque([root])
while queue:
    node = queue.popleft()
    if node in visited:
        continue
    visited.add(node)
    for dependent in rdep_map.get(node, []):
        if dependent not in visited:
            queue.append(dependent)

visited.discard(root)  # Don't include self

node_kinds = {n['fullName']: n['kind'] for n in data['nodes']}
print(f'Impact of changing {matches[0][\"name\"]}:')
print(f'Total affected: {len(visited)} nodes')
print()

# Group by kind
by_kind = {}
for v in sorted(visited):
    kind = node_kinds.get(v, '?')
    by_kind.setdefault(kind, []).append(v)

for kind in ['axiom', 'theorem', 'def', 'opaque', 'inductive']:
    items = by_kind.get(kind, [])
    if items:
        print(f'{kind} ({len(items)}):')
        for item in items:
            print(f'  {item.replace(\"Manifest.\", \"\")}')
        print()
"
}

cmd_axioms() {
  python3 -c "
import json
with open('$DEPGRAPH') as f:
    data = json.load(f)

axioms = [n for n in data['nodes'] if n['kind'] == 'axiom']
print(f'Axioms ({len(axioms)}):')
for a in sorted(axioms, key=lambda x: x['name']):
    # Count dependents
    rdeps = sum(1 for e in data['edges'] if e['target'] == a['fullName'])
    # Count dependencies
    deps = sum(1 for e in data['edges'] if e['source'] == a['fullName'])
    print(f'  {a[\"name\"]:55s}  deps={deps:3d}  rdeps={rdeps:3d}')
"
}

cmd_dot() {
  local filter="${1:-}"
  python3 -c "
import json, sys

with open('$DEPGRAPH') as f:
    data = json.load(f)

filter_mode = '$filter'

nodes = data['nodes']
edges = data['edges']

# Filter to axioms and theorems only if requested
if filter_mode == '--axiom-theorem':
    keep_kinds = {'axiom', 'theorem'}
    keep_names = set(n['fullName'] for n in nodes if n['kind'] in keep_kinds)
    nodes = [n for n in nodes if n['kind'] in keep_kinds]
    edges = [e for e in edges if e['source'] in keep_names and e['target'] in keep_names]

colors = {
    'axiom': '#e74c3c',
    'theorem': '#3498db',
    'def': '#2ecc71',
    'opaque': '#9b59b6',
    'inductive': '#f39c12',
}

print('digraph DepGraph {')
print('  rankdir=BT;')
print('  node [style=filled, fontsize=10];')

for n in nodes:
    short = n['name']
    color = colors.get(n['kind'], '#95a5a6')
    shape = 'box' if n['kind'] == 'axiom' else 'ellipse'
    print(f'  \"{n[\"fullName\"]}\" [label=\"{short}\", fillcolor=\"{color}\", shape={shape}];')

for e in edges:
    style = 'solid' if e['edgeKind'] == 'value' else 'dashed'
    print(f'  \"{e[\"source\"]}\" -> \"{e[\"target\"]}\" [style={style}];')

print('}')
"
}

case "${1:-help}" in
  generate) cmd_generate ;;
  stats) cmd_stats ;;
  deps) cmd_deps "${2:?Usage: depgraph.sh deps <name>}" ;;
  rdeps) cmd_rdeps "${2:?Usage: depgraph.sh rdeps <name>}" ;;
  impact) cmd_impact "${2:?Usage: depgraph.sh impact <name>}" ;;
  axioms) cmd_axioms ;;
  dot) cmd_dot "${2:-}" ;;
  *)
    echo "Usage: depgraph.sh {generate|stats|deps|rdeps|impact|axioms|dot}" >&2
    exit 1
    ;;
esac
