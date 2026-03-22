#!/usr/bin/env bash
# L1 Test Tampering Check Hook (PreToolUse: Edit/Write)
# D1: テスト改竄の構造的禁止
#
# テストファイルの改変が、テスト結果を通すためだけの変更でないかを検証する。
# テストファイル自体の編集はブロックしない（正当な改善もある）が、
# テスト削除やアサーション緩和のパターンを検出して警告する。

set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
NEW_STRING=$(echo "$INPUT" | jq -r '.tool_input.new_string // .tool_input.content // empty')

if [ -z "$FILE_PATH" ]; then
  echo '{"decision": "allow"}'
  exit 0
fi

# テストファイルの判定
IS_TEST=false
if echo "$FILE_PATH" | grep -qiE '(test|spec|_test\.|\.test\.|tests/)'; then
  IS_TEST=true
fi

if [ "$IS_TEST" = true ]; then
  # テスト削除パターンの検出
  if echo "$NEW_STRING" | grep -qiE '(skip|pending|xit|xdescribe|xtest|\.skip)'; then
    echo '{"decision": "block", "reason": "L1 warning: test skip/disable pattern detected in test file. If intentional, explain why."}'
    exit 2
  fi
fi

# .env / credentials ファイルへの書き込み検出
if echo "$FILE_PATH" | grep -qiE '(\.env|credentials|secret|\.pem|\.key|id_rsa)'; then
  echo '{"decision": "block", "reason": "L1 violation: writing to credential/secret file"}'
  exit 2
fi

echo '{"decision": "allow"}'
exit 0
