#!/usr/bin/env bash
# Phase 1 受け入れテスト: 構造的テスト
# D5: テストは実装に先行する（テストファースト）
# これらのテストは L1 の構造的強制が存在することを確認する（決定論的）

set -uo pipefail

PASS=0
FAIL=0
BASE="/Users/nirarin/work/agent-manifesto"

echo "=== Phase 1: L1 Structural Tests ==="

# S1.1: settings.json が存在し、hooks セクションがある
echo -n "S1.1 settings.json exists with hooks... "
if [ -f "$BASE/.claude/settings.json" ] && jq -e '.hooks' "$BASE/.claude/settings.json" > /dev/null 2>&1; then
  echo "PASS"; ((PASS++))
else
  echo "FAIL"; ((FAIL++))
fi

# S1.2: PreToolUse Hook が登録されている
echo -n "S1.2 PreToolUse hooks registered... "
if jq -e '.hooks.PreToolUse | length > 0' "$BASE/.claude/settings.json" > /dev/null 2>&1; then
  echo "PASS"; ((PASS++))
else
  echo "FAIL"; ((FAIL++))
fi

# S1.3: Permissions deny リストが存在する
echo -n "S1.3 Permissions deny list exists... "
if jq -e '.permissions.deny | length > 0' "$BASE/.claude/settings.json" > /dev/null 2>&1; then
  echo "PASS"; ((PASS++))
else
  echo "FAIL"; ((FAIL++))
fi

# S1.4: L1 safety check hook スクリプトが存在し実行可能
echo -n "S1.4 l1-safety-check.sh exists and executable... "
if [ -x "$BASE/.claude/hooks/l1-safety-check.sh" ]; then
  echo "PASS"; ((PASS++))
else
  echo "FAIL"; ((FAIL++))
fi

# S1.5: L1 test tampering check hook が存在し実行可能
echo -n "S1.5 l1-test-tampering-check.sh exists and executable... "
if [ -x "$BASE/.claude/hooks/l1-test-tampering-check.sh" ]; then
  echo "PASS"; ((PASS++))
else
  echo "FAIL"; ((FAIL++))
fi

# S1.6: L1 secret check hook が存在し実行可能
echo -n "S1.6 l1-secret-check.sh exists and executable... "
if [ -x "$BASE/.claude/hooks/l1-secret-check.sh" ]; then
  echo "PASS"; ((PASS++))
else
  echo "FAIL"; ((FAIL++))
fi

# S1.7: L1 rules ファイルが存在する
echo -n "S1.7 L1 rules file exists... "
if [ -f "$BASE/.claude/rules/l1-safety.md" ]; then
  echo "PASS"; ((PASS++))
else
  echo "FAIL"; ((FAIL++))
fi

# S1.8: git push --force が deny リストに含まれている
echo -n "S1.8 git push --force in deny list... "
if jq -e '.permissions.deny[] | select(contains("push --force"))' "$BASE/.claude/settings.json" > /dev/null 2>&1; then
  echo "PASS"; ((PASS++))
else
  echo "FAIL"; ((FAIL++))
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
