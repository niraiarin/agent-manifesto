#!/usr/bin/env bash
# 失敗した M-interp 14件のみをパッチ済み ccr で再実行
set -u
cd /Users/nirarin/work/agent-manifesto-research-594/docs/research/golden-dataset

FAILED_IDS=(4 7 9 10 12 15 17 18 19 20 22 24 27 30)

echo "=== M-interp FAIL 再バッチ開始: $(date) ==="
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

echo "=== 再バッチ完了: $(date) ==="
echo "成功: $success/${#FAILED_IDS[@]}"
