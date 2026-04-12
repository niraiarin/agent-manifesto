#!/bin/bash
# check-mapping-accuracy.sh — Phase 4 マッピング品質検証スクリプト (#458)
#
# 使い方:
#   bash check-mapping-accuracy.sh <partial-order-mapping.json>
#
# partial-order-mapping.json の各エントリについて:
# 1. manifestoPropositions の D-ID を抽出
# 2. DesignFoundation.lean から該当 D-ID のセクションタイトルを取得
# 3. justification テキストと並べて表示
#
# 人間が目視で「justification が定義と整合しているか」を判定する（judgmental タスク）。
# このスクリプトは判定材料の提示を自動化する（deterministic 成分）。

set -euo pipefail

MAPPING_FILE="${1:-}"

if [ -z "$MAPPING_FILE" ] || [ ! -f "$MAPPING_FILE" ]; then
  echo "Usage: $0 <partial-order-mapping.json>"
  echo ""
  echo "Displays D-ID definitions alongside mapping justifications for manual review."
  exit 1
fi

# DesignFoundation.lean の場所を探す
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MANIFESTO_ROOT=$(bash "$SCRIPT_DIR/../shared/resolve-manifesto-root.sh" 2>/dev/null || echo "")

if [ -z "$MANIFESTO_ROOT" ]; then
  # worktree からの実行を想定
  MANIFESTO_ROOT=$(cd "$SCRIPT_DIR/../../.." && pwd)
fi

DESIGN_LEAN="$MANIFESTO_ROOT/lean-formalization/Manifest/DesignFoundation.lean"

if [ ! -f "$DESIGN_LEAN" ]; then
  echo "ERROR: DesignFoundation.lean not found at: $DESIGN_LEAN"
  exit 1
fi

# D-ID → タイトルのマッピングを構築
declare -A D_DEFINITIONS
while IFS= read -r line; do
  # "-- D7: 信頼の非対称性" のようなパターンを抽出
  if [[ "$line" =~ ^--\ (D[0-9]+):\ (.+)$ ]]; then
    did="${BASH_REMATCH[1]}"
    title="${BASH_REMATCH[2]}"
    # 重複（D4, D5, D6 は半順序型クラスインスタンスの行もある）は最初の定義を優先
    if [ -z "${D_DEFINITIONS[$did]:-}" ]; then
      D_DEFINITIONS[$did]="$title"
    fi
  fi
done < "$DESIGN_LEAN"

# マッピングファイルを解析して検証レポートを出力
echo "================================================================"
echo "  Mapping Accuracy Review: $(basename "$MAPPING_FILE")"
echo "  DesignFoundation.lean: $DESIGN_LEAN"
echo "================================================================"
echo ""

TOTAL=0
D_ENTRIES=0
MISSING_DEFS=0

# jq でマッピングエントリを走査
ENTRY_COUNT=$(jq '.mapping | length' "$MAPPING_FILE")

for (( i=0; i<ENTRY_COUNT; i++ )); do
  PROP=$(jq -r ".mapping[$i].eccProposition" "$MAPPING_FILE")
  JUSTIFICATION=$(jq -r ".mapping[$i].justification" "$MAPPING_FILE")
  MANIFESTO_PROPS=$(jq -r ".mapping[$i].manifestoPropositions // [] | .[]" "$MAPPING_FILE")

  TOTAL=$((TOTAL + 1))

  # D-ID を含むエントリのみ詳細表示
  HAS_D=false
  for mp in $MANIFESTO_PROPS; do
    if [[ "$mp" =~ ^D[0-9]+$ ]]; then
      HAS_D=true
      break
    fi
  done

  if [ "$HAS_D" = false ]; then
    continue
  fi

  D_ENTRIES=$((D_ENTRIES + 1))

  echo "--- [$PROP] ---"
  echo "  Mapping: $(echo "$MANIFESTO_PROPS" | tr '\n' ', ' | sed 's/,$//')"
  echo "  Justification: $JUSTIFICATION"
  echo ""

  for mp in $MANIFESTO_PROPS; do
    if [[ "$mp" =~ ^D[0-9]+$ ]]; then
      DEF="${D_DEFINITIONS[$mp]:-}"
      if [ -n "$DEF" ]; then
        echo "  $mp definition: $DEF"
      else
        echo "  $mp definition: *** NOT FOUND IN DesignFoundation.lean ***"
        MISSING_DEFS=$((MISSING_DEFS + 1))
      fi
    fi
  done
  echo ""
  echo "  [  ] Justification matches definition(s)? (manual check)"
  echo ""
done

echo "================================================================"
echo "  Summary"
echo "  Total mappings: $TOTAL"
echo "  Mappings with D-IDs: $D_ENTRIES"
echo "  Missing D definitions: $MISSING_DEFS"
echo "================================================================"

if [ "$MISSING_DEFS" -gt 0 ]; then
  echo ""
  echo "WARNING: $MISSING_DEFS D-ID(s) not found in DesignFoundation.lean."
  echo "These may be invalid D-IDs or the Lean file may be out of date."
  exit 1
fi
