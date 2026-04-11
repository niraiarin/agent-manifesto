#!/usr/bin/env bash
INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)
SESSION=$(echo "$INPUT" | jq -r '.session_id // ""' 2>/dev/null)

if [ -z "$PROMPT" ]; then exit 0; fi

METRICS_DIR="$(git rev-parse --show-toplevel 2>/dev/null || echo .)/.claude/metrics"
mkdir -p "$METRICS_DIR"

APPROVAL_PATTERN='(^(ok|OK|yes|Yes|はい|いいよ|進めて|続けて|それで|良い|いい|LGTM|approved|go ahead|do it|sure|yep|that works))'
REJECTION_PATTERN='(^(no|No|いいえ|違う|やめて|stop|cancel|don.t|やり直|ダメ|not that|wrong|nope|reject))'

TYPE=""
if echo "$PROMPT" | grep -qiE "$APPROVAL_PATTERN"; then TYPE="approved"
elif echo "$PROMPT" | grep -qiE "$REJECTION_PATTERN"; then TYPE="rejected"
fi

if [ -n "$TYPE" ]; then
  jq -nc --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg result "$TYPE" --arg session "$SESSION" \
    '{timestamp: $ts, event: "v5_approval", result: $result, session: $session}' >> "$METRICS_DIR/v5-approvals.jsonl"
fi

exit 0
