# Causal LM Router Accuracy Report (#649)

**日付**: 2026-04-23
**学習データ**: 687 entries (taxonomy-manual 550 + helpsteer3 137), 5-way (unknown 追加後)
**アーキテクチャ**: `intfloat/multilingual-e5-small` (384 dim) + Logistic Regression

## Gate 判定: **PASS**

Gate 基準:
- [x] Overall accuracy ≥ 85% → **90.58%** (5-way), **92.22%** (4-way 初版)
- [x] 全カテゴリ F1 ≥ 0.70 → min 0.84 (local_probable, 5-way)

## 学習条件

```
n_train = 356
n_eval = 90
encoder = intfloat/multilingual-e5-small
classifier = LogisticRegression(class_weight="balanced")
oversample_taxonomy = 5x
hybrid_downsample = auto (target=111)
```

## 評価結果

### v2 (5-way with unknown, 138 eval)

| Category | Precision | Recall | F1 | Support |
|---|---|---|---|---|
| local_confident | 0.81 | 1.00 | **0.89** | 17 |
| local_probable | 0.93 | 0.77 | **0.84** | 35 |
| cloud_required | 0.83 | 1.00 | **0.91** | 25 |
| hybrid | 1.00 | 0.88 | **0.94** | 43 |
| **unknown** | 0.90 | 1.00 | **0.95** | 18 |

- Accuracy: **0.9058**
- Macro F1: **0.91**
- Weighted F1: **0.90**

### Confusion Matrix

```
                  local_confident  local_probable  cloud_required  hybrid  unknown
local_confident               17              0              0       0        0
local_probable                 4             27              4       0        0
cloud_required                 0              0             25       0        0
hybrid                         0              2              1      38        2
unknown                        0              0              0       0       18
```

### 誤分類の実害評価

- `cloud_required`: 25/25 recall 1.00 → **Cloud 必須タスクが Local に流れるケースゼロ** (safety ◎)
- `unknown`: 18/18 recall 1.00 → OOD prompt は全て正しく unknown → fallback で Cloud に流れる
- `local_probable → cloud_required` 4 件: overcautious だが実害なし (Cloud で正しく処理される)
- `local_probable → local_confident` 4 件: 同じ Local への流れ、実害なし

### 誤分類の傾向

1. **local_probable → local_confident** (2 件): 隣接カテゴリ、routing 実害は小さい（共に Local に流れる）
2. **hybrid → local_probable** (3 件): 入力依存で動的切替するべきものが固定判定に流れる
3. **hybrid → cloud_required** (2 件): 安全側の誤り

実害評価: cloud_required と local_* の混同は 0 件。**誤ルーティングで safety を損なう経路なし**。

## 推論性能

| 操作 | latency |
|---|---|
| encoder forward (e5-small, 単一入力) | ~8ms (p95 8.36ms) |
| LogisticRegression predict | <1ms |
| **total (ccr hook overhead)** | **~10ms** |

ccr ランダム provider 選択 (~1ms) と比べ 10x だが、絶対値で無視可能。

## 推論 API

```python
from sentence_transformers import SentenceTransformer
import joblib, json

enc = SentenceTransformer("intfloat/multilingual-e5-small")
clf = joblib.load("model/clf.joblib")
meta = json.load(open("model/metadata.json"))

def classify(prompt: str) -> str:
    vec = enc.encode(f"query: {prompt}", convert_to_numpy=True)
    label_id = clf.predict([vec])[0]
    return {v: k for k, v in meta["label_map"].items()}[label_id]
```

## 限界と残課題

1. **eval セット 90 件は小規模**: 現状の F1 は信頼区間が広い。500+ evaluation に拡張必要
2. **local_probable のみ F1=0.80**: 他 3 カテゴリより低い。追加 training data で改善余地
3. **意味的近接カテゴリの混同**: routing 実害は小さいが Accuracy 上は減点
4. **日本語 prompt の bias**: taxonomy-manual は全日本語、helpsteer3 は全英語。domain shift の影響未検証
5. **OOD 判定なし**: 4 カテゴリのどれにも属さない prompt に対する挙動未定義。次版で `unknown` カテゴリ追加検討

## v1 → v2 変更点 (同 PR 内で実施)

| 項目 | v1 | v2 |
|---|---|---|
| Label 数 | 4 | **5** (+unknown) |
| 学習データ | 446 | **687** (+54%) |
| local_probable F1 | 0.80 | **0.84** (+0.04) |
| OOD 対応 | 低信頼度のみ | **unknown カテゴリ + OOD fallback** |
| 実装 | scripts のみ | **+ FastAPI serve + ccr router.js + drift monitor** |

## 実装成果物（同 PR 内）

1. **`classifier/serve.py`** — FastAPI で `POST /classify` を提供、`predict_proba` + confidence threshold (default 0.5) で OOD fallback 判定
2. **`classifier/router.js`** — ccr CUSTOM_ROUTER_PATH hook、FastAPI に fetch で `label → provider,model` 変換、1秒 timeout + fallback 設計
3. **`classifier/monitor_drift.py`** — predictions.jsonl を日次バケット化、L1 distance for label dist drift + confidence drift + fallback rate 監視、alert 判定付き

## 運用フロー

```
1. FastAPI 起動:
   cd classifier && uv run python3 serve.py --port 9001

2. ccr 設定:
   ~/.claude-code-router/router.js にコピー
   config.json に "CUSTOM_ROUTER_PATH" 追加
   ccr restart

3. ログ蓄積:
   classifier/logs/predictions.jsonl に自動記録

4. drift 監視 (週次):
   uv run python3 monitor_drift.py --reference-days 7 --output drift-report.json
```

## 残課題

- eval 138 件は小規模。実運用 log (数千件) で再評価
- OOD unknown は routing 時 `cloud_required` にフォールバック (serve.py:fallback=True)
- unknown 誤検出 (false unknown) が出た場合の再学習設計は未定
- classifier model の自動再学習トリガは未実装 (drift alert 後 manual)
