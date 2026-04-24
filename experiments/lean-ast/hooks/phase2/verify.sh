#!/usr/bin/env bash
# Impl-E #669 Phase 2 — verify Claude Code session outcomes.
#
# Run after going through experiments/lean-ast/hooks/phase2/prompts.md in a
# Claude Code session. This script checks:
#   - trace.log entries (hook was invoked, made the expected decisions)
#   - fixture file contents (matches expected post-state)
#
# USAGE:
#   bash experiments/lean-ast/hooks/phase2/verify.sh

set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

TRACE="experiments/lean-ast/hooks/phase2/trace.log"
FIX="experiments/lean-ast/hooks/phase2/fixtures"

PASS=0
FAIL=0
RESULTS=()

log_pass() { RESULTS+=("PASS  $1"); PASS=$((PASS+1)); }
log_fail() { RESULTS+=("FAIL  $1: $2"); FAIL=$((FAIL+1)); }

echo "=== Impl-E #669 Phase 2 verification ==="
if [[ ! -f "$TRACE" ]]; then
  echo "ERROR: trace.log missing at $TRACE" >&2
  echo "Did you export LEAN_CLI_HOOK_TRACE_FILE before starting Claude Code?" >&2
  exit 1
fi

# ─────────────────────────────────────────────────
# P1 — axiom Edit on fixtures/P1-axiom.lean should have been routed.
# Expected: trace.log has "engaged-success target=foo" for this file,
# and the file content is the post-edit expected content.
# ─────────────────────────────────────────────────
NAME=P1_axiom_routed
if grep -q "result=engaged-success target=foo" "$TRACE" \
   && grep -q "file=.*P1-axiom.lean" "$TRACE"; then
  if grep -q 'axiom foo : Bool' "$FIX/P1-axiom.lean" \
     && grep -q 'axiom bar : Bool' "$FIX/P1-axiom.lean"; then
    log_pass "$NAME (hook engaged + file rewritten)"
  else
    log_fail "$NAME" "trace shows engaged-success but file content unexpected: $(cat "$FIX/P1-axiom.lean" | tr '\n' '|')"
  fi
else
  log_fail "$NAME" "trace.log does not contain engaged-success for P1-axiom.lean"
fi

# ─────────────────────────────────────────────────
# P2 — Edit on a non-.lean file should have passed through.
# Expected: trace.log has "passthrough-not-lean" for this file.
# File content should be whatever the Edit tool wrote (e.g., "world phase2")
# or unchanged if the user did not actually trigger Edit.
# ─────────────────────────────────────────────────
NAME=P2_non_lean_passthrough
if grep -q "result=passthrough-not-lean" "$TRACE" \
   && grep -q "file=.*P2-non-lean.txt" "$TRACE"; then
  log_pass "$NAME (hook passthrough on non-.lean file)"
else
  log_fail "$NAME" "trace.log does not contain passthrough-not-lean for P2-non-lean.txt"
fi

# ─────────────────────────────────────────────────
# P3 — Edit on a namespace line (unsupported pattern) should have passed
# through. Expected: trace.log has "passthrough-unsupported-pattern" for
# this file.
# ─────────────────────────────────────────────────
NAME=P3_unsupported_pattern_passthrough
if grep -q "result=passthrough-unsupported-pattern" "$TRACE" \
   && grep -q "file=.*P3-unsupported-pattern.lean" "$TRACE"; then
  log_pass "$NAME (hook passthrough on unsupported pattern)"
else
  log_fail "$NAME" "trace.log does not contain passthrough-unsupported-pattern for P3-unsupported-pattern.lean"
fi

# ─────────────────────────────────────────────────
# Report
# ─────────────────────────────────────────────────
echo
for r in "${RESULTS[@]}"; do echo "  $r"; done
echo
echo "PASS: $PASS / $((PASS+FAIL))"
echo "FAIL: $FAIL"

echo
echo "--- trace.log contents ---"
cat "$TRACE"
echo "--------------------------"
echo
echo "Copy the above into the results-template.md and attach to Issue #669."

[[ $FAIL -eq 0 ]] && exit 0 || exit 1
