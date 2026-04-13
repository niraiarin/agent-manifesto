#!/usr/bin/env bash
# @traces T1, T2, D1, D10, P4
# SessionStart hook: inject handoff resume into LLM context via additionalContext
# Pattern: same as p4-drift-detector.sh (proven mechanism)
# #514: branch-aware scoped file selection + branch matching
set -uo pipefail

BASE="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
HANDOFF_DIR="${HANDOFF_DIR:-$BASE/.claude/handoffs}"

# --- Scoped file selection (#514 G2) ---
# 1. Try branch-scoped file: handoff-resume-<branch>.md (slash→hyphen)
# 2. Fallback to handoff-resume.md (backward compat)
CURRENT_BRANCH=$(cd "$BASE" && git branch --show-current 2>/dev/null || echo "")
SCOPED_NAME=""
if [ -n "$CURRENT_BRANCH" ]; then
  SCOPED_NAME=$(echo "$CURRENT_BRANCH" | sed 's|/|-|g')
fi

RESUME_FILE=""
if [ -n "$SCOPED_NAME" ] && [ -f "$HANDOFF_DIR/handoff-resume-${SCOPED_NAME}.md" ]; then
  RESUME_FILE="$HANDOFF_DIR/handoff-resume-${SCOPED_NAME}.md"
elif [ -f "$HANDOFF_DIR/handoff-resume.md" ]; then
  RESUME_FILE="$HANDOFF_DIR/handoff-resume.md"
fi

CONTEXT=""

# --- Handoff resume injection ---
if [ -n "$RESUME_FILE" ]; then
  # Extract branch from resume file (#514 G1: branch matching)
  RESUME_BRANCH=$(grep -m1 '^branch:' "$RESUME_FILE" | sed 's/^branch:[[:space:]]*//')

  # Branch matching: skip injection if branch mismatch
  SKIP_INJECTION=false
  if [ -n "$RESUME_BRANCH" ] && [ "$RESUME_BRANCH" != "null" ]; then
    if [ -n "$CURRENT_BRANCH" ] && [ "$RESUME_BRANCH" != "$CURRENT_BRANCH" ]; then
      echo "[HANDOFF] skipped: for branch $RESUME_BRANCH, current is $CURRENT_BRANCH" >&2
      SKIP_INJECTION=true
    fi
    # If current is detached HEAD (empty), allow injection (conservative)
  fi
  # If RESUME_BRANCH is empty or "null", allow injection (backward compat / detached HEAD)

  if [ "$SKIP_INJECTION" = false ]; then
    # Extract git_sha from resume file
    RESUME_SHA=$(grep -m1 '^git_sha:' "$RESUME_FILE" | sed 's/^git_sha:[[:space:]]*//')
    CURRENT_SHA=$(cd "$BASE" && git rev-parse HEAD 2>/dev/null || echo "unknown")

    RESUME_CONTENT=$(cat "$RESUME_FILE")

    if [ "$RESUME_SHA" = "$CURRENT_SHA" ]; then
      CONTEXT="[HANDOFF RESUME] Previous session state restored.\n$RESUME_CONTENT"
    else
      CONTEXT="[HANDOFF RESUME - SHA MISMATCH WARNING] git_sha changed since handoff (was: $RESUME_SHA, now: $CURRENT_SHA). Commits occurred after handoff — intent/progress are likely valid but file state may have changed. Verify before proceeding.\n$RESUME_CONTENT"
    fi

    # Rename to .injected to prevent double injection (D1: structural enforcement)
    if ! mv "$RESUME_FILE" "${RESUME_FILE}.injected" 2>/dev/null; then
      echo "[HANDOFF] WARNING: failed to rename $RESUME_FILE to .injected" >&2
    fi
  fi
fi

# --- Sorry count check (integrated from evolve-state-loader.sh) ---
if [ -d "$BASE/lean-formalization/Manifest" ]; then
  SORRY_COUNT=$(grep -rn "^\s*sorry\s*$\|:=\s*sorry" "$BASE/lean-formalization/Manifest/" --include="*.lean" 2>/dev/null | grep -v -- "--" | grep -v "/-" | wc -l | tr -d ' ')
  if [ "$SORRY_COUNT" -gt 0 ] 2>/dev/null; then
    CONTEXT="$CONTEXT\n[WARNING] $SORRY_COUNT sorry found in Lean formalization"
  fi
fi

# --- Evolve last run (integrated from evolve-state-loader.sh) ---
HISTORY_FILE="$BASE/.claude/metrics/evolve-history.jsonl"
if [ -f "$HISTORY_FILE" ]; then
  LAST_RUN=$(tail -1 "$HISTORY_FILE" 2>/dev/null)
  if [ -n "$LAST_RUN" ]; then
    TIMESTAMP=$(echo "$LAST_RUN" | grep -o '"timestamp":"[^"]*"' | head -1 | cut -d'"' -f4)
    CONTEXT="$CONTEXT\n[evolve] Last run: $TIMESTAMP"
  fi
fi

# --- Output via additionalContext if there's anything to inject ---
if [ -n "$CONTEXT" ]; then
  # Escape for JSON: prefer python3, fallback to basic sed
  ESCAPED=$(printf '%b' "$CONTEXT" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))" 2>/dev/null | sed 's/^"//;s/"$//')
  if [ -z "$ESCAPED" ]; then
    # python3 not available: basic JSON escaping
    ESCAPED=$(printf '%b' "$CONTEXT" | sed 's/\\/\\\\/g; s/"/\\"/g; s/	/\\t/g' | tr '\n' ' ')
    echo "[handoff-resume-loader] WARNING: python3 not found, using basic escaping" >&2
  fi
  cat << JSON
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "$ESCAPED"
  }
}
JSON
fi

exit 0

# Traceability:
# T1: handoff は T1 のインスタンス消滅を前提に設計
# T2: handoff-resume.md に状態を永続化し次インスタンスに引き継ぐ
# D1: .injected リネームで二重注入を構造的に防止
# D10: エージェント消滅後も構造（handoff ログ）が残る
# P4: sorry-count と evolve 最終実行をセッション開始時に通知
