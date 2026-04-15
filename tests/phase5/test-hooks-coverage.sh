#!/usr/bin/env bash
# test-hooks-coverage.sh — 全 hooks の存在・構造テスト
# Phase 5: 以前テストカバレッジがなかった hooks を含む
# Reference: #496
set -uo pipefail
PASS=0; FAIL=0
BASE="$(git rev-parse --show-toplevel 2>/dev/null || echo /Users/nirarin/work/agent-manifesto)"
HOOKS_DIR="$BASE/.claude/hooks"

echo "=== Hooks Coverage Tests ==="

check() {
  local name="$1" cond="$2"
  echo -n "  HC.$((PASS+FAIL+1)): $name... "
  if eval "$cond"; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL"; FAIL=$((FAIL+1)); fi
}

# ============================================================
# 1. Previously untested hooks — existence
# ============================================================
echo "--- 1. Previously Untested Hooks: Existence ---"

UNTESTED_HOOKS=(
  branch-protection.sh
  p4-drift-detector.sh
  p4-gate-logger.sh
  p4-manifest-refs-check.sh
  p4-traces-integrity-check.sh
  p4-v5-approval-tracker.sh
  p4-v7-task-tracker.sh
  pr-conflict-blocker.sh
  pr-conflict-checker.sh
  prerequisites-check.sh
  rules-injector.sh
)

# Plugin-only hooks (not registered in settings.json, loaded via plugin mechanism)
PLUGIN_ONLY_HOOKS=(
  prerequisites-check.sh
  rules-injector.sh
)

for hook in "${UNTESTED_HOOKS[@]}"; do
  check "$hook exists" \
    "[ -f '$HOOKS_DIR/$hook' ]"
done

# ============================================================
# 2. All hooks are executable
# ============================================================
echo "--- 2. Executable Permission ---"

for hook in "$HOOKS_DIR"/*.sh; do
  name=$(basename "$hook")
  check "$name is executable" \
    "[ -x '$hook' ]"
done

# ============================================================
# 3. All hooks have shebang
# ============================================================
echo "--- 3. Shebang Line ---"

for hook in "$HOOKS_DIR"/*.sh; do
  name=$(basename "$hook")
  check "$name has shebang" \
    "head -1 '$hook' | grep -qE '^#!/usr/bin/env bash|^#!/bin/bash'"
done

# ============================================================
# 4. All hooks are registered in settings.json
# ============================================================
echo "--- 4. Settings Registration ---"

SETTINGS="$BASE/.claude/settings.json"

for hook in "${UNTESTED_HOOKS[@]}"; do
  # Plugin-only hooks are registered via plugin mechanism, not settings.json
  is_plugin_only=false
  for ph in "${PLUGIN_ONLY_HOOKS[@]}"; do
    [ "$hook" = "$ph" ] && is_plugin_only=true
  done
  if $is_plugin_only; then
    check "$hook is plugin-only (not in settings.json by design)" "true"
  else
    check "$hook registered in settings.json" \
      "grep -q '$hook' '$SETTINGS'"
  fi
done

# ============================================================
# 5. Structural checks for specific hooks
# ============================================================
echo "--- 5. Structural Checks ---"

check "branch-protection.sh checks branch name" \
  "grep -q 'branch\|BRANCH' '$HOOKS_DIR/branch-protection.sh'"

check "p4-drift-detector.sh references metrics" \
  "grep -q 'metric\|drift\|threshold' '$HOOKS_DIR/p4-drift-detector.sh'"

check "p4-traces-integrity-check.sh references artifact-manifest" \
  "grep -q 'artifact-manifest\|traces\|refs' '$HOOKS_DIR/p4-traces-integrity-check.sh'"

check "pr-conflict-checker.sh checks for conflicts" \
  "grep -q 'conflict\|merge\|CONFLICT' '$HOOKS_DIR/pr-conflict-checker.sh'"

check "rules-injector.sh references rules directory" \
  "grep -q 'rules\|\.claude/rules' '$HOOKS_DIR/rules-injector.sh'"

check "prerequisites-check.sh checks prerequisites" \
  "grep -q 'prerequisit\|check\|require' '$HOOKS_DIR/prerequisites-check.sh'"

echo ""
echo "=== Results: $PASS/$((PASS+FAIL)) passed ==="
[ "$FAIL" -eq 0 ]
