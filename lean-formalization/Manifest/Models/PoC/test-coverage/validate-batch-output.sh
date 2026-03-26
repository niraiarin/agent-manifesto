#!/usr/bin/env bash
# validate-batch-output.sh — バッチ出力の scenario_id 範囲 + スキーマバリデーション
#
# Usage:
#   validate-batch-output.sh -f <batch.json> --range <start>-<end>
#   validate-batch-output.sh -f <batch.json> --expected-ids 221,222,...,230
#   validate-batch-output.sh -f <batch.json> --count 10
#   validate-batch-output.sh --scan-dir <dir> --total-range 1-300
#
# Exit codes:
#   0 = all checks pass
#   1 = validation failure (details on stderr)
#   2 = usage error
set -euo pipefail

usage() {
  cat <<'USAGE' >&2
Usage:
  validate-batch-output.sh -f <batch.json> [OPTIONS]
  validate-batch-output.sh --scan-dir <dir> --total-range <start>-<end>

Single file validation:
  -f, --file FILE        Batch JSON file to validate
  --range START-END      Expected scenario_id range (inclusive)
  --expected-ids ID,...  Expected scenario_ids (comma-separated)
  --count N              Expected number of scenarios
  --strict               Fail on any schema warning (default: warn only)

Directory scan (find gaps across all batch files):
  --scan-dir DIR         Directory containing batch-*.json files
  --total-range S-E      Expected total scenario_id range

Schema checks (always run):
  - scenario_id: integer, present
  - project: non-empty string
  - model_spec: object with layers[] and propositions[]
  - model_spec.layers[].name: non-empty string
  - model_spec.layers[].ordValue: integer
  - model_spec.propositions[].id: non-empty string
  - model_spec.propositions[].layer: non-empty string
USAGE
  exit 2
}

# --- Argument parsing ---
FILE=""
RANGE_START=""
RANGE_END=""
EXPECTED_IDS=""
EXPECTED_COUNT=""
STRICT=false
SCAN_DIR=""
TOTAL_RANGE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -f|--file)       FILE="$2"; shift 2 ;;
    --range)
      RANGE_START="${2%-*}"; RANGE_END="${2#*-}"; shift 2 ;;
    --expected-ids)  EXPECTED_IDS="$2"; shift 2 ;;
    --count)         EXPECTED_COUNT="$2"; shift 2 ;;
    --strict)        STRICT=true; shift ;;
    --scan-dir)      SCAN_DIR="$2"; shift 2 ;;
    --total-range)
      TOTAL_RANGE="$2"; shift 2 ;;
    -h|--help)       usage ;;
    *)               echo "Unknown option: $1" >&2; usage ;;
  esac
done

# --- Directory scan mode ---
if [[ -n "$SCAN_DIR" ]]; then
  if [[ -z "$TOTAL_RANGE" ]]; then
    echo "ERROR: --total-range required with --scan-dir" >&2
    exit 2
  fi
  tr_start="${TOTAL_RANGE%-*}"
  tr_end="${TOTAL_RANGE#*-}"

  # Collect all scenario_ids from all batch files
  all_ids=$(for f in "$SCAN_DIR"/batch-*.json; do
    [[ -f "$f" ]] && jq -r '.[].scenario_id' "$f" 2>/dev/null
  done | sort -un)

  # Find missing
  missing=()
  for ((id=tr_start; id<=tr_end; id++)); do
    if ! echo "$all_ids" | grep -qx "$id"; then
      missing+=("$id")
    fi
  done

  total=$((tr_end - tr_start + 1))
  found=$(echo "$all_ids" | wc -l | tr -d ' ')

  echo "=== Directory Scan: $SCAN_DIR ==="
  echo "Expected range: $tr_start-$tr_end ($total scenarios)"
  echo "Found: $found scenarios"

  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "Missing ${#missing[@]} scenarios:"
    # Group consecutive IDs into ranges for readability
    range_start="${missing[0]}"
    range_end="${missing[0]}"
    for ((i=1; i<${#missing[@]}; i++)); do
      if [[ $((missing[i])) -eq $((range_end + 1)) ]]; then
        range_end="${missing[i]}"
      else
        if [[ "$range_start" == "$range_end" ]]; then
          echo "  S${range_start}"
        else
          echo "  S${range_start}-S${range_end}"
        fi
        range_start="${missing[i]}"
        range_end="${missing[i]}"
      fi
    done
    if [[ "$range_start" == "$range_end" ]]; then
      echo "  S${range_start}"
    else
      echo "  S${range_start}-S${range_end}"
    fi
    exit 1
  else
    echo "All scenarios present."
    exit 0
  fi
fi

# --- Single file validation mode ---
if [[ -z "$FILE" ]]; then
  echo "ERROR: -f <file> required" >&2
  usage
fi

if [[ ! -f "$FILE" ]]; then
  echo "ERROR: File not found: $FILE" >&2
  exit 1
fi

# Check valid JSON array
if ! jq -e 'type == "array"' "$FILE" > /dev/null 2>&1; then
  echo "ERROR: $FILE is not a JSON array" >&2
  exit 1
fi

ERRORS=0
WARNINGS=0
COUNT=$(jq '. | length' "$FILE")

# --- Count check ---
if [[ -n "$EXPECTED_COUNT" ]] && [[ "$COUNT" -ne "$EXPECTED_COUNT" ]]; then
  echo "ERROR: Expected $EXPECTED_COUNT scenarios, got $COUNT" >&2
  ERRORS=$((ERRORS + 1))
fi

# --- Derive expected IDs from range if not explicitly given ---
if [[ -n "$RANGE_START" ]] && [[ -z "$EXPECTED_IDS" ]]; then
  ids=""
  for ((i=RANGE_START; i<=RANGE_END; i++)); do
    [[ -n "$ids" ]] && ids="${ids},"
    ids="${ids}${i}"
  done
  EXPECTED_IDS="$ids"
  if [[ -z "$EXPECTED_COUNT" ]]; then
    EXPECTED_COUNT=$((RANGE_END - RANGE_START + 1))
    if [[ "$COUNT" -ne "$EXPECTED_COUNT" ]]; then
      echo "ERROR: Expected $EXPECTED_COUNT scenarios (range $RANGE_START-$RANGE_END), got $COUNT" >&2
      ERRORS=$((ERRORS + 1))
    fi
  fi
fi

# --- Scenario ID range check ---
if [[ -n "$EXPECTED_IDS" ]]; then
  actual_ids=$(jq -r '.[].scenario_id' "$FILE" | sort -n)
  IFS=',' read -ra expected_arr <<< "$EXPECTED_IDS"

  for eid in "${expected_arr[@]}"; do
    if ! echo "$actual_ids" | grep -qx "$eid"; then
      echo "ERROR: Missing scenario_id $eid" >&2
      ERRORS=$((ERRORS + 1))
    fi
  done

  # Check for unexpected IDs
  for aid in $actual_ids; do
    found=false
    for eid in "${expected_arr[@]}"; do
      if [[ "$aid" == "$eid" ]]; then found=true; break; fi
    done
    if ! $found; then
      echo "WARNING: Unexpected scenario_id $aid (not in expected range)" >&2
      WARNINGS=$((WARNINGS + 1))
    fi
  done
fi

# --- Schema validation per scenario ---
for ((i=0; i<COUNT; i++)); do
  sid=$(jq -r ".[$i].scenario_id" "$FILE")
  prefix="S${sid}"

  # Required top-level fields
  for field in scenario_id project model_spec; do
    val=$(jq -r ".[$i].$field // \"__MISSING__\"" "$FILE")
    if [[ "$val" == "__MISSING__" ]] || [[ "$val" == "null" ]]; then
      echo "ERROR: $prefix missing required field '$field'" >&2
      ERRORS=$((ERRORS + 1))
    fi
  done

  # scenario_id must be integer
  if ! jq -e ".[$i].scenario_id | type == \"number\"" "$FILE" > /dev/null 2>&1; then
    echo "ERROR: $prefix scenario_id is not a number" >&2
    ERRORS=$((ERRORS + 1))
  fi

  # project must be non-empty string
  proj=$(jq -r ".[$i].project // \"\"" "$FILE")
  if [[ -z "$proj" ]]; then
    echo "ERROR: $prefix project is empty" >&2
    ERRORS=$((ERRORS + 1))
  fi

  # namespace must be a non-empty string
  ns=$(jq -r ".[$i].model_spec.namespace // \"\"" "$FILE")
  if [[ -z "$ns" ]]; then
    echo "WARNING: $prefix model_spec.namespace is empty or missing" >&2
    WARNINGS=$((WARNINGS + 1))
  fi

  # model_spec must have layers (array, non-empty) and propositions (array, non-empty)
  has_layers=$(jq ".[$i].model_spec.layers // [] | length" "$FILE")
  has_props=$(jq ".[$i].model_spec.propositions // [] | length" "$FILE")

  if [[ "$has_layers" -eq 0 ]]; then
    echo "ERROR: $prefix model_spec.layers is empty or missing" >&2
    ERRORS=$((ERRORS + 1))
  fi
  if [[ "$has_props" -eq 0 ]]; then
    echo "ERROR: $prefix model_spec.propositions is empty or missing" >&2
    ERRORS=$((ERRORS + 1))
  fi

  # Validate each layer
  for ((j=0; j<has_layers; j++)); do
    lname=$(jq -r ".[$i].model_spec.layers[$j].name // \"\"" "$FILE")
    lord=$(jq ".[$i].model_spec.layers[$j].ordValue // -1" "$FILE")
    if [[ -z "$lname" ]]; then
      echo "WARNING: $prefix layers[$j].name is empty" >&2
      WARNINGS=$((WARNINGS + 1))
    fi
    if [[ "$lord" -lt 0 ]]; then
      echo "WARNING: $prefix layers[$j].ordValue missing or negative" >&2
      WARNINGS=$((WARNINGS + 1))
    fi
  done

  # Validate each proposition
  for ((j=0; j<has_props; j++)); do
    pid=$(jq -r ".[$i].model_spec.propositions[$j].id // \"\"" "$FILE")
    # Accept both "layer" and "layerName" (both formats exist in the data)
    player=$(jq -r ".[$i].model_spec.propositions[$j] | (.layer // .layerName // \"\")" "$FILE")
    if [[ -z "$pid" ]]; then
      echo "WARNING: $prefix propositions[$j].id is empty" >&2
      WARNINGS=$((WARNINGS + 1))
    fi
    if [[ -z "$player" ]]; then
      echo "WARNING: $prefix propositions[$j].layer is empty" >&2
      WARNINGS=$((WARNINGS + 1))
    fi
  done
done

# --- Summary ---
echo "=== Validation: $(basename "$FILE") ==="
echo "Scenarios: $COUNT"
[[ $ERRORS -gt 0 ]] && echo "Errors: $ERRORS" >&2
[[ $WARNINGS -gt 0 ]] && echo "Warnings: $WARNINGS" >&2

if [[ $ERRORS -gt 0 ]]; then
  exit 1
elif $STRICT && [[ $WARNINGS -gt 0 ]]; then
  exit 1
else
  [[ $ERRORS -eq 0 ]] && [[ $WARNINGS -eq 0 ]] && echo "All checks passed."
  exit 0
fi
