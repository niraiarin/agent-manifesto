#!/usr/bin/env bash
# Re-run FAILED M-interp items with qwen3.6-35b-a3b-bf16
set -u
cd /Users/nirarin/work/agent-manifesto-research-594/docs/research/golden-dataset

FAIL_IDS=(3 6 8 11 12 13 14 16 17 18 21 23 25 26 28 29 30)

echo "=== BF16 re-run 開始: $(date) ==="
echo "  Model: qwen3.6-35b-a3b-bf16"
echo "  Target: ${#FAIL_IDS[@]} items"
echo ""

count=0
ok=0
fail=0
for id in "${FAIL_IDS[@]}"; do
  count=$((count + 1))
  pad=$(printf "%03d" "$id")
  input_file="inputs/metrics-input-${pad}.json"
  echo "--- [$count/${#FAIL_IDS[@]}] M-interp-${pad} ($(date +%H:%M:%S)) ---"

  bash scripts/run-comparison.sh \
    --input "$input_file" \
    --task M-interp \
    --local-model qwen3.6-35b-a3b-bf16 \
    --local-only >/dev/null 2>&1

  out="outputs/local/M-interp-${pad}.json"
  size=$(stat -f%z "$out" 2>/dev/null || echo 0)
  if [ "$size" -gt 300 ]; then
    ok=$((ok + 1))
    echo "  OK size=$size"
  else
    fail=$((fail + 1))
    echo "  FAIL size=$size"
  fi
done

echo ""
echo "=== BF16 re-run 完了: $(date) ==="
echo "OK=$ok  FAIL=$fail  Total=${#FAIL_IDS[@]}"
