#!/usr/bin/env bash
# Plugin Packager Script
# .claude/ の現在の構成を dist/agent-manifesto-plugin/ にパッケージ化する。
#
# Usage: bash .claude/skills/package-plugin/scripts/package.sh [version]
# Example: bash .claude/skills/package-plugin/scripts/package.sh 0.3.0

set -euo pipefail

VERSION="${1:-}"
BASE="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SRC="$BASE/.claude"
DEST="$BASE/dist/agent-manifesto-plugin"

if [ -z "$VERSION" ]; then
  # 現在のバージョンから patch を increment
  CURRENT=$(jq -r '.version // "0.0.0"' "$DEST/plugin.json" 2>/dev/null || echo "0.0.0")
  MAJOR=$(echo "$CURRENT" | cut -d. -f1)
  MINOR=$(echo "$CURRENT" | cut -d. -f2)
  PATCH=$(echo "$CURRENT" | cut -d. -f3)
  VERSION="$MAJOR.$MINOR.$((PATCH + 1))"
  echo "Auto version: $CURRENT → $VERSION"
fi

echo "=== Packaging agent-manifesto plugin v$VERSION ==="

# --- Clean dest ---
rm -rf "$DEST"
mkdir -p "$DEST/hooks" "$DEST/agents" "$DEST/skills" "$DEST/rules"

# --- Hooks: copy scripts ---
echo "Hooks:"
for f in "$SRC/hooks/"*.sh; do
  [ -f "$f" ] || continue
  cp "$f" "$DEST/hooks/"
  chmod +x "$DEST/hooks/$(basename "$f")"
  echo "  + $(basename "$f")"
done

# --- Hooks: generate hooks.json from settings.json ---
echo "Generating hooks.json from settings.json..."
python3 -c "
import json, re, sys

with open('$SRC/settings.json') as f:
    settings = json.load(f)

hooks = settings.get('hooks', {})
plugin_hooks = {}

for event, matchers in hooks.items():
    plugin_matchers = []
    for matcher in matchers:
        plugin_matcher = dict(matcher)
        if 'hooks' in plugin_matcher:
            new_hooks = []
            for h in plugin_matcher['hooks']:
                new_h = dict(h)
                if 'command' in new_h:
                    # .claude/hooks/xxx.sh → \${CLAUDE_PLUGIN_ROOT}/hooks/xxx.sh
                    cmd = new_h['command']
                    cmd = re.sub(r'bash\s+\.claude/hooks/', 'bash \${CLAUDE_PLUGIN_ROOT}/hooks/', cmd)
                    new_h['command'] = cmd
                new_hooks.append(new_h)
            plugin_matcher['hooks'] = new_hooks
        plugin_matchers.append(plugin_matcher)
    plugin_hooks[event] = plugin_matchers

with open('$DEST/hooks/hooks.json', 'w') as f:
    json.dump({'hooks': plugin_hooks}, f, indent=2)
print('  hooks.json generated')
"

# --- Agents ---
echo "Agents:"
for f in "$SRC/agents/"*.md; do
  [ -f "$f" ] || continue
  cp "$f" "$DEST/agents/"
  echo "  + $(basename "$f")"
done

# --- Skills (exclude package-plugin itself) ---
echo "Skills:"
for d in "$SRC/skills/"*/; do
  [ -d "$d" ] || continue
  SKILL_NAME=$(basename "$d")
  [ "$SKILL_NAME" = "package-plugin" ] && continue
  # workspace dirs を除外
  echo "$SKILL_NAME" | grep -q "workspace" && continue
  if [ -f "$d/SKILL.md" ]; then
    mkdir -p "$DEST/skills/$SKILL_NAME"
    cp "$d/SKILL.md" "$DEST/skills/$SKILL_NAME/"
    echo "  + $SKILL_NAME"
  fi
done

# --- Rules ---
echo "Rules:"
for f in "$SRC/rules/"*.md; do
  [ -f "$f" ] || continue
  cp "$f" "$DEST/rules/"
  echo "  + $(basename "$f")"
done

# --- plugin.json ---
cat > "$DEST/plugin.json" << PJSON
{
  "name": "agent-manifesto",
  "version": "$VERSION",
  "description": "Manifest-compliant AI agent governance: L1 safety, P2 4-condition verification independence, P3 governed learning, P4 observability with drift detection, D8 equilibrium. Formally verified in Lean 4.",
  "author": {
    "name": "niraiarin",
    "url": "https://github.com/niraiarin/agent-manifesto"
  },
  "repository": "https://github.com/niraiarin/agent-manifesto",
  "license": "MIT",
  "keywords": ["safety", "governance", "verification", "manifesto", "agent", "lean4"],
  "agents": "./agents/",
  "skills": "./skills/",
  "hooks": "./hooks/hooks.json"
}
PJSON
echo "plugin.json v$VERSION"

# --- README.md ---
HOOK_COUNT=$(ls "$DEST/hooks/"*.sh 2>/dev/null | wc -l | tr -d ' ')
SKILL_COUNT=$(ls -d "$DEST/skills/"*/ 2>/dev/null | wc -l | tr -d ' ')
AGENT_COUNT=$(ls "$DEST/agents/"*.md 2>/dev/null | wc -l | tr -d ' ')
RULE_COUNT=$(ls "$DEST/rules/"*.md 2>/dev/null | wc -l | tr -d ' ')

cat > "$DEST/README.md" << README
# agent-manifesto Plugin v$VERSION

Manifest-compliant AI agent governance for Claude Code.

## Install

\`\`\`bash
claude plugin install <path-to-plugin> --scope user
\`\`\`

## .gitignore

Add to your project's \`.gitignore\`:
\`\`\`
.claude/metrics/*.jsonl
\`\`\`

## Contents

- **$HOOK_COUNT hooks**: L1 safety, P2 verification, P3 governance, P4 observability
- **$SKILL_COUNT skills**: /verify, /metrics, /adjust-action-space, /design-implementation-plan
- **$AGENT_COUNT agent**: verifier (P2, read-only, 4-condition model)
- **$RULE_COUNT rules**: L1 safety, L1 sandbox, P3 governed learning

## Source

<https://github.com/niraiarin/agent-manifesto>
README
echo "README.md generated"

# --- Verification ---
echo ""
echo "=== Verification ==="
ERRORS=0

# plugin.json valid
jq . "$DEST/plugin.json" > /dev/null 2>&1 && echo "✓ plugin.json valid" || { echo "✗ plugin.json invalid"; ERRORS=$((ERRORS+1)); }

# hooks.json valid
jq . "$DEST/hooks/hooks.json" > /dev/null 2>&1 && echo "✓ hooks.json valid" || { echo "✗ hooks.json invalid"; ERRORS=$((ERRORS+1)); }

# All hook scripts referenced in hooks.json exist
REFERENCED=$(jq -r '.. | .command? // empty' "$DEST/hooks/hooks.json" | grep -o '[^/]*\.sh' | sort -u)
for script in $REFERENCED; do
  [ -x "$DEST/hooks/$script" ] && echo "✓ $script exists" || { echo "✗ $script missing"; ERRORS=$((ERRORS+1)); }
done

# No absolute paths
if grep -r '/Users/' "$DEST/hooks/" --include="*.json" --include="*.sh" > /dev/null 2>&1; then
  echo "✗ Absolute paths found"; ERRORS=$((ERRORS+1))
else
  echo "✓ No absolute paths"
fi

echo ""
if [ "$ERRORS" -eq 0 ]; then
  echo "=== Plugin v$VERSION packaged successfully ==="
  echo "Location: $DEST"
else
  echo "=== $ERRORS errors found ==="
  exit 1
fi
