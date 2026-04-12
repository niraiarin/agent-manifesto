#!/usr/bin/env bash
# PR Conflict Blocker — PreToolUse: Bash
#
# pr-conflict-pending.json が存在する場合、PR の conflict 状態を
# 再確認し、未解消なら git commit をブロックする。
# @traces D1, P3

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Only gate git commit and gh pr create
if ! echo "$COMMAND" | grep -qE '(git\s+commit|gh\s+pr\s+create)'; then
  exit 0
fi

# Check state file
PROJECT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
STATE_FILE="$PROJECT_DIR/.claude/metrics/pr-conflict-pending.json"

if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

PR_URL=$(jq -r '.pr_url // empty' "$STATE_FILE" 2>/dev/null)
PR_NUMBER=$(jq -r '.pr_number // empty' "$STATE_FILE" 2>/dev/null)
REPO=$(jq -r '.repo // empty' "$STATE_FILE" 2>/dev/null)

if [ -z "$PR_URL" ] || [ -z "$PR_NUMBER" ]; then
  # Invalid state file — clean up
  rm -f "$STATE_FILE"
  exit 0
fi

# Re-check current conflict status on GitHub
RESPONSE=$(gh pr view "$PR_NUMBER" --repo "$REPO" --json mergeable,mergeStateStatus 2>/dev/null)
if [ $? -ne 0 ]; then
  # API failure — allow but warn
  echo "WARNING: Could not verify PR #$PR_NUMBER conflict status (API error). Proceeding." >&2
  exit 0
fi

MERGEABLE=$(echo "$RESPONSE" | jq -r '.mergeable // "UNKNOWN"')

if [ "$MERGEABLE" = "MERGEABLE" ]; then
  # Conflicts resolved — clear state and pass
  rm -f "$STATE_FILE"
  exit 0
fi

if [ "$MERGEABLE" = "UNKNOWN" ]; then
  # Still computing — allow but warn
  echo "WARNING: PR #$PR_NUMBER merge status is still being computed. Proceeding with caution." >&2
  exit 0
fi

# CONFLICTING — block
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null)
METRICS_DIR="$PROJECT_DIR/.claude/metrics"
if [ -d "$METRICS_DIR" ]; then
  printf '{"event":"gate_blocked","hook":"pr-conflict-blocker","reason":"unresolved_pr_conflict","pr":"%s","session_id":"%s","timestamp":"%s"}\n' \
    "$PR_URL" "$SESSION_ID" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$METRICS_DIR/tool-usage.jsonl" 2>/dev/null || true
fi

echo "BLOCKED: PR #$PR_NUMBER has unresolved merge conflicts." >&2
echo "  URL: $PR_URL" >&2
echo "  Resolve conflicts first:" >&2
echo "    git fetch origin main && git rebase origin/main" >&2
echo "    # resolve conflicts" >&2
echo "    git push --force-with-lease" >&2
exit 2

# Traceability:
# D1: 構造的強制 — conflict 未解消の PR がある間は新規コミットをブロック
# P3: 学習の統治 — conflict 解消を経ないマージを防止
