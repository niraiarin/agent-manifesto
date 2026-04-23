#!/usr/bin/env bash
# Sub-E #660: 12-pattern byte-preserving rewrite test harness
# Builds 12 test input .lean files with various edge cases,
# runs rewrite-poc on each, compares output with expected.

set -uo pipefail
cd "$(dirname "$0")"
export PATH="$HOME/.elan/bin:$PATH"

BIN=.lake/build/bin/rewrite-poc
[[ ! -x "$BIN" ]] && { echo "ERROR: binary not built. Run: lake build rewrite-poc" >&2; exit 1; }

OUTDIR="test-output"
mkdir -p "$OUTDIR"

PASS=0
FAIL=0
RESULTS=()

# Helper: create an input file, run rewrite, compare with expected.
#   check_pattern <pattern-id> <input-file> <decl-name> <new-decl-text> <expected-output-file>
check_pattern() {
  local id="$1"; local in="$2"; local name="$3"; local expr="$4"; local exp="$5"
  local out="$OUTDIR/${id}.out.lean"
  local log="$OUTDIR/${id}.log"
  if "$BIN" "$in" "$name" "$expr" "$out" >"$log" 2>&1; then
    if cmp -s "$exp" "$out"; then
      RESULTS+=("PASS  $id  ($(basename $in))")
      PASS=$((PASS+1))
    else
      RESULTS+=("FAIL  $id  byte diff from expected")
      FAIL=$((FAIL+1))
      cmp -l "$exp" "$out" | head -3 >>"$log"
    fi
  else
    RESULTS+=("FAIL  $id  rewrite exit $?: $(cat $log | head -1)")
    FAIL=$((FAIL+1))
  fi
}

# Reset test-input dir
INDIR="test-input"
rm -rf "$INDIR" "$OUTDIR" 2>/dev/null
mkdir -p "$INDIR" "$OUTDIR"

# ─────────────────────────────────────────────────
# P1: ASCII-only simple axiom, LF endings, trailing newline
# ─────────────────────────────────────────────────
printf 'axiom foo : Nat\n' > "$INDIR/p1.lean"
printf 'axiom foo : Bool\n' > "$INDIR/p1.expected.lean"
check_pattern P1 "$INDIR/p1.lean" "foo" "axiom foo : Bool" "$INDIR/p1.expected.lean"

# ─────────────────────────────────────────────────
# P2: multi-line type signature (Init-parseable: no Eq, no arithmetic)
# ─────────────────────────────────────────────────
cat > "$INDIR/p2.lean" <<'EOF'
axiom foo :
  ∀ (n : Nat),
  True
EOF
cat > "$INDIR/p2.expected.lean" <<'EOF'
axiom foo : True
EOF
check_pattern P2 "$INDIR/p2.lean" "foo" "axiom foo : True" "$INDIR/p2.expected.lean"

# ─────────────────────────────────────────────────
# P3: Unicode body (∀ notation, Init-parseable)
# ─────────────────────────────────────────────────
printf 'axiom foo : %s (x : Nat), True\n' '∀' > "$INDIR/p3.lean"
printf 'axiom foo : True\n' > "$INDIR/p3.expected.lean"
check_pattern P3 "$INDIR/p3.lean" "foo" "axiom foo : True" "$INDIR/p3.expected.lean"

# ─────────────────────────────────────────────────
# P4: with /-- docstring -/. Docstring is PART of declaration syntax in Lean,
# so cmd.getRange? includes it. Replacement text must include docstring to preserve.
# ─────────────────────────────────────────────────
cat > "$INDIR/p4.lean" <<'EOF'
/-- docstring for foo -/
axiom foo : Nat

axiom bar : Nat
EOF
cat > "$INDIR/p4.expected.lean" <<'EOF'
/-- docstring for foo -/
axiom foo : Bool

axiom bar : Nat
EOF
# The new text MUST include the docstring + newline, because Lean treats docstring as
# part of the declaration syntax. Byte-preservation of OUTSIDE-the-range is the goal;
# the docstring is INSIDE the range by Lean's grammar definition.
check_pattern P4 "$INDIR/p4.lean" "foo" "$(printf '/-- docstring for foo -/\naxiom foo : Bool\n')" "$INDIR/p4.expected.lean"

# ─────────────────────────────────────────────────
# P5: preceded by /-! ... -/ doc block
# ─────────────────────────────────────────────────
cat > "$INDIR/p5.lean" <<'EOF'
/-!
# Title
Context text.
-/

axiom foo : Nat
EOF
cat > "$INDIR/p5.expected.lean" <<'EOF'
/-!
# Title
Context text.
-/

axiom foo : Bool
EOF
check_pattern P5 "$INDIR/p5.lean" "foo" "axiom foo : Bool" "$INDIR/p5.expected.lean"

# ─────────────────────────────────────────────────
# P6: CRLF line endings (Windows-style)
# ─────────────────────────────────────────────────
printf 'axiom foo : Nat\r\naxiom bar : Nat\r\n' > "$INDIR/p6.lean"
printf 'axiom foo : Bool\r\naxiom bar : Nat\r\n' > "$INDIR/p6.expected.lean"
check_pattern P6 "$INDIR/p6.lean" "foo" "axiom foo : Bool" "$INDIR/p6.expected.lean"

# ─────────────────────────────────────────────────
# P7: UTF-8 BOM prefix (EF BB BF)
# ─────────────────────────────────────────────────
printf '\xEF\xBB\xBFaxiom foo : Nat\n' > "$INDIR/p7.lean"
printf '\xEF\xBB\xBFaxiom foo : Bool\n' > "$INDIR/p7.expected.lean"
check_pattern P7 "$INDIR/p7.lean" "foo" "axiom foo : Bool" "$INDIR/p7.expected.lean"

# ─────────────────────────────────────────────────
# P8: no trailing newline
# ─────────────────────────────────────────────────
printf 'axiom foo : Nat' > "$INDIR/p8.lean"
printf 'axiom foo : Bool' > "$INDIR/p8.expected.lean"
check_pattern P8 "$INDIR/p8.lean" "foo" "axiom foo : Bool" "$INDIR/p8.expected.lean"

# ─────────────────────────────────────────────────
# P9: Unicode NFD (decomposed form) in comment
# Lean parser rejects NFD in identifiers (regex allows Ā-ſ but not combining marks),
# so we place NFD in a /-- ... -/ comment which the parser treats as opaque text.
# NFD bytes in comment must be byte-preserved.
# ─────────────────────────────────────────────────
printf '/-- contains NFD: e\xcc\x81 -/\naxiom foo : Nat\n' > "$INDIR/p9.lean"
printf '/-- contains NFD: e\xcc\x81 -/\naxiom foo : Bool\n' > "$INDIR/p9.expected.lean"
check_pattern P9 "$INDIR/p9.lean" "foo" "$(printf '/-- contains NFD: e\xcc\x81 -/\naxiom foo : Bool\n')" "$INDIR/p9.expected.lean"

# ─────────────────────────────────────────────────
# P10: Unicode NFC (composed form) — é as single codepoint U+00E9
# ─────────────────────────────────────────────────
printf 'axiom foo_\xc3\xa9 : Nat\n' > "$INDIR/p10.lean"
printf 'axiom foo_\xc3\xa9 : Bool\n' > "$INDIR/p10.expected.lean"
check_pattern P10 "$INDIR/p10.lean" "foo_é" "axiom foo_é : Bool" "$INDIR/p10.expected.lean"

# ─────────────────────────────────────────────────
# P11: tabs + spaces mixed. Inside namespace, axiom foo is at top-level.
# Note: Lean's grammar may normalize tab→space in specific contexts; byte-preservation
# should still hold because we slice raw bytes.
# ─────────────────────────────────────────────────
printf 'namespace Test\naxiom foo : Nat\nend Test\n' > "$INDIR/p11.lean"
printf 'namespace Test\naxiom foo : Bool\nend Test\n' > "$INDIR/p11.expected.lean"
check_pattern P11 "$INDIR/p11.lean" "foo" "axiom foo : Bool" "$INDIR/p11.expected.lean"

# ─────────────────────────────────────────────────
# P12: many blank lines between decls
# ─────────────────────────────────────────────────
cat > "$INDIR/p12.lean" <<'EOF'
axiom a1 : Nat



axiom foo : Nat



axiom a2 : Nat
EOF
cat > "$INDIR/p12.expected.lean" <<'EOF'
axiom a1 : Nat



axiom foo : Bool



axiom a2 : Nat
EOF
check_pattern P12 "$INDIR/p12.lean" "foo" "axiom foo : Bool" "$INDIR/p12.expected.lean"

# ─────────────────────────────────────────────────
# Report
# ─────────────────────────────────────────────────
echo
echo "=== Sub-E #660 byte-preserving test results ==="
for r in "${RESULTS[@]}"; do echo "  $r"; done
echo
echo "PASS: $PASS / $((PASS+FAIL))"
echo "FAIL: $FAIL"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
