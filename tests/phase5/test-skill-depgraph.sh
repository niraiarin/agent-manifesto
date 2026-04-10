#!/usr/bin/env bash
# Skill dependency graph tests
# Verifies: generate-skill-depgraph.sh, verify-skill-dependencies.sh, dependency-graph.yaml
# Reference: #346
set -uo pipefail
PASS=0; FAIL=0
BASE="$(git rev-parse --show-toplevel 2>/dev/null || echo /Users/nirarin/work/agent-manifesto)"
SKILLS_DIR="$BASE/.claude/skills"
GEN_SCRIPT="$BASE/scripts/generate-skill-depgraph.sh"
VERIFY_SCRIPT="$BASE/scripts/verify-skill-dependencies.sh"
GRAPH="$SKILLS_DIR/dependency-graph.yaml"
SCHEMA="$SKILLS_DIR/dependency-schema.yaml"

echo "=== Phase 5: Skill Dependency Graph Tests ==="

check() {
  local name="$1" cond="$2"
  echo -n "$name... "
  if eval "$cond"; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL"; FAIL=$((FAIL+1)); fi
}

# ============================================================
# Structure tests
# ============================================================
echo "--- Structure ---"

check "SDG.01: generate-skill-depgraph.sh exists" \
  "[ -f '$GEN_SCRIPT' ]"

check "SDG.02: verify-skill-dependencies.sh exists" \
  "[ -f '$VERIFY_SCRIPT' ]"

check "SDG.03: dependency-graph.yaml exists" \
  "[ -f '$GRAPH' ]"

check "SDG.04: dependency-schema.yaml exists" \
  "[ -f '$SCHEMA' ]"

# ============================================================
# Schema tests
# ============================================================
echo "--- Schema ---"

check "SDG.05: schema defines invokes field" \
  "grep -q 'invokes:' '$SCHEMA'"

check "SDG.06: schema defines invoked_by field" \
  "grep -q 'invoked_by:' '$SCHEMA'"

check "SDG.07: schema defines agents field" \
  "grep -q 'agents:' '$SCHEMA'"

check "SDG.08: schema has no data section (schema-only)" \
  "! grep -q '^skills:' '$SCHEMA'"

# ============================================================
# SKILL.md frontmatter tests
# ============================================================
echo "--- Frontmatter ---"

skill_count=0
deps_count=0
for skill_dir in "$SKILLS_DIR"/*/; do
  skill_md="$skill_dir/SKILL.md"
  [ -f "$skill_md" ] || continue
  skill_count=$((skill_count + 1))
  if awk 'BEGIN{n=0} /^---$/{n++; next} n==1{print} n>=2{exit}' "$skill_md" | grep -q 'dependencies:'; then
    deps_count=$((deps_count + 1))
  fi
done

check "SDG.09: all SKILL.md have dependencies frontmatter ($deps_count/$skill_count)" \
  "[ $deps_count -eq $skill_count ]"

# ============================================================
# Graph content tests
# ============================================================
echo "--- Graph content ---"

check "SDG.10: graph has skill_count field" \
  "grep -q 'skill_count:' '$GRAPH'"

check "SDG.11: graph has edges section" \
  "grep -q '^edges:' '$GRAPH'"

check "SDG.12: graph has summary section" \
  "grep -q '^summary:' '$GRAPH'"

check "SDG.13: graph has bidirectional detection" \
  "grep -q 'bidirectional:' '$GRAPH'"

graph_skill_count=$(grep 'skill_count:' "$GRAPH" | head -1 | awk '{print $2}')
check "SDG.14: graph skill_count matches filesystem ($graph_skill_count == $skill_count)" \
  "[ '$graph_skill_count' = '$skill_count' ]"

# ============================================================
# Verification script test
# ============================================================
echo "--- Verification ---"

VERIFY_OUTPUT=$(bash "$VERIFY_SCRIPT" 2>&1 || true)
check "SDG.15: verify-skill-dependencies.sh passes (0 failures)" \
  "echo \"\$VERIFY_OUTPUT\" | grep -q 'Failures: 0'"

# ============================================================
# Summary
# ============================================================
echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
exit $FAIL
