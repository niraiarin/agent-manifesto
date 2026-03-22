#!/usr/bin/env bash
# P4 Metrics Collector — PostToolUse (全ツール)
#
# PostToolUse はブロックできないが、全ツール実行のログを記録できる。
# V2（コンテキスト効率）と V4（ゲート通過率）の測定基盤。

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // "unknown"' 2>/dev/null)
TOOL_ID=$(echo "$INPUT" | jq -r '.tool_use_id // ""' 2>/dev/null)
SESSION=$(echo "$INPUT" | jq -r '.session_id // ""' 2>/dev/null)

METRICS_DIR="$(git rev-parse --show-toplevel 2>/dev/null || echo .)/.claude/metrics"
mkdir -p "$METRICS_DIR"

# JSONL 形式でログ
echo "{\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"event\":\"tool_use\",\"tool\":\"$TOOL\",\"tool_id\":\"$TOOL_ID\",\"session\":\"$SESSION\"}" >> "$METRICS_DIR/tool-usage.jsonl"

exit 0
