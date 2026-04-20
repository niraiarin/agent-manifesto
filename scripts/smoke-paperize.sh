#!/usr/bin/env bash
# smoke-paperize.sh — end-to-end integration smoke for /paperize pipeline.
#
# Placed under scripts/ (not tests/) because steps 4-5 depend on external
# services (llama-server, LaTeX compiler) and are conditionally deferred.
# Not part of test-all.sh.
#
# Scope:
#   [A] aggregate-jsonl.sh            deterministic, always run
#   [B] update-todos.py               deterministic
#   [C] decay-expired-questions.py    deterministic
#   [D] verifier-refinement.py        deferred unless LLAMA_SERVER=1
#   [E] compile-paper.sh              deferred unless LATEX=1
#
# Usage:
#   bash scripts/smoke-paperize.sh
#   LLAMA_SERVER=1 bash scripts/smoke-paperize.sh   # include verifier
#   LATEX=1 bash scripts/smoke-paperize.sh          # include pdf compile

set -euo pipefail

BASE="$(cd "$(dirname "$0")/.." && pwd)"
cd "$BASE"

PASS=0
FAIL=0
DEFERRED=0

pass()     { echo "  [ok]    $1"; PASS=$((PASS+1)); }
fail()     { echo "  [fail]  $1"; FAIL=$((FAIL+1)); }
deferred() { echo "  [defer] $1"; DEFERRED=$((DEFERRED+1)); }

WORK="${TMPDIR:-/tmp}/paperize-smoke-$$"
mkdir -p "$WORK"
trap 'rm -rf "$WORK"' EXIT

echo "=== /paperize integration smoke ==="
echo "Work dir: $WORK"
echo ""

# --- Precondition: jsonl (real or fixture) ---
JSONL=".claude/metrics/p2-verified.jsonl"
if [ ! -f "$JSONL" ] || [ ! -s "$JSONL" ]; then
  echo "[pre] real jsonl missing; using fixture"
  JSONL="$WORK/fixture.jsonl"
  cat > "$JSONL" <<'EOF'
{"epoch":1776663606,"files":[".claude/hooks/example.sh"],"verdict":"PASS","evaluator":"logprob/qwen","evaluator_independent":true,"margin":0.818}
{"epoch":1776663800,"files":["scripts/aggregate-jsonl.sh"],"verdict":"PASS","source":"self-review"}
EOF
fi

# --- [A] aggregate-jsonl.sh ---
echo "[A] aggregate-jsonl.sh"
OUT="$WORK/docs/papers/test-slug"
if bash scripts/aggregate-jsonl.sh "$OUT" "$JSONL" "HEAD~3..HEAD" > "$WORK/aggregate.log" 2>&1; then
  pass "exit 0"
else
  fail "non-zero exit"
  cat "$WORK/aggregate.log"
  exit 1
fi

[ -f "$OUT/manifest.json" ]                         && pass "manifest.json"   || fail "manifest.json missing"
[ -f "$OUT/evidence/p2-verified-snapshot.jsonl" ]   && pass "snapshot jsonl"  || fail "snapshot missing"
[ -f "$OUT/evidence/commits.md" ]                   && pass "commits.md"      || fail "commits.md missing"
[ -f "$OUT/evidence/sources.md" ]                   && pass "sources.md"      || fail "sources.md missing"

VC=$(jq '.summary.verification_count' "$OUT/manifest.json")
if [ "$VC" -ge 1 ]; then pass "verification_count=$VC (>=1)"; else fail "verification_count=$VC"; fi

SCHEMA=$(jq -r '.schema_version' "$OUT/manifest.json")
[ "$SCHEMA" = "1" ] && pass "schema_version=1" || fail "schema_version=$SCHEMA"

# --- [B] update-todos.py ---
echo "[B] update-todos.py"
echo '{"category":"decisions","text":"adopted K=3","source":{"commit":"9159f62c"},"compatibility":"compatible change"}
{"category":"questions","text":"Does the halt rule generalize to N>128?"}
{"category":"findings","text":"Bidirectional cancels position bias +10.9pp","source":{"pr":637}}' \
  | python3 scripts/update-todos.py \
      --manifest "$OUT/manifest.json" \
      --output "$OUT/todos.md" \
      --decay-days 30 > "$WORK/update-todos.log" 2>&1 \
  && pass "exit 0" \
  || { fail "non-zero exit"; cat "$WORK/update-todos.log"; }

grep -q "## decisions" "$OUT/todos.md"   && pass "todos.md has ## decisions"  || fail "missing ## decisions"
grep -q "## questions" "$OUT/todos.md"   && pass "todos.md has ## questions"  || fail "missing ## questions"
grep -q "decay_at=" "$OUT/todos.md"      && pass "decay_at stamped"           || fail "decay_at missing"

# --- [C] decay-expired-questions.py ---
echo "[C] decay-expired-questions.py (synthetic future date)"
FUTURE=$(date -v+60d -u +%Y-%m-%d 2>/dev/null || date -d "+60 days" +%Y-%m-%d)
python3 scripts/decay-expired-questions.py \
  --todos "$OUT/todos.md" \
  --evidence-dir "$OUT/evidence" \
  --today "$FUTURE" > "$WORK/decay.log" 2>&1 \
  && pass "exit 0" \
  || { fail "non-zero exit"; cat "$WORK/decay.log"; }

if [ -f "$OUT/evidence/expired-questions.md" ]; then
  grep -q "Does the halt rule generalize" "$OUT/evidence/expired-questions.md" \
    && pass "question moved to expired-questions.md" \
    || fail "question not moved"
else
  fail "expired-questions.md not created"
fi

if grep -q "Does the halt rule generalize" "$OUT/todos.md"; then
  fail "question still in todos.md after decay"
else
  pass "question removed from todos.md"
fi

# --- [D] verifier-refinement.py (external: llama-server) ---
echo "[D] verifier-refinement.py"
if [ "${LLAMA_SERVER:-0}" = "1" ]; then
  echo "Paper version A (baseline with UNVERIFIED tags)." > "$WORK/paper-a.tex"
  echo "Paper version B (claims supported with internal citation commit 9159f62c)." > "$WORK/paper-b.tex"
  if python3 scripts/verifier-refinement.py \
      --paper-a "$WORK/paper-a.tex" --paper-b "$WORK/paper-b.tex" \
      --k-rounds 1 --out "$WORK/verdict.json" > "$WORK/verifier.log" 2>&1; then
    pass "exit 0"
    WIN=$(jq -r .winner "$WORK/verdict.json")
    HALT=$(jq -r .halt "$WORK/verdict.json")
    pass "verdict: winner=$WIN halt=$HALT"
  else
    fail "non-zero exit"
    cat "$WORK/verifier.log"
  fi
else
  deferred "LLAMA_SERVER=1 not set (requires llama-server on :8090)"
fi

# --- [E] compile-paper.sh (external: LaTeX) ---
echo "[E] compile-paper.sh"
if [ "${LATEX:-0}" = "1" ] && (command -v latexmk || command -v tectonic || command -v pdflatex) >/dev/null 2>&1; then
  cat > "$WORK/tiny.tex" <<'EOF'
\documentclass{article}
\begin{document}
Hello paperize smoke.
\end{document}
EOF
  if bash scripts/compile-paper.sh "$WORK/tiny.tex" "$WORK/tiny.pdf" > "$WORK/compile.log" 2>&1 && [ -f "$WORK/tiny.pdf" ]; then
    pass "tiny.pdf produced"
  else
    fail "compile failed"
    tail -20 "$WORK/compile.log"
  fi
else
  deferred "LATEX=1 not set or no compiler (install latexmk/tectonic/pdflatex)"
fi

# --- Summary ---
echo ""
echo "=== summary ==="
echo "  pass=$PASS  fail=$FAIL  deferred=$DEFERRED"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
