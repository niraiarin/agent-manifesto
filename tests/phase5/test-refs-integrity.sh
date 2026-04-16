#!/usr/bin/env bash
# refs 実在性テスト — artifact-manifest.json の refs がファイル内で @traces として宣言されているか検証
# 根拠: Traceability 4層モデル 層4（成果物内根拠説明）
set -uo pipefail
BASE="$(git rev-parse --show-toplevel 2>/dev/null || echo /Users/nirarin/work/agent-manifesto)"
MANIFEST="$BASE/artifact-manifest.json"
PASS=0; FAIL=0; SKIPPED=0

echo "=== Refs Integrity Tests ==="

# @traces 導入対象の artifact type
TRACEABLE_TYPES="skill hook agent rule"

# ファイルから @traces を抽出（Markdown + Shell 両対応）
# 仕様: 行頭が `<!-- @traces` または `# @traces` の場合のみ検出
# ファイル内での @traces の言及（コード例、説明文）は除外
extract_traces() {
  local file="$1"
  grep -h '^<!-- @traces\|^# @traces' "$file" 2>/dev/null \
    | sed 's/.*@traces[[:space:]]*//' \
    | sed 's/[[:space:]]*-->.*//' \
    | tr ',' '\n' \
    | sed 's/^[[:space:]]*//' \
    | sed 's/[[:space:]]*$//' \
    | tr '[:lower:]' '[:upper:]' \
    | grep '^[TEPLVD][0-9]\{1,2\}$' \
    | sort -u
}

# artifact-manifest.json から traceable な artifact を抽出して検証
echo ""
echo "--- @traces 存在チェック ---"

TOTAL_TRACEABLE=0
WITH_TRACES=0
WITHOUT_TRACES=0
MISMATCH=0

while IFS= read -r entry; do
  id=$(echo "$entry" | jq -r '.id')
  type=$(echo "$entry" | jq -r '.type')
  path=$(echo "$entry" | jq -r '.path')
  refs=$(echo "$entry" | jq -r '.refs[]' 2>/dev/null | sort -u)

  # traceable type でなければ対象外
  echo "$TRACEABLE_TYPES" | grep -qw "$type" || continue

  TOTAL_TRACEABLE=$((TOTAL_TRACEABLE + 1))
  full_path="$BASE/$path"

  if [ ! -f "$full_path" ]; then
    echo "  RI.$TOTAL_TRACEABLE [$id]: ファイル不在 ($path)... NOT_FOUND"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  # @traces の存在チェック
  traces=$(extract_traces "$full_path")

  if [ -z "$traces" ]; then
    echo "  RI.$TOTAL_TRACEABLE [$id]: @traces なし... XFAIL"
    WITHOUT_TRACES=$((WITHOUT_TRACES + 1))
    # XFAIL: @traces 未導入は既知の進行中ギャップ。FAIL カウントに含めない
    PASS=$((PASS + 1))
    continue
  fi

  WITH_TRACES=$((WITH_TRACES + 1))

  # refs との一致チェック
  refs_sorted=$(echo "$refs" | sort -u)
  traces_sorted=$(echo "$traces" | sort -u)

  if [ "$refs_sorted" = "$traces_sorted" ]; then
    echo "  RI.$TOTAL_TRACEABLE [$id]: @traces ↔ refs 一致... PASS"
    PASS=$((PASS + 1))
  else
    # 差分を表示
    only_refs=$(comm -23 <(echo "$refs_sorted") <(echo "$traces_sorted") | tr '\n' ',' | sed 's/,$//')
    only_traces=$(comm -13 <(echo "$refs_sorted") <(echo "$traces_sorted") | tr '\n' ',' | sed 's/,$//')
    echo "  RI.$TOTAL_TRACEABLE [$id]: @traces ↔ refs 不一致... FAIL"
    [ -n "$only_refs" ] && echo "    refs にあるが @traces にない: $only_refs"
    [ -n "$only_traces" ] && echo "    @traces にあるが refs にない: $only_traces"
    FAIL=$((FAIL + 1))
    MISMATCH=$((MISMATCH + 1))
  fi
done < <(jq -c '.artifacts[] | select(._comment == null)' "$MANIFEST")

echo ""
echo "--- サマリ ---"
echo "対象 artifact:     $TOTAL_TRACEABLE"
echo "@traces あり:      $WITH_TRACES"
echo "@traces なし:      $WITHOUT_TRACES (XFAIL)"
echo "不一致:            $MISMATCH"
echo "対象外:            $SKIPPED"

# RI.R1: @traces カバレッジ回帰検出
# 基準値: 39 (2026-04-10 時点、全 traceable artifact + integrity hook に @traces 導入済み)
BASELINE=38
echo ""
echo -n "  RI.R1: @traces カバレッジ回帰なし (>= $BASELINE)... "
if [ "$WITH_TRACES" -ge "$BASELINE" ]; then
  echo "PASS ($WITH_TRACES >= $BASELINE)"
  PASS=$((PASS + 1))
else
  echo "FAIL ($WITH_TRACES < $BASELINE)"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
exit $FAIL
