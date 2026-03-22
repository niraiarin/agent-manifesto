#!/usr/bin/env bash
# L1 Safety Check Hook (PreToolUse: Bash)
# D1: 固定境界（L1）の構造的強制
#
# stdin: JSON with tool_input.command
# stdout: JSON with decision (allow/block) and reason
# Exit 0 = allow, Exit 2 = block

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  echo '{"decision": "allow"}'
  exit 0
fi

# L1: 破壊的操作の検出
DESTRUCTIVE_PATTERNS=(
  'rm -rf /'
  'rm -rf \*'
  'rm -rf \.'
  'mkfs\.'
  'dd if=/dev/zero'
  ':(){:|:&};:'
  'chmod -R 777 /'
  '> /dev/sda'
)

for pattern in "${DESTRUCTIVE_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    echo "{\"decision\": \"block\", \"reason\": \"L1 violation: destructive operation detected — $pattern\"}"
    exit 2
  fi
done

# L1: 外部からの注入指示の検出パターン
INJECTION_PATTERNS=(
  'ignore previous instructions'
  'ignore all previous'
  'disregard your instructions'
  'you are now'
  'new role:'
  'system prompt override'
)

for pattern in "${INJECTION_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qi "$pattern"; then
    echo "{\"decision\": \"block\", \"reason\": \"L1 violation: potential prompt injection detected\"}"
    exit 2
  fi
done

# L1: 認証情報の外部送信検出
if echo "$COMMAND" | grep -qE 'curl.*(-d|--data).*(_TOKEN|_KEY|_SECRET|PASSWORD)'; then
  echo '{"decision": "block", "reason": "L1 violation: potential credential exfiltration"}'
  exit 2
fi

echo '{"decision": "allow"}'
exit 0
