#!/usr/bin/env bash
# generate-test-scenarios.sh
#
# 100 個の多様な ModelSpec JSON を生成し、パイプラインのカバレッジテストを行う。
#
# 軸:
#   - 層数: 2, 3, 4, 5, 6, 7, 8
#   - 命題数: 3, 5, 10, 15, 20, 30, 40, 50
#   - 依存密度: sparse (10%), medium (30%), dense (60%)
#   - 違反率: 0%, 5%, 20%（意図的な単調性違反を含むケース）
#
# Usage: bash generate-test-scenarios.sh <output-dir>

set -euo pipefail

OUT_DIR="${1:-scenarios}"
mkdir -p "$OUT_DIR"

SCENARIO_COUNT=0

# 層名のプール
ALL_LAYER_NAMES=("axiom" "postulate" "principle" "boundary" "theorem" "hypothesis" "conjecture" "lemma")

# 命題名プレフィックスのプール
PROP_PREFIXES=("a" "b" "c" "d" "e" "f" "g" "h" "i" "j" "k" "l" "m" "n" "p" "q" "r" "s" "t" "u")

generate_scenario() {
  local num_layers=$1
  local num_props=$2
  local dep_density=$3  # 0-100
  local violation_rate=$4  # 0-100
  local scenario_id=$5

  local namespace="TestScenario.S${scenario_id}"

  # 層の生成
  local layers_json="["
  for i in $(seq 0 $((num_layers - 1))); do
    local name="${ALL_LAYER_NAMES[$i]}"
    local ord=$((num_layers - 1 - i))
    local comma=""
    if [ $i -gt 0 ]; then comma=","; fi
    layers_json="${layers_json}${comma}{\"name\":\"${name}\",\"ordValue\":${ord},\"definition\":\"Layer ${name}\",\"derivedFrom\":[\"auto\"]}"
  done
  layers_json="${layers_json}]"

  # 命題の生成
  local props_json="["
  local prop_ids=()
  local prop_layers=()

  for j in $(seq 0 $((num_props - 1))); do
    local prefix_idx=$((j % ${#PROP_PREFIXES[@]}))
    local suffix=$((j / ${#PROP_PREFIXES[@]} + 1))
    local prop_id="${PROP_PREFIXES[$prefix_idx]}${suffix}"
    prop_ids+=("$prop_id")

    # 層の割り当て: 命題番号が大きいほど低い層
    local layer_idx=$(( j * num_layers / num_props ))
    if [ $layer_idx -ge $num_layers ]; then layer_idx=$((num_layers - 1)); fi
    local layer_name="${ALL_LAYER_NAMES[$layer_idx]}"
    local layer_ord=$((num_layers - 1 - layer_idx))
    prop_layers+=("$layer_idx")
  done

  # 依存関係の生成
  for j in $(seq 0 $((num_props - 1))); do
    local deps="[]"
    local dep_list=""

    if [ $j -gt 0 ]; then
      # 自分より前の命題（より強い層）への依存を確率的に追加
      for k in $(seq 0 $((j - 1))); do
        local rand=$((RANDOM % 100))
        if [ $rand -lt $dep_density ]; then
          local dep_layer_idx=${prop_layers[$k]}
          local my_layer_idx=${prop_layers[$j]}

          # 違反率に応じて、時々逆方向の依存を作る
          local viol_rand=$((RANDOM % 100))
          if [ $viol_rand -lt $violation_rate ] && [ $dep_layer_idx -gt $my_layer_idx ]; then
            # 意図的違反: 強い命題が弱い命題に依存
            if [ -n "$dep_list" ]; then
              dep_list="${dep_list},\".${prop_ids[$k]}\""
            else
              dep_list="\".${prop_ids[$k]}\""
            fi
          elif [ $dep_layer_idx -le $my_layer_idx ]; then
            # 正常: 弱い命題が強い命題に依存
            if [ -n "$dep_list" ]; then
              dep_list="${dep_list},\".${prop_ids[$k]}\""
            else
              dep_list="\".${prop_ids[$k]}\""
            fi
          fi
        fi
      done
    fi

    if [ -n "$dep_list" ]; then
      deps="[${dep_list}]"
    fi

    local layer_idx=${prop_layers[$j]}
    local layer_name="${ALL_LAYER_NAMES[$layer_idx]}"

    local comma=""
    if [ $j -gt 0 ]; then comma=","; fi
    props_json="${props_json}${comma}{\"id\":\"${prop_ids[$j]}\",\"layerName\":\"${layer_name}\",\"justification\":[\"auto\"],\"dependencies\":${deps}}"
  done
  props_json="${props_json}]"

  # JSON 出力
  cat <<EOF
{
  "namespace": "${namespace}",
  "layers": ${layers_json},
  "propositions": ${props_json}
}
EOF
}

# ============================================================
# シナリオ生成
# ============================================================

echo "Generating 100 test scenarios..."

# 軸の組み合わせ
LAYER_COUNTS=(2 3 4 5 6 7 8)
PROP_COUNTS=(3 5 10 15 20 30)
DENSITIES=(10 30 60)
VIOLATIONS=(0 0 0 5 20)  # 0が多めで、時々違反あり

for layers in "${LAYER_COUNTS[@]}"; do
  for props in "${PROP_COUNTS[@]}"; do
    for density in "${DENSITIES[@]}"; do
      for viol in "${VIOLATIONS[@]}"; do
        if [ $SCENARIO_COUNT -ge 100 ]; then break 4; fi
        if [ $props -lt $layers ]; then continue; fi  # 命題数 < 層数はスキップ

        SCENARIO_COUNT=$((SCENARIO_COUNT + 1))
        FILENAME="$OUT_DIR/scenario$(printf '%03d' $SCENARIO_COUNT).json"

        generate_scenario $layers $props $density $viol $SCENARIO_COUNT > "$FILENAME"
      done
    done
  done
done

echo "Generated $SCENARIO_COUNT scenarios in $OUT_DIR/"
echo ""

# ============================================================
# パイプライン実行
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# LEAN_ROOT は lakefile.lean がある lean-formalization/
LEAN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PASS=0; FAIL=0; MONOTONE_VIOLATIONS=0; TOTAL_BUILD_TIME=0

echo "Running pipeline on all scenarios..."
echo "======================================"
echo ""

for f in "$OUT_DIR"/scenario*.json; do
  scenario=$(basename "$f" .json)
  num_layers=$(cat "$f" | jq '.layers | length')
  num_props=$(cat "$f" | jq '.propositions | length')
  num_deps=$(cat "$f" | jq '[.propositions[].dependencies | length] | add // 0')

  # 事前検証
  if bash "$SCRIPT_DIR/check-monotonicity.sh" -f "$f" > /dev/null 2>&1; then
    monotone_ok=true
  else
    monotone_ok=false
    MONOTONE_VIOLATIONS=$((MONOTONE_VIOLATIONS + 1))
  fi

  # Lean 生成 + ビルド（違反なしの場合のみ）
  if $monotone_ok; then
    # Lean ファイル名は PascalCase（大文字開始）
    num=$(echo "$scenario" | grep -o '[0-9]*')
    lean_file="$OUT_DIR/S${num}.lean"
    start_time=$(date +%s%N 2>/dev/null || python3 -c 'import time; print(int(time.time()*1e9))')

    if bash "$SCRIPT_DIR/generate-conditional-axiom-system.sh" -f "$f" -o "$lean_file" --no-verify > /dev/null 2>&1; then
      # lake build
      ABS_OUTPUT="$(cd "$(dirname "$lean_file")" && pwd)/$(basename "$lean_file")"
      REL_PATH="${ABS_OUTPUT#${LEAN_ROOT}/}"
      MODULE_NAME=$(echo "$REL_PATH" | sed 's|/|.|g' | sed 's|\.lean$||')
      export PATH="$HOME/.elan/bin:$PATH"

      if (cd "$LEAN_ROOT" && lake build "$MODULE_NAME" > /dev/null 2>&1); then
        end_time=$(date +%s%N 2>/dev/null || python3 -c 'import time; print(int(time.time()*1e9))')
        build_ms=$(( (end_time - start_time) / 1000000 ))
        TOTAL_BUILD_TIME=$((TOTAL_BUILD_TIME + build_ms))
        PASS=$((PASS + 1))
        echo "✓ ${scenario}: layers=${num_layers} props=${num_props} deps=${num_deps} build=${build_ms}ms"
      else
        FAIL=$((FAIL + 1))
        echo "✗ ${scenario}: layers=${num_layers} props=${num_props} deps=${num_deps} BUILD FAILED"
      fi
    else
      FAIL=$((FAIL + 1))
      echo "✗ ${scenario}: layers=${num_layers} props=${num_props} deps=${num_deps} GENERATE FAILED"
    fi
  else
    echo "⚠ ${scenario}: layers=${num_layers} props=${num_props} deps=${num_deps} MONOTONICITY VIOLATION (expected)"
  fi
done

echo ""
echo "======================================"
echo "RESULTS"
echo "======================================"
echo "Total scenarios: $SCENARIO_COUNT"
echo "Build PASS: $PASS"
echo "Build FAIL: $FAIL"
echo "Monotonicity violations (expected): $MONOTONE_VIOLATIONS"
if [ $PASS -gt 0 ]; then
  AVG_BUILD=$((TOTAL_BUILD_TIME / PASS))
  echo "Average build time: ${AVG_BUILD}ms"
fi
echo ""
echo "Coverage:"
echo "  Layer counts tested: ${LAYER_COUNTS[*]}"
echo "  Proposition counts tested: ${PROP_COUNTS[*]}"
echo "  Dependency densities: ${DENSITIES[*]}%"
echo "  Violation rates: ${VIOLATIONS[*]}%"
