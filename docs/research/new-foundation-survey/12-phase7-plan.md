# Phase 7 Plan: Proof Generation Setup (Day 207 draft)

Phase 6 ended on Day 205 with spec-generation infrastructure complete and main merged on Day 206 (`c406008`). The natural next step is proof generation: move from statement-only generation (`sorry`) to end-to-end proof automation under Lean 4.

## Direction

Primary direction for Phase 7 is proof generation with three tool tiers:

1. `Aesop` as the lowest-risk baseline for local proof search.
2. `Duper` as the stronger symbolic prover for equality / first-order shaped goals.
3. `LeanCopilot` as the highest-upside but highest-integration-cost LLM-assisted prover.

Target outcome is not "solve everything", but a reproducible benchmark that measures proof pass rate on the same generated statements produced in Phase 6 sprint 3 A. Expected pass rate remains **5-15%**, positioned against CLEVER's reported **0.6%** end-to-end setting.

## Paper / Tool Survey

- **Aesop (CPP 2023)**: white-box best-first proof search for Lean; good baseline because setup is light and it can emit proof scripts via `aesop?`.
- **Tactic Script Optimisation for Aesop (CPP 2025 artifact)**: relevant for Phase 7 because successful search should be materialised into stable scripts, not left as opaque automation only.
- **Lean Copilot (arXiv 2024, NeuS 2025 acceptance in repo README)**: native Lean integration for tactic suggestion, proof search, and premise selection; strongest candidate for proof generation beyond rule-based automation.
- **Duper (active Lean 4 prover)**: proof-producing superposition prover with portfolio mode; especially relevant for theorem shapes where Aesop stalls but symbolic search still works.
- **LeanDojo / ReProver (2023)** and **REAL-Prover (2025)**: useful external comparison points for benchmark design and future retrieval-augmented follow-up, but not required for Phase 7 sprint 1.

## Tooling Status and Constraints

Current project toolchain is `leanprover/lean4:v4.29.0`. As of **2026-04-27**, the latest stable Lean release is **v4.29.1** and **v4.30.0-rc2** is available; mathlib4 also has **v4.29.1** stable and **v4.30.0-rc2** pre-release.

Implications:

- Do **not** make Lean 4.30 upgrade the entry task for Phase 7.
- Prefer Phase 7 work on Lean 4.29.x first, then evaluate upgrade separately.
- `LeanCopilot` has the highest integration friction because it needs extra link args, model download, and native libraries.
- `Duper` is easier than LeanCopilot but still adds dependency/version coupling.
- `Aesop` should be the baseline path and benchmark control.

## Sprint Draft

### Sprint 1: tooling integration (2-4 Day)

Acceptance:
- `Aesop` integrated and proven on a minimal local theorem set.
- `Duper` integrated and proven on a minimal local theorem set.
- `LeanCopilot` integration attempted with explicit outcome: `integrated` or `blocked with cause`.
- A single harness can run `baseline`, `aesop`, `duper`, and `copilot` modes on the same theorem list.

### Sprint 2: benchmark setup (2-3 Day)

Acceptance:
- Phase 6 spec-generation outputs are frozen into a benchmark dataset.
- Benchmark cases are labeled by theorem shape (trivial, rewriting, constructor, arithmetic, quantified, higher-order).
- Output schema records `statement_ok`, `proof_ok`, `tool_used`, `time`, `heartbeats`, and failure class.
- At least 10 benchmark cases are runnable end-to-end.

### Sprint 3: pass-rate measurement (2-4 Day)

Acceptance:
- Pass rate is reported per tool and overall.
- Failure taxonomy is reported (`timeout`, `missing lemma`, `bad search space`, `reconstruction failure`, `tooling failure`).
- At least one "materialised proof script" example exists for each tool that succeeds.
- Phase 7 report states whether the 5-15% target was hit.

## PI Placement

- **PI-23 Mathlib slim profile**: keep in Phase 7 as **secondary maintenance / ζ'** work, only if benchmark throughput is blocked by build time. Do not let slimming distort proof-generation comparability before baseline numbers exist.
- **PI-24 Lean 4.30 upgrade**: keep in Phase 7 as **post-sprint-1 evaluation item**, not as gate. First check whether `Aesop`, `Duper`, and `LeanCopilot` all have an acceptable 4.30 path; otherwise stay on 4.29.x for benchmark integrity.

## Recommended Execution Order

1. Land this planning doc on `research/new-foundation`.
2. Create `release/phase7` later using the same Phase 5/6 merge pattern.
3. Start with `Aesop` baseline, then `Duper`, then `LeanCopilot`.
4. Freeze benchmark cases before tuning prompts or tactic parameters.
5. Measure pass rate before attempting PI-23 or PI-24.

## Merge / Governance Notes

- Commit message should carry compatibility classification: **compatible change**.
- Expected change category for this planning doc: **process_only**.
- Main merge strategy remains `release/phase7` + cherry-pick + PR, matching Phase 5/6.

## References

- Lean release notes: https://lean-lang.org/doc/reference/latest/releases/
- Lean releases: https://github.com/leanprover/lean4/releases
- mathlib4 releases: https://github.com/leanprover-community/mathlib4/releases
- Aesop repo: https://github.com/leanprover-community/aesop
- Aesop paper (CPP 2023): https://zenodo.org/records/7430233
- Aesop optimisation artifact (CPP 2025): https://zenodo.org/records/14343543
- Duper repo: https://github.com/leanprover-community/duper
- LeanCopilot repo: https://github.com/lean-dojo/LeanCopilot
- Lean Copilot paper: https://huggingface.co/papers/2404.12534
- LeanDojo paper: https://huggingface.co/papers/2306.15626
- REAL-Prover paper: https://huggingface.co/papers/2505.20613
- CLEVER benchmark: https://www.researchgate.net/publication/391911216_CLEVER_A_Curated_Benchmark_for_Formally_Verified_Code_Generation
