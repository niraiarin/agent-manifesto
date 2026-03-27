#!/usr/bin/env bash
# PoC Hook のバリデーションスイート
# G1: 技術的実現可能性 / G2: 検出率 / G3: false positive

set -euo pipefail

HOOK="$(dirname "$0")/poc-hallucination-hook.sh"
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
export HALLUCINATION_HOOK_MODE=WARN
# PoC はプロジェクトルートを明示指定
export HALLUCINATION_HOOK_PROJECT_ROOT="/Users/nirarin/work/agent-manifesto"

PASS=0
FAIL=0
TOTAL=0

run_check() {
  local desc="$1"
  local input="$2"
  local expect_warn="$3"  # "yes" or "no"

  TOTAL=$((TOTAL + 1))
  local stderr_output
  stderr_output=$(echo "$input" | bash "$HOOK" 2>&1 >/dev/null || true)

  if [ "$expect_warn" = "yes" ]; then
    if [ -n "$stderr_output" ]; then
      PASS=$((PASS + 1))
      echo "  PASS: $desc"
    else
      FAIL=$((FAIL + 1))
      echo "  FAIL: $desc (expected warning, got none)"
    fi
  else
    if [ -n "$stderr_output" ]; then
      FAIL=$((FAIL + 1))
      echo "  FAIL: $desc (unexpected warning: $stderr_output)"
    else
      PASS=$((PASS + 1))
      echo "  PASS: $desc"
    fi
  fi
}

echo "=== G1: 技術的実現可能性 ==="
echo ""
echo "--- True Positive Checks (should warn) ---"

# TP1: 存在しない Lean 定義名
run_check "TP1: non-existent Lean def" \
  '{"tool_name":"Edit","tool_input":{"file_path":"'"$PROJECT_ROOT"'/doc.md","new_string":"The theorem `fake_nonexistent_theorem` proves safety."}}' \
  "yes"

# TP2: 間違った axiom count
run_check "TP2: wrong axiom count" \
  '{"tool_name":"Edit","tool_input":{"file_path":"'"$PROJECT_ROOT"'/doc.md","new_string":"Currently we have 99 axioms in the formalization."}}' \
  "yes"

# TP3: 間違った theorem count
run_check "TP3: wrong theorem count" \
  '{"tool_name":"Edit","tool_input":{"file_path":"'"$PROJECT_ROOT"'/doc.md","new_string":"The project contains 500 theorems."}}' \
  "yes"

# TP4: 存在しない定義名（実際の名前に似せた偽名）
run_check "TP4: plausible but fake Lean def" \
  '{"tool_name":"Edit","tool_input":{"file_path":"'"$PROJECT_ROOT"'/doc.md","new_string":"See `stasis_always_healthy` in Evolution.lean."}}' \
  "yes"

echo ""
echo "--- True Negative Checks (should NOT warn) ---"

# TN1: 存在する Lean 定義名 (camelCase — アンダースコアなし、検査対象外)
run_check "TN1: real Lean def stasisUnhealthy (camelCase)" \
  '{"tool_name":"Edit","tool_input":{"file_path":"'"$PROJECT_ROOT"'/doc.md","new_string":"The axiom `stasisUnhealthy` formalizes this."}}' \
  "no"

# TN2: 正しい axiom count
run_check "TN2: correct axiom count" \
  '{"tool_name":"Edit","tool_input":{"file_path":"'"$PROJECT_ROOT"'/doc.md","new_string":"Currently we have 63 axioms."}}' \
  "no"

# TN3: 正しい theorem count
run_check "TN3: correct theorem count" \
  '{"tool_name":"Edit","tool_input":{"file_path":"'"$PROJECT_ROOT"'/doc.md","new_string":"The project contains 288 theorems."}}' \
  "no"

# TN4: .lean ファイルへの書き込み（検査対象外）
run_check "TN4: .lean file (not checked)" \
  '{"tool_name":"Edit","tool_input":{"file_path":"'"$PROJECT_ROOT"'/code.lean","new_string":"theorem fake_thing : True := trivial"}}' \
  "no"

# TN5: 一般的なコマンド名（除外対象）
run_check "TN5: excluded command names" \
  '{"tool_name":"Edit","tool_input":{"file_path":"'"$PROJECT_ROOT"'/doc.md","new_string":"Run `bash` and `grep` for results."}}' \
  "no"

# TN6: JSON フィールド名（除外対象）
run_check "TN6: excluded field names" \
  '{"tool_name":"Edit","tool_input":{"file_path":"'"$PROJECT_ROOT"'/doc.md","new_string":"The `failure_type` and `failure_subtype` fields track errors."}}' \
  "no"

# TN7: 存在する定義名 (snake_case)
run_check "TN7: real Lean def breaking_change_dominates" \
  '{"tool_name":"Edit","tool_input":{"file_path":"'"$PROJECT_ROOT"'/doc.md","new_string":"See `breaking_change_dominates` in Evolution.lean."}}' \
  "no"

# TN8: 数値が含まれるが count パターンではない
run_check "TN8: number without count pattern" \
  '{"tool_name":"Edit","tool_input":{"file_path":"'"$PROJECT_ROOT"'/doc.md","new_string":"Run 63 completed with 4 improvements."}}' \
  "no"

echo ""
echo "--- Performance Check ---"

LARGE_CONTENT="The manifesto defines stasisUnhealthy and breaking_change_dominates as core theorems. We also reference integration_requires_verification and feedback_precedes_improvement. There are 63 axioms and 288 theorems in total. The validPhaseTransition function governs phase transitions. Some fake_hallucinated_name might appear."

START_TIME=$(python3 -c 'import time; print(time.time())')
echo '{"tool_name":"Edit","tool_input":{"file_path":"'"$PROJECT_ROOT"'/doc.md","new_string":"'"$LARGE_CONTENT"'"}}' | bash "$HOOK" 2>/dev/null || true
END_TIME=$(python3 -c 'import time; print(time.time())')
ELAPSED=$(python3 -c "print(f'{$END_TIME - $START_TIME:.3f}')")
echo "  Execution time: ${ELAPSED}s (target: < 2s)"
if python3 -c "import sys; sys.exit(0 if $END_TIME - $START_TIME < 2.0 else 1)"; then
  echo "  PASS: Performance within target"
  PASS=$((PASS + 1))
else
  echo "  FAIL: Performance exceeds target"
  FAIL=$((FAIL + 1))
fi
TOTAL=$((TOTAL + 1))

echo ""
echo "=== Results ==="
echo "PASS: $PASS / $TOTAL"
echo "FAIL: $FAIL / $TOTAL"
echo "Pass rate: $(python3 -c "print(f'{$PASS/$TOTAL*100:.1f}%')")"
