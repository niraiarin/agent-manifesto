# GT Labeling + Phase 2 Accuracy (#653 Item 1)

## Opus 4.7 による 100 件 GT labeling

注意: 完全な "human GT" ではなく **LLM-GT** (Opus 4.7 = classifier とは別 model family)。
BELLA の critic model パターン相当。人間レビュー・agreement 測定は後続 Issue。

### GT 分布 (Opus 4.7 judgment)

```
cloud_required:  66 (66.0%)
hybrid:          30 (30.0%)
local_confident:  4 ( 4.0%)
local_probable:   0
unknown:          0
```

Agent-manifesto プロジェクトの real prompts は大半が complex multi-step agent directive。
classifier の training data (balanced) とは distribution が乖離。

## Before retrain (PR #652 時点の classifier)

### Exact label accuracy: 31% (31/100)
### Routing accuracy (argmax): 59% (59/100)
### Routing accuracy (utility cost_safety=1.8): **69%** (69/100)
### Leak rate: **28%** (28/100) ❌

従来の "real prompt 82% + 0 leak" 主張は 20 件の非代表的サンプルに依存していた。
GT 100 件の honest 測定では leak 28% — production に使えない。

### Confusion matrix (utility vs GT)

| GT \ pred | local_confident | local_probable | cloud_required | hybrid | unknown |
|-----------|-----|-----|-----|-----|-----|
| local_confident (4) | 0 | 1 | 3 | 0 | 0 |
| cloud_required (66) | 4 | 18 | 44 | 0 | 0 |
| hybrid (30) | 0 | 6 | 24 | 0 | 0 |

真の cloud_required の 22 件 (18+4) が Local に流れ、hybrid 6 件が Local に流れている。

## After retrain (80 GT → train, 20 GT hold-out)

GT 100 件を 80/20 split:
- 80 件を train-augmented.jsonl に merge (total 680 → retrain)
- 20 件を hold-out に保持 (完全未知)

### 20 hold-out 結果

| 指標 | Before | **After retrain** |
|---|---|---|
| Exact accuracy | 31% (on 100) | **60%** (on 20) |
| Routing accuracy (utility) | 69% | **90%** |
| Leak rate | 28% | **10%** (2/20) |
| Over-cautious | 3% | 0% |

### 2 件 leak の内訳

- True cloud_required → pred local_confident: 2 件

hold-out の 20 件中 cloud_required 14 件 + hybrid 6 件。
hybrid は全て routing-correct (cloud 側)。
cloud_required の 2 件のみ Local に流れた。

## 結論

### Gate 判定

| 基準 | 結果 | 判定 |
|---|---|---|
| GT 100 件で accuracy ≥ 90% | 60% (exact), 90% (routing, hold-out) | 部分 ✅ |
| Leak rate 0 | 10% (2/20 hold-out) | ❌ |

**Gate PASS は未達**。production sign-off には:
1. 追加 GT ラベリング (目標 500+)
2. trace-interp 以外の weak task 発見 → training 変種拡張
3. classifier architecture 再検討 (LR → fine-tuned LLM 等)

### 重要な認識訂正

PR #650 の「real prompt 82% accuracy + 0 leak」主張は **誤った一般化**だった:
- 20 件は分類方法が明確な prompt 中心 (Q&A / M-interp 典型 / OOD 典型)
- 実セッションの中間的な複雑 prompt (agent orchestration) は含まれていなかった
- そのような complex prompt で classifier は cloud_required を大量に誤分類する

今後の PR では real GT データで honest な accuracy を報告すべき。

## 次のステップ (後続 Issue)

1. **人間による GT ラベリング**: Opus 4.7 判定と人間判定の agreement 測定 (Cohen's kappa)
2. **GT データ 500+ に拡大**: 各 taxonomy task × 20 件程度
3. **Architecture 再検討**: LR + e5 では agent-manifesto 固有の complex prompt を捉えきれない可能性。fine-tuned LLM (Qwen3.6-35b-a3b LoRA) を検討
