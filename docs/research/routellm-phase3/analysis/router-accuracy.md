# Causal LM Router Accuracy Report (#649)

**日付**: 2026-04-23
**学習データ**: 446 entries (taxonomy-manual 335 + helpsteer3 111)
**アーキテクチャ**: `intfloat/multilingual-e5-small` (384 dim) + Logistic Regression

## Gate 判定: **PASS**

Gate 基準:
- [x] Overall accuracy ≥ 85% → **92.22%**
- [x] 全 4 categories F1 ≥ 0.70 → min 0.80 (local_probable)

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

| Category | Precision | Recall | F1 | Support |
|---|---|---|---|---|
| local_confident | 0.91 | 1.00 | **0.95** | 20 |
| local_probable | 0.77 | 0.83 | **0.80** | 12 |
| cloud_required | 0.94 | 1.00 | **0.97** | 29 |
| hybrid | 1.00 | 0.83 | **0.91** | 29 |

- Accuracy: **0.9222**
- Macro F1: **0.91**
- Weighted F1: **0.92**

## Confusion Matrix

```
                  local_confident  local_probable  cloud_required  hybrid
local_confident                20               0               0       0
local_probable                  2              10               0       0
cloud_required                  0               0              29       0
hybrid                          0               3               2      24
```

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

## Deferred

- 実運用下での drift monitoring
- 分類信頼度 (predict_proba) の閾値調整（低 confidence → Cloud fallback）
- multi-label vs single-label の選択再評価

## 次ステップ

1. `ccr-integration.md` §方式 B の FastAPI 実装
2. `~/.claude-code-router/router.js` 作成
3. config.json に `CUSTOM_ROUTER_PATH` 追加
4. `ccr restart` + 実運用で validate
