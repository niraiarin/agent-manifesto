#!/usr/bin/env bash
# Prerequisites Check — SessionStart
#
# Plugin の前提条件を自動チェックし、不足時に additionalContext で
# 具体的なガイドを注入する。silent failure を排除する。
# @traces P4, D3, L1

ALERTS=""
CRITICAL=0

# --- Required tools ---

if ! command -v jq >/dev/null 2>&1; then
  ALERTS="${ALERTS}CRITICAL: jq is not installed. 16/19 hooks depend on jq and will silently fail.\n  Install: brew install jq (macOS) / apt install jq (Linux)\n\n"
  CRITICAL=$((CRITICAL + 1))
fi

if ! command -v git >/dev/null 2>&1; then
  ALERTS="${ALERTS}CRITICAL: git is not installed. Path resolution for metrics and hooks will fail.\n  Install: https://git-scm.com/downloads\n\n"
  CRITICAL=$((CRITICAL + 1))
fi

# --- Auto-fix: metrics directory ---

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo ".")"
METRICS_DIR="$PROJECT_ROOT/.claude/metrics"

if [ ! -d "$METRICS_DIR" ]; then
  mkdir -p "$METRICS_DIR" 2>/dev/null
  if [ -d "$METRICS_DIR" ]; then
    ALERTS="${ALERTS}AUTO-FIX: Created .claude/metrics/ directory for P4 observability logging.\n\n"
  else
    ALERTS="${ALERTS}WARNING: Could not create .claude/metrics/ — P4 metrics will not be recorded.\n  Create manually: mkdir -p .claude/metrics/\n\n"
  fi
fi

# --- Optional: domain prerequisites ---

if [ ! -d "$PROJECT_ROOT/lean-formalization" ]; then
  ALERTS="${ALERTS}INFO: lean-formalization/ not found. Domain-specific skills (formal-derivation, ground-axiom, instantiate-model, trace) will not function.\n  To use: git submodule add <manifesto-repo> lean-formalization\n\n"
fi

if ! command -v lake >/dev/null 2>&1; then
  if [ -d "$PROJECT_ROOT/lean-formalization" ]; then
    ALERTS="${ALERTS}WARNING: lake (Lean 4) is not installed but lean-formalization/ exists. Lean build will fail.\n  Install: https://leanprover-community.github.io/install/\n\n"
  fi
fi

# --- Optional: environment variables ---

if [ -z "${CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS:-}" ]; then
  ALERTS="${ALERTS}INFO: CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS is not set. /evolve skill (Agent Teams) will not function.\n  To enable: export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1\n\n"
fi

# --- Output ---

if [ -z "$ALERTS" ]; then
  exit 0
fi

# Build stop guidance for critical issues
STOP_MSG=""
if [ "$CRITICAL" -gt 0 ]; then
  STOP_MSG="STOP: $CRITICAL critical prerequisite(s) missing. Hooks will silently fail until resolved. Fix the CRITICAL items above before proceeding."
fi

CONTEXT="PLUGIN PREREQUISITES CHECK:\n${ALERTS}${STOP_MSG}"
ESCAPED=$(printf '%b' "$CONTEXT" | jq -Rs . 2>/dev/null || printf '"%s"' "Prerequisites check failed — jq not available for JSON escaping. Install jq first.")

cat << JSON
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": $ESCAPED
  }
}
JSON
