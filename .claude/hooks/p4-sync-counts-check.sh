#!/usr/bin/env bash
# P4 Sync Counts Gate — PreToolUse: Bash (git commit)
#
# コミット前に Lean/ドキュメントのカウント乖離を検出してブロックする。
# SYNC_SKIP_TESTS=1 で高速化（テスト数は check-loop.sh が担当）。

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

# git commit 以外はスルー
if ! echo "$COMMAND" | grep -qE 'git\s+commit'; then
  exit 0
fi

# sync-counts.sh の存在確認
SCRIPT_DIR="$(git rev-parse --show-toplevel 2>/dev/null)/scripts"
if [[ ! -f "$SCRIPT_DIR/sync-counts.sh" ]]; then
  exit 0
fi

# Lean カウントのみ高速チェック（テスト実行スキップ）
OUTPUT=$(SYNC_SKIP_TESTS=1 bash "$SCRIPT_DIR/sync-counts.sh" --check 2>&1)
RC=$?

if [[ $RC -ne 0 ]]; then
  echo "P4: Count sync check FAILED — files have stale counts." >&2
  echo "Run: bash scripts/sync-counts.sh --update" >&2
  echo "$OUTPUT" | grep -E '^\[DIFF\]' >&2
  exit 2
fi

exit 0
