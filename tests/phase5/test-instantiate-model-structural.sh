#!/usr/bin/env bash
# test-instantiate-model-structural.sh — /instantiate-model スキルの構造テスト
# Phase 5: 構造テスト
# Reference: #496
set -uo pipefail
PASS=0; FAIL=0
BASE="$(git rev-parse --show-toplevel 2>/dev/null || echo /Users/nirarin/work/agent-manifesto)"

echo "=== /instantiate-model Structure Tests ==="

check() {
  local name="$1" cond="$2"
  echo -n "  IM.$((PASS+FAIL+1)): $name... "
  if eval "$cond"; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL"; FAIL=$((FAIL+1)); fi
}

# ============================================================
# 1. File existence
# ============================================================
echo "--- 1. File Existence ---"

check "SKILL.md exists" \
  "[ -f '$BASE/.claude/skills/instantiate-model/SKILL.md' ]"

check "README.md exists" \
  "[ -f '$BASE/.claude/skills/instantiate-model/README.md' ]"

check "model-questioner agent exists" \
  "[ -f '$BASE/.claude/agents/model-questioner.md' ]"

# ============================================================
# 2. Frontmatter integrity
# ============================================================
echo "--- 2. Frontmatter ---"

SKILL="$BASE/.claude/skills/instantiate-model/SKILL.md"

check "frontmatter has name field" \
  "head -30 '$SKILL' | grep -q '^name:'"

check "frontmatter has user-invocable: true" \
  "head -30 '$SKILL' | grep -q 'user-invocable: true'"

check "frontmatter has dependencies section" \
  "head -30 '$SKILL' | grep -q 'dependencies:'"

check "frontmatter declares invokes" \
  "head -30 '$SKILL' | grep -q 'invokes:'"

check "frontmatter declares invoked_by" \
  "head -30 '$SKILL' | grep -q 'invoked_by:'"

check "frontmatter declares agents" \
  "head -30 '$SKILL' | grep -q 'agents:'"

# ============================================================
# 3. Dependency graph registration
# ============================================================
echo "--- 3. Dependency Graph ---"

DEPGRAPH="$BASE/.claude/skills/dependency-graph.yaml"

check "registered in dependency-graph.yaml" \
  "grep -q 'instantiate-model:' '$DEPGRAPH'"

# ============================================================
# 4. Traceability
# ============================================================
echo "--- 4. Traceability ---"

check "@traces annotation present" \
  "grep -q '@traces' '$SKILL'"

# ============================================================
# 5. Lean integration
# ============================================================
echo "--- 5. Lean Integration ---"

check "Models directory exists for instances" \
  "[ -d '$BASE/lean-formalization/Manifest/Models' ]"

check "EpistemicLayer.lean exists (dependency)" \
  "[ -f '$BASE/lean-formalization/Manifest/EpistemicLayer.lean' ]"

echo ""
echo "=== Results: $PASS/$((PASS+FAIL)) passed ==="
[ "$FAIL" -eq 0 ]
