#!/usr/bin/env bash
# scripts/check-doc-length.sh — verifier_history evaluator + day_plan scope の length lint
# Day 78 N2 [Gap B] (Documentation inflation 規律強化)
#
# Usage:
#   bash scripts/check-doc-length.sh           # 全 entry スキャン、超過は WARN
#   bash scripts/check-doc-length.sh --strict  # 超過は FAIL (exit 1)
#
# 規律 (CLAUDE.md "Documentation minimalism (B)" 反映):
#   - verifier_history evaluator: ≤ 600 chars (≈ 4 文)
#   - day_plan scope: ≤ 400 chars (≈ 3 文)
#   - ceremonial token (「N 度目」「段階発展」「極致到達」「ぶり」「完遂」) 検出
#
# 終了コード:
#   0  ALL PASS or WARN-only
#   1  --strict 時の超過 detect

set -u
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
MANIFEST="$REPO_ROOT/agent-spec-lib/artifact-manifest.json"
PENDING="$REPO_ROOT/docs/research/new-foundation-survey/11-pending-tasks.json"

MODE="${1:-warn}"
EVAL_LIMIT=600
SCOPE_LIMIT=400
CEREMONIAL_PATTERN='(N 度目|段階発展|極致到達|Day [0-9]+ ぶり|完遂)'

EXIT=0

echo "=== check-doc-length (mode=${MODE}, verifier_history+day_plan scan) ==="

# Check 1: verifier_history evaluator length (Day 70 以降の entry 限定、legacy 除外)
LONG_EVALS=$(jq -r --argjson lim "$EVAL_LIMIT" '
  .verifier_history
  | to_entries
  | map(select(.value.evaluator != null))
  | map(select(.value.round | test("Day (7[0-9]|[89][0-9]|[1-9][0-9]{2,})")))
  | map(select((.value.evaluator | length) > $lim))
  | map("[\(.value.round)] evaluator=\(.value.evaluator | length) chars (limit \($lim))")
  | .[]
' "$MANIFEST" 2>/dev/null | head -10)

if [ -n "$LONG_EVALS" ]; then
  echo "[1] WARN  verifier_history evaluator が ${EVAL_LIMIT} chars 超過 (Day 70+):"
  echo "$LONG_EVALS" | sed 's/^/    /'
  [ "$MODE" = "--strict" ] && EXIT=1
else
  echo "[1] OK  verifier_history evaluator length (Day 70+、≤ ${EVAL_LIMIT} chars)"
fi

# Check 2: day_plan scope length (Day 70 以降の entry 限定)
LONG_SCOPES=$(jq -r --argjson lim "$SCOPE_LIMIT" '
  .day_plan
  | map(select(.scope != null))
  | map(select((.day | tostring | tonumber? // 0) >= 70))
  | map(select((.scope | length) > $lim))
  | map("[Day \(.day)] scope=\(.scope | length) chars (limit \($lim))")
  | .[]
' "$PENDING" 2>/dev/null | head -10)

if [ -n "$LONG_SCOPES" ]; then
  echo "[2] WARN  day_plan scope が ${SCOPE_LIMIT} chars 超過 (Day 70+):"
  echo "$LONG_SCOPES" | sed 's/^/    /'
  [ "$MODE" = "--strict" ] && EXIT=1
else
  echo "[2] OK  day_plan scope length (Day 70+、≤ ${SCOPE_LIMIT} chars)"
fi

# Check 3: ceremonial token in Day 70+ entries (legacy 除外)
CEREMONIAL_HITS=$(jq -r '
  .verifier_history
  | map(select(.round | test("Day (7[0-9]|[89][0-9]|[1-9][0-9]{2,})")))
  | map([.round, (.evaluator // ""), (.scope // "")] | join(" "))
  | .[]
' "$MANIFEST" 2>/dev/null | grep -E "$CEREMONIAL_PATTERN" | head -5)

if [ -n "$CEREMONIAL_HITS" ]; then
  echo "[3] WARN  ceremonial token detected in Day 70+ verifier_history:"
  echo "$CEREMONIAL_HITS" | sed 's/^/    /' | head -3
  [ "$MODE" = "--strict" ] && EXIT=1
else
  echo "[3] OK  ceremonial token なし (Day 70+ verifier_history)"
fi

echo ""
echo "=== Summary ==="
if [ "$EXIT" -ne 0 ]; then
  echo "FAIL: --strict mode で超過 detect、commit 前に compress 推奨"
  exit 1
else
  echo "PASS (warning は informational)"
  exit 0
fi
