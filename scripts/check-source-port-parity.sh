#!/usr/bin/env bash
# Phase 5 PI-17: source ↔ port axiom/theorem statement parity audit (Day 192)
#
# 目的: lean-formalization/Manifest/* と agent-spec-lib/AgentSpec/Manifest/*
#       で同名 axiom/theorem の statement を比較、divergence を検出
#
# 出力: stdout に parity report (axiom/theorem name, source-only / port-only / divergent)
# exit code: 0 (no divergence) / 1 (divergence detected) / 2 (input error)
#
# 仕様:
# - source / port 両方から `^(axiom|theorem) NAME (...)` 形式を抽出
# - statement (signature 部分) を normalize:
#   - leading whitespace 削除
#   - namespace prefix `Manifest.` / `AgentSpec.Manifest.` を共通形 `MANIFEST.` に置換
# - source-only / port-only / common-divergent / common-parity の 4 カテゴリに分類

set -uo pipefail

REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
SOURCE_DIR="$REPO_ROOT/lean-formalization/Manifest"
PORT_DIR="$REPO_ROOT/agent-spec-lib/AgentSpec/Manifest"

if [ ! -d "$SOURCE_DIR" ] || [ ! -d "$PORT_DIR" ]; then
  echo "ERROR: source ($SOURCE_DIR) or port ($PORT_DIR) directory not found" >&2
  exit 2
fi

# Extract names + first-line signatures
# Format: NAME<TAB>NORMALIZED_SIGNATURE
extract_decls() {
  local DIR="$1"
  local NAMESPACE_PREFIX="$2"  # "Manifest." or "AgentSpec.Manifest."
  # Step 1: grep for declaration lines
  # Step 2: extract NAME via sed
  # Step 3: normalize signature (strip namespace prefix, leading whitespace)
  find "$DIR" -name "*.lean" -type f -print0 | while IFS= read -r -d '' f; do
    grep -hE '^(axiom|theorem) [a-zA-Z_][a-zA-Z0-9_]*' "$f" 2>/dev/null
  done | while IFS= read -r line; do
    # Extract name: 第 2 word (axiom/theorem の次)
    name=$(echo "$line" | sed -E 's/^(axiom|theorem) ([a-zA-Z_][a-zA-Z0-9_]*).*/\2/')
    # Normalize signature
    sig=$(echo "$line" | sed -E "s|${NAMESPACE_PREFIX}|MANIFEST.|g; s|^[ \t]+||")
    printf '%s\t%s\n' "$name" "$sig"
  done | sort -u
}

SOURCE_TMP="${TMPDIR:-/tmp}/parity-source-$$.txt"
PORT_TMP="${TMPDIR:-/tmp}/parity-port-$$.txt"
trap 'rm -f "$SOURCE_TMP" "$PORT_TMP"' EXIT

extract_decls "$SOURCE_DIR" "Manifest." > "$SOURCE_TMP"
extract_decls "$PORT_DIR" "AgentSpec.Manifest." > "$PORT_TMP"

SOURCE_COUNT=$(wc -l < "$SOURCE_TMP" | tr -d ' ')
PORT_COUNT=$(wc -l < "$PORT_TMP" | tr -d ' ')
echo "=== Statement parity audit (Phase 5 PI-17) ==="
echo "source decls (axiom + theorem): $SOURCE_COUNT"
echo "port decls   (axiom + theorem): $PORT_COUNT"
echo ""

# Names only
SOURCE_NAMES=$(awk -F'\t' '{print $1}' "$SOURCE_TMP" | sort -u)
PORT_NAMES=$(awk -F'\t' '{print $1}' "$PORT_TMP" | sort -u)

SOURCE_ONLY=$(comm -23 <(echo "$SOURCE_NAMES") <(echo "$PORT_NAMES"))
PORT_ONLY=$(comm -13 <(echo "$SOURCE_NAMES") <(echo "$PORT_NAMES"))
COMMON=$(comm -12 <(echo "$SOURCE_NAMES") <(echo "$PORT_NAMES"))

SOURCE_ONLY_COUNT=$([ -z "$SOURCE_ONLY" ] && echo 0 || echo "$SOURCE_ONLY" | wc -l | tr -d ' ')
PORT_ONLY_COUNT=$([ -z "$PORT_ONLY" ] && echo 0 || echo "$PORT_ONLY" | wc -l | tr -d ' ')
COMMON_COUNT=$([ -z "$COMMON" ] && echo 0 || echo "$COMMON" | wc -l | tr -d ' ')

echo "--- name-level parity ---"
echo "source-only (port で missing): $SOURCE_ONLY_COUNT"
echo "port-only   (source 由来でない): $PORT_ONLY_COUNT"
echo "common      (両方に存在): $COMMON_COUNT"
echo ""

# Allow-list: 既知の divergence (PI-9 native_decide → decide 由来など)
# 1 line per name、コメント # で skip
ALLOW_LIST="${REPO_ROOT}/scripts/parity-allow-list.txt"
KNOWN_ALLOWED=""
if [ -f "$ALLOW_LIST" ]; then
  KNOWN_ALLOWED=$(grep -vE '^[[:space:]]*#|^[[:space:]]*$' "$ALLOW_LIST" 2>/dev/null | sort -u)
fi

# Statement-level divergence (common names のみ)
DIVERGENT_COUNT=0
ALLOWED_DIVERGENT_COUNT=0
DIVERGENT_LIST=""
ALLOWED_DIVERGENT_LIST=""
if [ -n "$COMMON" ]; then
  while IFS= read -r name; do
    [ -z "$name" ] && continue
    SRC_SIG=$(awk -F'\t' -v n="$name" '$1 == n {print $2; exit}' "$SOURCE_TMP")
    PRT_SIG=$(awk -F'\t' -v n="$name" '$1 == n {print $2; exit}' "$PORT_TMP")
    if [ "$SRC_SIG" != "$PRT_SIG" ]; then
      # Check allow-list
      if echo "$KNOWN_ALLOWED" | grep -qFx "$name" 2>/dev/null; then
        ALLOWED_DIVERGENT_COUNT=$((ALLOWED_DIVERGENT_COUNT + 1))
        ALLOWED_DIVERGENT_LIST="${ALLOWED_DIVERGENT_LIST}${name}\n"
      else
        DIVERGENT_COUNT=$((DIVERGENT_COUNT + 1))
        DIVERGENT_LIST="${DIVERGENT_LIST}${name}\n"
      fi
    fi
  done <<< "$COMMON"
fi

echo "--- statement-level parity (common names) ---"
echo "byte-identical:    $((COMMON_COUNT - DIVERGENT_COUNT - ALLOWED_DIVERGENT_COUNT)) / $COMMON_COUNT"
echo "allow-listed div:  $ALLOWED_DIVERGENT_COUNT / $COMMON_COUNT (既知 = PI-9 native_decide 由来等)"
echo "unallowed div:     $DIVERGENT_COUNT / $COMMON_COUNT"

VERBOSE="${1:-}"
if [ "$VERBOSE" = "--verbose" ]; then
  if [ -n "$SOURCE_ONLY" ]; then
    echo ""
    echo "--- source-only (port で port されていない、最大 20 件) ---"
    echo "$SOURCE_ONLY" | head -20 | sed 's/^/    /'
  fi
  if [ -n "$PORT_ONLY" ]; then
    echo ""
    echo "--- port-only (port で追加された、最大 20 件) ---"
    echo "$PORT_ONLY" | head -20 | sed 's/^/    /'
  fi
  if [ "$DIVERGENT_COUNT" -gt 0 ]; then
    echo ""
    echo "--- divergent statements (最大 20 件) ---"
    echo -e "$DIVERGENT_LIST" | head -20 | sed 's/^/    /'
  fi
fi

# exit code logic
if [ "$DIVERGENT_COUNT" -gt 0 ]; then
  echo ""
  echo "FAIL: $DIVERGENT_COUNT divergent statements detected (run with --verbose for details)"
  exit 1
elif [ "$SOURCE_ONLY_COUNT" -gt 0 ]; then
  echo ""
  echo "WARN: $SOURCE_ONLY_COUNT source-only declarations (port 未完成、Phase 4 Foundation 含む既知 gap)"
  exit 0  # source-only は許容 (既知)、divergent のみ FAIL
else
  echo ""
  echo "PASS: 全 common names で statement parity 達成"
  exit 0
fi
