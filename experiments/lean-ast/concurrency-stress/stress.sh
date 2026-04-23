#!/usr/bin/env bash
# Sub-F #661: concurrency safety stress test harness
#
# Tests:
#   T1 — N parallel invocations on DIFFERENT output files (shared .lake/cache)
#   T2 — N parallel invocations writing to the SAME output file (target contention, primary scenario per #661 方法 step 1)
#   T3 — Same as T2 but with mkdir-based advisory lock + atomic rename mitigation (flock absent on macOS)
#
# Metrics: wall-clock per invocation (p50, p95), exit codes, output corruption detection.
#
# Baseline (Sub-D #659 Profile A): warm median ~103 ms, cold ~246 ms.
# Gate PASS: 2 parallel p95 wall-clock ≤ baseline * 1.10.

set -euo pipefail
cd "$(dirname "$0")"
export PATH="$HOME/.elan/bin:$PATH"

BIN="$(cd ../rewrite-poc && pwd)/.lake/build/bin/rewrite-poc"
[[ ! -x "$BIN" ]] && { echo "ERROR: rewrite-poc binary not built at $BIN" >&2; exit 1; }

INPUT="inputs/target.lean"
EXPECTED="inputs/target.expected.lean"
OUT="out"
LOG="log"
rm -rf "$OUT" "$LOG"
mkdir -p "$OUT" "$LOG"

N="${N:-4}"         # parallelism
TRIALS="${TRIALS:-5}"  # trials per test
echo "=== Sub-F #661 concurrency stress test ==="
echo "Binary: $BIN"
echo "Parallelism: N=$N, trials per test: TRIALS=$TRIALS"
echo

# Helper: run one invocation, log wall-clock in ns to stdout on its own line.
# Usage: run_one <id> <output-file>
run_one() {
  local id="$1"; local out="$2"
  local t0 t1 rc
  t0=$(python3 -c 'import time; print(time.perf_counter_ns())')
  set +e
  "$BIN" "$INPUT" "foo" "axiom foo : Bool" "$out" >"$LOG/$id.log" 2>&1
  rc=$?
  set -e
  t1=$(python3 -c 'import time; print(time.perf_counter_ns())')
  local dur_ns=$((t1 - t0))
  echo "$id $rc $dur_ns"
}

# Helper: same but serialize on mkdir-based advisory lock + atomic rename
run_one_locked() {
  # mkdir-based advisory lock: atomic on POSIX, portable to macOS (flock not available).
  # Contenders spin until they acquire the lock directory, then write + rename atomically.
  # trap ensures lock + tmp cleanup even on subshell abort (SIGPIPE, SIGKILL not caught).
  local id="$1"; local out="$2"
  local lockdir="${out}.lock.d"
  local tmp="${out}.tmp.$$.$id"
  local t0 t1 rc waited=0
  t0=$(python3 -c 'import time; print(time.perf_counter_ns())')
  set +e
  # Acquire lock (up to 10s with 10ms backoff)
  while ! mkdir "$lockdir" 2>/dev/null; do
    waited=$((waited + 1))
    if [[ $waited -gt 1000 ]]; then
      rc=124  # lock timeout
      break
    fi
    python3 -c 'import time; time.sleep(0.01)'
  done
  if [[ ${rc:-} != 124 ]]; then
    # Install trap to guarantee cleanup even on abort
    trap 'rmdir "'"$lockdir"'" 2>/dev/null; rm -f "'"$tmp"'"' RETURN INT TERM
    "$BIN" "$INPUT" "foo" "axiom foo : Bool" "$tmp" >"$LOG/$id.log" 2>&1
    rc=$?
    if [[ $rc -eq 0 ]]; then
      mv "$tmp" "$out"
    else
      rm -f "$tmp"
    fi
    rmdir "$lockdir" 2>/dev/null || true
    trap - RETURN INT TERM
  fi
  set -e
  t1=$(python3 -c 'import time; print(time.perf_counter_ns())')
  local dur_ns=$((t1 - t0))
  echo "$id $rc $dur_ns"
}

# ─────────────────────────────────────────────────
# T0: Baseline re-measurement (single invocation, warm)
# ─────────────────────────────────────────────────
echo "--- T0: single-invocation baseline (warm) ---"
T0_MEASURES="$LOG/t0.ns"
: >"$T0_MEASURES"
for i in $(seq 1 $TRIALS); do
  run_one "T0-$i" "$OUT/t0-$i.out" >>"$T0_MEASURES"
done
T0_NS=$(awk '{print $3}' "$T0_MEASURES" | sort -n)
T0_P50=$(echo "$T0_NS" | awk -v n="$TRIALS" 'NR==int(n/2)+1{print}')
T0_P95=$(echo "$T0_NS" | awk -v n="$TRIALS" 'NR==(n==1?1:int(n*0.95+0.5)){print}')
echo "T0 baseline p50=$((T0_P50/1000000))ms p95=$((T0_P95/1000000))ms"
echo

# ─────────────────────────────────────────────────
# T1: N parallel → DIFFERENT output files
# ─────────────────────────────────────────────────
echo "--- T1: N=$N parallel → different output files ---"
T1_MEASURES="$LOG/t1.ns"
: >"$T1_MEASURES"
for trial in $(seq 1 $TRIALS); do
  pids=()
  for i in $(seq 1 $N); do
    (run_one "T1-t${trial}-${i}" "$OUT/t1-t${trial}-${i}.out" >"$LOG/T1-t${trial}-${i}.ns") &
    pids+=($!)
  done
  for pid in "${pids[@]}"; do wait "$pid"; done
done
# Merge per-job ns files into measurement log (avoid race-prone parallel `>>`)
cat "$LOG"/T1-*.ns >"$T1_MEASURES"
T1_NS=$(awk '{print $3}' "$T1_MEASURES" | sort -n)
T1_COUNT=$(echo "$T1_NS" | wc -l | tr -d ' ')
T1_P50=$(echo "$T1_NS" | awk -v n="$T1_COUNT" 'NR==int(n/2)+1{print}')
T1_P95=$(echo "$T1_NS" | awk -v n="$T1_COUNT" 'NR==int(n*0.95+0.5){print}')
T1_MAX=$(echo "$T1_NS" | tail -1)
T1_RC_OK=$(awk '$2==0' "$T1_MEASURES" | wc -l | tr -d ' ')
T1_RC_FAIL=$((T1_COUNT - T1_RC_OK))
T1_CORRUPT=0
for f in "$OUT"/t1-*.out; do
  cmp -s "$EXPECTED" "$f" || T1_CORRUPT=$((T1_CORRUPT + 1))
done
echo "T1 n=$T1_COUNT p50=$((T1_P50/1000000))ms p95=$((T1_P95/1000000))ms max=$((T1_MAX/1000000))ms"
echo "T1 exit-ok=$T1_RC_OK exit-fail=$T1_RC_FAIL corrupt-outputs=$T1_CORRUPT"
echo

# ─────────────────────────────────────────────────
# T2: N parallel → SAME output file (no mitigation)
# ─────────────────────────────────────────────────
echo "--- T2: N=$N parallel → SAME output file (no mitigation) ---"
T2_MEASURES="$LOG/t2.ns"
: >"$T2_MEASURES"
T2_CORRUPT=0
for trial in $(seq 1 $TRIALS); do
  SHARED="$OUT/t2-shared-t${trial}.out"
  rm -f "$SHARED"
  pids=()
  for i in $(seq 1 $N); do
    (run_one "T2-t${trial}-${i}" "$SHARED" >"$LOG/T2-t${trial}-${i}.ns") &
    pids+=($!)
  done
  for pid in "${pids[@]}"; do wait "$pid"; done
  # Check final state
  if [[ -f "$SHARED" ]]; then
    if ! cmp -s "$EXPECTED" "$SHARED"; then
      T2_CORRUPT=$((T2_CORRUPT + 1))
    fi
  else
    T2_CORRUPT=$((T2_CORRUPT + 1))
  fi
done
cat "$LOG"/T2-*.ns >"$T2_MEASURES"
T2_NS=$(awk '{print $3}' "$T2_MEASURES" | sort -n)
T2_COUNT=$(echo "$T2_NS" | wc -l | tr -d ' ')
T2_P50=$(echo "$T2_NS" | awk -v n="$T2_COUNT" 'NR==int(n/2)+1{print}')
T2_P95=$(echo "$T2_NS" | awk -v n="$T2_COUNT" 'NR==int(n*0.95+0.5){print}')
T2_MAX=$(echo "$T2_NS" | tail -1)
T2_RC_OK=$(awk '$2==0' "$T2_MEASURES" | wc -l | tr -d ' ')
T2_RC_FAIL=$((T2_COUNT - T2_RC_OK))
echo "T2 n=$T2_COUNT p50=$((T2_P50/1000000))ms p95=$((T2_P95/1000000))ms max=$((T2_MAX/1000000))ms"
echo "T2 exit-ok=$T2_RC_OK exit-fail=$T2_RC_FAIL shared-file-corrupt=$T2_CORRUPT/$TRIALS trials"
echo

# ─────────────────────────────────────────────────
# T3: N parallel → SAME output file WITH mkdir-lock + atomic rename
# ─────────────────────────────────────────────────
echo "--- T3: N=$N parallel → SAME output file WITH mkdir-lock + atomic rename ---"
T3_MEASURES="$LOG/t3.ns"
: >"$T3_MEASURES"
T3_CORRUPT=0
for trial in $(seq 1 $TRIALS); do
  SHARED="$OUT/t3-shared-t${trial}.out"
  rm -f "$SHARED" "$SHARED.lock"
  rm -rf "$SHARED.lock.d"
  pids=()
  for i in $(seq 1 $N); do
    (run_one_locked "T3-t${trial}-${i}" "$SHARED" >"$LOG/T3-t${trial}-${i}.ns") &
    pids+=($!)
  done
  for pid in "${pids[@]}"; do wait "$pid"; done
  if [[ -f "$SHARED" ]]; then
    if ! cmp -s "$EXPECTED" "$SHARED"; then
      T3_CORRUPT=$((T3_CORRUPT + 1))
    fi
  else
    T3_CORRUPT=$((T3_CORRUPT + 1))
  fi
done
cat "$LOG"/T3-*.ns >"$T3_MEASURES"
T3_NS=$(awk '{print $3}' "$T3_MEASURES" | sort -n)
T3_COUNT=$(echo "$T3_NS" | wc -l | tr -d ' ')
T3_P50=$(echo "$T3_NS" | awk -v n="$T3_COUNT" 'NR==int(n/2)+1{print}')
T3_P95=$(echo "$T3_NS" | awk -v n="$T3_COUNT" 'NR==int(n*0.95+0.5){print}')
T3_MAX=$(echo "$T3_NS" | tail -1)
T3_RC_OK=$(awk '$2==0' "$T3_MEASURES" | wc -l | tr -d ' ')
T3_RC_FAIL=$((T3_COUNT - T3_RC_OK))
echo "T3 n=$T3_COUNT p50=$((T3_P50/1000000))ms p95=$((T3_P95/1000000))ms max=$((T3_MAX/1000000))ms"
echo "T3 exit-ok=$T3_RC_OK exit-fail=$T3_RC_FAIL shared-file-corrupt=$T3_CORRUPT/$TRIALS trials"
echo

# ─────────────────────────────────────────────────
# Summary + Gate judgment
# ─────────────────────────────────────────────────
echo "=== SUMMARY ==="
echo "N=$N parallel, TRIALS=$TRIALS"
printf "%-4s %-8s %-8s %-8s %-12s %-16s\n" "Test" "p50" "p95" "max" "exit-fails" "corruptions"
printf "%-4s %-8s %-8s %-8s %-12s %-16s\n" "T0" "$((T0_P50/1000000))ms" "$((T0_P95/1000000))ms" "-" "-" "-"
printf "%-4s %-8s %-8s %-8s %-12s %-16s\n" "T1" "$((T1_P50/1000000))ms" "$((T1_P95/1000000))ms" "$((T1_MAX/1000000))ms" "$T1_RC_FAIL/$T1_COUNT" "$T1_CORRUPT outputs"
printf "%-4s %-8s %-8s %-8s %-12s %-16s\n" "T2" "$((T2_P50/1000000))ms" "$((T2_P95/1000000))ms" "$((T2_MAX/1000000))ms" "$T2_RC_FAIL/$T2_COUNT" "$T2_CORRUPT/$TRIALS trials"
printf "%-4s %-8s %-8s %-8s %-12s %-16s\n" "T3" "$((T3_P50/1000000))ms" "$((T3_P95/1000000))ms" "$((T3_MAX/1000000))ms" "$T3_RC_FAIL/$T3_COUNT" "$T3_CORRUPT/$TRIALS trials"
echo
echo "Baseline (T0 p95): $((T0_P95/1000000))ms"
GATE_LIMIT_NS=$(( T0_P95 * 110 / 100 ))
echo "Gate limit (+10%): $((GATE_LIMIT_NS/1000000))ms"
echo
echo "T1 p95 within +10%: $([[ $T1_P95 -le $GATE_LIMIT_NS ]] && echo YES || echo NO)"
echo "T3 p95 within +10%: $([[ $T3_P95 -le $GATE_LIMIT_NS ]] && echo YES || echo NO)"
echo

# Save summary as jsonl for downstream verification
cat > "$LOG/summary.json" <<EOF
{
  "baseline_p50_ms": $((T0_P50/1000000)),
  "baseline_p95_ms": $((T0_P95/1000000)),
  "gate_limit_p95_ms": $((GATE_LIMIT_NS/1000000)),
  "T1_p50_ms": $((T1_P50/1000000)),
  "T1_p95_ms": $((T1_P95/1000000)),
  "T1_max_ms": $((T1_MAX/1000000)),
  "T1_exit_fails": $T1_RC_FAIL,
  "T1_corrupt_outputs": $T1_CORRUPT,
  "T2_p50_ms": $((T2_P50/1000000)),
  "T2_p95_ms": $((T2_P95/1000000)),
  "T2_max_ms": $((T2_MAX/1000000)),
  "T2_exit_fails": $T2_RC_FAIL,
  "T2_corrupt_outputs": $T2_CORRUPT,
  "T2_trials": $TRIALS,
  "T3_p50_ms": $((T3_P50/1000000)),
  "T3_p95_ms": $((T3_P95/1000000)),
  "T3_max_ms": $((T3_MAX/1000000)),
  "T3_exit_fails": $T3_RC_FAIL,
  "T3_corrupt_outputs": $T3_CORRUPT,
  "T3_trials": $TRIALS,
  "parallelism": $N,
  "trials_per_test": $TRIALS
}
EOF
echo "Summary JSON: $LOG/summary.json"
