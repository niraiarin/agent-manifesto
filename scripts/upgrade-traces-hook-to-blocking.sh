#!/usr/bin/env bash
# upgrade-traces-hook-to-blocking.sh — @traces 整合性 hook を WARNING → BLOCKING に昇格
# 人間が実行: bash scripts/upgrade-traces-hook-to-blocking.sh
set -euo pipefail

BASE="$(git rev-parse --show-toplevel)"
HOOK="$BASE/.claude/hooks/p4-traces-integrity-check.sh"

if [ ! -f "$HOOK" ]; then
  echo "ERROR: $HOOK not found" >&2
  exit 1
fi

# @traces 不在時: exit 0 → exit 2 (block)
sed -i '' '/WARNING.*@traces がありません/{n;s/exit 0/exit 2/;}' "$HOOK"

# @traces ↔ refs 不一致時: exit 0 → exit 2 (block)
sed -i '' '/WARNING.*@traces.*refs.*不一致/{n;n;n;s/exit 0/exit 2/;}' "$HOOK"

echo "Upgraded to BLOCKING mode: $HOOK"
echo "Verify:"
grep -n 'exit' "$HOOK"
