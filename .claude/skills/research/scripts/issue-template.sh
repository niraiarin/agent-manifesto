#!/usr/bin/env bash
# Step 2, 3: Issue テンプレート生成 (deterministic 成分)
# TaskAutomationClass: deterministic (テンプレート構造) → structural enforcement
# judgmental 成分（内容記述）は LLM が担当。このスクリプトは骨格のみ生成。
# 根拠: mixed_task_decomposition (TaskClassification.lean)
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  issue-template.sh parent <title>
  issue-template.sh sub <parent-number> <gap-number> <title>

Outputs template to stdout. LLM fills in the [placeholder] sections.

Examples:
  issue-template.sh parent "TaskClassification 準拠調査"
  issue-template.sh sub 359 1 "タスク分類テーブル組み込み"
USAGE
  exit 1
}

[[ $# -lt 2 ]] && usage

ACTION="$1"

case "$ACTION" in
  parent)
    TITLE="$2"
    cat <<TEMPLATE
## 背景
[なぜこのリサーチが必要か — LLM が記述]

## 現状 vs 目標
| 項目 | 現状 | 目標 |
|---|---|---|
| [項目1] | [現状] | [目標] |

## Gap 一覧
| # | Gap | リスク | 状態 |
|---|---|---|---|
| 1 | [Gap 名] | high / medium / low | 未着手 |

## Sub-Issues
| # | Sub-Issue | 状態 |
|---|---|---|
| 1 | TBD | TBD |

## 実行順序
[依存関係 — LLM が記述]
TEMPLATE
    ;;
  sub)
    PARENT="$2"
    GAP_NUM="$3"
    TITLE="${4:-}"
    cat <<TEMPLATE
Parent: #${PARENT}

## 目的
[一文: この研究が答える問い — LLM が記述]

## 背景
[なぜ重要か — LLM が記述]

## 方法
[具体的な実験手順 — LLM が記述]

## 成果物
[何が生まれるか — LLM が記述]

## 依存
[他の Sub-Issue への依存、または "なし"]

## Gate 判定プロセス

実験実施 → 結果記録（コメント） → Gate 判定
  ├─ PASS: [基準 — LLM が記述] → close
  ├─ CONDITIONAL: [基準] → sub-issue 起票
  └─ FAIL: [基準] → [アクション]
TEMPLATE
    ;;
  *)
    usage
    ;;
esac
