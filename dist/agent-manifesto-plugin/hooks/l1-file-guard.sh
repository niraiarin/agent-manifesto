#!/usr/bin/env bash
# L1 File Guard — PreToolUse: Edit, Write
#
# テストファイルの無効化パターンと秘密ファイルへの書き込みを検出。

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# --- L1: 秘密ファイルへの書き込み ---
if echo "$FILE_PATH" | grep -qiE '\.(env|pem|key)($|\.)|credentials|secret|id_rsa|id_ed25519'; then
  echo "L1: Writing to credential/secret file blocked: $FILE_PATH" >&2
  exit 2
fi

# --- L1: テスト改竄の検出 ---
if echo "$FILE_PATH" | grep -qiE '(test|spec|_test\.|\.test\.)'; then
  # 編集内容を取得（Edit: new_string, Write: content）
  CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string // .tool_input.content // empty' 2>/dev/null)
  if echo "$CONTENT" | grep -qiE '\b(skip|pending|xit|xdescribe|xtest|\.skip)\b'; then
    echo "L1: Test skip/disable pattern detected in test file: $FILE_PATH" >&2
    exit 2
  fi
fi

# --- L1: Hook 自己保護 (parry-guard の知見) ---
if echo "$FILE_PATH" | grep -qE '\.claude/(hooks|settings)'; then
  echo "L1: Modifying governance configuration requires human approval. File: $FILE_PATH" >&2
  exit 2
fi

exit 0
