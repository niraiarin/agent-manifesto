#!/usr/bin/env bash
# Step 7: クロージング (deterministic 成分)
# TaskAutomationClass: deterministic → structural enforcement
# 根拠: deterministic_must_be_structural (TaskClassification.lean)
#
# judgmental 成分（全体サマリ、GO/NO-GO 判定）は LLM が担当。
# このスクリプトは deterministic 成分のみを実行する。
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  closing.sh status <parent-issue-number>
  closing.sh close-sub <sub-issue-number> <comment>
  closing.sh cleanup-worktree <issue-number> <topic-name>

Examples:
  closing.sh status 359
  closing.sh close-sub 360 "Gate PASS"
  closing.sh cleanup-worktree 359 task-classification
USAGE
  exit 1
}

[[ $# -lt 2 ]] && usage

ACTION="$1"

case "$ACTION" in
  status)
    PARENT="$2"
    echo "=== Sub-Issues for #${PARENT} ==="
    # タイトルに "#<parent>" を含む issue でフィルタ（body 全文検索の誤ヒット回避）
    gh issue list --search "#${PARENT} Sub in:title" --state all --json number,title,state \
      --jq '.[] | "#\(.number) [\(.state)] \(.title)"'
    echo ""
    TOTAL=$(gh issue list --search "#${PARENT} Sub in:title" --state all --json number | jq length)
    CLOSED=$(gh issue list --search "#${PARENT} Sub in:title" --state closed --json number | jq length)
    echo "Progress: ${CLOSED}/${TOTAL} sub-issues closed"
    if [[ "$CLOSED" -eq "$TOTAL" ]] && [[ "$TOTAL" -gt 0 ]]; then
      echo "STATUS: All sub-issues closed. Ready for final Gate judgment."
    else
      echo "STATUS: $(( TOTAL - CLOSED )) sub-issues remaining."
    fi
    ;;
  close-sub)
    ISSUE="$2"
    COMMENT="${3:-Gate PASS}"
    gh issue close "$ISSUE" --comment "$COMMENT"
    echo "Closed #${ISSUE}"
    ;;
  cleanup-worktree)
    ISSUE="$2"
    TOPIC="${3:?topic-name required}"
    bash "$(dirname "$0")/worktree.sh" cleanup "$ISSUE" "$TOPIC"
    ;;
  *)
    usage
    ;;
esac
