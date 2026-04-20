#!/usr/bin/env bash
# Re-evaluate 7 newly-OK T-interp items (005-011) with Cloud judge
set -u
cd /Users/nirarin/work/agent-manifesto-research-594/docs/research/golden-dataset

IDS=(005 006 007 008 009 010 011)

echo "=== T-interp 追加評価開始: $(date) ==="
for id in "${IDS[@]}"; do
  run_id="T-interp-${id}"
  echo "--- $run_id ($(date +%H:%M:%S)) ---"
  if bash scripts/evaluate.sh --run-id "$run_id" --judge-model claude > /dev/null 2>&1; then
    eval_file="evaluations/${run_id}.json"
    delta=$(python3 -c "import json; d=json.load(open('$eval_file')); print(d.get('delta','?'))" 2>/dev/null)
    echo "  delta=$delta"
  else
    echo "  FAILED"
  fi
done
echo "=== T-interp 追加評価完了: $(date) ==="
