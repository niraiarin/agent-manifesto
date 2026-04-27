#!/usr/bin/env bash
# Phase 7 sprint 1 #4: proof generation evaluation harness (Day 212)
#
# 目的: docs/research/.../proof-gen/benchmark-*.json から theorem statement を読み込み、
#       baseline (sorry) / aesop / duper の各 solver で proof 試行、PASS/FAIL を集計。
#       sprint 2 で benchmark を拡張、sprint 3 で pass rate 測定。

set -uo pipefail

REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
BENCHMARK_DEFAULT="$REPO_ROOT/docs/research/new-foundation-survey/proof-gen/benchmark-skeleton.json"
WORK_DIR="${PROOF_HARNESS_WORK_DIR:-${TMPDIR:-/tmp}/proof-harness-$$}"
AGENT_SPEC_LIB="$REPO_ROOT/agent-spec-lib"

CMD="${1:-list}"
BENCHMARK="${2:-$BENCHMARK_DEFAULT}"

if [ ! -f "$BENCHMARK" ]; then
  echo "ERROR: benchmark not found at $BENCHMARK" >&2
  exit 2
fi

case "$CMD" in
  list)
    echo "=== Proof Generation Benchmark ==="
    echo "Source: $BENCHMARK"
    echo ""
    jq -r '.benchmarks[] | "\(.id) [\(.shape), expect: \(.expected_solvers | join(","))]: \(.statement)"' "$BENCHMARK"
    ;;

  generate)
    # Generate per-solver test files for a given benchmark id.
    # Usage: $0 generate <id> [output-dir]
    ID="${3:-}"
    OUT="${4:-$WORK_DIR}"
    if [ -z "$ID" ]; then
      echo "Usage: $0 generate <benchmark-file> <id> [output-dir]" >&2
      exit 64
    fi

    ENTRY=$(jq --arg id "$ID" '.benchmarks[] | select(.id == $id)' "$BENCHMARK")
    if [ -z "$ENTRY" ]; then
      echo "ERROR: benchmark id '$ID' not found" >&2
      exit 1
    fi

    STMT=$(echo "$ENTRY" | jq -r '.statement')
    PREMISES=$(echo "$ENTRY" | jq -r '.premises_form')
    IMPORTS=$(echo "$ENTRY" | jq -r '.imports | map("import " + .) | join("\n")')

    mkdir -p "$OUT"

    # Baseline: sorry (always compiles, but counts as no proof)
    cat > "$OUT/${ID}_baseline.lean" <<EOF
import AgentSpec
$IMPORTS

example $STMT := by sorry
EOF

    # Aesop attempt
    cat > "$OUT/${ID}_aesop.lean" <<EOF
import AgentSpec
$IMPORTS

example $STMT := by aesop
EOF

    # Duper attempt
    cat > "$OUT/${ID}_duper.lean" <<EOF
import AgentSpec
$IMPORTS

example $STMT := by duper $PREMISES
EOF

    echo "Generated 3 files in $OUT:"
    ls -1 "$OUT" | grep "^${ID}_"
    ;;

  run)
    # Run all solvers on all benchmarks, report pass/fail.
    # Usage: $0 run [benchmark-file]
    # Output: stdout = human-readable table + summary, JSON_OUT (env) optional path で full record JSON 保存
    OUT="$WORK_DIR"
    mkdir -p "$OUT"
    TOTAL=0
    declare -A PASS_COUNT
    PASS_COUNT[baseline]=0
    PASS_COUNT[aesop]=0
    PASS_COUNT[duper]=0

    echo "=== Proof Harness Run ==="
    echo "Benchmark: $BENCHMARK"
    echo "Work dir: $OUT"
    echo ""
    printf "%-40s %-10s %-10s %-10s\n" "id" "baseline" "aesop" "duper"
    printf "%-40s %-10s %-10s %-10s\n" "$(printf '%.0s-' {1..40})" "--------" "--------" "--------"

    JSON_RECORDS="["
    JSON_FIRST=1
    while IFS= read -r ID; do
      TOTAL=$((TOTAL + 1))
      "$0" generate "$BENCHMARK" "$ID" "$OUT" >/dev/null

      RESULTS=()
      for SOLVER in baseline aesop duper; do
        F="$OUT/${ID}_${SOLVER}.lean"
        STDERR_FILE="$OUT/${ID}_${SOLVER}.stderr"
        START_MS=$(date +%s%N | cut -c1-13)
        # Lean writes errors to stdout, not stderr. Capture both.
        if (cd "$AGENT_SPEC_LIB" && lake env lean "$F") >"$STDERR_FILE" 2>&1; then
          STATUS="PASS"
          PROOF_OK="true"
          FAILURE_CLASS="null"
          PASS_COUNT[$SOLVER]=$((PASS_COUNT[$SOLVER] + 1))
        else
          STATUS="FAIL"
          PROOF_OK="false"
          # Day 214 Phase 7 sprint 3 #2: failure_class auto-classification
          if grep -qiE "deterministic timeout|out of time|maxHeartbeats|maximum recursion depth" "$STDERR_FILE" 2>/dev/null; then
            FAILURE_CLASS='"timeout"'
          elif grep -qiE "unknown identifier|unknown constant|no instance found|cannot find synthesis" "$STDERR_FILE" 2>/dev/null; then
            FAILURE_CLASS='"missing_lemma"'
          elif grep -qiE "made no progress|no applicable rule|exhausted|failed to solve|unable to do so" "$STDERR_FILE" 2>/dev/null; then
            FAILURE_CLASS='"bad_search_space"'
          elif grep -qiE "type mismatch|reconstruction failed|elaboration failed|expected type" "$STDERR_FILE" 2>/dev/null; then
            FAILURE_CLASS='"reconstruction_failure"'
          else
            FAILURE_CLASS='"tooling_failure"'
          fi
        fi
        END_MS=$(date +%s%N | cut -c1-13)
        TIME_MS=$((END_MS - START_MS))
        RESULTS+=("$STATUS")

        if [ "$JSON_FIRST" -eq 0 ]; then JSON_RECORDS="$JSON_RECORDS,"; fi
        JSON_FIRST=0
        JSON_RECORDS="$JSON_RECORDS$(jq -c -n --arg id "$ID" --arg tool "$SOLVER" --argjson proof_ok "$PROOF_OK" --argjson time_ms "$TIME_MS" --argjson failure_class "$FAILURE_CLASS" '{id: $id, tool_used: $tool, statement_ok: true, proof_ok: $proof_ok, time_ms: $time_ms, heartbeats: null, failure_class: $failure_class}')"
      done
      printf "%-40s %-10s %-10s %-10s\n" "$ID" "${RESULTS[0]}" "${RESULTS[1]}" "${RESULTS[2]}"
    done < <(jq -r '.benchmarks[].id' "$BENCHMARK")
    JSON_RECORDS="$JSON_RECORDS]"

    if [ -n "${JSON_OUT:-}" ]; then
      echo "$JSON_RECORDS" | jq '.' > "$JSON_OUT"
      echo ""
      echo "JSON records → $JSON_OUT"
    fi

    echo ""
    echo "=== Summary (n=$TOTAL) ==="
    echo "baseline: ${PASS_COUNT[baseline]}/$TOTAL (sorry は常に compile)"
    echo "aesop:    ${PASS_COUNT[aesop]}/$TOTAL"
    echo "duper:    ${PASS_COUNT[duper]}/$TOTAL"
    ;;

  extract)
    # Day 215 Phase 7 sprint 3 #3: materialised proof script extraction.
    # For each (id, solver) where solver succeeded in last `run`, generate aesop?/duper?
    # variant, compile, capture "Try this: ..." line.
    # Usage: $0 extract [benchmark-file] [output-md]
    OUT_MD="${3:-$REPO_ROOT/docs/research/new-foundation-survey/proof-gen/materialised-scripts.md}"
    OUT="$WORK_DIR"
    mkdir -p "$OUT"

    echo "# Materialised Proof Scripts (Day 215 Phase 7 sprint 3 #3)" > "$OUT_MD"
    echo "" >> "$OUT_MD"
    echo "Each row shows the tactic script suggested by \`aesop?\` / \`duper?\` for benchmarks that PASS." >> "$OUT_MD"
    echo "" >> "$OUT_MD"
    echo "Source benchmark: $BENCHMARK" >> "$OUT_MD"
    echo "" >> "$OUT_MD"
    echo "| id | tool | suggested script |" >> "$OUT_MD"
    echo "|---|---|---|" >> "$OUT_MD"

    while IFS= read -r ID; do
      ENTRY=$(jq --arg id "$ID" '.benchmarks[] | select(.id == $id)' "$BENCHMARK")
      STMT=$(echo "$ENTRY" | jq -r '.statement')
      PREMISES=$(echo "$ENTRY" | jq -r '.premises_form')
      IMPORTS=$(echo "$ENTRY" | jq -r '.imports | map("import " + .) | join("\n")')

      for SOLVER in aesop duper; do
        F="$OUT/${ID}_${SOLVER}_extract.lean"
        if [ "$SOLVER" = "aesop" ]; then
          TACTIC="aesop?"
        else
          TACTIC="duper? $PREMISES"
        fi
        cat > "$F" <<EOF
import AgentSpec
$IMPORTS

example $STMT := by $TACTIC
EOF
        OUTPUT=$(cd "$AGENT_SPEC_LIB" && lake env lean "$F" 2>&1 | head -20)
        # Extract "Try this: ..." block (multi-line capture, take suggested tactic line)
        SCRIPT=$(echo "$OUTPUT" | awk '/^Try this:/{flag=1; next} flag && NF{print; exit}' | sed 's/^[[:space:]]*//;s/^\[apply\][[:space:]]*//')
        if [ -n "$SCRIPT" ]; then
          # Escape pipes for markdown table
          SCRIPT_ESCAPED=$(echo "$SCRIPT" | sed 's/|/\\|/g')
          echo "| \`$ID\` | $SOLVER | \`$SCRIPT_ESCAPED\` |" >> "$OUT_MD"
        else
          echo "| \`$ID\` | $SOLVER | (FAIL or no suggestion) |" >> "$OUT_MD"
        fi
      done
    done < <(jq -r '.benchmarks[].id' "$BENCHMARK")

    echo "Materialised scripts → $OUT_MD"
    cat "$OUT_MD"
    ;;

  *)
    cat <<USAGE
Usage:
  $0 list [benchmark-file]                       # benchmark 一覧
  $0 generate <benchmark-file> <id> [out-dir]    # solver 別 test file 生成
  $0 run [benchmark-file]                        # 全 benchmark × 全 solver 実行 + 集計
  $0 extract [benchmark-file] [output-md]        # PASS combination で aesop?/duper? script 抽出

Default benchmark: $BENCHMARK_DEFAULT

例:
  $0 list
  $0 run
  $0 generate \$REPO_ROOT/docs/research/new-foundation-survey/proof-gen/benchmark-skeleton.json p_implies_p /tmp/out
USAGE
    ;;
esac
