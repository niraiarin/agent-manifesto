---
name: adjust-action-space
user-invocable: true
description: >
  L4 行動空間の調整（拡張・縮小）を提案する。V4/V5 の実績データに基づき、
  permissions の変更を人間に提案する。D8（均衡探索）に従い、
  拡張と縮小の両方向を扱う。「行動空間」「権限」「permissions」
  「拡張」「縮小」「auto-merge」で起動。
dependencies:
  invokes:
    - skill: metrics
      type: soft
      phase: "Step 1-2"
      condition: "V4/V5 実績データ取得時"
---
<!-- @traces P1, D8, D7, L4, E2 -->

# Action Space Adjustment (D8: 均衡探索)

L4（行動空間境界）の調整を、V の実績データに基づいて提案する。

## Lean 形式化との対応

| スキルの概念 | Lean ファイル | 定理/定義 |
|------------|-------------|----------|
| D8: 過剰拡大は価値を毀損 | DesignFoundation.lean | `d8_overexpansion_risk` |
| D8: 能力-リスク共成長 | DesignFoundation.lean | `d8_capability_risk` |
| D7: 蓄積は bounded | DesignFoundation.lean | `d7_accumulation_bounded` |
| D7: 毀損は unbounded | DesignFoundation.lean | `d7_damage_unbounded` |
| D12: タスク設計は制約充足 | DesignFoundation.lean | `d12_task_is_csp` |
| T₀ 縮小禁止 | Procedure.lean | `t0_contraction_forbidden` |
| 均衡状態の定義 | Observable.lean | `atEquilibrium` |

## タスク自動化分類（TaskClassification.lean 準拠, #377/#380）

各ステップの `TaskAutomationClass` をデザインタイムに定義する。
実行時に LLM が毎回判断するコストを排除する（`designtime_classification_amortizes`）。

| ステップ | 分類 | 推奨実装手段 | 備考 |
|---|---|---|---|
| Step 1: ログ読み込み | **deterministic** | スクリプト（jq / ファイル読み込み） | .claude/metrics/ のファイル読み込み |
| Step 2: V4/V3 推移計算 | **deterministic** | スクリプト（算術演算） | 閾値との比較計算 |
| Step 3: トリガー条件評価 | **deterministic** | スクリプト（閾値比較） | 拡張: 90%/劣化なし/0件、縮小: 違反発生/急低下/70% — 全て数値比較 |
| Step 4: 提案フォーマット出力 | **deterministic + judgmental（未分離）** | LLM が直接実行 | deterministic: テンプレート構造の生成 / judgmental: 根拠の記述、防護設計の内容 |
| Step 5: 人間の承認待ち | **deterministic** | Elicitation 呼び出し | T6 準拠の承認/却下取得 |

**設計原則**:
- Step 1-3 は全て deterministic — スクリプト化でコンテキストコスト削減可能（`deterministic_must_be_structural`）
- Step 4 の deterministic 成分（テンプレート）と judgmental 成分（防護設計の記述）は分離候補（`mixed_task_decomposition`）
- /adjust-action-space は /metrics と類似構造（データ収集→計算→閾値判定→出力）のため、共通スクリプト化の余地あり

## 原則

- **最適 ≠ 最大** (D8: `d8_overexpansion_risk`): 行動空間の最大化は目的ではない
- **拡張と防護はセット** (D7/P1: `d7_damage_unbounded`): 拡張提案には必ず対応する防護設計を含める
- **人間が最終決定者** (T6): 提案のみ。実行は人間の承認後
- **タスク設計も制約充足** (D12: `d12_task_is_csp`): 行動空間の調整はタスク制約の変更に等しい

## 拡張トリガー

以下の条件が **全て** 満たされた場合、拡張を提案できる:
1. V4（ゲート通過率）が直近20回で 90% 以上
2. V3（出力品質）に劣化傾向がない
3. L1 違反ブロックが直近20セッションで 0 件

## 縮小トリガー

以下の **いずれか** が発生した場合、縮小を提案する:
1. L1 違反ブロックが発生した
2. V3（出力品質）が急激に低下した
3. V4（ゲート通過率）が 70% を下回った

## 提案フォーマット

```
=== 行動空間調整提案 ===

方向: 拡張 / 縮小
対象: (具体的な permission の変更内容)
根拠: (V データ、期間、件数)
防護設計: (拡張の場合のみ — 新たなリスクとその対策)
リスク: (調整に伴うリスク)
```

## 実行手順

1. `.claude/metrics/` からログを読み込む
2. V4, V3 の直近の推移を計算する
3. 拡張/縮小のトリガー条件を評価する
4. 該当する場合、提案をフォーマットに従って出力する
5. 人間の承認を待つ（Elicitation を使用）

## Traceability

| 命題 | このスキルとの関係 |
|------|-------------------|
| E2 | 拡張提案に必ず防護設計を含めることで、行動空間の能力拡大に伴うリスク拡大を明示的に管理 |
