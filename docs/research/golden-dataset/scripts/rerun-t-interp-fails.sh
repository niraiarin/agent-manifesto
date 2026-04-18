#!/usr/bin/env bash
# Re-run FAILED T-interp items (005-011) with qwen3.6-35b-a3b-bf16
set -u
cd /Users/nirarin/work/agent-manifesto-research-594/docs/research/golden-dataset

FAIL_IDS=(005 006 007 008 009 010 011)

echo "=== T-interp FAIL 再実行開始: $(date) ==="
echo "  Model: qwen3.6-35b-a3b-bf16"
echo "  Target: ${#FAIL_IDS[@]} items"
echo ""

count=0
ok=0
fail=0
for id in "${FAIL_IDS[@]}"; do
  count=$((count + 1))
  input_file="inputs/trace-input-${id}.json"
  echo "--- [$count/${#FAIL_IDS[@]}] T-interp-${id} ($(date +%H:%M:%S)) ---"

  bash scripts/run-comparison.sh \
    --input "$input_file" \
    --task T-interp \
    --local-model qwen3.6-35b-a3b-bf16 \
    --local-only >/dev/null 2>&1

  out="outputs/local/T-interp-${id}.json"
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
echo "=== T-interp FAIL 再実行完了: $(date) ==="
echo "OK=$ok  FAIL=$fail  Total=${#FAIL_IDS[@]}"
