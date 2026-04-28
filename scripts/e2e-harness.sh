#!/usr/bin/env bash
# Phase 8 sprint 1 e2e harness scaffolding (Day 218).
#
# 目的: NL input → spec-gen output (recorded or live) → proof attempt (aesop/duper) を
#       chain して end-to-end pass rate を測定。
# Sprint 1 acceptance: at least 3 e2e cases run successfully through the chain.
#
# 注意: spec-gen subagent dispatch は Claude Code 経由で manual 実行が必要なため、
#       本 sprint 1 では recorded output を benchmark に埋め込み、proof phase のみ
#       自動化。Sprint 2 で independent NL benchmark + live subagent dispatch、
#       Sprint 3 で full CLEVER same-condition measurement。

set -uo pipefail

REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
BENCHMARK_DEFAULT="$REPO_ROOT/docs/research/new-foundation-survey/proof-gen/benchmark-e2e-day218.json"
WORK_DIR="${E2E_HARNESS_WORK_DIR:-${TMPDIR:-/tmp}/e2e-harness-$$}"
AGENT_SPEC_LIB="$REPO_ROOT/agent-spec-lib"

CMD="${1:-list}"
BENCHMARK="${2:-$BENCHMARK_DEFAULT}"

if [ ! -f "$BENCHMARK" ]; then
  echo "ERROR: benchmark not found at $BENCHMARK" >&2
  exit 2
fi

case "$CMD" in
  list)
    echo "=== E2E Benchmark ==="
    echo "Source: $BENCHMARK"
    echo ""
    jq -r '.benchmarks[] | "\(.id): \(.nl_input)\n  → \(.recorded_spec_gen_output)"' "$BENCHMARK"
    ;;

  run)
    # Run e2e: spec compile + proof attempts for each benchmark.
    # Output: stdout + JSON_OUT (env)
    OUT="$WORK_DIR"
    mkdir -p "$OUT"
    TOTAL=0
    SPEC_PASS=0
    PROOF_PASS=0
    E2E_PASS=0

    echo "=== E2E Harness Run ==="
    echo "Benchmark: $BENCHMARK"
    echo "Work dir: $OUT"
    echo ""
    printf "%-40s %-10s %-15s %-10s\n" "id" "stmt" "proof_tool" "e2e"
    printf "%-40s %-10s %-15s %-10s\n" "$(printf '%.0s-' {1..40})" "----" "----------" "---"

    JSON_RECORDS="["
    JSON_FIRST=1
    while IFS= read -r ID; do
      TOTAL=$((TOTAL + 1))
      ENTRY=$(jq --arg id "$ID" '.benchmarks[] | select(.id == $id)' "$BENCHMARK")
      NL=$(echo "$ENTRY" | jq -r '.nl_input')
      STMT=$(echo "$ENTRY" | jq -r '.recorded_spec_gen_output')
      IMPORTS=$(echo "$ENTRY" | jq -r '.imports | map("import " + .) | join("\n")')
      NS_OPEN=$(echo "$ENTRY" | jq -r '.namespace_open')
      PRELUDE=$(echo "$ENTRY" | jq -r '.prelude // ""')

      # Step 1: statement compile (with sorry)
      STMT_FILE="$OUT/${ID}_stmt.lean"
      cat > "$STMT_FILE" <<EOF
$IMPORTS
$NS_OPEN

$PRELUDE

theorem stub $STMT := by sorry
EOF
      STMT_LOG="$OUT/${ID}_stmt.log"
      if (cd "$AGENT_SPEC_LIB" && lake env lean "$STMT_FILE") >"$STMT_LOG" 2>&1; then
        STMT_OK="true"
        SPEC_PASS=$((SPEC_PASS + 1))
      else
        STMT_OK="false"
      fi

      # Step 2: proof attempts (aesop, duper)
      BEST_TOOL="null"
      PROOF_OK="false"
      FAILURE_STAGE='"both"'  # default if everything fails

      if [ "$STMT_OK" = "true" ]; then
        FAILURE_STAGE='"proof"'
        for TOOL in aesop duper; do
          PROOF_FILE="$OUT/${ID}_${TOOL}.lean"
          if [ "$TOOL" = "aesop" ]; then
            TACTIC="by aesop"
          else
            TACTIC="by duper [*]"
          fi
          cat > "$PROOF_FILE" <<EOF
$IMPORTS
import Aesop
import Duper
$NS_OPEN

$PRELUDE

theorem stub $STMT := $TACTIC
EOF
          PROOF_LOG="$OUT/${ID}_${TOOL}.log"
          if (cd "$AGENT_SPEC_LIB" && lake env lean "$PROOF_FILE") >"$PROOF_LOG" 2>&1; then
            PROOF_OK="true"
            BEST_TOOL="\"$TOOL\""
            FAILURE_STAGE='"none"'
            PROOF_PASS=$((PROOF_PASS + 1))
            break
          fi
        done
      else
        FAILURE_STAGE='"spec"'
      fi

      if [ "$STMT_OK" = "true" ] && [ "$PROOF_OK" = "true" ]; then
        E2E_PASS=$((E2E_PASS + 1))
        E2E_STR="PASS"
      else
        E2E_STR="FAIL"
      fi

      printf "%-40s %-10s %-15s %-10s\n" "$ID" "$STMT_OK" "$([ "$BEST_TOOL" = "null" ] && echo "(none)" || echo "$BEST_TOOL" | tr -d '"')" "$E2E_STR"

      if [ "$JSON_FIRST" -eq 0 ]; then JSON_RECORDS="$JSON_RECORDS,"; fi
      JSON_FIRST=0
      JSON_RECORDS="$JSON_RECORDS$(jq -c -n \
        --arg id "$ID" \
        --arg nl "$NL" \
        --arg stmt "$STMT" \
        --argjson stmt_ok "$STMT_OK" \
        --argjson proof_ok "$PROOF_OK" \
        --argjson tool "$BEST_TOOL" \
        --argjson failure_stage "$FAILURE_STAGE" \
        '{id: $id, nl_input: $nl, generated_statement: $stmt, statement_compile_ok: $stmt_ok, proof_attempt_tool: $tool, proof_compile_ok: $proof_ok, e2e_pass: ($stmt_ok and $proof_ok), failure_stage: $failure_stage}')"
    done < <(jq -r '.benchmarks[].id' "$BENCHMARK")
    JSON_RECORDS="$JSON_RECORDS]"

    if [ -n "${JSON_OUT:-}" ]; then
      echo "$JSON_RECORDS" | jq '.' > "$JSON_OUT"
      echo ""
      echo "JSON records → $JSON_OUT"
    fi

    echo ""
    echo "=== Summary (n=$TOTAL) ==="
    echo "Spec compile pass:  $SPEC_PASS/$TOTAL"
    echo "Proof success (any solver): $PROOF_PASS/$TOTAL"
    echo "E2E pass:           $E2E_PASS/$TOTAL"
    if [ "$TOTAL" -gt 0 ]; then
      RATE=$(awk "BEGIN { printf \"%.1f\", ($E2E_PASS/$TOTAL)*100 }")
      echo "E2E pass rate:      ${RATE}%"
    fi
    ;;

  *)
    cat <<USAGE
Usage:
  $0 list [benchmark-file]                       # benchmark 一覧
  $0 run [benchmark-file]                        # e2e run (spec compile + proof attempt)

Default benchmark: $BENCHMARK_DEFAULT

例:
  $0 list
  JSON_OUT=results.json $0 run
USAGE
    ;;
esac
