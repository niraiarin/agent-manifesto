#!/usr/bin/env bash
# H5 Doc Comment Linter — PreToolUse: Bash (git commit)
#
# Lean doc comment の品質を git commit 時に検証する。
# Verso の制約から導出されたルール (H1-H5, P1-P2, A1-A3, C1) をチェック。
# errors がある場合はコミットをブロック。warnings は表示のみ。

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

# Only trigger on git commit
if ! echo "$COMMAND" | grep -qE 'git\s+commit'; then
  exit 0
fi

# Resolve git working directory for worktree support
GIT_DIR=""
if echo "$COMMAND" | grep -qE '^[[:space:]]*cd[[:space:]]+'; then
GIT_DIR=$(echo "$COMMAND" | sed -n 's/^[[:space:]]*cd[[:space:]][[:space:]]*\("\([^"]*\)"\|\([^ &;]*\)\).*/\2\3/p')
fi
GIT_CMD=(git)
if [ -n "$GIT_DIR" ] && [ -d "$GIT_DIR" ]; then
GIT_CMD=(git -C "$GIT_DIR")
fi

# Check if any Lean files in Manifest/ are staged
STAGED=$("${GIT_CMD[@]}" diff --cached --name-only 2>/dev/null)
if ! echo "$STAGED" | grep -qE 'lean-formalization/Manifest/.*\.lean$'; then
  exit 0
fi

# Run the linter
PROJECT_ROOT=$("${GIT_CMD[@]}" rev-parse --show-toplevel 2>/dev/null)
LINT_OUTPUT=$(cd "$PROJECT_ROOT" && python3 scripts/lint-doc-comments.py 2>&1)
LINT_EXIT=$?

if [ $LINT_EXIT -ne 0 ]; then
  # Check if there are errors (not just warnings)
  if echo "$LINT_OUTPUT" | grep -q 'errors'; then
    ERROR_COUNT=$(echo "$LINT_OUTPUT" | grep -oE '[0-9]+ errors' | head -1)
    echo "H5: Doc comment lint failed ($ERROR_COUNT). Fix before committing." >&2
    echo "$LINT_OUTPUT" | grep '\[.*\] ' | head -10 >&2
    exit 2
  fi
  # Warnings only — allow but show
  echo "$LINT_OUTPUT" | head -5
fi

exit 0
