#!/usr/bin/env bash
# paperize-jsonl-warn.sh — SessionStart hook.
# p2-verified.jsonl に未処理エントリがあれば警告する。
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

echo "[paperize] p2-verified.jsonl に $N 件の未処理検証トークンがあります" >&2
echo "[paperize] /paperize で論文化 → todos.md 保存 → jsonl flush を実行できます" >&2
