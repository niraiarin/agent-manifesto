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

    while IFS= read -r ID; do
      TOTAL=$((TOTAL + 1))
      "$0" generate "$BENCHMARK" "$ID" "$OUT" >/dev/null

      RESULTS=()
      for SOLVER in baseline aesop duper; do
        F="$OUT/${ID}_${SOLVER}.lean"
        if (cd "$AGENT_SPEC_LIB" && lake env lean "$F") >/dev/null 2>&1; then
          RESULTS+=("PASS")
          PASS_COUNT[$SOLVER]=$((PASS_COUNT[$SOLVER] + 1))
        else
          RESULTS+=("FAIL")
        fi
      done
      printf "%-40s %-10s %-10s %-10s\n" "$ID" "${RESULTS[0]}" "${RESULTS[1]}" "${RESULTS[2]}"
    done < <(jq -r '.benchmarks[].id' "$BENCHMARK")

    echo ""
    echo "=== Summary (n=$TOTAL) ==="
    echo "baseline: ${PASS_COUNT[baseline]}/$TOTAL (sorry は常に compile)"
    echo "aesop:    ${PASS_COUNT[aesop]}/$TOTAL"
    echo "duper:    ${PASS_COUNT[duper]}/$TOTAL"
    ;;

  *)
    cat <<USAGE
Usage:
  $0 list [benchmark-file]                       # benchmark 一覧
  $0 generate <benchmark-file> <id> [out-dir]    # solver 別 test file 生成
  $0 run [benchmark-file]                        # 全 benchmark × 全 solver 実行 + 集計

Default benchmark: $BENCHMARK_DEFAULT

例:
  $0 list
  $0 run
  $0 generate \$REPO_ROOT/docs/research/new-foundation-survey/proof-gen/benchmark-skeleton.json p_implies_p /tmp/out
USAGE
    ;;
esac
