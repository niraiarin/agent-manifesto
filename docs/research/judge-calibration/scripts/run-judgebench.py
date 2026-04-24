#!/usr/bin/env python3
"""Run Claude-as-judge on JudgeBench pairs and compute accuracy.

Claude is invoked via `claude -p` subprocess (matching our production judge).
Each pair gets a pairwise judgment; we compare to JudgeBench's objective label.
"""
import argparse
import json
import os
import subprocess
import sys
import time
from pathlib import Path
from datasets import load_dataset


JUDGE_PROMPT_TEMPLATE = """You are an independent quality judge. Given a question and two candidate responses (A and B), determine which response is more correct / better.

Question:
{question}

---

Response A:
{response_a}

---

Response B:
{response_b}

---

Evaluate both responses on correctness, reasoning quality, and completeness.

Output ONLY one of these tokens (no explanation):
- A (if Response A is clearly better)
- B (if Response B is clearly better)
- TIE (if they are roughly equivalent)
"""


def judge(question: str, response_a: str, response_b: str, timeout: int = 90) -> dict:
    """Call Claude via `claude -p` and parse the judgment."""
    prompt = JUDGE_PROMPT_TEMPLATE.format(
        question=question,
        response_a=response_a,
        response_b=response_b,
    )

    start = time.time()
    try:
        result = subprocess.run(
            ['claude', '-p', '--output-format', 'json'],
            input=prompt,
            capture_output=True,
            text=True,
            timeout=timeout,
        )
    except subprocess.TimeoutExpired:
        return {
            'verdict': 'TIMEOUT',
            'raw': '',
            'latency_ms': int((time.time() - start) * 1000),
            'error': 'timeout',
        }

    latency_ms = int((time.time() - start) * 1000)

    if result.returncode != 0:
        return {
            'verdict': 'ERROR',
            'raw': result.stderr[:500],
            'latency_ms': latency_ms,
            'error': f'exit={result.returncode}',
        }

    try:
        parsed = json.loads(result.stdout)
        raw_text = parsed.get('result', '').strip()
    except json.JSONDecodeError:
        return {
            'verdict': 'PARSE_ERROR',
            'raw': result.stdout[:500],
            'latency_ms': latency_ms,
            'error': 'json decode failed',
        }

    # Heuristic parse: look for 'A', 'B', 'TIE' in first tokens
    upper = raw_text.strip().upper()
    verdict = 'UNKNOWN'
    if upper.startswith('A') and not upper.startswith('A>B'):  # rare: echoing label
        verdict = 'A'
    elif upper.startswith('B') and not upper.startswith('B>A'):
        verdict = 'B'
    elif 'TIE' in upper[:10]:
        verdict = 'TIE'
    elif '\nA' in f'\n{upper}' or ' A ' in f' {upper} ':
        # last-resort: find standalone A/B token
        tokens = upper.replace(':', ' ').replace('.', ' ').replace(',', ' ').split()
        for tok in tokens:
            if tok == 'A':
                verdict = 'A'
                break
            if tok == 'B':
                verdict = 'B'
                break

    return {
        'verdict': verdict,
        'raw': raw_text[:200],
        'latency_ms': latency_ms,
    }


def normalize_label(label: str) -> str:
    """Convert JudgeBench label (A>B / B>A) to our verdict space."""
    if label == 'A>B':
        return 'A'
    if label == 'B>A':
        return 'B'
    return 'UNKNOWN'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--split', choices=['gpt', 'claude', 'both'], default='both')
    parser.add_argument('--output', required=True)
    parser.add_argument('--limit', type=int, default=0, help='0 = all pairs')
    parser.add_argument('--resume', action='store_true', help='skip already judged pair_ids')
    args = parser.parse_args()

    splits = [args.split] if args.split != 'both' else ['gpt', 'claude']

    # Resume: load existing results
    done = set()
    existing = []
    if args.resume and os.path.isfile(args.output):
        with open(args.output) as f:
            for line in f:
                try:
                    rec = json.loads(line)
                    done.add(rec['pair_id'])
                    existing.append(rec)
                except Exception:
                    pass
        print(f'Resume: {len(done)} pairs already done', file=sys.stderr)

    rows = []
    for split in splits:
        ds = load_dataset('ScalerLab/JudgeBench', split=split)
        for row in ds:
            rows.append({**row, '_split': split})

    if args.limit > 0:
        rows = rows[:args.limit]

    pending = [r for r in rows if r['pair_id'] not in done]
    print(f'Total: {len(rows)}, pending: {len(pending)}', file=sys.stderr)

    out_mode = 'a' if args.resume else 'w'
    with open(args.output, out_mode) as out:
        for i, row in enumerate(pending, 1):
            sys.stderr.write(f'[{i}/{len(pending)}] pair_id={row["pair_id"][:16]}...  ')
            sys.stderr.flush()

            result = judge(row['question'], row['response_A'], row['response_B'])
            gt = normalize_label(row['label'])
            correct = (result['verdict'] == gt)

            record = {
                'pair_id': row['pair_id'],
                'split': row['_split'],
                'source': row['source'],
                'response_model': row['response_model'],
                'ground_truth': row['label'],
                'gt_normalized': gt,
                'judge_verdict': result['verdict'],
                'correct': correct,
                'latency_ms': result['latency_ms'],
                'raw': result.get('raw', ''),
                'error': result.get('error'),
            }

            out.write(json.dumps(record, ensure_ascii=False) + '\n')
            out.flush()
            sys.stderr.write(f'verdict={result["verdict"]:<8} gt={gt}  {"✓" if correct else "✗"}  {result["latency_ms"]}ms\n')


if __name__ == '__main__':
    main()
