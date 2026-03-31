#!/usr/bin/env bash
set -uo pipefail
PASS=0; FAIL=0
BASE="$(git rev-parse --show-toplevel 2>/dev/null || echo /Users/nirarin/work/agent-manifesto)"

echo "=== Phase 5: Scripts Structural Tests ==="

check() {
  local name="$1" cond="$2"
  echo -n "$name... "
  if eval "$cond"; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL"; FAIL=$((FAIL+1)); fi
}

# ============================================================
# sync-counts.sh テスト
# ============================================================
echo "--- sync-counts.sh ---"

check "SS.1: scripts/sync-counts.sh exists" \
  "[ -f '$BASE/scripts/sync-counts.sh' ]"

check "SS.2: sync-counts.sh supports --check mode (grep)" \
  "grep -q '\-\-check' '$BASE/scripts/sync-counts.sh'"

check "SS.3: sync-counts.sh --check outputs measurement results (grep)" \
  "grep -q 'theorems\|axioms' '$BASE/scripts/sync-counts.sh'"

check "SS.4: sync-counts.sh supports --dry-run mode (grep)" \
  "grep -q '\-\-dry-run' '$BASE/scripts/sync-counts.sh'"

check "SS.5: sync-counts.sh computes THEOREM_COUNT" \
  "grep -q 'THEOREM_COUNT' '$BASE/scripts/sync-counts.sh'"

check "SS.6: sync-counts.sh computes AXIOM_COUNT" \
  "grep -q 'AXIOM_COUNT' '$BASE/scripts/sync-counts.sh'"

echo ""

# ============================================================
# check-loop.sh テスト（構造検証のみ、実行なし）
# ============================================================
echo "--- check-loop.sh ---"

check "CL.1: scripts/check-loop.sh exists" \
  "[ -f '$BASE/scripts/check-loop.sh' ]"

check "CL.2: check-loop.sh parses --max-iterations option" \
  "grep -q '\-\-max-iterations' '$BASE/scripts/check-loop.sh'"

check "CL.3: check-loop.sh includes lake build step" \
  "grep -q 'lake build' '$BASE/scripts/check-loop.sh'"

check "CL.4: check-loop.sh includes test-all.sh step" \
  "grep -q 'test-all.sh' '$BASE/scripts/check-loop.sh'"

check "CL.5: check-loop.sh includes sync-counts.sh --check step" \
  "grep -q 'sync-counts.*--check' '$BASE/scripts/check-loop.sh'"

echo ""

# ============================================================
# verify-preflight.sh テスト
# ============================================================
echo "--- verify-preflight.sh ---"

check "VP.1: scripts/verify-preflight.sh exists" \
  "[ -f '$BASE/scripts/verify-preflight.sh' ]"

check "VP.2: verify-preflight.sh supports --stdin mode" \
  "grep -q '\-\-stdin' '$BASE/scripts/verify-preflight.sh'"

check "VP.3: verify-preflight.sh generates JSON output (preflight_checks key)" \
  "grep -q 'preflight_checks' '$BASE/scripts/verify-preflight.sh'"

check "VP.4: verify-preflight.sh calls sync-counts.sh --check" \
  "grep -q 'sync-counts.*--check\|sync-counts.sh.*--check' '$BASE/scripts/verify-preflight.sh'"

echo ""

# ============================================================
# manifest-trace derivations テスト
# ============================================================
echo "--- manifest-trace derivations ---"

check "MT.1: manifest-trace derivations subcommand exists in help" \
  "grep -q 'derivations' '$BASE/manifest-trace'"

check "MT.2: manifest-trace derivations returns valid JSON Lines (pilot card)" \
  "'$BASE/manifest-trace' derivations 2>/dev/null | grep -q 'theorem'"

check "MT.3: parse_lean_derivations handles Derivation Card in Procedure.lean" \
  "'$BASE/manifest-trace' derivations 2>/dev/null | grep -q 't0_contraction_forbidden'"

echo ""

# ============================================================
# 結果サマリ
# ============================================================
echo "=== Results: $PASS passed, $FAIL failed ==="
echo ""

if [ "$FAIL" -gt 0 ]; then
  exit 1
else
  exit 0
fi
