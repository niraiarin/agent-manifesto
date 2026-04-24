#!/usr/bin/env bash
# Impl-E #669 Phase 2 — rollback: uninstall hook and restore settings.local.json.
#
# USAGE:
#   bash experiments/lean-ast/hooks/phase2/rollback.sh

set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

HOOK_DST=".claude/hooks/lean-cli-route.sh"
SETTINGS=".claude/settings.local.json"
BACKUP=".claude/settings.local.json.phase2-backup"
FIX_DIR="experiments/lean-ast/hooks/phase2/fixtures"

# Remove installed hook
if [[ -f "$HOOK_DST" ]]; then
  rm -f "$HOOK_DST"
  echo "Removed $HOOK_DST"
fi

# Restore settings.local.json from backup
if [[ -f "$BACKUP" ]]; then
  if [[ -s "$BACKUP" ]]; then
    cp "$BACKUP" "$SETTINGS"
    echo "Restored $SETTINGS from $BACKUP"
  else
    rm -f "$SETTINGS"
    echo "Removed $SETTINGS (did not exist before setup)"
  fi
  rm -f "$BACKUP"
fi

# Optional: clean up fixtures and trace log
if [[ -d "$FIX_DIR" ]]; then
  rm -rf "$FIX_DIR"
  echo "Removed fixtures $FIX_DIR"
fi
rm -f experiments/lean-ast/hooks/phase2/trace.log

echo
echo "Rollback complete. You may restart Claude Code to detach the hook from settings."
