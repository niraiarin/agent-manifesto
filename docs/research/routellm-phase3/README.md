# Causal LM Router Phase 3 (#649)

Parent: #639
Related: #647 taxonomy (merged PR #648)

## 目的

24 tasks × 4 models の routing 決定を Causal LM 分類器で統合。

## 構成

- `classifier/train.py` — 学習スクリプト
- `classifier/eval.py` — 評価 + per-category F1
- `classifier/model/` — 学習済みモデル (.gitignore)
- `label-data/` — 学習データ (JSONL、.gitignore)
- `analysis/` — 評価レポート
- `ccr-integration.md` — ccr hook 設計

## 実行計画

1. ccr hook 機構調査 (Gap 3)
2. ベースモデル選定（推論性能 bench）
3. 学習データラベリング（taxonomy manual + helpsteer3 mapping）
4. 学習 + 評価
5. ccr 統合
