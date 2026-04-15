#!/usr/bin/env bash
# Branch Protection — PreToolUse: Bash (git commit)
#
# main ブランチへの直接コミットをブロックし、
# feature branch + PR ワークフローを構造的に強制する。
# @traces D1, P3, T6

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null)

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Only check git commit commands
if ! echo "$COMMAND" | grep -qE 'git\s+commit'; then
  exit 0
fi

# Resolve git working directory for worktree support (#548)
# Strategy: check multiple patterns in priority order
#   1. git -C <dir> — explicit git directory flag
#   2. cd <dir> anywhere in command chain — last cd before git commit
#   3. fallback to hook process CWD (no -C flag)
GIT_DIR=""

# 1. Extract git -C <dir> (highest priority — explicit)
if echo "$COMMAND" | grep -qE 'git[[:space:]]+-C[[:space:]]+'; then
  GIT_DIR=$(echo "$COMMAND" | grep -oE 'git[[:space:]]+-C[[:space:]]+("[^"]*"|[^[:space:]]+)' | head -1 | sed 's/git[[:space:]]*-C[[:space:]]*//' | tr -d '"')
fi

# 2. Extract last cd <dir> from the pipeline segment containing git commit
#    Split by | first to exclude pipe-separated cd (cd in pipe doesn't affect git)
if [ -z "$GIT_DIR" ]; then
  SEGMENT=$(echo "$COMMAND" | tr '|' '\n' | grep 'git.*commit' | head -1)
  GIT_DIR=$(echo "$SEGMENT" | grep -oE '(^|[;&]+[[:space:]]*)cd[[:space:]]+("[^"]*"|[^ "&;]+)' | tail -1 | sed 's/.*cd[[:space:]]*//' | tr -d '"')
fi

GIT_CMD=(git)
if [ -n "$GIT_DIR" ] && [ -d "$GIT_DIR" ]; then
  GIT_CMD=(git -C "$GIT_DIR")
fi

# Get current branch name
CURRENT_BRANCH=$("${GIT_CMD[@]}" rev-parse --abbrev-ref HEAD 2>/dev/null)

if [ -z "$CURRENT_BRANCH" ]; then
  exit 0
fi

# Block commits on main/master
if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ]; then
  # Log gate_blocked event
  METRICS_DIR=$("${GIT_CMD[@]}" rev-parse --show-toplevel 2>/dev/null || echo ".")/.claude/metrics
  if [ -d "$METRICS_DIR" ]; then
    printf '{"event":"gate_blocked","hook":"branch-protection","reason":"commit_on_main","tool":"Bash","session_id":"%s","timestamp":"%s"}\n' \
      "$SESSION_ID" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$METRICS_DIR/tool-usage.jsonl" 2>/dev/null || true
  fi

  echo "BLOCKED: Direct commit to '$CURRENT_BRANCH' is not allowed." >&2
  echo "Create a feature branch first:" >&2
  echo "  git checkout -b <feature-branch>" >&2
  echo "Or use Agent with isolation: \"worktree\" for isolated work." >&2
  exit 2
fi

exit 0

# Traceability:
# D1: 構造的強制 — main への直接コミットを hook でブロックし、LLM 判断に依存しない
# P3: 学習の統治 — feature branch + PR ワークフローで変更を統治する
# T6: 人間の資源権限 — PR レビューを通じて人間の最終決定権を確保する
