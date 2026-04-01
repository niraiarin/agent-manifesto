#!/usr/bin/env bash
# check-lean-imports.sh — Manifest.lean の import 整合性チェック
#
# Manifest.lean の各 import 行に対応する .lean ファイルが存在することを検証する。
# ファイルが消失した場合に即座に検出し、ビルド前にブロックする。
#
# Usage: bash scripts/check-lean-imports.sh
#   Exit 0: 全 import に対応ファイルあり
#   Exit 1: 不整合あり（ファイル消失）

set -euo pipefail

BASE="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST_LEAN="$BASE/lean-formalization/Manifest.lean"
LEAN_BASE="$BASE/lean-formalization"
ERRORS=0

if [[ ! -f "$MANIFEST_LEAN" ]]; then
  echo "ERROR: Manifest.lean not found at $MANIFEST_LEAN" >&2
  exit 1
fi

echo "=== Lean Import Integrity Check ==="

while IFS= read -r line; do
  # import Manifest.Foo.Bar -- comment → Manifest/Foo/Bar.lean
  module=$(echo "$line" | sed 's/^import //; s/ *--.*//; s/[[:space:]]*$//' | tr '.' '/')
  lean_file="$LEAN_BASE/${module}.lean"

  if [[ ! -f "$lean_file" ]]; then
    echo "ERROR: Missing file for import: $line" >&2
    echo "  Expected: $lean_file" >&2
    ERRORS=$((ERRORS + 1))
  fi
done < <(grep '^import Manifest\.' "$MANIFEST_LEAN")

# Reverse check: .lean files in Manifest/ that are NOT imported
while IFS= read -r lean_file; do
  filename=$(basename "$lean_file" .lean)
  # Skip Foundation/* (imported via Foundation.lean or sub-imports)
  [[ "$lean_file" == *"/Foundation/"* ]] && continue
  # Skip Models/* (imported via Models.lean or sub-imports)
  [[ "$lean_file" == *"/Models/"* ]] && continue

  if ! grep -q "import Manifest\\.${filename}" "$MANIFEST_LEAN" 2>/dev/null; then
    echo "WARN: $lean_file exists but is not imported in Manifest.lean" >&2
  fi
done < <(find "$LEAN_BASE/Manifest" -maxdepth 1 -name "*.lean" -not -name "Manifest.lean" 2>/dev/null)

if [[ $ERRORS -gt 0 ]]; then
  echo ""
  echo "FAILED: $ERRORS import(s) have no corresponding file." >&2
  echo "This usually means a .lean file was deleted or not created." >&2
  echo "Fix: recreate the file or remove the import from Manifest.lean." >&2
  exit 1
fi

echo "✓ All imports have corresponding files."
exit 0
