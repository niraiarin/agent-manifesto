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
  AXIOM_COUNT=$(grep "^axiom [a-z]" "$LEAN_DIR"/Manifest/*.lean 2>/dev/null | wc -l | tr -d ' ')
  THEOREM_COUNT=$(grep "^theorem " "$LEAN_DIR"/Manifest/*.lean "$LEAN_DIR"/Manifest/Framework/*.lean 2>/dev/null | wc -l | tr -d ' ')
  FOUNDATION_THEOREMS=$(grep -r "^theorem " "$LEAN_DIR/Manifest/Foundation/" --include="*.lean" 2>/dev/null | wc -l | tr -d ' ')
  FOUNDATION_THEOREMS=${FOUNDATION_THEOREMS:-0}
  SORRY_COUNT=$(grep -rn "^\s*sorry\s*$\|:=\s*sorry" "$LEAN_DIR/Manifest/" --include="*.lean" --exclude-dir=Models 2>/dev/null | grep -v -- "--" | grep -v "/-" | wc -l | tr -d ' ')
  MODULE_COUNT=$(find "$LEAN_DIR/Manifest" -name "*.lean" -not -path "*/Models/*" 2>/dev/null | wc -l | tr -d ' ')
  # warnings (lake build output)
  WARNING_COUNT=$(cd "$LEAN_DIR" && lake build Manifest 2>&1 | grep -c "warning" || true)
  WARNING_COUNT=${WARNING_COUNT:-0}
  # compression ratio (theorems * 100 / axioms, 100x scale)
  if [ "${AXIOM_COUNT:-0}" -gt 0 ] 2>/dev/null; then
    COMPRESSION_RATIO=$((THEOREM_COUNT * 100 / AXIOM_COUNT))
  else
    COMPRESSION_RATIO=0
  fi
  # De Bruijn factor (formal_lines * 100 / informal_lines, 100x scale)
  FORMAL_LINES=$(find "$LEAN_DIR/Manifest" -name "*.lean" -not -path "*/Models/*" -exec cat {} + 2>/dev/null | wc -l | tr -d ' ')
  FORMAL_LINES=${FORMAL_LINES:-0}
  # test-axiom-quality.sh と統一: 4 ファイル（manifesto + docs 3 ファイル）
  INFORMAL_LINES=$(cat "$BASE/archive/manifesto.md" "$BASE/docs/design-development-foundation.md" "$BASE/docs/formal-derivation-procedure.md" "$BASE/docs/mathematical-logic-terminology.md" 2>/dev/null | wc -l | tr -d ' ')
  INFORMAL_LINES=${INFORMAL_LINES:-0}
  if [ "${INFORMAL_LINES:-0}" -gt 0 ] 2>/dev/null; then
    DE_BRUIJN=$((FORMAL_LINES * 100 / INFORMAL_LINES))
  else
    DE_BRUIJN=0
  fi
  echo "  \"lean\": {"
  echo "    \"axioms\": $AXIOM_COUNT,"
  echo "    \"theorems\": $THEOREM_COUNT,"
  echo "    \"sorry\": $SORRY_COUNT,"
  echo "    \"modules\": $MODULE_COUNT,"
  echo "    \"warnings\": $WARNING_COUNT,"
  echo "    \"compression_ratio\": $COMPRESSION_RATIO,"
  echo "    \"de_bruijn_factor\": $DE_BRUIJN,"
  echo "    \"foundation_theorems\": $FOUNDATION_THEOREMS"
  echo "  },"
fi

# --- テスト結果 ---
TEST_OUTPUT=$(bash "$BASE/tests/test-all.sh" 2>&1 || true)
TEST_PASSED=$(echo "$TEST_OUTPUT" | grep -o 'TOTAL: [0-9]* passed' | grep -o '[0-9]*' || echo "0")
TEST_FAILED=$(echo "$TEST_OUTPUT" | grep -o '[0-9]* failed' | tail -1 | grep -o '[0-9]*' || echo "0")
echo "  \"tests\": {"
echo "    \"passed\": ${TEST_PASSED:-0},"
echo "    \"failed\": ${TEST_FAILED:-0}"
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
  # 最新 Run 番号の取得（run フィールドが整数のエントリの最大値）
  EVOLVE_RUNS=$(jq -r '.run // empty' "$HISTORY_FILE" 2>/dev/null | grep -E '^[0-9]+$' | sort -n | tail -1)
  EVOLVE_RUNS=${EVOLVE_RUNS:-0}
  LAST_RUN=$(tail -1 "$HISTORY_FILE" 2>/dev/null | jq -r '.timestamp // empty' 2>/dev/null)
  LAST_RUN=${LAST_RUN:-never}
  # phases フィールド集計（標準スキーマ対応エントリのみ）
  PHASES_OBSERVER_SUM=$(jq -r '.phases.observer.findings_count // 0' "$HISTORY_FILE" 2>/dev/null | awk '{s+=$1} END{print s+0}')
  PHASES_HYPO_SUM=$(jq -r '.phases.hypothesizer.proposals_count // 0' "$HISTORY_FILE" 2>/dev/null | awk '{s+=$1} END{print s+0}')
  PHASES_VERIFIER_PASS_SUM=$(jq -r '.phases.verifier.pass_count // 0' "$HISTORY_FILE" 2>/dev/null | awk '{s+=$1} END{print s+0}')
  PHASES_VERIFIER_FAIL_SUM=$(jq -r '.phases.verifier.fail_count // 0' "$HISTORY_FILE" 2>/dev/null | awk '{s+=$1} END{print s+0}')
  PHASES_NULL_COUNT=$(jq -s '[.[] | select((.phases == null) or (.phases.observer.findings_count == null))] | length' "$HISTORY_FILE" 2>/dev/null || echo 0)
else
  EVOLVE_RUNS=0
  LAST_RUN="never"
  PHASES_NULL_COUNT=0
fi
echo "  \"evolve_history\": {"
echo "    \"latest_run_number\": $EVOLVE_RUNS,"
echo "    \"total_entries\": $(wc -l < "$HISTORY_FILE"),"
echo "    \"last_run\": \"$LAST_RUN\","
echo "    \"phases_totals\": {"
echo "      \"observer_findings\": ${PHASES_OBSERVER_SUM:-0},"
echo "      \"hypothesizer_proposals\": ${PHASES_HYPO_SUM:-0},"
echo "      \"verifier_pass\": ${PHASES_VERIFIER_PASS_SUM:-0},"
echo "      \"verifier_fail\": ${PHASES_VERIFIER_FAIL_SUM:-0},"
echo "      \"null_entries_count\": ${PHASES_NULL_COUNT:-0}"
echo "    }"
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
# v5-approvals.jsonl schema: {"timestamp":..., "event":"v5_approval", "result":"approved"|"rejected", "session":...}
# Written by: .claude/hooks/p4-v5-approval-tracker.sh (UserPromptSubmit hook)
# Mapping: .result == "approved" → V5_APPROVED count, total lines → V5_TOTAL
# 計測単位: UserPromptSubmit hook が承認パターンに一致した応答数
# PRIMARY: jq-based (authoritative)
# CROSSCHECK: grep-based (schema drift detection)
if [ -f "$V5_FILE" ]; then
  V5_APPROVED=$(jq -r 'select(.result == "approved") | .result' "$V5_FILE" 2>/dev/null | wc -l | tr -d ' ')
  V5_APPROVED=${V5_APPROVED:-0}
  V5_TOTAL=$(wc -l < "$V5_FILE" 2>/dev/null | tr -d ' ')
  V5_TOTAL=${V5_TOTAL:-0}
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

# V5 grep crosscheck (detect schema drift)
# jq-based (PRIMARY) と grep-based (CROSSCHECK) の不一致はスキーマドリフトを示す
# 不一致時: v5-approvals.jsonl のフォーマットが変化した可能性。schema_drift=true を出力
if [ -f "$V5_FILE" ]; then
  V5_GREP_APPROVED=$(grep -c '"result":"approved"' "$V5_FILE" 2>/dev/null || echo 0)
  V5_GREP_APPROVED=${V5_GREP_APPROVED:-0}
  if [ "$V5_APPROVED" -ne "$V5_GREP_APPROVED" ] 2>/dev/null; then
    V5_SCHEMA_DRIFT="true"
  else
    V5_SCHEMA_DRIFT="false"
  fi
else
  V5_GREP_APPROVED=0
  V5_SCHEMA_DRIFT="false"
fi

# V7: Task Design (completed tasks + quality indicators)
if [ -f "$V7_FILE" ]; then
  V7_COMPLETED=$(wc -l < "$V7_FILE" | tr -d ' ')
  V7_UNIQUE_SUBJECTS=$(jq -r '.subject // empty' "$V7_FILE" 2>/dev/null | sort -u | wc -l | tr -d ' ')
  V7_UNIQUE_SUBJECTS=${V7_UNIQUE_SUBJECTS:-0}
  V7_TEAMWORK=$(jq -r 'select(.teammate != null and .teammate != "") | .teammate' "$V7_FILE" 2>/dev/null | wc -l | tr -d ' ')
  V7_TEAMWORK=${V7_TEAMWORK:-0}
  if [ "$V7_COMPLETED" -gt 0 ] 2>/dev/null; then
    V7_TEAMWORK_PERCENT=$((V7_TEAMWORK * 100 / V7_COMPLETED))
  else
    V7_TEAMWORK_PERCENT=0
  fi
else
  V7_COMPLETED=0
  V7_UNIQUE_SUBJECTS=0
  V7_TEAMWORK=0
  V7_TEAMWORK_PERCENT=0
fi

# V2: Context Efficiency — primary: recent_avg (delta-based), baseline: cumulative_avg
# cumulative_avg = mean of all session deltas with delta > MIN_SESSION_DELTA (full history).
# raw_cumulative_avg = total_tool_calls / session_count (legacy, kept for transition period).
if [ -f "$SESSIONS_FILE" ]; then
  SESSION_COUNT=$(wc -l < "$SESSIONS_FILE" | tr -d ' ')
  # raw_cumulative_avg: legacy value (TOOL_CALLS / SESSION_COUNT), kept for transition comparison
  if [ "$SESSION_COUNT" -gt 0 ] 2>/dev/null && [ "$TOOL_CALLS" -gt 0 ] 2>/dev/null; then
    V2_RAW_CUMULATIVE=$((TOOL_CALLS / SESSION_COUNT))
  else
    V2_RAW_CUMULATIVE=0
  fi
  # Compute per-session deltas from consecutive total_tool_calls values
  # V2 uses MEDIAN of recent deltas (robust to outliers like evolve sessions).
  # V2_RECENT_AVG = median of last 10 session deltas (primary metric).
  # V2_CALLS_PER_SESSION = mean of all filtered deltas (full history, microSession-excluded baseline).
  # These are DIFFERENT values. Do not confuse them.
  # MIN_SESSION_DELTA: micro-sessions (e.g., single /metrics invocations) with <= this
  # delta are excluded from V2 median and cumulative_avg to prevent downward bias.
  MIN_SESSION_DELTA=3
  V2_RECENT_AVG=0
  V2_CALLS_PER_SESSION=0
  RAW_DELTA_COUNT=0
  FILTERED_DELTA_COUNT=0
  ALL_FILTERED_SUM=0
  ALL_FILTERED_COUNT=0
  if [ "$SESSION_COUNT" -gt 1 ] 2>/dev/null; then
    # --- Full history pass: compute cumulative_avg from all deltas (filtered) ---
    ALL_TOTALS=$(jq -r '.total_tool_calls // empty' "$SESSIONS_FILE" 2>/dev/null)
    PREV_FULL=""
    for T in $ALL_TOTALS; do
      if [ -n "$PREV_FULL" ] 2>/dev/null; then
        D=$((T - PREV_FULL))
        if [ "$D" -ge 0 ] 2>/dev/null; then
          # Exclude micro-sessions from cumulative_avg
          if [ "$D" -gt "$MIN_SESSION_DELTA" ] 2>/dev/null; then
            ALL_FILTERED_SUM=$((ALL_FILTERED_SUM + D))
            ALL_FILTERED_COUNT=$((ALL_FILTERED_COUNT + 1))
          fi
        fi
      fi
      PREV_FULL=$T
    done
    if [ "$ALL_FILTERED_COUNT" -gt 0 ] 2>/dev/null; then
      V2_CALLS_PER_SESSION=$((ALL_FILTERED_SUM / ALL_FILTERED_COUNT))
    fi
    # --- Recent pass: compute recent_avg from last 10 deltas (filtered) ---
    # Extract last 11 total_tool_calls to compute 10 deltas
    TOTALS=$(tail -11 "$SESSIONS_FILE" | jq -r '.total_tool_calls // empty' 2>/dev/null)
    PREV=""
    DELTAS=()
    for T in $TOTALS; do
      if [ -n "$PREV" ] 2>/dev/null; then
        D=$((T - PREV))
        if [ "$D" -ge 0 ] 2>/dev/null; then
          RAW_DELTA_COUNT=$((RAW_DELTA_COUNT + 1))
          # Skip micro-sessions (delta <= MIN_SESSION_DELTA)
          if [ "$D" -gt "$MIN_SESSION_DELTA" ] 2>/dev/null; then
            DELTAS+=("$D")
            FILTERED_DELTA_COUNT=$((FILTERED_DELTA_COUNT + 1))
          fi
        fi
      fi
      PREV=$T
    done
    DELTA_COUNT=${#DELTAS[@]}
    if [ "$DELTA_COUNT" -gt 0 ] 2>/dev/null; then
      # Sort deltas and take median (robust to outliers)
      SORTED=($(printf '%s\n' "${DELTAS[@]}" | sort -n))
      MID=$((DELTA_COUNT / 2))
      if [ $((DELTA_COUNT % 2)) -eq 0 ] 2>/dev/null; then
        # Even count: average of two middle values
        V2_RECENT_AVG=$(( (SORTED[MID-1] + SORTED[MID]) / 2 ))
      else
        # Odd count: middle value
        V2_RECENT_AVG=${SORTED[$MID]}
      fi
    fi
    # Edge case: all deltas filtered → V2_RECENT_AVG stays 0 (not an error)
  fi
else
  SESSION_COUNT=0
  V2_RAW_CUMULATIVE=0
  V2_CALLS_PER_SESSION=0
  V2_RECENT_AVG=0
fi

# V4: Gate Pass Rate — Bash tool_use events = passed (PostToolUse only fires after PreToolUse pass)
# gate_blocked events are logged by l1-safety-check.sh and l1-file-guard.sh (PR #76, Run 63)
if [ -f "$TOOL_LOG" ]; then
  V4_PASSED=$(grep -c '"tool":"Bash"' "$TOOL_LOG" 2>/dev/null || true)
  V4_PASSED=${V4_PASSED:-0}
  V4_BLOCKED_ALL=$(grep -c '"event":"gate_blocked"' "$TOOL_LOG" 2>/dev/null || true)
  V4_BLOCKED_ALL=${V4_BLOCKED_ALL:-0}
  V4_BLOCKED=$(jq -s '[.[] | select(.event == "gate_blocked" and .session_id != "unknown")] | length' "$TOOL_LOG" 2>/dev/null || echo "0")
  V4_BLOCKED=${V4_BLOCKED:-0}
  V4_BLOCKED_EXCLUDED=$((V4_BLOCKED_ALL - V4_BLOCKED))
  V4_TOTAL=$((V4_PASSED + V4_BLOCKED))
  if [ "$V4_TOTAL" -gt 0 ] 2>/dev/null; then
    V4_RATE=$((V4_PASSED * 100 / V4_TOTAL))
  else
    V4_RATE=100
  fi
else
  V4_PASSED=0
  V4_BLOCKED=0
  V4_BLOCKED_EXCLUDED=0
  V4_TOTAL=0
  V4_RATE=100
fi

# V1: Skill Quality — GQM-based measurement (benchmark.json schema)
# Q3 (operational stability): evolve success rate (reclassified from primary to process metric)
SKILL_COUNT=$(find "$BASE/.claude/skills" -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
EVOLVE_SUCCESS=0
EVOLVE_TOTAL_RUNS=0
if [ -f "$HISTORY_FILE" ]; then
  # human_feedback/observation エントリを除外し、実際の evolve 実行のみをカウント
  EVOLVE_TOTAL_RUNS=$(jq -r 'select(.result != "observation") | .result' "$HISTORY_FILE" 2>/dev/null | wc -l | tr -d ' ')
  EVOLVE_TOTAL_RUNS=${EVOLVE_TOTAL_RUNS:-0}
  EVOLVE_SUCCESS=$(jq -r 'select(.result=="success") | .result' "$HISTORY_FILE" 2>/dev/null | wc -l | tr -d ' ')
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

# Q1 (structural contribution): theorem delta and test delta per run
V1_THEOREM_DELTA=0
V1_TEST_DELTA=0
V1_THEOREM_DELTA_AVG=0
V1_TEST_DELTA_AVG=0
if [ -f "$HISTORY_FILE" ]; then
  # Calculate deltas between consecutive runs from evolve-history.jsonl
  V1_THEOREM_DELTA=$(jq -s '
    [.[] | select(.result != "observation" and .lean.theorems != null)]
    | if length > 1 then
        .[-1].lean.theorems - .[-2].lean.theorems
      else 0 end
  ' "$HISTORY_FILE" 2>/dev/null || echo 0)
  V1_TEST_DELTA=$(jq -s '
    [.[] | select(.result != "observation" and .tests.passed != null)]
    | if length > 1 then
        .[-1].tests.passed - .[-2].tests.passed
      else 0 end
  ' "$HISTORY_FILE" 2>/dev/null || echo 0)
  # Rolling average over last 10 runs (decimal, 2-digit precision via *100/100.0)
  V1_THEOREM_DELTA_AVG=$(jq -s '
    [.[] | select(.result != "observation" and .lean.theorems != null)]
    | if length > 1 then
        [range(1; length) as $i | (.[($i)].lean.theorems - .[($i) - 1].lean.theorems)]
        | [.[-10:][]] | if length > 0 then (add * 100 / length / 100.0) else 0 end
      else 0 end
  ' "$HISTORY_FILE" 2>/dev/null || echo 0)
  V1_TEST_DELTA_AVG=$(jq -s '
    [.[] | select(.result != "observation" and .tests.passed != null)]
    | if length > 1 then
        [range(1; length) as $i | (.[($i)].tests.passed - .[($i) - 1].tests.passed)]
        | [.[-10:][]] | if length > 0 then (add * 100 / length / 100.0) else 0 end
      else 0 end
  ' "$HISTORY_FILE" 2>/dev/null || echo 0)
fi
V1_THEOREM_DELTA=${V1_THEOREM_DELTA:-0}
V1_TEST_DELTA=${V1_TEST_DELTA:-0}
V1_THEOREM_DELTA_AVG=${V1_THEOREM_DELTA_AVG:-0}
V1_TEST_DELTA_AVG=${V1_TEST_DELTA_AVG:-0}

# Q2 (verification quality): verifier pass rate and rejected count
V1_VERIFIER_PASS=0
V1_VERIFIER_FAIL=0
V1_VERIFIER_RATE=0
V1_REJECTED_COUNT=0
V1_REJECTED_AVG=0
if [ -f "$HISTORY_FILE" ]; then
  V1_VERIFIER_PASS=$(jq -s '[.[] | select(.result != "observation") | .phases.verifier.pass_count // 0] | add // 0' "$HISTORY_FILE" 2>/dev/null || echo 0)
  V1_VERIFIER_FAIL=$(jq -s '[.[] | select(.result != "observation") | .phases.verifier.fail_count // 0] | add // 0' "$HISTORY_FILE" 2>/dev/null || echo 0)
  V1_VERIFIER_TOTAL=$((V1_VERIFIER_PASS + V1_VERIFIER_FAIL))
  if [ "$V1_VERIFIER_TOTAL" -gt 0 ] 2>/dev/null; then
    V1_VERIFIER_RATE=$((V1_VERIFIER_PASS * 100 / V1_VERIFIER_TOTAL))
  fi
  V1_REJECTED_COUNT=$(jq -s '[.[] | select(.result != "observation")] | .[-1].rejected | length // 0' "$HISTORY_FILE" 2>/dev/null || echo 0)
  # Rolling average rejected count over last 10 runs
  V1_REJECTED_AVG=$(jq -s '
    [.[] | select(.result != "observation") | (.rejected | length // 0)]
    | [.[-10:][]] | if length > 0 then (add * 100 / length / 100.0) else 0 end
  ' "$HISTORY_FILE" 2>/dev/null || echo 0)
fi
V1_VERIFIER_PASS=${V1_VERIFIER_PASS:-0}
V1_VERIFIER_FAIL=${V1_VERIFIER_FAIL:-0}
V1_VERIFIER_RATE=${V1_VERIFIER_RATE:-0}
V1_REJECTED_COUNT=${V1_REJECTED_COUNT:-0}
V1_REJECTED_AVG=${V1_REJECTED_AVG:-0}

# Non-triviality score (R5): 0-4 based on structural conditions met
NTS_C1=0; NTS_C2=0; NTS_C3=0; NTS_C4=0
if [ "$V1_THEOREM_DELTA" -gt 0 ] 2>/dev/null; then NTS_C1=1; fi
if [ "$V1_TEST_DELTA" -gt 0 ] 2>/dev/null; then NTS_C2=1; fi
# C3: axiom delta != 0
NTS_AXIOM_DELTA=0
if [ -f "$HISTORY_FILE" ]; then
  NTS_AXIOM_DELTA=$(jq -s '
    [.[] | select(.result != "observation" and .lean.axioms != null)]
    | if length > 1 then .[-1].lean.axioms - .[-2].lean.axioms else 0 end
  ' "$HISTORY_FILE" 2>/dev/null || echo 0)
  NTS_AXIOM_DELTA=${NTS_AXIOM_DELTA:-0}
fi
if [ "$NTS_AXIOM_DELTA" -ne 0 ] 2>/dev/null; then NTS_C3=1; fi
# C4: verifier pass >= 2 in last run
NTS_LAST_VERIFIER_PASS=0
if [ -f "$HISTORY_FILE" ]; then
  NTS_LAST_VERIFIER_PASS=$(jq -s '[.[] | select(.result != "observation")] | .[-1].phases.verifier.pass_count // 0' "$HISTORY_FILE" 2>/dev/null || echo 0)
  NTS_LAST_VERIFIER_PASS=${NTS_LAST_VERIFIER_PASS:-0}
fi
if [ "$NTS_LAST_VERIFIER_PASS" -ge 2 ] 2>/dev/null; then NTS_C4=1; fi
NTS_SCORE=$((NTS_C1 + NTS_C2 + NTS_C3 + NTS_C4))
if [ "$NTS_SCORE" -ge 3 ]; then NTS_LABEL="substantial"
elif [ "$NTS_SCORE" -ge 1 ]; then NTS_LABEL="moderate"
else NTS_LABEL="trivial"
fi

# Saturation detection (R6): consecutive zero-delta runs for test count
SAT_CONSECUTIVE=0
if [ -f "$HISTORY_FILE" ]; then
  # Count trailing identical values for saturation detection
  SAT_CONSECUTIVE=$(jq -s '
    [.[] | select(.result != "observation" and .tests.passed != null) | .tests.passed] |
    . as $a | $a[-1] as $last |
    [range(length-1; -1; -1) | select($a[.] == $last)] |
    length - 1
  ' "$HISTORY_FILE" 2>/dev/null || echo 0)
  SAT_CONSECUTIVE=${SAT_CONSECUTIVE:-0}
fi
if [ "$SAT_CONSECUTIVE" -ge 10 ] 2>/dev/null; then SAT_STATUS="alert"
elif [ "$SAT_CONSECUTIVE" -ge 5 ] 2>/dev/null; then SAT_STATUS="warning"
else SAT_STATUS="ok"
fi

echo "  \"v1_v7\": {"
echo "    \"v1_skill_quality\": { \"gqm_version\": \"0.1.0\", \"q1_structural_contribution\": { \"theorem_delta_last_run\": $V1_THEOREM_DELTA, \"test_delta_last_run\": $V1_TEST_DELTA, \"theorem_delta_avg_10r\": $V1_THEOREM_DELTA_AVG, \"test_delta_avg_10r\": $V1_TEST_DELTA_AVG }, \"q2_verification_quality\": { \"verifier_pass_total\": $V1_VERIFIER_PASS, \"verifier_fail_total\": $V1_VERIFIER_FAIL, \"verifier_pass_rate\": $V1_VERIFIER_RATE, \"rejected_last_run\": $V1_REJECTED_COUNT, \"rejected_avg_10r\": $V1_REJECTED_AVG }, \"q3_operational_stability\": { \"evolve_success_rate\": $EVOLVE_SUCCESS_RATE, \"lean_health\": $LEAN_HEALTH, \"skill_count\": ${SKILL_COUNT:-0} }, \"non_triviality\": { \"score\": $NTS_SCORE, \"label\": \"$NTS_LABEL\", \"c1_theorem_growth\": $NTS_C1, \"c2_test_growth\": $NTS_C2, \"c3_axiom_change\": $NTS_C3, \"c4_multi_verification\": $NTS_C4 }, \"saturation\": { \"test_consecutive_zero_delta\": $SAT_CONSECUTIVE, \"status\": \"$SAT_STATUS\" }, \"proxy_classification\": \"formal\", \"graduation_date\": \"2026-03-27\", \"graduation_source\": \"#77 G1-G4\" },"
# V2 trend semantics: compare recent_avg (median of last 10 session deltas)
# against cumulative_avg (filtered full-history mean) as baseline.
# divergence_percent = (recent_avg - cumulative_avg) * 100 / cumulative_avg
# NOTE: V2 is a hub variable with tradeoffs against V1,V3,V5,V6,V7 (tradeoff_context_is_hub).
# divergence_percent > 100% is NOT necessarily a problem: evolve sessions (large tool usage)
# drive recent_avg upward. Rising divergence with rising evolve depth is expected behavior.
V2_TREND="stable"
V2_DIVERGENCE=0
if [ "$V2_CALLS_PER_SESSION" -gt 0 ] 2>/dev/null; then
  # increasing: recent_avg (median) > cumulative_avg * 120/100
  THRESHOLD_UP=$((V2_CALLS_PER_SESSION * 120 / 100))
  # decreasing: recent_avg (median) < cumulative_avg * 80/100
  THRESHOLD_DOWN=$((V2_CALLS_PER_SESSION * 80 / 100))
  if [ "$V2_RECENT_AVG" -gt "$THRESHOLD_UP" ] 2>/dev/null; then
    V2_TREND="increasing"
  elif [ "$V2_RECENT_AVG" -lt "$THRESHOLD_DOWN" ] 2>/dev/null; then
    V2_TREND="decreasing"
  fi
  V2_DIVERGENCE=$(( (V2_RECENT_AVG - V2_CALLS_PER_SESSION) * 100 / V2_CALLS_PER_SESSION ))
fi
echo "    \"v2_context_efficiency\": { \"tool_calls\": $TOOL_CALLS, \"sessions\": $SESSION_COUNT, \"recent_avg\": $V2_RECENT_AVG, \"cumulative_avg\": $V2_CALLS_PER_SESSION, \"raw_cumulative_avg\": ${V2_RAW_CUMULATIVE:-0}, \"trend_direction\": \"$V2_TREND\", \"divergence_percent\": $V2_DIVERGENCE, \"primary_metric\": \"recent_median\", \"raw_delta_count\": $RAW_DELTA_COUNT, \"filtered_delta_count\": $FILTERED_DELTA_COUNT, \"min_session_delta\": $MIN_SESSION_DELTA },"
V3_TOTAL_COMMITS=$(git -C "$BASE" rev-list --count HEAD 2>/dev/null || echo "0")
V3_TOTAL_COMMITS=${V3_TOTAL_COMMITS:-0}
V3_PASS=${TEST_PASSED:-0}
V3_FAIL=${TEST_FAILED:-0}
V3_TOTAL_TESTS=$((V3_PASS + V3_FAIL))
if [ "$V3_TOTAL_TESTS" -gt 0 ] 2>/dev/null; then
  V3_TEST_PASS_RATE=$((V3_PASS * 100 / V3_TOTAL_TESTS))
else
  V3_TEST_PASS_RATE=0
fi
# V3 hallucination_proxy: rejected[].failure_type の集計
# 注意: failure_type フィールドは Run 54 から標準化開始。
# データが蓄積されるまで全指標値は 0 になる（設計上の帰結であり異常ではない）。
V3_HALL_OBS=0
V3_HALL_HYP=0
V3_HALL_ASS=0
V3_HALL_PRE=0
V3_HALL_LOOPBACK_TOTAL=0
V3_HALL_REJECTED_TOTAL=0
V3_HALL_OBS_ACTIVE=0
V3_HALL_HYP_ACTIVE=0
V3_HALL_ASS_ACTIVE=0
V3_HALL_PRE_ACTIVE=0
if [ -f "$HISTORY_FILE" ]; then
  V3_HALL_OBS=$({ jq -r '.rejected[]?.failure_type // empty' "$HISTORY_FILE" 2>/dev/null | grep -c "^observation_error$"; } || true)
  V3_HALL_HYP=$({ jq -r '.rejected[]?.failure_type // empty' "$HISTORY_FILE" 2>/dev/null | grep -c "^hypothesis_error$"; } || true)
  V3_HALL_ASS=$({ jq -r '.rejected[]?.failure_type // empty' "$HISTORY_FILE" 2>/dev/null | grep -c "^assumption_error$"; } || true)
  V3_HALL_PRE=$({ jq -r '.rejected[]?.failure_type // empty' "$HISTORY_FILE" 2>/dev/null | grep -c "^precondition_error$"; } || true)
  V3_HALL_OBS=${V3_HALL_OBS:-0}
  V3_HALL_HYP=${V3_HALL_HYP:-0}
  V3_HALL_ASS=${V3_HALL_ASS:-0}
  V3_HALL_PRE=${V3_HALL_PRE:-0}
  V3_HALL_LOOPBACK_TOTAL=$({ jq -r '.rejected[]?.loopback_count // 0' "$HISTORY_FILE" 2>/dev/null | awk '{s+=$1} END{print s+0}'; } || echo 0)
  V3_HALL_REJECTED_TOTAL=$({ jq -r '.rejected[]?.failure_type // empty' "$HISTORY_FILE" 2>/dev/null | wc -l | tr -d ' '; } || echo 0)
  # resolved filter: select(.resolved != true) を適用したアクティブ件数
  V3_HALL_OBS_ACTIVE=$({ jq -r '.rejected[]? | select((.resolved // false) != true) | .failure_type // empty' "$HISTORY_FILE" 2>/dev/null | grep -c "^observation_error$"; } || true)
  V3_HALL_HYP_ACTIVE=$({ jq -r '.rejected[]? | select((.resolved // false) != true) | .failure_type // empty' "$HISTORY_FILE" 2>/dev/null | grep -c "^hypothesis_error$"; } || true)
  V3_HALL_ASS_ACTIVE=$({ jq -r '.rejected[]? | select((.resolved // false) != true) | .failure_type // empty' "$HISTORY_FILE" 2>/dev/null | grep -c "^assumption_error$"; } || true)
  V3_HALL_PRE_ACTIVE=$({ jq -r '.rejected[]? | select((.resolved // false) != true) | .failure_type // empty' "$HISTORY_FILE" 2>/dev/null | grep -c "^precondition_error$"; } || true)
  V3_HALL_OBS_ACTIVE=${V3_HALL_OBS_ACTIVE:-0}
  V3_HALL_HYP_ACTIVE=${V3_HALL_HYP_ACTIVE:-0}
  V3_HALL_ASS_ACTIVE=${V3_HALL_ASS_ACTIVE:-0}
  V3_HALL_PRE_ACTIVE=${V3_HALL_PRE_ACTIVE:-0}
  # post-quality-gate filter: Run 57+ (quality gate introduced in commit 99cc654)
  V3_HALL_OBS_POST_GATE=$({ jq -r 'select(.run != null and .run >= 57) | .rejected[]? | select((.resolved // false) != true) | .failure_type // empty' "$HISTORY_FILE" 2>/dev/null | grep -c "^observation_error$"; } || true)
  V3_HALL_HYP_POST_GATE=$({ jq -r 'select(.run != null and .run >= 57) | .rejected[]? | select((.resolved // false) != true) | .failure_type // empty' "$HISTORY_FILE" 2>/dev/null | grep -c "^hypothesis_error$"; } || true)
  V3_HALL_ASS_POST_GATE=$({ jq -r 'select(.run != null and .run >= 57) | .rejected[]? | select((.resolved // false) != true) | .failure_type // empty' "$HISTORY_FILE" 2>/dev/null | grep -c "^assumption_error$"; } || true)
  V3_HALL_PRE_POST_GATE=$({ jq -r 'select(.run != null and .run >= 57) | .rejected[]? | select((.resolved // false) != true) | .failure_type // empty' "$HISTORY_FILE" 2>/dev/null | grep -c "^precondition_error$"; } || true)
  V3_HALL_OBS_POST_GATE=${V3_HALL_OBS_POST_GATE:-0}
  V3_HALL_HYP_POST_GATE=${V3_HALL_HYP_POST_GATE:-0}
  V3_HALL_ASS_POST_GATE=${V3_HALL_ASS_POST_GATE:-0}
  V3_HALL_PRE_POST_GATE=${V3_HALL_PRE_POST_GATE:-0}
  # failure_subtype post-gate: H_wrong_premise, H_impl_specification, H_trivially_true, none (null/missing)
  V3_HALL_SUBTYPE_WRONG_PREMISE=0
  V3_HALL_SUBTYPE_IMPL_SPEC=0
  V3_HALL_SUBTYPE_TRIVIALLY_TRUE=0
  V3_HALL_SUBTYPE_NONE=0
  if [ -f "$HISTORY_FILE" ]; then
    V3_HALL_SUBTYPE_WRONG_PREMISE=$({ jq -r 'select(.run != null and .run >= 57) | .rejected[]? | select((.resolved // false) != true) | .failure_subtype // empty' "$HISTORY_FILE" 2>/dev/null | grep -c "^H_wrong_premise$"; } || true)
    V3_HALL_SUBTYPE_IMPL_SPEC=$({ jq -r 'select(.run != null and .run >= 57) | .rejected[]? | select((.resolved // false) != true) | .failure_subtype // empty' "$HISTORY_FILE" 2>/dev/null | grep -c "^H_impl_specification$"; } || true)
    V3_HALL_SUBTYPE_TRIVIALLY_TRUE=$({ jq -r 'select(.run != null and .run >= 57) | .rejected[]? | select((.resolved // false) != true) | .failure_subtype // empty' "$HISTORY_FILE" 2>/dev/null | grep -c "^H_trivially_true$"; } || true)
    V3_HALL_SUBTYPE_NONE=$({ jq -r 'select(.run != null and .run >= 57) | .rejected[]? | select((.resolved // false) != true) | select(.failure_subtype == null or .failure_subtype == "") | .failure_type // empty' "$HISTORY_FILE" 2>/dev/null | wc -l | tr -d ' '; } || echo 0)
    V3_HALL_SUBTYPE_WRONG_PREMISE=${V3_HALL_SUBTYPE_WRONG_PREMISE:-0}
    V3_HALL_SUBTYPE_IMPL_SPEC=${V3_HALL_SUBTYPE_IMPL_SPEC:-0}
    V3_HALL_SUBTYPE_TRIVIALLY_TRUE=${V3_HALL_SUBTYPE_TRIVIALLY_TRUE:-0}
    V3_HALL_SUBTYPE_NONE=${V3_HALL_SUBTYPE_NONE:-0}
  fi
fi
echo "    \"v3_output_quality\": { \"total_commits\": $V3_TOTAL_COMMITS, \"test_pass_rate\": $V3_TEST_PASS_RATE, \"proxy_classification\": \"formal\", \"graduation_date\": \"2026-03-27\", \"graduation_source\": \"#77 G1-G4\", \"hallucination_proxy\": { \"observation_error\": $V3_HALL_OBS, \"hypothesis_error\": $V3_HALL_HYP, \"assumption_error\": $V3_HALL_ASS, \"precondition_error\": $V3_HALL_PRE, \"loopback_total\": $V3_HALL_LOOPBACK_TOTAL, \"typed_rejected_total\": $V3_HALL_REJECTED_TOTAL, \"observation_error_active\": ${V3_HALL_OBS_ACTIVE:-0}, \"hypothesis_error_active\": ${V3_HALL_HYP_ACTIVE:-0}, \"assumption_error_active\": ${V3_HALL_ASS_ACTIVE:-0}, \"precondition_error_active\": ${V3_HALL_PRE_ACTIVE:-0}, \"observation_error_post_gate\": $V3_HALL_OBS_POST_GATE, \"hypothesis_error_post_gate\": $V3_HALL_HYP_POST_GATE, \"assumption_error_post_gate\": $V3_HALL_ASS_POST_GATE, \"precondition_error_post_gate\": $V3_HALL_PRE_POST_GATE, \"subtype_post_gate\": { \"H_wrong_premise\": ${V3_HALL_SUBTYPE_WRONG_PREMISE:-0}, \"H_impl_specification\": ${V3_HALL_SUBTYPE_IMPL_SPEC:-0}, \"H_trivially_true\": ${V3_HALL_SUBTYPE_TRIVIALLY_TRUE:-0}, \"none\": ${V3_HALL_SUBTYPE_NONE:-0} }, \"quality_gate_run\": 57, \"note\": \"failure_type 標準化は Run 54 から。_post_gate は Run 57 品質ゲート導入後のみ\" } },"
echo "    \"v4_gate_pass_rate\": { \"passed\": $V4_PASSED, \"blocked\": $V4_BLOCKED, \"blocked_excluded\": $V4_BLOCKED_EXCLUDED, \"total\": $V4_TOTAL, \"rate_percent\": $V4_RATE },"
echo "    \"v5_proposal_accuracy\": { \"approved\": $V5_APPROVED, \"total\": $V5_TOTAL, \"rate_percent\": $V5_RATE, \"grep_crosscheck\": $V5_GREP_APPROVED, \"schema_drift\": $V5_SCHEMA_DRIFT },"
ESCAPED_REPO=$(echo "$BASE" | sed 's|/|-|g; s|^-||')
MEMORY_DIR="$HOME/.claude/projects/-${ESCAPED_REPO}/memory"
MEMORY_MD="$MEMORY_DIR/MEMORY.md"
V6_MEMORY_ENTRIES=$(grep -c "^- \[" "$MEMORY_MD" 2>/dev/null || echo "0")
V6_MEMORY_FILES=$(find "$MEMORY_DIR" -maxdepth 1 -name "*.md" ! -name "MEMORY.md" 2>/dev/null | wc -l | tr -d ' ' || echo "0")
V6_MEMORY_ENTRIES=${V6_MEMORY_ENTRIES:-0}
V6_MEMORY_FILES=${V6_MEMORY_FILES:-0}
V6_MTIME=$(stat -f "%m" "$MEMORY_MD" 2>/dev/null || stat -c "%Y" "$MEMORY_MD" 2>/dev/null || echo "0")
V6_MTIME=${V6_MTIME:-0}
if [ "$V6_MTIME" -gt 0 ] 2>/dev/null; then
  V6_LAST_UPDATE_DAYS=$(( ($(date +%s) - V6_MTIME) / 86400 ))
else
  V6_LAST_UPDATE_DAYS=-1
fi
V6_RETIRED_COUNT=0
if [ -f "$HISTORY_FILE" ]; then
  V6_RETIRED_COUNT=$({ grep '"retired"' "$HISTORY_FILE" 2>/dev/null || true; } | wc -l | tr -d ' ')
  V6_RETIRED_COUNT=${V6_RETIRED_COUNT:-0}
fi
# type_distribution: MEMORY エントリの type 別件数（frontmatter type: フィールドを集計）
V6_TYPE_FEEDBACK=$(find "$MEMORY_DIR" -maxdepth 1 -name "*.md" ! -name "MEMORY.md" 2>/dev/null -exec grep -l "^type: feedback" {} \; 2>/dev/null | wc -l | tr -d ' ' || echo "0")
V6_TYPE_PROJECT=$(find "$MEMORY_DIR" -maxdepth 1 -name "*.md" ! -name "MEMORY.md" 2>/dev/null -exec grep -l "^type: project" {} \; 2>/dev/null | wc -l | tr -d ' ' || echo "0")
V6_TYPE_REFERENCE=$(find "$MEMORY_DIR" -maxdepth 1 -name "*.md" ! -name "MEMORY.md" 2>/dev/null -exec grep -l "^type: reference" {} \; 2>/dev/null | wc -l | tr -d ' ' || echo "0")
V6_TYPE_OTHER=0
if [ "$V6_MEMORY_FILES" -gt 0 ] 2>/dev/null; then
  V6_TYPE_OTHER=$(( V6_MEMORY_FILES - V6_TYPE_FEEDBACK - V6_TYPE_PROJECT - V6_TYPE_REFERENCE ))
  [ "$V6_TYPE_OTHER" -lt 0 ] && V6_TYPE_OTHER=0
fi
# index_consistency: MEMORY.md インデックスと実ファイルの整合性チェック
V6_ORPHAN_FILES=0
V6_MISSING_FILES=0
if [ -f "$MEMORY_MD" ] && [ -d "$MEMORY_DIR" ]; then
  # インデックスに記載されたファイル名を抽出（[label](filename.md) 形式）
  INDEX_FILES=$(grep -oE '\([a-zA-Z0-9_-]+\.md\)' "$MEMORY_MD" 2>/dev/null | tr -d '()' || true)
  # orphan_files: ファイルあり・インデックスなし
  while IFS= read -r f; do
    fname=$(basename "$f")
    if ! echo "$INDEX_FILES" | grep -qF "$fname" 2>/dev/null; then
      V6_ORPHAN_FILES=$(( V6_ORPHAN_FILES + 1 ))
    fi
  done < <(find "$MEMORY_DIR" -maxdepth 1 -name "*.md" ! -name "MEMORY.md" 2>/dev/null)
  # missing_files: インデックスあり・ファイルなし
  while IFS= read -r fname; do
    [ -z "$fname" ] && continue
    if [ ! -f "$MEMORY_DIR/$fname" ]; then
      V6_MISSING_FILES=$(( V6_MISSING_FILES + 1 ))
    fi
  done <<< "$INDEX_FILES"
fi
echo "    \"v6_knowledge_structure\": { \"memory_entries\": $V6_MEMORY_ENTRIES, \"memory_files\": $V6_MEMORY_FILES, \"last_update_days_ago\": $V6_LAST_UPDATE_DAYS, \"retired_count\": $V6_RETIRED_COUNT, \"type_distribution\": {\"feedback\": $V6_TYPE_FEEDBACK, \"project\": $V6_TYPE_PROJECT, \"reference\": $V6_TYPE_REFERENCE, \"other\": $V6_TYPE_OTHER}, \"index_consistency\": {\"orphan_files\": $V6_ORPHAN_FILES, \"missing_files\": $V6_MISSING_FILES}, \"note\": \"proxy: entry_count + staleness\" },"
echo "    \"v7_task_design\": { \"completed\": $V7_COMPLETED, \"unique_subjects\": $V7_UNIQUE_SUBJECTS, \"teamwork_percent\": $V7_TEAMWORK_PERCENT, \"teamwork_status\": \"suppressed_single_agent\" }"
echo "  },"

# --- T7: コスト計測（ccusage） ---
if command -v bunx >/dev/null 2>&1 || command -v npx >/dev/null 2>&1; then
  CCUSAGE_CMD=""
  if command -v bunx >/dev/null 2>&1; then
    CCUSAGE_CMD="bunx ccusage"
  else
    CCUSAGE_CMD="npx ccusage@latest"
  fi
  CCUSAGE_JSON=$($CCUSAGE_CMD daily --json --offline --mode calculate 2>/dev/null || echo "{}")
  CCUSAGE_TODAY=$(echo "$CCUSAGE_JSON" | jq -c '.daily | last // {}' 2>/dev/null || echo "{}")
  echo "  \"ccusage\": $CCUSAGE_TODAY,"
else
  echo "  \"ccusage\": {\"error\": \"ccusage not available\"},"
fi

# --- ccusage backfill: session_cost_usd の遡及補完 ---
# SKILL.md backfill 例外に基づく: null フィールドのみ補完、非 null は上書きしない
EVOLVE_HISTORY="$METRICS_DIR/evolve-history.jsonl"
BACKFILL_RESULT='{"backfilled": 0, "note": "skipped"}'
if [ -f "$EVOLVE_HISTORY" ] && (command -v bunx >/dev/null 2>&1 || command -v npx >/dev/null 2>&1); then
  CCUSAGE_CMD=""
  if command -v bunx >/dev/null 2>&1; then
    CCUSAGE_CMD="bunx ccusage"
  else
    CCUSAGE_CMD="npx ccusage@latest"
  fi
  CCUSAGE_SESSIONS=$($CCUSAGE_CMD session --json --offline --mode calculate 2>/dev/null || echo '{"sessions":[]}')
  BACKFILL_RESULT=$(python3 -c "
import json, sys, os, tempfile, re

UUID_RE = re.compile(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
history_path = os.path.expandvars('$EVOLVE_HISTORY')
sessions_raw = sys.stdin.read()

# Build UUID -> totalCost map from ccusage sessions (projectPath contains UUID)
uuid_cost = {}
try:
    data = json.loads(sessions_raw)
    sessions = data.get('sessions', []) if isinstance(data, dict) else data
    for s in sessions:
        pp = s.get('projectPath', '')
        if '/' in pp:
            uuid = pp.split('/')[-1]
            if UUID_RE.match(uuid):
                uuid_cost[uuid] = uuid_cost.get(uuid, 0) + s.get('totalCost', 0)
except: pass

if not uuid_cost:
    print(json.dumps({'backfilled': 0, 'note': 'no ccusage session data with UUID'}))
    sys.exit(0)

# Read and backfill
lines = open(history_path).readlines()
updated = 0
new_lines = []
for line in lines:
    try:
        rec = json.loads(line.strip())
        cost = rec.get('cost') or {}
        sid = rec.get('session_id', '')
        if (cost.get('session_cost_usd') is None
            and isinstance(sid, str) and UUID_RE.match(sid) and sid in uuid_cost):
            cost['session_cost_usd'] = round(uuid_cost[sid], 2)
            imps = cost.get('improvements_count') or len(rec.get('improvements', []))
            if imps and imps > 0:
                cost['cost_per_improvement_usd'] = round(uuid_cost[sid] / imps, 2)
            rec['cost'] = cost
            new_lines.append(json.dumps(rec, ensure_ascii=False) + '\n')
            updated += 1
        else:
            new_lines.append(line)
    except:
        new_lines.append(line)

if updated > 0:
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(history_path))
    with os.fdopen(fd, 'w') as f:
        f.writelines(new_lines)
    os.replace(tmp, history_path)

print(json.dumps({'backfilled': updated, 'uuid_matches_available': len(uuid_cost)}))
" <<< "$CCUSAGE_SESSIONS" 2>/dev/null || echo '{"backfilled": 0, "error": "backfill script failed"}')
fi
echo "  \"backfill_result\": $BACKFILL_RESULT,"

# --- evolve コスト効率サマリ（evolve-history.jsonl から集計） ---
EVOLVE_HISTORY="$METRICS_DIR/evolve-history.jsonl"
if [ -f "$EVOLVE_HISTORY" ]; then
  COST_STATS=$(python3 -c "
import json, sys
runs_with_cost = []
total_improvements = 0
for line in open('$EVOLVE_HISTORY'):
    try:
        rec = json.loads(line.strip())
        cost = rec.get('cost', {})
        if cost and cost.get('session_cost_usd') is not None:
            runs_with_cost.append(cost)
        imps = rec.get('improvements', [])
        if isinstance(imps, list):
            total_improvements += len(imps)
    except: pass
if runs_with_cost:
    costs = [c['session_cost_usd'] for c in runs_with_cost]
    mean_cost = sum(costs) / len(costs)
    cpi_vals = [c['cost_per_improvement_usd'] for c in runs_with_cost if c.get('cost_per_improvement_usd') is not None]
    mean_cpi = sum(cpi_vals) / len(cpi_vals) if cpi_vals else None
    print(json.dumps({'data_points': len(runs_with_cost), 'mean_session_cost_usd': round(mean_cost, 2), 'mean_cost_per_improvement_usd': round(mean_cpi, 2) if mean_cpi else None, 'total_improvements': total_improvements}))
else:
    print(json.dumps({'data_points': 0, 'mean_session_cost_usd': None, 'mean_cost_per_improvement_usd': None, 'total_improvements': total_improvements, 'note': 'no cost data yet in evolve-history'}))
" 2>/dev/null || echo '{"error": "cost stats computation failed"}')
  echo "  \"evolve_cost_efficiency\": $COST_STATS,"
else
  echo "  \"evolve_cost_efficiency\": {\"error\": \"evolve-history.jsonl not found\"},"
fi

# --- Deferred 正規クエリ（deferred-status.json から open 項目を取得） ---
DEFERRED_FILE="$METRICS_DIR/deferred-status.json"
if [ -f "$DEFERRED_FILE" ]; then
  DEFERRED_OPEN=$(jq -c '[.items | to_entries[] | select(.value.status == "open") | {id: .key} + .value]' "$DEFERRED_FILE" 2>/dev/null || echo "[]")
else
  DEFERRED_OPEN="[]"
fi
echo "  \"deferred_open\": $DEFERRED_OPEN,"

# --- 仮説テーブル自動集計（evolve-history.jsonl からの権威的カウント） ---
# H1: Verifier pass/fail 全期間合計（.phases.verifier フィールド対応エントリのみ）
# H4: 互換性クラス別改善件数（.improvements[].compatibility）
# H5: 有効 UUID session_id 件数（UUID v4 パターンに一致し "unknown" を除外）
if [ -f "$HISTORY_FILE" ]; then
  MAX_RUN=$(jq -r '.run // empty' "$HISTORY_FILE" 2>/dev/null | grep -E '^[0-9]+$' | sort -n | tail -1)
  MAX_RUN=${MAX_RUN:-0}
  TOTAL_ENTRIES=$(wc -l < "$HISTORY_FILE" | tr -d ' ')
  TOTAL_ENTRIES=${TOTAL_ENTRIES:-0}

  # H1: Verifier pass/fail 合計
  H1_PASS=$(jq -r '.phases.verifier.pass_count // 0' "$HISTORY_FILE" 2>/dev/null | awk '{s+=$1} END{print s+0}')
  H1_FAIL=$(jq -r '.phases.verifier.fail_count // 0' "$HISTORY_FILE" 2>/dev/null | awk '{s+=$1} END{print s+0}')
  H1_TOTAL=$((H1_PASS + H1_FAIL))
  if [ "$H1_TOTAL" -gt 0 ] 2>/dev/null; then
    H1_PASS_RATE=$((H1_PASS * 100 / H1_TOTAL))
  else
    H1_PASS_RATE=0
  fi

  # H4: 互換性クラス別改善件数
  # grep -c が 0 マッチで exit 1 を返すため || true で保護し ${:-0} で既定値
  H4_CONSERVATIVE=$({ jq -r '.improvements[]?.compatibility // empty' "$HISTORY_FILE" 2>/dev/null | grep -c "conservative extension"; } || true)
  H4_COMPATIBLE=$({ jq -r '.improvements[]?.compatibility // empty' "$HISTORY_FILE" 2>/dev/null | grep -c "compatible change"; } || true)
  H4_BREAKING=$({ jq -r '.improvements[]?.compatibility // empty' "$HISTORY_FILE" 2>/dev/null | grep -c "breaking change"; } || true)
  H4_OTHER=$({ jq -r '.improvements[]?.compatibility // empty' "$HISTORY_FILE" 2>/dev/null | grep -cv "conservative extension\|compatible change\|breaking change"; } || true)
  H4_CONSERVATIVE=${H4_CONSERVATIVE:-0}
  H4_COMPATIBLE=${H4_COMPATIBLE:-0}
  H4_BREAKING=${H4_BREAKING:-0}
  H4_OTHER=${H4_OTHER:-0}
  H4_TOTAL=$((H4_CONSERVATIVE + H4_COMPATIBLE + H4_BREAKING + H4_OTHER))

  # H5: ユニーク有効 UUID session_id 件数（UUID v4 パターン: 8-4-4-4-12 の hex 文字列）
  # sort -u で重複除外: 同一 session_id が複数エントリに出現するケースに対応
  H5_VALID_UUIDS=$({ jq -r '.session_id // empty' "$HISTORY_FILE" 2>/dev/null | \
    grep -E '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$' | \
    sort -u | wc -l | tr -d ' '; } || true)
  H5_VALID_UUIDS=${H5_VALID_UUIDS:-0}
else
  MAX_RUN=0
  TOTAL_ENTRIES=0
  H1_PASS=0
  H1_FAIL=0
  H1_TOTAL=0
  H1_PASS_RATE=0
  H4_CONSERVATIVE=0
  H4_COMPATIBLE=0
  H4_BREAKING=0
  H4_OTHER=0
  H4_TOTAL=0
  H5_VALID_UUIDS=0
fi
echo "  \"hypothesis_table_stats\": {"
echo "    \"header\": {\"max_run\": $MAX_RUN, \"total_entries\": $TOTAL_ENTRIES},"
echo "    \"h1_verifier\": {\"pass\": $H1_PASS, \"fail\": $H1_FAIL, \"total\": $H1_TOTAL, \"pass_rate_percent\": $H1_PASS_RATE},"
echo "    \"h4_compatibility\": {\"conservative_extension\": $H4_CONSERVATIVE, \"compatible_change\": $H4_COMPATIBLE, \"breaking_change\": $H4_BREAKING, \"other\": $H4_OTHER, \"total\": $H4_TOTAL},"
echo "    \"h5_valid_uuids\": $H5_VALID_UUIDS"
echo "  },"

# --- priority_bias_review: review_policy トリガー検出 ---
BENCHMARK_FILE="$METRICS_DIR/benchmark.json"
PBR_CURRENT_RUN=$MAX_RUN
PBR_RUN_AT_DECISION=$(jq -r '.priority_bias.current_snapshot.run_at_decision // empty' "$BENCHMARK_FILE" 2>/dev/null)
if [ -z "$PBR_RUN_AT_DECISION" ] || ! [ "$PBR_RUN_AT_DECISION" -eq "$PBR_RUN_AT_DECISION" ] 2>/dev/null; then
  PBR_RUN_AT_DECISION=97  # fallback: last known value from Run 97 decision
fi
PBR_RUNS_SINCE=$((PBR_CURRENT_RUN - PBR_RUN_AT_DECISION))
PBR_RUN_THRESHOLD=20
PBR_NEXT_RUN_TRIGGER=$((PBR_RUN_AT_DECISION + PBR_RUN_THRESHOLD))

# Trigger 0: V1/V3 formal graduation (benchmark.json から確認)
PBR_T0_FIRED=false
PBR_T0_RESOLVED=false
if [ -f "$BENCHMARK_FILE" ]; then
  PBR_T0_ACTION=$(jq -r '.priority_bias.review_policy.trigger_log[0].action_taken // ""' "$BENCHMARK_FILE" 2>/dev/null)
  if echo "$PBR_T0_ACTION" | grep -q "^resolved" 2>/dev/null; then
    PBR_T0_RESOLVED=true
  fi
fi
# Trigger 0 fires only if V1/V3 graduated AND not yet resolved
if [ "$PBR_T0_RESOLVED" = "false" ]; then
  V1_CLASS=$(jq -r '.priority_bias.current_snapshot.f_t_observations.system_phase // ""' "$BENCHMARK_FILE" 2>/dev/null)
  if echo "$V1_CLASS" | grep -q "formal" 2>/dev/null; then
    PBR_T0_FIRED=true
  fi
fi
PBR_T0_DETAIL=""
if [ "$PBR_T0_FIRED" = "true" ]; then
  PBR_T0_DETAIL="V1/V3 formal 2026-03-27, snapshot predates graduation"
fi

# Trigger 2: 20 runs elapsed since last review
PBR_T2_FIRED=false
PBR_T2_NEXT=$PBR_NEXT_RUN_TRIGGER
if [ "$PBR_CURRENT_RUN" -ge "$PBR_NEXT_RUN_TRIGGER" ] 2>/dev/null; then
  PBR_T2_FIRED=true
fi

# review_needed: either trigger 0 or trigger 2 fires
PBR_REVIEW_NEEDED=false
if [ "$PBR_T0_FIRED" = "true" ] || [ "$PBR_T2_FIRED" = "true" ]; then
  PBR_REVIEW_NEEDED=true
fi

echo "  \"priority_bias_review\": {"
echo "    \"current_run\": $PBR_CURRENT_RUN,"
echo "    \"run_at_decision\": $PBR_RUN_AT_DECISION,"
echo "    \"runs_since_decision\": $PBR_RUNS_SINCE,"
echo "    \"triggers_fired\": ["
echo "      {\"trigger\": \"V1/V3 formal graduation\", \"fired\": $PBR_T0_FIRED, \"detail\": \"$PBR_T0_DETAIL\"},"
echo "      {\"trigger\": \"20 runs elapsed\", \"fired\": $PBR_T2_FIRED, \"next\": $PBR_T2_NEXT}"
echo "    ],"
echo "    \"review_needed\": $PBR_REVIEW_NEEDED,"
echo "    \"authority\": \"T6 (human decision required)\""
echo "  },"

# --- manifest-trace 指標 ---
if [ -x "$BASE/manifest-trace" ]; then
  TRACE_JSON=$("$BASE/manifest-trace" json 2>/dev/null || echo "{}")
  TRACE_COVERED=$(echo "$TRACE_JSON" | jq '.summary.covered // 0' 2>/dev/null || echo "0")
  TRACE_UNCOVERED=$(echo "$TRACE_JSON" | jq '.summary.uncovered | length // 0' 2>/dev/null || echo "0")
  TRACE_WEAK=$(echo "$TRACE_JSON" | jq '.summary.weak | length // 0' 2>/dev/null || echo "0")
  TRACE_TOTAL=$(echo "$TRACE_JSON" | jq '.meta.total_propositions // 0' 2>/dev/null || echo "0")
  TRACE_ARTIFACTS=$(echo "$TRACE_JSON" | jq '.meta.total_artifacts // 0' 2>/dev/null || echo "0")
  # evidence_coverage: axioms + empirical postulates のみ（公理の証拠カバレッジ）
  # 導出のみの constraint（has_derivation=true, has_evidence=false）は derivation_completeness で追跡するため除外
  # 現在: T8 が該当（axiom→theorem 降格済み、Derivation Card あり、Axiom Card なし）
  TRACE_EC_WITH=$(echo "$TRACE_JSON" | jq '[.propositions[] | select(.category == "constraint" or .category == "empiricalPostulate") | select((.category == "constraint" and .coverage.has_derivation == true and (.coverage.has_evidence | not)) | not) | select(.coverage.has_evidence)] | length' 2>/dev/null || echo "0")
  TRACE_EC_TOTAL=$(echo "$TRACE_JSON" | jq '[.propositions[] | select(.category == "constraint" or .category == "empiricalPostulate") | select((.category == "constraint" and .coverage.has_derivation == true and (.coverage.has_evidence | not)) | not)] | length' 2>/dev/null || echo "0")
  # derivation_completeness: 導出命題（principle, boundary, designTheorem, observable）+ 導出のみの constraint
  TRACE_DC_WITH=$(echo "$TRACE_JSON" | jq '[.propositions[] | select(.category == "principle" or .category == "boundary" or .category == "designTheorem" or .category == "observable" or (.category == "constraint" and .coverage.has_derivation == true and (.coverage.has_evidence | not))) | select(.coverage.has_derivation)] | length' 2>/dev/null || echo "0")
  TRACE_DC_TOTAL=$(echo "$TRACE_JSON" | jq '[.propositions[] | select(.category == "principle" or .category == "boundary" or .category == "designTheorem" or .category == "observable" or (.category == "constraint" and .coverage.has_derivation == true and (.coverage.has_evidence | not)))] | length' 2>/dev/null || echo "0")
  # 深さ別カバレッジ
  TRACE_S5=$(echo "$TRACE_JSON" | jq '[.propositions[] | select(.strength == 5 and .coverage.total > 0)] | length' 2>/dev/null || echo "0")
  TRACE_S5_T=$(echo "$TRACE_JSON" | jq '[.propositions[] | select(.strength == 5)] | length' 2>/dev/null || echo "0")
  TRACE_S4=$(echo "$TRACE_JSON" | jq '[.propositions[] | select(.strength == 4 and .coverage.total > 0)] | length' 2>/dev/null || echo "0")
  TRACE_S4_T=$(echo "$TRACE_JSON" | jq '[.propositions[] | select(.strength == 4)] | length' 2>/dev/null || echo "0")
  TRACE_S3=$(echo "$TRACE_JSON" | jq '[.propositions[] | select(.strength == 3 and .coverage.total > 0)] | length' 2>/dev/null || echo "0")
  TRACE_S3_T=$(echo "$TRACE_JSON" | jq '[.propositions[] | select(.strength == 3)] | length' 2>/dev/null || echo "0")
  TRACE_S2=$(echo "$TRACE_JSON" | jq '[.propositions[] | select(.strength == 2 and .coverage.total > 0)] | length' 2>/dev/null || echo "0")
  TRACE_S2_T=$(echo "$TRACE_JSON" | jq '[.propositions[] | select(.strength == 2)] | length' 2>/dev/null || echo "0")
  TRACE_S1=$(echo "$TRACE_JSON" | jq '[.propositions[] | select(.strength == 1 and .coverage.total > 0)] | length' 2>/dev/null || echo "0")
  TRACE_S1_T=$(echo "$TRACE_JSON" | jq '[.propositions[] | select(.strength == 1)] | length' 2>/dev/null || echo "0")
  TRACE_S0=$(echo "$TRACE_JSON" | jq '[.propositions[] | select(.strength == 0 and .coverage.total > 0)] | length' 2>/dev/null || echo "0")
  TRACE_S0_T=$(echo "$TRACE_JSON" | jq '[.propositions[] | select(.strength == 0)] | length' 2>/dev/null || echo "0")
  echo "  \"manifest_trace\": {"
  echo "    \"version\": $(echo "$TRACE_JSON" | jq '.meta.version // "unknown"' 2>/dev/null || echo '\"unknown\"'),"
  echo "    \"coverage\": {\"covered\": $TRACE_COVERED, \"uncovered\": $TRACE_UNCOVERED, \"weak\": $TRACE_WEAK, \"total\": $TRACE_TOTAL},"
  echo "    \"artifacts\": $TRACE_ARTIFACTS,"
  echo "    \"evidence_coverage\": {\"with\": $TRACE_EC_WITH, \"total\": $TRACE_EC_TOTAL},"
  echo "    \"derivation_completeness\": {\"with\": $TRACE_DC_WITH, \"total\": $TRACE_DC_TOTAL},"
  echo "    \"by_strength\": {\"s5\": \"${TRACE_S5}/${TRACE_S5_T}\", \"s4\": \"${TRACE_S4}/${TRACE_S4_T}\", \"s3\": \"${TRACE_S3}/${TRACE_S3_T}\", \"s2\": \"${TRACE_S2}/${TRACE_S2_T}\", \"s1\": \"${TRACE_S1}/${TRACE_S1_T}\", \"s0\": \"${TRACE_S0}/${TRACE_S0_T}\"},"
  # G1: 優先修復候補 — uncovered かつ dependents が多い命題 (D13 影響波及順)
  TRACE_PRIORITY=$(cd "$BASE" && ./manifest-trace json 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.loads(sys.stdin.read())
    props = data.get('propositions', [])
    uncovered = [p for p in props if p.get('coverage', {}).get('total', 0) == 0]
    priority = sorted(uncovered, key=lambda x: (-len(x.get('depended_by', [])), -x.get('strength', 0)))[:5]
    print(json.dumps([{'id': p['id'], 'dependents': len(p.get('depended_by', [])), 'strength': p.get('strength', 0)} for p in priority]))
except: print('[]')
" 2>/dev/null || echo "[]")
  echo "    \"priority_repairs\": $TRACE_PRIORITY"
  echo "  },"
else
  echo "  \"manifest_trace\": null,"
fi

# ============================================================
# Observer 決定論的データ収集（G1 #232: judgmental→structural 移行）
# 以下のセクションは、従来 Observer Agent が手動で実行していた
# 決定論的データ収集をスクリプト化したもの。
# 根拠: mixed_task_decomposition (TaskClassification.lean)
# ============================================================

# --- GAP 1: Human Feedback History ---
EVOLVE_HISTORY="$METRICS_DIR/evolve-history.jsonl"
if [ -f "$EVOLVE_HISTORY" ]; then
  HUMAN_FEEDBACK=$(jq -s -c '[.[] | select(.type=="human_feedback") | {run: .run, timestamp: .timestamp, notes: .notes}] | .[-5:]' "$EVOLVE_HISTORY" 2>/dev/null || echo "[]")
else
  HUMAN_FEEDBACK="[]"
fi
echo "  \"human_feedback_recent\": $HUMAN_FEEDBACK,"

# --- GAP 2: T6 Issues from GitHub ---
if command -v gh >/dev/null 2>&1; then
  T6_ISSUES=$(gh issue list --label "T6:human-review" --state all --json number,title,state,comments --limit 20 2>/dev/null | \
    jq -c '[.[] | {number, title, state, has_comments: ((.comments // []) | length > 0), comment_count: ((.comments // []) | length)}]' 2>/dev/null || echo "[]")
  T6_OPEN=$(echo "$T6_ISSUES" | jq '[.[] | select(.state == "OPEN")] | length' 2>/dev/null || echo "0")
  T6_WITH_RESPONSE=$(echo "$T6_ISSUES" | jq '[.[] | select(.state == "OPEN" and .has_comments == true)] | length' 2>/dev/null || echo "0")
else
  T6_ISSUES="[]"
  T6_OPEN=0
  T6_WITH_RESPONSE=0
fi
echo "  \"t6_issues\": {"
echo "    \"items\": $T6_ISSUES,"
echo "    \"open_count\": $T6_OPEN,"
echo "    \"open_with_response\": $T6_WITH_RESPONSE"
echo "  },"

# --- GAP 3: Failure Pattern Analysis (unresolved, by type and subtype) ---
if [ -f "$EVOLVE_HISTORY" ]; then
  FAILURE_BY_TYPE=$(jq -s '[.[].rejected[]? | select(.failure_type != null) | select((.resolved // false) != true) | .failure_type] | group_by(.) | map({type: .[0], count: length}) | sort_by(-.count)' "$EVOLVE_HISTORY" 2>/dev/null || echo "[]")
  FAILURE_BY_SUBTYPE=$(jq -s '[.[].rejected[]? | select(.failure_subtype != null) | select((.resolved // false) != true) | {type: .failure_type, subtype: .failure_subtype}] | group_by(.subtype) | map({subtype: .[0].subtype, type: .[0].type, count: length}) | sort_by(-.count)' "$EVOLVE_HISTORY" 2>/dev/null || echo "[]")
  UNRESOLVED_TOTAL=$(echo "$FAILURE_BY_TYPE" | jq '[.[].count] | add // 0' 2>/dev/null || echo "0")
else
  FAILURE_BY_TYPE="[]"
  FAILURE_BY_SUBTYPE="[]"
  UNRESOLVED_TOTAL=0
fi
echo "  \"failure_patterns\": {"
echo "    \"unresolved_total\": $UNRESOLVED_TOTAL,"
echo "    \"by_type\": $FAILURE_BY_TYPE,"
echo "    \"by_subtype\": $FAILURE_BY_SUBTYPE"
echo "  },"

# --- GAP 4: MEMORY Retirement Candidates (6+ months without update) ---
MEMORY_DIR_PATH=""
for candidate in \
  "$HOME/.claude/projects/-Users-nirarin-work-agent-manifesto/memory" \
  "$HOME/.claude/projects/$(echo "$BASE" | tr '/' '-')/memory"; do
  if [ -d "$candidate" ]; then
    MEMORY_DIR_PATH="$candidate"
    break
  fi
done

if [ -n "$MEMORY_DIR_PATH" ] && [ -f "$MEMORY_DIR_PATH/MEMORY.md" ]; then
  RETIREMENT_CANDIDATES=$(python3 -c "
import os, sys, json
from datetime import datetime, timedelta
memory_dir = '$MEMORY_DIR_PATH'
threshold = datetime.now() - timedelta(days=180)
candidates = []
for f in os.listdir(memory_dir):
    if f.endswith('.md') and f != 'MEMORY.md':
        path = os.path.join(memory_dir, f)
        mtime = datetime.fromtimestamp(os.path.getmtime(path))
        if mtime < threshold:
            candidates.append({'file': f, 'last_modified': mtime.strftime('%Y-%m-%d'), 'days_ago': (datetime.now() - mtime).days})
print(json.dumps(sorted(candidates, key=lambda x: -x['days_ago'])))
" 2>/dev/null || echo "[]")
else
  RETIREMENT_CANDIDATES="[]"
fi
echo "  \"memory_retirement_candidates\": $RETIREMENT_CANDIDATES,"

# --- GAP 5: Structure File Currency (last update per key file) ---
STRUCTURE_CURRENCY=$(python3 -c "
import subprocess, json, os
files = [
    '.claude/skills/evolve/SKILL.md',
    '.claude/agents/observer/AGENT.md',
    '.claude/agents/hypothesizer/AGENT.md',
    '.claude/agents/integrator/AGENT.md',
    '.claude/agents/verifier.md',
    '.claude/agents/judge.md',
]
result = []
for f in files:
    if os.path.exists(f):
        try:
            out = subprocess.check_output(['git', 'log', '-1', '--format=%ci', '--', f], stderr=subprocess.DEVNULL, text=True).strip()
            result.append({'file': f, 'last_commit': out})
        except:
            result.append({'file': f, 'last_commit': 'unknown'})
print(json.dumps(result))
" 2>/dev/null || echo "[]")
echo "  \"structure_file_currency\": $STRUCTURE_CURRENCY,"

# --- GAP 6: Failed Test Details (cached from earlier test run) ---
# TEST_FAILED is set at line 58 from the test run earlier in this script.
# If tests failed, report the cached output. No re-run needed.
if [ "${TEST_FAILED:-0}" -gt 0 ] 2>/dev/null; then
  FAILED_TESTS=$(echo "$TEST_OUTPUT" | grep "FAIL" | grep -v "^TOTAL:" | head -20 | jq -R -s -c 'split("\n") | map(select(length > 0))' 2>/dev/null || echo "[]")
else
  FAILED_TESTS="[]"
fi
echo "  \"failed_test_details\": $FAILED_TESTS"

echo "}"
