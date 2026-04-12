#!/usr/bin/env bash
# validate-evolve-entry.sh — evolve-history.jsonl エントリの整合性検証
# Input:  stdin (JSON single-line entry)
# Output: JSON result { "pass": true/false, "checks": [...] }
# Exit:   0 = all checks pass, 1 = one or more checks fail
#
# Checks:
#   C1: proposals_count == pass_count + fail_count
#   C2: len(rejected) >= fail_count
#   C3a: len(improvements) <= pass_count
#   C3b: len(improvements) >= 0
#   C5: if judge != null, judge.evaluated == judge.pass + judge.conditional + judge.fail
#   C6: each rejected entry has failure_type (if fail_count > 0)
#   C7: required fields present (run, timestamp, result, improvements, rejected, commits, lean, tests, phases, notes)
#   C8: phases.judge must exist (non-null) — Judge results are deterministic observable facts
#   C9: proposals_count + skipped_count + t6_count + deferred_count >= findings_count (#475)

set -euo pipefail

INPUT=$(cat)

if [ -z "$INPUT" ]; then
  echo '{"pass": false, "checks": [{"id": "C0", "name": "non_empty_input", "pass": false, "message": "Input is empty"}]}'
  exit 1
fi

# Validate that input is valid JSON
if ! echo "$INPUT" | jq '.' > /dev/null 2>&1; then
  echo '{"pass": false, "checks": [{"id": "C0", "name": "valid_json", "pass": false, "message": "Input is not valid JSON"}]}'
  exit 1
fi

CHECKS='[]'
OVERALL_PASS=true

add_check() {
  local id="$1"
  local name="$2"
  local pass="$3"
  local message="$4"
  CHECKS=$(echo "$CHECKS" | jq --arg id "$id" --arg name "$name" --argjson pass "$pass" --arg message "$message" \
    '. + [{"id": $id, "name": $name, "pass": $pass, "message": $message}]')
  if [ "$pass" = "false" ]; then
    OVERALL_PASS=false
  fi
}

# Extract fields
PASS_COUNT=$(echo "$INPUT" | jq '.phases.verifier.pass_count // 0')
FAIL_COUNT=$(echo "$INPUT" | jq '.phases.verifier.fail_count // 0')
PROPOSALS=$(echo "$INPUT" | jq '.phases.hypothesizer.proposals_count // 0')
IMP_LEN=$(echo "$INPUT" | jq '.improvements | length')
REJ_LEN=$(echo "$INPUT" | jq '.rejected | length')

# C1: proposals_count == pass_count + fail_count
EXPECTED_PROPOSALS=$((PASS_COUNT + FAIL_COUNT))
if [ "$PROPOSALS" -eq "$EXPECTED_PROPOSALS" ]; then
  add_check "C1" "proposals_sum" "true" "proposals_count=$PROPOSALS == pass_count($PASS_COUNT) + fail_count($FAIL_COUNT)"
else
  add_check "C1" "proposals_sum" "false" "proposals_count=$PROPOSALS != pass_count($PASS_COUNT) + fail_count($FAIL_COUNT) (expected $EXPECTED_PROPOSALS)"
fi

# C2: len(rejected) >= fail_count
if [ "$REJ_LEN" -ge "$FAIL_COUNT" ]; then
  add_check "C2" "rejected_count" "true" "len(rejected)=$REJ_LEN >= fail_count=$FAIL_COUNT"
else
  add_check "C2" "rejected_count" "false" "len(rejected)=$REJ_LEN < fail_count=$FAIL_COUNT"
fi

# C3a: len(improvements) <= pass_count
if [ "$IMP_LEN" -le "$PASS_COUNT" ]; then
  add_check "C3a" "improvements_upper_bound" "true" "len(improvements)=$IMP_LEN <= pass_count=$PASS_COUNT"
else
  add_check "C3a" "improvements_upper_bound" "false" "len(improvements)=$IMP_LEN > pass_count=$PASS_COUNT"
fi

# C3b: len(improvements) >= 0 (always true, but check non-negative)
if [ "$IMP_LEN" -ge 0 ]; then
  add_check "C3b" "improvements_non_negative" "true" "len(improvements)=$IMP_LEN >= 0"
else
  add_check "C3b" "improvements_non_negative" "false" "len(improvements)=$IMP_LEN < 0"
fi

# C5: if judge != null, judge.evaluated == judge.pass + judge.conditional + judge.fail
JUDGE_NULL=$(echo "$INPUT" | jq '.phases.judge == null')
if [ "$JUDGE_NULL" = "true" ]; then
  add_check "C5" "judge_sum" "true" "judge is null (not applicable)"
else
  JUDGE_EVALUATED=$(echo "$INPUT" | jq '.phases.judge.evaluated // 0')
  JUDGE_PASS=$(echo "$INPUT" | jq '.phases.judge.pass // 0')
  JUDGE_CONDITIONAL=$(echo "$INPUT" | jq '.phases.judge.conditional // 0')
  JUDGE_FAIL=$(echo "$INPUT" | jq '.phases.judge.fail // 0')
  JUDGE_SUM=$((JUDGE_PASS + JUDGE_CONDITIONAL + JUDGE_FAIL))
  if [ "$JUDGE_EVALUATED" -eq "$JUDGE_SUM" ]; then
    add_check "C5" "judge_sum" "true" "judge.evaluated=$JUDGE_EVALUATED == pass($JUDGE_PASS)+conditional($JUDGE_CONDITIONAL)+fail($JUDGE_FAIL)"
  else
    add_check "C5" "judge_sum" "false" "judge.evaluated=$JUDGE_EVALUATED != pass($JUDGE_PASS)+conditional($JUDGE_CONDITIONAL)+fail($JUDGE_FAIL) (sum=$JUDGE_SUM)"
  fi
fi

# C6: each rejected entry has failure_type (if fail_count > 0)
if [ "$FAIL_COUNT" -gt 0 ] && [ "$REJ_LEN" -gt 0 ]; then
  MISSING_FT=$(echo "$INPUT" | jq '[.rejected[] | select(.failure_type == null or .failure_type == "")] | length')
  if [ "$MISSING_FT" -eq 0 ]; then
    add_check "C6" "failure_type_presence" "true" "all $REJ_LEN rejected entries have failure_type"
  else
    add_check "C6" "failure_type_presence" "false" "$MISSING_FT rejected entries missing failure_type"
  fi
else
  add_check "C6" "failure_type_presence" "true" "fail_count=$FAIL_COUNT (not applicable or no rejected entries)"
fi

# C7: required fields present
REQUIRED_FIELDS='["run","timestamp","result","improvements","rejected","commits","lean","tests","phases","notes"]'
MISSING_FIELDS=$(echo "$INPUT" | jq --argjson req "$REQUIRED_FIELDS" \
  '[$req[] | select(. as $f | input_object_keys | index($f) == null)] | @json' \
  2>/dev/null || echo '[]')
# Alternative approach that works without input_object_keys
MISSING_FIELDS=$(echo "$INPUT" | jq -r \
  '["run","timestamp","result","improvements","rejected","commits","lean","tests","phases","notes"] |
   map(. as $f | if $f as $k | input | has($k) then empty else . end) | @json' \
  2>/dev/null || echo "check_failed")

# Use simpler approach
MISSING_COUNT=0
for field in run timestamp result improvements rejected commits lean tests phases notes; do
  if ! echo "$INPUT" | jq -e "has(\"$field\")" > /dev/null 2>&1; then
    MISSING_COUNT=$((MISSING_COUNT + 1))
  fi
done

if [ "$MISSING_COUNT" -eq 0 ]; then
  add_check "C7" "required_fields" "true" "all required fields present"
else
  add_check "C7" "required_fields" "false" "$MISSING_COUNT required field(s) missing"
fi

# C8: phases.judge must exist (non-null)
JUDGE_EXISTS=$(echo "$INPUT" | jq '.phases.judge != null')
if [ "$JUDGE_EXISTS" = "true" ]; then
  add_check "C8" "judge_present" "true" "phases.judge is present"
else
  add_check "C8" "judge_present" "false" "phases.judge is null or missing — Judge results must be recorded (deterministic observable fact)"
fi

# C9: proposals_count + skipped_count + t6_count + deferred_count >= findings_count (#475)
FINDINGS=$(echo "$INPUT" | jq '.phases.observer.findings_count // 0')
SKIPPED_COUNT=$(echo "$INPUT" | jq '.phases.hypothesizer.skipped_items // [] | length')
T6_COUNT=$(echo "$INPUT" | jq '.phases.hypothesizer.t6_items // [] | length')
DEFERRED_COUNT=$(echo "$INPUT" | jq '.deferred // [] | length')
ACCOUNTED=$((PROPOSALS + SKIPPED_COUNT + T6_COUNT + DEFERRED_COUNT))
if [ "$FINDINGS" -gt 0 ]; then
  if [ "$ACCOUNTED" -ge "$FINDINGS" ]; then
    add_check "C9" "full_processing" "true" "accounted=$ACCOUNTED (proposals=$PROPOSALS+skipped=$SKIPPED_COUNT+t6=$T6_COUNT+deferred=$DEFERRED_COUNT) >= findings=$FINDINGS"
  else
    add_check "C9" "full_processing" "false" "accounted=$ACCOUNTED (proposals=$PROPOSALS+skipped=$SKIPPED_COUNT+t6=$T6_COUNT+deferred=$DEFERRED_COUNT) < findings=$FINDINGS — silent drop detected"
  fi
else
  add_check "C9" "full_processing" "true" "findings_count=0 or missing (not applicable)"
fi

# Output result
echo "$CHECKS" | jq --argjson pass "$OVERALL_PASS" '{"pass": $pass, "checks": .}'

if [ "$OVERALL_PASS" = "true" ]; then
  exit 0
else
  exit 1
fi
