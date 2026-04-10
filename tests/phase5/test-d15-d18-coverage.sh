#!/usr/bin/env bash
# test-d15-d18-coverage.sh — D15-D18 弱カバレッジ解消テスト
# Phase 5: D15 (ハーネス工学), D16 (情報関連性), D17 (演繹的設計), D18 (マルチエージェント)
#
# manifest-trace coverage の弱カバレッジ警告（テストなし）を解消する。

set -uo pipefail

BASE="$(git rev-parse --show-toplevel 2>/dev/null || echo /Users/nirarin/work/agent-manifesto)"
cd "$BASE"

PASS=0
FAIL=0

check() {
  local name="$1" cond="$2"
  echo -n "  $name... "
  if eval "$cond"; then echo "PASS"; PASS=$((PASS + 1)); else echo "FAIL"; FAIL=$((FAIL + 1)); fi
}

echo "=== D15-D18 Coverage Tests ==="
echo ""

# --- D15: ハーネス工学定理 ---
echo "D15: Harness Engineering"
check "D15.1 DesignFoundation.lean has d15 theorems" \
  "grep -q 'd15' lean-formalization/Manifest/DesignFoundation.lean"
check "D15.2 D15 dependencies defined in Ontology.lean" \
  "grep -q '| .d15 =>' lean-formalization/Manifest/Ontology.lean"

# --- D16: 情報関連性定理 ---
echo ""
echo "D16: Information Relevance"
check "D16.1 DesignFoundation.lean has d16 theorems" \
  "grep -q 'd16' lean-formalization/Manifest/DesignFoundation.lean"
check "D16.2 D16 dependencies defined in Ontology.lean" \
  "grep -q '| .d16 =>' lean-formalization/Manifest/Ontology.lean"

# --- D17: 演繹的設計ワークフロー ---
echo ""
echo "D17: Deductive Design Workflow"
check "D17.1 generate-plugin SKILL.md exists" \
  "test -f .claude/skills/generate-plugin/SKILL.md"
check "D17.2 d17-state.sh exists" \
  "test -f .claude/skills/generate-plugin/scripts/d17-state.sh"
check "D17.3 ConditionalAxiomSystem.lean exists" \
  "test -f lean-formalization/Manifest/Models/ConditionalAxiomSystem.lean"
check "D17.4 D17 has artifact-manifest entries with refs" \
  "jq -e '[.artifacts[] | select(.refs? // [] | index(\"D17\"))] | length > 0' artifact-manifest.json > /dev/null"
check "D17.5 D17 dependencies defined in Ontology.lean" \
  "grep -q '| .d17 =>' lean-formalization/Manifest/Ontology.lean"

# --- D18: マルチエージェント協調 ---
echo ""
echo "D18: Multi-Agent Coordination"
check "D18.1 DesignFoundation.lean has d18 theorems" \
  "grep -q 'd18' lean-formalization/Manifest/DesignFoundation.lean"
check "D18.2 CC-C8 defines coordination primitives" \
  "grep -q 'CC-C8' lean-formalization/Manifest/Models/Instances/ClaudeCode/Assumptions.lean"
check "D18.3 ConditionalDesignFoundation.lean references D18" \
  "grep -q 'd18' lean-formalization/Manifest/Models/Instances/ClaudeCode/ConditionalDesignFoundation.lean"
check "D18.4 D18 dependencies defined in Ontology.lean" \
  "grep -q '| .d18 =>' lean-formalization/Manifest/Ontology.lean"

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
exit $FAIL
