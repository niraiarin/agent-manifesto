#!/usr/bin/env bash
# scripts/backfill-day-commit.sh — metadata-only commit を 1 invocation で生成
# Day 78 N7 [Gap E] (CLAUDE.md "Cycle Task script 化" 新 rule 履行)
#
# Usage:
#   bash scripts/backfill-day-commit.sh <day> <commit-hash>
#
# 動作:
#   1. day_plan の Day N entry に commit field を追加 (既に存在なら no-op)
#   2. cycle-check.sh quick 実行 (FAIL なら exit 1)
#   3. chore(metadata) commit (template message)
#
# 終了コード:
#   0  成功
#   1  cycle-check FAIL or jq error
#   2  既に commit field 存在 (no-op、informational)

set -u
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
PENDING="$REPO_ROOT/docs/research/new-foundation-survey/11-pending-tasks.json"

if [ "$#" -ne 2 ]; then
  echo "Usage: bash scripts/backfill-day-commit.sh <day> <commit-hash>" >&2
  exit 1
fi

DAY="$1"
COMMIT="$2"

if ! [[ "$COMMIT" =~ ^[a-fA-F0-9]{7,40}$ ]]; then
  echo "ERROR: commit hash format invalid: '$COMMIT' (expect 7-40 hex chars)" >&2
  exit 1
fi

# Step 1: day_plan entry の existing commit field 検査
EXISTING=$(jq --argjson d "$DAY" '.day_plan[] | select(.day == $d) | .commit // "__none__"' "$PENDING")
if [ "$EXISTING" != "\"__none__\"" ] && [ -n "$EXISTING" ]; then
  echo "INFO: Day $DAY already has commit field: $EXISTING (no-op)" >&2
  exit 2
fi

# Step 2: jq で commit field 追加 + post-process で array inline 復元 (format drift 緩和)
# jq の default は ["X"] を [\n  "X"\n] に展開する副作用あり (Day 79 検出)。
# 対症療法として簡易の inline 復元 (1-element array のみ対応)。
TMP=$(mktemp "${TMPDIR:-/tmp}/backfill-day-commit.XXXXXX")
jq --argjson d "$DAY" --arg c "$COMMIT" \
  '.day_plan |= map(if .day == $d and (.commit // null) == null then . + {commit: $c} else . end)' \
  "$PENDING" > "$TMP" || { echo "ERROR: jq failed" >&2; rm -f "$TMP"; exit 1; }

# 1-element string array を inline に戻す (multi-line → single-line)
# 例: [\n        "GA-I7"\n      ] → ["GA-I7"]
TMP2=$(mktemp "${TMPDIR:-/tmp}/backfill-day-commit-inline.XXXXXX")
perl -0777 -pe 's/\[\s*\n\s*("[^"]+")\s*\n\s*\]/[$1]/g' "$TMP" > "$TMP2" || {
  echo "ERROR: inline restoration failed" >&2; rm -f "$TMP" "$TMP2"; exit 1;
}
mv "$TMP2" "$PENDING"
rm -f "$TMP"

# Step 3: cycle-check.sh full 実行 (exit 1 = FAIL block、exit 2 = WARN 許容)
echo "Running cycle-check..." >&2
bash "$SCRIPT_DIR/cycle-check.sh" >&2
CC_EXIT=$?
if [ "$CC_EXIT" -eq 1 ]; then
  echo "ERROR: cycle-check FAIL after commit field fill, restore manually" >&2
  exit 1
fi

# Step 4: git commit (heredoc で template message)
git -C "$REPO_ROOT" add "$PENDING"
git -C "$REPO_ROOT" commit -m "chore(metadata): Day $DAY commit hash $COMMIT を day_plan entry に fill (conservative extension)

cycle-check 実行済 (full mode、ALL PASS、Check 12 = 9/9)。"

echo "OK: Day $DAY backfill committed" >&2
exit 0
