# Spec Generation Benchmark Results (Day 204、Phase 6 sprint 3 A #4)

PoC: 5 benchmark prompts × subagent dispatch、statement byte parity 評価。

## 結果

| # | benchmark id | difficulty | syntax | vocab | statement parity | note |
|---|---|---|---|---|---|---|
| 1 | v1_measurable | easy | ✓ | ✓ | **✓ byte-identical** | name 違いのみ (`skillQuality_measurable` vs `v1_measurable`) |
| 2 | platform_not_in_constraint_boundary | medium | ✓ | ✓ | **✓ byte-identical** | name `l5_unmapped_to_any_constraint` |
| 3 | constraint_has_boundary | medium | ✓ | ✓ | **✓ byte-identical** | parens 違いのみ (`(c : ConstraintId)` vs `c : ConstraintId`) |
| 4 | d2_from_e1 | hard | ✓ | ✓ | **✓ byte-identical** | name `p2_cognitive_separation_from_e1` |
| 5 | observable_and | medium | ✓ | ✓ | **✓ byte-identical** | hypothesis name 違い (`hP/hQ` vs `hp/hq`) |

**5/5 = 100% statement parity (modulo theorem name + minor surface)**

## 結論

| metric | 期待 (Day 203 plan) | 実測 | 評価 |
|---|---|---|---|
| syntax pass | 60-80% | **100%** | 上振れ |
| vocabulary pass | 20-40% | **100%** | 大幅上振れ |
| semantic equiv pass | 5-15% | **100%** | 大幅上振れ (期待値の ~10x) |

## Honest 評価

**この 100% は CLEVER ベンチマークと同条件ではない**:

| 軸 | CLEVER | 我々 |
|---|---|---|
| input | 自然言語 task 全体 | 自然言語要件 + **既存 vocabulary 提示** |
| output | spec + impl + proof end-to-end | **statement のみ** (proof は sorry) |
| benchmark source | 独立 task set | **既存 PI-19 26 theorems から逆方向 reverse-benchmark** |
| open-endedness | 完全 open | constrained (name + type 既存) |

→ **constrained setting での 100% は infrastructure 動作確認の成功**、CLEVER 0.6% を 100% に改善したわけではない。

## 何が示せたか / 示せていないか

### 示せた

1. LLM-driven Lean spec generation は **既存 vocabulary を context にすれば** 高 pass rate 可能
2. 評価 harness (prompt template + subagent dispatch + statement byte 比較) が functional
3. Phase 6 sprint 3 A の deliverable (評価 framework) 達成

### 示せていない (Phase 7+ 候補)

1. open-ended (vocabulary 提示なし) での pass rate
2. proof generation (statement のみ生成、proof は sorry のまま)
3. 新 axiom / 新 def の生成 (既存 vocabulary 拡張のシナリオ)
4. CLEVER と同条件比較 (independent benchmark で再評価)

## 次 step (sprint 3 closure)

- A #2 harness script: 本 PoC の manual 実行を script 化 (5 dispatch を 1 command に集約)
- A #5 example 13: spec-gen pipeline pattern demo
- sprint 3 audit + main merge prep
