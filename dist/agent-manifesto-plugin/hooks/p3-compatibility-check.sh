#!/usr/bin/env bash
# P3 Compatibility Classification — PreToolUse: Bash (git commit)
#
# 構造変更（.claude/, tests/, manifesto 関連ファイル）を含むコミットに
# 互換性分類（conservative/compatible/breaking）を要求する。

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

if ! echo "$COMMAND" | grep -qE 'git\s+commit'; then
  exit 0
fi

# コミットメッセージに互換性分類が含まれているか確認
STRUCTURAL_PATTERNS='\.claude/|tests/|manifesto\.md|constraints-taxonomy|design-development-foundation|lean-formalization/'
STAGED=$(git diff --cached --name-only 2>/dev/null)

if echo "$STAGED" | grep -qE "$STRUCTURAL_PATTERNS"; then
  # コミットメッセージを抽出（-m "..." or -m '...' パターン、POSIX互換）
  MSG=$(echo "$COMMAND" | sed -n 's/.*-m[[:space:]]*["'"'"']\([^"'"'"']*\)["'"'"'].*/\1/p')

  # 互換性分類キーワードの検出（MSG が空でも COMMAND 全体を検索）
  if echo "$MSG$COMMAND" | grep -qiE '(conservative|compatible|breaking|保守的|互換的|破壊的)'; then
    exit 0
  fi
  
  echo "P3: Structural files changed. Commit message should include compatibility classification:" >&2
  echo "  - conservative extension / 保守的拡張" >&2
  echo "  - compatible change / 互換的変更" >&2
  echo "  - breaking change / 破壊的変更" >&2
  echo "" >&2
  echo "Staged structural files:" >&2
  echo "$STAGED" | grep -E "$STRUCTURAL_PATTERNS" | while read -r f; do echo "  - $f" >&2; done
  # 警告のみ（exit 0）。D8: 段階的に厳格化
fi

exit 0
