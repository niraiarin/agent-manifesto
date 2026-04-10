#!/usr/bin/env bash
# p4-manifest-refs-check.sh — artifact-manifest.json の refs 整合性を commit 前に検証
# PreToolUse: Bash (git commit) で発動
# P4 (可観測性) + D13 (影響波及) の構造的強制
# @traces P4, D1, D13

set -euo pipefail

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || true)

# git commit 以外はスキップ
case "$CMD" in
  git\ commit*) ;;
  *) exit 0 ;;
esac

# artifact-manifest.json が staged されていなければスキップ
if ! git diff --cached --name-only 2>/dev/null | grep -q "artifact-manifest.json"; then
  exit 0
fi

MANIFEST="artifact-manifest.json"
if [ ! -f "$MANIFEST" ]; then
  exit 0
fi

ERRORS=""

# 1. JSON パース可能か
if ! jq empty "$MANIFEST" 2>/dev/null; then
  echo "artifact-manifest.json is not valid JSON" >&2
  exit 2
fi

# 2. propositions リストを取得
PROPOSITIONS=$(jq -r '.propositions[]' "$MANIFEST" 2>/dev/null)

# 3. 全エントリの refs が propositions に含まれるか検証
INVALID_REFS=$(jq -r '.artifacts[] | .id as $id | .refs[]? | . as $ref | select(. != "") | "\($id):\($ref)"' "$MANIFEST" | while IFS=: read -r id ref; do
  if ! echo "$PROPOSITIONS" | grep -qx "$ref"; then
    echo "  $id refs '$ref' which is not in propositions list"
  fi
done)

if [ -n "$INVALID_REFS" ]; then
  ERRORS="${ERRORS}refs reference undeclared propositions:\n${INVALID_REFS}\n"
fi

# 4. 全エントリの path が存在するか検証（data ファイルは除外 — 動的生成）
MISSING_FILES=$(jq -r '.artifacts[] | select(.type != "data") | "\(.id):\(.path)"' "$MANIFEST" | while IFS=: read -r id path; do
  if [ ! -e "$path" ]; then
    echo "  $id path '$path' does not exist"
  fi
done)

if [ -n "$MISSING_FILES" ]; then
  ERRORS="${ERRORS}artifact paths not found:\n${MISSING_FILES}\n"
fi

# 5. id の重複チェック
DUPES=$(jq -r '.artifacts[].id' "$MANIFEST" | sort | uniq -d)
if [ -n "$DUPES" ]; then
  ERRORS="${ERRORS}duplicate artifact ids: ${DUPES}\n"
fi

if [ -n "$ERRORS" ]; then
  echo -e "P4: artifact-manifest.json validation failed:\n${ERRORS}" >&2
  exit 2
fi

exit 0

# Traceability:
# D1: 構造的強制 — artifact-manifest.json の refs が ontology の命題に存在するか自動検証
