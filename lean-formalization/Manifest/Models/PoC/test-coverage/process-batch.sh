#!/usr/bin/env bash
# process-batch.sh — バッチ結果の JSON 配列を個別に分解し、パイプラインを実行
set -euo pipefail

BATCH_FILE="$1"
OUT_DIR="${2:-results}"

# スクリプトのディレクトリから Models/ を見つける
THIS_DIR="$(cd "$(dirname "$0")" && pwd)"
MODELS_DIR="$(cd "$THIS_DIR/../.." && pwd)"

mkdir -p "$OUT_DIR"

NUM=$(jq '. | length' "$BATCH_FILE")
PASS=0; FAIL=0; VIOLATIONS=0; TOTAL_MS=0

for i in $(seq 0 $((NUM - 1))); do
  sid=$(jq -r ".[$i].scenario_id" "$BATCH_FILE")
  project=$(jq -r ".[$i].project" "$BATCH_FILE")
  num_layers=$(jq ".[$i].num_layers" "$BATCH_FILE")
  num_props=$(jq ".[$i].num_props" "$BATCH_FILE")
  num_deps=$(jq ".[$i].num_deps" "$BATCH_FILE")

  spec_file="$OUT_DIR/s${sid}.json"
  jq ".[$i].model_spec" "$BATCH_FILE" > "$spec_file"

  if bash "$MODELS_DIR/check-monotonicity.sh" -f "$spec_file" > /dev/null 2>&1; then
    mono_ok=true
  else
    mono_ok=false
    VIOLATIONS=$((VIOLATIONS + 1))
  fi

  if $mono_ok; then
    lean_file="$OUT_DIR/S${sid}.lean"
    start_ns=$(python3 -c 'import time; print(int(time.time()*1e9))')

    if bash "$MODELS_DIR/generate-conditional-axiom-system.sh" -f "$spec_file" -o "$lean_file" --no-verify > /dev/null 2>&1; then
      LEAN_ROOT="$(cd "$MODELS_DIR/../.." && pwd)"
      ABS_OUT="$(cd "$(dirname "$lean_file")" && pwd)/$(basename "$lean_file")"
      REL="${ABS_OUT#${LEAN_ROOT}/}"
      MOD=$(echo "$REL" | sed 's|/|.|g; s|\.lean$||')
      export PATH="$HOME/.elan/bin:$PATH"

      if (cd "$LEAN_ROOT" && lake build "$MOD" > /dev/null 2>&1); then
        end_ns=$(python3 -c 'import time; print(int(time.time()*1e9))')
        ms=$(( (end_ns - start_ns) / 1000000 ))
        TOTAL_MS=$((TOTAL_MS + ms))
        PASS=$((PASS + 1))
        echo "✓ S${sid} ${project} | L=${num_layers} P=${num_props} D=${num_deps} | ${ms}ms"
      else
        FAIL=$((FAIL + 1))
        echo "✗ S${sid} ${project} | L=${num_layers} P=${num_props} D=${num_deps} | BUILD FAIL"
      fi
    else
      FAIL=$((FAIL + 1))
      echo "✗ S${sid} ${project} | L=${num_layers} P=${num_props} D=${num_deps} | GEN FAIL"
    fi
  else
    echo "⚠ S${sid} ${project} | L=${num_layers} P=${num_props} D=${num_deps} | MONOTONE VIOLATION"
  fi
done

echo ""
echo "--- Batch Summary ---"
echo "PASS: $PASS  FAIL: $FAIL  VIOLATIONS: $VIOLATIONS"
if [ $PASS -gt 0 ]; then
  echo "Avg build: $((TOTAL_MS / PASS))ms"
fi
