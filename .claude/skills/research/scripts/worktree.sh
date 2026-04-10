#!/usr/bin/env bash
# Step 4: Worktree 作成/削除 (deterministic)
# TaskAutomationClass: deterministic → structural enforcement
# 根拠: deterministic_must_be_structural (TaskClassification.lean)
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  worktree.sh create <issue-number> <topic-name>
  worktree.sh cleanup <issue-number> <topic-name>

Examples:
  worktree.sh create 359 task-classification
  worktree.sh cleanup 359 task-classification
USAGE
  exit 1
}

[[ $# -lt 3 ]] && usage

ACTION="$1"
ISSUE_NUM="$2"
TOPIC="$3"
BRANCH="research/${ISSUE_NUM}-${TOPIC}"
WORKTREE_PATH="../$(basename "$(pwd)")-research-${ISSUE_NUM}"

case "$ACTION" in
  create)
    if git worktree list | grep -q "$WORKTREE_PATH"; then
      echo "Worktree already exists: $WORKTREE_PATH"
      exit 0
    fi
    git worktree add "$WORKTREE_PATH" -b "$BRANCH" main
    echo "Created worktree: $WORKTREE_PATH (branch: $BRANCH)"
    ;;
  cleanup)
    if ! git worktree list | grep -q "$WORKTREE_PATH"; then
      echo "Worktree not found: $WORKTREE_PATH"
      exit 0
    fi
    git worktree remove "$WORKTREE_PATH"
    # ブランチ削除は人間の確認後（T6）
    echo "Removed worktree: $WORKTREE_PATH"
    echo "Branch '$BRANCH' is still available. Delete manually if no longer needed:"
    echo "  git branch -d $BRANCH"
    ;;
  *)
    usage
    ;;
esac
