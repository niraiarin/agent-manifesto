#!/usr/bin/env bash
# convergence.sh behavioral tests (#480)
# philosophy mode + normal mode の動作検証
set -uo pipefail
PASS=0; FAIL=0
BASE="$(git rev-parse --show-toplevel 2>/dev/null || echo /Users/nirarin/work/agent-manifesto)"
CONV="$BASE/.claude/skills/brownfield/convergence.sh"
TMPDIR_TEST="${TMPDIR:-/tmp}/test-convergence-$$"
trap 'rm -rf "$TMPDIR_TEST"' EXIT

echo "=== Phase 3: Convergence Behavioral Tests ==="

# --- Normal mode ---

# C.1: add-detailed normal mode
echo -n "C.1 add-detailed normal mode creates iteration file... "
D="$TMPDIR_TEST/c1"
mkdir -p "$D"
echo '[{"id":"PD-001","content":"test","source":"code_analysis","confidence":"high"}]' > "$TMPDIR_TEST/pds.json"
bash "$CONV" add-detailed "$D" 1 "test-unit" "$TMPDIR_TEST/pds.json" >/dev/null 2>&1
if [ -f "$D/iteration-1.json" ]; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL"; FAIL=$((FAIL+1)); fi

# C.2: cumulative.txt tracks normal mode
echo -n "C.2 cumulative.txt tracks normal mode count... "
CUM=$(cat "$D/cumulative.txt" 2>/dev/null)
if [ "$CUM" = "1" ]; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL (got: $CUM)"; FAIL=$((FAIL+1)); fi

# C.3: status normal mode
echo -n "C.3 status normal mode shows iteration... "
OUT=$(bash "$CONV" status "$D" 2>&1)
if echo "$OUT" | grep -q "Iteration.*1"; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL"; FAIL=$((FAIL+1)); fi

# C.4: check normal mode (unconverged with rate=1.0)
echo -n "C.4 check normal mode reports UNCONVERGED at rate=1.0... "
OUT=$(bash "$CONV" check "$D" 2>&1 || true)
if echo "$OUT" | grep -q "UNCONVERGED"; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL"; FAIL=$((FAIL+1)); fi

# --- Philosophy mode ---

# C.5: add-detailed philosophy mode creates prefixed file
echo -n "C.5 add-detailed --mode philosophy creates philosophy-iteration file... "
D2="$TMPDIR_TEST/c5"
mkdir -p "$D2"
bash "$CONV" add-detailed "$D2" 10 "test-unit" "$TMPDIR_TEST/pds.json" --mode philosophy >/dev/null 2>&1
if [ -f "$D2/philosophy-iteration-10.json" ]; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL"; FAIL=$((FAIL+1)); fi

# C.6: philosophy mode uses separate cumulative counter
echo -n "C.6 philosophy mode uses cumulative-philosophy.txt... "
if [ -f "$D2/cumulative-philosophy.txt" ]; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL"; FAIL=$((FAIL+1)); fi

# C.7: philosophy iteration file contains mode field
echo -n "C.7 philosophy iteration file has mode field... "
MODE_VAL=$(jq -r '.mode // empty' "$D2/philosophy-iteration-10.json" 2>/dev/null)
if [ "$MODE_VAL" = "philosophy" ]; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL (got: $MODE_VAL)"; FAIL=$((FAIL+1)); fi

# C.8: normal iteration file does NOT have mode field
echo -n "C.8 normal iteration file has no mode field... "
MODE_VAL=$(jq -r '.mode // "absent"' "$D/iteration-1.json" 2>/dev/null)
if [ "$MODE_VAL" = "absent" ]; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL (got: $MODE_VAL)"; FAIL=$((FAIL+1)); fi

# C.9: cumulative counters are isolated between modes
echo -n "C.9 cumulative counters isolated between modes... "
D3="$TMPDIR_TEST/c9"
mkdir -p "$D3"
echo '[{"id":"PD-A","content":"a"},{"id":"PD-B","content":"b"}]' > "$TMPDIR_TEST/pds2.json"
echo '[{"id":"PP-1","content":"x"}]' > "$TMPDIR_TEST/pds3.json"
bash "$CONV" add-detailed "$D3" 1 "u" "$TMPDIR_TEST/pds2.json" >/dev/null 2>&1
bash "$CONV" add-detailed "$D3" 10 "u" "$TMPDIR_TEST/pds3.json" --mode philosophy >/dev/null 2>&1
NORM_CUM=$(cat "$D3/cumulative.txt" 2>/dev/null)
PHIL_CUM=$(cat "$D3/cumulative-philosophy.txt" 2>/dev/null)
if [ "$NORM_CUM" = "2" ] && [ "$PHIL_CUM" = "1" ]; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL (normal=$NORM_CUM, philosophy=$PHIL_CUM)"; FAIL=$((FAIL+1)); fi

# C.10: status --mode philosophy shows only philosophy iterations
echo -n "C.10 status --mode philosophy shows only philosophy iterations... "
OUT=$(bash "$CONV" status "$D3" --mode philosophy 2>&1)
if echo "$OUT" | grep -q "Iteration.*10" && ! echo "$OUT" | grep -q "Iteration  1:"; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL"; FAIL=$((FAIL+1)); fi

# C.11: check --mode philosophy works independently
echo -n "C.11 check --mode philosophy reports independently... "
OUT=$(bash "$CONV" check "$D3" --mode philosophy 2>&1 || true)
if echo "$OUT" | grep -q "\[philosophy\]"; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL"; FAIL=$((FAIL+1)); fi

# --- Error handling ---

# C.12: unknown mode rejected
echo -n "C.12 unknown mode rejected with exit 1... "
OUT=$(bash "$CONV" check "$D" --mode typo 2>&1; echo "EXIT:$?")
if echo "$OUT" | grep -q "EXIT:1" && echo "$OUT" | grep -q "unknown mode"; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL"; FAIL=$((FAIL+1)); fi

# C.13: trailing --mode without value rejected
echo -n "C.13 trailing --mode without value rejected... "
OUT=$(bash "$CONV" check "$D" --mode 2>&1; echo "EXIT:$?")
if echo "$OUT" | grep -q "EXIT:1" && echo "$OUT" | grep -q "requires a value"; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL"; FAIL=$((FAIL+1)); fi

# --- Backward compatibility ---

# C.14: normal mode unaffected by philosophy mode data
echo -n "C.14 normal mode unaffected by philosophy data... "
D4="$TMPDIR_TEST/c14"
mkdir -p "$D4"
echo '[{"id":"PD-1","content":"x"}]' > "$TMPDIR_TEST/pd1.json"
bash "$CONV" add-detailed "$D4" 1 "u" "$TMPDIR_TEST/pd1.json" >/dev/null 2>&1
bash "$CONV" add-detailed "$D4" 10 "u" "$TMPDIR_TEST/pd1.json" --mode philosophy >/dev/null 2>&1
bash "$CONV" add-detailed "$D4" 11 "u" "$TMPDIR_TEST/pd1.json" --mode philosophy >/dev/null 2>&1
# Normal status should show only iteration 1
OUT=$(bash "$CONV" status "$D4" 2>&1)
LINES=$(echo "$OUT" | grep "Iteration" | wc -l | tr -d ' ')
if [ "$LINES" = "1" ]; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL ($LINES iterations shown)"; FAIL=$((FAIL+1)); fi

# --- Convergence detection (2 consecutive < 0.03 + validation) ---

# C.15: single iteration below threshold → UNCONVERGED (need 2 consecutive)
echo -n "C.15 single iteration < 0.03 reports UNCONVERGED (need 2 consecutive)... "
D5="$TMPDIR_TEST/c15"
mkdir -p "$D5"
echo "100" > "$D5/cumulative.txt"
echo '[{"id":"PD-BIG","content":"x"}]' > "$TMPDIR_TEST/pd_one.json"
bash "$CONV" add-detailed "$D5" 5 "u" "$TMPDIR_TEST/pd_one.json" >/dev/null 2>&1
OUT=$(bash "$CONV" check "$D5" 2>&1 || true)
if echo "$OUT" | grep -q "^UNCONVERGED.*need 2"; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL ($OUT)"; FAIL=$((FAIL+1)); fi

# C.16: 2 consecutive < 0.03 → CONVERGED_PENDING_VALIDATION
echo -n "C.16 2 consecutive < 0.03 reports CONVERGED_PENDING_VALIDATION... "
D6="$TMPDIR_TEST/c16"
mkdir -p "$D6"
echo "100" > "$D6/cumulative.txt"
echo '[{"id":"PD-A","content":"x"}]' > "$TMPDIR_TEST/pd_a.json"
echo '[{"id":"PD-B","content":"y"}]' > "$TMPDIR_TEST/pd_b.json"
bash "$CONV" add-detailed "$D6" 4 "u" "$TMPDIR_TEST/pd_a.json" >/dev/null 2>&1
bash "$CONV" add-detailed "$D6" 5 "u" "$TMPDIR_TEST/pd_b.json" >/dev/null 2>&1
OUT=$(bash "$CONV" check "$D6" 2>&1 || true)
if echo "$OUT" | grep -q "CONVERGED_PENDING_VALIDATION"; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL ($OUT)"; FAIL=$((FAIL+1)); fi

# C.17: validation iteration → CONVERGED
echo -n "C.17 validation iteration < 0.03 reports CONVERGED... "
D7="$TMPDIR_TEST/c17"
mkdir -p "$D7"
echo "100" > "$D7/cumulative.txt"
echo '[{"id":"PD-C","content":"x"}]' > "$TMPDIR_TEST/pd_c.json"
echo '[]' > "$TMPDIR_TEST/pd_empty.json"
bash "$CONV" add-detailed "$D7" 4 "u" "$TMPDIR_TEST/pd_c.json" >/dev/null 2>&1
bash "$CONV" add-detailed "$D7" 5 "u" "$TMPDIR_TEST/pd_c.json" >/dev/null 2>&1
bash "$CONV" add-detailed "$D7" 6 "u" "$TMPDIR_TEST/pd_empty.json" --validation >/dev/null 2>&1
OUT=$(bash "$CONV" check "$D7" 2>&1 || true)
if echo "$OUT" | grep -q "^CONVERGED \[normal\]: validation PASS"; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL ($OUT)"; FAIL=$((FAIL+1)); fi

# C.18: exit code 2 for CONVERGED_PENDING_VALIDATION
echo -n "C.18 CONVERGED_PENDING_VALIDATION exits with code 2... "
bash "$CONV" check "$D6" >/dev/null 2>&1; RC=$?
if [ "$RC" = "2" ]; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL (exit=$RC)"; FAIL=$((FAIL+1)); fi

# C.19: validation flag stored in iteration JSON
echo -n "C.19 --validation flag stored in iteration JSON... "
VAL=$(jq -r '.validation' "$D7/iteration-6.json" 2>/dev/null)
if [ "$VAL" = "true" ]; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL (got: $VAL)"; FAIL=$((FAIL+1)); fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
exit $FAIL
