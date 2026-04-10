#!/usr/bin/env bash
# @traces P4, D3, D9
set -uo pipefail
TOOL_INPUT=$(cat 2>/dev/null || true)
TOOL_NAME=$(echo "$TOOL_INPUT" | grep -o '"tool_name":"[^"]*"' | head -1 | cut -d'"' -f4 2>/dev/null || true)
if [ "$TOOL_NAME" = "Bash" ]; then
  COMMAND=$(echo "$TOOL_INPUT" | grep -o '"command":"[^"]*"' | head -1 | cut -d'"' -f4 2>/dev/null || true)
  # Resolve git working directory for worktree support
  GIT_DIR=""
  if echo "$COMMAND" | grep -qE '^[[:space:]]*cd[[:space:]]+' 2>/dev/null; then
    GIT_DIR=$(echo "$COMMAND" | sed -n 's/^[[:space:]]*cd[[:space:]][[:space:]]*\("\([^"]*\)"\|\([^ &;]*\)\).*/\2\3/p')
  fi
  if [ -n "$GIT_DIR" ] && [ -d "$GIT_DIR" ]; then
    BASE="$GIT_DIR"
  else
    BASE="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  fi
  METRICS_DIR="$BASE/.claude/metrics"
  HISTORY_FILE="$METRICS_DIR/evolve-history.jsonl"
  if echo "$COMMAND" | grep -q "git commit" 2>/dev/null; then
    if echo "$COMMAND" | grep -q "互換性分類\|conservative extension\|compatible change\|breaking change" 2>/dev/null; then
      mkdir -p "$METRICS_DIR"
      TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
      echo "{\"timestamp\":\"$TIMESTAMP\",\"event\":\"evolve_commit\",\"command\":\"$(echo "$COMMAND" | head -c 200)\"}" >> "$HISTORY_FILE"
    fi
  fi
fi
exit 0

# Traceability:
# P4: 可観測性 — /evolve の各フェーズ結果を evolve-history.jsonl に自動記録 # D3: 可観測性先行 — 改善の成果を計測可能にする基盤 # D9: 自己適用 — /evolve 自身のメトリクスを記録し、スキル改善の入力にする
