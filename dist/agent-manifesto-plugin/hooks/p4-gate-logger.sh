#!/usr/bin/env bash
# P4 Gate Logger — SessionStart に登録し、L1 hook の結果を集計
#
# V4（ゲート通過率）: Phase 1 の hook が何回ブロックし何回通過したかを記録。
# このスクリプト自体は何もブロックしない。

METRICS_DIR="$(git rev-parse --show-toplevel 2>/dev/null || echo .)/.claude/metrics"
mkdir -p "$METRICS_DIR"

# セッション開始時に前回のメトリクスサマリを生成
if [ -f "$METRICS_DIR/tool-usage.jsonl" ]; then
  TOTAL=$(wc -l < "$METRICS_DIR/tool-usage.jsonl" | tr -d ' ')
  echo "{\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"event\":\"session_summary\",\"total_tool_calls\":$TOTAL}" >> "$METRICS_DIR/sessions.jsonl"
fi

exit 0
