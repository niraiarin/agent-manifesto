#!/usr/bin/env bash
INPUT=$(cat)
TASK_ID=$(echo "$INPUT" | jq -r '.task_id // empty' 2>/dev/null)
TASK_SUBJECT=$(echo "$INPUT" | jq -r '.task_subject // empty' 2>/dev/null)
TEAMMATE=$(echo "$INPUT" | jq -r '.teammate_name // empty' 2>/dev/null)

METRICS_DIR="$(git rev-parse --show-toplevel 2>/dev/null || echo .)/.claude/metrics"
mkdir -p "$METRICS_DIR"

jq -nc --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg id "$TASK_ID" --arg subj "$TASK_SUBJECT" --arg tm "$TEAMMATE" \
  '{timestamp: $ts, event: "v7_task_completed", task_id: $id, subject: $subj, teammate: $tm}' >> "$METRICS_DIR/v7-tasks.jsonl"

exit 0
