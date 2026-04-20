#!/usr/bin/env bash
# Re-run all 26 T-interp items with qwen3.6-35b-a3b-bf16
set -u
cd /Users/nirarin/work/agent-manifesto-research-594/docs/research/golden-dataset

echo "=== T-interp BF16 再実行開始: $(date) ==="
echo "  Model: qwen3.6-35b-a3b-bf16"
echo ""

count=0
ok=0
fail=0
for input_file in inputs/trace-input-*.json; do
  [ -f "$input_file" ] || continue
  count=$((count + 1))
  id=$(basename "$input_file" .json | sed 's/trace-input-//')
  echo "--- [$count] T-interp-${id} ($(date +%H:%M:%S)) ---"

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
echo "=== T-interp BF16 再実行完了: $(date) ==="
echo "OK=$ok  FAIL=$fail  Total=$count"
