#!/usr/bin/env bash
# Rules Injector — SessionStart
#
# Plugin spec does not support .claude/rules/ as auto-loaded components.
# This hook injects rule content via additionalContext on SessionStart.
# Reads from ${CLAUDE_PLUGIN_ROOT}/rules/ when deployed as plugin,
# or from .claude/rules/ when running standalone.
# @traces P3, D1

# Resolve rules directory: plugin root or project .claude/rules/
if [ -n "$CLAUDE_PLUGIN_ROOT" ] && [ -d "$CLAUDE_PLUGIN_ROOT/rules" ]; then
  RULES_DIR="$CLAUDE_PLUGIN_ROOT/rules"
elif [ -d "$(git rev-parse --show-toplevel 2>/dev/null || echo .)/.claude/rules" ]; then
  RULES_DIR="$(git rev-parse --show-toplevel 2>/dev/null || echo .)/.claude/rules"
else
  exit 0
fi

# Collect all .md rule files
RULES_CONTENT=""
for rule_file in "$RULES_DIR"/*.md; do
  [ -f "$rule_file" ] || continue
  RULES_CONTENT="${RULES_CONTENT}$(cat "$rule_file")
---
"
done

if [ -z "$RULES_CONTENT" ]; then
  exit 0
fi

# Escape for JSON
ESCAPED=$(printf '%s' "$RULES_CONTENT" | jq -Rs .)

cat << JSON
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": $ESCAPED
  }
}
JSON
