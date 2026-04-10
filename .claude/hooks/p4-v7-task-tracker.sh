#!/usr/bin/env bash
# @traces P4, D3, V7
INPUT=$(cat)
TASK_ID=$(echo "$INPUT" | jq -r '.task_id // empty' 2>/dev/null)
TASK_SUBJECT=$(echo "$INPUT" | jq -r '.task_subject // empty' 2>/dev/null)
TEAMMATE=$(echo "$INPUT" | jq -r '.teammate_name // empty' 2>/dev/null)

METRICS_DIR="$(git rev-parse --show-toplevel 2>/dev/null || echo .)/.claude/metrics"
mkdir -p "$METRICS_DIR"

jq -nc --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg id "$TASK_ID" --arg subj "$TASK_SUBJECT" --arg tm "$TEAMMATE" \
  '{timestamp: $ts, event: "v7_task_completed", task_id: $id, subject: $subj, teammate: $tm}' >> "$METRICS_DIR/v7-tasks.jsonl"

exit 0

# Traceability:
# P4: 可観測性 — タスク設計の自動化率を記録し V7 を計測可能にする # D3: 可観測性先行 — V7 の計測基盤として機能 # V7: タスク設計効率 — deterministic/mixed/judgmental の分類比率を計測
