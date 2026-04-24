import Manifest.Models.Assumptions.EpistemicLayer

/-!
# lean-ast CLI Conditional Design Foundation - Assumptions

Assumptions for the `experiments/lean-ast/lean-cli/` instance whose
technical feasibility was established by Research Parent Issue #654.

## Origin

The three LLM-inference assumptions identified in Sub-F (#661)
`concurrency-report.md` are lifted here as Assumption values so that
TemporalValidity can track staleness across Lean toolchain, macOS base
system, and Lean 4 runtime changes. See Impl-C (#667).

## Epistemic Source

All three are LLM Inference (H). Grounds: Sub-F empirical data
(0 corruption across 280 parallel invocations) and direct inspection
of the Lean 4 runtime implementation.

## TemporalValidity

- LA-H1 (prev CC-H*Sub-F-01): 365 days. POSIX / Lean 4 runtime write
  semantics are stable on this horizon.
- LA-H2 (prev CC-H*Sub-F-02): 180 days. Tracks macOS base-system
  shell-tool changes.
- LA-H3 (prev CC-H*Sub-F-03): 180 days. Tracks potential changes to
  Lean 4's olean / importModules implementation.
-/

namespace Manifest.Models.Instances.LeanAstCli

open Manifest
open Manifest.Models.Assumptions

-- ============================================================
-- H: Lean 4 runtime behavior (Sub-F derived)
-- ============================================================

/-- LA-H1 (prev CC-H*Sub-F-01): single-write(2) atomicity of
`IO.FS.writeBinFile` for small buffers. Sub-F #661 demonstrated
0 corruption across 280 parallel invocations. -/
def la_h1 : Assumption := {
  id := "LA-H1"
  source := .llmInference
    []
    "Refuted if buffer size grows past ~4KB so libc buffering splits writes, or if the target filesystem (NFS, FUSE, ...) does not provide inode-level locking."
  content := "Lean 4's `IO.FS.writeBinFile` writes payloads of ~4KB or less via an `fwrite` + `fclose` sequence in the C++ runtime (`src/runtime/io.cpp`) that results in a single `write(2)` syscall. POSIX does not guarantee atomicity of a single write to a regular file, but the Linux/macOS (APFS/ext4) implementations serialize writes through VFS-level inode locks, so the operation is atomic in practice. The lean-cli PoC's outputs (~50 bytes up to a few KB) fall within this regime. Empirical evidence: Sub-F #661 stress test observed 0 corruption across N=8 TRIALS=30 = 240 parallel plus N=2 TRIALS=20 = 40 parallel invocations."
  validity := some {
    sourceRef := "experiments/lean-ast/concurrency-stress/concurrency-report.md + Lean 4 src/runtime/io.cpp"
    lastVerified := "2026-04-23"
    reviewInterval := some 365
  }
}

/-- LA-H2 (prev CC-H*Sub-F-02): the macOS base system does not ship
the `flock(1)` command. -/
def la_h2 : Assumption := {
  id := "LA-H2"
  source := .llmInference
    []
    "Refuted if a future macOS release (14+ shell-tool expansion) ships `flock(1)` in the base system."
  content := "The macOS 14 base system does not include the `flock(1)` command. The `flock(2)` syscall exists as part of the BSD heritage, but the GNU coreutils `flock` binary must be installed separately (e.g., via Homebrew). The lean-cli therefore uses an `mkdir`-based advisory lock, whose behavior was verified by the Sub-F stress test."
  validity := some {
    sourceRef := "Sub-F stress.sh run log `flock: command not found` (log-n8/summary.json, log-n2/summary.json)"
    lastVerified := "2026-04-23"
    reviewInterval := some 180
  }
}

/-- LA-H3 (prev CC-H*Sub-F-03): per-process startup cost of
`importModules #[Init]`. It is not shared across parallel
invocations and dominates wall-clock overhead. -/
def la_h3 : Assumption := {
  id := "LA-H3"
  source := .llmInference
    []
    "Refuted if Lean 4 introduces a shared olean cache (mmap-based persistent) or a pre-loaded environment served over the Lean server protocol."
  content := "`importModules #[{ module := \\`Init }]` (Sub-D Profile A) incurs ~100 ms of startup per Lean process. Parallel invocations do not share this cost, so CPU/disk I/O contention produces wall-clock overhead. Empirical evidence: Sub-D #659 measured a warm median of 103 ms; Sub-F #661 measured a +5-17% overhead at N=2 and +103% at N=8; Impl-A #666 reproduced 124-138 ms warm invocation."
  validity := some {
    sourceRef := "experiments/lean-ast/startup-bench.md + experiments/lean-ast/concurrency-stress/concurrency-report.md"
    lastVerified := "2026-04-23"
    reviewInterval := some 180
  }
}

-- ============================================================
-- Instance manifest
-- ============================================================

/-- All lean-ast CLI instance assumptions. -/
def allAssumptions : List Assumption :=
  [la_h1, la_h2, la_h3]

end Manifest.Models.Instances.LeanAstCli
