#!/usr/bin/env bash
# verify-extract-gate.sh — D17 extractStepValid runtime check
# Maps to DesignFoundation.lean L1595-1596:
#   extractStepValid(a) = a.allHaveTemporalValidity && (humanDecisionCount + llmInferenceCount > 0)
#
# Usage: bash verify-extract-gate.sh <model-spec.json>
# Exit 0 = PASS, Exit 1 = FAIL
set -euo pipefail

MODEL_SPEC="${1:?Usage: verify-extract-gate.sh <model-spec.json>}"

if [ ! -f "$MODEL_SPEC" ]; then
  echo '{"gate":"extractStepValid","verdict":"FAIL","reason":"model-spec.json not found"}' >&2
  exit 1
fi

# Condition 1: allHaveTemporalValidity
# Every assumption must have a non-null validity object
MISSING_VALIDITY=$(jq '[.assumptions // [] | .[] | select(.validity == null or .validity.sourceRef == null)] | length' "$MODEL_SPEC")

# Condition 2: humanDecisionCount + llmInferenceCount > 0
HUMAN_COUNT=$(jq '[.assumptions // [] | .[] | select(.type == "C")] | length' "$MODEL_SPEC")
LLM_COUNT=$(jq '[.assumptions // [] | .[] | select(.type == "H")] | length' "$MODEL_SPEC")
TOTAL=$(( HUMAN_COUNT + LLM_COUNT ))

ALL_VALID="true"
[ "$MISSING_VALIDITY" -gt 0 ] && ALL_VALID="false"

HAS_ASSUMPTIONS="true"
[ "$TOTAL" -eq 0 ] && HAS_ASSUMPTIONS="false"

RESULT=$(jq -n \
  --arg gate "extractStepValid" \
  --argjson allValid "$( [ "$ALL_VALID" = "true" ] && echo true || echo false )" \
  --argjson hasAssumptions "$( [ "$HAS_ASSUMPTIONS" = "true" ] && echo true || echo false )" \
  --argjson missingValidity "$MISSING_VALIDITY" \
  --argjson humanCount "$HUMAN_COUNT" \
  --argjson llmCount "$LLM_COUNT" \
  --argjson total "$TOTAL" \
  '{gate: $gate, allHaveTemporalValidity: $allValid, hasAssumptions: $hasAssumptions, missingValidity: $missingValidity, humanDecisionCount: $humanCount, llmInferenceCount: $llmCount, totalAssumptions: $total}')

if [ "$ALL_VALID" = "true" ] && [ "$HAS_ASSUMPTIONS" = "true" ]; then
  echo "$RESULT" | jq '. + {verdict: "PASS"}'
  exit 0
else
  echo "$RESULT" | jq '. + {verdict: "FAIL"}' >&2
  exit 1
fi
