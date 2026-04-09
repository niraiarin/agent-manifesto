#!/usr/bin/env bash
# verify-investigate-gate.sh — D17 investigateStepValid runtime check
# Maps to DesignFoundation.lean:
#   investigateStepValid(r) =
#     r.investigationPasses >= 2 &&
#     r.categoriesCovered == r.categoriesTotal &&
#     r.decisionCount > 0 &&
#     r.sourceCount > 0
#
# Usage: bash verify-investigate-gate.sh <investigation-report.json>
# Exit 0 = PASS, Exit 1 = FAIL
set -euo pipefail

REPORT="${1:?Usage: verify-investigate-gate.sh <investigation-report.json>}"

if [ ! -f "$REPORT" ]; then
  echo '{"gate":"investigateStepValid","verdict":"FAIL","reason":"report file not found"}' >&2
  exit 1
fi

PASSES=$(jq '.investigationPasses // 0' "$REPORT")
CAT_COVERED=$(jq '.categoriesCovered // 0' "$REPORT")
CAT_TOTAL=$(jq '.categoriesTotal // 0' "$REPORT")
DECISIONS=$(jq '.decisionCount // 0' "$REPORT")
SOURCES=$(jq '.sourceCount // 0' "$REPORT")

# Condition 1: investigationPasses >= 2
PASSES_OK=$( [ "$PASSES" -ge 2 ] && echo true || echo false )

# Condition 2: categoriesCovered == categoriesTotal
CATS_OK=$( [ "$CAT_COVERED" -eq "$CAT_TOTAL" ] && [ "$CAT_TOTAL" -gt 0 ] && echo true || echo false )

# Condition 3: decisionCount > 0
DECISIONS_OK=$( [ "$DECISIONS" -gt 0 ] && echo true || echo false )

# Condition 4: sourceCount > 0
SOURCES_OK=$( [ "$SOURCES" -gt 0 ] && echo true || echo false )

RESULT=$(jq -n \
  --arg gate "investigateStepValid" \
  --argjson passes "$PASSES" \
  --argjson categoriesCovered "$CAT_COVERED" \
  --argjson categoriesTotal "$CAT_TOTAL" \
  --argjson decisionCount "$DECISIONS" \
  --argjson sourceCount "$SOURCES" \
  --argjson passesOk "$( [ "$PASSES_OK" = true ] && echo true || echo false )" \
  --argjson catsOk "$( [ "$CATS_OK" = true ] && echo true || echo false )" \
  --argjson decisionsOk "$( [ "$DECISIONS_OK" = true ] && echo true || echo false )" \
  --argjson sourcesOk "$( [ "$SOURCES_OK" = true ] && echo true || echo false )" \
  '{gate: $gate, investigationPasses: $passes, categoriesCovered: $categoriesCovered, categoriesTotal: $categoriesTotal, decisionCount: $decisionCount, sourceCount: $sourceCount, checks: {passesGe2: $passesOk, categoriesComplete: $catsOk, hasDecisions: $decisionsOk, hasSources: $sourcesOk}}')

if [ "$PASSES_OK" = true ] && [ "$CATS_OK" = true ] && [ "$DECISIONS_OK" = true ] && [ "$SOURCES_OK" = true ]; then
  echo "$RESULT" | jq '. + {verdict: "PASS"}'
  exit 0
else
  echo "$RESULT" | jq '. + {verdict: "FAIL"}' >&2
  exit 1
fi
