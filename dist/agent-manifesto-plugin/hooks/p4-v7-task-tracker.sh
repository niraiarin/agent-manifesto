#!/usr/bin/env bash
# P4 V7 Task Tracker — TaskCompleted
#
# V7（タスク設計効率）: タスク完了イベントを記録する。
# TaskCompleted は Agent Teams のタスク完了時に発火する。

INPUT=$(cat)
TASK_ID=$(echo "$INPUT" | jq -r '.task_id // empty' 2>/dev/null)
TASK_SUBJECT=$(echo "$INPUT" | jq -r '.task_subject // empty' 2>/dev/null)
TEAMMATE=$(echo "$INPUT" | jq -r '.teammate_name // empty' 2>/dev/null)

METRICS_DIR="$(git rev-parse --show-toplevel 2>/dev/null || echo .)/.claude/metrics"
mkdir -p "$METRICS_DIR"

echo "{\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"event\":\"v7_task_completed\",\"task_id\":\"$TASK_ID\",\"subject\":\"$TASK_SUBJECT\",\"teammate\":\"$TEAMMATE\"}" >> "$METRICS_DIR/v7-tasks.jsonl"

exit 0
