#!/usr/bin/env bash
# L1 File Guard — PreToolUse: Edit, Write
#
# テストファイルの無効化パターンと秘密ファイルへの書き込みを検出。
# @traces L1, T1

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null)

# V4 gate_blocked イベント記録関数
log_gate_blocked() {
  local reason="$1"
  local metrics_dir
  metrics_dir="$(cd "$(dirname "$0")/.." && pwd)/metrics"
  local log_file="$metrics_dir/tool-usage.jsonl"
  if [ -d "$metrics_dir" ]; then
    printf '{"event":"gate_blocked","hook":"l1-file-guard","reason":"%s","tool":"%s","file":"%s","session_id":"%s","timestamp":"%s"}\n' \
      "$reason" "$TOOL" "$FILE_PATH" "$SESSION_ID" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$log_file" 2>/dev/null || true
  fi
}

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# --- L1: 秘密ファイルへの書き込み ---
if echo "$FILE_PATH" | grep -qiE '\.(env|pem|key)($|\.)|credentials|secret|id_rsa|id_ed25519'; then
  log_gate_blocked "credential_file_write"
  echo "L1: Writing to credential/secret file blocked: $FILE_PATH" >&2
  exit 2
fi

# --- L1: テスト改竄の検出 ---
if echo "$FILE_PATH" | grep -qiE '(test|spec|_test\.|\.test\.)'; then
  # 編集内容を取得（Edit: new_string, Write: content）
  CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string // .tool_input.content // empty' 2>/dev/null)
  if echo "$CONTENT" | grep -qiE '\b(skip|pending|xit|xdescribe|xtest|\.skip)\b'; then
    log_gate_blocked "test_tampering"
    echo "L1: Test skip/disable pattern detected in test file: $FILE_PATH" >&2
    exit 2
  fi
fi

# --- L1: Hook 自己保護 (parry-guard の知見) ---
if echo "$FILE_PATH" | grep -qE '\.claude/(hooks|settings)'; then
  log_gate_blocked "hook_self_protection"
  echo "L1: Modifying governance configuration requires human approval. File: $FILE_PATH" >&2
  exit 2
fi

exit 0

# Traceability:
# T1: セッション有界性 — テスト改竄・秘密ファイルの書き込みを阻止し、セッション間の構造整合性を保護
