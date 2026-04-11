#!/usr/bin/env bash
# H5 Doc Comment Linter — PreToolUse: Bash (git commit)
#
# Lean doc comment の品質を git commit 時に検証する。
# Verso の制約から導出されたルール (H1-H5, P1-P2, A1-A3, C1) をチェック。
# errors がある場合はコミットをブロック。warnings は表示のみ。
# リント対象は staged された Lean ファイルのみ (#414)。
# @traces D5, D1

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
STAGED_LEAN=$(echo "$STAGED" | grep -E 'lean-formalization/Manifest/.*\.lean$' || true)
if [ -z "$STAGED_LEAN" ]; then
  exit 0
fi

# Run the linter on staged Lean files only
PROJECT_ROOT=$("${GIT_CMD[@]}" rev-parse --show-toplevel 2>/dev/null)
LINT_OUTPUT=""
LINT_HAS_ERRORS=false

while IFS= read -r lean_file; do
  [ -z "$lean_file" ] && continue
  FILE_OUTPUT=$(cd "$PROJECT_ROOT" && python3 scripts/lint-doc-comments.py "$lean_file" 2>&1) || true
  if echo "$FILE_OUTPUT" | grep -qE '[1-9][0-9]* errors'; then
    LINT_HAS_ERRORS=true
  fi
  [ -n "$FILE_OUTPUT" ] && LINT_OUTPUT="${LINT_OUTPUT}${FILE_OUTPUT}"$'\n'
done <<< "$STAGED_LEAN"

if [ "$LINT_HAS_ERRORS" = true ]; then
  ERROR_COUNT=$(echo "$LINT_OUTPUT" | grep -oE '[0-9]+ errors' | head -1)
  echo "H5: Doc comment lint failed (${ERROR_COUNT:-errors}). Fix before committing." >&2
  echo "$LINT_OUTPUT" | grep '\[.*\] ' | head -10 >&2
  exit 2
fi

# Warnings only — allow but show
if [ -n "$LINT_OUTPUT" ]; then
  echo "$LINT_OUTPUT" | head -5
fi

exit 0

# Traceability:
# D5: 仕様層の順序 — ドキュメントの書式整合性を検証し、仕様の品質を構造的に維持
# D1: 構造的強制 — lint ルールを hook で自動実行し、LLM の判断に依存しない品質保証
