#!/usr/bin/env bash
# P4 V5 Approval Tracker — UserPromptSubmit
#
# V5（提案精度）: 人間の承認/却下パターンを記録する。
# UserPromptSubmit は全ユーザー入力で発火する。
# 承認/却下のシグナルをヒューリスティックで検出してログに記録。

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)
SESSION=$(echo "$INPUT" | jq -r '.session_id // ""' 2>/dev/null)

if [ -z "$PROMPT" ]; then
  exit 0
fi

METRICS_DIR="$(git rev-parse --show-toplevel 2>/dev/null || echo .)/.claude/metrics"
mkdir -p "$METRICS_DIR"

# 承認シグナル
APPROVAL_PATTERN='(^(ok|OK|yes|Yes|はい|いいよ|進めて|続けて|それで|良い|いい|LGTM|approved|go ahead|do it|sure|yep|that works))'
# 却下シグナル
REJECTION_PATTERN='(^(no|No|いいえ|違う|やめて|stop|cancel|don.t|やり直|ダメ|not that|wrong|nope|reject))'

if echo "$PROMPT" | grep -qiE "$APPROVAL_PATTERN"; then
  echo "{\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"event\":\"v5_approval\",\"type\":\"approved\",\"session\":\"$SESSION\"}" >> "$METRICS_DIR/v5-approvals.jsonl"
elif echo "$PROMPT" | grep -qiE "$REJECTION_PATTERN"; then
  echo "{\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"event\":\"v5_approval\",\"type\":\"rejected\",\"session\":\"$SESSION\"}" >> "$METRICS_DIR/v5-approvals.jsonl"
fi

exit 0
