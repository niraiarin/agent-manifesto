#!/usr/bin/env bash
BASE="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
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
