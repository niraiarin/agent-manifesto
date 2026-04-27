#!/usr/bin/env bash
# governance toolkit installer (Day 176 Phase 3 Theme C4)
# Use case 4: Claude Code governance pattern を別 project に install
#
# usage:
#   bash install.sh <target-project-root>
#
# Installs:
#   - .claude/hooks/{l1-file-guard,l1-safety-check,p2-verify-on-commit}.sh
#   - scripts/{cycle-check,check-doc-length}.sh
#   - templates/artifact-manifest.schema.json (if user opts in)
#
# Required at target:
#   - jq (1.6+)
#   - bash 4+
#   - git
#   - shasum (macOS) or sha256sum (linux)
#
# Optional integrations:
#   - .claude/settings.json hook configuration (sample below)
#   - pre-commit hook (.git/hooks/pre-commit)

set -euo pipefail

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
  echo "Usage: bash install.sh <target-project-root>" >&2
  echo "Example: bash install.sh /path/to/your-project" >&2
  exit 64
fi

if [ ! -d "$TARGET" ]; then
  echo "ERROR: target directory $TARGET does not exist" >&2
  exit 1
fi

if [ ! -d "$TARGET/.git" ]; then
  echo "WARN: target is not a git repository ($TARGET/.git not found)" >&2
fi

SOURCE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "=== governance toolkit installer ==="
echo "source: $SOURCE_DIR"
echo "target: $TARGET"
echo

# 1. .claude/hooks/
mkdir -p "$TARGET/.claude/hooks"
for hook in l1-file-guard.sh l1-safety-check.sh p2-verify-on-commit.sh; do
  if [ -f "$TARGET/.claude/hooks/$hook" ]; then
    echo "SKIP $hook (already exists at target — backup as $hook.bak first if you want to overwrite)"
  else
    cp "$SOURCE_DIR/hooks/$hook" "$TARGET/.claude/hooks/"
    chmod +x "$TARGET/.claude/hooks/$hook"
    echo "INSTALL .claude/hooks/$hook"
  fi
done

# 2. scripts/
mkdir -p "$TARGET/scripts"
for script in cycle-check.sh check-doc-length.sh; do
  if [ -f "$TARGET/scripts/$script" ]; then
    echo "SKIP $script (already exists at target)"
  else
    cp "$SOURCE_DIR/scripts/$script" "$TARGET/scripts/"
    chmod +x "$TARGET/scripts/$script"
    echo "INSTALL scripts/$script"
  fi
done

# 3. .claude/metrics/ (空ディレクトリ + .gitkeep)
mkdir -p "$TARGET/.claude/metrics/cycle-check-runs"
[ -f "$TARGET/.claude/metrics/.gitkeep" ] || touch "$TARGET/.claude/metrics/.gitkeep"
echo "INSTALL .claude/metrics/ (empty)"

# 4. settings.json sample
SAMPLE_SETTINGS="$TARGET/.claude/settings.governance.sample.json"
cat > "$SAMPLE_SETTINGS" <<'SETTINGS_EOF'
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {"type": "command", "command": "bash $CLAUDE_PROJECT_DIR/.claude/hooks/l1-file-guard.sh"}
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          {"type": "command", "command": "bash $CLAUDE_PROJECT_DIR/.claude/hooks/l1-safety-check.sh"},
          {"type": "command", "command": "bash $CLAUDE_PROJECT_DIR/.claude/hooks/p2-verify-on-commit.sh"}
        ]
      }
    ]
  }
}
SETTINGS_EOF
echo "SAMPLE .claude/settings.governance.sample.json (merge into your settings.json)"

echo
echo "=== installation complete ==="
echo
echo "Next steps:"
echo "  1. Merge .claude/settings.governance.sample.json into .claude/settings.json"
echo "  2. (Optional) Set up pre-commit hook to run cycle-check.sh:"
echo "       cp $TARGET/scripts/cycle-check.sh $TARGET/.git/hooks/pre-commit"
echo "       chmod +x $TARGET/.git/hooks/pre-commit"
echo "  3. Read $SOURCE_DIR/README.md for governance design rationale"
echo "  4. Read $SOURCE_DIR/USAGE.md for runtime workflow"
