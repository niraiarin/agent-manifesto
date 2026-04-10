#!/usr/bin/env bash
# Step 5: PR 作成・マージ (deterministic 成分)
# TaskAutomationClass: deterministic → structural enforcement
# 根拠: deterministic_must_be_structural (TaskClassification.lean)
#
# judgmental 成分（PR 説明文の品質判断、要レビュー判定）は LLM が担当。
# このスクリプトは deterministic 成分のみを実行する。
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  pr-workflow.sh create <run-number> <title> [--review]
  pr-workflow.sh merge <run-number>
  pr-workflow.sh cleanup

Options:
  --review    T6:human-review ラベルを付与（マージしない）

Examples:
  pr-workflow.sh create 100 "Fix sync-counts hook"
  pr-workflow.sh create 100 "Breaking: remove deprecated API" --review
  pr-workflow.sh merge 100
  pr-workflow.sh cleanup
USAGE
  exit 1
}

[[ $# -lt 1 ]] && usage

ACTION="$1"

case "$ACTION" in
  create)
    [[ $# -lt 3 ]] && usage
    RUN_NUM="$2"
    TITLE="$3"
    REVIEW="${4:-}"
    BRANCH="evolve/run-${RUN_NUM}"

    # ブランチ push
    git push -u origin "$BRANCH"

    if [[ "$REVIEW" == "--review" ]]; then
      # 要レビューフロー
      gh pr create --base main \
        --title "Run ${RUN_NUM}: ${TITLE} [要レビュー]" \
        --label "evolve" --label "T6:human-review" \
        --body "## LLM が PR 説明文を記述する（judgmental 成分）"
      echo "PR created with T6:human-review label. Awaiting human review."
    else
      # 通常フロー
      gh pr create --base main \
        --title "Run ${RUN_NUM}: ${TITLE}" \
        --label "evolve" \
        --body "## LLM が PR 説明文を記述する（judgmental 成分）"
      echo "PR created. Ready for merge."
    fi
    ;;
  merge)
    [[ $# -lt 2 ]] && usage
    RUN_NUM="$2"
    BRANCH="evolve/run-${RUN_NUM}"

    # T6:human-review ラベルがある場合はマージしない
    if gh pr view "$BRANCH" --json labels --jq '.labels[].name' 2>/dev/null | grep -q "T6:human-review"; then
      echo "ERROR: PR has T6:human-review label. Human review required before merge."
      exit 1
    fi

    gh pr merge "$BRANCH" --squash --delete-branch
    echo "PR merged and branch deleted."
    ;;
  cleanup)
    git checkout main && git pull
    echo "Switched to main and pulled latest."
    ;;
  *)
    usage
    ;;
esac
