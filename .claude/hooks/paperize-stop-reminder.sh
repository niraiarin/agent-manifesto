#!/usr/bin/env bash
# paperize-stop-reminder.sh — Stop hook.
# セッション終了時に jsonl エントリがあれば /paperize 起動を促す。
# @traces P3, D1

set -euo pipefail
BASE="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
JSONL="$BASE/.claude/metrics/p2-verified.jsonl"
[ -f "$JSONL" ] || exit 0
N=$(grep -c '' "$JSONL" 2>/dev/null || echo 0)
[ "$N" -gt 0 ] 2>/dev/null || exit 0

PAPERIZE_MODE=$(yq -r '.enforcement.mode // "warn"' "$BASE/paperize.yaml" 2>/dev/null || echo "warn")
case "$PAPERIZE_MODE" in
  skip) exit 0 ;;
esac

echo "[paperize] セッション終了: p2-verified.jsonl に $N 件の検証トークンが蓄積中" >&2
echo "[paperize] 次セッション開始前に /paperize 実行を推奨" >&2
