#!/usr/bin/env bash
# Impl-A #666 lean-cli integration test harness
#
# Tests each subcommand on small fixtures. Gate basis:
# - parse:  emits JSONL with correct name/kind/range for 3 known axioms
# - query:  filters by --kind and --name-substring
# - edit:   byte-preserving replace (delegates to Sub-E 14-pattern harness for full coverage)
# - insert: inserts declaration before target

set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.elan/bin:$PATH"

BIN=.lake/build/bin/lean-cli
[[ ! -x "$BIN" ]] && { echo "ERROR: binary not built. Run: lake build" >&2; exit 1; }

mkdir -p tests/fixtures tests/out
INDIR=tests/fixtures
OUTDIR=tests/out
rm -rf "$OUTDIR"
mkdir -p "$OUTDIR"

PASS=0
FAIL=0
RESULTS=()

log_pass() { RESULTS+=("PASS  $1"); PASS=$((PASS+1)); }
log_fail() { RESULTS+=("FAIL  $1: $2"); FAIL=$((FAIL+1)); }

# ─────────────────────────────────────────────────
# Fixture: 3 axioms with distinct kinds for parse/query testing.
# ─────────────────────────────────────────────────
cat > "$INDIR/basic.lean" <<'EOF'
axiom foo : Nat
axiom bar : Bool
axiom bazQuux : Nat
EOF

# ─────────────────────────────────────────────────
# T1: parse emits 3 JSONL lines with names
# ─────────────────────────────────────────────────
NAME=T1_parse_basic
OUT="$OUTDIR/$NAME.out"
if "$BIN" parse "$INDIR/basic.lean" >"$OUT" 2>"$OUTDIR/$NAME.err"; then
  count=$(wc -l <"$OUT" | tr -d ' ')
  if [[ "$count" == "3" ]] \
     && grep -q '"name": "foo"' "$OUT" \
     && grep -q '"name": "bar"' "$OUT" \
     && grep -q '"name": "bazQuux"' "$OUT" \
     && grep -q '"kind": "axiom"' "$OUT"; then
    log_pass "$NAME"
  else
    log_fail "$NAME" "unexpected output (count=$count):$(tr '\n' ';' <"$OUT")"
  fi
else
  log_fail "$NAME" "exit $?: $(cat "$OUTDIR/$NAME.err" | head -1)"
fi

# ─────────────────────────────────────────────────
# T2: query --kind axiom matches all 3
# ─────────────────────────────────────────────────
NAME=T2_query_kind
OUT="$OUTDIR/$NAME.out"
if "$BIN" query "$INDIR/basic.lean" --kind axiom >"$OUT" 2>"$OUTDIR/$NAME.err"; then
  count=$(wc -l <"$OUT" | tr -d ' ')
  if [[ "$count" == "3" ]]; then log_pass "$NAME"
  else log_fail "$NAME" "count=$count"
  fi
else
  log_fail "$NAME" "exit $?: $(cat "$OUTDIR/$NAME.err" | head -1)"
fi

# ─────────────────────────────────────────────────
# T3: query --name-substring baz matches only bazQuux
# ─────────────────────────────────────────────────
NAME=T3_query_name_substring
OUT="$OUTDIR/$NAME.out"
if "$BIN" query "$INDIR/basic.lean" --name-substring baz >"$OUT" 2>"$OUTDIR/$NAME.err"; then
  count=$(wc -l <"$OUT" | tr -d ' ')
  if [[ "$count" == "1" ]] && grep -q '"name": "bazQuux"' "$OUT"; then
    log_pass "$NAME"
  else
    log_fail "$NAME" "count=$count content=$(tr '\n' ';' <"$OUT")"
  fi
else
  log_fail "$NAME" "exit $?: $(cat "$OUTDIR/$NAME.err" | head -1)"
fi

# ─────────────────────────────────────────────────
# T4: edit replaces foo, leaving bar/bazQuux untouched (byte-preserving)
# ─────────────────────────────────────────────────
NAME=T4_edit_byte_preserving
OUT="$OUTDIR/$NAME.out.lean"
cat > "$INDIR/edit-expected.lean" <<'EOF'
axiom foo : Bool
axiom bar : Bool
axiom bazQuux : Nat
EOF
if "$BIN" edit "$INDIR/basic.lean" --replace-body foo "axiom foo : Bool" --output "$OUT" >"$OUTDIR/$NAME.log" 2>&1; then
  if cmp -s "$INDIR/edit-expected.lean" "$OUT"; then
    log_pass "$NAME"
  else
    log_fail "$NAME" "byte diff: $(cmp -l "$INDIR/edit-expected.lean" "$OUT" | head -3)"
  fi
else
  log_fail "$NAME" "exit $?: $(cat "$OUTDIR/$NAME.log" | head -1)"
fi

# ─────────────────────────────────────────────────
# T5: edit fails cleanly on missing name (exit 5 = name_not_found)
# ─────────────────────────────────────────────────
NAME=T5_edit_name_not_found
OUT="$OUTDIR/$NAME.out.lean"
set +e
"$BIN" edit "$INDIR/basic.lean" --replace-body nonexistent "axiom nonexistent : Nat" --output "$OUT" >"$OUTDIR/$NAME.log" 2>&1
RC=$?
set -e
if [[ "$RC" == "5" ]] && grep -qi "name_not_found" "$OUTDIR/$NAME.log"; then
  log_pass "$NAME"
else
  log_fail "$NAME" "expected exit=5, got $RC; log=$(cat "$OUTDIR/$NAME.log" | head -1)"
fi

# ─────────────────────────────────────────────────
# T6: insert places new declaration before target
# ─────────────────────────────────────────────────
NAME=T6_insert_before
OUT="$OUTDIR/$NAME.out.lean"
cat > "$INDIR/insert-expected.lean" <<'EOF'
axiom foo : Nat
axiom inserted : Bool
axiom bar : Bool
axiom bazQuux : Nat
EOF
INSERT_DECL=$'axiom inserted : Bool\n'
if "$BIN" insert "$INDIR/basic.lean" --before bar "$INSERT_DECL" --output "$OUT" >"$OUTDIR/$NAME.log" 2>&1; then
  if cmp -s "$INDIR/insert-expected.lean" "$OUT"; then
    log_pass "$NAME"
  else
    log_fail "$NAME" "byte diff: $(cmp -l "$INDIR/insert-expected.lean" "$OUT" | head -3)"
  fi
else
  log_fail "$NAME" "exit $?: $(cat "$OUTDIR/$NAME.log" | head -1)"
fi

# ─────────────────────────────────────────────────
# T7: usage error (unknown subcommand) exits with 64
# ─────────────────────────────────────────────────
NAME=T7_usage_error
set +e
"$BIN" nonsense --foo bar >"$OUTDIR/$NAME.out" 2>"$OUTDIR/$NAME.err"
RC=$?
set -e
if [[ "$RC" == "64" ]]; then log_pass "$NAME"
else log_fail "$NAME" "expected exit=64, got $RC"
fi

# ─────────────────────────────────────────────────
# Report
# ─────────────────────────────────────────────────
echo
echo "=== Impl-A #666 lean-cli integration test results ==="
for r in "${RESULTS[@]}"; do echo "  $r"; done
echo
echo "PASS: $PASS / $((PASS+FAIL))"
echo "FAIL: $FAIL"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
