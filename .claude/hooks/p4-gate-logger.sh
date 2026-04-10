#!/usr/bin/env bash
# P4 Gate Logger — SessionStart に登録し、L1 hook の結果を集計
#
# V4（ゲート通過率）: Phase 1 の hook が何回ブロックし何回通過したかを記録。
# このスクリプト自体は何もブロックしない。
# @traces P4, L6, V4

METRICS_DIR="$(git rev-parse --show-toplevel 2>/dev/null || echo .)/.claude/metrics"
mkdir -p "$METRICS_DIR"

INPUT=$(cat)
SESSION=$(echo "$INPUT" | jq -r '.session_id // ""' 2>/dev/null)
SESSION=${SESSION:-""}

# セッション開始時に前回のメトリクスサマリを生成
if [ -f "$METRICS_DIR/tool-usage.jsonl" ]; then
  TOTAL=$(wc -l < "$METRICS_DIR/tool-usage.jsonl" | tr -d ' ')
  echo "{\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"event\":\"session_summary\",\"total_tool_calls\":$TOTAL,\"session_id\":\"$SESSION\"}" >> "$METRICS_DIR/sessions.jsonl"
fi

exit 0
