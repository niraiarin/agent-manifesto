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
#   depgraph.sh subgraph <name> [--format=dot|json] [--depth=N] [--direction=both|up|down]
#                                      — Extract subgraph around <name>
#   depgraph.sh diff <old.json> [new.json] — Compare two graphs
#   depgraph.sh rebuild                — Generate + verify in one step
#   depgraph.sh classify              — Show axiom classification (basis category)
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

cmd_subgraph() {
  local name="$1"; shift
  local format="dot"
  local depth="0"  # 0 = unlimited
  local direction="both"

  while [ $# -gt 0 ]; do
    case "$1" in
      --format=*) format="${1#--format=}" ;;
      --depth=*) depth="${1#--depth=}" ;;
      --direction=*) direction="${1#--direction=}" ;;
      *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
    shift
  done

  python3 - "$DEPGRAPH" "$name" "$format" "$depth" "$direction" << 'PYEOF'
import json
import sys
from collections import deque

depgraph_path = sys.argv[1]
name = sys.argv[2]
fmt = sys.argv[3]
max_depth = int(sys.argv[4])
direction = sys.argv[5]

with open(depgraph_path) as f:
    data = json.load(f)

nodes = data['nodes']
edges = data['edges']
node_map = {n['fullName']: n for n in nodes}

# Resolve name
matches = [n for n in nodes if name in n['fullName'] or name in n['name']]
if not matches:
    print(f'No node matching "{name}"', file=sys.stderr)
    sys.exit(1)
if len(matches) > 1:
    exact = [m for m in matches if m['name'] == name or m['fullName'] == 'Manifest.' + name]
    if exact:
        matches = exact
    else:
        print(f'Ambiguous: {[m["name"] for m in matches[:10]]}', file=sys.stderr)
        sys.exit(1)

root = matches[0]['fullName']

# Build adjacency lists
downstream = {}  # source -> targets (what source depends on)
upstream = {}    # target -> sources (what depends on target)
for e in edges:
    downstream.setdefault(e['source'], []).append(e['target'])
    upstream.setdefault(e['target'], []).append(e['source'])

# BFS with depth limit
def bfs(start, adj_map, max_d):
    visited = {}  # node -> depth
    queue = deque([(start, 0)])
    while queue:
        node, depth = queue.popleft()
        if node in visited:
            continue
        if max_d > 0 and depth > max_d:
            continue
        visited[node] = depth
        for neighbor in adj_map.get(node, []):
            if neighbor not in visited:
                queue.append((neighbor, depth + 1))
    return visited

# Collect nodes in both directions
collected = {root: 0}

if direction in ('both', 'down'):
    # Downstream: what root depends on (follow dependency edges)
    down_nodes = bfs(root, downstream, max_depth)
    collected.update(down_nodes)

if direction in ('both', 'up'):
    # Upstream: what depends on root (follow reverse edges)
    up_nodes = bfs(root, upstream, max_depth)
    collected.update(up_nodes)

collected_names = set(collected.keys())

# Collect relevant edges (both endpoints in subgraph)
sub_edges = [e for e in edges
             if e['source'] in collected_names and e['target'] in collected_names]
sub_nodes = [n for n in nodes if n['fullName'] in collected_names]

if fmt == 'json':
    # Add depth info to nodes
    enriched_nodes = []
    for n in sub_nodes:
        enriched = dict(n)
        enriched['depth'] = collected.get(n['fullName'], -1)
        enriched['isRoot'] = n['fullName'] == root
        enriched_nodes.append(enriched)

    output = {
        'root': root,
        'direction': direction,
        'maxDepth': max_depth if max_depth > 0 else 'unlimited',
        'nodes': enriched_nodes,
        'edges': sub_edges,
    }
    print(json.dumps(output, indent=2, ensure_ascii=False))

elif fmt == 'dot':
    colors = {
        'axiom': '#e74c3c',
        'theorem': '#3498db',
        'def': '#2ecc71',
        'opaque': '#9b59b6',
        'inductive': '#f39c12',
    }
    print('digraph SubGraph {')
    print('  rankdir=BT;')
    print('  node [style=filled, fontsize=10];')
    print(f'  label="Subgraph: {matches[0]["name"]} (direction={direction})";')
    print('  labelloc=t;')
    print()

    for n in sub_nodes:
        short = n['name']
        color = colors.get(n['kind'], '#95a5a6')
        shape = 'box' if n['kind'] == 'axiom' else 'ellipse'
        penwidth = '3' if n['fullName'] == root else '1'
        print(f'  "{n["fullName"]}" [label="{short}", fillcolor="{color}", shape={shape}, penwidth={penwidth}];')

    print()
    for e in sub_edges:
        style = 'solid' if e['edgeKind'] == 'value' else 'dashed'
        print(f'  "{e["source"]}" -> "{e["target"]}" [style={style}];')

    print('}')

else:
    print(f'Unknown format: {fmt}', file=sys.stderr)
    sys.exit(1)

# Summary to stderr
print(f'Subgraph around {matches[0]["name"]}: {len(sub_nodes)} nodes, {len(sub_edges)} edges', file=sys.stderr)
PYEOF
}

cmd_diff() {
  local old_json="$1"
  local new_json="${2:-$DEPGRAPH}"

  if [ ! -f "$old_json" ]; then
    echo "ERROR: $old_json not found" >&2; exit 1
  fi
  if [ ! -f "$new_json" ]; then
    echo "ERROR: $new_json not found" >&2; exit 1
  fi

  python3 - "$old_json" "$new_json" << 'PYEOF'
import json
import sys

old_path = sys.argv[1]
new_path = sys.argv[2]

with open(old_path) as f:
    old = json.load(f)
with open(new_path) as f:
    new = json.load(f)

old_nodes = {n['fullName']: n for n in old['nodes']}
new_nodes = {n['fullName']: n for n in new['nodes']}
old_edges = set((e['source'], e['target'], e['edgeKind']) for e in old['edges'])
new_edges = set((e['source'], e['target'], e['edgeKind']) for e in new['edges'])

# --- Node changes ---
added_nodes = sorted(set(new_nodes) - set(old_nodes))
removed_nodes = sorted(set(old_nodes) - set(new_nodes))
common_nodes = set(old_nodes) & set(new_nodes)

kind_changes = []
for name in sorted(common_nodes):
    ok = old_nodes[name]['kind']
    nk = new_nodes[name]['kind']
    if ok != nk:
        kind_changes.append((name.replace('Manifest.', ''), ok, nk))

# --- Edge changes ---
added_edges = sorted(new_edges - old_edges)
removed_edges = sorted(old_edges - new_edges)

# --- Stats comparison ---
def count_by_kind(nodes_dict):
    kinds = {}
    for n in nodes_dict.values():
        k = n['kind']
        kinds[k] = kinds.get(k, 0) + 1
    return kinds

old_kinds = count_by_kind(old_nodes)
new_kinds = count_by_kind(new_nodes)
all_kinds = sorted(set(old_kinds) | set(new_kinds))

# --- Isolated axiom comparison ---
def get_isolated_axioms(nodes_dict, edges_list):
    axiom_names = set(n for n, v in nodes_dict.items() if v['kind'] == 'axiom')
    has_rdeps = set(e[1] for e in edges_list)
    return axiom_names - has_rdeps

# Reconstruct edge tuple sets with only (src, tgt) for rdeps check
old_edge_pairs = set((e['source'], e['target']) for e in old['edges'])
new_edge_pairs = set((e['source'], e['target']) for e in new['edges'])

old_isolated = get_isolated_axioms(old_nodes, [(s,t) for s,t in old_edge_pairs])
new_isolated = get_isolated_axioms(new_nodes, [(s,t) for s,t in new_edge_pairs])
newly_connected = sorted((old_isolated - new_isolated))
newly_isolated = sorted((new_isolated - old_isolated))

# --- Output ---
print("=" * 60)
print("Dependency Graph Diff")
print("=" * 60)
print(f"Old: {old_path}")
print(f"New: {new_path}")
print()

# Stats table
print("--- Stats ---")
print(f"{'':20s} {'Old':>8s} {'New':>8s} {'Delta':>8s}")
print(f"{'Nodes':20s} {len(old_nodes):8d} {len(new_nodes):8d} {len(new_nodes)-len(old_nodes):+8d}")
print(f"{'Edges':20s} {len(old_edges):8d} {len(new_edges):8d} {len(new_edges)-len(old_edges):+8d}")
for k in all_kinds:
    ov = old_kinds.get(k, 0)
    nv = new_kinds.get(k, 0)
    if ov != nv:
        print(f"  {k:18s} {ov:8d} {nv:8d} {nv-ov:+8d}")
print()

# Kind changes (the key signal for axiom→theorem demotion)
if kind_changes:
    print(f"--- Kind Changes ({len(kind_changes)}) ---")
    for name, ok, nk in kind_changes:
        print(f"  {name}: {ok} → {nk}")
    print()
else:
    print("--- Kind Changes: none ---")
    print()

# Added nodes
if added_nodes:
    print(f"--- Added Nodes ({len(added_nodes)}) ---")
    for name in added_nodes:
        short = name.replace('Manifest.', '')
        kind = new_nodes[name]['kind']
        print(f"  + {short} ({kind})")
    print()

# Removed nodes
if removed_nodes:
    print(f"--- Removed Nodes ({len(removed_nodes)}) ---")
    for name in removed_nodes:
        short = name.replace('Manifest.', '')
        kind = old_nodes[name]['kind']
        print(f"  - {short} ({kind})")
    print()

# Edge changes (summarized)
if added_edges or removed_edges:
    print(f"--- Edge Changes ---")
    print(f"  Added:   {len(added_edges)}")
    print(f"  Removed: {len(removed_edges)}")

    # Show edge changes involving kind-changed nodes (most relevant)
    changed_names = set('Manifest.' + kc[0] for kc in kind_changes)
    relevant_added = [(s,t,k) for s,t,k in added_edges
                      if s in changed_names or t in changed_names]
    relevant_removed = [(s,t,k) for s,t,k in removed_edges
                        if s in changed_names or t in changed_names]

    if relevant_added or relevant_removed:
        print(f"  Involving kind-changed nodes:")
        for s, t, k in relevant_added[:10]:
            print(f"    + {s.replace('Manifest.', '')} →[{k}]→ {t.replace('Manifest.', '')}")
        for s, t, k in relevant_removed[:10]:
            print(f"    - {s.replace('Manifest.', '')} →[{k}]→ {t.replace('Manifest.', '')}")
    print()

# Isolated axiom changes
if newly_connected or newly_isolated:
    print("--- Isolated Axiom Changes ---")
    for name in newly_connected:
        print(f"  ✅ {name.replace('Manifest.', '')} — now connected (was isolated)")
    for name in newly_isolated:
        print(f"  ⚠️  {name.replace('Manifest.', '')} — now isolated (was connected)")
    print()

# No changes
if (not added_nodes and not removed_nodes and not kind_changes
    and not added_edges and not removed_edges
    and not newly_connected and not newly_isolated):
    print("No changes detected.")
    print()

# Summary
total_changes = (len(added_nodes) + len(removed_nodes) + len(kind_changes)
                 + len(added_edges) + len(removed_edges))
print(f"Total: {total_changes} changes "
      f"({len(kind_changes)} kind, "
      f"+{len(added_nodes)}/{'-' + str(len(removed_nodes))} nodes, "
      f"+{len(added_edges)}/{'-' + str(len(removed_edges))} edges)")
PYEOF
}

cmd_rebuild() {
  local snapshot="${1:-}"

  echo "=== Rebuild: generate + verify ===" >&2

  # Auto-snapshot before regeneration if depgraph.json exists
  if [ -f "$DEPGRAPH" ]; then
    local ts
    ts="$(date +%Y%m%d-%H%M%S)"
    local snap="$PROJECT_DIR/depgraph-${ts}.json"
    cp "$DEPGRAPH" "$snap"
    echo "Snapshot saved: $snap" >&2
    snapshot="$snap"
  fi

  # Step 1: Build extractor (if source changed)
  echo "" >&2
  echo "--- Step 1: Build ---" >&2
  cd "$LEAN_DIR"
  export PATH="$HOME/.elan/bin:$PATH"
  if ! lake build extractdeps 2>&1 | tail -3; then
    echo "ERROR: lake build failed" >&2
    exit 1
  fi

  # Step 2: Generate
  echo "" >&2
  echo "--- Step 2: Generate ---" >&2
  lake exe extractdeps > "$DEPGRAPH"
  python3 -c "
import json
with open('$DEPGRAPH') as f:
    data = json.load(f)
print(f'Nodes: {len(data[\"nodes\"])}, Edges: {len(data[\"edges\"])}')
kinds = {}
for n in data['nodes']:
    kinds[n['kind']] = kinds.get(n['kind'], 0) + 1
for k, v in sorted(kinds.items(), key=lambda x: -x[1]):
    print(f'  {k}: {v}')
"

  # Step 3: Diff (if snapshot exists)
  if [ -n "$snapshot" ] && [ -f "$snapshot" ]; then
    echo "" >&2
    echo "--- Step 3: Diff ---" >&2
    cd "$PROJECT_DIR"
    cmd_diff "$snapshot" "$DEPGRAPH"
  fi

  # Step 4: Verify
  echo "" >&2
  echo "--- Step 4: Verify ---" >&2
  cd "$PROJECT_DIR"
  "$SCRIPT_DIR/depgraph-verify.sh" "$DEPGRAPH"
}

cmd_classify() {
  python3 - "$DEPGRAPH" "$LEAN_DIR" << 'PYEOF'
import json
import sys
import os
import re

depgraph_path = sys.argv[1]
lean_dir = sys.argv[2]

with open(depgraph_path) as f:
    data = json.load(f)

axioms = [n for n in data['nodes'] if n['kind'] == 'axiom']
edges = data['edges']

# Extract Axiom Card metadata from Lean source
axiom_info = {}
manifest_dir = os.path.join(lean_dir, 'Manifest')

for root, dirs, files in os.walk(manifest_dir):
    for fname in files:
        if not fname.endswith('.lean'):
            continue
        fpath = os.path.join(root, fname)
        with open(fpath) as f:
            content = f.read()

        # Find axiom cards: /-- [Axiom Card] ... -/ followed by axiom declaration
        # Match doc comment blocks before axiom declarations
        pattern = r'/--\s*\[Axiom Card\](.*?)-/\s*axiom\s+(\w+)'
        for m in re.finditer(pattern, content, re.DOTALL):
            card_text = m.group(1)
            axiom_name = m.group(2)

            # Extract Layer
            layer_match = re.search(r'Layer:\s*(.+?)(?:\n|$)', card_text)
            layer = layer_match.group(1).strip() if layer_match else 'unknown'

            # Extract Refutation condition
            refut_match = re.search(r'Refutation condition:\s*(.+?)(?:\n\s*\w|\Z)', card_text, re.DOTALL)
            refutation = refut_match.group(1).strip() if refut_match else 'unknown'

            # Classify basis
            if 'Environment-derived' in layer:
                basis = 'environment'
            elif 'Contract-derived' in layer:
                basis = 'contract'
            elif 'Natural-science-derived' in layer:
                basis = 'natural-science'
            elif 'Hypothesis-derived' in layer:
                basis = 'hypothesis'
            elif 'Design-derived' in layer or 'Design' in layer:
                basis = 'design'
            else:
                basis = 'other'

            # Classify reclassification potential
            if basis in ('environment', 'natural-science'):
                potential = 'derivable'  # potentially derivable from math foundations
            elif basis == 'hypothesis':
                potential = 'derivable?'  # potentially derivable from statistics
            elif basis == 'contract':
                potential = 'true-axiom'  # must remain axiom
            elif basis == 'design':
                potential = 'design-axiom'  # design choice, may remain
            else:
                potential = 'unknown'

            axiom_info[axiom_name] = {
                'layer': layer,
                'basis': basis,
                'potential': potential,
                'refutation': refutation[:60] + '...' if len(refutation) > 60 else refutation,
            }

# Count rdeps for each axiom
rdeps_count = {}
for a in axioms:
    rdeps_count[a['fullName']] = sum(1 for e in edges if e['target'] == a['fullName'])

# Output classification table
print(f"{'Axiom':<50s} {'Basis':<16s} {'Potential':<14s} {'rdeps':>5s}")
print("-" * 90)

# Group by basis
groups = {}
for a in sorted(axioms, key=lambda x: x['name']):
    short = a['name']
    # Strip namespace prefix for lookup
    lookup = short.split('.')[-1] if '.' in short else short
    info = axiom_info.get(lookup, {})
    basis = info.get('basis', 'no-card')
    potential = info.get('potential', 'no-card')
    rdeps = rdeps_count.get(a['fullName'], 0)
    groups.setdefault(basis, []).append((short, potential, rdeps))

order = ['environment', 'natural-science', 'contract', 'hypothesis', 'design', 'other', 'no-card']
for basis in order:
    items = groups.get(basis, [])
    if not items:
        continue
    print(f"\n[{basis}] ({len(items)} axioms)")
    for name, potential, rdeps in items:
        print(f"  {name:<48s} {potential:<14s} {rdeps:>5d}")

# Summary
print()
print("=" * 50)
print("Classification Summary")
print("=" * 50)
potentials = {}
for items in groups.values():
    for _, pot, _ in items:
        potentials[pot] = potentials.get(pot, 0) + 1
for pot in ['derivable', 'derivable?', 'true-axiom', 'design-axiom', 'no-card', 'unknown']:
    count = potentials.get(pot, 0)
    if count:
        print(f"  {pot:<16s} {count:>3d}")
PYEOF
}

case "${1:-help}" in
  generate) cmd_generate ;;
  stats) cmd_stats ;;
  deps) cmd_deps "${2:?Usage: depgraph.sh deps <name>}" ;;
  rdeps) cmd_rdeps "${2:?Usage: depgraph.sh rdeps <name>}" ;;
  impact) cmd_impact "${2:?Usage: depgraph.sh impact <name>}" ;;
  axioms) cmd_axioms ;;
  dot) cmd_dot "${2:-}" ;;
  subgraph) shift; cmd_subgraph "$@" ;;
  diff) cmd_diff "${2:?Usage: depgraph.sh diff <old.json> [new.json]}" "${3:-$DEPGRAPH}" ;;
  rebuild) cmd_rebuild "${2:-}" ;;
  classify) cmd_classify ;;
  *)
    echo "Usage: depgraph.sh {generate|stats|deps|rdeps|impact|axioms|dot|subgraph|diff|rebuild|classify}" >&2
    exit 1
    ;;
esac
