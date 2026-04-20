#!/usr/bin/env python3
"""
RouteLLM preference data converter.

Converts Cloud vs Local judge evaluation results into RouteLLM-compatible
preference data (Chatbot Arena battle format).

Output schema (jsonl, one record per line):
{
  "id": "M-interp-001",
  "task_type": "M-interp",
  "input_file": "metrics-input-001.json",
  "prompt": "...",
  "model_a": "claude-opus-4-6",
  "response_a": "...",
  "model_b": "qwen3.6-35b-a3b-bf16",
  "response_b": "...",
  "judge_scores": {"cloud": {...}, "local": {...}},
  "delta": 0.2,           # cloud - local (positive = cloud better)
  "winner": "model_a" | "model_b" | "tie"
}

Winner label mapping (based on research note thresholds):
- delta > 0.5  → model_a (cloud) wins
- delta < -0.5 → model_b (local) wins
- |delta| ≤ 0.5 → tie

Usage:
  python3 convert-to-routellm.py \\
    --dataset-dir /path/to/golden-dataset \\
    --output routellm-preference-data.jsonl
"""
import argparse
import json
import os
import glob
import sys
from pathlib import Path


def load_evaluation(eval_file):
    return json.load(open(eval_file))


def load_output(path):
    if not os.path.isfile(path):
        return None
    return json.load(open(path))


def load_input_prompt(dataset_dir, run_id):
    """Reconstruct the input prompt from the raw input file."""
    # run_id: M-interp-001 → inputs/metrics-input-001.json
    # run_id: T-interp-001 → inputs/trace-input-001.json
    parts = run_id.split('-')
    task = '-'.join(parts[:2])  # M-interp or T-interp
    idx = parts[-1]

    if task == 'M-interp':
        input_path = Path(dataset_dir) / 'inputs' / f'metrics-input-{idx}.json'
    elif task == 'T-interp':
        input_path = Path(dataset_dir) / 'inputs' / f'trace-input-{idx}.json'
    else:
        return None

    if not input_path.exists():
        return None

    input_data = json.load(open(input_path))
    return input_data.get('data', input_data)


def delta_to_winner(delta, threshold=0.5):
    """Map delta (cloud - local) to winner label."""
    if delta is None:
        return 'unknown'
    if delta > threshold:
        return 'model_a'   # cloud wins
    if delta < -threshold:
        return 'model_b'   # local wins
    return 'tie'


def build_record(run_id, dataset_dir, cloud_model, local_model, threshold):
    eval_path = Path(dataset_dir) / 'evaluations' / f'{run_id}.json'
    cloud_path = Path(dataset_dir) / 'outputs' / 'cloud' / f'{run_id}.json'
    local_path = Path(dataset_dir) / 'outputs' / 'local' / f'{run_id}.json'

    if not eval_path.exists():
        return None

    evaluation = load_evaluation(eval_path)
    cloud = load_output(cloud_path)
    local = load_output(local_path)

    if cloud is None or local is None:
        return None

    delta = evaluation.get('delta')
    task_type = evaluation.get('task_type', run_id.rsplit('-', 1)[0])
    input_file = evaluation.get('cloud_file', '')
    input_file = os.path.basename(input_file) if input_file else ''

    input_data = load_input_prompt(dataset_dir, run_id)

    record = {
        'id': run_id,
        'task_type': task_type,
        'input_file': cloud.get('input_file', input_file),
        'input_data': input_data,
        'model_a': cloud_model,
        'response_a': cloud.get('output', ''),
        'model_b': local_model,
        'response_b': local.get('output', ''),
        'judge_scores': evaluation.get('judge_scoring', {}),
        'mechanical_agreement': evaluation.get('mechanical_agreement', {}),
        'delta': delta,
        'winner': delta_to_winner(delta, threshold),
        'threshold': threshold,
    }
    return record


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--dataset-dir', required=True)
    parser.add_argument('--output', required=True)
    parser.add_argument('--cloud-model', default='claude-opus-4-6')
    parser.add_argument('--local-model', default='qwen3.6-35b-a3b-bf16')
    parser.add_argument('--threshold', type=float, default=0.5,
                        help='delta threshold for winner label (default 0.5)')
    args = parser.parse_args()

    dataset_dir = Path(args.dataset_dir).resolve()
    eval_dir = dataset_dir / 'evaluations'
    eval_files = sorted(eval_dir.glob('*.json'))

    records = []
    skipped = []
    for f in eval_files:
        run_id = f.stem
        record = build_record(run_id, dataset_dir, args.cloud_model,
                              args.local_model, args.threshold)
        if record is None:
            skipped.append(run_id)
            continue
        records.append(record)

    with open(args.output, 'w') as out:
        for rec in records:
            out.write(json.dumps(rec, ensure_ascii=False) + '\n')

    # Summary
    winners = {'model_a': 0, 'model_b': 0, 'tie': 0, 'unknown': 0}
    by_task = {}
    for r in records:
        winners[r['winner']] = winners.get(r['winner'], 0) + 1
        t = r['task_type']
        by_task.setdefault(t, {'model_a': 0, 'model_b': 0, 'tie': 0, 'unknown': 0})
        by_task[t][r['winner']] += 1

    print(f'Total records: {len(records)}  (skipped: {len(skipped)})', file=sys.stderr)
    print(f'Output: {args.output}', file=sys.stderr)
    print(f'', file=sys.stderr)
    print(f'Winner distribution (threshold={args.threshold}):', file=sys.stderr)
    for k, v in winners.items():
        pct = 100.0 * v / len(records) if records else 0
        print(f'  {k}: {v} ({pct:.1f}%)', file=sys.stderr)
    print(f'', file=sys.stderr)
    print(f'By task type:', file=sys.stderr)
    for t, w in by_task.items():
        total = sum(w.values())
        tie_pct = 100.0 * w['tie'] / total if total else 0
        print(f'  {t}: n={total}  model_a (cloud)={w["model_a"]}  model_b (local)={w["model_b"]}  tie={w["tie"]} ({tie_pct:.0f}%)', file=sys.stderr)
    if skipped:
        print(f'', file=sys.stderr)
        print(f'Skipped (no eval or missing outputs):', file=sys.stderr)
        for s in skipped:
            print(f'  {s}', file=sys.stderr)


if __name__ == '__main__':
    main()
