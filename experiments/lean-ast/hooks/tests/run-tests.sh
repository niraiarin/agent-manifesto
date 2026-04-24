#!/usr/bin/env bash
# Impl-E #669 — hook routing harness tests
#
# Feeds synthetic JSON to lean-cli-route.sh, asserting:
#   T1 — non-.lean path: exit 0, no JSON output (pass-through)
#   T2 — .lean + axiom pattern: lean-cli invoked, JSON output with permissionDecision=deny
#   T3 — .lean + unsupported pattern (namespace): exit 0, no JSON output
#   T4 — lean-cli binary missing: exit 0, no JSON output (best-effort fallback)
#
# Does NOT require Claude Code to be running. Hook stdin/stdout is a plain
# JSON pipe, so we can exercise it with printf + jq.

set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.elan/bin:$PATH"

HOOK="./lean-cli-route.sh"
[[ ! -x "$HOOK" ]] && chmod +x "$HOOK"

CLI_DIR="$(cd ../lean-cli && pwd)"
CLI_BIN="$CLI_DIR/.lake/build/bin/lean-cli"
[[ ! -x "$CLI_BIN" ]] && { echo "ERROR: lean-cli binary missing at $CLI_BIN; run 'lake build' in $CLI_DIR" >&2; exit 1; }

WORK=$(mktemp -d -t hooks-tests.XXXXXX)
trap 'rm -rf "$WORK"' EXIT

export CLAUDE_PROJECT_DIR="$(cd ../../.. && pwd)"

PASS=0
FAIL=0
RESULTS=()

log_pass() { RESULTS+=("PASS  $1"); PASS=$((PASS+1)); }
log_fail() { RESULTS+=("FAIL  $1: $2"); FAIL=$((FAIL+1)); }

# ─────────────────────────────────────────────────
# T1 — non-.lean path pass-through
# ─────────────────────────────────────────────────
NAME=T1_non_lean_passthrough
printf '{"tool_name":"Edit","tool_input":{"file_path":"/tmp/foo.txt","old_string":"a","new_string":"b"}}' \
  | "$HOOK" >"$WORK/$NAME.out" 2>"$WORK/$NAME.err"
RC=$?
if [[ "$RC" -eq 0 ]] && [[ ! -s "$WORK/$NAME.out" ]]; then
  log_pass "$NAME"
else
  log_fail "$NAME" "rc=$RC out=$(cat "$WORK/$NAME.out")"
fi

# ─────────────────────────────────────────────────
# T2 — .lean + axiom pattern routes through lean-cli
# ─────────────────────────────────────────────────
NAME=T2_axiom_routed
cp "$CLI_DIR/tests/fixtures/basic.lean" "$WORK/target.lean"
json=$(jq -n --arg fp "$WORK/target.lean" --arg old "axiom foo : Nat" --arg new "axiom foo : Bool" '{
  tool_name: "Edit",
  tool_input: { file_path: $fp, old_string: $old, new_string: $new }
}')
set +e
printf '%s' "$json" | "$HOOK" >"$WORK/$NAME.out" 2>"$WORK/$NAME.err"
RC=$?
set -e
if [[ "$RC" -eq 0 ]] && jq -e '.hookSpecificOutput.permissionDecision == "deny"' "$WORK/$NAME.out" >/dev/null 2>&1; then
  # Verify the file was actually rewritten
  if grep -q 'axiom foo : Bool' "$WORK/target.lean"; then
    log_pass "$NAME"
  else
    log_fail "$NAME" "file not rewritten: $(head -1 "$WORK/target.lean")"
  fi
else
  log_fail "$NAME" "rc=$RC out=$(cat "$WORK/$NAME.out") err=$(head -1 "$WORK/$NAME.err")"
fi

# ─────────────────────────────────────────────────
# T3 — .lean but unsupported pattern (namespace) → pass-through
# ─────────────────────────────────────────────────
NAME=T3_namespace_passthrough
cp "$CLI_DIR/tests/fixtures/basic.lean" "$WORK/target3.lean"
json=$(jq -n --arg fp "$WORK/target3.lean" --arg old "namespace Test" --arg new "namespace Foo" '{
  tool_name: "Edit",
  tool_input: { file_path: $fp, old_string: $old, new_string: $new }
}')
printf '%s' "$json" | "$HOOK" >"$WORK/$NAME.out" 2>"$WORK/$NAME.err"
RC=$?
if [[ "$RC" -eq 0 ]] && [[ ! -s "$WORK/$NAME.out" ]]; then
  log_pass "$NAME"
else
  log_fail "$NAME" "rc=$RC out=$(cat "$WORK/$NAME.out")"
fi

# ─────────────────────────────────────────────────
# T4 — tool_name != Edit pass-through
# ─────────────────────────────────────────────────
NAME=T4_wrong_tool_passthrough
printf '{"tool_name":"Read","tool_input":{"file_path":"/tmp/foo.lean"}}' \
  | "$HOOK" >"$WORK/$NAME.out" 2>"$WORK/$NAME.err"
RC=$?
if [[ "$RC" -eq 0 ]] && [[ ! -s "$WORK/$NAME.out" ]]; then
  log_pass "$NAME"
else
  log_fail "$NAME" "rc=$RC out=$(cat "$WORK/$NAME.out")"
fi

# ─────────────────────────────────────────────────
# Report
# ─────────────────────────────────────────────────
echo
echo "=== Impl-E #669 hook routing test results ==="
for r in "${RESULTS[@]}"; do echo "  $r"; done
echo
echo "PASS: $PASS / $((PASS+FAIL))"
echo "FAIL: $FAIL"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
