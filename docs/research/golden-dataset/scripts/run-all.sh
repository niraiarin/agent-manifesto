#!/usr/bin/env bash
# run-all.sh — 全入力データに対して比較実験を一括実行
#
# Usage:
#   bash run-all.sh [--task M-interp|T-interp|all] [--local-model <model>] [--runs N]
#   bash run-all.sh --task M-interp --local-model gemma4:e4b-128k
#   bash run-all.sh --task all --runs 3
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATASET_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

TASK_TYPE="all"
LOCAL_MODEL="gemma4:e4b-128k"
RUNS=1
EXTRA_ARGS=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --task) TASK_TYPE="$2"; shift 2 ;;
    --local-model) LOCAL_MODEL="$2"; shift 2 ;;
    --runs) RUNS="$2"; shift 2 ;;
    --cloud-only) EXTRA_ARGS="$EXTRA_ARGS --cloud-only"; shift ;;
    --local-only) EXTRA_ARGS="$EXTRA_ARGS --local-only"; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# タスクタイプと入力ファイルのマッピング
run_task() {
  local task="$1"
  local prefix="$2"  # metrics or trace

  local count=0
  local success=0
  local failed=0

  for input_file in "$DATASET_DIR/inputs/${prefix}-input-"*.json; do
    [ -f "$input_file" ] || continue
    count=$((count + 1))
    echo ""
    echo "========================================"
    echo "  [$count] $task: $(basename "$input_file")"
    echo "========================================"

    if bash "$SCRIPT_DIR/run-comparison.sh" \
      --input "$input_file" \
      --task "$task" \
      --local-model "$LOCAL_MODEL" \
      --runs "$RUNS" \
      $EXTRA_ARGS; then
      success=$((success + 1))
    else
      failed=$((failed + 1))
      echo "  WARNING: Failed for $(basename "$input_file")"
    fi
  done

  echo ""
  echo "--- $task: $success/$count succeeded, $failed failed ---"
}

echo "=== Batch Comparison Run ==="
echo "  Task: $TASK_TYPE"
echo "  Local model: $LOCAL_MODEL"
echo "  Runs per input: $RUNS"
echo "  Extra args: $EXTRA_ARGS"
echo ""

START_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

case "$TASK_TYPE" in
  M-interp) run_task "M-interp" "metrics" ;;
  T-interp) run_task "T-interp" "trace" ;;
  all)
    run_task "M-interp" "metrics"
    run_task "T-interp" "trace"
    ;;
  *) echo "Unknown task type: $TASK_TYPE"; exit 1 ;;
esac

END_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo ""
echo "=== Batch Run Complete ==="
echo "  Started: $START_TIME"
echo "  Ended:   $END_TIME"
echo ""
echo "Outputs:"
echo "  Cloud: $(ls "$DATASET_DIR/outputs/cloud/"*.json 2>/dev/null | wc -l | tr -d ' ') files"
echo "  Local: $(ls "$DATASET_DIR/outputs/local/"*.json 2>/dev/null | wc -l | tr -d ' ') files"
echo ""
echo "Next: bash evaluate.sh --run-id <id> to evaluate each pair"
