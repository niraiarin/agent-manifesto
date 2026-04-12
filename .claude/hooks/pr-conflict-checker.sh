#!/usr/bin/env bash
# PR Conflict Checker — PostToolUse: Bash (gh pr create)
#
# gh pr create 完了後に GitHub の mergeable status をポーリングし、
# conflict がある場合は state file を書き出す。
# PostToolUse はブロックできないが、stdout は LLM に表示される。
# @traces D1, P3, T6

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null)

if [ "$TOOL_NAME" != "Bash" ]; then
  exit 0
fi

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

# gh pr create の完了を検出
if ! echo "$COMMAND" | grep -qE 'gh\s+pr\s+create'; then
  exit 0
fi

# tool_result から PR URL を抽出
RESULT=$(echo "$INPUT" | jq -r '.tool_result // empty' 2>/dev/null)
PR_URL=$(echo "$RESULT" | grep -oE 'https://github\.com/[^/]+/[^/]+/pull/[0-9]+' | head -1)

if [ -z "$PR_URL" ]; then
  exit 0
fi

PR_NUMBER=$(echo "$PR_URL" | grep -oE '[0-9]+$')
REPO=$(echo "$PR_URL" | sed 's|https://github.com/||; s|/pull/[0-9]*||')

# State file (project-level for cross-session persistence)
PROJECT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
STATE_DIR="$PROJECT_DIR/.claude/metrics"
STATE_FILE="$STATE_DIR/pr-conflict-pending.json"
mkdir -p "$STATE_DIR"

# Poll for mergeable status (GitHub takes time to compute)
MAX_RETRIES=6
RETRY_DELAY=5
MERGEABLE="UNKNOWN"

echo "--- PR Conflict Check: $PR_URL ---"

for i in $(seq 1 $MAX_RETRIES); do
  RESPONSE=$(gh pr view "$PR_NUMBER" --repo "$REPO" --json mergeable,mergeStateStatus 2>/dev/null)
  if [ $? -ne 0 ]; then
    echo "[Attempt $i/$MAX_RETRIES] Failed to query PR status. Retrying in ${RETRY_DELAY}s..."
    sleep "$RETRY_DELAY"
    continue
  fi

  MERGEABLE=$(echo "$RESPONSE" | jq -r '.mergeable // "UNKNOWN"')
  MERGE_STATE=$(echo "$RESPONSE" | jq -r '.mergeStateStatus // "UNKNOWN"')

  if [ "$MERGEABLE" = "UNKNOWN" ]; then
    echo "[Attempt $i/$MAX_RETRIES] GitHub is still computing mergeability. Retrying in ${RETRY_DELAY}s..."
    sleep "$RETRY_DELAY"
    continue
  fi

  # Definitive result
  break
done

TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

if [ "$MERGEABLE" = "CONFLICTING" ]; then
  # Get conflicting files if possible
  CONFLICTING_FILES=$(gh pr view "$PR_NUMBER" --repo "$REPO" --json files --jq '.files[].path' 2>/dev/null | head -20)

  # Write state file
  jq -n \
    --arg url "$PR_URL" \
    --arg num "$PR_NUMBER" \
    --arg repo "$REPO" \
    --arg status "$MERGEABLE" \
    --arg merge_state "$MERGE_STATE" \
    --arg ts "$TIMESTAMP" \
    '{pr_url: $url, pr_number: ($num | tonumber), repo: $repo, status: $status, merge_state: $merge_state, detected_at: $ts}' \
    > "$STATE_FILE"

  echo ""
  echo "CONFLICT DETECTED in PR #$PR_NUMBER"
  echo "  Status: $MERGEABLE ($MERGE_STATE)"
  echo "  URL: $PR_URL"
  echo ""
  echo "ACTION REQUIRED: Resolve merge conflicts before proceeding."
  echo "  1. git fetch origin main"
  echo "  2. git rebase origin/main (or git merge origin/main)"
  echo "  3. Resolve conflicts and git push"
  echo ""
  echo "Further commits will be BLOCKED until conflicts are resolved."

elif [ "$MERGEABLE" = "MERGEABLE" ]; then
  # Clean — remove any stale state file
  rm -f "$STATE_FILE"
  echo "PR #$PR_NUMBER: No conflicts (mergeable: $MERGEABLE, state: $MERGE_STATE)"

elif [ "$MERGEABLE" = "UNKNOWN" ]; then
  # Still unknown after all retries — write tentative state for manual check
  jq -n \
    --arg url "$PR_URL" \
    --arg num "$PR_NUMBER" \
    --arg repo "$REPO" \
    --arg ts "$TIMESTAMP" \
    '{pr_url: $url, pr_number: ($num | tonumber), repo: $repo, status: "UNKNOWN", merge_state: "UNKNOWN", detected_at: $ts}' \
    > "$STATE_FILE"

  echo ""
  echo "WARNING: Could not determine merge status for PR #$PR_NUMBER after $MAX_RETRIES attempts."
  echo "  URL: $PR_URL"
  echo "  Conflict check will be retried on next commit attempt."
fi

exit 0

# Traceability:
# D1: 構造的強制 — PR conflict を自動検出し、state file で後続 hook と連携
# P3: 学習の統治 — PR ワークフローの品質を構造的に保証
# T6: 人間の資源権限 — conflict 解消は人間/エージェントの判断で行う
