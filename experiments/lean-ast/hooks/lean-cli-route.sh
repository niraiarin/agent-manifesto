#!/usr/bin/env bash
# Impl-E #669 — PreToolUse hook: route Edit on *.lean files through lean-cli.
#
# This is the Phase-1 artifact. Phase 2 (copying to ~/.claude/hooks/ and
# registering in .claude/settings.json) requires human approval per
# L1 safety (.claude/hooks/* is governance configuration).
#
# See experiments/lean-ast/invocation-spec.md (Sub-G #662) for the full
# routing design and JSON protocol.
#
# Behaviour:
#   - tool != Edit                       → exit 0 (pass-through)
#   - file_path !~ *.lean or missing     → exit 0
#   - lean-cli binary missing            → exit 0 (best-effort: let Edit handle)
#   - conservative single-decl match OK  → run `lean-cli edit`; on success emit
#     hookSpecificOutput JSON to suppress Edit. On failure exit 0 (Edit proceeds).
#   - no match                            → exit 0 (let Edit proceed)
#
# Exit codes returned to Claude Code:
#   0 → continue (Edit proceeds, or Edit suppressed via JSON output)
#   2 → block (only for explicit parse_failure abort; rarely used)
#
# Invocation: read JSON from stdin, emit JSON on stdout, stderr for logs.

set -euo pipefail

input=$(cat)

tool_name=$(printf '%s' "$input" | jq -r '.tool_name // ""')
file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // ""')
old_string=$(printf '%s' "$input" | jq -r '.tool_input.old_string // ""')
new_string=$(printf '%s' "$input" | jq -r '.tool_input.new_string // ""')

# Gate: only engage on Edit tool
[[ "$tool_name" != "Edit" ]] && exit 0
[[ -z "$file_path" ]] && exit 0
[[ ! -f "$file_path" ]] && exit 0
case "$file_path" in
  *.lean) ;;
  *) exit 0 ;;
esac

# Resolve project structure
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || true)}"
[[ -z "$PROJECT_DIR" ]] && exit 0

# Locate lean-cli package dir. We invoke via subshell + `lake env` so the
# lean-toolchain file in the package dir is honoured. See Sub-G #662 invocation
# pattern I2 (subshell-scoped cd; parent cwd unaffected).
CLI_PKG="$PROJECT_DIR/experiments/lean-ast/lean-cli"
[[ ! -d "$CLI_PKG/.lake/build" ]] && exit 0
[[ ! -f "$CLI_PKG/lean-toolchain" ]] && exit 0
export PATH="$HOME/.elan/bin:$PATH"

# Conservative subcommand inference.
# We engage ONLY when old_string is a single-line axiom/theorem/def declaration
# whose name we can extract unambiguously. Anything else falls through to Edit.
#
# Supported patterns (old_string, anchored on first line):
#   axiom <name> : <rest>
#   theorem <name> : <rest>
#   def <name> : <rest>
#   def <name> (...) : <rest>     -- heuristic: name is 2nd token
#
# The replacement is the ENTIRE new_string (caller is responsible for keeping
# it a valid single declaration; lean-cli edit --replace-body replaces the
# Syntax range, so trailing newlines / comments in new_string are user intent).

first_line=$(printf '%s' "$old_string" | head -n1)
case "$first_line" in
  "axiom "*|"theorem "*|"def "*|"abbrev "*|"instance "*)
    # Extract second whitespace-delimited token as name
    target_name=$(printf '%s' "$first_line" | awk '{print $2}' | sed 's/[:()]$//')
    ;;
  *)
    # Not a pattern we route. Let Edit proceed.
    exit 0
    ;;
esac

if [[ -z "$target_name" ]]; then
  exit 0
fi

# Prepare tmp output. The hook's CLI invocation writes to a tmp file
# and, on success, atomically replaces the target file. This mirrors the
# atomic-rename pattern already built into lean-cli (Impl-B #663) and
# keeps the Edit tool's semantics (file modified in place) intact.
tmp_out=$(mktemp "${TMPDIR:-/tmp}/lean-cli-route.XXXXXX.lean")
trap 'rm -f "$tmp_out"' EXIT

set +e
# Subshell-scoped cd so the lean-toolchain file next to lake-cli is resolved.
(cd "$CLI_PKG" && .lake/build/bin/lean-cli edit "$file_path" \
  --replace-body "$target_name" "$new_string" \
  --output "$tmp_out") >/dev/null 2>"$tmp_out.err"
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  # Success: atomically replace and suppress Edit.
  mv -f "$tmp_out" "$file_path"
  # Emit hookSpecificOutput to instruct Claude Code that the edit is done.
  # Format per docs.claude.com/en/docs/claude-code/hooks-guide (PreToolUse).
  jq -n --arg decl "$target_name" --arg path "$file_path" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      additionalContext: ("[lean-cli] applied replace-body for " + $decl + " in " + $path + "; Edit suppressed.")
    }
  }'
  exit 0
fi

# lean-cli failed. Let Edit proceed; surface the reason to context.
err_head=$(head -n1 "$tmp_out.err" 2>/dev/null || echo "unknown")
jq -n --arg err "$err_head" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    additionalContext: ("[lean-cli] fallback to Edit: " + $err)
  }
}'
exit 0
