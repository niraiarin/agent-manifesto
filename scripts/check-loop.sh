#!/usr/bin/env bash
# check-loop.sh — 全チェックをエラーゼロまでループ実行
#
# 修正後の検証を自動化する。deterministic_must_be_structural の運用実装。
# 各イテレーションで: lake build → test-all.sh → sync-counts.sh --check を実行。
# 不整合があれば sync-counts.sh --update で自動修正し、次のイテレーションへ。
#
# Usage:
#   bash scripts/check-loop.sh [--max-iterations N]
#
# Exit:
#   0 = 全チェック PASS
#   1 = max iterations 到達、未解決の問題あり
set -uo pipefail

BASE="$(cd "$(dirname "$0")/.." && pwd)"
LEAN_DIR="$BASE/lean-formalization"
MAX_ITER="${2:-3}"
if [[ "${1:-}" == "--max-iterations" ]]; then
  MAX_ITER="$2"
fi

for i in $(seq 1 "$MAX_ITER"); do
  echo ""
  echo "=== Iteration $i / $MAX_ITER ==="
  FAILED=0

  # --- 0. Lean import integrity ---
  echo "--- check-lean-imports ---"
  if bash "$BASE/scripts/check-lean-imports.sh" 2>&1; then
    echo "PASS"
  else
    echo "FAIL: Lean import integrity check failed. Fix before building."
    FAILED=$((FAILED + 1))
  fi

  # --- 1. Lean build ---
  echo "--- lake build ---"
  BUILD_OUT=$(cd "$LEAN_DIR" && export PATH="$HOME/.elan/bin:$PATH" && lake build Manifest 2>&1)
  if echo "$BUILD_OUT" | grep -q "Build completed successfully"; then
    echo "PASS: $(echo "$BUILD_OUT" | grep 'Build completed')"
  else
    echo "FAIL: Lean build failed"
    echo "$BUILD_OUT" | grep "error:" | head -5
    FAILED=$((FAILED + 1))
  fi

  # --- 2. Tests ---
  echo "--- tests ---"
  TEST_OUT=$(bash "$BASE/tests/test-all.sh" 2>&1)
  TEST_TOTAL=$(echo "$TEST_OUT" | grep "^TOTAL:" | head -1)
  echo "$TEST_TOTAL"
  if echo "$TEST_TOTAL" | grep -q "0 failed"; then
    echo "PASS"
  else
    echo "FAIL: Tests failed"
    FAILED=$((FAILED + 1))
  fi

  # --- 3. Count sync ---
  echo "--- sync-counts --check ---"
  SYNC_OUT=$(SYNC_SKIP_TESTS=1 bash "$BASE/scripts/sync-counts.sh" --check 2>&1)
  if echo "$SYNC_OUT" | grep -q "All files in sync"; then
    echo "PASS: All files in sync"
  else
    DRIFT=$(echo "$SYNC_OUT" | grep -c "^DIFF:" || true)
    echo "DRIFT: $DRIFT file(s) out of sync. Auto-fixing..."
    SYNC_SKIP_TESTS=1 bash "$BASE/scripts/sync-counts.sh" --update 2>&1 | grep -E "Updated|Found"
    FAILED=$((FAILED + 1))

    # sync 修正後は lake build が必要（rfl 値が変わる可能性）
    echo "--- re-building after sync ---"
    REBUILD_OUT=$(cd "$LEAN_DIR" && export PATH="$HOME/.elan/bin:$PATH" && lake build Manifest 2>&1)
    if ! echo "$REBUILD_OUT" | grep -q "Build completed successfully"; then
      echo "FAIL: Rebuild after sync failed"
      echo "$REBUILD_OUT" | grep "error:" | head -5
    fi
  fi

  # --- 4. 結果判定 ---
  if [[ $FAILED -eq 0 ]]; then
    echo ""
    echo "=== All checks PASS (iteration $i). Loop complete. ==="
    exit 0
  else
    echo ""
    echo "--- $FAILED check(s) failed. Continuing to iteration $((i + 1))... ---"
  fi
done

echo ""
echo "=== Max iterations ($MAX_ITER) reached. Unresolved issues remain. ==="
exit 1
