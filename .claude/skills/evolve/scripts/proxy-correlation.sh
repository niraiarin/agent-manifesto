#!/usr/bin/env bash
# proxy-correlation.sh — R3: proxy-vs-outcome rolling correlation
# Computes Pearson correlation between optimization proxies and structural outcomes.
# Uses Python for statistical computation (requires python3).
# Usage: bash .claude/skills/evolve/scripts/proxy-correlation.sh

set -uo pipefail

BASE="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
HISTORY_FILE="$BASE/.claude/metrics/evolve-history.jsonl"

if [ ! -f "$HISTORY_FILE" ]; then
  echo '{"error": "evolve-history.jsonl not found"}'
  exit 1
fi

# Extract data from evolve-history.jsonl
DATA=$(jq -s '
  [.[] | select(.result != "observation" and .lean.theorems != null and .phases.verifier != null)] |
  [range(1; length) as $i | {
    run: .[($i)].run,
    theorem_delta: (.[($i)].lean.theorems - .[($i)-1].lean.theorems),
    test_delta: (.[($i)].tests.passed - .[($i)-1].tests.passed),
    verifier_rate: (if (.[($i)].phases.verifier.pass_count + .[($i)].phases.verifier.fail_count) > 0 then (.[($i)].phases.verifier.pass_count * 100 / (.[($i)].phases.verifier.pass_count + .[($i)].phases.verifier.fail_count)) else 0 end),
    improvements: (.[($i)].improvements | length),
    rejected: (.[($i)].rejected | length)
  }]
' "$HISTORY_FILE" 2>/dev/null)

echo "$DATA" | python3 -c "
import json, statistics, sys

data = json.loads(sys.stdin.read())
n = len(data)

def pearson(xs, ys):
    if len(xs) < 3: return None
    mx, my = statistics.mean(xs), statistics.mean(ys)
    sx = sum((x - mx)**2 for x in xs)**0.5
    sy = sum((y - my)**2 for y in ys)**0.5
    if sx == 0 or sy == 0: return None
    return round(sum((x - mx)*(y - my) for x, y in zip(xs, ys)) / (sx * sy), 3)

def rolling(xs, ys, w=10):
    return [pearson(xs[i-w:i], ys[i-w:i]) for i in range(w, len(xs)+1)]

def trend(rc):
    valid = [r for r in rc if r is not None]
    if len(valid) < 4: return 'insufficient_data'
    h = len(valid) // 2
    d = statistics.mean(valid[h:]) - statistics.mean(valid[:h])
    if d < -0.1: return 'weakening'
    if d > 0.1: return 'strengthening'
    return 'stable'

theorem_d = [d['theorem_delta'] for d in data]
test_d = [d['test_delta'] for d in data]
verifier = [d['verifier_rate'] for d in data]
improvements = [d['improvements'] for d in data]

pairs = {
    'improvements_vs_theorem_delta': (improvements, theorem_d),
    'improvements_vs_test_delta': (improvements, test_d),
    'verifier_rate_vs_theorem_delta': (verifier, theorem_d),
    'verifier_rate_vs_test_delta': (verifier, test_d),
}

result = {'data_points': n, 'window_size': 10, 'correlations': {}, 'goodhart_detection': {}}
for name, (x, y) in pairs.items():
    r = pearson(x, y)
    rc = rolling(x, y, 10)
    recent = [v for v in rc[-3:] if v is not None]
    result['correlations'][name] = {
        'overall': r,
        'recent_3_windows': recent,
        'trend': trend(rc)
    }
    if trend(rc) == 'weakening':
        result['goodhart_detection'][name] = 'WARNING: correlation weakening — possible Goodhart pressure'

json.dump(result, sys.stdout, indent=2)
print()
"
