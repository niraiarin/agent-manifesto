#!/usr/bin/env bash
set -uo pipefail
PASS=0; FAIL=0
BASE="$(git rev-parse --show-toplevel 2>/dev/null || echo /Users/nirarin/work/agent-manifesto)"
DEPGRAPH="$BASE/scripts/depgraph.sh"
VERIFY="$BASE/scripts/depgraph-verify.sh"
GRAPH_JSON="$BASE/depgraph.json"

echo "=== Phase 5: Dependency Graph Tests ==="

check() {
  local name="$1" cond="$2"
  echo -n "$name... "
  if eval "$cond"; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL"; FAIL=$((FAIL+1)); fi
}

# ============================================================
# 構造テスト: ファイル存在・基本構造
# ============================================================
echo "--- Structure ---"

check "DG.01: depgraph.sh exists and is executable" \
  "[ -x '$DEPGRAPH' ]"

check "DG.02: depgraph-verify.sh exists and is executable" \
  "[ -x '$VERIFY' ]"

check "DG.03: ExtractDeps.lean exists" \
  "[ -f '$BASE/lean-formalization/ExtractDeps.lean' ]"

check "DG.04: depgraph.json exists and is valid JSON" \
  "python3 -c 'import json; json.load(open(\"$GRAPH_JSON\"))' 2>/dev/null"

check "DG.05: depgraph.json has nodes array" \
  "python3 -c 'import json; d=json.load(open(\"$GRAPH_JSON\")); assert \"nodes\" in d' 2>/dev/null"

check "DG.06: depgraph.json has edges array" \
  "python3 -c 'import json; d=json.load(open(\"$GRAPH_JSON\")); assert \"edges\" in d' 2>/dev/null"

echo ""

# ============================================================
# stats コマンド
# ============================================================
echo "--- stats ---"

STATS_OUT="$("$DEPGRAPH" stats 2>&1)"

check "DG.10: stats outputs node count" \
  "echo '$STATS_OUT' | grep -q 'Total nodes:'"

check "DG.11: stats reports 64 axioms" \
  "echo '$STATS_OUT' | grep -q 'axiom: 64'"

check "DG.12: stats reports theorem count >= 359" \
  "python3 -c \"
import re
m = re.search(r'theorem: (\d+)', '''$STATS_OUT''')
assert m and int(m.group(1)) >= 359
\" 2>/dev/null"

check "DG.13: stats reports most-depended-on axioms" \
  "echo '$STATS_OUT' | grep -q 'Most-depended-on axioms:'"

echo ""

# ============================================================
# axioms コマンド
# ============================================================
echo "--- axioms ---"

AXIOMS_OUT="$("$DEPGRAPH" axioms 2>&1)"

check "DG.20: axioms lists 64 axioms" \
  "echo '$AXIOMS_OUT' | grep -q 'Axioms (64)'"

check "DG.21: axioms includes output_nondeterministic" \
  "echo '$AXIOMS_OUT' | grep -q 'output_nondeterministic'"

check "DG.22: axioms includes verification_requires_independence" \
  "echo '$AXIOMS_OUT' | grep -q 'verification_requires_independence'"

check "DG.23: axioms shows deps and rdeps columns" \
  "echo '$AXIOMS_OUT' | grep -q 'deps=.*rdeps='"

echo ""

# ============================================================
# deps コマンド
# ============================================================
echo "--- deps ---"

DEPS_OUT="$("$DEPGRAPH" deps output_nondeterministic 2>&1)"

check "DG.30: deps shows kind (axiom)" \
  "echo '$DEPS_OUT' | grep -q 'axiom'"

check "DG.31: deps of output_nondeterministic includes World" \
  "echo '$DEPS_OUT' | grep -q 'World'"

check "DG.32: deps of output_nondeterministic includes canTransition" \
  "echo '$DEPS_OUT' | grep -q 'canTransition'"

check "DG.33: deps shows edge kind [type] or [value]" \
  "echo '$DEPS_OUT' | grep -qE '\[(type|value)\]'"

check "DG.34: deps shows total count" \
  "echo '$DEPS_OUT' | grep -q 'Total:'"

# Error case
check "DG.35: deps with nonexistent name returns error" \
  "! '$DEPGRAPH' deps nonexistent_xyz_123 2>/dev/null"

echo ""

# ============================================================
# rdeps コマンド
# ============================================================
echo "--- rdeps ---"

RDEPS_OUT="$("$DEPGRAPH" rdeps structure_accumulates 2>&1)"

check "DG.40: rdeps of structure_accumulates shows dependents" \
  "echo '$RDEPS_OUT' | grep -q 'reverse dependencies'"

check "DG.41: rdeps includes at least 1 theorem" \
  "echo '$RDEPS_OUT' | grep -q 'theorem'"

echo ""

# ============================================================
# impact コマンド
# ============================================================
echo "--- impact ---"

IMPACT_OUT="$("$DEPGRAPH" impact output_nondeterministic 2>&1)"

check "DG.50: impact shows total affected count" \
  "echo '$IMPACT_OUT' | grep -q 'Total affected:'"

check "DG.51: impact of output_nondeterministic affects 3 nodes" \
  "echo '$IMPACT_OUT' | grep -q 'Total affected: 3'"

check "DG.52: impact includes d12_task_design_probabilistic" \
  "echo '$IMPACT_OUT' | grep -q 'd12_task_design_probabilistic'"

check "DG.53: impact includes task_design_is_probabilistic" \
  "echo '$IMPACT_OUT' | grep -q 'task_design_is_probabilistic'"

check "DG.54: impact includes manifesto_probabilistically_interpreted" \
  "echo '$IMPACT_OUT' | grep -q 'manifesto_probabilistically_interpreted'"

IMPACT_E1="$("$DEPGRAPH" impact verification_requires_independence 2>&1)"

check "DG.55: impact of verification_requires_independence affects 4 nodes" \
  "echo '$IMPACT_E1' | grep -q 'Total affected: 4'"

check "DG.56: impact of E1 includes cognitive_separation_required (P2)" \
  "echo '$IMPACT_E1' | grep -q 'cognitive_separation_required'"

echo ""

# ============================================================
# dot コマンド
# ============================================================
echo "--- dot ---"

DOT_TMP="$(mktemp)"
"$DEPGRAPH" dot > "$DOT_TMP" 2>/dev/null

check "DG.60: dot outputs valid digraph header" \
  "head -1 '$DOT_TMP' | grep -q 'digraph DepGraph'"

check "DG.61: dot outputs closing brace" \
  "tail -1 '$DOT_TMP' | grep -q '}'"

check "DG.62: dot includes axiom nodes (red)" \
  "grep -q '#e74c3c' '$DOT_TMP'"

check "DG.63: dot includes theorem nodes (blue)" \
  "grep -q '#3498db' '$DOT_TMP'"

DOT_AT_TMP="$(mktemp)"
"$DEPGRAPH" dot --axiom-theorem > "$DOT_AT_TMP" 2>/dev/null

check "DG.64: dot --axiom-theorem filters to axioms and theorems" \
  "! grep -q '#2ecc71' '$DOT_AT_TMP'"  # no def (green) nodes

rm -f "$DOT_TMP" "$DOT_AT_TMP"

echo ""

# ============================================================
# subgraph コマンド: DOT 出力
# ============================================================
echo "--- subgraph (DOT) ---"

SUB_DOT="$("$DEPGRAPH" subgraph output_nondeterministic 2>/dev/null)"

check "DG.70: subgraph DOT has digraph header" \
  "echo '$SUB_DOT' | head -1 | grep -q 'digraph SubGraph'"

check "DG.71: subgraph DOT has label with node name" \
  "echo '$SUB_DOT' | grep -q 'output_nondeterministic'"

check "DG.72: subgraph DOT highlights root with penwidth=3" \
  "echo '$SUB_DOT' | grep 'output_nondeterministic' | grep -q 'penwidth=3'"

check "DG.73: subgraph DOT non-root has penwidth=1" \
  "echo '$SUB_DOT' | grep 'World' | grep -q 'penwidth=1'"

echo ""

# ============================================================
# subgraph コマンド: JSON 出力
# ============================================================
echo "--- subgraph (JSON) ---"

SUB_JSON="$("$DEPGRAPH" subgraph output_nondeterministic --format=json 2>/dev/null)"

check "DG.80: subgraph JSON is valid" \
  "echo '$SUB_JSON' | python3 -c 'import json,sys; json.load(sys.stdin)' 2>/dev/null"

check "DG.81: subgraph JSON has root field" \
  "echo '$SUB_JSON' | python3 -c 'import json,sys; d=json.load(sys.stdin); assert \"root\" in d' 2>/dev/null"

check "DG.82: subgraph JSON has nodes with depth" \
  "echo '$SUB_JSON' | python3 -c '
import json,sys
d=json.load(sys.stdin)
assert all(\"depth\" in n for n in d[\"nodes\"])
' 2>/dev/null"

check "DG.83: subgraph JSON has nodes with isRoot" \
  "echo '$SUB_JSON' | python3 -c '
import json,sys
d=json.load(sys.stdin)
roots = [n for n in d[\"nodes\"] if n.get(\"isRoot\")]
assert len(roots) == 1
' 2>/dev/null"

check "DG.84: subgraph JSON root node has depth=0" \
  "echo '$SUB_JSON' | python3 -c '
import json,sys
d=json.load(sys.stdin)
root = [n for n in d[\"nodes\"] if n.get(\"isRoot\")][0]
assert root[\"depth\"] == 0
' 2>/dev/null"

check "DG.85: subgraph JSON edges only reference subgraph nodes" \
  "echo '$SUB_JSON' | python3 -c '
import json,sys
d=json.load(sys.stdin)
names = set(n[\"fullName\"] for n in d[\"nodes\"])
for e in d[\"edges\"]:
    assert e[\"source\"] in names, f\"edge source {e['source']} not in subgraph\"
    assert e[\"target\"] in names, f\"edge target {e['target']} not in subgraph\"
' 2>/dev/null"

echo ""

# ============================================================
# subgraph コマンド: direction フィルタ
# ============================================================
echo "--- subgraph (direction) ---"

SUB_UP="$("$DEPGRAPH" subgraph output_nondeterministic --direction=up --format=json 2>/dev/null)"
SUB_DOWN="$("$DEPGRAPH" subgraph output_nondeterministic --direction=down --format=json 2>/dev/null)"
SUB_BOTH="$("$DEPGRAPH" subgraph output_nondeterministic --direction=both --format=json 2>/dev/null)"

check "DG.90: direction=up includes only dependents (theorems)" \
  "echo '$SUB_UP' | python3 -c '
import json,sys
d=json.load(sys.stdin)
assert d[\"direction\"] == \"up\"
non_root = [n for n in d[\"nodes\"] if not n.get(\"isRoot\")]
# upstream nodes should include theorems that depend on this axiom
thms = [n for n in non_root if n[\"kind\"] == \"theorem\"]
assert len(thms) >= 1
' 2>/dev/null"

check "DG.91: direction=down includes only dependencies (types)" \
  "echo '$SUB_DOWN' | python3 -c '
import json,sys
d=json.load(sys.stdin)
assert d[\"direction\"] == \"down\"
non_root = [n for n in d[\"nodes\"] if not n.get(\"isRoot\")]
# downstream nodes should NOT include theorems that depend on this axiom
thms = [n for n in non_root if n[\"kind\"] == \"theorem\"]
assert len(thms) == 0, f\"found {len(thms)} theorems in downstream\"
' 2>/dev/null"

check "DG.92: direction=both has more nodes than up or down alone" \
  "echo '$SUB_BOTH' | python3 -c '
import json,sys
d=json.load(sys.stdin)
both_count = len(d[\"nodes\"])
' 2>/dev/null && echo '$SUB_UP' | python3 -c '
import json,sys
d=json.load(sys.stdin)
up_count = len(d[\"nodes\"])
' 2>/dev/null && python3 -c '
import json, sys
both = json.loads(sys.argv[1])
up = json.loads(sys.argv[2])
down = json.loads(sys.argv[3])
assert len(both[\"nodes\"]) >= len(up[\"nodes\"])
assert len(both[\"nodes\"]) >= len(down[\"nodes\"])
' '$SUB_BOTH' '$SUB_UP' '$SUB_DOWN' 2>/dev/null"

echo ""

# ============================================================
# subgraph コマンド: depth 制限
# ============================================================
echo "--- subgraph (depth) ---"

SUB_D1="$("$DEPGRAPH" subgraph cognitive_separation_required --depth=1 --format=json 2>/dev/null)"
SUB_D2="$("$DEPGRAPH" subgraph cognitive_separation_required --depth=2 --format=json 2>/dev/null)"
SUB_UNL="$("$DEPGRAPH" subgraph cognitive_separation_required --format=json 2>/dev/null)"

check "DG.100: depth=1 all nodes have depth <= 1" \
  "echo '$SUB_D1' | python3 -c '
import json,sys
d=json.load(sys.stdin)
assert all(n[\"depth\"] <= 1 for n in d[\"nodes\"])
' 2>/dev/null"

check "DG.101: depth=2 has more nodes than depth=1" \
  "python3 -c '
import json
d1 = json.loads(\"\"\"$(echo "$SUB_D1")\"\"\")
d2 = json.loads(\"\"\"$(echo "$SUB_D2")\"\"\")
assert len(d2[\"nodes\"]) > len(d1[\"nodes\"]), f\"depth=2 ({len(d2['nodes'])}) not > depth=1 ({len(d1['nodes'])})\"
' 2>/dev/null"

check "DG.102: unlimited depth has >= nodes than depth=2" \
  "python3 -c '
import json
d2 = json.loads(\"\"\"$(echo "$SUB_D2")\"\"\")
du = json.loads(\"\"\"$(echo "$SUB_UNL")\"\"\")
assert len(du[\"nodes\"]) >= len(d2[\"nodes\"])
' 2>/dev/null"

echo ""

# ============================================================
# subgraph コマンド: 整合性チェック
# ============================================================
echo "--- subgraph (consistency) ---"

check "DG.110: subgraph of axiom with rdeps=0 has no upstream theorems" \
  "'$DEPGRAPH' subgraph context_bounds_action --direction=up --format=json 2>/dev/null | python3 -c '
import json,sys
d=json.load(sys.stdin)
non_root = [n for n in d[\"nodes\"] if not n.get(\"isRoot\")]
thms = [n for n in non_root if n[\"kind\"] == \"theorem\"]
assert len(thms) == 0, f\"isolated axiom has {len(thms)} upstream theorems\"
' 2>/dev/null"

check "DG.111: subgraph is subset of full graph" \
  "'$DEPGRAPH' subgraph structure_accumulates --format=json 2>/dev/null | python3 -c '
import json,sys
sub = json.load(sys.stdin)
with open(\"$GRAPH_JSON\") as f:
    full = json.load(f)
full_names = set(n[\"fullName\"] for n in full[\"nodes\"])
for n in sub[\"nodes\"]:
    assert n[\"fullName\"] in full_names, f\"{n['fullName']} not in full graph\"
full_edges = set((e[\"source\"],e[\"target\"]) for e in full[\"edges\"])
for e in sub[\"edges\"]:
    assert (e[\"source\"],e[\"target\"]) in full_edges, f\"edge not in full graph\"
' 2>/dev/null"

check "DG.112: subgraph error on nonexistent name" \
  "! '$DEPGRAPH' subgraph nonexistent_xyz_123 --format=json 2>/dev/null"

echo ""

# ============================================================
# diff コマンド
# ============================================================
echo "--- diff ---"

# Create a modified graph for diff testing
DIFF_TMP="$(mktemp)"
python3 -c "
import json
with open('$GRAPH_JSON') as f:
    data = json.load(f)

# Simulate axiom→theorem demotion
for n in data['nodes']:
    if n['fullName'] == 'Manifest.output_nondeterministic':
        n['kind'] = 'theorem'

# Simulate new foundation node
data['nodes'].append({
    'name': 'SoftmaxDistribution',
    'fullName': 'Manifest.SoftmaxDistribution',
    'kind': 'def'
})

# Simulate new edge
data['edges'].append({
    'source': 'Manifest.output_nondeterministic',
    'target': 'Manifest.SoftmaxDistribution',
    'edgeKind': 'value'
})

# Simulate removed node
data['nodes'] = [n for n in data['nodes'] if n['fullName'] != 'Manifest.governanceNecessityExplanation']

with open('$DIFF_TMP', 'w') as f:
    json.dump(data, f)
" 2>/dev/null

DIFF_OUT="$("$DEPGRAPH" diff "$GRAPH_JSON" "$DIFF_TMP" 2>&1)"

check "DG.130: diff outputs header" \
  "echo '$DIFF_OUT' | grep -q 'Dependency Graph Diff'"

check "DG.131: diff detects kind change (axiom→theorem)" \
  "echo '$DIFF_OUT' | grep -q 'output_nondeterministic: axiom.*theorem'"

check "DG.132: diff detects added node" \
  "echo '$DIFF_OUT' | grep -q 'SoftmaxDistribution'"

check "DG.133: diff detects removed node" \
  "echo '$DIFF_OUT' | grep -q 'governanceNecessityExplanation'"

check "DG.134: diff detects edge changes" \
  "echo '$DIFF_OUT' | grep -q 'Edge Changes'"

check "DG.135: diff shows stats delta" \
  "echo '$DIFF_OUT' | grep -q 'Delta'"

check "DG.136: diff shows axiom count -1" \
  "echo '$DIFF_OUT' | grep 'axiom' | grep -q '\-1'"

check "DG.137: diff shows theorem count +1" \
  "echo '$DIFF_OUT' | grep 'theorem' | grep -q '+1'"

check "DG.138: diff shows edge involving kind-changed node" \
  "echo '$DIFF_OUT' | grep -q 'output_nondeterministic.*SoftmaxDistribution'"

# Self-diff should show no changes
SELFDIFF_OUT="$("$DEPGRAPH" diff "$GRAPH_JSON" "$GRAPH_JSON" 2>&1)"

check "DG.139: self-diff reports no changes" \
  "echo '$SELFDIFF_OUT' | grep -q 'No changes detected'"

check "DG.140: self-diff total is 0" \
  "echo '$SELFDIFF_OUT' | grep -q 'Total: 0 changes'"

# Error case
check "DG.141: diff with nonexistent file returns error" \
  "! '$DEPGRAPH' diff /nonexistent/file.json 2>/dev/null"

rm -f "$DIFF_TMP"

echo ""

# ============================================================
# classify コマンド
# ============================================================
echo "--- classify ---"

CLASSIFY_OUT="$("$DEPGRAPH" classify 2>&1)"

check "DG.150: classify outputs classification summary" \
  "echo '$CLASSIFY_OUT' | grep -q 'Classification Summary'"

check "DG.151: classify detects environment-derived axioms" \
  "echo '$CLASSIFY_OUT' | grep -q 'environment'"

check "DG.152: classify detects contract-derived axioms" \
  "echo '$CLASSIFY_OUT' | grep -q 'contract'"

check "DG.153: classify shows derivable potential" \
  "echo '$CLASSIFY_OUT' | grep -q 'derivable'"

check "DG.154: classify shows true-axiom potential" \
  "echo '$CLASSIFY_OUT' | grep -q 'true-axiom'"

check "DG.155: classify includes output_nondeterministic as derivable" \
  "echo '$CLASSIFY_OUT' | grep 'output_nondeterministic' | grep -q 'derivable'"

check "DG.156: classify includes human_resource_authority as true-axiom" \
  "echo '$CLASSIFY_OUT' | grep 'human_resource_authority' | grep -q 'true-axiom'"

echo ""

# ============================================================
# rebuild コマンド (structural verification only)
# ============================================================
echo "--- rebuild (structure) ---"

check "DG.160: rebuild command is defined in depgraph.sh" \
  "grep -q 'cmd_rebuild' '$DEPGRAPH'"

check "DG.161: rebuild calls depgraph-verify.sh" \
  "grep -q 'depgraph-verify.sh' '$DEPGRAPH'"

check "DG.162: rebuild creates snapshot" \
  "grep -q 'snapshot' '$DEPGRAPH'"

echo ""

# ============================================================
# workflow doc
# ============================================================
echo "--- workflow doc ---"

check "DG.170: workflow doc exists" \
  "[ -f '$BASE/docs/research/157-axiom-restructuring-workflow.md' ]"

check "DG.171: workflow doc covers all phases" \
  "grep -q 'Phase 0' '$BASE/docs/research/157-axiom-restructuring-workflow.md' && \
   grep -q 'Phase 1' '$BASE/docs/research/157-axiom-restructuring-workflow.md' && \
   grep -q 'Phase 2' '$BASE/docs/research/157-axiom-restructuring-workflow.md' && \
   grep -q 'Phase 3' '$BASE/docs/research/157-axiom-restructuring-workflow.md' && \
   grep -q 'Phase 4' '$BASE/docs/research/157-axiom-restructuring-workflow.md'"

check "DG.172: workflow doc references all tools" \
  "grep -q 'classify' '$BASE/docs/research/157-axiom-restructuring-workflow.md' && \
   grep -q 'subgraph' '$BASE/docs/research/157-axiom-restructuring-workflow.md' && \
   grep -q 'rebuild' '$BASE/docs/research/157-axiom-restructuring-workflow.md' && \
   grep -q 'diff' '$BASE/docs/research/157-axiom-restructuring-workflow.md' && \
   grep -q 'verify' '$BASE/docs/research/157-axiom-restructuring-workflow.md'"

echo ""

# ============================================================
# depgraph-verify.sh
# ============================================================
echo "--- verify ---"

VERIFY_OUT="$("$VERIFY" 2>&1)" || true

check "DG.120: verify runs without crash" \
  "echo '$VERIFY_OUT' | grep -q 'SUMMARY'"

check "DG.121: verify reports no failures" \
  "echo '$VERIFY_OUT' | grep -q 'No failures'"

check "DG.122: verify checks completeness" \
  "echo '$VERIFY_OUT' | grep -q 'Check 1: Completeness'"

check "DG.123: verify checks DAG integrity" \
  "echo '$VERIFY_OUT' | grep -q 'Check 2: DAG Integrity'"

check "DG.124: verify checks reachability" \
  "echo '$VERIFY_OUT' | grep -q 'Check 3: Reachability'"

check "DG.125: verify checks PropositionId cross-reference" \
  "echo '$VERIFY_OUT' | grep -q 'Check 4: PropositionId'"

check "DG.126: verify detects 6 isolated axioms" \
  "echo '$VERIFY_OUT' | grep -q '6 axioms'"

check "DG.127: verify confirms no cycles" \
  "echo '$VERIFY_OUT' | grep -q 'No cycles'"

check "DG.128: verify verdict is PASS" \
  "echo '$VERIFY_OUT' | grep -q 'VERDICT: PASS'"

echo ""

# ============================================================
# Summary
# ============================================================
echo "=== Results: $PASS passed, $FAIL failed ==="
exit $FAIL
