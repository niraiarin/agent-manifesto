#!/usr/bin/env bash
# @traces P3, T2, D10
set -uo pipefail
BASE="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
HISTORY_FILE="$BASE/.claude/metrics/evolve-history.jsonl"
if [ -f "$HISTORY_FILE" ]; then
  LAST_RUN=$(tail -1 "$HISTORY_FILE" 2>/dev/null)
  if [ -n "$LAST_RUN" ]; then
    TIMESTAMP=$(echo "$LAST_RUN" | grep -o '"timestamp":"[^"]*"' | head -1 | cut -d'"' -f4)
    echo "[evolve] Last run: $TIMESTAMP"
  fi
fi
if [ -d "$BASE/lean-formalization/Manifest" ]; then
  SORRY_COUNT=$(grep -rn "^\s*sorry\s*$\|:=\s*sorry" "$BASE/lean-formalization/Manifest/" --include="*.lean" 2>/dev/null | grep -v -- "--" | grep -v "/-" | wc -l | tr -d ' ')
  if [ "$SORRY_COUNT" -gt 0 ] 2>/dev/null; then
    echo "[evolve] WARNING: $SORRY_COUNT sorry found in Lean formalization"
  fi
fi

# Traceability:
# P3: 学習の統治 — /evolve セッション開始時に前回の状態を復元し、学習の継続性を保証 # T2: 構造永続性 — evolve-history.jsonl から構造に蓄積された学習履歴を読み出す # D10: 構造永続性 — エージェント消滅後も構造（ログ）が残ることを前提に状態復元を実現
