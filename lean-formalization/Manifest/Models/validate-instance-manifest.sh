#!/usr/bin/env bash
# validate-instance-manifest.sh
#
# 条件付き公理系インスタンスマニフェストを検証する汎用スクリプト。
# instance-manifest-schema.json に準拠する任意のマニフェストに対応。
#
# 検証項目:
#   1. JSON パース可能性
#   2. 必須フィールドの存在
#   3. TemporalValidity 鮮度チェック（stale assumption 検出）
#   4. カバレッジ計算（axiom_to_config / config_to_axiom）
#   5. 逆方向整合性（config_to_axiom の axiomId が axiom_to_config に存在するか）
#
# Usage:
#   bash validate-instance-manifest.sh <manifest.json> [--stale-threshold=DAYS]
#
# Exit codes:
#   0 = all checks passed
#   1 = validation errors found

set -euo pipefail

MANIFEST="${1:-}"
STALE_THRESHOLD="${2:-90}"

# Parse --stale-threshold= option
for arg in "$@"; do
  case $arg in
    --stale-threshold=*) STALE_THRESHOLD="${arg#*=}" ;;
  esac
done

if [ -z "$MANIFEST" ] || [ ! -f "$MANIFEST" ]; then
  echo "Usage: $0 <manifest.json> [--stale-threshold=DAYS]" >&2
  exit 1
fi

if ! command -v jq &> /dev/null; then
  echo "Error: jq is required" >&2
  exit 1
fi

ERRORS=0
WARNINGS=0

pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; ERRORS=$((ERRORS + 1)); }
warn() { echo "  ⚠ $1"; WARNINGS=$((WARNINGS + 1)); }

echo "=== Validating: $MANIFEST ==="
echo ""

# ============================================================
# 1. JSON パース
# ============================================================
echo "--- 1. JSON Parse ---"
if ! jq empty "$MANIFEST" 2>/dev/null; then
  fail "Invalid JSON"
  echo ""
  echo "=== FAILED: Cannot parse JSON ==="
  exit 1
fi
pass "Valid JSON"

# ============================================================
# 2. 必須フィールド
# ============================================================
echo "--- 2. Required Fields ---"

for field in version system assumptions axiom_to_config config_to_axiom; do
  if jq -e ".$field" "$MANIFEST" > /dev/null 2>&1; then
    pass "$field exists"
  else
    fail "$field missing"
  fi
done

SYSTEM_NAME=$(jq -r '.system.name // "unknown"' "$MANIFEST")
pass "System: $SYSTEM_NAME"

# ============================================================
# 3. TemporalValidity 鮮度チェック
# ============================================================
echo "--- 3. TemporalValidity Freshness ---"

TODAY=$(date +%Y-%m-%d)
TODAY_EPOCH=$(date -j -f "%Y-%m-%d" "$TODAY" "+%s" 2>/dev/null || date -d "$TODAY" "+%s" 2>/dev/null || echo 0)

NUM_ASSUMPTIONS=$(jq '.assumptions | length' "$MANIFEST")
STALE_COUNT=0
FRESH_COUNT=0
NO_VALIDITY_COUNT=0

for i in $(seq 0 $((NUM_ASSUMPTIONS - 1))); do
  ID=$(jq -r ".assumptions[$i].id" "$MANIFEST")
  LAST_VERIFIED=$(jq -r ".assumptions[$i].lastVerified // empty" "$MANIFEST")
  REVIEW_INTERVAL=$(jq -r ".assumptions[$i].reviewInterval // empty" "$MANIFEST")

  if [ -z "$LAST_VERIFIED" ]; then
    NO_VALIDITY_COUNT=$((NO_VALIDITY_COUNT + 1))
    warn "$ID: no lastVerified date"
    continue
  fi

  if [ -n "$REVIEW_INTERVAL" ] && [ "$REVIEW_INTERVAL" != "null" ]; then
    VERIFIED_EPOCH=$(date -j -f "%Y-%m-%d" "$LAST_VERIFIED" "+%s" 2>/dev/null || date -d "$LAST_VERIFIED" "+%s" 2>/dev/null || echo 0)
    if [ "$TODAY_EPOCH" -gt 0 ] && [ "$VERIFIED_EPOCH" -gt 0 ]; then
      DAYS_SINCE=$(( (TODAY_EPOCH - VERIFIED_EPOCH) / 86400 ))
      if [ "$DAYS_SINCE" -gt "$REVIEW_INTERVAL" ]; then
        fail "$ID: STALE (last verified $LAST_VERIFIED, interval ${REVIEW_INTERVAL}d, ${DAYS_SINCE}d ago)"
        STALE_COUNT=$((STALE_COUNT + 1))
      else
        FRESH_COUNT=$((FRESH_COUNT + 1))
      fi
    else
      FRESH_COUNT=$((FRESH_COUNT + 1))
    fi
  else
    FRESH_COUNT=$((FRESH_COUNT + 1))
  fi
done

pass "Assumptions: $NUM_ASSUMPTIONS total, $FRESH_COUNT fresh, $STALE_COUNT stale, $NO_VALIDITY_COUNT no-validity"

# ============================================================
# 4. カバレッジ計算
# ============================================================
echo "--- 4. Coverage ---"

NUM_AXIOMS=$(jq '.axiom_to_config | length' "$MANIFEST")
NUM_CONFIGS=$(jq '.config_to_axiom | length' "$MANIFEST")
CONFIGS_WITH_AXIOM=$(jq '[.config_to_axiom[] | select(.axiomIds | length > 0)] | length' "$MANIFEST")
CONFIGS_WITHOUT_AXIOM=$(jq '[.config_to_axiom[] | select(.axiomIds | length == 0)] | length' "$MANIFEST")

pass "Axiom→Config mappings: $NUM_AXIOMS"
pass "Config→Axiom mappings: $NUM_CONFIGS ($CONFIGS_WITH_AXIOM covered, $CONFIGS_WITHOUT_AXIOM uncovered)"

if [ "$NUM_CONFIGS" -gt 0 ]; then
  COVERAGE=$(echo "scale=1; $CONFIGS_WITH_AXIOM * 100 / $NUM_CONFIGS" | bc)
  pass "Coverage: ${COVERAGE}%"
else
  warn "No config_to_axiom entries"
fi

# ============================================================
# 5. 逆方向整合性
# ============================================================
echo "--- 5. Reverse Consistency ---"

# axiom_to_config の axiomId を全て収集
AXIOM_IDS=$(jq -r '.axiom_to_config[].axiomId' "$MANIFEST" | sort -u)

# config_to_axiom の axiomIds を全て収集
CONFIG_AXIOM_IDS=$(jq -r '.config_to_axiom[].axiomIds[]' "$MANIFEST" 2>/dev/null | sort -u)

# config_to_axiom にあって axiom_to_config にない axiomId を検出
ORPHAN_COUNT=0
for cid in $CONFIG_AXIOM_IDS; do
  if ! echo "$AXIOM_IDS" | grep -qx "$cid"; then
    fail "Orphan axiomId in config_to_axiom: $cid (not in axiom_to_config)"
    ORPHAN_COUNT=$((ORPHAN_COUNT + 1))
  fi
done

if [ "$ORPHAN_COUNT" -eq 0 ]; then
  pass "All config_to_axiom axiomIds exist in axiom_to_config"
fi

# ============================================================
# 6. PD トレーサビリティ（D17 Step 0 → Step 1）
# ============================================================
echo "--- 6. PD Traceability ---"

# platform-decisions.json の存在確認
MANIFEST_DIR=$(dirname "$MANIFEST")
PD_FILE="$MANIFEST_DIR/platform-decisions.json"

if [ -f "$PD_FILE" ]; then
  pass "platform-decisions.json exists"

  # 各仮定に derivedFromPDs があるか
  ASSUMPTIONS_WITH_PD=$(jq '[.assumptions[] | select(.derivedFromPDs != null and (.derivedFromPDs | length) > 0)] | length' "$MANIFEST")
  ASSUMPTIONS_WITHOUT_PD=$(jq '[.assumptions[] | select(.derivedFromPDs == null or (.derivedFromPDs | length) == 0)] | length' "$MANIFEST")

  pass "Assumptions with PD traceability: $ASSUMPTIONS_WITH_PD"
  if [ "$ASSUMPTIONS_WITHOUT_PD" -gt 0 ]; then
    warn "$ASSUMPTIONS_WITHOUT_PD assumptions lack derivedFromPDs"
  fi

  # derivedFromPDs の PD ID が platform-decisions.json に存在するか
  PD_IDS=$(jq -r '.decisions[].id' "$PD_FILE" 2>/dev/null | sort -u)
  ORPHAN_PD=0
  for pid in $(jq -r '.assumptions[].derivedFromPDs[]?' "$MANIFEST" 2>/dev/null | sort -u); do
    if ! echo "$PD_IDS" | grep -qx "$pid"; then
      warn "Assumption references PD $pid not found in platform-decisions.json"
      ORPHAN_PD=$((ORPHAN_PD + 1))
    fi
  done
  if [ "$ORPHAN_PD" -eq 0 ] && [ "$ASSUMPTIONS_WITH_PD" -gt 0 ]; then
    pass "All referenced PDs exist in platform-decisions.json"
  fi
else
  warn "platform-decisions.json not found (Step 0 output not persisted)"
fi

# ============================================================
# Summary
# ============================================================
echo ""
echo "=== Summary ==="
echo "System: $SYSTEM_NAME"
echo "Errors: $ERRORS"
echo "Warnings: $WARNINGS"

if [ "$ERRORS" -gt 0 ]; then
  echo "=== FAILED ==="
  exit 1
else
  echo "=== PASSED ==="
  exit 0
fi
