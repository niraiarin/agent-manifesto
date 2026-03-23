#!/usr/bin/env bash
# observe.sh — Observer の計測スクリプト
# P4（可観測性）: 構造の現在状態を計測してJSON で出力する。
# 使い方: bash .claude/skills/evolve/scripts/observe.sh
set -euo pipefail

BASE="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
METRICS_DIR="$BASE/.claude/metrics"
LEAN_DIR="$BASE/lean-formalization"

echo "{"

# --- Lean 品質指標 ---
if [ -d "$LEAN_DIR/Manifest" ]; then
  AXIOM_COUNT=$(grep -r "^axiom " "$LEAN_DIR/Manifest/" --include="*.lean" 2>/dev/null | grep -v "axiom は" | wc -l | tr -d ' ')
  THEOREM_COUNT=$(grep -r "^theorem " "$LEAN_DIR/Manifest/" --include="*.lean" 2>/dev/null | wc -l | tr -d ' ')
  SORRY_COUNT=$(grep -rn "^\s*sorry\s*$\|:=\s*sorry" "$LEAN_DIR/Manifest/" --include="*.lean" 2>/dev/null | grep -v -- "--" | grep -v "/-" | wc -l | tr -d ' ')
  MODULE_COUNT=$(find "$LEAN_DIR/Manifest" -name "*.lean" 2>/dev/null | wc -l | tr -d ' ')
  echo "  \"lean\": {"
  echo "    \"axioms\": $AXIOM_COUNT,"
  echo "    \"theorems\": $THEOREM_COUNT,"
  echo "    \"sorry\": $SORRY_COUNT,"
  echo "    \"modules\": $MODULE_COUNT"
  echo "  },"
fi

# --- テスト結果 ---
TEST_OUTPUT=$(bash "$BASE/tests/test-all.sh" 2>&1 || true)
PASS=$(echo "$TEST_OUTPUT" | grep -o 'TOTAL: [0-9]* passed' | grep -o '[0-9]*' || echo "0")
FAIL=$(echo "$TEST_OUTPUT" | grep -o '[0-9]* failed' | tail -1 | grep -o '[0-9]*' || echo "0")
echo "  \"tests\": {"
echo "    \"passed\": ${PASS:-0},"
echo "    \"failed\": ${FAIL:-0}"
echo "  },"

# --- git 停滞検出 ---
STALE_FILES=""
for f in "$BASE"/.claude/skills/*/SKILL.md "$BASE"/.claude/agents/*.md "$BASE"/.claude/agents/*/AGENT.md; do
  [ -f "$f" ] || continue
  LAST_MODIFIED=$(git -C "$BASE" log -1 --format=%at -- "$f" 2>/dev/null || echo "0")
  NOW=$(date +%s)
  DAYS_AGO=$(( (NOW - LAST_MODIFIED) / 86400 ))
  if [ "$DAYS_AGO" -gt 30 ] 2>/dev/null; then
    REL_PATH="${f#$BASE/}"
    # JSON-safe: escape backslashes and double quotes
    SAFE_PATH=$(echo "$REL_PATH" | sed 's/\\/\\\\/g; s/"/\\"/g')
    STALE_FILES="$STALE_FILES\"$SAFE_PATH ($DAYS_AGO days)\", "
  fi
done
echo "  \"stale_files\": [$(echo "$STALE_FILES" | sed 's/, $//')],"

# --- evolve 履歴 ---
HISTORY_FILE="$METRICS_DIR/evolve-history.jsonl"
if [ -f "$HISTORY_FILE" ]; then
  EVOLVE_RUNS=$(wc -l < "$HISTORY_FILE" | tr -d ' ')
  LAST_RUN=$(tail -1 "$HISTORY_FILE" 2>/dev/null | grep -o '"timestamp":"[^"]*"' | head -1 | cut -d'"' -f4 || echo "never")
else
  EVOLVE_RUNS=0
  LAST_RUN="never"
fi
echo "  \"evolve_history\": {"
echo "    \"total_runs\": $EVOLVE_RUNS,"
echo "    \"last_run\": \"$LAST_RUN\""
echo "  },"

# --- metrics ログ ---
TOOL_LOG="$METRICS_DIR/tool-usage.jsonl"
if [ -f "$TOOL_LOG" ]; then
  TOOL_CALLS=$(wc -l < "$TOOL_LOG" | tr -d ' ')
else
  TOOL_CALLS=0
fi
echo "  \"metrics\": {"
echo "    \"tool_calls\": $TOOL_CALLS"
echo "  }"

echo "}"
