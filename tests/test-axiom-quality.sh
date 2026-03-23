#!/usr/bin/env bash
# 公理体系の品質指標テスト
# 根拠: AxiomQuality.lean の指標定義 + formal-derivation-procedure.md §2.6
set -uo pipefail
BASE="$(git rev-parse --show-toplevel 2>/dev/null || echo /Users/nirarin/work/agent-manifesto)"
LEAN="$BASE/lean-formalization"
PASS=0; FAIL=0

echo "=== Axiom Quality Dashboard ==="

check() {
  local name="$1"; shift
  echo -n "$name... "
  if "$@" > /dev/null 2>&1; then
    echo "PASS"; PASS=$((PASS+1))
  else
    echo "FAIL"; FAIL=$((FAIL+1))
  fi
}

# --- Phase 1: 静的解析 (grep ベース) ---

echo ""
echo "--- Counts ---"

AXIOM_COUNT=$(grep -rc "^axiom [a-z]" "$LEAN/Manifest/"*.lean 2>/dev/null | awk -F: '{s+=$2}END{print s}')
THEOREM_COUNT=$(grep -rc "^theorem [a-z]" "$LEAN/Manifest/"*.lean 2>/dev/null | awk -F: '{s+=$2}END{print s}')
# sorry: lake build 成功 + sorry warning なし = sorry 0
SORRY_COUNT=0
if cd "$LEAN" && export PATH="$HOME/.elan/bin:$PATH" && lake build Manifest 2>&1 | grep -q "declaration uses 'sorry'"; then
  SORRY_COUNT=1
fi

echo "Axioms:   $AXIOM_COUNT"
echo "Theorems: $THEOREM_COUNT"
echo "Sorry:    $SORRY_COUNT"

# Compression ratio (100x scale)
if [ "$AXIOM_COUNT" -gt 0 ]; then
  COMPRESSION=$((THEOREM_COUNT * 100 / AXIOM_COUNT))
else
  COMPRESSION=0
fi
echo "Compression: $((COMPRESSION / 100)).$((COMPRESSION % 100))x"
echo ""

echo "--- Quality Checks ---"

# Q1: Sorry count = 0 (T₀-2: CIC 健全性)
check "Q1 Sorry-free (T₀-2)" test "$SORRY_COUNT" -eq 0

# Q2: Compression ratio ≥ 2.0 (H4: 表現力の近似指標, H7: 暫定閾値)
check "Q2 Compression ≥ 2.0x (H4)" test "$COMPRESSION" -ge 200

# Q3: lake build 成功 (H5: base theory preservation, T₀-2)
check "Q3 lake build succeeds (H5/H6)" bash -c "cd '$LEAN' && export PATH=\"\$HOME/.elan/bin:\$PATH\" && lake build Manifest 2>&1 | tail -1 | grep -q 'completed successfully'"

# Q4: 全 axiom に docstring あり (公理カード形式, 手順書 §2.5)
# axiom の直前行が -/ で終わっているか（docstring の閉じ）
AXIOM_WITH_DOC=$(cd "$LEAN" && grep -B1 "^axiom [a-z]" Manifest/*.lean | grep -c "\-/" || echo 0)
check "Q4 All axioms have docstrings (§2.5)" test "$AXIOM_WITH_DOC" -ge "$AXIOM_COUNT"

# Q5: Import DAG 層分離 (H3: independence 近似)
check "Q5 Axioms.lean imports only Ontology" bash -c "head -5 '$LEAN/Manifest/Axioms.lean' | grep -q 'import Manifest.Ontology' && ! head -5 '$LEAN/Manifest/Axioms.lean' | grep -q 'import Manifest.Observable'"

check "Q6 EmpiricalPostulates imports only Ontology" bash -c "head -5 '$LEAN/Manifest/EmpiricalPostulates.lean' | grep -q 'import Manifest.Ontology' && ! head -5 '$LEAN/Manifest/EmpiricalPostulates.lean' | grep -q 'import Manifest.Axioms'"

# Q7: warning 0
WARNING_COUNT=$(cd "$LEAN" && export PATH="$HOME/.elan/bin:$PATH" && lake build Manifest 2>&1 | grep -c "warning:" || true)
check "Q7 Build warnings = 0" test "$WARNING_COUNT" -eq 0

echo ""
echo "--- De Bruijn Factor ---"

FORMAL_LINES=$(wc -l "$LEAN/Manifest/"*.lean 2>/dev/null | tail -1 | awk '{print $1}')
INFORMAL_LINES=$(wc -l "$BASE/docs/formal-derivation-procedure.md" "$BASE/docs/mathematical-logic-terminology.md" "$BASE/docs/design-development-foundation.md" "$BASE/manifesto.md" 2>/dev/null | tail -1 | awk '{print $1}')

if [ "$INFORMAL_LINES" -gt 0 ]; then
  DEBRUIJN=$((FORMAL_LINES * 100 / INFORMAL_LINES))
  echo "Formal lines:   $FORMAL_LINES"
  echo "Informal lines: $INFORMAL_LINES"
  echo "De Bruijn:      $((DEBRUIJN / 100)).$((DEBRUIJN % 100))x"

  # Q8: De Bruijn factor 1.5-5.0x (H5: Wiedijk典型値, H7: 暫定閾値)
  check "Q8 De Bruijn 1.5-5.0x (H5)" test "$DEBRUIJN" -ge 150 -a "$DEBRUIJN" -le 500
else
  echo "Informal lines: (not found)"
fi

echo ""
echo "--- Hygiene Automation (H6) ---"

# Q9: Minimality 近似 — 全ての axiom 名が少なくとも 1 つの theorem で参照されているか
# T₀-1: #print axioms の代わりに grep ベースの近似
# axiom 名を完全な名前として抽出（: 以降の型シグネチャの手前まで）
AXIOM_NAMES=$(cd "$LEAN" && grep "^axiom [a-z]" Manifest/*.lean | sed 's/.*axiom \([a-zA-Z_0-9]*\).*/\1/' | sort -u)
UNUSED=0
for ax in $AXIOM_NAMES; do
  # axiom 定義行以外でこの完全な名前が使われているか（単語境界で検索）
  REFS=$(cd "$LEAN" && grep -rw "$ax" Manifest/*.lean --include="*.lean" | grep -v "^.*:axiom $ax" | grep -v "^.*axiom $ax " | grep -v "公理カード" | grep -v "Sorry" | wc -l | tr -d ' ')
  if [ "$REFS" -eq 0 ]; then
    UNUSED=$((UNUSED+1))
    echo "  WARNING: axiom '$ax' appears unused (0 references outside definition)"
  fi
done
echo "  Used: $((AXIOM_COUNT - UNUSED))/$AXIOM_COUNT axioms"
# NOTE: Q9 は品質指標。FAIL = 改善の余地あり（未使用 axiom の除去を検討）
check "Q9 No unused axioms (H1/H4)" test "$UNUSED" -eq 0

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
