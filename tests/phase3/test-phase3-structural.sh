#!/usr/bin/env bash
set -uo pipefail
PASS=0; FAIL=0
BASE="$(git rev-parse --show-toplevel 2>/dev/null || echo /Users/nirarin/work/agent-manifesto)"

echo "=== Phase 3: P4 Structural Tests ==="

check() {
  local name="$1" cond="$2"
  echo -n "$name... "
  if eval "$cond"; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL"; FAIL=$((FAIL+1)); fi
}

check "S3.1 PostToolUse hook registered" \
  "jq -e '.hooks.PostToolUse | length > 0' '$BASE/.claude/settings.json' >/dev/null 2>&1"

check "S3.2 SessionStart hook registered" \
  "jq -e '.hooks.SessionStart | length > 0' '$BASE/.claude/settings.json' >/dev/null 2>&1"

check "S3.3 Metrics collector hook exists" \
  "[ -x '$BASE/.claude/hooks/p4-metrics-collector.sh' ]"

check "S3.4 Gate logger hook exists" \
  "[ -x '$BASE/.claude/hooks/p4-gate-logger.sh' ]"

check "S3.5 Metrics skill exists" \
  "[ -f '$BASE/.claude/skills/metrics/SKILL.md' ]"

check "S3.6 Metrics directory exists" \
  "[ -d '$BASE/.claude/metrics' ]"

check "S3.7 PostToolUse hook is async (non-blocking)" \
  "jq -e '.hooks.PostToolUse[0].hooks[0].async == true' '$BASE/.claude/settings.json' >/dev/null 2>&1"

check "S3.8 Metrics collector logs to JSONL" \
  "grep -q 'jsonl' '$BASE/.claude/hooks/p4-metrics-collector.sh'"

check "S3.9 Metrics skill covers V1-V7" \
  "grep -c 'V[1-7]' '$BASE/.claude/skills/metrics/SKILL.md' | xargs test 7 -le"

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
