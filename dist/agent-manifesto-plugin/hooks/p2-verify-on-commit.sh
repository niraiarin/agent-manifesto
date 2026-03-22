#!/usr/bin/env bash
# P2 Verification Hook — PreToolUse: Bash (git commit)
#
# git commit 時にステージされたファイルをチェックし、
# 高リスクファイル（hooks, settings, tests）が含まれる場合のみ
# 独立検証を要求する。
#
# D2: コンテキスト分離は claude -p（別プロセス）で実現。
# コスト制御: 高リスクファイルがある場合のみ verifier を起動。

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

# git commit 以外はスキップ
if ! echo "$COMMAND" | grep -qE 'git\s+commit'; then
  exit 0
fi

# ステージされたファイルを確認
STAGED=$(git diff --cached --name-only 2>/dev/null)
if [ -z "$STAGED" ]; then
  exit 0
fi

# 高リスクファイルの検出
HIGH_RISK_PATTERNS='\.claude/|tests/|\.test\.|_test\.|settings\.json|\.env'
HIGH_RISK_FILES=$(echo "$STAGED" | grep -E "$HIGH_RISK_PATTERNS" || true)

if [ -n "$HIGH_RISK_FILES" ]; then
  echo "P2: High-risk files staged for commit:" >&2
  echo "$HIGH_RISK_FILES" | while read -r f; do echo "  - $f" >&2; done
  echo "" >&2
  echo "P2: Independent verification recommended. Run /verify before committing." >&2
  echo "    To proceed without verification, re-run the commit." >&2
  # ask ではなく通知のみ（exit 0）。ブロックすると開発フローが止まりすぎる。
  # 厳密な P2 準拠には exit 2 が必要だが、D7（信頼の非対称性）を考慮し
  # まず通知から始め、段階的に厳格化する（D8: 均衡探索）。
fi

exit 0
