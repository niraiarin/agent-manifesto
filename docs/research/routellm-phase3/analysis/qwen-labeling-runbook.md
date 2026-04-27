# Qwen LLM Labeling Runbook

Phase 2 of #671: use a Qwen3.6 model as pseudo-GT annotator before involving humans.

## Model Substitution Note

**Target**: `YTan2000/Qwen3.6-27B-TQ3_4S`
**Used**: `Qwen3.6-35B-A3B-UD-Q2_K_XL` (local)

Why: `TQ3_4S` (TurboQuant) uses ggml tensor type 46, which stock llama.cpp
(build 8890) cannot load (max supported type is 42). Running the target model
requires the `turbo-tan/llama.cpp-tq3` fork. The 35B-A3B MoE alternative is
same-generation and already tested, so it serves as the substitute. Record the
substitution when reporting agreement numbers.

## 1. Start the server

```bash
bash scripts/start-llama-server.sh
```

- Default model: `$HOME/models/Qwen3.6-35B-A3B-UD-Q2_K_XL.gguf`
- Default port: `8090`
- `--jinja` is enabled so `chat_template_kwargs: {enable_thinking: false}` works
  on Qwen3.6 (required to suppress reasoning output).

Verify:

```bash
curl -sf http://localhost:8090/v1/models
```

## 2. Extract real prompts

```bash
python3 docs/research/routellm-phase3/classifier/extract_real_prompts.py \
  --project-dir ~/.claude/projects/-Users-nirarin-work-agent-manifesto/ \
  --output docs/research/routellm-phase3/label-data/real-prompts.jsonl \
  --max-len 2000 --dedup
```

Outputs ~1,200 full prompts.

## 3. Stratified sample of 500

```bash
python3 docs/research/routellm-phase3/classifier/sample_qwen_candidates.py \
  --real-prompts docs/research/routellm-phase3/label-data/real-prompts.jsonl \
  --corpus-classified docs/research/routellm-phase3/analysis/real-corpus-per-prompt.jsonl \
  --output docs/research/routellm-phase3/label-data/qwen-candidates-500.jsonl \
  --n 500
```

Stratification uses the `label` + `confidence` fields from `real-corpus-per-prompt.jsonl`
(production mDeBERTa predictions). Target routing distribution:

- `local_probable`: 50%
- `cloud_required`: 20%
- `local_confident`: 15%
- `hybrid`: 10%
- `unknown`: 5%

## 4. Qwen labeling

```bash
python3 docs/research/routellm-phase3/classifier/qwen_labels.py \
  --input docs/research/routellm-phase3/label-data/qwen-candidates-500.jsonl \
  --output docs/research/routellm-phase3/label-data/qwen-labels-500.jsonl \
  --llama-url http://localhost:8090/v1/chat/completions \
  --checkpoint-every 50
```

- Thinking mode disabled via `chat_template_kwargs: {enable_thinking: false}`
- Checkpoints every 50 items (resume-safe: existing `id`s in the output file are skipped)
- Each entry records `gt_label`, `annotator`, `latency_ms`, `ts`, and a short raw preview

Smoke test (first 5 items):

```bash
python3 docs/research/routellm-phase3/classifier/qwen_labels.py \
  --input docs/research/routellm-phase3/label-data/qwen-candidates-500.jsonl \
  --output /tmp/qwen-smoke.jsonl \
  --llama-url http://localhost:8090/v1/chat/completions \
  --limit 5 --checkpoint-every 1
```

## 5. Agreement with Opus pseudo-GT

```bash
python3 docs/research/routellm-phase3/classifier/qwen_vs_opus.py \
  --qwen docs/research/routellm-phase3/label-data/qwen-labels-500.jsonl \
  --opus-source docs/research/routellm-phase3/classifier/opus_labels.py \
  --output docs/research/routellm-phase3/analysis/qwen-vs-opus.md
```

Overlap may be zero if Qwen candidates do not share ids with Opus. In that
case pass `--candidates-ref <path>` to a JSONL that carries the original
`gt-NNN` ids (session_id + prompt prefix are used for matching).

## 6. Gate

| Metric | PASS | CONDITIONAL | FAIL |
|---|---|---|---|
| Qwen-Opus Cohen's kappa (overlap ≥ 30) | ≥ 0.6 | 0.4–0.6 | < 0.4 |
| 500-item completion rate | 100% | 95–99% | < 95% |
| Qwen label distribution vs. routing target | ≤ 20% L1 delta | 20–30% | > 30% |

- **PASS** → proceed with human annotation on the same 500 candidates.
- **CONDITIONAL** → iterate on the system prompt, or accept as provisional GT.
- **FAIL** → Qwen-at-this-quant is not a credible annotator; escalate to humans directly.

## 7. Next steps after PASS

- Convert Qwen labels to corrections: `gt_to_corrections.py --labeled qwen-labels-500.jsonl`
- Run `calibrate_from_gt.py --labeled qwen-labels-500.jsonl` to measure mDeBERTa ECE
- Release candidates to human annotators for final GT

## Troubleshooting

- **500 Model loading error `ggml type 46`** — stock llama.cpp cannot load TurboQuant.
  Use 35B-A3B substitute or build `turbo-tan/llama.cpp-tq3` and reinvoke with the
  forked binary.
- **Empty `content` + thinking trace in `reasoning_content`** — `--jinja` missing
  or `chat_template_kwargs.enable_thinking` not set to `false`.
- **Labels mostly `unknown`** — parse fallback triggered; inspect `raw_preview`
  in the output JSONL for malformed JSON.
- **Checkpoint not resuming** — confirm the output file already contains entries
  with matching `id`s; only same-`id` entries are skipped.
