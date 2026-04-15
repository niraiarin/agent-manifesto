#!/usr/bin/env bash
# Main Repo Branch Guard — PreToolUse: Bash
#
# main repo（プロジェクトルート）を main branch 以外に切り替える操作をブロック。
# ブランチ作業は worktree で行うべき。main repo は常に main branch に留まる。
#
# ブロック対象:
# - git checkout <branch> (main 以外)
# - git checkout -b <branch>
# - git switch <branch>
# - git switch -c <branch>
#
# 許可:
# - worktree 内での checkout/switch（main repo 外）
# - git checkout -- <file> (ファイル復元)
# - git checkout main (main への復帰)
#
# @traces D1, L1

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

[[ -z "$COMMAND" ]] && exit 0

# checkout/switch を含むか
if ! echo "$COMMAND" | grep -qE 'git\s+(checkout|switch)'; then
  exit 0
fi

# Resolve target directory from command (#548)
# 1. git -C <dir>, 2. last cd <dir> in pipeline segment with checkout/switch
TARGET_DIR=""
if echo "$COMMAND" | grep -qE 'git[[:space:]]+-C[[:space:]]+'; then
  TARGET_DIR=$(echo "$COMMAND" | grep -oE 'git[[:space:]]+-C[[:space:]]+("[^"]*"|[^[:space:]]+)' | head -1 | sed 's/git[[:space:]]*-C[[:space:]]*//' | tr -d '"')
fi
if [ -z "$TARGET_DIR" ]; then
  SEGMENT=$(echo "$COMMAND" | tr '|' '\n' | grep -E 'git.*(checkout|switch)' | head -1)
  TARGET_DIR=$(echo "$SEGMENT" | grep -oE '(^|[;&]+[[:space:]]*)cd[[:space:]]+("[^"]*"|[^ "&;]+)' | tail -1 | sed 's/.*cd[[:space:]]*//' | tr -d '"')
fi

# If target directory resolves to outside main repo, allow (worktree operation)
if [ -n "$TARGET_DIR" ] && [ -d "$TARGET_DIR" ]; then
  PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
  TARGET_DIR_REAL=$(cd "$TARGET_DIR" && pwd)
  if [ "$TARGET_DIR_REAL" != "$PROJECT_ROOT" ]; then
    exit 0
  fi
fi

# git checkout -- <file> (ファイル復元) は許可
if echo "$COMMAND" | grep -qE 'git\s+checkout\s+--\s'; then
  exit 0
fi

# git checkout main / git switch main は許可
if echo "$COMMAND" | grep -qE 'git\s+(checkout|switch)\s+main\b'; then
  exit 0
fi

# git checkout -b / git switch -c (新ブランチ作成) をブロック
if echo "$COMMAND" | grep -qE 'git\s+(checkout\s+-b|switch\s+-c)'; then
  BRANCH=$(echo "$COMMAND" | grep -oE '(checkout\s+-b|switch\s+-c)\s+\S+' | awk '{print $NF}')
  echo "BLOCKED: main repo でブランチ '$BRANCH' を作成できません。" >&2
  echo "" >&2
  echo "ブランチ作業は worktree で行ってください:" >&2
  echo "  bash .claude/skills/research/scripts/worktree.sh create <issue> <topic>" >&2
  echo "または EnterWorktree ツールを使用してください。" >&2
  exit 2
fi

# git checkout <branch> / git switch <branch> (既存ブランチへの切替) をブロック
if echo "$COMMAND" | grep -qE 'git\s+(checkout|switch)\s+\S+'; then
  TARGET=$(echo "$COMMAND" | grep -oE '(checkout|switch)\s+\S+' | awk '{print $NF}')
  # フラグ(-で始まる)は除外
  if [[ "$TARGET" != -* ]] && [[ "$TARGET" != "main" ]]; then
    echo "BLOCKED: main repo を '$TARGET' に切り替えできません。" >&2
    echo "" >&2
    echo "main repo は常に main branch に留めてください。" >&2
    echo "ブランチ作業は worktree で行ってください:" >&2
    echo "  bash .claude/skills/research/scripts/worktree.sh create <issue> <topic>" >&2
    exit 2
  fi
fi

exit 0
