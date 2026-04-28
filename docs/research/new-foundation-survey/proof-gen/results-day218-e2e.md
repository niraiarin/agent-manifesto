# Phase 8 Sprint 1 E2E Harness Scaffolding Results (Day 218)

Phase 8 sprint 1 acceptance check: end-to-end harness scaffolding 動作確認 + 4 case PoC。

## Sprint 1 acceptance status

| # | acceptance | status | evidence |
|---|---|---|---|
| 1 | scripts/e2e-harness.sh chains spec-gen + proof harness | ✓ | list / run 2 mode、theorem stub <recorded_output> := by <tactic> wrap |
| 2 | Output schema (nl_input/generated_statement/statement_compile_ok/proof_attempt_tool/proof_compile_ok/e2e_pass/failure_stage) | ✓ | JSON_OUT 経由 record 出力、results-day218-e2e.json 全 field 含む |
| 3 | Reuse Phase 6 spec-gen benchmark | ✓ | benchmark-e2e-day218.json は Phase 6 Day 204 PoC 5/5 のうち 4 件 (d2_from_e1 は generates predicate 複雑のため除外) |
| 4 | ≥3 e2e cases run successfully through chain | ✓ | 4 cases all ran through spec compile + proof attempt stages without infrastructure failure |

## Run results

| id | stmt compile | proof attempts | E2E |
|---|---|---|---|
| v1_measurable | ✓ | aesop FAIL (made no progress), duper FAIL | FAIL (proof stage) |
| platform_not_in_constraint_boundary | ✓ | aesop FAIL, duper FAIL | FAIL (proof stage) |
| constraint_has_boundary | ✓ | aesop FAIL, duper FAIL | FAIL (proof stage) |
| observable_and | ✓ | aesop FAIL, duper FAIL | FAIL (proof stage) |

**Spec compile pass: 4/4 = 100%**
**Proof success (any solver): 0/4 = 0%**
**E2E pass rate: 0/4 = 0%**

## CLEVER same-condition への意味

### 重要な finding

これは Phase 7 in-domain v0.2.0 (aesop 83.3% / duper 66.7%) との **強烈な対比**:

| benchmark | spec source | aesop | duper | e2e |
|---|---|---|---|---|
| v0.2.0 (Phase 7) | 自作 trivial | 83.3% | 66.7% | (proof only) |
| e2e-day218 (Phase 8 sprint 1) | Phase 6 spec-gen recorded | 0% | 0% | 0% |

**Why the gap**:
- v0.2.0 は aesop/duper が知っている lemma (Nat.add, ∧/∨ symmetry, ∃-elim) で構成
- e2e-day218 は AgentSpec.Manifest 内 domain-specific theorem (Measurable / constraintBoundary / Observable) で、aesop/duper の default rule set では解けない
- 元の Lean proof は manual 構築 (PI-19 SemanticEquivalence registry の 26 entries は人間が書いた proof)

### CLEVER 0.6% 比較

CLEVER も自然言語タスクからの end-to-end 評価で 0.6% pass rate を報告。我々の **0/4 = 0%** はサンプル数が少なすぎて (n=4) 統計的比較不可だが、トレンドとして:

- 期待された 5-15% target を **大幅に下回る** (0% < 0.6%、しかも n=4 で信頼区間広い)
- これは "in-domain Manifest theorems requires domain-specific lemma database" という当然の事実を裏付け
- Sprint 2 で benchmark を独立 NL task に拡張、easy + hard mix で pass rate を realistic に

### Failure stage 分布

| stage | count |
|---|---|
| spec | 0 (recorded outputs are all syntactically valid) |
| proof | 4 (all fail at proof tier) |
| both | 0 |
| none (PASS) | 0 |

## Sprint 2/3 design implication

### Sprint 2 benchmark 設計指針

1. **多様性確保**: trivial (aesop should pass) + medium + hard (require lemma hints) を混ぜる
2. **independent NL framing**: 既存 PI-19 vocabulary に依存しない 10+ task を作成
3. **sprint 2 #3 calibration**: deliberately hard tasks 3 件を CLEVER difficulty 範囲に揃える

### Sprint 3 measurement focus

Phase 7 final report で書いた 5-15% target 評価は in-domain 想定。Phase 8 の sprint 3 で:
- True CLEVER same-condition (NL → spec → proof end-to-end) の pass rate を measure
- Failure stage breakdown (spec vs proof vs both) で bottleneck identification
- Realistic な statistical significance (n ≥ 10 per shape category)

## References

- Phase 8 plan: docs/research/new-foundation-survey/13-phase8-plan.md
- Phase 7 final report: docs/research/new-foundation-survey/proof-gen/results-day214-classified.md
- Phase 6 spec-gen results: docs/research/new-foundation-survey/spec-gen/results-day204.md
- raw JSON: docs/research/new-foundation-survey/proof-gen/results-day218-e2e.json
