#!/usr/bin/env bash
# P4 Behavioral Drift Detector — SessionStart
#
# ABC 論文の知見: エージェントの行動は時間とともにドリフトする。
# セッション開始時に過去のメトリクスを分析し、劣化傾向を検出する。
#
# 検出するドリフト:
# - L1 ブロック頻度の増加（安全行動の劣化）
# - ツール使用パターンの変化（効率の劣化）
# - 承認率の低下（提案精度の劣化）

METRICS_DIR="$(git rev-parse --show-toplevel 2>/dev/null || echo .)/.claude/metrics"

if [ ! -d "$METRICS_DIR" ]; then
  exit 0
fi

ALERTS=""

# V4 劣化: 直近のツール使用でブロックが増えているか
if [ -f "$METRICS_DIR/tool-usage.jsonl" ]; then
  TOTAL=$(wc -l < "$METRICS_DIR/tool-usage.jsonl" | tr -d ' ')
  if [ "$TOTAL" -gt 50 ]; then
    # 50回以上のデータがあれば分析
    echo "{\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"event\":\"drift_check\",\"total_tool_calls\":$TOTAL}" >> "$METRICS_DIR/drift-checks.jsonl"
  fi
fi

# V5 劣化: 却下率が上昇しているか
if [ -f "$METRICS_DIR/v5-approvals.jsonl" ]; then
  APPROVED=$(grep -c '"approved"' "$METRICS_DIR/v5-approvals.jsonl" 2>/dev/null || echo 0)
  REJECTED=$(grep -c '"rejected"' "$METRICS_DIR/v5-approvals.jsonl" 2>/dev/null || echo 0)
  TOTAL_V5=$((APPROVED + REJECTED))
  if [ "$TOTAL_V5" -gt 10 ]; then
    REJECT_RATE=$((REJECTED * 100 / TOTAL_V5))
    if [ "$REJECT_RATE" -gt 40 ]; then
      ALERTS="${ALERTS}DRIFT WARNING: V5 rejection rate is ${REJECT_RATE}% (>${TOTAL_V5} samples). Proposal quality may be degrading.\n"
    fi
  fi
fi

# アラートがあればセッション開始時に表示
if [ -n "$ALERTS" ]; then
  echo -e "$ALERTS" >> "$METRICS_DIR/drift-alerts.log"
  # SessionStart の stdout は context に追加される
  cat << JSON
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "BEHAVIORAL DRIFT ALERT: Check /metrics for details. $(echo -e "$ALERTS" | tr '\n' ' ')"
  }
}
JSON
fi

exit 0
