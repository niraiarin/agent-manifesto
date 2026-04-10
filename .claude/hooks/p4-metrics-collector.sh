#!/usr/bin/env bash
# P4 Metrics Collector — PostToolUse (全ツール)
#
# PostToolUse はブロックできないが、全ツール実行のログを記録できる。
# V2（コンテキスト効率）と V4（ゲート通過率）の測定基盤。
# @traces P4, D3, V2, V4

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // "unknown"' 2>/dev/null)
TOOL_ID=$(echo "$INPUT" | jq -r '.tool_use_id // ""' 2>/dev/null)
SESSION=$(echo "$INPUT" | jq -r '.session_id // ""' 2>/dev/null)

METRICS_DIR="$(git rev-parse --show-toplevel 2>/dev/null || echo .)/.claude/metrics"
mkdir -p "$METRICS_DIR"

# JSONL 形式でログ（METRICS_LOG が設定済みならそちらに書き込む — テスト隔離用）
LOG_FILE="${METRICS_LOG:-$METRICS_DIR/tool-usage.jsonl}"
echo "{\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"event\":\"tool_use\",\"tool\":\"$TOOL\",\"tool_id\":\"$TOOL_ID\",\"session\":\"$SESSION\"}" >> "$LOG_FILE"

exit 0
