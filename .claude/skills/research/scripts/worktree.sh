#!/usr/bin/env bash
# Step 4/7: Worktree 作成/削除/PR作成 (deterministic)
# TaskAutomationClass: deterministic → structural enforcement
# 根拠: deterministic_must_be_structural (TaskClassification.lean)
# @traces D1, P4
set -euo pipefail

MAIN_REPO="$(git rev-parse --show-toplevel 2>/dev/null)"

usage() {
  cat <<'USAGE'
Usage:
  worktree.sh create  <issue-number> <topic-name>
  worktree.sh cleanup <issue-number> <topic-name>
  worktree.sh pr      <issue-number> <topic-name> <pr-branch-name>

Examples:
  worktree.sh create  527 epistemic-tagged-values
  worktree.sh cleanup 527 epistemic-tagged-values
  worktree.sh pr      527 epistemic-tagged-values feat/526-epistemic-status
USAGE
  exit 1
}

[[ $# -lt 3 ]] && usage

ACTION="$1"
ISSUE_NUM="$2"
TOPIC="$3"
BRANCH="research/${ISSUE_NUM}-${TOPIC}"
WORKTREE_PATH="../$(basename "$MAIN_REPO")-research-${ISSUE_NUM}"

case "$ACTION" in
  create)
    if git worktree list | grep -q "$WORKTREE_PATH"; then
      echo "Worktree already exists: $WORKTREE_PATH"
      exit 0
    fi
    git worktree add "$WORKTREE_PATH" -b "$BRANCH" main
    echo "Created worktree: $WORKTREE_PATH (branch: $BRANCH)"

    # Lean 依存関係の初期化: .lake/packages を main repo から symlink (#544)
    MAIN_LAKE="$MAIN_REPO/lean-formalization/.lake"
    WT_LEAN="$WORKTREE_PATH/lean-formalization"
    if [[ -d "$MAIN_LAKE/packages" ]] && [[ -d "$WT_LEAN/.lake" ]]; then
      if [[ -d "$WT_LEAN/.lake/packages" ]] && [[ ! "$(ls -A "$WT_LEAN/.lake/packages" 2>/dev/null)" ]]; then
        # packages が空の場合、main repo からコピー
        cp -R "$MAIN_LAKE/packages/"* "$WT_LEAN/.lake/packages/" 2>/dev/null || true
        echo "Initialized .lake/packages from main repo"
      fi
    fi
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

  pr)
    # Worktree の変更を main repo の feature branch にコピーして PR 準備 (#544)
    [[ $# -lt 4 ]] && { echo "Error: pr requires <pr-branch-name>"; usage; }
    PR_BRANCH="$4"
    WT_ABS="$(cd "$WORKTREE_PATH" 2>/dev/null && pwd)" || { echo "Worktree not found: $WORKTREE_PATH"; exit 1; }

    # worktree のブランチで変更されたファイルを列挙
    CHANGED_FILES=$(cd "$WT_ABS" && git diff --name-only main...HEAD 2>/dev/null)
    if [[ -z "$CHANGED_FILES" ]]; then
      echo "No changes found in worktree branch $BRANCH"
      exit 1
    fi

    # main repo で feature branch を作成（既に存在すればチェックアウト）
    git checkout "$PR_BRANCH" 2>/dev/null || git checkout -b "$PR_BRANCH"

    # 変更ファイルを worktree からコピー
    COPIED=0
    while IFS= read -r file; do
      [[ -z "$file" ]] && continue
      SRC="$WT_ABS/$file"
      DST="$MAIN_REPO/$file"
      if [[ -f "$SRC" ]]; then
        mkdir -p "$(dirname "$DST")"
        cp "$SRC" "$DST"
        COPIED=$((COPIED + 1))
      fi
    done <<< "$CHANGED_FILES"

    echo "Copied $COPIED files from worktree to branch $PR_BRANCH"
    echo ""
    echo "Next steps:"
    echo "  1. Run: SYNC_SKIP_TESTS=1 bash scripts/sync-counts.sh --update"
    echo "  2. Run: lake build Manifest (in lean-formalization/)"
    echo "  3. git add + git commit"
    echo "  4. git push -u origin $PR_BRANCH"
    echo "  5. gh pr create"
    ;;

  *)
    usage
    ;;
esac
