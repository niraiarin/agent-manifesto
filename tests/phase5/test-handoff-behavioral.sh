#!/usr/bin/env bash
# @traces T1, T2, D1, D10, P4
# Behavioral tests for handoff-resume-loader.sh hook
set -uo pipefail
PASS=0; FAIL=0
BASE="$(git rev-parse --show-toplevel 2>/dev/null || echo /Users/nirarin/work/agent-manifesto)"
HOOK="$BASE/.claude/hooks/handoff-resume-loader.sh"

echo "=== Phase 5: Handoff Behavioral Tests ==="

check() {
  local name="$1" cond="$2"
  echo -n "$name... "
  if eval "$cond"; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL"; FAIL=$((FAIL+1)); fi
}

# Precondition: hook must exist (structural test S-HO.5 covers this)
check "B-HO.0 handoff-resume-loader.sh exists" \
  "[ -x '$HOOK' ]"

# --- Setup: create temp handoffs dir for testing ---
TEST_HANDOFFS="${TMPDIR:-/tmp}/handoff-test-$$"
mkdir -p "$TEST_HANDOFFS"
CURRENT_SHA=$(cd "$BASE" && git rev-parse HEAD 2>/dev/null || echo "abc123")
trap "rm -rf '$TEST_HANDOFFS'" EXIT

# --- B-HO.1: No resume file → no output, exit 0 ---
check "B-HO.1 No resume file exits cleanly" \
  "HANDOFF_DIR='$TEST_HANDOFFS' bash '$HOOK' >/dev/null 2>&1; [ \$? -eq 0 ]"

# --- B-HO.2: Resume file with matching sha → additionalContext output ---
cat > "$TEST_HANDOFFS/handoff-resume.md" << EOF
# Handoff Resume
git_sha: $CURRENT_SHA
skill: evolve
phase: Phase 2
intent: Testing handoff mechanism
next_steps:
- Complete Phase 3 verification
EOF

check "B-HO.2 Matching sha produces additionalContext" \
  "HANDOFF_DIR='$TEST_HANDOFFS' GIT_DIR='$BASE/.git' bash '$HOOK' 2>/dev/null | grep -q 'additionalContext'"

# --- B-HO.3: Resume file with mismatched sha → warn in output ---
cat > "$TEST_HANDOFFS/handoff-resume.md" << EOF
# Handoff Resume
git_sha: 0000000000000000000000000000000000000000
skill: evolve
phase: Phase 2
intent: Testing stale detection
EOF

check "B-HO.3 Mismatched sha produces warn" \
  "HANDOFF_DIR='$TEST_HANDOFFS' GIT_DIR='$BASE/.git' bash '$HOOK' 2>/dev/null | grep -qi 'warn\|mismatch'"

# --- B-HO.4: After injection, file is renamed to .injected ---
cat > "$TEST_HANDOFFS/handoff-resume.md" << EOF
# Handoff Resume
git_sha: $CURRENT_SHA
skill: test
phase: Phase 1
intent: Test rename
EOF

HANDOFF_DIR="$TEST_HANDOFFS" GIT_DIR="$BASE/.git" bash "$HOOK" >/dev/null 2>&1
check "B-HO.4 Resume file renamed to .injected after injection" \
  "[ -f '$TEST_HANDOFFS/handoff-resume.md.injected' ] && [ ! -f '$TEST_HANDOFFS/handoff-resume.md' ]"

# --- B-HO.5: .injected file is not re-injected ---
# At this point only .injected exists, no .md — hook may still output evolve/sorry info
# but must NOT contain HANDOFF RESUME
check "B-HO.5 No re-injection of .injected file" \
  "OUTPUT=\$(HANDOFF_DIR='$TEST_HANDOFFS' GIT_DIR='$BASE/.git' bash '$HOOK' 2>/dev/null); ! echo \"\$OUTPUT\" | grep -q 'HANDOFF RESUME'"

# --- B-HO.6: Output is valid JSON when additionalContext is produced ---
cat > "$TEST_HANDOFFS/handoff-resume.md" << EOF
# Handoff Resume
git_sha: $CURRENT_SHA
skill: test-json
phase: Phase 1
intent: Validate JSON output
EOF

check "B-HO.6 Hook output is valid JSON" \
  "OUTPUT=\$(HANDOFF_DIR='$TEST_HANDOFFS' GIT_DIR='$BASE/.git' bash '$HOOK' 2>/dev/null); echo \"\$OUTPUT\" | python3 -m json.tool >/dev/null 2>&1"

# --- B-HO.7: sorry-count integration ---
check "B-HO.7 Sorry count logic present in hook" \
  "grep -q 'sorry' '$HOOK'"

# --- B-HO.8: Branch match → injection allowed (#514 G1) ---
rm -f "$TEST_HANDOFFS"/handoff-resume*.md "$TEST_HANDOFFS"/handoff-resume*.injected
CURRENT_BRANCH=$(cd "$BASE" && git branch --show-current 2>/dev/null || echo "main")
cat > "$TEST_HANDOFFS/handoff-resume.md" << EOF
# Handoff Resume
git_sha: $CURRENT_SHA
branch: $CURRENT_BRANCH
skill: test
phase: Phase 1
intent: Test branch match
EOF

check "B-HO.8 Branch match allows injection" \
  "HANDOFF_DIR='$TEST_HANDOFFS' bash '$HOOK' 2>/dev/null | grep -q 'HANDOFF RESUME'"

# --- B-HO.9: Branch mismatch → injection skipped (#514 G1) ---
rm -f "$TEST_HANDOFFS"/handoff-resume*.md "$TEST_HANDOFFS"/handoff-resume*.injected
cat > "$TEST_HANDOFFS/handoff-resume.md" << EOF
# Handoff Resume
git_sha: $CURRENT_SHA
branch: nonexistent-branch-xyz
skill: test
phase: Phase 1
intent: Test branch mismatch
EOF

check "B-HO.9 Branch mismatch skips injection" \
  "OUTPUT=\$(HANDOFF_DIR='$TEST_HANDOFFS' bash '$HOOK' 2>/dev/null); ! echo \"\$OUTPUT\" | grep -q 'HANDOFF RESUME'"

# --- B-HO.10: Absent branch field → backward compat injection (#514 G1) ---
rm -f "$TEST_HANDOFFS"/handoff-resume*.md "$TEST_HANDOFFS"/handoff-resume*.injected
cat > "$TEST_HANDOFFS/handoff-resume.md" << EOF
# Handoff Resume
git_sha: $CURRENT_SHA
skill: test
phase: Phase 1
intent: Test no branch field (old format)
EOF

check "B-HO.10 Absent branch field allows injection (backward compat)" \
  "HANDOFF_DIR='$TEST_HANDOFFS' bash '$HOOK' 2>/dev/null | grep -q 'HANDOFF RESUME'"

# --- B-HO.11: branch: null → injection allowed (#514 G1) ---
rm -f "$TEST_HANDOFFS"/handoff-resume*.md "$TEST_HANDOFFS"/handoff-resume*.injected
cat > "$TEST_HANDOFFS/handoff-resume.md" << EOF
# Handoff Resume
git_sha: $CURRENT_SHA
branch: null
skill: test
phase: Phase 1
intent: Test null branch (detached HEAD)
EOF

check "B-HO.11 branch: null allows injection" \
  "HANDOFF_DIR='$TEST_HANDOFFS' bash '$HOOK' 2>/dev/null | grep -q 'HANDOFF RESUME'"

# --- B-HO.12: Scoped file selected over fallback (#514 G2) ---
rm -f "$TEST_HANDOFFS"/handoff-resume*.md "$TEST_HANDOFFS"/handoff-resume*.injected
SCOPED_FILE="handoff-resume-$(echo "$CURRENT_BRANCH" | sed 's|/|-|g').md"
cat > "$TEST_HANDOFFS/$SCOPED_FILE" << EOF
# Handoff Resume
git_sha: $CURRENT_SHA
branch: $CURRENT_BRANCH
skill: scoped-test
phase: Phase 1
intent: SCOPED file
EOF
cat > "$TEST_HANDOFFS/handoff-resume.md" << EOF
# Handoff Resume
git_sha: $CURRENT_SHA
branch: other-branch
skill: fallback-test
phase: Phase 1
intent: FALLBACK file
EOF

check "B-HO.12 Scoped file selected over fallback" \
  "HANDOFF_DIR='$TEST_HANDOFFS' bash '$HOOK' 2>/dev/null | grep -q 'SCOPED file'"

# --- B-HO.13: Fallback used when no scoped file (#514 G2) ---
rm -f "$TEST_HANDOFFS"/handoff-resume*.md "$TEST_HANDOFFS"/handoff-resume*.injected
cat > "$TEST_HANDOFFS/handoff-resume.md" << EOF
# Handoff Resume
git_sha: $CURRENT_SHA
branch: $CURRENT_BRANCH
skill: fallback-test
phase: Phase 1
intent: FALLBACK used
EOF

check "B-HO.13 Fallback file used when no scoped file exists" \
  "HANDOFF_DIR='$TEST_HANDOFFS' bash '$HOOK' 2>/dev/null | grep -q 'FALLBACK used'"

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
