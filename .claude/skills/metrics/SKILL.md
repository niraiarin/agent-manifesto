---
name: metrics
user-invocable: true
description: >
  V1-V7 の現在値を計算して表示する。P4（可観測性）の運用ツール。
  「メトリクス」「V1-V7」「健全性」「system health」「metrics」で起動。
dependencies:
  invokes: []
---
<!-- @traces P4, D3, V1, V2, V3, V4, V5, V6, V7 -->

# Metrics Dashboard (P4: 可観測性)

V1–V7 の現在値を .claude/metrics/ のログから計算して表示する。

## Lean 形式化との対応

| スキルの概念 | Lean ファイル | 定理/定義 |
|------------|-------------|----------|
| D3: 可観測性 3 条件 | DesignFoundation.lean | `ObservabilityConditions`, `effectivelyOptimizable` |
| D3: 3 条件すべてが必要 | DesignFoundation.lean | `d3_partial_observability_insufficient` |
| D11: コンテキストコスト | DesignFoundation.lean | `contextCost`, `d11_enforcement_cost_inverse` |
| V1–V7 可測性 | Observable.lean | `v1_measurable` ... `v7_measurable` |
| 系の健全性 | Observable.lean | `systemHealthy`, `system_health_observable` |
| トレードオフ | Observable.lean | `tradeoff_v1_v2` 等 |
| Goodhart 脆弱性 | Observable.lean | `v4_goodhart`, `v7_goodhart` |

## 測定方法

### 即時測定可能

| V | 測定方法 | データソース |
|---|---------|------------|
| V2 | セッションあたりのツール呼び出し回数 | `.claude/metrics/tool-usage.jsonl` |
| V4 | L1 hook のブロック率（= 1 - 通過率） | `.claude/metrics/tool-usage.jsonl` + hook exit code |

### 間接測定（推定）

| V | 測定方法 | データソース |
|---|---------|------------|
| V1 | スキル使用率（スキル呼び出し / 全ツール呼び出し） | tool-usage.jsonl の tool=Skill エントリ |
| V3 | git commit 成功率（コミット試行 / コミット成功） | tool-usage.jsonl の git commit パターン |
| V6 | MEMORY.md のエントリ数と最終更新日 | ファイルシステム直接参照 |

### UserPromptSubmit / TaskCompleted ベース

| V | 測定方法 | データソース |
|---|---------|------------|
| V5 | 人間の承認/却下率（ヒューリスティック検出） | `.claude/metrics/v5-approvals.jsonl` |
| V7 | タスク完了数と完了率 | `.claude/metrics/v7-tasks.jsonl` |

## 実行手順

1. `.claude/metrics/tool-usage.jsonl` を読み込む
2. 以下のメトリクスを計算する:
   - 総ツール呼び出し回数
   - ツール別の呼び出し回数
   - セッション数（sessions.jsonl から）
   - セッションあたりの平均ツール呼び出し回数（V2 の近似）
3. 結果を以下の形式で表示する:

```
=== V1-V7 Metrics Dashboard ===

V1 (Skill Quality):       [値 or "測定中"]
V2 (Context Efficiency):  [ツール呼び出し/セッション]
V3 (Output Quality):      [コミット成功率]
V4 (Gate Pass Rate):      [通過率 %]
V5 (Proposal Accuracy):   [承認率 %]
V6 (Knowledge Structure): [MEMORY.md entries: N, last updated: date]
V7 (Task Design):         [タスク完了数]

System Health: [HEALTHY / WARNING / DEGRADED]
```

4. WARNING/DEGRADED の場合、具体的な劣化指標と推奨アクションを表示する

## D3 可観測性 3 条件の確認

各 V に対して D3 の 3 条件（DesignFoundation.lean `ObservabilityConditions`）を評価する:

| V | 測定可能 | 劣化検知 | 改善検証 | 実効性 |
|---|---------|---------|---------|--------|
| V2 | ✅ ツール呼び出し/セッション | ✅ 経時比較 | ✅ 前後比較 | 実効的 |
| V4 | ✅ pass/fail 統計 | ✅ 閾値比較 | ✅ 前後比較 | 実効的 |
| V1 | △ スキル使用率（間接） | △ 推定 | △ 推定 | 部分的 |
| V3 | △ commit 成功率（間接） | △ 推定 | △ 推定 | 部分的 |
| V5 | △ 承認/却下率 | △ 推定 | △ 推定 | 部分的 |
| V6 | △ エントリ数 | △ 推定 | △ 推定 | 部分的 |
| V7 | △ タスク完了数 | △ 推定 | △ 推定 | 部分的 |

D3 (`d3_partial_observability_insufficient`): 3 条件すべてが必要。
部分的な V は名目上の最適化対象であり、測定手段の改善が優先。

## D11 コンテキスト経済の指標

D11 (`d11_enforcement_cost_inverse`): 構造的強制のコンテキストコストが最低。
メトリクスダッシュボード自体は規範的指針（コンテキストコスト高）に属するが、
測定結果を構造的改善に活かすことでコストを正当化する。
