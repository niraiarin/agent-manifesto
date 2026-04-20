#!/usr/bin/env bash
# 全入力を llama-server (qwen3.6-35b-a3b-ud-q2) で再実行
# Q2_K_XL 量子化版の評価用
set -u
cd /Users/nirarin/work/agent-manifesto-research-594/docs/research/golden-dataset

echo "=== Q2 全再バッチ開始: $(date) ==="
echo "  Model: qwen3.6-35b-a3b-ud-q2 (Q2_K_XL)"
echo "  Target: M-interp 29 + T-interp 26 = 55 items"
echo ""

total=0
ok=0
fail=0

run_task() {
  local task="$1"
  local prefix="$2"

  for input_file in inputs/${prefix}-input-*.json; do
    [ -f "$input_file" ] || continue
    total=$((total + 1))
    id=$(basename "$input_file" .json | sed 's/^[^-]*-input-//')
    echo "--- [$total] ${task}-${id} ($(date +%H:%M:%S)) ---"

    bash scripts/run-comparison.sh \
      --input "$input_file" \
      --task "$task" \
      --local-model qwen3.6-35b-a3b-ud-q2 \
      --local-only >/dev/null 2>&1

    out="outputs/local/${task}-${id}.json"
    size=$(stat -f%z "$out" 2>/dev/null || echo 0)
    if [ "$size" -gt 300 ]; then
      ok=$((ok + 1))
      echo "  OK size=$size"
    else
      fail=$((fail + 1))
      echo "  FAIL size=$size"
    fi
  done
}

run_task "M-interp" "metrics"
echo ""
run_task "T-interp" "trace"

echo ""
echo "=== Q2 全再バッチ完了: $(date) ==="
echo "Total: $total  OK: $ok  FAIL: $fail"
