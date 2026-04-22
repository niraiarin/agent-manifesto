# Router Architecture Survey for Production Redesign (#653)

## 背景

PR #652/#655 で現在の architecture (LR + multilingual-e5-small embedding) の限界が判明:
- eval 96.6% accuracy だが GT 100 件で routing 69% / leak 28%
- 学習データが taxonomy-balanced、実 prompt 分布 (cloud_required 66%) と乖離
- LR softmax は 5-class で信頼度が低く (mean conf 0.46)、OOD とドメイン内の区別が曖昧

## 先行・最新研究サーベイ (2025-2026)

### A. 軽量 classifier + LoRA: vLLM Semantic Router (arxiv:2603.12646, 2026)

mmBERT-32K + LoRA で multi-task classification (domain / jailbreak / PII)。
**98x faster** than naive baseline、ONNX concurrent session で deployment。
[link](https://arxiv.org/html/2603.12646)

**教訓**: 複数 classification task を LoRA で共有 → latency 削減 + accuracy 維持。

### B. Cross-encoder vs Bi-encoder

- Cross-encoder accuracy: +44pt MRR on MS MARCO vs bi-encoder
- 2-stage pipeline (bi-encoder 候補絞り → cross-encoder rerank) が現在の best practice
- Distilled cross-encoder で 2-3x 高速 + 精度 95% 維持
[link](https://www.emergentmind.com/topics/bi-encoder-and-cross-encoder-architectures)

**教訓**: 我々の bi-encoder (e5-small) は search 向け、classification には cross-encoder の方が精度出る。

### C. SetFit: Few-shot contrastive (HuggingFace, 2025)

Sentence Transformer + 分類 head を **contrastive learning** で fine-tune。
**8 examples/class** で RoBERTa-Large 3k-full-train に匹敵の精度達成。
学習 30 秒 / $0.025。class imbalance にも対応。
[link](https://huggingface.co/blog/setfit)

**教訓**: 100 GT だけで現状を大幅改善できる可能性。

### D. BELLA: Skill profile (arxiv:2602.02386, Feb 2026)

Critic LLM が task ごとに skill profile を生成、cost-aware で model select。
**Transparency**: natural-language rationale を出力 — black-box routing の対極。
[link](https://arxiv.org/abs/2602.02386)

**教訓**: 単なる label 予測でなく、理由付きで routing すれば debuggable。

### E. Fine-tuned Qwen3 0.5-1.5B (QLoRA, 2026)

Qwen3.5 0.8B は **< 2GB VRAM (4-bit)**。500-1000 examples で classification 任務に十分。
**50x cheaper** than generic frontier API、domain-narrow で大型を超える。
[link](https://www.datacamp.com/tutorial/fine-tuning-qwen3-5-small)

**教訓**: agent-manifesto 語彙を LM 自体が学習 → embedding layer が domain-aware に。

### F. Coding agent routing (Claude Code / Cursor / Windsurf, 2026)

- **Cursor**: local embedding index で RAG-based routing
- **Claude Code**: terminal agent、architectural thinking
- **Windsurf**: Cascade で persistent context session
- 各社 agent routing の洗練が急進中

**教訓**: production coding agent は RAG + agent routing を組合せた complex system。我々の LR 一本は足りない。

## 我々への適用可能性マトリクス

| Architecture | 実装容易度 | 必要 data | 見込み精度 | 備考 |
|---|---|---|---|---|
| **SetFit + e5** | ★★★ | 100-200 GT | +15-30pt | 最速で実装、現 embedding 再利用 |
| **QLoRA Qwen3 0.5B** | ★★ | 500-1000 GT | +20-40pt | domain 特化、latency ~50-100ms |
| **2-stage: e5 → cross-encoder** | ★ | 大量 pair data | +10-20pt | 境界ケース精度、latency 2x |
| **BELLA 相当 critic LLM** | ★ | unlimited | 不定 | transparent だが LLM call cost |
| **Multi-task LoRA (vLLM SR)** | ★ | per-task data | ? | multi-task 時に強み |

## 推奨 Architecture ロードマップ

### Phase 1 (即実装): SetFit 切替

**Why**: 現状の最大課題「100 件 GT で improvement 見込めず」を直接解決。
- Contrastive objective で class imbalance 耐性
- 既存 e5-small 再利用、infra 変更最小
- 30 秒 train → iteration 早い

**Expected**: eval routing 90% → 95%+、leak 10% → 5% 以下

### Phase 2 (GT 500+ 到達後): Fine-tuned Qwen3 0.5B QLoRA

**Why**: SetFit では shallow embedding、agent-manifesto 語彙 (P2, D13, valueless_change 等) を LM に学習させる必要。
- 24GB Mac で train 可能 (QLoRA 4-bit)
- latency 50-100ms、CUSTOM_ROUTER_PATH で問題なし
- Fine-tuned model は domain-narrow で大型汎用を超える (Qwen3 事例: 50x cheaper)

**Expected**: routing 98%+、production sign-off 水準

### Phase 3 (将来): 2-stage cross-encoder + transparency

**Why**: 境界ケース精度 + debuggable な routing 決定。
- BELLA スタイルの rationale 出力
- 現 QLoRA classifier を first-stage、cross-encoder で rerank top-2
- Edge case の routing を精査可能に

**Expected**: routing 99%+、"安心して on" できる状態

## 実装計画 (Phase 1: SetFit)

```python
from setfit import SetFitModel, SetFitTrainer
from sentence_transformers.losses import CosineSimilarityLoss

model = SetFitModel.from_pretrained(
    "intfloat/multilingual-e5-small",
    labels=["local_confident", "local_probable", "cloud_required", "hybrid", "unknown"],
)
trainer = SetFitTrainer(
    model=model,
    train_dataset=gt_80,      # Opus GT 80 件 + taxonomy 80 件 = 160 件
    eval_dataset=gt_holdout_20,
    loss_class=CosineSimilarityLoss,
    num_iterations=20,
    num_epochs=1,
)
trainer.train()
```

既存 serve.py の LogisticRegression を SetFit model に置換。probs 出力は同形式。

### Gate 再設定

| 基準 | 現状 | Phase 1 target | Phase 2 target |
|---|---|---|---|
| Routing accuracy (hold-out) | 90% | **95%** | **98%** |
| Leak rate | 10% | **5%** | **0%** |
| ECE | 0.073 | 0.05 | 0.03 |

## References

- [vLLM Semantic Router (arxiv:2603.12646)](https://arxiv.org/html/2603.12646)
- [SetFit (HuggingFace)](https://huggingface.co/blog/setfit)
- [BELLA (arxiv:2602.02386)](https://arxiv.org/abs/2602.02386)
- [SkillRouter (arxiv:2603.22455)](https://arxiv.org/abs/2603.22455)
- [Qwen3.5 Fine-tune Tutorial](https://www.datacamp.com/tutorial/fine-tuning-qwen3-5-small)
- [Cross-encoder vs Bi-encoder guide](https://www.emergentmind.com/topics/bi-encoder-and-cross-encoder-architectures)
- [Fine-Tuned Small Models Beat RAG (2026)](https://dev.to/dr_hernani_costa/fine-tuned-small-models-beat-rag-the-2026-economics-171h)
- [Best Small LLMs 2026](https://www.bentoml.com/blog/the-best-open-source-small-language-models)

## 次アクション

1. **本 PR 内で Phase 1 SetFit 実装** (user 判断次第)
2. **Phase 2/3 は別 Issue で追跡**: GT 500+ 収集後に着手

Phase 1 を同 PR で実施するか、survey 記録のみとして別 Issue へ回すか、user 判断要。
