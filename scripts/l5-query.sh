#!/usr/bin/env bash
# l5-query.sh — L5 Platform Capabilities のクエリツール
#
# Usage:
#   ./scripts/l5-query.sh capabilities <platform>
#   ./scripts/l5-query.sh enforcement <platform> <layer>
#   ./scripts/l5-query.sh route <platform> <task-class>
#   ./scripts/l5-query.sh compare <capability>
#   ./scripts/l5-query.sh fallback <platform> <required-layer>
#
# Unknown platforms automatically fall back to _default.
#
# Examples:
#   ./scripts/l5-query.sh capabilities claude-code
#   ./scripts/l5-query.sh enforcement claude-code structural
#   ./scripts/l5-query.sh route claude-code deterministic
#   ./scripts/l5-query.sh compare skill_system
#   ./scripts/l5-query.sh fallback unknown-platform structural

set -euo pipefail

BASE="$(git rev-parse --show-toplevel 2>/dev/null || echo /Users/nirarin/work/agent-manifesto)"
L5_JSON="$BASE/docs/l5-platform-capabilities.json"

if [ ! -f "$L5_JSON" ]; then
  echo "ERROR: L5 SSOT not found at $L5_JSON" >&2
  exit 1
fi

usage() {
  echo "Usage: $0 {capabilities|enforcement|route|compare|fallback} <args...>" >&2
  exit 1
}

# Resolve platform: if not found, fall back to _default
resolve_platform() {
  local platform="$1"
  if jq -e ".platforms[\"$platform\"]" "$L5_JSON" >/dev/null 2>&1; then
    echo "$platform"
  else
    echo "[FALLBACK] Platform '$platform' not found, using _default" >&2
    echo "_default"
  fi
}

cmd_capabilities() {
  local platform
  platform=$(resolve_platform "${1:?Platform required}")
  jq -r ".platforms[\"$platform\"].capabilities | to_entries[] | \"\(.key): \(.value)\"" "$L5_JSON"
}

cmd_enforcement() {
  local platform
  platform=$(resolve_platform "${1:?Platform required}")
  local layer="${2:?Layer required (structural|procedural|normative)}"
  jq -r ".platforms[\"$platform\"].enforcement_primitives[\"$layer\"].primitives[] | \"[\(.id)] \(.description) (deterministic: \(.deterministic))\"" "$L5_JSON"
}

cmd_route() {
  local platform
  platform=$(resolve_platform "${1:?Platform required}")
  local task_class="${2:?Task class required (deterministic|bounded|judgmental)}"
  echo "Platform: $platform | TaskClass: $task_class"
  echo "Routing targets:"
  jq -r ".platforms[\"$platform\"].task_routing[\"$task_class\"][]" "$L5_JSON" | sed 's/^/  - /'
}

cmd_compare() {
  local capability="${1:?Capability required}"
  echo "Capability: $capability"
  jq -r ".platforms | to_entries[] | select(.key != \"_default\") | \"  \(.key): \(.value.capabilities[\"$capability\"] // \"N/A\")\"" "$L5_JSON"
}

# Fallback analysis: given a platform and required enforcement layer,
# determine what's available and what falls back.
cmd_fallback() {
  local platform
  platform=$(resolve_platform "${1:?Platform required}")
  local required="${2:?Required layer (structural|procedural|normative)}"

  local layers=("structural" "procedural" "normative")
  local found=false

  echo "Platform: $platform | Required: $required"
  echo ""

  # Check if required layer has primitives
  local count
  count=$(jq -r ".platforms[\"$platform\"].enforcement_primitives[\"$required\"].primitives | length" "$L5_JSON")

  if [ "$count" -gt 0 ]; then
    echo "Status: AVAILABLE ($count primitives)"
    jq -r ".platforms[\"$platform\"].enforcement_primitives[\"$required\"].primitives[] | \"  [\(.id)] \(.description)\"" "$L5_JSON"
    found=true
  else
    echo "Status: NOT AVAILABLE at $required layer"
    echo ""
    echo "Fallback chain (degrading only):"
    # Walk down: structural → procedural → normative
    local started=false
    for layer in "${layers[@]}"; do
      if [ "$layer" = "$required" ]; then
        started=true
        continue
      fi
      if [ "$started" = true ]; then
        local lcount
        lcount=$(jq -r ".platforms[\"$platform\"].enforcement_primitives[\"$layer\"].primitives | length" "$L5_JSON")
        if [ "$lcount" -gt 0 ]; then
          echo "  → Fallback to: $layer ($lcount primitives)"
          jq -r ".platforms[\"$platform\"].enforcement_primitives[\"$layer\"].primitives[] | \"    [\(.id)] \(.description)\"" "$L5_JSON"
          found=true
          break
        fi
      fi
    done
  fi

  if [ "$found" = false ]; then
    echo "  ⚠ NO FALLBACK AVAILABLE — escalate to human (T6)"
  fi

  echo ""
  echo "Note: Fallback means minimumEnforcement is NOT met. Flag to human (T6)."
}

case "${1:-}" in
  capabilities) shift; cmd_capabilities "$@" ;;
  enforcement)  shift; cmd_enforcement "$@" ;;
  route)        shift; cmd_route "$@" ;;
  compare)      shift; cmd_compare "$@" ;;
  fallback)     shift; cmd_fallback "$@" ;;
  *)            usage ;;
esac
