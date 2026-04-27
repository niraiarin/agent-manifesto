# Disagreement-Tier Results (2026-04-27)

Run of `compute_disagreement_tiers.py` on the 500-item Qwen-labeled corpus.
First end-to-end execution since the tool shipped (PR #686, fix #687).

## Inputs

| Source | File | Records | Model |
|--------|------|---------|-------|
| qwen35b  | `qwen-labels-500.jsonl` | 500 | `Qwen3.6-35B-A3B-UD-Q2_K_XL` (Metal full offload) |
| qwen27b  | `qwen-labels-27b-q4.jsonl` | 500 | `Qwen3.6-27B-UD-Q4_K_XL` |
| mdeberta | `qwen-candidates-500.jsonl` (`predicted_label`) | 500 | production mDeBERTa via stratified sampling |

All three labelings completed with **0 fallbacks** (no parse failures).

## Tier distribution

| Tier | Definition | Count | % | Annotator action |
|------|-----------|-------|---|------------------|
| **0** | All 3 agree | 115 | 23.0% | Auto-accept majority as GT |
| **1** | 2-vs-1 (one dissenter) | 313 | 62.6% | Quick review (~30 s each) |
| **2** | All 3 unique | 72 | 14.4% | Deep review (~2-3 min each) |
| total | | 500 | 100% | |

Estimated human time:

- tier 0: 0 min (auto-accept)
- tier 1: 313 × 30 s ≈ **156 min**
- tier 2: 72 × 2.5 min ≈ **180 min**
- **total ≈ 5.6 hours** (vs ~20 hours for full review = 28% effort)

The tier 2 yield (14.4%) is below the issue's projected 20-30%, meaning
the high-cost deep review queue is shorter than expected. Net win.

## Per-model label distribution

| Label | qwen35b | qwen27b | mdeberta |
|-------|--------:|--------:|---------:|
| local_confident | 72 | 15 | 49 |
| local_probable | 97 | 28 | 138 |
| cloud_required | 240 | 320 | 129 |
| hybrid | 52 | 99 | 119 |
| unknown | 39 | 38 | 65 |
| **total** | **500** | **500** | **500** |

Qwen 27B is markedly more "cloud-eager" (320/500 = 64% cloud_required)
than Qwen 35B (240/500 = 48%) or mDeBERTa (129/500 = 26%). This bias
is the dominant driver of tier-1 splits where 27B disagrees with the
other two.

## Pairwise agreement (Cohen's κ)

| Pair | Agreement | κ | Interpretation |
|------|----------:|--:|----------------|
| qwen35b vs qwen27b | 65.0% | **0.4624** | Moderate (Gate 0.6 still unmet, consistent with prior PR #675 0.4642) |
| qwen35b vs mdeberta | 34.2% | 0.1494 | Slight |
| qwen27b vs mdeberta | 32.4% | 0.1099 | Slight |

Qwen vs mDeBERTa agreement is essentially noise-level (κ ≈ 0.1). This
is the expected mismatch between an LLM annotator and a trained
classifier on a 5-class taxonomy with ambiguous middle ground (hybrid /
local_probable).

## Tier 2 sample (deep-review queue)

Five representative entries where all 3 models disagree:

| id | qwen35b | qwen27b | mdeberta | prompt preview |
|----|---------|---------|----------|----------------|
| gt-qwen-0008 | unknown | cloud_required | local_confident | 独立 context agent で議論し提案して。 |
| gt-qwen-0064 | local_confident | cloud_required | local_probable | 今回の実験において、新規課題や発展調査研究があれば Issue を立てて。 |
| gt-qwen-0067 | cloud_required | unknown | local_probable | LM Studio で、95% までは進捗するんだけど、Client disconnected って出てしまう。 |
| gt-qwen-0071 | local_confident | unknown | local_probable | そのworktreeが関連している branchもマージ済 |
| gt-qwen-0078 | hybrid | cloud_required | local_probable | research の過程の話なんだけど、先行研究調査や judgment について issue に記録するような workflow って |

These are exactly the prompts where human reasoning is needed: ambiguous
intent, mixed cognitive vs operational components, or short fragments
that lack enough context for any model to commit confidently.

## Gate evaluation (per #677 spec)

| Metric | Threshold (PASS / CONDITIONAL / FAIL) | Actual | Verdict |
|--------|---------------------------------------|--------|---------|
| Inter-annotator κ (tier 1+2) | ≥ 0.75 / 0.60–0.75 / < 0.60 | **N/A** (no human labels yet) | — |
| Tier 0 auto-accept rate | ≥ 25% / 15-25% / < 15% | **23.0%** | **CONDITIONAL** |
| mDeBERTa retrained ECE | ≤ 0.10 / 0.10-0.15 / > 0.15 | **N/A** (no retrain yet) | — |

**Tier 0 = 23%** lands just below the 25% PASS threshold. The CONDITIONAL
zone applies. Two interpretations:

1. **Annotation efficiency is preserved** even at 23% (~5.6 h vs full 20 h),
   so PASS-via-effort is still favorable.
2. **Model bias** (especially Qwen 27B's cloud-eagerness) suppresses
   tier 0 yield. A re-run with calibration or prompt-tuning of 27B may
   nudge tier 0 above 25%.

Recommendation: proceed with human annotation on tier 1+2. If the
inter-annotator κ on the human results clears 0.75, the auto-accept
shortfall is moot — the human consensus replaces the missing tier 0
margin.

## Files (under `label-data/`, gitignored)

| File | Records | Notes |
|------|--------:|-------|
| `qwen-candidates-500.jsonl` | 500 | Stratified sample input + mDeBERTa predictions |
| `qwen-labels-500.jsonl` | 500 | Qwen 35B output |
| `qwen-labels-27b-q4.jsonl` | 500 | Qwen 27B Q4 output |
| `disagreement-tiers.jsonl` | 500 | Tier classification output |
| `human-gt-tier0-auto.jsonl` | 115 | Auto-accepted GT (no human review) |
| `tier1-candidates.jsonl` | 313 | Quick-review queue |
| `tier2-candidates.jsonl` | 72 | Deep-review queue |

## Next steps

1. Pass `tier1-candidates.jsonl` and `tier2-candidates.jsonl` through
   `annotator_kit.py` to generate per-annotator packets.
2. Recruit ≥ 2 annotators (e.g. alice, bob); they label independently.
3. Compute inter-annotator κ via the existing `kappa.py` (#674).
4. Build the merged `human-gt-majority.jsonl` from auto-accept tier 0 +
   majority of tier 1+2.
5. Feed corrections through `gt_to_corrections.py` → retrain mDeBERTa →
   measure new ECE.

Reproduce:

```bash
python3 docs/research/routellm-phase3/classifier/compute_disagreement_tiers.py \
  --qwen35b   docs/research/routellm-phase3/label-data/qwen-labels-500.jsonl \
  --qwen27b   docs/research/routellm-phase3/label-data/qwen-labels-27b-q4.jsonl \
  --mdeberta  docs/research/routellm-phase3/label-data/qwen-candidates-500.jsonl \
  --output    docs/research/routellm-phase3/label-data/disagreement-tiers.jsonl \
  --summary
```
