#!/usr/bin/env bash
# detect-refs-body-violations.sh — refs の命題 ID がファイル本文に言及されていない違反を検出
# 層4 の深い検証: @traces ヘッダだけでなく、本文内で「なぜこの命題を実装するか」が説明されているか
set -uo pipefail

BASE="$(git rev-parse --show-toplevel 2>/dev/null || echo /Users/nirarin/work/agent-manifesto)"
MANIFEST="$BASE/artifact-manifest.json"

TOTAL=0
VIOLATIONS=0
CLEAN=0

echo "=== refs 本文言及チェック ==="
echo ""

jq -r '.artifacts[] | select(._comment == null) | select(.type == "skill" or .type == "hook" or .type == "agent" or .type == "rule") | "\(.id)|\(.path)|\(.refs | join(","))"' "$MANIFEST" | while IFS='|' read -r id path refs; do
  full_path="$BASE/$path"
  [ -f "$full_path" ] || continue

  TOTAL=$((TOTAL + 1))

  # @traces 行を除外した本文
  BODY=$(grep -v '@traces' "$full_path" 2>/dev/null || true)

  MISSING=""
  IFS=',' read -ra REF_ARRAY <<< "$refs"
  for ref in "${REF_ARRAY[@]}"; do
    ref=$(echo "$ref" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    # 命題 ID が本文中に出現するか
    if ! echo "$BODY" | grep -qw "$ref"; then
      MISSING="$MISSING $ref"
    fi
  done

  if [ -n "$MISSING" ]; then
    VIOLATIONS=$((VIOLATIONS + 1))
    echo "VIOLATION [$id]:$MISSING"
  fi
done

echo ""
echo "=== Done ==="
