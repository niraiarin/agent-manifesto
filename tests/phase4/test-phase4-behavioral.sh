#!/usr/bin/env bash
set -uo pipefail
PASS=0; FAIL=0
BASE="$(git rev-parse --show-toplevel 2>/dev/null || echo /Users/nirarin/work/agent-manifesto)"
HOOKS="$BASE/.claude/hooks"

echo "=== Phase 4: P3 Behavioral Tests ==="

check_exit() {
  local name="$1" hook="$2" json="$3" expected="$4"
  echo -n "$name... "
  local code=$(echo "$json" | bash "$hook" 2>/dev/null; echo $?)
  if [ "$code" = "$expected" ]; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL (exit $code, expected $expected)"; FAIL=$((FAIL+1)); fi
}

check_stderr() {
  local name="$1" hook="$2" json="$3" pattern="$4"
  echo -n "$name... "
  local stderr=$(echo "$json" | bash "$hook" 2>&1 >/dev/null)
  if echo "$stderr" | grep -qi "$pattern"; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL (stderr missing '$pattern')"; FAIL=$((FAIL+1)); fi
}

# B4.1: 通常のコミットはスルー
check_exit "B4.1 Non-structural commit passes" \
  "$HOOKS/p3-compatibility-check.sh" \
  '{"tool_input":{"command":"git commit -m \"fix typo\""}}' "0"

# B4.2: 分類付きコミットは分類キーワードを検出して警告しない
check_exit "B4.2 Classified commit accepted" \
  "$HOOKS/p3-compatibility-check.sh" \
  '{"tool_input":{"command":"git commit -m \"conservative extension: add rule\""}}' "0"

# B4.3: git status はスキップ
check_exit "B4.3 Non-commit skipped" \
  "$HOOKS/p3-compatibility-check.sh" \
  '{"tool_input":{"command":"git status"}}' "0"

# B4.4: 分類キーワードがコマンド全体から検出できる
check_exit "B4.4 Breaking change keyword detected" \
  "$HOOKS/p3-compatibility-check.sh" \
  '{"tool_input":{"command":"git commit -m \"breaking change: remove old hook\""}}' "0"

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
