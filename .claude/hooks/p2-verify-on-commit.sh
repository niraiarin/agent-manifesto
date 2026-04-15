#!/usr/bin/env bash
# P2 Verification Hook — PreToolUse: Bash (git commit)
#
# 検証トークンがある → 通過（/verify の実行を構造的に検知）
# 1回目の高リスクコミット → 警告
# 2回目以降 → ブロック
#
# Critical files (CRITICAL_PATTERNS) additionally require evaluator_independent=true.
# This ensures VerificationIndependence.evaluatorIndependent for safety-critical changes.
#
# 検証トークン: .claude/metrics/p2-verified.jsonl
# TTL: 10 分
# @traces P2, E1, D2, VerificationIndependence
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
if ! echo "$COMMAND" | grep -qE 'git\s+commit'; then
exit 0
fi
# Resolve git working directory from command.
# Claude Code runs `cd /path/to/worktree && git commit ...` but the hook
# executes in the session CWD (main worktree). Extract the cd target so
# `git diff --cached` queries the correct worktree.
GIT_DIR=""
if echo "$COMMAND" | grep -qE '^[[:space:]]*cd[[:space:]]+'; then
GIT_DIR=$(echo "$COMMAND" | sed -n 's/^[[:space:]]*cd[[:space:]][[:space:]]*\("\([^"]*\)"\|\([^ &;]*\)\).*/\2\3/p')
fi
GIT_CMD=(git)
if [ -n "$GIT_DIR" ] && [ -d "$GIT_DIR" ]; then
GIT_CMD=(git -C "$GIT_DIR")
fi
STAGED=$("${GIT_CMD[@]}" diff --cached --name-only 2>/dev/null)
if [ -z "$STAGED" ]; then
exit 0
fi
# Config lookup: userConfig -> config.json -> default
_CONFIG_FILE="${CLAUDE_PLUGIN_DATA:-/dev/null}/config.json"
if [ -f "$_CONFIG_FILE" ] && jq -e '.HIGH_RISK_PATTERNS' "$_CONFIG_FILE" >/dev/null 2>&1; then
  HIGH_RISK_PATTERNS=$(jq -r '.HIGH_RISK_PATTERNS' "$_CONFIG_FILE")
else
  HIGH_RISK_PATTERNS='\.claude/|tests/|\.test\.|_test\.|settings\.json'
fi
HIGH_RISK_FILES=$(echo "$STAGED" | grep -E "$HIGH_RISK_PATTERNS" || true)
if [ -z "$HIGH_RISK_FILES" ]; then
exit 0
fi
VERIFIED_LOG=".claude/metrics/p2-verified.jsonl"
if [ -n "$GIT_DIR" ] && [ -f "$GIT_DIR/$VERIFIED_LOG" ]; then
VERIFIED_LOG="$GIT_DIR/$VERIFIED_LOG"
fi

# --- evaluatorIndependent enforcement for critical files ---
# CRITICAL_PATTERNS: subset of HIGH_RISK_PATTERNS requiring evaluator_independent=true.
# Hook only checks the field value; choice of independent means (Ollama, another API, human)
# is /verify SKILL.md's responsibility (normative layer).
CRITICAL_PATTERNS='\.claude/hooks/|\.claude/settings\.json|\.claude/settings\.local\.json'
CRITICAL_FILES=$(echo "$STAGED" | grep -E "$CRITICAL_PATTERNS" || true)
if [ -n "$CRITICAL_FILES" ] && [ -f "$VERIFIED_LOG" ]; then
  NOW=$(date +%s)
  TTL=600
  UNVERIFIED_CRITICAL=""
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    FOUND_INDEPENDENT=false
    while IFS= read -r line; do
      VERDICT=$(echo "$line" | jq -r '.verdict // empty' 2>/dev/null)
      EVAL_INDEP=$(echo "$line" | jq -r '.evaluator_independent // false' 2>/dev/null)
      if [ "$VERDICT" = "PASS" ] && [ "$EVAL_INDEP" = "true" ]; then
        EPOCH=$(echo "$line" | jq -r '.epoch // empty' 2>/dev/null)
        if [ -z "$EPOCH" ] || [ "$EPOCH" = "null" ]; then
          continue
        fi
        AGE=$(( NOW - EPOCH ))
        if [ "$AGE" -ge 0 ] && [ "$AGE" -le "$TTL" ]; then
          if echo "$line" | jq -e --arg file "$f" '.files | index($file)' >/dev/null 2>&1; then
            FOUND_INDEPENDENT=true
            break
          fi
        fi
      fi
    done < <(tac "$VERIFIED_LOG" 2>/dev/null || tail -r "$VERIFIED_LOG" 2>/dev/null)
    if [ "$FOUND_INDEPENDENT" = false ]; then
      UNVERIFIED_CRITICAL="${UNVERIFIED_CRITICAL}${f}
"
    fi
  done <<< "$CRITICAL_FILES"
  UNVERIFIED_CRITICAL=$(echo "$UNVERIFIED_CRITICAL" | sed '/^$/d')
  if [ -n "$UNVERIFIED_CRITICAL" ]; then
    echo "P2: Critical files require evaluatorIndependent verification." >&2
    echo "  Use Ollama, another API, or human review — subagent alone is insufficient." >&2
    echo "  Critical files without independent verification:" >&2
    echo "$UNVERIFIED_CRITICAL" | while IFS= read -r f; do
      [ -n "$f" ] && echo "    - $f" >&2
    done
    exit 2
  fi
fi
# --- end evaluatorIndependent enforcement ---

if [ -f "$VERIFIED_LOG" ]; then
NOW=$(date +%s)
TTL=600
UNVERIFIED=""
while IFS= read -r f; do
FOUND=false
while IFS= read -r line; do
VERDICT=$(echo "$line" | jq -r '.verdict // empty' 2>/dev/null)
if [ "$VERDICT" != "PASS" ]; then
continue
fi
EPOCH=$(echo "$line" | jq -r '.epoch // empty' 2>/dev/null)
if [ -z "$EPOCH" ] || [ "$EPOCH" = "null" ]; then
continue
fi
AGE=$(( NOW - EPOCH ))
if [ "$AGE" -ge 0 ] && [ "$AGE" -le "$TTL" ]; then
if echo "$line" | jq -e --arg file "$f" '.files | index($file)' >/dev/null 2>&1; then
FOUND=true
break
fi
fi
done < <(tac "$VERIFIED_LOG" 2>/dev/null || tail -r "$VERIFIED_LOG" 2>/dev/null)
if [ "$FOUND" = false ]; then
UNVERIFIED="${UNVERIFIED}${f}
"
fi
done <<< "$HIGH_RISK_FILES"
UNVERIFIED=$(echo "$UNVERIFIED" | sed '/^$/d')
if [ -z "$UNVERIFIED" ]; then
echo "P2: All high-risk files have valid verification tokens. Allowing commit." >&2
exit 0
fi
HIGH_RISK_FILES="$UNVERIFIED"
fi
SESSION=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null)
STATE_FILE="${TMPDIR:-/tmp}/p2-warned-${SESSION}"
if [ -f "$STATE_FILE" ]; then
echo "P2: High-risk commit blocked. Run /verify first, then retry." >&2
echo "Staged high-risk files (unverified):" >&2
echo "$HIGH_RISK_FILES" | while IFS= read -r f; do [ -n "$f" ] && echo "  - $f" >&2; done
exit 2
else
touch "$STATE_FILE"
echo "P2: High-risk files staged. Independent verification recommended." >&2
echo "  Run /verify before committing. Next attempt will be blocked." >&2
echo "Staged high-risk files (unverified):" >&2
echo "$HIGH_RISK_FILES" | while IFS= read -r f; do [ -n "$f" ] && echo "  - $f" >&2; done
exit 0
fi

# Traceability:
# E1: 検証独立性 — P2 検証トークンの有無で、独立検証を経たコミットかを判定
# D2: 認知的関心の分離 — 生成（Worker）と検証（Verifier）が分離されていることをコミット時に強制
# VerificationIndependence: CRITICAL_PATTERNS で evaluatorIndependent を構造的に強制
