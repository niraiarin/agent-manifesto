#!/usr/bin/env bash
# evaluate-all.sh — 全ペアを一括評価
#
# Usage:
#   bash evaluate-all.sh [--task M-interp|T-interp|all] [--judge-model claude|ollama]
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATASET_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

TASK_TYPE="all"
JUDGE_MODEL="claude"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --task) TASK_TYPE="$2"; shift 2 ;;
    --judge-model) JUDGE_MODEL="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

evaluate_task() {
  local task="$1"
  local prefix="$2"
  local count=0
  local success=0

  for cloud_file in "$DATASET_DIR/outputs/cloud/${task}-"*.json; do
    [ -f "$cloud_file" ] || continue
    local run_id=$(basename "$cloud_file" .json)
    local local_file="$DATASET_DIR/outputs/local/${run_id}.json"

    if [ ! -f "$local_file" ]; then
      echo "  SKIP: $run_id (no local output)"
      continue
    fi

    # エラー出力をスキップ
    local has_error=$(python3 -c "import json; d=json.load(open('$local_file')); print('yes' if 'error' in d else 'no')" 2>/dev/null)
    if [ "$has_error" = "yes" ]; then
      echo "  SKIP: $run_id (local error)"
      continue
    fi

    count=$((count + 1))
    echo "  [$count] Evaluating $run_id..."
    if bash "$SCRIPT_DIR/evaluate.sh" --run-id "$run_id" --judge-model "$JUDGE_MODEL" > /dev/null 2>&1; then
      # サマリーだけ表示
      local eval_file="$DATASET_DIR/evaluations/${run_id}.json"
      if [ -f "$eval_file" ]; then
        python3 -c "
import json
d = json.load(open('$eval_file'))
delta = d.get('delta', '?')
mech = d.get('mechanical_agreement', {})
agree = mech.get('agreement_score', '?')
print(f'    delta={delta}, agreement={agree}')
"
      fi
      success=$((success + 1))
    else
      echo "    FAILED"
    fi
  done

  echo ""
  echo "--- $task: $success/$count evaluated ---"
}

echo "=== Batch Evaluation ==="
echo "  Judge: $JUDGE_MODEL"
echo ""

case "$TASK_TYPE" in
  M-interp) evaluate_task "M-interp" "metrics" ;;
  T-interp) evaluate_task "T-interp" "trace" ;;
  all)
    evaluate_task "M-interp" "metrics"
    evaluate_task "T-interp" "trace"
    ;;
esac

# 集計サマリー
echo ""
echo "=== Aggregate Summary ==="
python3 -c "
import json, os, glob

eval_dir = '$DATASET_DIR/evaluations'
files = sorted(glob.glob(os.path.join(eval_dir, '*.json')))

by_task = {}
for f in files:
    d = json.load(open(f))
    task = d.get('task_type', 'unknown')
    delta = d.get('delta')
    if delta is None:
        continue
    by_task.setdefault(task, []).append(delta)

for task, deltas in sorted(by_task.items()):
    n = len(deltas)
    avg = sum(deltas) / n
    mn = min(deltas)
    mx = max(deltas)
    passed = sum(1 for d in deltas if abs(d) <= 0.5)
    print(f'{task}: n={n}, avg_delta={avg:.2f}, min={mn}, max={mx}, pass_rate={passed}/{n} ({100*passed/n:.0f}%)')
"
