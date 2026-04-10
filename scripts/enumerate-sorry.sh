#!/usr/bin/env bash
# enumerate-sorry.sh — sorry 列挙・分類スクリプト (#302 G6)
# TaskAutomationClass: deterministic → structural enforcement
# 根拠: deterministic_must_be_structural (TaskClassification.lean)
#
# sorry の検出と分類。分類は sorry 行の直前コメントに基づく:
#   -- [sorry:placeholder] 理由
#   -- [sorry:dangling] 理由
#   -- [sorry:deferred] 理由
#   -- [sorry:exploratory] 理由
# タグなしの sorry は "unclassified" として報告する。
#
# 出力: JSON 形式（--json）または人間向けテキスト
set -euo pipefail

BASE="$(cd "$(dirname "$0")/.." && pwd)"
LEAN_DIR="$BASE/lean-formalization/Manifest"

FORMAT="text"
if [[ "${1:-}" == "--json" ]]; then
  FORMAT="json"
fi

# sorry を含む行を検出（文字列リテラル・コメント内を除外）
find_sorrys() {
  grep -rnE '^\s*sorry\s*$|:=\s*sorry\s*$' "$LEAN_DIR"/ --include="*.lean" 2>/dev/null || true
}

# sorry の分類タグを前の行から抽出
classify_sorry() {
  local file="$1"
  local line_num="$2"
  local prev_line=$((line_num - 1))
  if [[ $prev_line -ge 1 ]]; then
    local prev_content
    prev_content=$(sed -n "${prev_line}p" "$file")
    if echo "$prev_content" | grep -oqE '\[sorry:(placeholder|dangling|deferred|exploratory)\]'; then
      echo "$prev_content" | grep -oE '\[sorry:(placeholder|dangling|deferred|exploratory)\]' | sed 's/\[sorry://;s/\]//'
      return
    fi
  fi
  echo "unclassified"
}

sorry_lines=$(find_sorrys)

if [[ -z "$sorry_lines" ]]; then
  if [[ "$FORMAT" == "json" ]]; then
    echo '{"total":0,"classified":0,"unclassified":0,"by_class":{"placeholder":0,"dangling":0,"deferred":0,"exploratory":0},"items":[]}'
  else
    echo "sorry: 0 件（分類不要）"
  fi
  exit 0
fi

declare -A counts=([placeholder]=0 [dangling]=0 [deferred]=0 [exploratory]=0 [unclassified]=0)
items=""

while IFS=: read -r file line_num content; do
  [[ -z "$file" ]] && continue
  class=$(classify_sorry "$file" "$line_num")
  counts[$class]=$((${counts[$class]} + 1))
  rel_path="${file#$BASE/}"
  if [[ "$FORMAT" == "json" ]]; then
    [[ -n "$items" ]] && items="$items,"
    items="$items{\"file\":\"$rel_path\",\"line\":$line_num,\"class\":\"$class\"}"
  else
    printf "  %-14s %s:%d\n" "[$class]" "$rel_path" "$line_num"
  fi
done <<< "$sorry_lines"

total=$((${counts[placeholder]} + ${counts[dangling]} + ${counts[deferred]} + ${counts[exploratory]} + ${counts[unclassified]}))
classified=$((total - ${counts[unclassified]}))

if [[ "$FORMAT" == "json" ]]; then
  cat <<ENDJSON
{"total":$total,"classified":$classified,"unclassified":${counts[unclassified]},"by_class":{"placeholder":${counts[placeholder]},"dangling":${counts[dangling]},"deferred":${counts[deferred]},"exploratory":${counts[exploratory]}},"items":[$items]}
ENDJSON
else
  echo ""
  echo "=== sorry 分類サマリ ==="
  echo "  合計:          $total"
  echo "  分類済み:      $classified"
  echo "  未分類:        ${counts[unclassified]}"
  echo "  ---"
  echo "  placeholder:   ${counts[placeholder]}"
  echo "  dangling:      ${counts[dangling]}"
  echo "  deferred:      ${counts[deferred]}"
  echo "  exploratory:   ${counts[exploratory]}"
  if [[ ${counts[unclassified]} -gt 0 ]]; then
    echo ""
    echo "⚠ 未分類の sorry あり。直前行にタグを追加してください:"
    echo "  -- [sorry:placeholder|dangling|deferred|exploratory] 理由"
    exit 1
  fi
fi
