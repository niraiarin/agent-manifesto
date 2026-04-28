# Phase 9 Plan: Adversarial Calibration Recipe — 5-15% Band Hit Defensible (Day 224 draft)

Phase 8 ended on Day 221 with the measurement triangle `e2e harness 0% / adversarial mid 58.3% / independent NL 91.7%` and an honest finding: the 5-15% target band exists between `e2e harness 0%` and `adversarial mid 58.3%`, but the Day 220 adversarial benchmark was insufficient to land in it. Day 220 sprint 3 #4 (Phase 8 final report) proposed Recipe A-D as the path to defensible 5-15% band hit. Phase 9 executes that recipe.

## Direction

Primary direction for Phase 9 is **adversarial calibration recipe 洗練**:

1. Translate Recipe A-D (Day 221 final report §「Adversarial calibration recipe」) into 12+ concrete adversarial cases.
2. Pre-validate each case fails `aesop` default (and `omega` / `decide` / `simp` baseline) before inclusion — every case must be a "designed fail" candidate.
3. Run the same e2e harness from Phase 8 sprint 1 against the new benchmark.
4. Measure pass rate; the target is 5-15% (with explicit confidence interval given small sample).

Secondary directions (parallel sprints or Phase 10):
- Failure taxonomy refinement using internal solver stats (Phase 8 sprint 3 #2 carry-over): split `bad_search_space` into `search_too_deep` / `missing_database`, expose `aesop` rule-application count.
- LeanCopilot 再評価 once v4.29.0+ upstream release lands (Phase 7 sprint 1 #3 blocker reactivation).
- PI-23 (Mathlib slim profile): only triggered if Phase 9 sprint 2/3 throughput is build-time blocked.

Deferred infrastructure (Phase 10 candidates):
- PI-24 (Lean 4.30 upgrade): still ecosystem-blocked by LeanCopilot.
- PI-25 (ecosystem dependency version lag tracking): backlog, no critical pressure.

## Why Adversarial Calibration Recipe Is the Critical Measurement

Phase 8 results made three measurement points concrete:
- **0%** (`e2e harness` v0.2.0 in-domain): full chain fails — spec-gen subagent could not produce compileable Lean for the existing project vocabulary, so proof attempts never started.
- **58.3%** (`adversarial mid` Day 220): designed adversarial 12 cases, but `deriving DecidableEq` auto-decide + definitional `rfl`-simp solved 7/12 anyway.
- **91.7%** (`independent NL` Day 219): real-math common identities, Mathlib `@[simp]` / `@[aesop]` registry directly hit.

The 5-15% band sits between `0%` and `58.3%`, but only if the benchmark is calibrated to defeat the unintended easy paths Day 220 found:
- `deriving DecidableEq` → aesop tries `decide` and wins for free.
- definitional unfold → aesop tries `simp` + `rfl` and wins for free.
- Mathlib `@[simp]` direct hit → aesop applies a single registry lemma.

**Recipe A-D from Day 221 final report**:
- **A**: 排除 `deriving DecidableEq`. Hand-define `Decidable` instances; the instance itself becomes a proof obligation.
- **B**: Quantified properties (e.g., `∀ xs : List α, myLen xs ≥ 0`) where definitional simp does not auto-fire because there is no `simp` rule for the custom recursive function.
- **C**: omega / induction / cases-required propositions (`(a + b) + c = a + (b + c)`, `n ≤ 2*n`, nonempty list → ∃ member). These have Mathlib lemmas but are not in `aesop` default rule sets.
- **D**: Mathlib `@[simp]` 攻撃面外 (e.g., `2 * n = n + n` direction is normalized by `Nat.two_mul` to `n.succ + n`, the reverse direction does not fire).

A 12+ case benchmark hitting all four recipes uniformly should produce 1-3 PASS / 9-11 FAIL (≈10-25% pass rate, centered on 15%) — within the 5-15% band with appropriate margin.

## Paper / Tool Survey

- **CLEVER (NeurIPS 2025)**: 0.6% baseline. Recipe A-D adversarial design imitates CLEVER's "no in-domain hint" condition more strictly than Phase 8 Day 220.
- **miniF2F (ICLR 2022)**: high-school olympiad benchmark, 5-7% pass rate is the baseline for many systems. Useful upper-bound reference for adversarial difficulty.
- **ProofNet (ICLR 2023)**: undergraduate math benchmark. Pass rates around 10-20% for top systems. Direct comparison target for Recipe A-D.
- **Aesop / Duper from Phase 7+8**: continue as proof tier. Phase 9 instruments them with `aesop_state` debug output for failure taxonomy.
- **LeanDojo / ReProver retrieval pattern**: optional Phase 9 sprint 3 augmentation if Recipe A-D pass rate is too low; retrieval may close the gap defensibly.

## Tooling Status and Constraints

Toolchain: still `leanprover/lean4:v4.29.0`. As of Day 224 (2026-04-28), no upstream change since Phase 8 plan (Day 217). Lean 4.29.1 stable, 4.30.0-rc2 unchanged.

Implications:
- Stay on 4.29.x for Phase 9 (PI-24 still deferred).
- Phase 8 e2e-harness (`scripts/e2e-harness.sh` with `prelude` field) is reused unchanged.
- Phase 8 adversarial benchmark format (`benchmark-adversarial-day220.json`) is the schema base for the Recipe A-D benchmark.
- LeanCopilot still v4.28.0 (no movement since 2026-02-17); Phase 9 cannot integrate.
- Aesop / Duper / omega / decide remain the core tactic portfolio.

## Sprint Draft

### Sprint 1: Recipe A+B benchmark design (3-4 Day)

Acceptance:
- 6 adversarial cases (3 Recipe A + 3 Recipe B) defined in `docs/research/new-foundation-survey/proof-gen/benchmark-adversarial-recipe-ab.json`.
- Recipe A: 3 custom inductive types with hand-defined `Decidable` instance (instance proof itself is the goal). No `deriving DecidableEq`.
- Recipe B: 3 quantified properties over custom recursive functions (e.g., `myLen`, custom `MyList.append`) where no `simp` rule covers the recursion.
- Pre-validation: each case must be confirmed to fail `aesop` (default) + `omega` + `simp` baseline (with `prelude` providing only the type definitions, not solver hints) before inclusion. Document the validation log.
- Schema reuses Day 220 adversarial benchmark format with optional `prelude` field.

### Sprint 2: Recipe C+D benchmark design + e2e harness extension (3-4 Day)

Acceptance:
- 6 additional adversarial cases (3 Recipe C + 3 Recipe D) appended to a unified `benchmark-adversarial-recipe-full.json` (12 cases total).
- Recipe C: 3 omega / induction / cases-required propositions (Day 220 adv_a1 / a2 / b2 patterns extended to non-trivial arithmetic).
- Recipe D: 3 Mathlib `@[simp]` 攻撃面外 propositions (reverse-direction equalities that Mathlib normalizes the opposite way).
- e2e-harness optional extension: `solver_trace` field capturing aesop's terminal state (rule application count, last-tried tactic) when available.
- Failure taxonomy split: `bad_search_space` → `search_too_deep` (depth >limit) / `missing_database` (no rule applicable). Apply to Day 220 results retroactively as comparison baseline.

### Sprint 3: full benchmark run + Phase 9 final report (2-3 Day)

Acceptance:
- Run e2e-harness over the 12-case Recipe A+B+C+D benchmark; record pass rate per recipe + overall.
- Pass rate must be **defensibly within 5-15% band** (target: 8-12% with 1-2 PASS / 11-10 FAIL).
- If overall pass rate falls outside band, document which recipe over-performed and propose Recipe E (Phase 10 carry-over).
- Phase 9 final report (`results-phase9-final.md`) compares against:
  - CLEVER 0.6% (paper baseline).
  - Phase 8 measurement triangle (0% / 58.3% / 91.7%).
  - miniF2F / ProofNet baseline (5-15% / 10-20% reported pass rates from prior work).
- Triangulation argument: with all four recipes hit, the resulting pass rate is the **defensible** estimate of "what AgentSpec proof tier achieves when the benchmark is truly adversarial" — finally letting us claim 5-15% improvement-over-CLEVER without measurement bias.

## Carry-over from Phase 8

Phase 8 sprint 3 #4 finding ("adversarial calibration recipe is Phase 9 candidate") is fully absorbed by Phase 9 primary direction. Mark as resolved when sprint 3 lands.

Phase 8 sprint 3 #2 deferred refinement (failure taxonomy internal solver stats) becomes Phase 9 sprint 2 secondary acceptance.

## PI Placement

- **PI-23 (Mathlib slim profile)**: Defer to Phase 10. Only triggered if Phase 9 sprint 2/3 e2e harness throughput is build-time blocked (>10 min per case).
- **PI-24 (Lean 4.30 upgrade)**: Defer to Phase 10. Re-evaluate when LeanCopilot v4.30 releases.
- **PI-25 (ecosystem dependency version lag tracking)**: Backlog. No active pressure.
- **PI-26 (e2e harness execution mode auditing)**: From Phase 8 plan, candidate. Folded into Phase 9 sprint 2 `solver_trace` extension.
- **PI-27 candidate (NEW)**: failure-taxonomy granularity ratchet — once `search_too_deep` / `missing_database` split is validated on Day 220 retroactive run, lock the schema and forbid `bad_search_space` going forward.

## Recommended Execution Order

1. Land this planning doc on `research/new-foundation` (Day 224 commit, this batch).
2. Sprint 1 (Day 225-228 estimated): Recipe A+B benchmark + pre-validation.
3. Sprint 2 (Day 229-232 estimated): Recipe C+D benchmark + harness extension + failure taxonomy split.
4. Sprint 3 (Day 233-235 estimated): full run + Phase 9 final report.
5. Day 236+: release/phase9 cherry-pick + PR + main merge (Phase 5/6/7/8 同 pattern).

Total estimate: 12 Day (Day 225-236). Conservative estimate; Phase 7+8 historical pace was ≈60% of estimate.

## Merge / Governance Notes

- Recipe A-D benchmark JSON commits: `additive_test`.
- e2e-harness extension (`solver_trace` field): `compatible_change` (existing schema + new optional field).
- Phase 9 plan + final report: `process_only`.
- Failure taxonomy schema split: `compatible_change` (enum extension, not breaking).
- Main merge strategy: `release/phase9` + cherry-pick + PR + squash, matching Phase 5/6/7/8.

## Risks

- **Recipe pre-validation cost**: each adversarial case requires running `aesop` / `omega` / `simp` baseline upfront to confirm "designed fail" status. Phase 8 Day 220 spent ≈1 Day on this for 12 cases; Phase 9 Recipe A-D may take 1.5-2x because the recipe constraints are tighter.
- **Recipe C / D arithmetic ambiguity**: some adversarial Nat / List propositions become trivial under `omega` if the user invokes `omega` in the prelude. Strict prelude policy: only type definitions, no tactic enablements.
- **Pass rate inversion**: if Recipe A-D over-performs (>15%), Phase 9 fails its primary direction. Mitigation: have Recipe E (designed-harder) ready as sprint 3 fallback.
- **Subagent dispatch dependency**: Phase 9 sprint 3 e2e run still requires spec-gen subagent dispatch for cases that include NL→Lean translation. If subagent dispatch latency dominates run time, harness should batch via `Task` tool's parallel dispatch (Phase 8 plan already noted).

## References

- Phase 8 plan: docs/research/new-foundation-survey/13-phase8-plan.md
- Phase 8 final report (Recipe A-D source): docs/research/new-foundation-survey/proof-gen/results-day221-phase8-final.md
- Phase 8 adversarial benchmark (Day 220): docs/research/new-foundation-survey/proof-gen/benchmark-adversarial-day220.json
- Phase 8 adversarial results (Day 220): docs/research/new-foundation-survey/proof-gen/results-day220-adversarial.md
- Phase 7 final report: docs/research/new-foundation-survey/proof-gen/results-day214-classified.md
- Phase 7 v0.2.0 benchmark: docs/research/new-foundation-survey/proof-gen/benchmark-v0.2.0.json
- e2e-harness: scripts/e2e-harness.sh
- LeanCopilot blocked: docs/research/new-foundation-survey/leancopilot-integration-blocked.md
- CLEVER benchmark (NeurIPS 2025): https://www.researchgate.net/publication/391911216_CLEVER_A_Curated_Benchmark_for_Formally_Verified_Code_Generation
- miniF2F: https://arxiv.org/abs/2109.00110
- ProofNet: https://arxiv.org/abs/2302.12433
