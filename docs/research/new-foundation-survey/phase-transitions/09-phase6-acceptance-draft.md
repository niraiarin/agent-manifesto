# Phase 6 Acceptance Criteria (Day 199 draft)

Day 197 Phase 5 main merge 後の Phase 6 計画。複数候補のうち priority + dependency 分析で **ζ Build performance を sprint 1 (Day 199-201)、D CLEVER framework を sprint 2 (Day 202+)** とする 2-sprint 構成。

## 戦略決定

### ζ 先行の根拠

| 観点 | ζ Build performance | D / A primary work |
|---|---|---|
| 即時 ROI | CI 5-10x 短縮 (35-50 min → 5-10 min) | research advance |
| 後続影響 | 全 Phase 6+ work が CI 高速化を享受 | 単独 |
| risk | 低 (workflow 改修のみ、Lean 影響なし) | 中-高 (新研究領域) |
| scope | 明確 (PI-21〜24 documented) | Phase 6 primary 内で再 scope 必要 |

ROI 計算: ζ 完成 (Day 199-201、想定 3 Day) で残 Phase 6+ work の CI 待ち時間が compound して短縮。

### 候補間の dependency

```
ζ (Build perf) — prerequisite for all subsequent CI-bound work
  ↓
D (CLEVER framework) — evaluation pipeline (build on PI-12 + PI-19)
  ↓
A (Survey P0 #5 仕様生成) — requires D evaluation framework
  ↓
B (SMT 統合) — supports A verification step

E (EnvExtension) ← Lean infrastructure、A/D と独立、parallel 可
F (Perspective/Iterative) ← LLM tooling、scope 大、Phase 7+ defer
```

## sprint 1: ζ Build performance (Day 199-201、3 Day)

### acceptance criteria 4 項目

| # | criterion | PI | 工数 |
|---|---|---|---|
| 1 | mathlib4-cache action 採用 (lake exe cache get) | PI-21 | 1 Day |
| 2 | cache restore-keys 階層化 (branch 跨ぎ partial restore) | PI-22 | 0.5 Day |
| 3 | CI 時間 measurement before/after | (新規 metric) | 0.5 Day |
| 4 | ζ verification: 次 PR で CI ≤ 15 min 達成 | (PI-21+22 効果検証) | 1 Day |

### sprint 1 NOT goals

- PI-23 Mathlib slim profile (subset 化、複雑、Phase 7 へ defer)
- PI-24 Lean 4.30 upgrade (ecosystem 同期必要、Phase 7 へ defer)

## sprint 2: D CLEVER 風自己評価 framework (Day 202+、想定 5-7 Day)

Phase 5 で確立した SemanticEquivalence registry pattern を CLEVER style evaluation pipeline に extend。

### acceptance criteria 5 項目 (草案)

| # | criterion | 関連 |
|---|---|---|
| 1 | EvaluationBenchmark Lean module: theorem × test pair の registry | PI-19 拡張 |
| 2 | Pass rate calculator: registry から CLEVER style metrics (M1〜M3) 計算 | (新規) |
| 3 | Subagent dispatch integration: 外部 LLM evaluator (PI-8 pattern) を benchmark に組込 | PI-8 拡張 |
| 4 | benchmark report generator: M1-M3 + per-theorem outcome を Markdown export | (新規) |
| 5 | examples 12: CLEVER pattern usage demo | (Phase 5 #5 と同型) |

### sprint 2 secondary

- A Survey P0 #5 (正しい仕様生成): D framework 完成後、primary direction として Phase 7+
- B SMT 統合: Lean-Auto / Boole (LeanHammer) 統合、Phase 7+ scope

## Phase 6 全体構造

| sprint | content | Day | priority |
|---|---|---|---|
| sprint 1 ζ | Build performance (PI-21 + PI-22) | 199-201 | high (compound ROI) |
| sprint 2 D | CLEVER framework | 202-208 | high (research vehicle) |
| sprint 3 A | Survey P0 #5 仕様生成 | 209+ | P0、最重要 |
| sprint 4 B / C / E | SMT 統合 / Atlas augment / EnvExtension | TBD | P1 |
| sprint 5 F | Perspective / Iterative | TBD | P1 |

Phase 6 全体: Day 199-220 ~ 22 Day 想定 (sprint 1-3 で 14 Day + buffer)。

## risk + mitigation

| risk | mitigation |
|---|---|
| ζ で CI 改善が想定通りいかない (PI-21 の mathlib4-cache が我々の lakefile と incompatible) | sprint 1 #4 で early verification、想定外なら PI-23 (slim profile) 検討 |
| D CLEVER framework が research-level で正解定義できない | sprint 2 #1 で benchmark scope を 10-20 theorem に限定、incremental 拡大 |
| A 仕様生成は CLEVER 0.6% 領域、達成困難 | sprint 3 で expectation = 「partial 自動化 + judgment 補助」、100% 達成を期待しない |

## 着手順序

- **Day 199**: 本 plan 作成 + sprint 1 #1 (PI-21 mathlib4-cache 実装)
- Day 200: sprint 1 #2 (PI-22 restore-keys) + 次 PR での CI 計測
- Day 201: sprint 1 #4 (verification PR、CI ≤ 15 min 達成検証)
- Day 202-: sprint 2 D CLEVER framework 着手
