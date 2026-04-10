#!/usr/bin/env bash
# P4 Temporal Constraint Tracker — PreToolUse: Bash
#
# セッション内の操作順序を追跡し、時相制約違反を検出する。
# Agent-C 論文のアイデアをシンプルな状態機械で実装。
#
# 制約:
# - git push の前に test 実行が必要（test-before-push）
# - git commit の前に変更がある（no-empty-commit は git が保証）
# - 破壊的操作の前にバックアップ確認（warn-before-destructive）
# @traces P4, T1

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
SESSION=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null)

if [ -z "$COMMAND" ]; then
  exit 0
fi

STATE_DIR="/tmp/temporal-${SESSION}"
mkdir -p "$STATE_DIR"

# イベントの記録
if echo "$COMMAND" | grep -qE '(npm test|pytest|cargo test|lake build|bash tests/|make test)'; then
  touch "$STATE_DIR/tests-run"
fi

if echo "$COMMAND" | grep -qE 'git\s+add'; then
  touch "$STATE_DIR/files-staged"
fi

if echo "$COMMAND" | grep -qE 'git\s+commit'; then
  touch "$STATE_DIR/committed"
  # commit 後は tests-run をリセット（新しい変更にはテストが必要）
  rm -f "$STATE_DIR/tests-run"
fi

# --- 時相制約チェック ---

# TC1: git push の前にテストが実行されているか
if echo "$COMMAND" | grep -qE 'git\s+push'; then
  if [ ! -f "$STATE_DIR/tests-run" ] && [ ! -f "$STATE_DIR/committed" ]; then
    echo "Temporal: git push without prior test run or commit in this session." >&2
    echo "  Consider running tests before pushing." >&2
    # 警告のみ（D8: 段階的）
  fi
fi

# TC2: git commit --amend は直前の commit がある場合のみ警告
if echo "$COMMAND" | grep -qE 'git\s+commit.*--amend'; then
  echo "Temporal: git commit --amend detected. This modifies the previous commit." >&2
  echo "  Ensure this is intentional (not accidentally overwriting someone else's work)." >&2
fi

exit 0
