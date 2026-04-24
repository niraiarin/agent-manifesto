# Impl-D #668 — Lake-level concurrent race verification

Harness + execution protocol for verifying Lake build-cache concurrency
behavior surrounding the lean-cli package.

## Files

- `stress.sh` — three-test harness
  - T1: warm `lake exe lean-cli` × 4 parallel (binary-level race probe under `lake env`)
  - T2: concurrent `lake build lean-cli` × 2 (Lake build lock serialization probe)
  - T3: cold `lake build lean-cli` (wall-clock measurement after `.lake/build/` wipe)

## Gate criteria (from Issue #668)

PASS (all):
- (a) cold state parallel `lake exe` → 0 corruption
- (b) 2 shell simultaneous `lake build` → both succeed, Lake serializes writes
- (c) cold build wall-clock ≤ 120 s
- (d) binary invocation wall-clock ≤ Sub-D Profile A baseline + 25 %

CONDITIONAL: specific race encountered but pre-build mitigation suffices.
FAIL: Lake cache corrupts or pre-build cannot prevent races.

## Execution protocol

The harness performs destructive operations on `experiments/lean-ast/lean-cli/.lake/`
and therefore requires explicit human approval before running. To execute:

```bash
bash experiments/lean-ast/lake-concurrency/stress.sh
```

This will:

1. Pre-build the lean-cli once (warm).
2. Run T1 — four parallel `lake exe` (non-destructive).
3. Run T2 — two parallel `lake build` (modifies `.lake/build/` but serialized by Lake).
4. Run T3 — delete `.lake/build/` and perform a cold build (destructive, reversible).
5. Emit `log/summary.json` with per-test metrics and pass flags.

Expected runtime: several minutes on a warm Mac (M1 arm64). The first run needs
`lake build` dependencies already fetched; run from a worktree whose `.lake/` has
been initialized once.

## Current status

- Harness committed (`experiments/lean-ast/lake-concurrency/stress.sh`).
- First execution deferred to user / CI. The automated agent (Claude Code)
  was blocked from running the destructive portions of the harness.
- Impl-D Gate therefore held at CONDITIONAL until execution evidence is
  attached to Issue #668. Impl-F #670 (CI integration) is the natural home
  for continuous execution of this harness alongside Impl-A's integration tests.

## Reference

- Sub-F #661 `concurrency-stress/` — binary-level race probe (already PASS,
  280 parallel invocations, 0 corruption).
- Sub-D #659 `startup-bench.md` — Profile A baseline for wall-clock Gate.
- Impl-B #663 — atomic rename; reduces T1 corruption surface to zero.
