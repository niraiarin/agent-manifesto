#!/usr/bin/env bash
# test-l5-ssot-structural.sh — L5 Platform Capabilities SSOT の構造テスト
# Phase 5: 構造テスト
#
# テスト対象:
# - L5 SSOT JSON の存在と構造
# - Ontology.lean の L5 doc comment との整合性
# - EnforcementLayer × Platform → Primitives マッピングの完全性
# - TaskClassification との接続（task_routing）

set -euo pipefail

BASE="$(git rev-parse --show-toplevel 2>/dev/null || echo /Users/nirarin/work/agent-manifesto)"
cd "$BASE"

PASS=0
FAIL=0
TOTAL=0

pass() {
  PASS=$((PASS + 1))
  TOTAL=$((TOTAL + 1))
  echo "  PASS: $1"
}

fail() {
  FAIL=$((FAIL + 1))
  TOTAL=$((TOTAL + 1))
  echo "  FAIL: $1"
}

L5_JSON="docs/l5-platform-capabilities.json"
ONTOLOGY="lean-formalization/Manifest/Ontology.lean"

echo "--- Section 12: L5 Platform Capabilities SSOT Tests ---"

# 12.1: JSON file exists
if [ -f "$L5_JSON" ]; then
  pass "L5 SSOT JSON exists"
else
  fail "L5 SSOT JSON exists"
fi

# 12.2: Valid JSON
if jq empty "$L5_JSON" 2>/dev/null; then
  pass "L5 SSOT is valid JSON"
else
  fail "L5 SSOT is valid JSON"
fi

# 12.3: Has platforms key
if jq -e '.platforms' "$L5_JSON" >/dev/null 2>&1; then
  pass "Has platforms key"
else
  fail "Has platforms key"
fi

# 12.4: All platforms from Ontology.lean are present
# Ontology.lean lists: Claude Code, Codex CLI, Gemini CLI, Local LLM
for platform in "claude-code" "codex-cli" "gemini-cli"; do
  if jq -e ".platforms[\"$platform\"]" "$L5_JSON" >/dev/null 2>&1; then
    pass "Platform '$platform' present"
  else
    fail "Platform '$platform' present"
  fi
done

# 12.5: Each platform has enforcement_primitives with all 3 layers
for platform in $(jq -r '.platforms | keys[]' "$L5_JSON"); do
  for layer in "structural" "procedural" "normative"; do
    if jq -e ".platforms[\"$platform\"].enforcement_primitives[\"$layer\"]" "$L5_JSON" >/dev/null 2>&1; then
      pass "Platform '$platform' has '$layer' enforcement layer"
    else
      fail "Platform '$platform' has '$layer' enforcement layer"
    fi
  done
done

# 12.6: Each platform has task_routing with all 3 TaskAutomationClass values
for platform in $(jq -r '.platforms | keys[]' "$L5_JSON"); do
  for class in "deterministic" "bounded" "judgmental"; do
    if jq -e ".platforms[\"$platform\"].task_routing[\"$class\"]" "$L5_JSON" >/dev/null 2>&1; then
      pass "Platform '$platform' has task_routing for '$class'"
    else
      fail "Platform '$platform' has task_routing for '$class'"
    fi
  done
done

# 12.7: Capabilities match Ontology.lean L5 table
# Claude Code should have skill_system=true, codex-cli should have skill_system=false
CC_SKILL=$(jq -r '.platforms["claude-code"].capabilities.skill_system' "$L5_JSON")
CODEX_SKILL=$(jq -r '.platforms["codex-cli"].capabilities.skill_system' "$L5_JSON")
if [ "$CC_SKILL" = "true" ] && [ "$CODEX_SKILL" = "false" ]; then
  pass "Skill system capability matches Ontology.lean (CC=true, Codex=false)"
else
  fail "Skill system capability matches Ontology.lean (CC=$CC_SKILL, Codex=$CODEX_SKILL)"
fi

CC_HOOKS=$(jq -r '.platforms["claude-code"].capabilities.hooks' "$L5_JSON")
CODEX_HOOKS=$(jq -r '.platforms["codex-cli"].capabilities.hooks' "$L5_JSON")
if [ "$CC_HOOKS" = "true" ] && [ "$CODEX_HOOKS" = "false" ]; then
  pass "Hooks capability matches Ontology.lean (CC=true, Codex=false)"
else
  fail "Hooks capability matches Ontology.lean (CC=$CC_HOOKS, Codex=$CODEX_HOOKS)"
fi

CC_AGENTS=$(jq -r '.platforms["claude-code"].capabilities.sub_agents' "$L5_JSON")
CODEX_AGENTS=$(jq -r '.platforms["codex-cli"].capabilities.sub_agents' "$L5_JSON")
if [ "$CC_AGENTS" = "true" ] && [ "$CODEX_AGENTS" = "false" ]; then
  pass "Sub-agents capability matches Ontology.lean (CC=true, Codex=false)"
else
  fail "Sub-agents capability matches Ontology.lean (CC=$CC_AGENTS, Codex=$CODEX_AGENTS)"
fi

# 12.8: task_routing.deterministic always includes deterministic primitives
for platform in $(jq -r '.platforms | keys[]' "$L5_JSON"); do
  det_count=$(jq -r ".platforms[\"$platform\"].task_routing.deterministic | length" "$L5_JSON")
  if [ "$det_count" -gt 0 ]; then
    pass "Platform '$platform' has deterministic routing targets"
  else
    fail "Platform '$platform' has deterministic routing targets (empty)"
  fi
done

# 12.9: structural primitives are all deterministic=true
all_structural_det=true
for platform in $(jq -r '.platforms | keys[]' "$L5_JSON"); do
  non_det=$(jq -r ".platforms[\"$platform\"].enforcement_primitives.structural.primitives[]? | select(.deterministic == false) | .id" "$L5_JSON")
  if [ -n "$non_det" ]; then
    all_structural_det=false
    fail "Platform '$platform' structural primitive '$non_det' is not deterministic"
  fi
done
if [ "$all_structural_det" = true ]; then
  pass "All structural enforcement primitives are deterministic"
fi

# 12.10: Ontology.lean still references L5 platform comparison table
if grep -q "Action Space Comparison by Platform" "$ONTOLOGY"; then
  pass "Ontology.lean still contains L5 platform comparison (sync source)"
else
  fail "Ontology.lean L5 platform comparison not found (sync broken)"
fi

# --- Section 12b: Fallback Strategy Tests ---

echo ""
echo "--- Section 12b: Fallback Strategy Tests ---"

# 12b.1: fallback section exists
if jq -e '.fallback' "$L5_JSON" >/dev/null 2>&1; then
  pass "Fallback section exists"
else
  fail "Fallback section exists"
fi

# 12b.2: fallback has invariant
if jq -e '.fallback.invariant' "$L5_JSON" >/dev/null 2>&1; then
  pass "Fallback invariant defined"
else
  fail "Fallback invariant defined"
fi

# 12b.3: _default platform exists
if jq -e '.platforms["_default"]' "$L5_JSON" >/dev/null 2>&1; then
  pass "_default fallback platform exists"
else
  fail "_default fallback platform exists"
fi

# 12b.4: _default has all 3 enforcement layers
for layer in "structural" "procedural" "normative"; do
  if jq -e ".platforms[\"_default\"].enforcement_primitives[\"$layer\"]" "$L5_JSON" >/dev/null 2>&1; then
    pass "_default has '$layer' enforcement layer"
  else
    fail "_default has '$layer' enforcement layer"
  fi
done

# 12b.5: _default has all 3 task_routing entries
for class in "deterministic" "bounded" "judgmental"; do
  if jq -e ".platforms[\"_default\"].task_routing[\"$class\"]" "$L5_JSON" >/dev/null 2>&1; then
    pass "_default has task_routing for '$class'"
  else
    fail "_default has task_routing for '$class'"
  fi
done

# 12b.6: _default capabilities are all false/conservative
default_caps=$(jq -r '.platforms["_default"].capabilities | to_entries[] | select(.value == true) | .key' "$L5_JSON")
if [ -z "$default_caps" ]; then
  pass "_default capabilities are all conservative (no true values)"
else
  fail "_default has non-conservative capabilities: $default_caps"
fi

# 12b.7: fallback rules cover all 3 scenarios
rule_count=$(jq -r '.fallback.rules | length' "$L5_JSON")
if [ "$rule_count" -ge 3 ]; then
  pass "Fallback has >= 3 rules ($rule_count)"
else
  fail "Fallback has >= 3 rules (only $rule_count)"
fi

# 12b.8: l5-query.sh exists and is executable
if [ -f "scripts/l5-query.sh" ]; then
  pass "l5-query.sh exists"
else
  fail "l5-query.sh exists"
fi

# 12b.9: _default platform resolves unknown platforms (structural test via JSON)
default_routing=$(jq -r '.platforms["_default"].task_routing.deterministic | length' "$L5_JSON")
if [ "$default_routing" -gt 0 ]; then
  pass "_default platform provides deterministic routing ($default_routing targets)"
else
  fail "_default platform provides deterministic routing"
fi

echo ""
echo "=== L5 SSOT Results: $PASS passed, $FAIL failed (total: $TOTAL) ==="
exit "$FAIL"
