#!/usr/bin/env bash
set -uo pipefail
BASE="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
METRICS_DIR="$BASE/.claude/metrics"
HISTORY_FILE="$METRICS_DIR/evolve-history.jsonl"
TOOL_INPUT=$(cat 2>/dev/null || true)
TOOL_NAME=$(echo "$TOOL_INPUT" | grep -o '"tool_name":"[^"]*"' | head -1 | cut -d'"' -f4 2>/dev/null || true)
if [ "$TOOL_NAME" = "Bash" ]; then
  COMMAND=$(echo "$TOOL_INPUT" | grep -o '"command":"[^"]*"' | head -1 | cut -d'"' -f4 2>/dev/null || true)
  if echo "$COMMAND" | grep -q "git commit" 2>/dev/null; then
    if echo "$COMMAND" | grep -q "互換性分類\|conservative extension\|compatible change\|breaking change" 2>/dev/null; then
      mkdir -p "$METRICS_DIR"
      TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
      echo "{\"timestamp\":\"$TIMESTAMP\",\"event\":\"evolve_commit\",\"command\":\"$(echo "$COMMAND" | head -c 200)\"}" >> "$HISTORY_FILE"
    fi
  fi
fi
exit 0
