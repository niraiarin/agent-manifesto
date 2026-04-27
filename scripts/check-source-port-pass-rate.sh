#!/usr/bin/env bash
# Phase 6 sprint 2 D #1: comprehensive pass rate calculator (Day 201)
#
# 目的: PI-17 statement parity audit を category-wise + per-Manifest-section の
#       pass rate report に拡張。CLEVER style evaluation framework の base。
#
# 出力: stdout に category × pass_rate matrix + JSON 形式 metrics

set -uo pipefail

REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
SOURCE_DIR="$REPO_ROOT/lean-formalization/Manifest"
PORT_DIR="$REPO_ROOT/agent-spec-lib/AgentSpec/Manifest"

# Allow-list (PI-17 と共有)
ALLOW_LIST="${REPO_ROOT}/scripts/parity-allow-list.txt"
KNOWN_ALLOWED=""
if [ -f "$ALLOW_LIST" ]; then
  KNOWN_ALLOWED=$(grep -vE '^[[:space:]]*#|^[[:space:]]*$' "$ALLOW_LIST" 2>/dev/null | sort -u)
fi

# Extract decl_kind + name from a Lean file
# Format: KIND<TAB>NAME<TAB>FILE
extract_kind_name() {
  local DIR="$1"
  find "$DIR" -name "*.lean" -type f -print0 | while IFS= read -r -d '' f; do
    grep -hE '^(axiom|theorem) [a-zA-Z_][a-zA-Z0-9_]*' "$f" 2>/dev/null | while IFS= read -r line; do
      kind=$(echo "$line" | sed -E 's/^(axiom|theorem) .*/\1/')
      name=$(echo "$line" | sed -E 's/^(axiom|theorem) ([a-zA-Z_][a-zA-Z0-9_]*).*/\2/')
      printf '%s\t%s\t%s\n' "$kind" "$name" "${f##*/}"
    done
  done | sort -u
}

SOURCE_TMP="${TMPDIR:-/tmp}/passrate-source-$$.txt"
PORT_TMP="${TMPDIR:-/tmp}/passrate-port-$$.txt"
trap 'rm -f "$SOURCE_TMP" "$PORT_TMP"' EXIT

extract_kind_name "$SOURCE_DIR" > "$SOURCE_TMP"
extract_kind_name "$PORT_DIR" > "$PORT_TMP"

# Per-kind tallies
echo "=== Comprehensive pass rate (Phase 6 D #1) ==="
echo ""

for kind in axiom theorem; do
  SRC_NAMES=$(awk -F'\t' -v k="$kind" '$1 == k {print $2}' "$SOURCE_TMP" | sort -u)
  PRT_NAMES=$(awk -F'\t' -v k="$kind" '$1 == k {print $2}' "$PORT_TMP" | sort -u)
  SRC_COUNT=$(echo "$SRC_NAMES" | grep -cv '^$' 2>/dev/null || echo 0)
  PRT_COUNT=$(echo "$PRT_NAMES" | grep -cv '^$' 2>/dev/null || echo 0)
  COMMON=$(comm -12 <(echo "$SRC_NAMES") <(echo "$PRT_NAMES"))
  COMMON_COUNT=$([ -z "$COMMON" ] && echo 0 || echo "$COMMON" | grep -cv '^$' || echo 0)
  if [ "$SRC_COUNT" -eq 0 ]; then
    PASS_RATE_BY_NAME="0.0"
  else
    PASS_RATE_BY_NAME=$(echo "scale=2; $COMMON_COUNT * 100 / $SRC_COUNT" | bc)
  fi
  echo "[$kind] source=$SRC_COUNT port=$PRT_COUNT common=$COMMON_COUNT (name pass-rate ${PASS_RATE_BY_NAME}%)"
done

# Per-Manifest-section tallies (file-grouped)
echo ""
echo "--- per-file pass rate (top-level Manifest) ---"
SRC_FILES=$(find "$SOURCE_DIR" -maxdepth 1 -name "*.lean" -type f | xargs -n1 basename | sort -u)
for fname in $SRC_FILES; do
  SRC_DECLS=$(awk -F'\t' -v f="$fname" '$3 == f {print $2}' "$SOURCE_TMP" | sort -u)
  SRC_N=$(echo "$SRC_DECLS" | grep -cv '^$' 2>/dev/null || echo 0)
  if [ "$SRC_N" -eq 0 ]; then continue; fi
  PRT_DECLS=$(awk -F'\t' -v f="$fname" '$3 == f {print $2}' "$PORT_TMP" | sort -u)
  COMMON_FILE=$(comm -12 <(echo "$SRC_DECLS") <(echo "$PRT_DECLS"))
  COMMON_FN=$([ -z "$COMMON_FILE" ] && echo 0 || echo "$COMMON_FILE" | grep -cv '^$' || echo 0)
  if [ "$SRC_N" -eq 0 ]; then RATE="0"; else RATE=$(echo "scale=0; $COMMON_FN * 100 / $SRC_N" | bc); fi
  printf "  %-32s %3d/%3d = %3d%%\n" "$fname" "$COMMON_FN" "$SRC_N" "$RATE"
done

# JSON metrics output
echo ""
echo "--- JSON metrics ---"
TOTAL_SRC=$(wc -l < "$SOURCE_TMP" | tr -d ' ')
TOTAL_PRT=$(wc -l < "$PORT_TMP" | tr -d ' ')
TOTAL_COMMON=$(comm -12 <(awk -F'\t' '{print $2}' "$SOURCE_TMP" | sort -u) <(awk -F'\t' '{print $2}' "$PORT_TMP" | sort -u) | wc -l | tr -d ' ')
ALLOW_COUNT=$([ -z "$KNOWN_ALLOWED" ] && echo 0 || echo "$KNOWN_ALLOWED" | grep -cv '^$' || echo 0)

cat <<JSON
{
  "phase": 6,
  "sprint": 2,
  "criterion": "D-1-pass-rate",
  "source_total": $TOTAL_SRC,
  "port_total": $TOTAL_PRT,
  "common_count": $TOTAL_COMMON,
  "allow_listed_divergent": $ALLOW_COUNT,
  "name_pass_rate_pct": $(if [ "$TOTAL_SRC" -gt 0 ]; then echo "scale=1; $TOTAL_COMMON * 100 / $TOTAL_SRC" | bc; else echo 0; fi)
}
JSON
