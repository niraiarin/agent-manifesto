# Impl-E #669 Phase 2 — Claude Code prompts

Copy each prompt **verbatim** into a Claude Code session (one at a time) and
watch how Claude responds. You do not need Claude to complete anything
beyond the Edit call — what we are checking is whether the hook fires
and whether `permissionDecision: deny` actually suppresses the Edit.

## Pre-conditions

1. You have already run `bash experiments/lean-ast/hooks/phase2/setup.sh`.
2. You exported the trace env var **before** starting Claude Code:
   ```bash
   export LEAN_CLI_HOOK_TRACE_FILE="$PWD/experiments/lean-ast/hooks/phase2/trace.log"
   claude
   ```
3. This is a **fresh Claude Code session** in the project root
   (`/Users/nirarin/work/agent-manifesto-lean-ast`).

> If you instead want to test inside this very session, the hook will
> also apply to my own Edit tool calls. That is fine but surprising:
> I will see Edit denials in my tool trace. Run `rollback.sh` afterwards.

## Prompt P1 — positive routing (axiom replacement)

Paste this into Claude Code:

```
Use the Edit tool on experiments/lean-ast/hooks/phase2/fixtures/P1-axiom.lean
to change the line
  axiom foo : Nat
to
  axiom foo : Bool

Then also change
  axiom bar : Bool
stays the same — only change foo.
```

Expected observations:

- Claude attempts an `Edit` tool call.
- The hook emits JSON with `permissionDecision: "deny"` and an
  `additionalContext` mentioning `[lean-cli] applied replace-body for foo`.
- Claude's tool trace should show the Edit as denied / suppressed.
- The file on disk should end up as:
  ```
  axiom foo : Bool
  axiom bar : Bool
  ```
  That final state is produced by `lean-cli edit`, not by the Edit tool.

Now ask Claude to Edit **bar** as well (optional second sub-step):

```
Same file, now change
  axiom bar : Bool
to
  axiom bar : Nat
```

This should produce another `engaged-success target=bar` trace entry and
rewrite `bar` to `axiom bar : Nat`.

## Prompt P2 — passthrough on a non-.lean file

```
Use the Edit tool on experiments/lean-ast/hooks/phase2/fixtures/P2-non-lean.txt
to change the line
  hello phase2
to
  world phase2
```

Expected observations:

- Claude issues an `Edit` tool call.
- The hook runs but exits 0 silently with trace `passthrough-not-lean`.
- Claude's Edit proceeds normally and the file becomes `world phase2`.

## Prompt P3 — passthrough on an unsupported pattern

```
Use the Edit tool on experiments/lean-ast/hooks/phase2/fixtures/P3-unsupported-pattern.lean
to change
  namespace Phase2
to
  namespace Phase2Renamed
```

Expected observations:

- Claude issues an `Edit` tool call.
- The hook runs, extracts `first_line = "namespace Phase2"`, does not match
  the `axiom|theorem|def|abbrev|instance` pattern, so writes trace
  `passthrough-unsupported-pattern` and exits 0.
- Claude's Edit proceeds normally.

## When done

1. Exit the Claude Code session (Ctrl-D or `/exit`).
2. From a regular shell:
   ```bash
   bash experiments/lean-ast/hooks/phase2/verify.sh
   ```
3. Paste the `verify.sh` output + the contents of `trace.log` into
   `experiments/lean-ast/hooks/phase2/results-template.md` and attach
   it to Issue #669 as a comment.
4. When the evidence has been posted, run:
   ```bash
   bash experiments/lean-ast/hooks/phase2/rollback.sh
   ```
