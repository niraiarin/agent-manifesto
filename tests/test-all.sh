#!/usr/bin/env bash
# 統合テスト: 全フェーズの受け入れテスト���実行
set -uo pipefail
BASE="$(git rev-parse --show-toplevel 2>/dev/null || echo /Users/nirarin/work/agent-manifesto)"
TOTAL_PASS=0; TOTAL_FAIL=0

# Preflight: staged-but-uncommitted ファイルがテスト結果を汚染していないか検証 (#432)
STAGED_UNCOMMITTED=$(cd "$BASE" && git diff --cached --name-only 2>/dev/null)
if [ -n "$STAGED_UNCOMMITTED" ]; then
  COUNT=$(echo "$STAGED_UNCOMMITTED" | wc -l | tr -d ' ')
  echo "========================================="
  echo "WARNING: $COUNT file(s) staged but not committed."
  echo "Tests may PASS due to disk state, not git state."
  echo "Run 'git status' to review. (#432)"
  echo "========================================="
  echo ""
fi

CRITICAL_PHASES="1 2"  # L1 safety (phase 1) + P2 verification (phase 2) は fail-fast

for phase in 1 2 3 4 5; do
  PHASE_FAIL=0
  for test_file in "$BASE/tests/phase$phase"/test-*.sh; do
    [ -f "$test_file" ] || continue
    echo ""
    OUTPUT=$(bash "$test_file" 2>&1)
    echo "$OUTPUT"
    P=$(echo "$OUTPUT" | grep -o '[0-9]* passed' | grep -o '[0-9]*')
    F=$(echo "$OUTPUT" | grep -o '[0-9]* failed' | grep -o '[0-9]*')
    TOTAL_PASS=$((TOTAL_PASS + ${P:-0}))
    TOTAL_FAIL=$((TOTAL_FAIL + ${F:-0}))
    PHASE_FAIL=$((PHASE_FAIL + ${F:-0}))
  done
  # G13: critical phase で failure があれば後続をスキップ
  if [ "$PHASE_FAIL" -gt 0 ] && echo "$CRITICAL_PHASES" | grep -qw "$phase"; then
    echo ""
    echo "*** Phase $phase (critical) failed with $PHASE_FAIL failure(s). Skipping remaining phases. ***"
    break
  fi
done

echo ""
echo "========================================="
echo "TOTAL: $TOTAL_PASS passed, $TOTAL_FAIL failed"
echo "========================================="
[ "$TOTAL_FAIL" -eq 0 ]
