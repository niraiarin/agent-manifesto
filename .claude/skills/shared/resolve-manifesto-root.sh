#!/usr/bin/env bash
# resolve-manifesto-root.sh — Locate the agent-manifesto repository root.
#
# Usage: MANIFESTO_ROOT=$(bash /path/to/resolve-manifesto-root.sh)
#
# Resolution order:
#   1. Current directory has lean-formalization/Manifest.lean (we ARE in the repo)
#   2. $AGENT_MANIFESTO_ROOT environment variable
#   3. Sibling directories (../agent-manifesto, ../../agent-manifesto)
#   4. Git submodule named agent-manifesto
#   5. Fail with setup instructions
#
# Validation: candidate must contain lean-formalization/Manifest.lean
# Exit 0 + stdout path on success, exit 1 + stderr instructions on failure.

set -euo pipefail

validate() {
  [ -f "$1/lean-formalization/Manifest.lean" ]
}

# 1. Current directory
if validate "."; then
  echo "$(pwd)"
  exit 0
fi

# Also check git root (in case CWD is a subdirectory)
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [ -n "$GIT_ROOT" ] && validate "$GIT_ROOT"; then
  echo "$GIT_ROOT"
  exit 0
fi

# 2. Environment variable
if [ -n "${AGENT_MANIFESTO_ROOT:-}" ] && validate "$AGENT_MANIFESTO_ROOT"; then
  echo "$AGENT_MANIFESTO_ROOT"
  exit 0
fi

# 3. Sibling / parent directories
for candidate in \
  "../agent-manifesto" \
  "../../agent-manifesto" \
  "${GIT_ROOT:+$GIT_ROOT/../agent-manifesto}"; do
  [ -z "$candidate" ] && continue
  if [ -d "$candidate" ] && validate "$candidate"; then
    echo "$(cd "$candidate" && pwd)"
    exit 0
  fi
done

# 4. Git submodule
if [ -n "$GIT_ROOT" ] && [ -f "$GIT_ROOT/.gitmodules" ]; then
  SUB_PATH=$(git -C "$GIT_ROOT" config --file .gitmodules --get-regexp 'submodule\..*\.path' \
    | grep 'agent-manifesto' | awk '{print $2}' || true)
  if [ -n "$SUB_PATH" ] && validate "$GIT_ROOT/$SUB_PATH"; then
    echo "$(cd "$GIT_ROOT/$SUB_PATH" && pwd)"
    exit 0
  fi
fi

# 5. Fail
cat >&2 <<'MSG'
agent-manifesto repository not found.

Setup options:
  1. Set environment variable:
     export AGENT_MANIFESTO_ROOT=/path/to/agent-manifesto

  2. Clone as sibling directory:
     cd .. && git clone git@github.com:niraiarin/agent-manifesto.git

  3. Add as git submodule:
     git submodule add git@github.com:niraiarin/agent-manifesto.git
MSG
exit 1
