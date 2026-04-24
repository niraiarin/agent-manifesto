#!/usr/bin/env bash
# Re-run remaining FP16/outlier items with BF16 for clean dataset
set -u
cd /Users/nirarin/work/agent-manifesto-research-594/docs/research/golden-dataset

echo "=== 残件 BF16 統一バッチ: $(date) ==="

# M-interp outliers (019, 022)
echo ""
echo "--- M-interp outliers ---"
M_IDS=(019 022)
for id in "${M_IDS[@]}"; do
  input_file="inputs/metrics-input-${id}.json"
  echo "--- M-interp-${id} ($(date +%H:%M:%S)) ---"
  bash scripts/run-comparison.sh \
    --input "$input_file" --task M-interp \
    --local-model qwen3.6-35b-a3b-bf16 --local-only >/dev/null 2>&1
  out="outputs/local/M-interp-${id}.json"
  size=$(stat -f%z "$out" 2>/dev/null || echo 0)
  [ "$size" -gt 300 ] && echo "  OK size=$size" || echo "  FAIL size=$size"
done

# T-interp FP16 remainders (019-026)
echo ""
echo "--- T-interp FP16 remainders ---"
T_IDS=(019 020 021 022 023 024 025 026)
for id in "${T_IDS[@]}"; do
  input_file="inputs/trace-input-${id}.json"
  echo "--- T-interp-${id} ($(date +%H:%M:%S)) ---"
  bash scripts/run-comparison.sh \
    --input "$input_file" --task T-interp \
    --local-model qwen3.6-35b-a3b-bf16 --local-only >/dev/null 2>&1
  out="outputs/local/T-interp-${id}.json"
  size=$(stat -f%z "$out" 2>/dev/null || echo 0)
  [ "$size" -gt 300 ] && echo "  OK size=$size" || echo "  FAIL size=$size"
done

echo ""
echo "=== 完了: $(date) ==="
