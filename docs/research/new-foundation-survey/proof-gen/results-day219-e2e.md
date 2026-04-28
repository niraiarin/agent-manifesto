# Phase 8 Sprint 2 Independent NL Benchmark Results (Day 219)

12 case independent NL benchmark + e2e harness。Sprint 2 acceptance check + 重要 measurement bias finding。

## Sprint 2 acceptance status

| # | acceptance | status | evidence |
|---|---|---|---|
| 1 | benchmark-e2e-day219.json with 10+ NL tasks (PI-19 vocabulary 非依存) | ✓ | 12 case、全 NL は AgentSpec.Manifest 非依存 (Nat/List/Set/Prop の standard math) |
| 2 | 6 shape coverage (trivial / rewriting / constructor / arithmetic / quantified / higher-order) | ✓ | trivial 3, rewriting 2, constructor 1, arithmetic 2, quantified 2, higher-order 2 |
| 3 | ≥3 deliberately hard tasks (CLEVER difficulty calibrated) | partial | 4 hard tasks 含むが 3/4 が aesop/duper で解けた → "hard" の calibration が CLEVER 比 generous |

## Run results

| id | shape | difficulty | stmt compile | best tool | e2e |
|---|---|---|---|---|---|
| easy_self_implication | trivial | easy | ✓ | **aesop** | **PASS** |
| easy_and_commutative | trivial | easy | ✓ | **aesop** | **PASS** |
| easy_or_idempotent | trivial | easy | ✓ | **aesop** | **PASS** |
| med_modus_tollens | quantified | medium | ✓ | **aesop** | **PASS** |
| med_nat_zero_left | arithmetic | medium | ✓ | **aesop** | **PASS** |
| med_list_append_nil | rewriting | medium | ✓ | **aesop** | **PASS** |
| med_function_compose_assoc | higher-order | medium | ✓ | **aesop** | **PASS** |
| med_exists_intro_via_concrete | quantified | medium | ✓ | **aesop** | **PASS** |
| hard_nat_add_assoc | arithmetic | hard | ✓ | (none) | FAIL |
| hard_list_reverse_involutive | rewriting | hard | ✓ | **aesop** | **PASS** |
| hard_set_inter_subset | higher-order | hard | ✓ | **aesop** | **PASS** |
| hard_decidable_classical | constructor | hard | ✓ | **duper** | **PASS** |

**Spec compile pass: 12/12 = 100%**
**Proof success (any solver): 11/12 = 91.7%**
**E2E pass rate: 11/12 = 91.7%**

## 重要な measurement bias finding

### 91.7% (Day 219 independent) vs 0% (Day 218 in-domain) の対比

| benchmark | n | spec | proof | e2e | comment |
|---|---|---|---|---|---|
| Day 218 (Phase 6 spec-gen → proof) | 4 | 100% | 0% | **0%** | AgentSpec.Manifest domain-specific theorems |
| Day 219 (independent NL → proof) | 12 | 100% | 91.7% | **91.7%** | Standard math (Nat/List/Set/Prop) covered by Mathlib |

### Why 91.7% on independent, 0% on Manifest?

- **Aesop's rule set**: Mathlib registers `@[simp]` / `@[aesop]` attributes for thousands of common math lemmas. `easy_*` and `med_*` cases trigger these directly.
- **Duper's portfolio**: For propositional + first-order goals, duper's `[*]` premise + portfolioInstance heuristic covers basic cases.
- **Manifest theorems are NOT in any solver's rule set**: AgentSpec custom definitions (Measurable, constraintBoundary, Observable) lack `@[simp]` / `@[aesop]` tags. Solvers see "unknown territory."

### Hard task が 3/4 解けてしまう問題

`hard_*` 4 件のうち 3 件 (list_reverse_involutive, set_inter_subset, decidable_classical) が aesop/duper で解けた = 我々の "hard" calibration は CLEVER の adversarial design 比で **緩い**。

CLEVER は意図的に Mathlib の direct lookup から外れた task を含む (multi-step reasoning, custom inductive types, etc.)。我々の hard は "standard math だが Mathlib lemma name を覚えてないと書けない" レベル → aesop の simp normalisation で解けてしまう。

### 真の CLEVER same-condition への path

Day 219 independent benchmark は **真の CLEVER same-condition ではない**:
- Day 218 (Manifest): 0% — too hard, biased downward
- Day 219 (independent common math): 91.7% — too easy, biased upward
- 真の CLEVER: 0.6% — adversarial design で middle ground

Sprint 3 では Day 218 + Day 219 の **mid-bias を avoid する benchmark mix** を設計する必要がある:
1. Manifest domain (固定 0%)
2. Common math (Mathlib coverage、固定 ~80-90%)
3. **Adversarial mid**: standard math だが Mathlib direct lookup を意図的に外した命題 (例: 自己定義型 + 算術混合、新規 inductive + lemma 必要)

### 5-15% target 評価

Phase 7 final report で書いた 5-15% target は CLEVER 0.6% 比 ~10x。我々の measurement は:

- v0.2.0 (Phase 7 in-domain): aesop 83.3% / duper 66.7% — band over
- e2e Manifest (Day 218): 0% — band under
- e2e independent (Day 219): 91.7% — band over

**結論**: 5-15% target は **measurement design 次第で変動**、CLEVER 比較を主張するには adversarial benchmark design が必須。Sprint 3 で adversarial mid benchmark を設計し、その上で 5-15% 検証する。

## Sprint 3 design implication (Day 220+)

### Adversarial mid benchmark 候補

1. Mathlib に lemma があるが `@[simp]` 外: `(n : Nat) : 2 * n = n + n` (mul_two の方向違い)
2. 新規 inductive 定義 + lemma 必要: 独自 BinaryTree + height = depth proof
3. Multi-step reasoning: `(n : Nat) (h : n > 0) : ∃ m, n = m + 1` (cases + Nat.succ)
4. Domain mixing: AgentSpec.Manifest + Mathlib (e.g., List of Manifest types)

### Failure stage 強化

Day 218/219 はほぼ proof stage failure のみ。Sprint 3 で spec stage failure も意図的に作る (NL ambiguity high task) → spec/proof/both 分布を realistic に。

## References

- Phase 8 plan: docs/research/new-foundation-survey/13-phase8-plan.md
- Day 218 sprint 1 results: docs/research/new-foundation-survey/proof-gen/results-day218-e2e.md
- Phase 7 final report: docs/research/new-foundation-survey/proof-gen/results-day214-classified.md
- raw JSON: docs/research/new-foundation-survey/proof-gen/results-day219-e2e.json
