#!/usr/bin/env bash
# verify-construct-gate.sh — D17 constructStepValid runtime check
# Maps to DesignFoundation.lean L1586-1587:
#   constructStepValid(r) = r.sorryCount == 0 && r.buildSuccess
#
# Usage: bash verify-construct-gate.sh <lean-dir> [module-name]
# Exit 0 = PASS, Exit 1 = FAIL
set -euo pipefail

LEAN_DIR="${1:?Usage: verify-construct-gate.sh <lean-dir> [module-name]}"
MODULE="${2:-Manifest}"

if [ ! -d "$LEAN_DIR" ]; then
  echo '{"gate":"constructStepValid","verdict":"FAIL","reason":"lean directory not found"}' >&2
  exit 1
fi

# Run lake build — this is the authoritative source for both conditions
BUILD_OUTPUT=$(cd "$LEAN_DIR" && lake build "$MODULE" 2>&1) || true

# Condition 1: sorryCount == 0 (from lake build output)
SORRY_COUNT=$(echo "$BUILD_OUTPUT" | grep -c "declaration uses 'sorry'" || true)

# Condition 2: buildSuccess (no error lines)
BUILD_SUCCESS="true"
if echo "$BUILD_OUTPUT" | grep -q "error:"; then
  BUILD_SUCCESS="false"
fi

RESULT=$(jq -n \
  --arg gate "constructStepValid" \
  --argjson sorryCount "$SORRY_COUNT" \
  --argjson buildSuccess "$( [ "$BUILD_SUCCESS" = "true" ] && echo true || echo false )" \
  '{gate: $gate, sorryCount: $sorryCount, buildSuccess: $buildSuccess}')

if [ "$SORRY_COUNT" -eq 0 ] && [ "$BUILD_SUCCESS" = "true" ]; then
  echo "$RESULT" | jq '. + {verdict: "PASS"}'
  exit 0
else
  echo "$RESULT" | jq '. + {verdict: "FAIL"}' >&2
  exit 1
fi
