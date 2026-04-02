# metrics

V1-V7 の現在値を計算して表示する P4（可観測性）の運用ツール。

`.claude/metrics/` のログから各変数の値を算出し、ダッシュボード形式で表示する。

## 起動トリガー

`/metrics` または「メトリクス」「V1-V7」「健全性」「system health」

## 変数一覧

| V | 概要 | データソース |
|---|------|------------|
| V1 | 安全性 | L1 違反検出ログ |
| V2 | 効率性 | `.claude/metrics/tool-usage.jsonl` |
| V3 | 再現性 | テスト結果 |
| V4 | 自律性 | 行動空間ログ |
| V5 | 介入率 | 人間介入ログ |
| V6 | 学習速度 | P3 統合ログ |
| V7 | 整合性 | トレーサビリティ検査 |

## Lean 形式化との対応

- D3: 可観測性 3 条件 (`ObservabilityConditions`)
- V1-V7 可測性 (`v1_measurable` ... `v7_measurable`)
- 系の健全性 (`systemHealthy`)
- Goodhart 脆弱性 (`v4_goodhart`, `v7_goodhart`)
