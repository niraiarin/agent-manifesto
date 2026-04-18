#!/usr/bin/env bash
# Evaluate remaining 9 M-interp items
set -u
cd /Users/nirarin/work/agent-manifesto-research-594/docs/research/golden-dataset

IDS=(007 009 010 015 019 020 022 024 027)

echo "=== 追加評価開始: $(date) ==="
echo "Target: ${#IDS[@]} items"
echo ""

for id in "${IDS[@]}"; do
  run_id="M-interp-${id}"
  echo "--- $run_id ($(date +%H:%M:%S)) ---"
  if bash scripts/evaluate.sh --run-id "$run_id" --judge-model claude > /dev/null 2>&1; then
    eval_file="evaluations/${run_id}.json"
    delta=$(python3 -c "import json; d=json.load(open('$eval_file')); print(d.get('delta','?'))" 2>/dev/null)
    echo "  delta=$delta"
  else
    echo "  FAILED"
  fi
done
echo ""
echo "=== 追加評価完了: $(date) ==="
