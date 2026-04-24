# Impl-E #669 Phase 2 — live verification protocol

Phase 1 (committed under `experiments/lean-ast/hooks/`) landed the routing
hook and its synthetic-JSON unit tests. Phase 2 verifies that Claude
Code actually honours `hookSpecificOutput.permissionDecision = "deny"`
when the hook engages — the one condition Sub-G #662 closed as
CONDITIONAL because it required a live Claude Code runtime.

## What this kit does

1. Installs `lean-cli-route.sh` into `.claude/hooks/` and registers it
   in `.claude/settings.local.json` (git-ignored).
2. Creates three fixture files and instructs you to drive Claude Code
   through three prompts.
3. Collects evidence from a trace log produced by the hook.
4. Generates a results template you paste into Issue #669.
5. Rolls everything back when you are done.

## Files

| Path | Purpose |
|------|---------|
| `setup.sh` | Install hook + create fixtures. Idempotent. |
| `prompts.md` | Three Claude Code prompts (copy-paste). |
| `verify.sh` | Automated post-session check against `trace.log`. |
| `results-template.md` | Fill-in evidence report for Issue #669. |
| `rollback.sh` | Uninstall hook + restore `settings.local.json`. |
| `trace.log` (generated) | Produced by the hook when `LEAN_CLI_HOOK_TRACE_FILE` is exported. |
| `fixtures/` (generated) | Three test inputs + their pre-state snapshots. |

## Happy path

```bash
# 1. Install
bash experiments/lean-ast/hooks/phase2/setup.sh

# 2. Export trace env and start a fresh Claude Code
export LEAN_CLI_HOOK_TRACE_FILE="$PWD/experiments/lean-ast/hooks/phase2/trace.log"
claude

#    → inside Claude Code, follow experiments/lean-ast/hooks/phase2/prompts.md
#      (three prompts). Exit Claude Code when done.

# 3. Verify
bash experiments/lean-ast/hooks/phase2/verify.sh

# 4. Record evidence into results-template.md and post to Issue #669.

# 5. Rollback
bash experiments/lean-ast/hooks/phase2/rollback.sh
```

## Important caveats

- **Governance-sensitive file**: `.claude/hooks/` and `settings.local.json`
  are governance configuration. The agent (Claude in automated mode)
  cannot modify them; you run the scripts yourself in a plain shell.
- **Recursion warning**: if you run Phase 2 inside the same Claude Code
  session that has been producing all this code, the hook will also
  intercept that session's own `.lean` Edits. The cleanest approach is
  to open a second terminal, run `setup.sh`, start a fresh `claude`
  instance there, and do the testing in that fresh session.
- **Sub-G invocation pattern**: the hook invokes lean-cli via the
  subshell pattern `(cd "$CLI_PKG" && .lake/build/bin/lean-cli ...)` so
  the lean-toolchain next to the package is honoured. This matches
  Sub-G #662 invocation variant I2.
- **Rollback is clean**: `rollback.sh` restores the pre-setup state of
  `settings.local.json` and removes the copied hook file. The
  Phase 1 artifacts under `experiments/lean-ast/hooks/` are not
  touched.

## When the test succeeds

The PASS criteria are:

- `verify.sh` reports 3 / 3 PASS.
- The trace log contains:
  - `engaged-success target=foo` for the P1 fixture
  - `passthrough-not-lean` for the P2 fixture
  - `passthrough-unsupported-pattern` for the P3 fixture
- `fixtures/P1-axiom.lean` ends with the lean-cli-generated content
  (both `foo` and optionally `bar` rewritten if you ran the P1 sub-step).

When the evidence is posted to Issue #669, the Gate flips from
CONDITIONAL to PASS and Parent #665 can receive its overall judgment.
