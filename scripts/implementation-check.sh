#!/usr/bin/env bash
# implementation-check.sh — 実装先判断の妥当性チェック（決定論的部分）
#
# 新しい実装を始める前に、TaskClassification × L5 の妥当性を自動チェックする。
# 最適性判断は人間/LLM が担当（T6）。
#
# Usage:
#   ./scripts/implementation-check.sh <platform> <task-class> [required-layer]
#
# Examples:
#   ./scripts/implementation-check.sh claude-code deterministic
#   ./scripts/implementation-check.sh codex-cli judgmental
#   ./scripts/implementation-check.sh unknown-platform bounded

set -euo pipefail

BASE="$(git rev-parse --show-toplevel 2>/dev/null || echo /Users/nirarin/work/agent-manifesto)"
L5_JSON="$BASE/docs/l5-platform-capabilities.json"

if [ ! -f "$L5_JSON" ]; then
  echo "ERROR: L5 SSOT not found at $L5_JSON" >&2
  exit 1
fi

PLATFORM="${1:?Platform required (e.g., claude-code)}"
TASK_CLASS="${2:?Task class required (deterministic|bounded|judgmental)}"

# Map TaskAutomationClass → EnforcementLayer (mirrors taskMinEnforcement in Lean)
case "$TASK_CLASS" in
  deterministic) REQUIRED_LAYER="structural" ;;
  bounded)       REQUIRED_LAYER="procedural" ;;
  judgmental)    REQUIRED_LAYER="normative" ;;
  *) echo "ERROR: Unknown task class: $TASK_CLASS (must be deterministic|bounded|judgmental)" >&2; exit 1 ;;
esac

# Override if explicitly specified
REQUIRED_LAYER="${3:-$REQUIRED_LAYER}"

echo "=== Implementation Validity Check ==="
echo ""
echo "  Platform:       $PLATFORM"
echo "  Task class:     $TASK_CLASS"
echo "  Required layer: $REQUIRED_LAYER (from taskMinEnforcement)"
echo ""

# Resolve platform (fallback to _default)
RESOLVED=$(jq -e ".platforms[\"$PLATFORM\"]" "$L5_JSON" >/dev/null 2>&1 && echo "$PLATFORM" || echo "_default")
if [ "$RESOLVED" = "_default" ]; then
  echo "  ⚠ Platform '$PLATFORM' not in L5 SSOT — using _default (conservative)"
  echo ""
fi

# Check if required layer has primitives
PRIM_COUNT=$(jq -r ".platforms[\"$RESOLVED\"].enforcement_primitives[\"$REQUIRED_LAYER\"].primitives | length" "$L5_JSON")

if [ "$PRIM_COUNT" -gt 0 ]; then
  echo "  ✓ VALID: $REQUIRED_LAYER layer has $PRIM_COUNT primitive(s)"
  echo ""
  echo "  Available primitives:"
  jq -r ".platforms[\"$RESOLVED\"].enforcement_primitives[\"$REQUIRED_LAYER\"].primitives[] | \"    [\(.id)] \(.description)\"" "$L5_JSON"
  echo ""
  echo "  Routing targets for $TASK_CLASS:"
  jq -r ".platforms[\"$RESOLVED\"].task_routing[\"$TASK_CLASS\"][]" "$L5_JSON" | sed 's/^/    - /'
else
  echo "  ✗ INSUFFICIENT: $REQUIRED_LAYER layer has no primitives for $RESOLVED"
  echo ""

  # Find fallback
  LAYERS=("structural" "procedural" "normative")
  FOUND=false
  for layer in "${LAYERS[@]}"; do
    if [ "$layer" = "$REQUIRED_LAYER" ]; then
      continue
    fi
    # Only check layers weaker than required
    case "$REQUIRED_LAYER:$layer" in
      structural:procedural|structural:normative|procedural:normative)
        FC=$(jq -r ".platforms[\"$RESOLVED\"].enforcement_primitives[\"$layer\"].primitives | length" "$L5_JSON")
        if [ "$FC" -gt 0 ]; then
          echo "  → Fallback available: $layer ($FC primitives)"
          echo "    ⚠ minimumEnforcement NOT met — escalate to human (T6)"
          FOUND=true
          break
        fi
        ;;
    esac
  done

  if [ "$FOUND" = false ]; then
    echo "  ⚠ NO FALLBACK — escalate to human (T6)"
  fi
fi

echo ""
echo "--- Optimality Note ---"
echo "This check verifies VALIDITY (minimumEnforcement met)."
echo "OPTIMALITY (best primitive choice) requires human judgment or /research."
