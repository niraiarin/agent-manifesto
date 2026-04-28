# Phase 8 Plan: CLEVER Same-Condition End-to-End Measurement (Day 217 draft)

Phase 7 ended on Day 215 with proof-generation framework (Aesop/Duper integration + harness + benchmark + failure taxonomy + materialised scripts) at 12/12 acceptance, main merged on Day 216 (`26a7431`). The natural next step is Phase 8: connect Phase 6 spec-gen and Phase 7 proof-gen into a single end-to-end pipeline and measure pass rate under CLEVER same-condition (NL task → spec → proof, no in-domain hints).

## Direction

Primary direction for Phase 8 is **CLEVER same-condition end-to-end measurement**:

1. Glue Phase 6 spec-generation (subagent dispatch with NL → Lean statement) and Phase 7 proof-generation (Aesop/Duper portfolio).
2. Measure end-to-end pass rate (NL task → final compiled theorem) on a benchmark not biased by existing project vocabulary.
3. Compare with CLEVER's reported 0.6%; target band remains **5-15% (≥10x improvement vs CLEVER)**.

Secondary directions (parallel sprints or Phase 9):
- Phase 6 spec-gen freeze with AgentSpec namespace handling (sprint 2 #1 carry-over from Phase 7).
- Failure taxonomy refinement using internal solver stats (timeout vs missing_lemma vs search_too_deep separation).
- LeanCopilot 再評価 once v4.29.0+ upstream release lands.

Deferred infrastructure (Phase 9 candidates):
- PI-23 Mathlib slim profile.
- PI-24 Lean 4.30 upgrade.

## Why CLEVER Same-Condition Is the Critical Measurement

Phase 7 results (in-domain v0.2.0): aesop 83.3%, duper 66.7% — far above 5-15% target band. Honest interpretation:
- The benchmark theorems were pre-stated in Lean syntax (constrained input).
- Solvers operated on already-typed goals with explicit hypotheses.
- No NL → spec translation in the loop.

CLEVER's 0.6% measures **the full chain failing**: most commonly the spec is wrong, or the spec is right but the proof tooling cannot close it. Without measuring the full chain, our 5-15% claim is unverified.

Phase 8 closes this gap.

## Paper / Tool Survey

- **CLEVER (NeurIPS 2025)**: 0.6% end-to-end pass rate baseline. Our reference point.
- **LeanDojo / ReProver (NeurIPS 2023)**: retrieval-augmented theorem proving. Useful pattern for premise selection in Phase 8 sprint 2.
- **REAL-Prover (2025)**: combines retrieval with multi-shot proof attempts. Potential model for Phase 8 sprint 3 portfolio.
- **Aesop / Duper from Phase 7**: reused as proof tier; new addition is the NL→spec layer above them.
- **Phase 6 spec-gen subagent template** (Day 203 PoC): existing prompt template for NL → Lean statement, used in Day 204 5/5 PoC. Phase 8 sprint 1 builds on this.

## Tooling Status and Constraints

Toolchain: still `leanprover/lean4:v4.29.0`. As of Day 217 (2026-04-27), no upstream change since Phase 7 plan (Day 207). Lean 4.29.1 stable available, 4.30.0-rc2 unchanged.

Implications:
- Stay on 4.29.x for Phase 8 (PI-24 still deferred).
- Subagent dispatch infrastructure (Claude Code Agent tool) is the spec-gen execution path; bash/json wrappers script the harness.
- Phase 6 spec-gen evaluation harness (`scripts/eval-spec-generation.sh`) and Phase 7 proof harness (`scripts/proof-harness.sh`) need to merge into a single end-to-end harness.
- LeanCopilot still v4.28.0 (no movement since 2026-02-17); Phase 8 cannot integrate.

## Sprint Draft

### Sprint 1: end-to-end harness (3-4 Day)

Acceptance:
- New `scripts/e2e-harness.sh` chains spec-gen subagent dispatch + Phase 7 proof-harness on the same benchmark id.
- Output schema records `nl_input`, `generated_statement`, `statement_compile_ok`, `proof_attempt_tool`, `proof_compile_ok`, `e2e_pass`, `failure_stage` (spec / proof / both).
- Reuse Phase 6 spec-gen benchmark.json + Phase 7 v0.2.0 (where statements are pre-existing) for cross-comparison.
- At least 3 e2e cases run successfully through the chain.

### Sprint 2: independent benchmark dataset (2-3 Day)

Acceptance:
- `docs/research/new-foundation-survey/proof-gen/benchmark-e2e.json` with **10+ NL tasks** that are **not derived from existing project vocabulary** (independence from PI-19 SemanticEquivalence registry).
- Tasks cover the same 6 shapes as v0.2.0 (trivial / rewriting / constructor / arithmetic / quantified / higher-order).
- At least 3 tasks chosen to be deliberately hard for both spec-gen and proof-gen (calibrated against CLEVER difficulty).

### Sprint 3: pass-rate measurement under CLEVER same-condition (2-3 Day)

Acceptance:
- E2E pass rate reported per stage: `spec_pass_rate`, `proof_pass_rate_given_spec_pass`, `e2e_pass_rate`.
- Failure stage breakdown (spec vs proof vs both).
- Phase 8 final report compares e2e_pass_rate against CLEVER's 0.6% and our 5-15% target band.
- Honest assessment of whether 5-15% target is hit.

## Carry-over from Phase 7

Phase 7 sprint 2 #1 (Phase 6 spec-gen full freeze with AgentSpec namespace handling) is naturally absorbed into Phase 8 sprint 1 (end-to-end harness must already handle AgentSpec namespace). Mark as resolved when sprint 1 delivers.

Phase 7 sprint 3 #2 deferred refinement (failure taxonomy using internal solver stats) becomes Phase 8 sprint 3 secondary acceptance: extend `failure_class` to include `spec_unknown_identifier`, `spec_type_mismatch`, `proof_no_progress`, etc.

## PI Placement

- **PI-23 (Mathlib slim profile)**: Defer to Phase 9. Only triggered if Phase 8 sprint 1 e2e-harness is throughput-blocked by build time.
- **PI-24 (Lean 4.30 upgrade)**: Defer to Phase 9. Re-evaluate if LeanCopilot v4.30 releases simultaneously.
- **PI-25 candidate (ecosystem dependency version lag tracking)**: Created Day 210, still backlog. Phase 9 candidate.
- **PI-26 candidate (NEW)**: e2e harness execution mode auditing (subagent dispatch is judgmental; spec-gen prompt + proof-harness invocation are deterministic). Apply `mixed_task_decomposition` (TaskClassification.lean) to separate stages cleanly.

## Recommended Execution Order

1. Land this planning doc on `research/new-foundation` (Day 217).
2. Sprint 1: e2e-harness (Day 218-220 estimate).
3. Sprint 2: benchmark-e2e.json with independent tasks (Day 221-222).
4. Sprint 3: full e2e measurement + Phase 8 final report (Day 223-224).
5. Day 225+: release/phase8 cherry-pick + PR + main merge (Phase 5/6/7 同 pattern).

Total estimate: **8-9 Day** (vs Phase 7's actual 9-10 Day).

## Merge / Governance Notes

- All commits should carry `conservative extension` classification (purely additive harness/benchmark/results, no AgentSpec/ source change expected).
- Expected change categories: `additive_test` (harness, benchmark) / `process_only` (results docs, manifest entries).
- If a sprint finds a need to modify lakefile.lean (e.g., new dependency for spec-gen subagent integration), classify as `compatible change` with explicit explanation.
- Main merge strategy remains `release/phase8` + cherry-pick + PR + squash, matching Phase 5/6/7.

## Risks

- **Subagent dispatch latency**: Phase 6 spec-gen used Claude Code subagent (5-30s per dispatch). 10+ benchmark × 1 dispatch each = 1-5 min serial. Phase 8 harness should support batch parallelism via `Task` tool's parallel agent dispatch.
- **NL task framing bias**: writing NL tasks "ourselves" risks subtle in-domain framing. Consider drawing from external CLEVER-style task lists if available, or having a non-author write the NL prompts.
- **CLEVER same-condition definition**: CLEVER's exact protocol (input format, scoring rubric) needs to be verified against the paper to ensure measurement comparability.

## References

- Phase 7 plan: docs/research/new-foundation-survey/12-phase7-plan.md
- Phase 7 final report: docs/research/new-foundation-survey/proof-gen/results-day214-classified.md
- Phase 6 spec-gen results: docs/research/new-foundation-survey/spec-gen/results-day204.md
- Phase 6 spec-gen benchmark: docs/research/new-foundation-survey/spec-gen/benchmark.json
- Phase 7 v0.2.0 benchmark: docs/research/new-foundation-survey/proof-gen/benchmark-v0.2.0.json
- LeanCopilot blocked: docs/research/new-foundation-survey/leancopilot-integration-blocked.md
- CLEVER benchmark: https://www.researchgate.net/publication/391911216_CLEVER_A_Curated_Benchmark_for_Formally_Verified_Code_Generation
- LeanDojo / ReProver: https://huggingface.co/papers/2306.15626
- REAL-Prover: https://huggingface.co/papers/2505.20613
