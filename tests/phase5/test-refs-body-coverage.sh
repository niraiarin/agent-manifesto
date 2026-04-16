#!/usr/bin/env bash
# refs 本文言及カバレッジテスト — refs の命題 ID がファイル本文で言及されているか
# 根拠: Traceability 4層モデル 層4（成果物内根拠説明の深い検証）
set -uo pipefail
BASE="$(git rev-parse --show-toplevel 2>/dev/null || echo /Users/nirarin/work/agent-manifesto)"
MANIFEST="$BASE/artifact-manifest.json"
PASS=0; FAIL=0

echo "=== Refs Body Coverage Tests ==="

TOTAL_TRACEABLE=0
WITH_BODY=0
WITHOUT_BODY=0

while IFS= read -r entry; do
  id=$(echo "$entry" | jq -r '.id')
  type=$(echo "$entry" | jq -r '.type')
  path=$(echo "$entry" | jq -r '.path')

  case "$type" in
    skill|hook|agent|rule) ;;
    *) continue ;;
  esac

  TOTAL_TRACEABLE=$((TOTAL_TRACEABLE + 1))
  full_path="$BASE/$path"
  [ -f "$full_path" ] || continue

  BODY=$(grep -v '^<!-- @traces\|^# @traces' "$full_path" 2>/dev/null || true)

  ALL_MENTIONED=true
  while IFS= read -r ref; do
    ref=$(echo "$ref" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    [ -z "$ref" ] && continue
    if ! grep -v '^<!-- @traces\|^# @traces' "$full_path" | grep -qw "$ref"; then
      ALL_MENTIONED=false
      break
    fi
  done < <(echo "$entry" | jq -r '.refs[]' 2>/dev/null)

  if [ "$ALL_MENTIONED" = true ]; then
    WITH_BODY=$((WITH_BODY + 1))
  else
    WITHOUT_BODY=$((WITHOUT_BODY + 1))
  fi
done < <(jq -c '.artifacts[] | select(._comment == null)' "$MANIFEST")

echo ""
echo "--- サマリ ---"
echo "対象 artifact:      $TOTAL_TRACEABLE"
echo "全 refs 言及あり:   $WITH_BODY"
echo "未言及あり:         $WITHOUT_BODY (XFAIL)"

# RB.1: 本文言及カバレッジ回帰検出
# 基準値: 36 (2026-04-12 — echo "$BODY" | grep バグ修正後の正確な値。旧 39 は echo の
# ARG_MAX 超過により誤検出を含んでいた。grep を直接ファイルに適用する方式に修正)
BASELINE=33
echo ""
echo -n "  RB.1: 本文言及カバレッジ回帰なし (>= $BASELINE)... "
if [ "$WITH_BODY" -ge "$BASELINE" ]; then
  echo "PASS ($WITH_BODY >= $BASELINE)"
  PASS=$((PASS + 1))
else
  echo "FAIL ($WITH_BODY < $BASELINE)"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
exit $FAIL
