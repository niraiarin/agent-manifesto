# Impl-E #669 — PreToolUse hook routing

Phase 1 artifact: the hook script and its integration tests, stored under
`experiments/lean-ast/hooks/` so that installation into the real
`.claude/hooks/` directory remains a human-gated Phase 2 step (L1 safety
requires human approval for governance configuration).

## Files

- `lean-cli-route.sh` — the hook. Reads Claude Code's PreToolUse JSON on
  stdin, routes supported `.lean` Edits through `lean-cli edit`, and emits
  `hookSpecificOutput` JSON on stdout to suppress Edit when the CLI
  succeeds.
- `tests/run-tests.sh` — 4 synthetic-JSON tests (non-.lean passthrough,
  axiom routing, unsupported-pattern passthrough, wrong-tool passthrough).
  Runs without requiring Claude Code to be live.

## Routing behaviour

The hook engages only when **all** of the following hold:

1. `tool_name == "Edit"`
2. `tool_input.file_path` exists and ends in `.lean`
3. Project root is resolvable via `$CLAUDE_PROJECT_DIR` or `git`
4. lean-cli package is built (`.lake/build/` present) and has a
   `lean-toolchain` file
5. `old_string` begins with a supported keyword
   (`axiom` / `theorem` / `def` / `abbrev` / `instance`)
6. The second whitespace-delimited token of `old_string` is a non-empty
   identifier

On engagement the hook:

1. Invokes `lean-cli edit <file> --replace-body <name> <new_string>
   --output <tmp>` inside a subshell that `cd`s into the package dir so
   the `lean-toolchain` file resolves correctly.
2. On success (exit 0): atomically `mv` the tmp file onto the target
   path, then emit `hookSpecificOutput.permissionDecision = "deny"` with
   an informational `additionalContext` so Claude Code suppresses the
   Edit.
3. On failure (any non-zero exit): emit `additionalContext` with the
   first stderr line, then `exit 0` so the Edit proceeds as a fallback.

All other cases fall through via `exit 0` without any JSON output.

## Phase 2 — installation (human only)

L1 Safety (`.claude/rules/l1-safety.md`) reserves modifications to
`.claude/hooks/` and `.claude/settings.json` for human review. To enable
the hook for a running project:

```bash
# 1. Copy the hook into the project's hook directory
cp experiments/lean-ast/hooks/lean-cli-route.sh .claude/hooks/

# 2. Register it in .claude/settings.json under hooks.PreToolUse.Edit
#    Example entry (merge with existing hooks; do not replace):
#    {
#      "hooks": {
#        "PreToolUse": {
#          "Edit": [
#            {"command": "bash $CLAUDE_PROJECT_DIR/.claude/hooks/lean-cli-route.sh"}
#          ]
#        }
#      }
#    }
```

After editing `settings.json` the user should restart Claude Code so the
new hook is loaded.

## Running the tests

```bash
bash experiments/lean-ast/hooks/tests/run-tests.sh
```

Prerequisites:

- `lake build` already executed once in `experiments/lean-ast/lean-cli/`
  so the binary and `.lake/build/` are present (Impl-A #666).
- `jq` available on PATH (Claude Code environment ships it).

## Sub-G CONDITIONAL stabilization

Sub-G #662 closed as CONDITIONAL because the `hookSpecificOutput` JSON
protocol had been specified but not exercised against a real Claude Code
instance. Impl-E carries that item forward:

- The hook emits the exact JSON envelope (`hookEventName`,
  `permissionDecision`, `additionalContext`) that Sub-G specified.
- The unit tests validate the JSON shape with `jq -e` assertions.
- End-to-end verification against live Claude Code is Phase 2 — the
  human installs the hook, triggers an Edit on a `.lean` file, and
  confirms the Edit is suppressed. That evidence can be attached to
  Issue #669 to flip the Gate to PASS.

Until Phase 2 evidence is posted, Impl-E Gate remains CONDITIONAL.

## Known scope limits

- Only single-line declarations whose name is the 2nd whitespace token
  are routed. Multi-line signatures, partial-body edits, and attribute
  modifications fall through to Edit.
- `$CLAUDE_PROJECT_DIR` is required or fallback to `git rev-parse`
  top-level. Hook will bail out silently if neither resolves.
- The CLI package location (`experiments/lean-ast/lean-cli/`) is
  hard-coded relative to the project root. A symlink or env override
  would let the hook work in alternate layouts; deferred.
