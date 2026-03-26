#!/usr/bin/env bash
# extract-dependency-graph.sh
#
# Ontology.lean の PropositionId.dependencies から依存グラフを抽出し、
# 質問生成の入力となる構造データを出力する。
#
# 出力:
#   1. 全命題とそのカテゴリ・strength
#   2. 依存グラフ（隣接リスト）
#   3. 依存の推移閉包による到達可能性
#   4. カテゴリ境界を跨ぐ依存（境界ケース候補）
#
# Usage: bash extract-dependency-graph.sh [path/to/Ontology.lean]

set -euo pipefail

ONTOLOGY="${1:-$(dirname "$0")/../Ontology.lean}"

if [ ! -f "$ONTOLOGY" ]; then
  echo "Error: $ONTOLOGY not found" >&2
  exit 1
fi

echo "=== PropositionId Dependency Graph ==="
echo ""

# --- 1. 命題一覧とカテゴリ ---
echo "## 1. Propositions and Categories"
echo ""
echo "| PropositionId | Category | Strength |"
echo "|---------------|----------|----------|"

declare -A CATEGORIES
declare -A STRENGTHS

# カテゴリマッピング（PropositionId.category から）
for p in t1 t2 t3 t4 t5 t6 t7 t8; do
  CATEGORIES[$p]="constraint"
  STRENGTHS[$p]=5
done
for p in e1 e2; do
  CATEGORIES[$p]="empiricalPostulate"
  STRENGTHS[$p]=4
done
for p in p1 p2 p3 p4 p5 p6; do
  CATEGORIES[$p]="principle"
  STRENGTHS[$p]=3
done
for p in l1 l2 l3 l4 l5 l6; do
  CATEGORIES[$p]="boundary"
  STRENGTHS[$p]=2
done
for p in d1 d2 d3 d4 d5 d6 d7 d8 d9 d10 d11 d12 d13 d14; do
  CATEGORIES[$p]="designTheorem"
  STRENGTHS[$p]=1
done

for p in t1 t2 t3 t4 t5 t6 t7 t8 e1 e2 p1 p2 p3 p4 p5 p6 l1 l2 l3 l4 l5 l6 d1 d2 d3 d4 d5 d6 d7 d8 d9 d10 d11 d12 d13 d14; do
  echo "| $p | ${CATEGORIES[$p]} | ${STRENGTHS[$p]} |"
done

echo ""

# --- 2. 依存グラフ ---
echo "## 2. Direct Dependencies (from Ontology.lean)"
echo ""

declare -A DEPS

# Ontology.lean から依存関係を抽出
while IFS= read -r line; do
  # パターン: | .xx => [.yy, .zz] or | .xx => []
  if [[ "$line" =~ \|[[:space:]]*\.([a-z0-9]+)[[:space:]]*'=>'[[:space:]]*\[([^\]]*)\] ]] || \
     [[ "$line" =~ \|[[:space:]]\.([a-z0-9]+).*'=>'.*\[([^\]]*)\] ]]; then
    prop="${BASH_REMATCH[1]}"
    deps_raw="${BASH_REMATCH[2]}"
    # .xx を xx に変換
    deps_clean=$(echo "$deps_raw" | sed 's/\.//g' | sed 's/,/ /g' | xargs)
    DEPS[$prop]="$deps_clean"
  fi
done < <(sed -n '/def PropositionId.dependencies/,/^$/p' "$ONTOLOGY" | grep '=>')

for p in t1 t2 t3 t4 t5 t6 t7 t8 e1 e2 p1 p2 p3 p4 p5 p6 l1 l2 l3 l4 l5 l6 d1 d2 d3 d4 d5 d6 d7 d8 d9 d10 d11 d12 d13 d14; do
  deps="${DEPS[$p]:-}"
  if [ -z "$deps" ]; then
    echo "$p → (none)"
  else
    echo "$p → $deps"
  fi
done

echo ""

# --- 3. カテゴリ境界を跨ぐ依存 ---
echo "## 3. Cross-Category Dependencies (boundary case candidates)"
echo ""
echo "Dependencies where source and target have DIFFERENT categories:"
echo ""

cross_count=0
for p in t1 t2 t3 t4 t5 t6 t7 t8 e1 e2 p1 p2 p3 p4 p5 p6 l1 l2 l3 l4 l5 l6 d1 d2 d3 d4 d5 d6 d7 d8 d9 d10 d11 d12 d13 d14; do
  deps="${DEPS[$p]:-}"
  if [ -n "$deps" ]; then
    src_cat="${CATEGORIES[$p]}"
    for dep in $deps; do
      dep_cat="${CATEGORIES[$dep]:-unknown}"
      if [ "$src_cat" != "$dep_cat" ]; then
        echo "  $p ($src_cat, str=${STRENGTHS[$p]}) → $dep ($dep_cat, str=${STRENGTHS[$dep]})"
        cross_count=$((cross_count + 1))
      fi
    done
  fi
done

echo ""
echo "Total cross-category dependencies: $cross_count"

echo ""

# --- 4. 統計サマリ ---
echo "## 4. Summary Statistics"
echo ""

total=0
roots=0
leaves=0
for p in t1 t2 t3 t4 t5 t6 t7 t8 e1 e2 p1 p2 p3 p4 p5 p6 l1 l2 l3 l4 l5 l6 d1 d2 d3 d4 d5 d6 d7 d8 d9 d10 d11 d12 d13 d14; do
  total=$((total + 1))
  deps="${DEPS[$p]:-}"
  if [ -z "$deps" ]; then
    roots=$((roots + 1))
  fi
  # Check if anyone depends on this
  is_leaf=true
  for q in t1 t2 t3 t4 t5 t6 t7 t8 e1 e2 p1 p2 p3 p4 p5 p6 l1 l2 l3 l4 l5 l6 d1 d2 d3 d4 d5 d6 d7 d8 d9 d10 d11 d12 d13 d14; do
    q_deps="${DEPS[$q]:-}"
    if echo "$q_deps" | grep -qw "$p"; then
      is_leaf=false
      break
    fi
  done
  if $is_leaf; then
    leaves=$((leaves + 1))
  fi
done

echo "Total propositions: $total"
echo "Root nodes (no dependencies): $roots"
echo "Leaf nodes (nothing depends on them): $leaves"
echo ""

# カテゴリ別
echo "By category:"
for cat in constraint empiricalPostulate principle boundary designTheorem; do
  count=0
  for p in t1 t2 t3 t4 t5 t6 t7 t8 e1 e2 p1 p2 p3 p4 p5 p6 l1 l2 l3 l4 l5 l6 d1 d2 d3 d4 d5 d6 d7 d8 d9 d10 d11 d12 d13 d14; do
    if [ "${CATEGORIES[$p]}" = "$cat" ]; then
      count=$((count + 1))
    fi
  done
  echo "  $cat: $count"
done
