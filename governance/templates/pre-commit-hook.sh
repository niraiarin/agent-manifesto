#!/usr/bin/env bash
# Pre-commit hook template (Day 179 Phase 3 acceptance #4 — Local CI gate)
#
# Install:
#   cp governance/templates/pre-commit-hook.sh .git/hooks/pre-commit
#   chmod +x .git/hooks/pre-commit
#
# What it runs (in order, fail-fast):
#   1. scripts/cycle-check.sh — Check 1-24 governance hygiene
#   2. (optional) lake build — Lean lib verify (uncomment if Lean lib in repo)
#
# Bypass: git commit --no-verify  (use sparingly — bypass leaves no audit trail)

set -e

REPO_ROOT="$( git rev-parse --show-toplevel 2>/dev/null )"
if [ -z "$REPO_ROOT" ]; then
  echo "pre-commit: not in git repo, skip" >&2
  exit 0
fi

cd "$REPO_ROOT"

# 1. cycle-check (mandatory)
if [ -f "scripts/cycle-check.sh" ]; then
  echo "pre-commit: running cycle-check..."
  if ! bash scripts/cycle-check.sh; then
    echo "pre-commit: cycle-check FAIL — fix before committing" >&2
    echo "  (override with 'git commit --no-verify' if intentional)" >&2
    exit 1
  fi
fi

# 2. lake build (optional, uncomment if Lean lib exists)
# if [ -f "agent-spec-lib/lakefile.lean" ]; then
#   echo "pre-commit: running lake build..."
#   if ! (cd agent-spec-lib && lake build); then
#     echo "pre-commit: lake build FAIL" >&2
#     exit 1
#   fi
# fi

echo "pre-commit: PASS"
