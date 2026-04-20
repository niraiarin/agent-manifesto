#!/usr/bin/env bash
# Re-run remaining 7 FAIL items (M-interp-009 already saved manually)
set -u
cd /Users/nirarin/work/agent-manifesto-research-594/docs/research/golden-dataset

FAILED_IDS=(10 12 17 18 19 27 30)

echo "=== M-interp FAIL 再バッチ v2 開始: $(date) ==="
echo "対象: ${#FAILED_IDS[@]} 件"
echo ""

count=0
success=0
for id in "${FAILED_IDS[@]}"; do
  count=$((count + 1))
  pad=$(printf "%03d" "$id")
  input_file="inputs/metrics-input-${pad}.json"
  echo "--- [$count/${#FAILED_IDS[@]}] M-interp-${pad} ($(date +%H:%M:%S)) ---"

  if bash scripts/run-comparison.sh \
      --input "$input_file" \
      --task M-interp \
      --local-model qwen3.6-35b-a3b \
      --local-only; then
    out="outputs/local/M-interp-${pad}.json"
    size=$(stat -f%z "$out" 2>/dev/null || echo 0)
    if [ "$size" -gt 300 ]; then
      success=$((success + 1))
      echo "  OK size=$size"
    else
      echo "  FAIL size=$size"
    fi
  else
    echo "  script failed"
  fi
  echo ""
done

echo "=== 再バッチ v2 完了: $(date) ==="
echo "成功: $success/${#FAILED_IDS[@]}"
