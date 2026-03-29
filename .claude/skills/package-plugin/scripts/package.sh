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

# Hooks excluded from plugin (evolve-specific, not portable)
HOOKS_EXCLUDE="evolve-metrics-recorder.sh evolve-state-loader.sh"

# --- Hooks: copy scripts ---
echo "Hooks:"
for f in "$SRC/hooks/"*.sh; do
  [ -f "$f" ] || continue
  HOOK_NAME=$(basename "$f")
  # Skip evolve-specific hooks
  if echo "$HOOKS_EXCLUDE" | grep -qw "$HOOK_NAME"; then
    echo "  - $HOOK_NAME (excluded: evolve-specific)"
    continue
  fi
  cp "$f" "$DEST/hooks/"
  chmod +x "$DEST/hooks/$HOOK_NAME"
  echo "  + $HOOK_NAME"
done

# --- Hooks: generate hooks.json from settings.json ---
echo "Generating hooks.json from settings.json..."
python3 -c "
import json, re, sys

HOOKS_EXCLUDE = {'evolve-metrics-recorder.sh', 'evolve-state-loader.sh'}

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
                    cmd = new_h['command']
                    # Skip excluded hook scripts
                    import re as _re
                    script_match = _re.search(r'(\S+\.sh)', cmd)
                    if script_match:
                        script_name = script_match.group(1).split('/')[-1]
                        if script_name in HOOKS_EXCLUDE:
                            continue
                    # .claude/hooks/xxx.sh → \${CLAUDE_PLUGIN_ROOT}/hooks/xxx.sh
                    cmd = _re.sub(r'bash\s+\.claude/hooks/', 'bash \${CLAUDE_PLUGIN_ROOT}/hooks/', cmd)
                    new_h['command'] = cmd
                new_hooks.append(new_h)
            plugin_matcher['hooks'] = new_hooks
        plugin_matchers.append(plugin_matcher)
    plugin_hooks[event] = plugin_matchers

with open('$DEST/hooks/hooks.json', 'w') as f:
    json.dump({'hooks': plugin_hooks}, f, indent=2)
print('  hooks.json generated')
"

# Agents excluded from plugin (evolve-specific, not portable)
AGENTS_EXCLUDE="hypothesizer integrator observer"

# --- Agents ---
echo "Agents:"
# Copy flat .md agent files (exclude evolve-specific directories)
for f in "$SRC/agents/"*.md; do
  [ -f "$f" ] || continue
  AGENT_NAME=$(basename "$f" .md)
  if echo "$AGENTS_EXCLUDE" | grep -qw "$AGENT_NAME"; then
    echo "  - $(basename "$f") (excluded: evolve-specific)"
    continue
  fi
  cp "$f" "$DEST/agents/"
  echo "  + $(basename "$f")"
done
# Copy agent subdirectories (exclude evolve-specific)
for d in "$SRC/agents/"*/; do
  [ -d "$d" ] || continue
  AGENT_DIR=$(basename "$d")
  if echo "$AGENTS_EXCLUDE" | grep -qw "$AGENT_DIR"; then
    echo "  - $AGENT_DIR/ (excluded: evolve-specific)"
    continue
  fi
  mkdir -p "$DEST/agents/$AGENT_DIR"
  cp -r "$d"* "$DEST/agents/$AGENT_DIR/" 2>/dev/null || true
  echo "  + $AGENT_DIR/"
done

# Skills excluded from plugin (evolve-specific or internal)
SKILLS_EXCLUDE="evolve formal-derivation instantiate-model"

# --- Skills (exclude package-plugin itself) ---
echo "Skills:"
for d in "$SRC/skills/"*/; do
  [ -d "$d" ] || continue
  SKILL_NAME=$(basename "$d")
  [ "$SKILL_NAME" = "package-plugin" ] && continue
  # workspace dirs を除外
  echo "$SKILL_NAME" | grep -q "workspace" && continue
  # evolve-specific スキルを除外
  if echo "$SKILLS_EXCLUDE" | grep -qw "$SKILL_NAME"; then
    echo "  - $SKILL_NAME (excluded: evolve-specific)"
    continue
  fi
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

# --- artifact-manifest.json テンプレート生成 ---
echo ""
echo "=== Generating artifact-manifest.json ==="

# 本体の propositions を継承（-c で compact JSON として取得）
PROPOSITIONS=$(jq -c '.propositions' "$BASE/artifact-manifest.json" 2>/dev/null || echo '[]')

# パッケージ内のコンポーネントから artifacts を自動生成
PLUGIN_ARTIFACTS="[]"

# hooks → plugin-hook:<name>
for hook_file in "$DEST"/hooks/*.sh; do
  [ -f "$hook_file" ] || continue
  name=$(basename "$hook_file" .sh)
  # ファイル内の命題 ID (T1, E1, P2 等) を refs として抽出
  refs=$((grep -oE '[TEPLVD][0-9]+' "$hook_file" 2>/dev/null || true) | sort -u | jq -R . | jq -s .)
  PLUGIN_ARTIFACTS=$(echo "$PLUGIN_ARTIFACTS" | jq --arg id "plugin-hook:$name" --arg path ".claude/hooks/$name.sh" --argjson refs "$refs" \
    '. + [{"id": $id, "type": "hook", "path": $path, "refs": $refs, "scope": "plugin"}]')
done

# rules → plugin-rule:<name>
for rule_file in "$DEST"/rules/*.md; do
  [ -f "$rule_file" ] || continue
  name=$(basename "$rule_file" .md)
  refs=$((grep -oE '[TEPLVD][0-9]+' "$rule_file" 2>/dev/null || true) | sort -u | jq -R . | jq -s .)
  PLUGIN_ARTIFACTS=$(echo "$PLUGIN_ARTIFACTS" | jq --arg id "plugin-rule:$name" --arg path ".claude/rules/$name.md" --argjson refs "$refs" \
    '. + [{"id": $id, "type": "rule", "path": $path, "refs": $refs, "scope": "plugin"}]')
done

# agents → plugin-agent:<name>
# flat .md files
for agent_file in "$DEST"/agents/*.md; do
  [ -f "$agent_file" ] || continue
  name=$(basename "$agent_file" .md)
  refs=$((grep -oE '[TEPLVD][0-9]+' "$agent_file" 2>/dev/null || true) | sort -u | jq -R . | jq -s .)
  PLUGIN_ARTIFACTS=$(echo "$PLUGIN_ARTIFACTS" | jq --arg id "plugin-agent:$name" --arg path ".claude/agents/$name" --argjson refs "$refs" \
    '. + [{"id": $id, "type": "agent", "path": $path, "refs": $refs, "scope": "plugin"}]')
done
# subdirectory AGENT.md files (use find to avoid glob failure)
while IFS= read -r agent_file; do
  [ -f "$agent_file" ] || continue
  name=$(basename "$(dirname "$agent_file")")
  refs=$((grep -oE '[TEPLVD][0-9]+' "$agent_file" 2>/dev/null || true) | sort -u | jq -R . | jq -s .)
  PLUGIN_ARTIFACTS=$(echo "$PLUGIN_ARTIFACTS" | jq --arg id "plugin-agent:$name" --arg path ".claude/agents/$name" --argjson refs "$refs" \
    '. + [{"id": $id, "type": "agent", "path": $path, "refs": $refs, "scope": "plugin"}]')
done < <(find "$DEST/agents" -mindepth 2 -name "AGENT.md" 2>/dev/null)

jq -n --argjson props "$PROPOSITIONS" --argjson arts "$PLUGIN_ARTIFACTS" \
  '{version: "0.2.0", parent: "agent-manifesto", scopes: ["plugin"], propositions: $props, artifacts: $arts}' \
  > "$DEST/artifact-manifest.json"

ARTIFACT_COUNT=$(echo "$PLUGIN_ARTIFACTS" | jq 'length')
echo "artifact-manifest.json generated ($ARTIFACT_COUNT artifacts)"

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

# artifact-manifest.json valid
jq . "$DEST/artifact-manifest.json" > /dev/null 2>&1 && echo "✓ artifact-manifest.json valid" || { echo "✗ artifact-manifest.json invalid"; ERRORS=$((ERRORS+1)); }

# artifact-manifest.json refs grounded in propositions
BAD_REFS=$(jq -r '[.artifacts[].refs[]] | unique | .[] | select(. as $r | ['"$PROPOSITIONS"'[] | select(. == $r)] | length == 0)' "$DEST/artifact-manifest.json" 2>/dev/null)
if [ -z "$BAD_REFS" ]; then
  echo "✓ All refs grounded in propositions"
else
  echo "✗ Ungrounded refs: $BAD_REFS"; ERRORS=$((ERRORS+1))
fi

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
