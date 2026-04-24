# GT Labeling Runbook

## 1. Sampling

Generate a new GT candidate batch from the worktree root:

```bash
python3 docs/research/routellm-phase3/classifier/sample_for_gt.py \
  --real-prompts docs/research/routellm-phase3/label-data/real-prompts.jsonl \
  --model-dir docs/research/routellm-phase3/model \
  --output docs/research/routellm-phase3/label-data/gt-candidates-500.jsonl \
  --n 500 \
  --exclude docs/research/routellm-phase3/label-data/real-gt-candidates.jsonl
```

- Default behavior stays unchanged when `--n`, `--exclude`, and `--backend` are omitted.
- Use `--backend mdeberta --serve-url http://localhost:9001` only when the local encoder service is running.
- Review the output for duplicate prompts before distribution.

## 2. Annotator Kit Setup

Create per-annotator packets:

```bash
python3 docs/research/routellm-phase3/classifier/annotator_kit.py \
  --candidates docs/research/routellm-phase3/label-data/gt-candidates-500.jsonl \
  --annotators alice bob carol \
  --output-dir docs/research/routellm-phase3/label-data/annotations
```

- Taxonomy reference: `docs/research/routellm-phase3/analysis/label-guide.md`
- Distribute one JSONL and one Markdown packet per annotator.
- Prompts may contain sensitive content. Do not upload them to external tools, hosted LLMs, chat systems, or shared drives beyond the approved review path.

## 3. Annotation Review

- Collect returned `*.jsonl` files in a single review directory.
- Confirm each file preserves `id`, `prompt`, `session_id`, and `predicted_*`.
- Diff `gt_label` and `annotator_notes` only.
- Reject packets with broken JSONL rows, missing labels, or rewritten ids.

## 4. Agreement Analysis

Run agreement analysis after at least two packets are complete:

```bash
python3 docs/research/routellm-phase3/classifier/kappa.py \
  --annotations \
    docs/research/routellm-phase3/label-data/annotations/alice.jsonl \
    docs/research/routellm-phase3/label-data/annotations/bob.jsonl \
    docs/research/routellm-phase3/label-data/annotations/carol.jsonl \
  --pseudo-gt docs/research/routellm-phase3/label-data/gt-opus.jsonl \
  --output docs/research/routellm-phase3/analysis/annotator-agreement.json
```

- Gate: Cohen's kappa or Fleiss' kappa must be `>= 0.75`.
- Use the emitted majority-vote JSONL as the reviewer baseline for final GT.
- If the gate fails, escalate disputed items for adjudication instead of silently averaging.

## 5. Recalibration

Re-measure mDeBERTa calibration against majority GT:

```bash
python3 docs/research/routellm-phase3/classifier/calibrate_from_gt.py \
  --labeled docs/research/routellm-phase3/label-data/gt-labeled-majority.jsonl \
  --model-dir docs/research/routellm-phase3/model-mdeberta \
  --serve-url http://localhost:9001 \
  --output docs/research/routellm-phase3/analysis/mdeberta-calibration-gt500.md
```

- If the local service is unavailable, the script falls back to loading `model-dir` directly.
- Gate: overall ECE must be `<= 0.10`.
- Keep the markdown report with the run artifacts.

## 6. Retrain

Convert GT into retraining corrections and then use the existing retrain pipeline:

```bash
python3 docs/research/routellm-phase3/classifier/gt_to_corrections.py \
  --labeled docs/research/routellm-phase3/label-data/gt-labeled-majority.jsonl \
  --output docs/research/routellm-phase3/label-data/corrections-gt500.jsonl \
  --only-disagreements

python3 docs/research/routellm-phase3/classifier/retrain_cli.py \
  --base-train docs/research/routellm-phase3/label-data/train.jsonl \
  --base-eval docs/research/routellm-phase3/label-data/eval.jsonl \
  --corrections docs/research/routellm-phase3/label-data/corrections-gt500.jsonl \
  --model-dir docs/research/routellm-phase3/model-mdeberta
```

- The corrections schema remains the existing `retrain_cli.py` contract.
- Validate the new model on GT hold-out before rollout.
- If routing accuracy regresses or ECE rises above gate, rollback to the previous model backup.

## 7. Troubleshooting

- Duplicate ids: rerun sampling with the correct `--exclude` file. Do not hand-edit ids after distribution.
- Duplicate prompts: investigate dedup keys (`session_id` + prompt prefix) before issuing a new batch.
- Annotator disagreement: escalate only the disputed subset for reviewer adjudication and preserve original labels.
- Low agreement: re-check taxonomy interpretation, packet version, and whether annotators used external tools.
- Calibration report missing diagram: matplotlib is optional; ASCII fallback is acceptable.
- Localhost classification failure: verify the service is bound to `127.0.0.1`/`localhost` only.
