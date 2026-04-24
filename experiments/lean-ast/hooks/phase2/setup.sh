#!/usr/bin/env bash
# Impl-E #669 Phase 2 — install lean-cli-route hook into .claude/settings.local.json
#
# .claude/settings.local.json is git-ignored; this install does NOT change
# the committed .claude/settings.json. The hook is registered under
# hooks.PreToolUse."Edit". An existing settings.local.json is merged via jq.
#
# USAGE:
#   bash experiments/lean-ast/hooks/phase2/setup.sh
#
# After running this script:
#   1. Start (or restart) Claude Code in the same project directory.
#   2. Before launching Claude Code, export LEAN_CLI_HOOK_TRACE_FILE so the
#      hook emits diagnostic trace entries:
#        export LEAN_CLI_HOOK_TRACE_FILE="$PWD/experiments/lean-ast/hooks/phase2/trace.log"
#        claude
#   3. Follow experiments/lean-ast/hooks/phase2/prompts.md to drive the
#      Claude Code session through three test scenarios.
#   4. Run experiments/lean-ast/hooks/phase2/verify.sh to check the
#      observed outcomes.
#   5. Run experiments/lean-ast/hooks/phase2/rollback.sh to uninstall.

set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

HOOK_SRC="experiments/lean-ast/hooks/lean-cli-route.sh"
HOOK_DST=".claude/hooks/lean-cli-route.sh"
SETTINGS=".claude/settings.local.json"
BACKUP=".claude/settings.local.json.phase2-backup"

# Pre-conditions
[[ -x "$HOOK_SRC" ]] || { echo "ERROR: hook source missing or not executable: $HOOK_SRC" >&2; exit 1; }
command -v jq >/dev/null || { echo "ERROR: jq not found on PATH" >&2; exit 1; }

# Ensure lean-cli binary is built
if [[ ! -x experiments/lean-ast/lean-cli/.lake/build/bin/lean-cli ]]; then
  echo "Building lean-cli (one-time)..."
  (cd experiments/lean-ast/lean-cli && lake build)
fi

# Copy hook into .claude/hooks/
mkdir -p .claude/hooks
cp "$HOOK_SRC" "$HOOK_DST"
chmod +x "$HOOK_DST"
echo "Installed hook: $HOOK_DST"

# Backup existing settings.local.json (if present)
if [[ -f "$SETTINGS" ]]; then
  cp "$SETTINGS" "$BACKUP"
  echo "Backed up existing $SETTINGS -> $BACKUP"
else
  printf '{}\n' > "$SETTINGS"
  : > "$BACKUP"   # empty backup file signals "did not exist before"
  echo "Created fresh $SETTINGS"
fi

# Merge hook entry using jq. We register under hooks.PreToolUse.Edit.
# If an entry for this exact command already exists, do not duplicate.
HOOK_CMD="bash \$CLAUDE_PROJECT_DIR/.claude/hooks/lean-cli-route.sh"
updated=$(jq --arg cmd "$HOOK_CMD" '
  .hooks //= {} |
  .hooks.PreToolUse //= {} |
  .hooks.PreToolUse.Edit //= [] |
  if any(.hooks.PreToolUse.Edit[]; .command == $cmd)
  then .
  else .hooks.PreToolUse.Edit += [{command: $cmd}]
  end
' "$SETTINGS")
printf '%s\n' "$updated" > "$SETTINGS"
echo "Registered hook in $SETTINGS"

# Create fixture directory for Phase 2 tests
FIX_DIR="experiments/lean-ast/hooks/phase2/fixtures"
rm -rf "$FIX_DIR" "$FIX_DIR"/../trace.log 2>/dev/null || true
mkdir -p "$FIX_DIR"

cat > "$FIX_DIR/P1-axiom.lean" <<'EOF'
axiom foo : Nat
axiom bar : Bool
EOF

cat > "$FIX_DIR/P2-non-lean.txt" <<'EOF'
hello phase2
EOF

cat > "$FIX_DIR/P3-unsupported-pattern.lean" <<'EOF'
namespace Phase2

axiom foo : Nat

end Phase2
EOF

# Snapshot pre-state for verify.sh
mkdir -p "$FIX_DIR/.pre"
for f in "$FIX_DIR"/P1-axiom.lean "$FIX_DIR"/P2-non-lean.txt "$FIX_DIR"/P3-unsupported-pattern.lean; do
  cp "$f" "$FIX_DIR/.pre/$(basename "$f")"
done

echo "Created fixtures in $FIX_DIR"
echo
echo "Next steps:"
echo "  1. Export trace file env and start Claude Code:"
echo "       export LEAN_CLI_HOOK_TRACE_FILE=\"$PWD/experiments/lean-ast/hooks/phase2/trace.log\""
echo "       claude"
echo "  2. Follow experiments/lean-ast/hooks/phase2/prompts.md"
echo "  3. When done, run: bash experiments/lean-ast/hooks/phase2/verify.sh"
echo "  4. Finally: bash experiments/lean-ast/hooks/phase2/rollback.sh"
