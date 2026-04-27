# Proof Harness Skeleton Results (Day 212, Phase 7 sprint 1 #4)

PoC: 5 minimal benchmark theorems × 3 solver (baseline / aesop / duper) = 15 attempts。

## Results

| id | shape | baseline | aesop | duper | expected match |
|---|---|---|---|---|---|
| p_implies_p | trivial | PASS | **PASS** | **PASS** | yes (both) |
| and_symmetry | trivial | PASS | **PASS** | **PASS** | yes (both) |
| modus_ponens_chain | quantified | PASS | **PASS** | **PASS** | yes (both) |
| function_equality_chain | rewriting | PASS | **PASS** | **PASS** | aesop unexpected pass (over-prediction) |
| nat_zero_add | arithmetic | PASS | **PASS** | FAIL | duper fail expected, aesop expected |

baseline (sorry): 5/5 = 100% (常に compile、design)
aesop: **5/5 = 100%**
duper: **4/5 = 80%**

## 結論

### Infrastructure 評価 (sprint 1 #4 acceptance)

Single harness が 3 mode (baseline / aesop / duper) を同一 theorem list で実行できる ✓
- `scripts/proof-harness.sh list` で benchmark 一覧
- `scripts/proof-harness.sh generate <id>` で per-solver test file 生成
- `scripts/proof-harness.sh run` で全 benchmark 集計

Sprint 1 #4 acceptance 充足。

### Solver 傾向 (sprint 2 / 3 で本格 benchmark 化)

- **Aesop**: 一般用 baseline として強力。trivial / quantified / arithmetic / rewriting 全て pass (本 skeleton 範囲では over-deliver)
- **Duper**: equality reasoning + first-order に特化、Nat 算術系は苦手 (nat_zero_add fail)。premise 渡しが [*] 必須 (Day 209 finding 再確認)
- **Baseline (sorry)**: design 上 compile pass、proof rate measurement の reference

### Sprint 2 / 3 への引継ぎ

1. **Sprint 2 候補**: 本 skeleton (5 件) を Phase 6 spec gen の benchmark.json (5 PoC) 由来 statement に置き換えて 10+ 件に拡張、shape labeling refine
2. **Sprint 3 候補**: pass rate measurement formal report (per-tool, per-shape, with timing if measured)
3. **発見**: Aesop が想定以上に強力 → "5-15% pass rate target" は trivial benchmark での upper bound に近い、open-ended (CLEVER 同条件) では大幅減少 想定

## CLEVER 同条件比較への path

現在 (sprint 1 skeleton):
- 既知 statement + 既知 vocabulary + Lean tactic 直叩き = constrained setting

CLEVER 0.6% 同条件 (sprint 3+ 目標):
- 自然言語 task → spec generation (Phase 6 sprint 3 A) → proof generation (Phase 7) end-to-end
- 期待 pass rate 5-15% は CLEVER 比 ~10x、constrained skeleton の 100% / 80% から大幅減

Sprint 2 で benchmark を CLEVER style に近づけ、Sprint 3 で同条件比較が現実的になる。

## References

- Phase 7 plan: docs/research/new-foundation-survey/12-phase7-plan.md
- Phase 6 sprint 3 A spec gen: docs/research/new-foundation-survey/spec-gen/results-day204.md
- Aesop integration (Day 208): agent-spec-lib/examples/14_aesop_baseline.lean
- Duper integration (Day 209): agent-spec-lib/examples/15_duper_baseline.lean
- LeanCopilot blocked (Day 210): docs/research/new-foundation-survey/leancopilot-integration-blocked.md
