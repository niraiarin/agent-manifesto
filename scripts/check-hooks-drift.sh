#!/usr/bin/env bash
# check-hooks-drift.sh — Detect drift between settings.json and plugin hooks.json
#
# Compares hook script references in .claude/settings.json against
# the exported plugin's hooks/hooks.json. Reports missing and extra entries.
# Exit 0 = in sync, Exit 1 = drift detected.
# @traces P4, D13

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SETTINGS_JSON="$PROJECT_ROOT/.claude/settings.json"

# Plugin repo path: argument or env var
PLUGINS_REPO="${1:-${CLAUDE_PLUGINS_REPO:-}}"
PLUGIN_NAME="${2:-agent-manifesto-base}"

if [ -z "$PLUGINS_REPO" ]; then
  echo "Usage: $0 <plugins-repo-path> [plugin-name]"
  echo "  or set CLAUDE_PLUGINS_REPO environment variable"
  exit 2
fi

HOOKS_JSON="$PLUGINS_REPO/$PLUGIN_NAME/hooks/hooks.json"

if [ ! -f "$SETTINGS_JSON" ]; then
  echo "ERROR: settings.json not found: $SETTINGS_JSON" >&2
  exit 2
fi

if [ ! -f "$HOOKS_JSON" ]; then
  echo "ERROR: hooks.json not found: $HOOKS_JSON" >&2
  exit 2
fi

# Extract script names from settings.json hooks
SETTINGS_SCRIPTS=$(python3 -c "
import json, re, sys
with open('$SETTINGS_JSON') as f:
    data = json.load(f)
scripts = set()
for event, matchers in data.get('hooks', {}).items():
    for matcher in matchers:
        for hook in matcher.get('hooks', []):
            m = re.search(r'/([^/]+\.sh)', hook.get('command', ''))
            if m: scripts.add(m.group(1))
for s in sorted(scripts): print(s)
" 2>/dev/null)

# Extract script names from hooks.json
HOOKS_SCRIPTS=$(python3 -c "
import json, re, sys
with open('$HOOKS_JSON') as f:
    data = json.load(f)
scripts = set()
for event, matchers in data.get('hooks', {}).items():
    for matcher in matchers:
        for hook in matcher.get('hooks', []):
            m = re.search(r'/([^/]+\.sh)', hook.get('command', ''))
            if m: scripts.add(m.group(1))
for s in sorted(scripts): print(s)
" 2>/dev/null)

# Known plugin-only hooks (not in settings.json by design)
PLUGIN_ONLY="prerequisites-check.sh rules-injector.sh"

# Compare
MISSING=""
EXTRA=""

while IFS= read -r script; do
  [ -z "$script" ] && continue
  if ! echo "$HOOKS_SCRIPTS" | grep -qx "$script"; then
    MISSING="$MISSING  $script\n"
  fi
done <<< "$SETTINGS_SCRIPTS"

while IFS= read -r script; do
  [ -z "$script" ] && continue
  # Skip known plugin-only hooks
  is_plugin_only=false
  for po in $PLUGIN_ONLY; do
    if [ "$script" = "$po" ]; then
      is_plugin_only=true
      break
    fi
  done
  $is_plugin_only && continue

  if ! echo "$SETTINGS_SCRIPTS" | grep -qx "$script"; then
    EXTRA="$EXTRA  $script (in hooks.json but not in settings.json)\n"
  fi
done <<< "$HOOKS_SCRIPTS"

# Also check that all referenced scripts exist as files
SCRIPTS_DIR="$PLUGINS_REPO/$PLUGIN_NAME/hooks/scripts"
MISSING_FILES=""
while IFS= read -r script; do
  [ -z "$script" ] && continue
  if [ ! -f "$SCRIPTS_DIR/$script" ]; then
    MISSING_FILES="$MISSING_FILES  $script\n"
  elif [ ! -x "$SCRIPTS_DIR/$script" ]; then
    MISSING_FILES="$MISSING_FILES  $script (exists but not executable)\n"
  fi
done <<< "$HOOKS_SCRIPTS"

# Report
DRIFT=0

if [ -n "$MISSING" ]; then
  echo "DRIFT: hooks in settings.json but NOT in hooks.json:"
  printf "$MISSING"
  DRIFT=1
fi

if [ -n "$EXTRA" ]; then
  echo "DRIFT: hooks in hooks.json but NOT in settings.json (not plugin-only):"
  printf "$EXTRA"
  DRIFT=1
fi

if [ -n "$MISSING_FILES" ]; then
  echo "MISSING FILES:"
  printf "$MISSING_FILES"
  DRIFT=1
fi

if [ "$DRIFT" -eq 0 ]; then
  SETTINGS_COUNT=$(echo "$SETTINGS_SCRIPTS" | grep -c '.' || true)
  HOOKS_COUNT=$(echo "$HOOKS_SCRIPTS" | grep -c '.' || true)
  PLUGIN_ONLY_COUNT=$(echo "$PLUGIN_ONLY" | wc -w | tr -d ' ')
  echo "OK: settings.json ($SETTINGS_COUNT hooks) and hooks.json ($HOOKS_COUNT hooks, incl. $PLUGIN_ONLY_COUNT plugin-only) are in sync."
fi

exit $DRIFT
