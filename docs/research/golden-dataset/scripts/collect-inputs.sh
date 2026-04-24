#!/usr/bin/env bash
# collect-inputs.sh — ゴールデンデータセットの入力スナップショットを収集
# Usage: bash collect-inputs.sh [--id NNN] [--type metrics|trace|all]
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATASET_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
INPUTS_DIR="$DATASET_DIR/inputs"
BASE="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# デフォルト値
ID=""
TYPE="all"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --id) ID="$2"; shift 2 ;;
    --type) TYPE="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# ID が未指定なら自動採番
if [ -z "$ID" ]; then
  EXISTING=$(ls "$INPUTS_DIR"/*.json 2>/dev/null | wc -l | tr -d ' ')
  ID=$(printf "%03d" $((EXISTING / 2 + 1)))
fi

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
GIT_REV=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

collect_metrics() {
  local outfile="$INPUTS_DIR/metrics-input-${ID}.json"
  echo "Collecting metrics input → $outfile"

  local raw
  raw=$(bash "$BASE/.claude/skills/evolve/scripts/observe.sh" 2>/dev/null)
  if [ $? -ne 0 ] || [ -z "$raw" ]; then
    echo "ERROR: observe.sh failed" >&2
    return 1
  fi

  # メタデータを付加
  echo "$raw" | python3 -c "
import sys, json
data = json.load(sys.stdin)
wrapper = {
    'meta': {
        'id': 'metrics-input-${ID}',
        'type': 'metrics',
        'timestamp': '${TIMESTAMP}',
        'git_rev': '${GIT_REV}',
        'source': 'observe.sh'
    },
    'data': data
}
json.dump(wrapper, sys.stdout, indent=2)
" > "$outfile"

  echo "  OK: $(wc -c < "$outfile" | tr -d ' ') bytes"
}

collect_trace() {
  local outfile="$INPUTS_DIR/trace-input-${ID}.json"
  echo "Collecting trace input → $outfile"

  local raw
  raw=$(bash "$BASE/manifest-trace" json 2>/dev/null)
  if [ $? -ne 0 ] || [ -z "$raw" ]; then
    echo "ERROR: manifest-trace json failed" >&2
    return 1
  fi

  echo "$raw" | python3 -c "
import sys, json
data = json.load(sys.stdin)
wrapper = {
    'meta': {
        'id': 'trace-input-${ID}',
        'type': 'trace',
        'timestamp': '${TIMESTAMP}',
        'git_rev': '${GIT_REV}',
        'source': 'manifest-trace json'
    },
    'data': data
}
json.dump(wrapper, sys.stdout, indent=2)
" > "$outfile"

  echo "  OK: $(wc -c < "$outfile" | tr -d ' ') bytes"
}

case "$TYPE" in
  metrics) collect_metrics ;;
  trace) collect_trace ;;
  all) collect_metrics; collect_trace ;;
  *) echo "Unknown type: $TYPE"; exit 1 ;;
esac

echo ""
echo "Inputs collected with ID=$ID at git rev $GIT_REV"
echo "Files in $INPUTS_DIR:"
ls -la "$INPUTS_DIR"/*.json 2>/dev/null
