#!/usr/bin/env bash
# trace-coverage.sh — テスト→命題トレーサビリティのカバレッジレポート
# 方式A（@traces アノテーション）と方式B（trace-map.json）の両方から集計
#
# Usage: bash scripts/trace-coverage.sh [--json]
set -uo pipefail

BASE="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
JSON_MODE="${1:-}"

# 全 PropositionId（Ontology.lean から動的取得 — SSOT）
ALL_PROPS=$(bash "$BASE/scripts/list-propositions.sh" 2>/dev/null)
if [ -z "$ALL_PROPS" ]; then
  echo "ERROR: list-propositions.sh failed" >&2
  exit 1
fi
TOTAL_PROPS=$(echo $ALL_PROPS | wc -w | tr -d ' ')

declare -A PROP_TESTS  # proposition → test count

# --- 方式A: @traces アノテーションを解析 ---
extract_annotations() {
  local file="$1"
  grep -n '# @traces' "$file" 2>/dev/null | while IFS= read -r line; do
    local lineno=$(echo "$line" | cut -d: -f1)
    local props=$(echo "$line" | sed 's/.*# @traces //' | tr ',' ' ')
    # 次の check 行からテストIDを抽出
    local check_line=$(sed -n "$((lineno+1))p" "$file")
    local test_id=$(echo "$check_line" | grep -o '"[A-Z][A-Z0-9]*\.[0-9]*' | tr -d '"' | head -1)
    for prop in $props; do
      prop_upper=$(echo "$prop" | tr '[:lower:]' '[:upper:]')
      echo "$prop_upper $test_id"
    done
  done
}

# --- 方式B: trace-map.json を解析 ---
extract_json_map() {
  local map_file="$BASE/tests/trace-map.json"
  [ -f "$map_file" ] || return
  jq -r '
    .mapping | to_entries[] | .value | to_entries[] |
    .key as $test |
    (.value.primary | ascii_upcase) as $primary |
    (.value.secondary // [] | .[] | ascii_upcase) as $sec |
    "\($primary) \($test)", "\($sec) \($test)"
  ' "$map_file" 2>/dev/null
}

# --- 集計 ---
{
  # 方式A: 全テストファイルからアノテーション抽出
  for f in "$BASE"/tests/phase*/test-*.sh; do
    extract_annotations "$f"
  done
  # 方式B: JSON マッピング
  extract_json_map
} | sort -u | while read -r prop test_id; do
  [ -n "$prop" ] && [ -n "$test_id" ] && echo "$prop $test_id"
done > /tmp/trace-links.txt

# 命題ごとのテスト数を集計
for prop in $ALL_PROPS; do
  count=$(grep -c "^${prop} " /tmp/trace-links.txt 2>/dev/null || true)
  count=${count:-0}
  count=$(echo "$count" | tr -d '[:space:]')
  PROP_TESTS[$prop]=$count
done

# --- レポート出力 ---
if [ "$JSON_MODE" = "--json" ]; then
  echo "{"
  echo "  \"total_propositions\": $TOTAL_PROPS,"
  covered=0
  uncovered_list=""
  for prop in $ALL_PROPS; do
    [ "${PROP_TESTS[$prop]}" -gt 0 ] && covered=$((covered + 1)) || uncovered_list="$uncovered_list \"$prop\","
  done
  echo "  \"covered\": $covered,"
  echo "  \"uncovered\": $(($TOTAL_PROPS - covered)),"
  echo "  \"coverage_pct\": $(echo "scale=1; $covered * 100 / $TOTAL_PROPS" | bc),"
  echo "  \"uncovered_props\": [${uncovered_list%,}],"
  echo '  "details": {'
  first=true
  for prop in $ALL_PROPS; do
    tests=$(grep "^$prop " /tmp/trace-links.txt | awk '{print $2}' | sort -u | tr '\n' ',' | sed 's/,$//')
    $first || echo ","
    first=false
    printf '    "%s": {"count": %d, "tests": [%s]}' "$prop" "${PROP_TESTS[$prop]}" \
      "$(echo "$tests" | sed 's/\([^,]*\)/"\1"/g')"
  done
  echo ""
  echo "  }"
  echo "}"
else
  echo "=== Trace Coverage Report ==="
  echo ""
  covered=0
  uncovered=""
  for prop in $ALL_PROPS; do
    count=${PROP_TESTS[$prop]}
    if [ "$count" -gt 0 ]; then
      tests=$(grep "^$prop " /tmp/trace-links.txt | awk '{print $2}' | sort -u | tr '\n' ', ' | sed 's/, $//')
      printf "  %-4s  %2d tests  [%s]\n" "$prop" "$count" "$tests"
      covered=$((covered + 1))
    else
      printf "  %-4s  -- UNCOVERED --\n" "$prop"
      uncovered="$uncovered $prop"
    fi
  done
  echo ""
  echo "Coverage: $covered / $TOTAL_PROPS ($(echo "scale=1; $covered * 100 / $TOTAL_PROPS" | bc)%)"
  [ -n "$uncovered" ] && echo "Uncovered:$uncovered"
  echo ""
  echo "Source: @traces annotations + tests/trace-map.json"
fi

rm -f /tmp/trace-links.txt
