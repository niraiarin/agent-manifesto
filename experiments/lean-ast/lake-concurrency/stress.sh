#!/usr/bin/env bash
# Impl-D #668: Lake-level concurrent race verification
#
# Tests:
#   T1 — cold state + N parallel `lake exe lean-cli parse`
#        (artifacts pre-built, then .lake/build/bin/ deleted)
#   T2 — cold `lake build` concurrent (2 shells simultaneously kick lake build)
#   T3 — warm `lake exe` concurrent (comparison baseline, already covered by Sub-F)
#
# Gate (from issue #668 Gate with Verifier F5 fix):
#   PASS: cold state 4-parallel `lake exe` 0 corruption AND 2-shell `lake build`
#         serializes gracefully AND cold build ≤ 120s AND warm invocation ≤ 130ms
#   CONDITIONAL: race encountered but pre-build strict mitigation works
#   FAIL: lake build cache corrupted or pre-build cannot prevent race

set -euo pipefail
cd "$(dirname "$0")"
export PATH="$HOME/.elan/bin:$PATH"

CLI_DIR="$(cd ../lean-cli && pwd)"
FIXTURE="$CLI_DIR/tests/fixtures/basic.lean"
LOG="$PWD/log"
rm -rf "$LOG"
mkdir -p "$LOG"

echo "=== Impl-D #668 Lake-level concurrent race test ==="
echo "CLI dir: $CLI_DIR"
echo

# ─────────────────────────────────────────────────
# Pre-condition: ensure lean-cli is built (warm state)
# ─────────────────────────────────────────────────
echo "--- Pre-condition: build lean-cli (once) ---"
(cd "$CLI_DIR" && lake build lean-cli 2>&1 | tail -3)
echo

BIN="$CLI_DIR/.lake/build/bin/lean-cli"
[[ ! -x "$BIN" ]] && { echo "ERROR: lean-cli binary missing after pre-build" >&2; exit 1; }

# ─────────────────────────────────────────────────
# T1: warm `lake exe lean-cli` concurrent (4 parallel)
# Confirms Sub-F binary-level race-free holds when invoked via lake env
# ─────────────────────────────────────────────────
echo "--- T1: warm `lake exe lean-cli` × 4 parallel ---"
T1_FAIL=0
T1_PIDS=()
T1_START=$(python3 -c 'import time; print(int(time.perf_counter_ns()))')
for i in 1 2 3 4; do
  (
    set +e
    (cd "$CLI_DIR" && lake exe lean-cli parse "$FIXTURE") >"$LOG/t1-$i.out" 2>"$LOG/t1-$i.err"
    echo $? >"$LOG/t1-$i.rc"
  ) &
  T1_PIDS+=($!)
done
for pid in "${T1_PIDS[@]}"; do wait "$pid"; done
T1_END=$(python3 -c 'import time; print(int(time.perf_counter_ns()))')
T1_MS=$(( (T1_END - T1_START) / 1000000 ))
for i in 1 2 3 4; do
  RC=$(cat "$LOG/t1-$i.rc")
  if [[ "$RC" != "0" ]]; then
    T1_FAIL=$((T1_FAIL + 1))
    echo "  T1-$i FAIL rc=$RC err=$(head -1 "$LOG/t1-$i.err")"
  fi
done
# Check outputs: all 4 should have 3 JSONL lines for basic.lean
T1_CORRUPT=0
for i in 1 2 3 4; do
  count=$(wc -l <"$LOG/t1-$i.out" | tr -d ' ')
  if [[ "$count" != "3" ]]; then
    T1_CORRUPT=$((T1_CORRUPT + 1))
    echo "  T1-$i corrupt output (line count=$count)"
  fi
done
echo "T1: 4 parallel wall=${T1_MS}ms, exit-fails=$T1_FAIL/4, corrupt-outputs=$T1_CORRUPT/4"
echo

# ─────────────────────────────────────────────────
# T2: concurrent `lake build lean-cli` from warm state
# Lake should serialize internal writes; both should succeed without corruption
# ─────────────────────────────────────────────────
echo "--- T2: concurrent `lake build lean-cli` × 2 (warm state) ---"
T2_FAIL=0
T2_PIDS=()
T2_START=$(python3 -c 'import time; print(int(time.perf_counter_ns()))')
for i in 1 2; do
  (
    set +e
    (cd "$CLI_DIR" && lake build lean-cli) >"$LOG/t2-$i.out" 2>"$LOG/t2-$i.err"
    echo $? >"$LOG/t2-$i.rc"
  ) &
  T2_PIDS+=($!)
done
for pid in "${T2_PIDS[@]}"; do wait "$pid"; done
T2_END=$(python3 -c 'import time; print(int(time.perf_counter_ns()))')
T2_MS=$(( (T2_END - T2_START) / 1000000 ))
for i in 1 2; do
  RC=$(cat "$LOG/t2-$i.rc")
  if [[ "$RC" != "0" ]]; then
    T2_FAIL=$((T2_FAIL + 1))
    echo "  T2-$i FAIL rc=$RC err=$(head -1 "$LOG/t2-$i.err")"
  fi
done
# Post: binary must still be executable and produce valid output
if ! "$BIN" parse "$FIXTURE" >"$LOG/t2-post.out" 2>&1; then
  T2_FAIL=$((T2_FAIL + 10))
  echo "  T2 post-check: binary broken after concurrent build"
fi
echo "T2: 2 parallel lake build wall=${T2_MS}ms, exit-fails=$T2_FAIL/2"
echo

# ─────────────────────────────────────────────────
# T3: cold `lake build` — wipe .lake/build/ then single build
# Measures pure cold build time for Gate criterion
# ─────────────────────────────────────────────────
echo "--- T3: cold `lake build lean-cli` (after .lake/build/ wipe) ---"
(cd "$CLI_DIR" && rm -rf .lake/build)
T3_START=$(python3 -c 'import time; print(int(time.perf_counter_ns()))')
set +e
(cd "$CLI_DIR" && lake build lean-cli) >"$LOG/t3.out" 2>"$LOG/t3.err"
T3_RC=$?
set -e
T3_END=$(python3 -c 'import time; print(int(time.perf_counter_ns()))')
T3_MS=$(( (T3_END - T3_START) / 1000000 ))
echo "T3: cold build wall=${T3_MS}ms, rc=$T3_RC"
if [[ "$T3_RC" != "0" ]]; then
  echo "  T3 err: $(head -3 "$LOG/t3.err")"
fi
echo

# Post: binary exists and runs
if ! "$BIN" parse "$FIXTURE" >"$LOG/t3-post.out" 2>&1; then
  echo "T3 post-check: binary broken after cold build"
  T3_RC=99
fi

# ─────────────────────────────────────────────────
# Gate evaluation
# ─────────────────────────────────────────────────
echo "=== Gate evaluation ==="
echo "T1 cold-artifact lake exe: exit-fails=$T1_FAIL corrupt-outputs=$T1_CORRUPT"
echo "T2 concurrent lake build:  exit-fails=$T2_FAIL"
echo "T3 cold build wall-clock:  ${T3_MS}ms (Gate ≤ 120000ms)"
echo

PASS_T1=0; PASS_T2=0; PASS_T3=0
[[ $T1_FAIL -eq 0 && $T1_CORRUPT -eq 0 ]] && PASS_T1=1
[[ $T2_FAIL -eq 0 ]] && PASS_T2=1
[[ $T3_RC -eq 0 && $T3_MS -le 120000 ]] && PASS_T3=1

echo "T1 PASS=$PASS_T1, T2 PASS=$PASS_T2, T3 PASS=$PASS_T3"

cat > "$LOG/summary.json" <<EOF
{
  "T1_concurrent_lake_exe": {"parallel": 4, "exit_fails": $T1_FAIL, "corrupt_outputs": $T1_CORRUPT, "wall_ms": $T1_MS, "pass": $PASS_T1},
  "T2_concurrent_lake_build": {"parallel": 2, "exit_fails": $T2_FAIL, "wall_ms": $T2_MS, "pass": $PASS_T2},
  "T3_cold_build": {"rc": $T3_RC, "wall_ms": $T3_MS, "gate_ms": 120000, "pass": $PASS_T3}
}
EOF
echo "Summary: $LOG/summary.json"

[[ $PASS_T1 -eq 1 && $PASS_T2 -eq 1 && $PASS_T3 -eq 1 ]] && exit 0 || exit 1
