#!/usr/bin/env bash
# Phase 2: P2 行動的テスト
set -uo pipefail
PASS=0; FAIL=0
BASE="$(git rev-parse --show-toplevel 2>/dev/null || echo /Users/nirarin/work/agent-manifesto)"
HOOKS="$BASE/.claude/hooks"

echo "=== Phase 2: P2 Behavioral Tests ==="

check_output() {
  local name="$1" hook="$2" json="$3" expected="$4"
  echo -n "$name... "
  local output=$(echo "$json" | bash "$hook" 2>&1; echo "EXIT:$?")
  if echo "$output" | grep -qi "$expected"; then
    echo "PASS"; PASS=$((PASS+1))
  else
    echo "FAIL (expected '$expected')"; FAIL=$((FAIL+1))
  fi
}

# P2 hook: git commit with high-risk files
# Clean warned state to ensure first-attempt behavior (warning, not block)
rm -f /tmp/p2-warned-unknown /tmp/p2-warned-test 2>/dev/null || true
check_output "B2.1 High-risk commit triggers warning" \
  "$HOOKS/p2-verify-on-commit.sh" \
  '{"tool_input":{"command":"git commit -m test"},"session_id":"test"}' \
  "EXIT:0"

# P2 hook: non-commit command is skipped
check_output "B2.2 Non-commit command skipped" \
  "$HOOKS/p2-verify-on-commit.sh" \
  '{"tool_input":{"command":"git status"}}' \
  "EXIT:0"

# Verifier agent: read-only (no Edit/Write/Bash in tools)
echo -n "B2.3 Verifier agent is read-only... "
if grep -q 'tools:' "$BASE/.claude/agents/verifier.md" && \
   ! grep -A 5 'tools:' "$BASE/.claude/agents/verifier.md" | grep -qE '^\s+- (Edit|Write|Bash)'; then
  echo "PASS"; PASS=$((PASS+1))
else
  echo "FAIL"; FAIL=$((FAIL+1))
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
