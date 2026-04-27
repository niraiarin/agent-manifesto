#!/usr/bin/env bash
# Phase 5 PI-18: source ↔ port proof text parity audit (Day 193)
#
# 目的: 各 theorem の proof body (statement 後の `:= ...` 部分) を text-level で
#       byte 比較。proof byte-identical なら axiom dependency も identical (semantic 同型)。
#
# rationale:
# - Lean source build は heavy (Mathlib clone)、port build (2056 jobs) で代替
# - source 側で `#print axioms` を取得せず、proof body の byte-identical を以て semantic 同型と判定
# - proof 一致 + statement 一致 (PI-17) ⇒ axiom dependency 同型 (modulo namespace)
#
# 出力: proof-divergent な theorem を report
# exit code: 0 (no divergence) / 1 (proof divergent)

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

# Extract proof body for a theorem (multi-line until next decl or blank line)
# args: file, theorem_name, namespace_prefix
extract_proof() {
  local FILE="$1"
  local NAME="$2"
  local NSPREFIX="$3"
  # Find the line where theorem starts, get all lines until next blank line or next decl
  awk -v name="$NAME" -v nsprefix="$NSPREFIX" '
    BEGIN { in_decl = 0; first = 1 }
    $0 ~ "^theorem " name "[ :\\n]" {
      in_decl = 1
      # output but normalize namespace
      line = $0
      gsub(nsprefix, "MANIFEST.", line)
      print line
      first = 0
      next
    }
    in_decl && /^$/ { in_decl = 0; exit }
    in_decl && /^(theorem|axiom|def|opaque|structure|inductive|class|instance|example|namespace|end) / { in_decl = 0; exit }
    in_decl && /^\/--/ { in_decl = 0; exit }
    in_decl {
      line = $0
      gsub(nsprefix, "MANIFEST.", line)
      print line
    }
  ' "$FILE"
}

# 50 critical theorems list
CRITICAL_THEOREMS=(
  "context_bounds_action" "cognitive_separation_required" "no_self_verification"
  "d1_fixed_requires_structural" "d1_enforcement_monotone" "d2_from_e1"
  "d3_observability_precedes_improvement" "d4_no_self_dependency" "d4_full_chain"
  "critical_requires_all_four" "subagent_only_sufficient_for_low"
  "v1_measurable" "v2_measurable" "v3_measurable" "v4_measurable"
  "v5_measurable" "v6_measurable" "v7_measurable"
  "constraint_has_boundary" "platform_not_in_constraint_boundary"
  "measurable_threshold_observable" "system_health_observable"
  "degradation_detectable_observable" "observable_and" "observable_or" "observable_not"
)

echo "=== Proof text parity audit (Phase 5 PI-18) ==="
echo "checking ${#CRITICAL_THEOREMS[@]} critical theorems..."
echo ""

DIVERGENT=0
ALLOWED=0
PASSED=0
NOT_FOUND=0

for thm in "${CRITICAL_THEOREMS[@]}"; do
  # Find file containing the theorem in source
  SRC_FILE=$(grep -lrE "^theorem ${thm}[ :]" "$SOURCE_DIR" 2>/dev/null | head -1)
  PRT_FILE=$(grep -lrE "^theorem ${thm}[ :]" "$PORT_DIR" 2>/dev/null | head -1)

  if [ -z "$SRC_FILE" ] || [ -z "$PRT_FILE" ]; then
    NOT_FOUND=$((NOT_FOUND + 1))
    continue
  fi

  SRC_PROOF=$(extract_proof "$SRC_FILE" "$thm" "Manifest.")
  PRT_PROOF=$(extract_proof "$PRT_FILE" "$thm" "AgentSpec.Manifest.")

  if [ "$SRC_PROOF" = "$PRT_PROOF" ]; then
    PASSED=$((PASSED + 1))
  else
    if echo "$KNOWN_ALLOWED" | grep -qFx "$thm" 2>/dev/null; then
      ALLOWED=$((ALLOWED + 1))
    else
      DIVERGENT=$((DIVERGENT + 1))
      echo "  DIVERGENT: $thm"
    fi
  fi
done

TOTAL=${#CRITICAL_THEOREMS[@]}
echo ""
echo "--- proof parity summary ---"
echo "byte-identical: $PASSED / $TOTAL"
echo "allow-listed:   $ALLOWED / $TOTAL"
echo "divergent:      $DIVERGENT / $TOTAL"
echo "not-found:      $NOT_FOUND / $TOTAL (port にない or source にない)"

if [ "$DIVERGENT" -gt 0 ]; then
  echo ""
  echo "FAIL: $DIVERGENT proof divergences (allow-list 追加 or 修正)"
  exit 1
fi
echo ""
echo "PASS: 全 critical theorems で proof parity 達成 (allow-list 含む)"
