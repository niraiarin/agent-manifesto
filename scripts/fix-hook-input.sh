#!/usr/bin/env bash
# fix-hook-input.sh — hook の入力取得方法を修正
set -euo pipefail
BASE="$(git rev-parse --show-toplevel)"

# 1. p4-traces-integrity-check.sh
FILE="$BASE/.claude/hooks/p4-traces-integrity-check.sh"
sed -i '' 's/TOOL_INPUT="${CLAUDE_TOOL_INPUT:-}"/INPUT=$(cat)/' "$FILE"
sed -i '' 's/\$TOOL_INPUT/$INPUT/g' "$FILE"
sed -i '' "s/'.file_path/'.tool_input.file_path/" "$FILE"
echo "Fixed: $FILE"

# 2. p4-manifest-refs-check.sh
FILE="$BASE/.claude/hooks/p4-manifest-refs-check.sh"
sed -i '' 's/TOOL_INPUT="${CLAUDE_TOOL_INPUT:-}"/INPUT=$(cat)/' "$FILE"
sed -i '' 's/\$TOOL_INPUT/$INPUT/g' "$FILE"
sed -i '' "s/'.command/'.tool_input.command/" "$FILE"
echo "Fixed: $FILE"

echo ""
echo "Verify:"
grep -n 'INPUT\|TOOL_INPUT' \
  "$BASE/.claude/hooks/p4-traces-integrity-check.sh" \
  "$BASE/.claude/hooks/p4-manifest-refs-check.sh"
