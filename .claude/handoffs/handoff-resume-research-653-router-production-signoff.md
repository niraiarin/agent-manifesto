# Handoff Resume
git_sha: 310cf114485e87e3b17ba185edcd4da483a0e55d
branch: research/653-router-production-signoff
worktree: /Users/nirarin/work/agent-manifesto-research-653
skill: research (#653 Sub-5 production sign-off)
phase: Phase 2 勝者決定済、production release 前の 6 項目が未実装
intent: PR #655 (Sub-5 Router production sign-off) で **Architecture Phase 2 = mDeBERTa-v3-base full fine-tune** を採用決定。本セッションで結果確認、次セッションで serve 更新 + 検証 + merge までを実行する想定。

## Progress

### Done
- Phase 3 (fine cost_safety sweep): cost_safety=**1.8** が真の optimum (integer grid では 2.0 だった)
- Phase 4 (held-out calibration): true hold-out ECE **0.0524** (< 報告 0.0734、over-optimism なし)
- Phase 5 (per-task accuracy): 41 tasks / 40 で routing_acc ≥ 0.80、唯一の weak (trace-interp 0.667) は long-form variants 追加で 1.000 に
- Phase 1 SetFit (Gate PASS): GT hold-out routing 95% / leak 5% / latency 20ms
- Opus 4.7 GT labeling: 100 件の LLM-pseudo-GT (真 human GT は別 Issue)
- GT 80/20 split で re-train → hold-out 20 件で routing 90% → leak 10% (SetFit 前)
- **Architecture 再検討サーベイ 5 論文**: mmBERT/mDeBERTa/ModernBERT/Nemotron/Bonsai 比較
- **Phase 2 勝者決定: microsoft/mdeberta-v3-base**
  - Training 時間: **300秒 (MPS)**
  - Taxonomy (n=150): exact 99.3% / routing 100% / leak 0%
  - **GT hold-out (n=20): exact 65% / routing 100% / leak 0%** ← production Gate 全項目クリア
- 次点 mmBERT-base (GT exact 60%、latency 優位)、3 位 xlm-roberta-base (GT exact 65% だが taxonomy leak 1.3%)
- 除外: Qwen 2.5-0.5B LoRA (overfit)、Qwen 3.5-4B zero-shot (latency 8sec)、Nemotron 9B (規模/causal 不適合)、Bonsai 8B (fine-tune 未対応)

### Remaining (次セッションで実行)
- [ ] 1. `serve_encoder.py` 新規作成 (mDeBERTa 用 FastAPI endpoint)
- [ ] 2. mDeBERTa の calibration 検証 (raw softmax が reliable か)
- [ ] 3. Latency 実測 (予想 ~80ms、確認要)
- [ ] 4. Load test (concurrent 1/5/10)
- [ ] 5. E2E smoke test: classify → router.js → routing decision
- [ ] 6. Docs 更新: router-accuracy-v2.md §7+ を mDeBERTa 中心に書き換え
- [ ] 7. commit + push + PR #655 description 更新
- [ ] 8. Verifier agent 独立 review → 指摘対処 → merge

### Deferred (別 Issue)
- GT 500+ 拡大 (Opus 100件のみでなく human annotator + Cohen's kappa)
- Auto-retrain cron 設定
- Prometheus/Grafana observability

## Next Steps (具体アクション)

### Step 1: serve_encoder.py 新規作成

既存 `serve_setfit.py` を参考に、`AutoModelForSequenceClassification` 用の FastAPI endpoint を書く:

```python
# key differences from serve_setfit.py:
#   model = AutoModelForSequenceClassification.from_pretrained(model_dir / "encoder_model")
#   tokenizer = AutoTokenizer.from_pretrained(model_dir / "encoder_model")
#   # predict: tokenize → forward → softmax
#   logits = model(**tokenizer(prompt, return_tensors="pt", truncation=True, max_length=512)).logits
#   probs_arr = torch.softmax(logits, dim=-1).squeeze().cpu().numpy()
```

同じ `ClassifyResponse` schema (label, confidence, probs, fallback, latency_ms, p_local, p_cloud, utility_route) を維持。

### Step 2: Calibration 検証

```bash
cd docs/research/routellm-phase3/classifier
uv run python3 held_out_calibration.py --train-full ../label-data/full.jsonl \
  --encoder microsoft/mdeberta-v3-base --output ../analysis/held-out-calibration-mdeberta.json
```

(注意: held_out_calibration.py は現状 LR 用。encoder 対応に書き換え必要、または ECE 計算だけ別 script で)

### Step 3: Latency + Load test

```bash
# serve 起動
uv run python3 serve_encoder.py --port 9001 --model-dir ../model-mdeberta

# 別 terminal から
uv run python3 load_test.py --concurrency 1 5 10 --total 50 \
  --output ../analysis/load-test-mdeberta.json
```

### Step 4: E2E smoke test

```bash
# llama-server は停止したまま、classifier だけ serve
# router.js の LOCAL_PROVIDER は現 "llama-server,qwen3.6-35b-a3b-bf16" のまま
# ccr 再起動して CUSTOM_ROUTER_PATH 経由で通す
# 20 件の GT hold-out prompt を順次投入して routing 確認
```

### Step 5: Docs 更新

`docs/research/routellm-phase3/analysis/router-accuracy-v2.md` に:
- §1 主要指標表を mDeBERTa 数値に更新
- §8 運用移行ガイドに serve_encoder.py コマンド追加
- §9 新設: Architecture Phase 2 最終比較 (mmBERT/mDeBERTa/XLM-R/SetFit)
- `architecture-survey.md` に Phase 2 最終結論を追記

`phase3-summary.md` も mDeBERTa 基準に更新。

### Step 6: commit + PR 更新

```bash
cd /Users/nirarin/work/agent-manifesto-research-653
git add docs/research/routellm-phase3/
# 注: model-*/encoder_model/ と model-*/_training/ は .gitignore に追加 (既に setfit_model は gitignore 済)
# Large model files 除外: .gitignore に "model-*/encoder_model/" 追加
git commit -m "research: Phase 2 mDeBERTa-v3-base adopted (#653) (conservative extension)"
git push
gh pr edit 655 --body "<updated with mDeBERTa results>"
```

### Step 7: Verifier + merge

前 Session で PR #652 の verifier 独立 review が重要な発見をした (argmax silent leak 等)。
同様に PR #655 もverifier → 対処 → merge の流れ。

## Files Modified (staged or pending)

### 実装 (committed in current branch, push 済)
- `docs/research/routellm-phase3/classifier/train_encoder.py` — encoder full fine-tune (mmBERT/mDeBERTa/XLM-R 共通)
- `docs/research/routellm-phase3/classifier/train_qlora.py` — Qwen LoRA (失敗、除外)
- `docs/research/routellm-phase3/classifier/train_setfit.py` — SetFit (Phase 1、退役候補)
- `docs/research/routellm-phase3/classifier/zero_shot_qwen.py` — Qwen zero-shot (記録のみ)
- `docs/research/routellm-phase3/classifier/opus_labels.py` — Opus GT labeling
- `docs/research/routellm-phase3/classifier/gt_accuracy.py` — GT hold-out accuracy 測定
- `docs/research/routellm-phase3/classifier/sample_for_gt.py` — stratified sampling
- `docs/research/routellm-phase3/classifier/fine_cost_sweep.py` — cost_safety sweep
- `docs/research/routellm-phase3/classifier/held_out_calibration.py` — calibration
- `docs/research/routellm-phase3/classifier/per_task_accuracy.py` — per-task breakdown
- `docs/research/routellm-phase3/classifier/utility_decision.py` — utility-based decision
- `docs/research/routellm-phase3/analysis/architecture-survey.md` — Phase 2 再検討記録

### 実装 (未 commit、本セッションで作った)
- `docs/research/routellm-phase3/classifier/train_encoder.py` ← train 済
- `docs/research/routellm-phase3/analysis/gt-phase2-summary.md`
- model ディレクトリ (.gitignore 追加要): model-mmbert/, model-mdeberta/, model-xlmr/, model-qlora/

### 次セッションで作る
- `docs/research/routellm-phase3/classifier/serve_encoder.py` (mDeBERTa 用 FastAPI)
- `docs/research/routellm-phase3/analysis/load-test-mdeberta.json`
- `docs/research/routellm-phase3/analysis/latency-mdeberta.json`
- `docs/research/routellm-phase3/analysis/e2e-smoke-mdeberta.json`

## Key Decisions

- **Phase 2 採用: mdeberta-v3-base full fine-tune** (当初 QLoRA Qwen 0.5B は失敗で除外)
- **Encoder full-FT vs Causal LM LoRA**: 我々のタスク (680 samples, 5-way classification) には encoder 直接学習が最適。causal LM の classification head ハックより素直
- **cost_safety default: 1.8** (従来 2.0 から変更、integer grid 依存の失敗を解消)
- **Pseudo-GT from Opus 4.7**: human GT は別 Issue に切り出し (workflow として separation)

## Training Data 現状

- `docs/research/routellm-phase3/label-data/train-augmented.jsonl`: **680 entries**
  - 600 taxonomy-manual (oversampled 5x + balanced)
  - 80 Opus-GT (training にマージ済)
- `docs/research/routellm-phase3/label-data/eval.jsonl`: 150 (taxonomy)
- `docs/research/routellm-phase3/label-data/gt-holdout.jsonl`: 20 (Opus-GT)

## Model 結果サマリ

| Model | Taxonomy exact | GT routing | GT leak | Training時間 |
|---|---|---|---|---|
| LR baseline (calibrated) | 96.7% | 90% | 10% | 2s |
| SetFit (Phase 1) | 100% | 95% | 5% | 9min CPU |
| Qwen 2.5-0.5B LoRA | 88% | 65% | 35% | 9min CPU |
| Qwen 3.5-4B zero-shot | N/A | 95% | 5% | 0 (推論 8sec) |
| mmBERT-base fullFT | **100%** | **100%** | **0%** | 5min MPS |
| **mdeberta-v3-base fullFT** ⭐ | 99.3% | **100%** | **0%** | 5min MPS |
| xlm-roberta-base fullFT | 95.3% | 100% | 0% | 3.3min MPS |

## Infrastructure 状態

- llama-server: 停止済 (MPS メモリ解放のため)
- ccr: 状態未確認 (停止していればそのまま、ccr start で起動可能)
- Python env: `docs/research/routellm-phase3/classifier/.venv` (uv, gitignored)
- 追加パッケージ: `setfit`, `peft`, `protobuf`, `sentencepiece`, `joblib`, `aiohttp`

## PR 状態
- PR #655 (https://github.com/niraiarin/agent-manifesto/pull/655) OPEN
- 最新 commit: 310cf11 (SetFit Phase 1 実装)
- 次セッションで mDeBERTa 成果追加 → description 更新 → verifier → merge

## Issues
- #653: Sub-5 Router production sign-off (進行中、本 PR で close 予定)
- #651 (merged via PR #652): Sub-4 Router production hardening
- #639: Parent Phase 2 issue
- #589: Root Parent (Local LLM routing)
