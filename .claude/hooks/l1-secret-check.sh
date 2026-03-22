#!/usr/bin/env bash
# L1 Secret Check Hook (PostToolUse: git add)
# D1: 秘密情報コミットの構造的禁止

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# git add の後、ステージングされたファイルに秘密情報がないかチェック
STAGED=$(git diff --cached --name-only 2>/dev/null || true)

SECRET_PATTERNS=('.env' '.env.local' '.env.production' 'credentials.json' 'serviceAccountKey' '.pem' 'id_rsa' 'id_ed25519')

for file in $STAGED; do
  for pattern in "${SECRET_PATTERNS[@]}"; do
    if echo "$file" | grep -qi "$pattern"; then
      echo "{\"decision\": \"block\", \"reason\": \"L1 violation: staged file matches secret pattern: $file\"}"
      exit 2
    fi
  done
done

echo '{"decision": "allow"}'
exit 0
