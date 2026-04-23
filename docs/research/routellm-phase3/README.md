# Causal LM Router Phase 3 (#649)

Parent: #639
Related: #647 taxonomy (merged PR #648)

## 目的

24 tasks × 4 models の routing 決定を Causal LM 分類器で統合。

## 構成

- `classifier/train.py` — 学習スクリプト
- `classifier/train_encoder.py` — encoder full fine-tune 比較
- `classifier/serve_encoder.py` — production mDeBERTa router endpoint
- `classifier/eval.py` — 評価 + per-category F1
- `classifier/model/` — 学習済みモデル (.gitignore)
- `label-data/` — 学習データ (JSONL、.gitignore)
- `analysis/` — 評価レポート
- `ccr-integration.md` — ccr hook 設計

## Production default (#653)

2026-04-23 時点の採用モデルは **microsoft/mdeberta-v3-base full fine-tune**。

```bash
cd docs/research/routellm-phase3/classifier
uv run python3 serve_encoder.py --port 9001 --model-dir ../model-mdeberta
```

主要結果:
- Taxonomy exact 99.3%、routing 100%、leak 0%
- GT hold-out exact 65%、routing 100%、leak 0%
- Load test p95: 43.9ms (c=1), 80.8ms (c=5), 259.2ms (c=10)
- E2E smoke: classifier -> router.js PASS

## 実行計画

1. ccr hook 機構調査 (Gap 3)
2. ベースモデル選定（推論性能 bench）
3. 学習データラベリング（taxonomy manual + helpsteer3 mapping）
4. 学習 + 評価
5. ccr 統合
