# Impl-F #670 — lean-cli CI workflow

`.github/workflows/lean-cli.yml` runs on every push / PR that touches
the lean-ast experiment artifacts (plus manual `workflow_dispatch`).

## Jobs

| Job | Trigger | Purpose |
|-----|---------|---------|
| `build-and-test` | always | `lake build` + Impl-A integration tests (7), Sub-E byte-preserving tests (14), Impl-E hook routing tests (4). Runs on macOS + Ubuntu. |
| `perf-regression` | always, depends on `build-and-test` | 22 warm `lean-cli parse` invocations (drop first 2 as warmup); asserts p95 ≤ `CI_PERF_GATE_MS` env (default 250 ms). GitHub macos-latest runners steady-state around 170 ms p95 (observed 2026-04-24); a 250 ms Gate lets real regressions (≥ 2x) fire while tolerating ambient variance. Dev machines should re-enable 130 ms locally by exporting `CI_PERF_GATE_MS=130`. |
| `lake-concurrency` | `workflow_dispatch` with `run_lake_concurrency=true` | Runs Impl-D `stress.sh` (destructive `.lake/build` wipe). Gated behind manual opt-in to avoid slow CI runs by default. Uploads `log/summary.json` as an artifact. |

## Gate mapping

| Impl-F Gate (issue #670) | Workflow job | Threshold |
|--------------------------|--------------|-----------|
| (a) build + tests pass on macOS + Ubuntu | `build-and-test` | non-zero job exit fails the check |
| (b) p95 ≤ `CI_PERF_GATE_MS` (default 250 ms on macos-latest; 130 ms for dev M1) | `perf-regression` | Python script `sys.exit` if exceeded |
| (c) PR check registration | GitHub branch protection (manual setup) | — |
| (d) regression threshold enforcement | `perf-regression` | see (b) |

## Opt-in lake-concurrency (Impl-D Gate evidence)

The destructive Impl-D #668 stress harness runs only when the workflow is
manually dispatched:

```
gh workflow run lean-cli.yml -f run_lake_concurrency=true
```

The workflow uploads `experiments/lean-ast/lake-concurrency/log/summary.json`.
Attach it to issue #668 to flip its Gate from CONDITIONAL to PASS.

## Why not run full stress on every PR?

- Impl-D `stress.sh` wipes `.lake/build/` and performs a cold rebuild; it
  burns CI minutes and blocks other PRs behind it.
- Sub-F `concurrency-stress/stress.sh` executes 240 parallel CLI invocations
  at N=8; on shared runners this can flake on load.
- Impl-E Phase 2 (hook install + live Edit) requires Claude Code running,
  not available on CI.

These heavy checks stay manual or human-gated; the workflow default keeps
PR latency low.
