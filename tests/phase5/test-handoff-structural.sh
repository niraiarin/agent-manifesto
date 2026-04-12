#!/usr/bin/env bash
# @traces T1, T2, D1, D10, P4
# Structural tests for handoff skill
set -uo pipefail
PASS=0; FAIL=0
BASE="$(git rev-parse --show-toplevel 2>/dev/null || echo /Users/nirarin/work/agent-manifesto)"

echo "=== Phase 5: Handoff Structural Tests ==="

check() {
  local name="$1" cond="$2"
  echo -n "$name... "
  if eval "$cond"; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL"; FAIL=$((FAIL+1)); fi
}

# --- Layer 1: Checkpoint infrastructure ---

check "S-HO.1 handoffs directory exists" \
  "[ -d '$BASE/.claude/handoffs' ]"

check "S-HO.2 handoff SKILL.md exists" \
  "[ -f '$BASE/.claude/skills/handoff/SKILL.md' ]"

check "S-HO.3 SKILL.md has user-invocable: true" \
  "grep -q 'user-invocable: true' '$BASE/.claude/skills/handoff/SKILL.md'"

check "S-HO.4 SKILL.md traces T1 and T2" \
  "grep -q '@traces.*T1.*T2\|@traces.*T2.*T1' '$BASE/.claude/skills/handoff/SKILL.md'"

# --- Layer 2: SessionStart hook ---

check "S-HO.5 handoff-resume-loader.sh exists and is executable" \
  "[ -x '$BASE/.claude/hooks/handoff-resume-loader.sh' ]"

check "S-HO.6 hook registered in settings.json SessionStart" \
  "grep -q 'handoff-resume-loader' '$BASE/.claude/settings.json'"

check "S-HO.7 hook uses additionalContext JSON pattern" \
  "grep -q 'additionalContext' '$BASE/.claude/hooks/handoff-resume-loader.sh'"

check "S-HO.8 hook uses hookSpecificOutput pattern" \
  "grep -q 'hookSpecificOutput' '$BASE/.claude/hooks/handoff-resume-loader.sh'"

# --- sorry-count integration ---

check "S-HO.9 hook includes sorry-count check" \
  "grep -q 'sorry' '$BASE/.claude/hooks/handoff-resume-loader.sh'"

# --- L1 integration ---

check "S-HO.10 handoffs/ not in l1-file-guard protected paths" \
  "! grep -q 'handoffs' '$BASE/.claude/hooks/l1-file-guard.sh'"

# --- sandbox integration ---

check "S-HO.11 handoffs in sandbox allowWrite" \
  "grep -q 'handoffs\|\.claude/handoffs' '$BASE/.claude/settings.json'"

# --- dependency graph ---

check "S-HO.12 handoff in dependency-graph.yaml" \
  "grep -q 'handoff' '$BASE/.claude/skills/dependency-graph.yaml'"

# --- checkpoint embedding in target skills ---

check "S-HO.13 evolve SKILL.md references checkpoint" \
  "grep -qi 'checkpoint\|handoff' '$BASE/.claude/skills/evolve/SKILL.md'"

check "S-HO.14 spec-driven-workflow SKILL.md references checkpoint" \
  "grep -qi 'checkpoint\|handoff' '$BASE/.claude/skills/spec-driven-workflow/SKILL.md'"

check "S-HO.15 brownfield SKILL.md references checkpoint" \
  "grep -qi 'checkpoint\|handoff' '$BASE/.claude/skills/brownfield/SKILL.md'"

check "S-HO.16 formal-derivation SKILL.md references checkpoint" \
  "grep -qi 'checkpoint\|handoff' '$BASE/.claude/skills/formal-derivation/SKILL.md'"

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
