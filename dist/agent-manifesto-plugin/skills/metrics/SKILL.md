---
name: metrics
description: >
  V1-V7 の現在値を計算して表示する。P4（可観測性）の運用ツール。
  「メトリクス」「V1-V7」「健全性」「system health」「metrics」で起動。
---

# Metrics Dashboard (P4: 可観測性)

V1–V7 の現在値を .claude/metrics/ のログから計算して表示する。

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
