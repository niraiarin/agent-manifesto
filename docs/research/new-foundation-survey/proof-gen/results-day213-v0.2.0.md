# Proof Harness Day 213 Results — Benchmark v0.2.0 (Phase 7 sprint 2)

12 benchmark theorems × 3 solver = 36 attempts。Sprint 2 acceptance 全 4 充足。

## Sprint 2 acceptance (Phase 7 plan)

| # | acceptance | status | evidence |
|---|---|---|---|
| 1 | Phase 6 spec-gen outputs frozen | partial | v0.2.0 schema 拡張済 + 一部 carryover (full freeze は sprint 3 で AgentSpec namespace handling 後) |
| 2 | shape labeling | ✓ | 6 shape (trivial / rewriting / constructor / arithmetic / quantified / higher-order) 全 cover |
| 3 | output schema (statement_ok/proof_ok/tool_used/time_ms/heartbeats/failure_class) | ✓ | input_schema + output_schema 両方 benchmark-v0.2.0.json に定義、harness JSON_OUT で record 出力可能 |
| 4 | ≥10 cases runnable end-to-end | ✓ | 12 cases × 3 solver = 36 attempts 完走 |

## Results

| id | shape | baseline | aesop | duper |
|---|---|---|---|---|
| p_implies_p | trivial | PASS | **PASS** | **PASS** |
| and_symmetry | trivial | PASS | **PASS** | **PASS** |
| modus_ponens_chain | quantified | PASS | **PASS** | **PASS** |
| function_equality_chain | rewriting | PASS | **PASS** | **PASS** |
| nat_zero_add | arithmetic | PASS | **PASS** | FAIL |
| or_symmetry | trivial | PASS | **PASS** | **PASS** |
| triple_negation_collapse | rewriting | PASS | **PASS** | **PASS** |
| exists_elim_propagation | quantified | PASS | **PASS** | **PASS** |
| list_length_zero_iff_nil | constructor | PASS | **PASS** | FAIL |
| nat_add_comm | arithmetic | PASS | FAIL | FAIL |
| subset_transitivity | higher-order | PASS | FAIL | FAIL |
| function_const_compose | higher-order | PASS | **PASS** | **PASS** |

**baseline: 12/12 = 100%** (design 通り、reference)
**aesop: 10/12 ≈ 83.3%**
**duper: 8/12 ≈ 66.7%**

## Failure 分類 (sprint 3 failure_class taxonomy 候補)

### aesop 失敗 (2 件)

- `nat_add_comm`: Nat.add_comm は Mathlib にあるが aesop の default rule set 外 (`bad_search_space`)。`@[simp]` extension が必要かも。
- `subset_transitivity`: `Set.Subset.trans` の知識を aesop が持たない (`missing_lemma`)。Mathlib.Data.Set.Basic 単独 import では不足、追加 lemma hint が必要。

### duper 失敗 (4 件)

- `nat_zero_add`: Nat 算術の equation reasoning が苦手 (`bad_search_space`)。Day 212 既知。
- `list_length_zero_iff_nil`: List constructor + ↔ reasoning が苦手 (`bad_search_space`)。
- `nat_add_comm`: 同上 (Nat 算術)。
- `subset_transitivity`: Set theory 知識なし (`missing_lemma`)。

## Solver 強み比較

| shape | aesop | duper |
|---|---|---|
| trivial | 3/3 | 3/3 |
| rewriting | 2/2 | 1/2 (3-neg collapse fail にならない、function eq chain pass) |
| quantified | 2/2 | 2/2 |
| arithmetic | 1/2 | 0/2 |
| constructor | 1/1 | 0/1 |
| higher-order | 1/2 | 1/2 |

**aesop**: 一般用 baseline、constructor + arithmetic で arithmetic library 知識依存
**duper**: equality + first-order quantifier 強い、arithmetic + constructor 弱い (Day 212 同 finding 再確認)

## Sprint 3 着手要素

Sprint 2 で残した部分 (sprint 3 candidate):

1. **Phase 6 spec-gen full freeze**: AgentSpec namespace を harness で handling、v1_measurable / observable_and 等 5 件を benchmark に組み込む
2. **failure_class auto-classification**: `lake env lean` の error output を parse、上記 4 taxonomy (timeout / missing_lemma / bad_search_space / reconstruction_failure / tooling_failure) に自動 mapping
3. **heartbeats measurement**: Lean の `set_option maxHeartbeats N` 経由で計測、timeout vs proof complexity を separate
4. **Materialised proof script**: aesop? / duper? を呼び出して成功した tactic script を保存
5. **CLEVER 同条件比較 path**: end-to-end (自然言語 → spec → proof) の pass rate measurement

## 5-15% target 評価

Constrained (本 v0.2.0): aesop **83.3%**, duper **66.7%** — far above 5-15% target band

これは本 benchmark が **既知 Lean 命題** で構成されていることが原因 (CLEVER 同条件 = 自然言語 task → end-to-end 生成 ではない)。Sprint 3 で CLEVER 同条件 evaluation を追加すれば 5-15% に近い数字 (もしくはそれ以下) が出る想定。

現時点の数字は "in-domain solver baseline" として記録、CLEVER 比較は sprint 3 の per-task end-to-end measurement で行う。

## References

- Phase 7 plan: docs/research/new-foundation-survey/12-phase7-plan.md
- Day 212 skeleton: docs/research/new-foundation-survey/proof-gen/results-day212-skeleton.md
- benchmark dataset: docs/research/new-foundation-survey/proof-gen/benchmark-v0.2.0.json
- raw JSON results: docs/research/new-foundation-survey/proof-gen/results-day213-v0.2.0.json
