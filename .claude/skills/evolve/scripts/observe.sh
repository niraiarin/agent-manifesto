#!/usr/bin/env bash
# observe.sh — Observer の計測スクリプト
# P4（可観測性）: 構造の現在状態を計測してJSON で出力する。
# 使い方: bash .claude/skills/evolve/scripts/observe.sh
set -uo pipefail
# Note: set -e を外している。grep が 0 マッチで exit 1 を返すと
# スクリプト全体が終了するため。各コマンドは || true で保護済み。

BASE="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
METRICS_DIR="$BASE/.claude/metrics"
LEAN_DIR="$BASE/lean-formalization"

echo "{"

# --- Lean 品質指標 ---
if [ -d "$LEAN_DIR/Manifest" ]; then
  AXIOM_COUNT=$(grep -r "^axiom [a-zA-Z_]" "$LEAN_DIR/Manifest/" --include="*.lean" 2>/dev/null | wc -l | tr -d ' ')
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
echo "  },"

# --- V1-V7 計測 ---
V5_FILE="$METRICS_DIR/v5-approvals.jsonl"
V7_FILE="$METRICS_DIR/v7-tasks.jsonl"
SESSIONS_FILE="$METRICS_DIR/sessions.jsonl"

# V5: Proposal Accuracy (approved / total)
if [ -f "$V5_FILE" ]; then
  V5_APPROVED=$(grep -c '"type":"approved"' "$V5_FILE" 2>/dev/null || echo "0")
  V5_TOTAL=$(wc -l < "$V5_FILE" | tr -d ' ')
  if [ "$V5_TOTAL" -gt 0 ] 2>/dev/null; then
    V5_RATE=$((V5_APPROVED * 100 / V5_TOTAL))
  else
    V5_RATE=0
  fi
else
  V5_APPROVED=0
  V5_TOTAL=0
  V5_RATE=0
fi

# V7: Task Design (completed tasks)
if [ -f "$V7_FILE" ]; then
  V7_COMPLETED=$(wc -l < "$V7_FILE" | tr -d ' ')
else
  V7_COMPLETED=0
fi

# V2: Context Efficiency (tool calls / sessions) with delta-based recent average
if [ -f "$SESSIONS_FILE" ]; then
  SESSION_COUNT=$(wc -l < "$SESSIONS_FILE" | tr -d ' ')
  if [ "$SESSION_COUNT" -gt 0 ] 2>/dev/null && [ "$TOOL_CALLS" -gt 0 ] 2>/dev/null; then
    V2_CALLS_PER_SESSION=$((TOOL_CALLS / SESSION_COUNT))
  else
    V2_CALLS_PER_SESSION=0
  fi
  # Compute per-session deltas from consecutive total_tool_calls values
  V2_RECENT_AVG=0
  if [ "$SESSION_COUNT" -gt 1 ] 2>/dev/null; then
    # Extract last 11 total_tool_calls to compute 10 deltas
    TOTALS=$(tail -11 "$SESSIONS_FILE" | jq -r '.total_tool_calls // empty' 2>/dev/null)
    PREV=""
    DELTA_SUM=0
    DELTA_COUNT=0
    for T in $TOTALS; do
      if [ -n "$PREV" ] 2>/dev/null; then
        D=$((T - PREV))
        if [ "$D" -ge 0 ] 2>/dev/null; then
          DELTA_SUM=$((DELTA_SUM + D))
          DELTA_COUNT=$((DELTA_COUNT + 1))
        fi
      fi
      PREV=$T
    done
    if [ "$DELTA_COUNT" -gt 0 ] 2>/dev/null; then
      V2_RECENT_AVG=$((DELTA_SUM / DELTA_COUNT))
    fi
  fi
else
  SESSION_COUNT=0
  V2_CALLS_PER_SESSION=0
  V2_RECENT_AVG=0
fi

# V4: Gate Pass Rate — Bash tool_use events = passed (PostToolUse only fires after PreToolUse pass)
# gate_blocked events are not yet instrumented in l1-safety-check.sh (L1 file guard prevents hook edits)
if [ -f "$TOOL_LOG" ]; then
  V4_PASSED=$(grep -c '"tool":"Bash"' "$TOOL_LOG" 2>/dev/null || true)
  V4_PASSED=${V4_PASSED:-0}
  V4_BLOCKED=$(grep -c '"event":"gate_blocked"' "$TOOL_LOG" 2>/dev/null || true)
  V4_BLOCKED=${V4_BLOCKED:-0}
  V4_TOTAL=$((V4_PASSED + V4_BLOCKED))
  if [ "$V4_TOTAL" -gt 0 ] 2>/dev/null; then
    V4_RATE=$((V4_PASSED * 100 / V4_TOTAL))
  else
    V4_RATE=100
  fi
else
  V4_PASSED=0
  V4_BLOCKED=0
  V4_TOTAL=0
  V4_RATE=100
fi

# V1: Skill Quality — provisional proxy (not benchmark.json-based)
SKILL_COUNT=$(find "$BASE/.claude/skills" -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
EVOLVE_SUCCESS=0
EVOLVE_TOTAL_RUNS=0
if [ -f "$HISTORY_FILE" ]; then
  EVOLVE_TOTAL_RUNS=$(wc -l < "$HISTORY_FILE" | tr -d ' ')
  EVOLVE_SUCCESS=$(grep -c '"result":"success"' "$HISTORY_FILE" 2>/dev/null || true)
  EVOLVE_SUCCESS=${EVOLVE_SUCCESS:-0}
fi
if [ "$EVOLVE_TOTAL_RUNS" -gt 0 ] 2>/dev/null; then
  EVOLVE_SUCCESS_RATE=$((EVOLVE_SUCCESS * 100 / EVOLVE_TOTAL_RUNS))
else
  EVOLVE_SUCCESS_RATE=0
fi
LEAN_HEALTH=1
if [ "${SORRY_COUNT:-0}" -gt 0 ] 2>/dev/null; then
  LEAN_HEALTH=0
fi

echo "  \"v1_v7\": {"
echo "    \"v1_skill_quality\": { \"evolve_success_rate\": $EVOLVE_SUCCESS_RATE, \"lean_health\": $LEAN_HEALTH, \"skill_count\": ${SKILL_COUNT:-0}, \"note\": \"provisional_proxy\" },"
echo "    \"v2_context_efficiency\": { \"tool_calls\": $TOOL_CALLS, \"sessions\": $SESSION_COUNT, \"calls_per_session\": $V2_CALLS_PER_SESSION, \"recent_avg\": $V2_RECENT_AVG },"
echo "    \"v3_output_quality\": \"not_available\","
echo "    \"v4_gate_pass_rate\": { \"passed\": $V4_PASSED, \"blocked\": $V4_BLOCKED, \"total\": $V4_TOTAL, \"rate_percent\": $V4_RATE },"
echo "    \"v5_proposal_accuracy\": { \"approved\": $V5_APPROVED, \"total\": $V5_TOTAL, \"rate_percent\": $V5_RATE },"
echo "    \"v6_knowledge_structure\": \"see_memory_and_lean_sections\","
echo "    \"v7_task_design\": { \"completed\": $V7_COMPLETED }"
echo "  }"

echo "}"
