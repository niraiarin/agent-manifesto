#!/usr/bin/env bash
# Axiom Card 完全性テスト — 全 47 命題に Axiom Card が存在するかを検証
# 根拠: Traceability 4層モデル 層3（根拠完全性）
# manifest-trace evidence の出力（JSON Lines）から命題カバレッジを計測
set -uo pipefail
BASE="$(git rev-parse --show-toplevel 2>/dev/null || echo /Users/nirarin/work/agent-manifesto)"
PASS=0; FAIL=0

echo "=== Axiom Card Coverage Tests ==="

check() {
  local id="$1" name="$2"; shift 2
  echo -n "  $id: $name... "
  if "$@" > /dev/null 2>&1; then
    echo "PASS"; PASS=$((PASS+1))
  else
    echo "FAIL"; FAIL=$((FAIL+1))
  fi
}

# 全 47 命題
ALL_PROPS="T1 T2 T3 T4 T5 T6 T7 T8 E1 E2 P1 P2 P3 P4 P5 P6 L1 L2 L3 L4 L5 L6 D1 D2 D3 D4 D5 D6 D7 D8 D9 D10 D11 D12 D13 D14 D15 D16 D17 D18 V1 V2 V3 V4 V5 V6 V7"
TOTAL=$(echo $ALL_PROPS | wc -w | tr -d ' ')

# manifest-trace evidence + derivations からカバーされている命題を抽出
# Axiom Card (axiom 宣言) と Derivation Card (theorem 宣言) の両方を根拠として認める
EVIDENCE=$("$BASE/manifest-trace" evidence 2>/dev/null || true)
DERIVATIONS=$("$BASE/manifest-trace" derivations 2>/dev/null || true)
COVERED_PROPS=$(printf '%s\n%s\n' \
  "$(echo "$EVIDENCE" | jq -r '.proposition' 2>/dev/null)" \
  "$(echo "$DERIVATIONS" | jq -r '.proposition' 2>/dev/null)" \
  | sort -u | grep -v '^$' | tr '\n' ' ')
COVERED_COUNT=$(echo "$COVERED_PROPS" | wc -w | tr -d ' ')

echo ""
echo "--- Axiom Card カバレッジサマリ ---"
echo "総命題数:     $TOTAL"
echo "カバー済み:   $COVERED_COUNT"
echo "未カバー:     $((TOTAL - COVERED_COUNT))"
echo ""

# AC.1: manifest-trace evidence/derivations が実行可能
check "AC.1" "manifest-trace evidence+derivations は実行可能" test -n "$EVIDENCE" -o -n "$DERIVATIONS"

# AC.2: カバレッジが 0 より大きい
check "AC.2" "Axiom Card カバレッジ > 0%" test "$COVERED_COUNT" -gt 0

# AC.3: 各命題カテゴリでの個別チェック
echo ""
echo "--- カテゴリ別カバレッジ ---"

for category in "T:T1 T2 T3 T4 T5 T6 T7 T8" "E:E1 E2" "P:P1 P2 P3 P4 P5 P6" "L:L1 L2 L3 L4 L5 L6" "D:D1 D2 D3 D4 D5 D6 D7 D8 D9 D10 D11 D12 D13 D14 D15 D16 D17 D18" "V:V1 V2 V3 V4 V5 V6 V7"; do
  cat_name="${category%%:*}"
  cat_props="${category#*:}"
  cat_total=$(echo $cat_props | wc -w | tr -d ' ')
  cat_covered=0
  cat_missing=""
  for prop in $cat_props; do
    if echo "$COVERED_PROPS" | grep -qw "$prop"; then
      cat_covered=$((cat_covered + 1))
    else
      cat_missing="$cat_missing $prop"
    fi
  done
  printf "  %s: %d/%d" "$cat_name" "$cat_covered" "$cat_total"
  if [ -n "$cat_missing" ]; then
    printf "  (missing:%s)" "$cat_missing"
  fi
  echo ""
done

# AC.4: 全命題カバレッジは最終目標（現時点では XFAIL として記録）
echo ""
echo "--- 完全性チェック ---"
MISSING=""
for prop in $ALL_PROPS; do
  if ! echo "$COVERED_PROPS" | grep -qw "$prop"; then
    MISSING="$MISSING $prop"
  fi
done

if [ -z "$MISSING" ]; then
  echo "  AC.3: 全命題に Axiom Card あり (47/47)... PASS"
  PASS=$((PASS+1))
else
  MISSING_COUNT=$(echo $MISSING | wc -w | tr -d ' ')
  echo "  AC.3: 全命題に Axiom Card あり ($COVERED_COUNT/$TOTAL)... XFAIL (未カバー $MISSING_COUNT 件:$MISSING)"
  # XFAIL: 既知の進行中ギャップ (#366)。FAIL カウントに含めない
  # 47/47 達成時に PASS に昇格する
  PASS=$((PASS+1))
fi

# AC.4: カバレッジが前回より後退していないか（回帰検出）
# 基準値: 47 命題 (2026-04-10 時点、evidence + derivations で全命題カバー)
BASELINE=47
echo -n "  AC.4: カバレッジ回帰なし (>= $BASELINE)... "
if [ "$COVERED_COUNT" -ge "$BASELINE" ]; then
  echo "PASS ($COVERED_COUNT >= $BASELINE)"
  PASS=$((PASS+1))
else
  echo "FAIL ($COVERED_COUNT < $BASELINE)"
  FAIL=$((FAIL+1))
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
exit $FAIL
