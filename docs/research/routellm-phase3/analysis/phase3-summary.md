# Phase 3-5 Summary (#653)

## 成果物

本 PR で Phase 3, 4, 5 を自動実行可能な部分まで完了。Phase 1 (human GT) は候補 100 件の sampling まで完了、実際のラベリングは operational task。

2026-04-23 追記: Phase 2 architecture comparison の最終 winner は
**microsoft/mdeberta-v3-base full fine-tune**。GT hold-out routing 100% / leak 0% により
production router の default とする。

## Phase 2: Architecture comparison 最終結論

| Model | Taxonomy exact | GT hold-out exact | GT routing | GT leak | 判定 |
|---|---:|---:|---:|---:|---|
| LR + calibrated e5 | 96.6% | 60.0% | 90.0% | 10.0% | 退役候補 |
| SetFit + e5 | 100.0% | 65.0% | 95.0% | 5.0% | 次点 |
| mmBERT-base full FT | 100.0% | 60.0% | 100.0% | 0.0% | 次点 |
| **mDeBERTa-v3-base full FT** | **99.3%** | **65.0%** | **100.0%** | **0.0%** | **採用** |
| xlm-roberta-base full FT | 95.3% | 65.0% | 100.0% | 0.0% | taxonomy leak で除外 |

追加検証:
- Eval calibration: ECE 0.1096, accuracy 99.3%
- GT hold-out calibration: ECE 0.2702, exact accuracy 65.0%
- Load test: p95 43.9ms (c=1), 80.8ms (c=5), 259.2ms (c=10)
- E2E smoke: `serve_encoder.py` -> `/classify` -> `router.js` utility decision PASS

## Phase 3: Fine-grained cost_safety sweep

**Verifier B-3 (medium)** の「cost_safety={1,2,5,10,20,50} の粗い grid」を解消。
1.0-3.0 を 0.1 刻みで 21 点 sweep 実行:

### 結果

| cost_safety | routing_acc | leak | Real Local count | Real Local % |
|---|---|---|---|---|
| 1.00 | 0.9796 | **0.0068** | 254 | 21.6% |
| 1.70 | 0.9796 | **0.0068** | 217 | 18.4% |
| **1.80** ⭐ | **0.9864** | **0.0000** | **213** | **18.1%** |
| 2.00 (旧 default) | 0.9864 | 0.0000 | 207 | 17.6% |
| 3.00 | 0.9864 | 0.0000 | 174 | 14.8% |

- **First zero-leak 点: cost_safety=1.8** (連続 sweep で 1.7→1.8 でステップ変化)
- Best zero-leak routing accuracy: **0.9864** (cost=1.8 が最小)
- 旧 default 2.0 より **+6 件 Real Local** (+0.5pt) を取り戻せる

### 結論

**Default を 2.0 → 1.8 に変更**。router.js の `ROUTING_COST_SAFETY` default を更新。

## Phase 4: Held-out calibration validation

**Verifier A-1 (medium)** の "double-dipping" 懸念を検証。

### Method

full corpus 731 を stratified 60/20/20 split:
- Train (60%): 438 件
- Calibration (20%): 146 件 → CalibratedClassifierCV の CV で使用
- True hold-out (20%): 147 件 → method selection に使わず純粋に測定

### 結果

| 指標 | v2 報告 (train-eval split) | **v3 true hold-out** | Delta |
|---|---|---|---|
| ECE | 0.0734 | **0.0524** | -0.021 |
| Accuracy | 0.9660 | 0.9592 | -0.007 |

**Delta -0.021 = 報告 ECE は conservative だった**。double-dipping による inflation は観測されず。

### 結論

calibration は実際に汎化する。v2 の ECE 0.073 claim は defensible。Verifier A-1 懸念は empirical に解消。

## Phase 5: Per-task accuracy breakdown

**Verifier D-1 (medium)** の "24 task のうち long-form coverage 5 task のみ" を測定。

### 結果

41 tasks に eval coverage あり（target 24 + OOD 変種 + helpsteer3 由来）。

**routing_accuracy ≥ 0.80: 40/41 tasks**

#### Weak task (1件)

- **`trace-interp`**: routing_acc 0.667 (4/6)、n_eval=6、n_train=34

### 結論

ほぼ全 task で high routing accuracy。trace-interp のみ要追加 training variants。これは後続 Issue として追加。

## Phase 1: Human GT (sampling 完了、labeling は manual)

### 成果物

`label-data/real-gt-candidates.jsonl` — 1,178 real prompts から層化サンプリング:

- Predicted label 分布を target に一致: local_confident 5, local_probable 20, cloud_required 23, hybrid 38, unknown 14
- Confidence bin: low 2, mid 23, high 26, vhigh 26, peak 23
- Length bin: short 76, medium 18, long 2, xlong 4

### 次のステップ (operational)

1. `real-gt-candidates.jsonl` を人間 (ideally 2 annotators) に渡す
2. 各 entry の `gt_label` field を埋める (分類軸: #647 taxonomy §3.1 A1-A6)
3. Cohen's kappa 測定で inter-annotator agreement
4. 完成後、`retrain_cli.py` で corrections として再学習

これは本 PR の scope 外。別 task として 2-4 週で実施。

## Overall Gate 判定

| Phase | 成果 | Gate |
|---|---|---|
| 1 | 100 候補 sampling、分布正しい | ✅ 準備完了（manual labeling 待ち） |
| 3 | cost_safety=1.8 が真の optimum、default 更新 | ✅ |
| 4 | held-out ECE 0.0524 < 0.0734 報告値、double-dipping なし | ✅ |
| 5 | 40/41 tasks で routing_acc ≥ 0.80 | ✅ (trace-interp のみ要改善) |

**Sub-5 (#653) → production sign-off Gate PASS。**

残すべき follow-up は production blocker ではなく quality/ops improvement:
1. Human GT 500+ + Cohen's kappa
2. Trace-interp 追加変種の継続
3. Auto-retrain cron と Prometheus/Grafana observability
