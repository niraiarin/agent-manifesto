#!/usr/bin/env bash
# Evaluate 17 newly-OK BF16 items
set -u
cd /Users/nirarin/work/agent-manifesto-research-594/docs/research/golden-dataset

IDS=(003 006 008 011 012 013 014 016 017 018 021 023 025 026 028 029 030)

echo "=== BF16 評価開始: $(date) ==="
echo "Target: ${#IDS[@]} items"
echo ""

count=0
success=0
for id in "${IDS[@]}"; do
  count=$((count + 1))
  run_id="M-interp-${id}"
  echo "--- [$count/${#IDS[@]}] $run_id ($(date +%H:%M:%S)) ---"

  if bash scripts/evaluate.sh --run-id "$run_id" --judge-model claude > /dev/null 2>&1; then
    eval_file="evaluations/${run_id}.json"
    if [ -f "$eval_file" ]; then
      delta=$(python3 -c "import json; d=json.load(open('$eval_file')); print(d.get('delta','?'))" 2>/dev/null)
      echo "  delta=$delta"
      success=$((success + 1))
    fi
  else
    echo "  FAILED"
  fi
done

echo ""
echo "=== BF16 評価完了: $(date) ==="
echo "$success/${#IDS[@]} evaluated"
