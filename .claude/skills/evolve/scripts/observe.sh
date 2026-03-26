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
  FORMAL_LINES=$(find "$LEAN_DIR/Manifest" -name "*.lean" -exec cat {} + 2>/dev/null | wc -l | tr -d ' ')
  FORMAL_LINES=${FORMAL_LINES:-0}
  # test-axiom-quality.sh と統一: 4 ファイル（manifesto + docs 3 ファイル）
  INFORMAL_LINES=$(cat "$BASE/manifesto.md" "$BASE/docs/design-development-foundation.md" "$BASE/docs/formal-derivation-procedure.md" "$BASE/docs/mathematical-logic-terminology.md" 2>/dev/null | wc -l | tr -d ' ')
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
  echo "    \"de_bruijn_factor\": $DE_BRUIJN"
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
  # Run 番号ベースのカウント（run=null の human_feedback/旧エントリを除外）
  EVOLVE_RUNS=$(jq -r '.run // empty' "$HISTORY_FILE" 2>/dev/null | sort -n | tail -1)
  EVOLVE_RUNS=${EVOLVE_RUNS:-0}
  LAST_RUN=$(tail -1 "$HISTORY_FILE" 2>/dev/null | jq -r '.timestamp // empty' 2>/dev/null)
  LAST_RUN=${LAST_RUN:-never}
  # phases フィールド集計（標準スキーマ対応エントリのみ）
  PHASES_OBSERVER_SUM=$(jq -r '.phases.observer.findings_count // 0' "$HISTORY_FILE" 2>/dev/null | awk '{s+=$1} END{print s+0}')
  PHASES_HYPO_SUM=$(jq -r '.phases.hypothesizer.proposals_count // 0' "$HISTORY_FILE" 2>/dev/null | awk '{s+=$1} END{print s+0}')
  PHASES_VERIFIER_PASS_SUM=$(jq -r '.phases.verifier.pass_count // 0' "$HISTORY_FILE" 2>/dev/null | awk '{s+=$1} END{print s+0}')
  PHASES_VERIFIER_FAIL_SUM=$(jq -r '.phases.verifier.fail_count // 0' "$HISTORY_FILE" 2>/dev/null | awk '{s+=$1} END{print s+0}')
else
  EVOLVE_RUNS=0
  LAST_RUN="never"
fi
echo "  \"evolve_history\": {"
echo "    \"total_runs\": $EVOLVE_RUNS,"
echo "    \"last_run\": \"$LAST_RUN\","
echo "    \"phases_totals\": {"
echo "      \"observer_findings\": ${PHASES_OBSERVER_SUM:-0},"
echo "      \"hypothesizer_proposals\": ${PHASES_HYPO_SUM:-0},"
echo "      \"verifier_pass\": ${PHASES_VERIFIER_PASS_SUM:-0},"
echo "      \"verifier_fail\": ${PHASES_VERIFIER_FAIL_SUM:-0}"
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

echo "  \"v1_v7\": {"
echo "    \"v1_skill_quality\": { \"evolve_success_rate\": $EVOLVE_SUCCESS_RATE, \"lean_health\": $LEAN_HEALTH, \"skill_count\": ${SKILL_COUNT:-0}, \"proxy_classification\": \"provisional\", \"graduation_criteria\": \"benchmark.json implementation OR operational correlation evidence (T6)\" },"
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
# V3 fix_ratio proxy の制限: このパターンは "[fix]:" や "fix:" で始まるコミットのみにマッチする。
# "[evolve] Fix ..." のようにプレフィックスが異なる形式はマッチしない。
# そのため、実際のバグ修正コミット数はこの proxy 値より多い可能性がある。
V3_FIX_COMMITS=$({ git -C "$BASE" log --oneline 2>/dev/null || true; } | { grep -iE "^\[?(fix|bugfix|hotfix)\]?[: ]" || true; } | wc -l | tr -d ' ')
V3_FIX_COMMITS=${V3_FIX_COMMITS:-0}
V3_TOTAL_COMMITS=${V3_TOTAL_COMMITS:-0}
if [ "$V3_TOTAL_COMMITS" -gt 0 ] 2>/dev/null; then
  V3_FIX_RATIO=$((V3_FIX_COMMITS * 100 / V3_TOTAL_COMMITS))
else
  V3_FIX_RATIO=0
fi
V3_PASS=${PASS:-0}
V3_FAIL=${FAIL:-0}
V3_TOTAL_TESTS=$((V3_PASS + V3_FAIL))
if [ "$V3_TOTAL_TESTS" -gt 0 ] 2>/dev/null; then
  V3_TEST_PASS_RATE=$((V3_PASS * 100 / V3_TOTAL_TESTS))
else
  V3_TEST_PASS_RATE=0
fi
# V3 baseline: fix_ratio <= 20% is healthy. Rationale: current ratio ~15% (10 fix / 66 total).
# Threshold set at run 12 (commit 05653dc). If ratio exceeds 20%, structural quality is degrading.
V3_BASELINE_THRESHOLD=20
if [ "$V3_FIX_RATIO" -le "$V3_BASELINE_THRESHOLD" ] && [ "$V3_TEST_PASS_RATE" -eq 100 ] 2>/dev/null; then
  V3_BASELINE_MET="true"
else
  V3_BASELINE_MET="false"
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
fi
echo "    \"v3_output_quality\": { \"total_commits\": $V3_TOTAL_COMMITS, \"fix_commits\": $V3_FIX_COMMITS, \"fix_ratio_percent\": $V3_FIX_RATIO, \"test_pass_rate\": $V3_TEST_PASS_RATE, \"v3_baseline_threshold\": $V3_BASELINE_THRESHOLD, \"v3_baseline_met\": $V3_BASELINE_MET, \"proxy_classification\": \"provisional\", \"graduation_criteria\": \"gate pass rate implementation OR operational correlation evidence (T6)\", \"hallucination_proxy\": { \"observation_error\": $V3_HALL_OBS, \"hypothesis_error\": $V3_HALL_HYP, \"assumption_error\": $V3_HALL_ASS, \"precondition_error\": $V3_HALL_PRE, \"loopback_total\": $V3_HALL_LOOPBACK_TOTAL, \"typed_rejected_total\": $V3_HALL_REJECTED_TOTAL, \"note\": \"failure_type 標準化は Run 54 から。データ蓄積前は全値 0\" } },"
echo "    \"v4_gate_pass_rate\": { \"passed\": $V4_PASSED, \"blocked\": $V4_BLOCKED, \"total\": $V4_TOTAL, \"rate_percent\": $V4_RATE },"
echo "    \"v5_proposal_accuracy\": { \"approved\": $V5_APPROVED, \"total\": $V5_TOTAL, \"rate_percent\": $V5_RATE, \"grep_crosscheck\": $V5_GREP_APPROVED, \"schema_drift\": $V5_SCHEMA_DRIFT },"
MEMORY_MD="$HOME/.claude/projects/-Users-nirarin-work-agent-manifesto/memory/MEMORY.md"
MEMORY_DIR="$HOME/.claude/projects/-Users-nirarin-work-agent-manifesto/memory"
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
echo "    \"v6_knowledge_structure\": { \"memory_entries\": $V6_MEMORY_ENTRIES, \"memory_files\": $V6_MEMORY_FILES, \"last_update_days_ago\": $V6_LAST_UPDATE_DAYS, \"retired_count\": $V6_RETIRED_COUNT, \"note\": \"proxy: entry_count + staleness\" },"
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

# JSONL deferred duplication metric (legacy data quality indicator)
# 目的: JSONL の append-only 累積方式により同一 ID が複数 run に出現することの定量的記録
# 解釈: total_entries と unique_ids の差分が大きいほど重複度が高い
#       これは設計上の帰結であり異常ではない（各 run が状態スナップショットを記録）
# 用途: deferred-status.json が正規ソースであることの裏付けデータ
#       分析・改善判断には使用しない（legacy_audit_metric）
# 注意: open 件数の確認には deferred_open フィールドを使用すること
if [ -f "$HISTORY_FILE" ]; then
  DEFERRED_TOTAL=$(jq -r '.deferred[]?.id // empty' "$HISTORY_FILE" 2>/dev/null | wc -l | tr -d ' ')
  DEFERRED_UNIQUE=$(jq -r '.deferred[]?.id // empty' "$HISTORY_FILE" 2>/dev/null | sort -u | wc -l | tr -d ' ')
else
  DEFERRED_TOTAL=0
  DEFERRED_UNIQUE=0
fi
echo "  \"deferred_jsonl_quality\": {\"total_entries\": $DEFERRED_TOTAL, \"unique_ids\": $DEFERRED_UNIQUE, \"note\": \"legacy_audit_metric: not_for_analysis. See SKILL.md Step 0\"},"

# --- 仮説テーブル自動集計（evolve-history.jsonl からの権威的カウント） ---
# H1: Verifier pass/fail 全期間合計（.phases.verifier フィールド対応エントリのみ）
# H4: 互換性クラス別改善件数（.improvements[].compatibility）
# H5: 有効 UUID session_id 件数（UUID v4 パターンに一致し "unknown" を除外）
if [ -f "$HISTORY_FILE" ]; then
  MAX_RUN=$(jq -r '.run // empty' "$HISTORY_FILE" 2>/dev/null | sort -n | tail -1)
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
echo "  }"

echo "}"
