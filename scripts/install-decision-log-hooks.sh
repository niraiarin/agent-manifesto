#!/usr/bin/env bash
# install-decision-log-hooks.sh — idempotent installer for git hooks.
#
# Installs decision-log-commit-hook.sh as the repo's git post-commit hook.
# Safe to re-run: detects existing symlink/copy and skips.
#
# Does NOT touch .claude/settings.json. Hook registration for Claude Code
# (UserPromptSubmit / PreToolUse / PostToolUse / Stop) requires human
# approval to edit .claude/settings.json — see docs for the snippet.

set -eu

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$REPO_ROOT" ]; then
  echo "[install] not in a git repo" >&2
  exit 1
fi

GIT_HOOKS_DIR="$REPO_ROOT/.git/hooks"
# For linked worktrees, .git is a file pointing at the actual gitdir
if [ -f "$REPO_ROOT/.git" ]; then
  GIT_DIR=$(sed -n 's/^gitdir: //p' "$REPO_ROOT/.git" 2>/dev/null)
  if [ -n "$GIT_DIR" ]; then
    # worktree gitdir is $mainrepo/.git/worktrees/<name>
    # hooks live in the main repo's .git/hooks
    MAIN_GIT_DIR=$(dirname "$(dirname "$GIT_DIR")")
    GIT_HOOKS_DIR="$MAIN_GIT_DIR/hooks"
  fi
fi

TARGET="$GIT_HOOKS_DIR/post-commit"
SOURCE="$REPO_ROOT/scripts/decision-log-commit-hook.sh"

if [ ! -x "$SOURCE" ]; then
  echo "[install] source hook not found or not executable: $SOURCE" >&2
  exit 1
fi

mkdir -p "$GIT_HOOKS_DIR"

if [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
  # Existing hook: check if it's ours. If yes, skip. If no, refuse.
  if [ -L "$TARGET" ] && [ "$(readlink "$TARGET")" = "$SOURCE" ]; then
    echo "[install] post-commit already installed (symlink → $SOURCE)"
    exit 0
  fi
  if head -n 3 "$TARGET" 2>/dev/null | grep -q "decision-log-commit-hook.sh"; then
    echo "[install] post-commit already installed (copy)"
    exit 0
  fi
  echo "[install] refusing to overwrite existing $TARGET" >&2
  echo "[install] existing hook contents:" >&2
  head -n 5 "$TARGET" >&2
  echo "[install] to replace: rm $TARGET && bash $0" >&2
  exit 1
fi

# Symlink preferred (auto-updates when source changes)
ln -s "$SOURCE" "$TARGET"
echo "[install] linked $TARGET → $SOURCE"
echo "[install] decision-log post-commit hook active. Next git commit in this repo will emit outcome.commit."

cat <<'NOTE'

Additional registration (requires human approval because .claude/settings.json
is a governance file):

  Add this block to .claude/settings.json (or merge into existing "hooks"):

  {
    "hooks": {
      "UserPromptSubmit": [{"hooks": [{"type": "command",
         "command": "bash $CLAUDE_PROJECT_DIR/scripts/decision-log-emit.sh user.turn"}]}],
      "PreToolUse":      [{"hooks": [{"type": "command",
         "command": "bash $CLAUDE_PROJECT_DIR/scripts/decision-log-emit.sh agent.tool_call"}]}],
      "PostToolUse":     [{"hooks": [{"type": "command",
         "command": "bash $CLAUDE_PROJECT_DIR/scripts/decision-log-emit.sh agent.tool_call_complete"}]}],
      "Stop":            [{"hooks": [{"type": "command",
         "command": "bash $CLAUDE_PROJECT_DIR/scripts/decision-log-emit.sh agent.output"}]}]
    }
  }

  Once added, Claude Code will emit:
    - user.turn on each prompt submit
    - agent.tool_call before each tool invocation
    - agent.tool_call_complete after each tool invocation
    - agent.output at session Stop

  See docs/research/routellm-phase3/analysis/decision-log-schema.md for full
  schema and analysis recipes.
NOTE
