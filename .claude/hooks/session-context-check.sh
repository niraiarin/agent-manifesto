#!/usr/bin/env bash
# @traces D1, T2
# Session start: emit pwd / git branch / worktree count as additional context.
# Structurally enforces CLAUDE.md session startup check (D1).

set -uo pipefail

PWD_VAL=$(pwd)
BRANCH=$(git branch --show-current 2>/dev/null || echo "not-a-repo")
WORKTREE_COUNT=$(git worktree list 2>/dev/null | wc -l | tr -d ' ')

echo "[session] pwd=$PWD_VAL"
echo "[session] branch=$BRANCH"
if [ "$WORKTREE_COUNT" -gt 0 ] 2>/dev/null; then
  echo "[session] worktrees=$WORKTREE_COUNT"
fi

# Traceability:
# D1: 構造的強制 — セッション開始時の位置確認を hook で保証
# T2: 構造永続性 — 確認事項を LLM 判断ではなく構造が提供
