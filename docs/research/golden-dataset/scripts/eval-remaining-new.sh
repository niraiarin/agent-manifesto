#!/usr/bin/env bash
# Re-evaluate remaining 10 items newly run with BF16
set -u
cd /Users/nirarin/work/agent-manifesto-research-594/docs/research/golden-dataset

M_IDS=(019 022)
T_IDS=(019 020 021 022 023 024 025 026)

echo "=== 残件評価開始: $(date) ==="
for id in "${M_IDS[@]}"; do
  run_id="M-interp-${id}"
  echo "--- $run_id ---"
  bash scripts/evaluate.sh --run-id "$run_id" --judge-model claude > /dev/null 2>&1
  delta=$(python3 -c "import json; d=json.load(open('evaluations/${run_id}.json')); print(d.get('delta','?'))" 2>/dev/null)
  echo "  delta=$delta"
done
for id in "${T_IDS[@]}"; do
  run_id="T-interp-${id}"
  echo "--- $run_id ---"
  bash scripts/evaluate.sh --run-id "$run_id" --judge-model claude > /dev/null 2>&1
  delta=$(python3 -c "import json; d=json.load(open('evaluations/${run_id}.json')); print(d.get('delta','?'))" 2>/dev/null)
  echo "  delta=$delta"
done
echo "=== 完了: $(date) ==="
