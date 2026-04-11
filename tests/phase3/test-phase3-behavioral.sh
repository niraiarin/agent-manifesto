#!/usr/bin/env bash
set -uo pipefail
PASS=0; FAIL=0
BASE="$(git rev-parse --show-toplevel 2>/dev/null || echo /Users/nirarin/work/agent-manifesto)"
HOOKS="$BASE/.claude/hooks"

echo "=== Phase 3: P4 Behavioral Tests ==="

# B3.1: メトリクスコレクターがログを書き込む
echo -n "B3.1 Metrics collector writes JSONL... "
TMPLOG="${TMPDIR:-/tmp}/test-metrics-$$.log"
trap 'rm -f "$TMPLOG"' EXIT
BEFORE=0
echo '{"tool_name":"Bash","tool_use_id":"test123","session_id":"s1"}' | METRICS_LOG="$TMPLOG" bash "$HOOKS/p4-metrics-collector.sh" 2>/dev/null
AFTER=$(wc -l < "$TMPLOG" 2>/dev/null | tr -d ' ')
if [ "$AFTER" -gt "$BEFORE" ]; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL"; FAIL=$((FAIL+1)); fi

# B3.2: ログのJSONが有効
echo -n "B3.2 Log entry is valid JSON... "
LAST_LINE=$(tail -1 "$TMPLOG")
if echo "$LAST_LINE" | jq . >/dev/null 2>&1; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL"; FAIL=$((FAIL+1)); fi

# B3.3: ログにツール名が記録されている
echo -n "B3.3 Log contains tool name... "
if echo "$LAST_LINE" | jq -e '.tool == "Bash"' >/dev/null 2>&1; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL"; FAIL=$((FAIL+1)); fi

# B3.4: ログにタイムスタンプがある
echo -n "B3.4 Log contains timestamp... "
if echo "$LAST_LINE" | jq -e '.timestamp' >/dev/null 2>&1; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL"; FAIL=$((FAIL+1)); fi

# B3.5: ゲートロガーがセッションサマリを書く
echo -n "B3.5 Gate logger writes session summary... "
echo '{}' | bash "$HOOKS/p4-gate-logger.sh" 2>/dev/null
if [ -f "$BASE/.claude/metrics/sessions.jsonl" ]; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL"; FAIL=$((FAIL+1)); fi

# B3.6: 複数エントリの蓄積
echo -n "B3.6 Multiple entries accumulate... "
echo '{"tool_name":"Edit","tool_use_id":"test456","session_id":"s1"}' | METRICS_LOG="$TMPLOG" bash "$HOOKS/p4-metrics-collector.sh" 2>/dev/null
echo '{"tool_name":"Read","tool_use_id":"test789","session_id":"s1"}' | METRICS_LOG="$TMPLOG" bash "$HOOKS/p4-metrics-collector.sh" 2>/dev/null
COUNT=$(wc -l < "$TMPLOG" | tr -d ' ')
if [ "$COUNT" -ge 3 ]; then echo "PASS ($COUNT entries)"; PASS=$((PASS+1)); else echo "FAIL ($COUNT entries)"; FAIL=$((FAIL+1)); fi

echo ""
echo "--- H5 Doc Lint Hook ---"
echo -n "B3.7 h5-doc-lint: non-commit command passes... "
CODE=$(echo '{"tool_input":{"command":"ls -la"}}' | bash "$HOOKS/h5-doc-lint.sh" >/dev/null 2>/dev/null; echo $?)
if [ "$CODE" -eq 0 ]; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL (exit $CODE)"; FAIL=$((FAIL+1)); fi

echo -n "B3.8 h5-doc-lint: commit without Lean files passes... "
CODE=$(echo '{"tool_input":{"command":"git commit -m \"test\""}}' | bash "$HOOKS/h5-doc-lint.sh" >/dev/null 2>/dev/null; echo $?)
if [ "$CODE" -eq 0 ]; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL (exit $CODE)"; FAIL=$((FAIL+1)); fi

echo ""
echo "--- P3 Axiom Evidence Check Hook ---"
echo -n "B3.9 p3-axiom-evidence: non-commit command passes... "
CODE=$(echo '{"tool_input":{"command":"git status"}}' | bash "$HOOKS/p3-axiom-evidence-check.sh" >/dev/null 2>/dev/null; echo $?)
if [ "$CODE" -eq 0 ]; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL (exit $CODE)"; FAIL=$((FAIL+1)); fi

echo -n "B3.10 p3-axiom-evidence: commit without axiom files passes... "
CODE=$(echo '{"tool_input":{"command":"git commit -m \"test\""}}' | bash "$HOOKS/p3-axiom-evidence-check.sh" >/dev/null 2>/dev/null; echo $?)
if [ "$CODE" -eq 0 ]; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL (exit $CODE)"; FAIL=$((FAIL+1)); fi

echo ""
echo "--- P4 Sync Counts Check Hook ---"
echo -n "B3.11 p4-sync-counts: non-commit command passes... "
CODE=$(echo '{"tool_input":{"command":"echo hello"}}' | bash "$HOOKS/p4-sync-counts-check.sh" >/dev/null 2>/dev/null; echo $?)
if [ "$CODE" -eq 0 ]; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL (exit $CODE)"; FAIL=$((FAIL+1)); fi

echo -n "B3.12 p4-sync-counts: commit with synced counts passes... "
CODE=$(echo '{"tool_input":{"command":"git commit -m \"test\""}}' | bash "$HOOKS/p4-sync-counts-check.sh" >/dev/null 2>/dev/null; echo $?)
if [ "$CODE" -eq 0 ]; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL (exit $CODE)"; FAIL=$((FAIL+1)); fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
