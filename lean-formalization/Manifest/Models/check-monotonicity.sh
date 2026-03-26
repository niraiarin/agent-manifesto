#!/usr/bin/env bash
# check-monotonicity.sh
#
# ModelSpec JSON の分類が依存関係の単調性を満たすかを事前検証する。
# lake build の前に実行し、違反があれば詳細な診断を出力する。
#
# G5 フィードバックループの「検出」部分。
# 違反検出 → LLM による変更提案 → Phase 1/2 に戻る。
#
# Usage: bash check-monotonicity.sh -f model-spec.json

set -euo pipefail

INPUT_FILE=""
while [[ $# -gt 0 ]]; do
  case $1 in
    -f) INPUT_FILE="$2"; shift 2 ;;
    *) echo "Usage: $0 -f model-spec.json" >&2; exit 1 ;;
  esac
done

if [ -z "$INPUT_FILE" ]; then
  echo "Error: -f model-spec.json required" >&2
  exit 1
fi

JSON=$(cat "$INPUT_FILE")

# Ontology.lean から依存関係を取得
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ONTOLOGY="$SCRIPT_DIR/../Ontology.lean"

if [ ! -f "$ONTOLOGY" ]; then
  echo "Error: $ONTOLOGY not found" >&2
  exit 1
fi

# ============================================================
# 依存グラフの抽出
# ============================================================

declare -A DEPS
while IFS= read -r line; do
  if [[ "$line" =~ \|[[:space:]]\.([a-z0-9]+).*'=>'.*\[([^\]]*)\] ]]; then
    prop="${BASH_REMATCH[1]}"
    deps_raw="${BASH_REMATCH[2]}"
    deps_clean=$(echo "$deps_raw" | sed 's/\.//g' | sed 's/,/ /g' | xargs)
    DEPS[$prop]="$deps_clean"
  fi
done < <(sed -n '/def PropositionId.dependencies/,/^$/p' "$ONTOLOGY" | grep '=>')

# ============================================================
# ModelSpec から分類を取得
# ============================================================

declare -A CLASSIFY  # proposition → layerName
declare -A ORD_MAP   # layerName → ordValue

NUM_LAYERS=$(echo "$JSON" | jq '.layers | length')
for i in $(seq 0 $((NUM_LAYERS - 1))); do
  name=$(echo "$JSON" | jq -r ".layers[$i].name")
  ord=$(echo "$JSON" | jq -r ".layers[$i].ordValue")
  ORD_MAP[$name]=$ord
done

NUM_ASSIGNMENTS=$(echo "$JSON" | jq '.assignments | length')
for i in $(seq 0 $((NUM_ASSIGNMENTS - 1))); do
  prop=$(echo "$JSON" | jq -r ".assignments[$i].proposition")
  layer=$(echo "$JSON" | jq -r ".assignments[$i].layerName")
  CLASSIFY[$prop]=$layer
done

# ============================================================
# 単調性チェック
# ============================================================

violations=0
echo "=== Monotonicity Check ==="
echo ""

for prop in "${!DEPS[@]}"; do
  deps="${DEPS[$prop]}"
  if [ -z "$deps" ]; then continue; fi

  prop_layer="${CLASSIFY[$prop]:-UNKNOWN}"
  prop_ord="${ORD_MAP[$prop_layer]:-999}"

  for dep in $deps; do
    dep_layer="${CLASSIFY[$dep]:-UNKNOWN}"
    dep_ord="${ORD_MAP[$dep_layer]:-999}"

    if [ "$dep_ord" -lt "$prop_ord" ]; then
      violations=$((violations + 1))
      echo "VIOLATION #${violations}:"
      echo "  ${prop} (${prop_layer}, ord=${prop_ord}) depends on ${dep} (${dep_layer}, ord=${dep_ord})"
      echo "  Required: ord(${dep}) >= ord(${prop}), but ${dep_ord} < ${prop_ord}"
      echo ""

      # 修正提案
      echo "  Suggested fixes:"
      echo "    (a) Promote ${dep} to ${prop_layer} or higher"
      echo "    (b) Demote ${prop} to ${dep_layer} or lower"
      echo "    (c) Remove dependency ${prop} → ${dep} (if not essential)"

      # justification の情報
      for i in $(seq 0 $((NUM_ASSIGNMENTS - 1))); do
        a_prop=$(echo "$JSON" | jq -r ".assignments[$i].proposition")
        if [ "$a_prop" = "$dep" ]; then
          a_just=$(echo "$JSON" | jq -r ".assignments[$i].justification | join(\", \")")
          echo "    ${dep} justification: [${a_just}]"
        fi
        if [ "$a_prop" = "$prop" ]; then
          a_just=$(echo "$JSON" | jq -r ".assignments[$i].justification | join(\", \")")
          echo "    ${prop} justification: [${a_just}]"
        fi
      done
      echo ""
    fi
  done
done

if [ "$violations" -eq 0 ]; then
  echo "✓ No monotonicity violations found."
  echo ""
  echo "All dependencies respect the layer ordering."
  exit 0
else
  echo "✗ Found ${violations} monotonicity violation(s)."
  echo ""
  echo "Fix the violations above, then re-run this check."
  echo "If fix requires changing a human decision (C), escalate to Phase 1."
  echo "If fix only requires changing an LLM inference (H), update directly."
  exit 1
fi
