#!/usr/bin/env bash
# Generate Mermaid graph from .claude/skills/dependency-graph.yaml
#
# Usage: generate-skill-mermaid.sh [--check]
#   (no args): Output Mermaid to stdout
#   --check:   Verify README.md's mermaid block matches generated output (exit 1 on diff)
#
# Requires: yq (https://github.com/mikefarah/yq)
# Reference: #346

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DEPGRAPH="$PROJECT_DIR/.claude/skills/dependency-graph.yaml"
README="$PROJECT_DIR/README.md"
CHECK_MODE=false

if [ "${1:-}" = "--check" ]; then
  CHECK_MODE=true
fi

if ! command -v yq &>/dev/null; then
  echo "ERROR: yq is required but not found. Install: brew install yq" >&2
  exit 1
fi

if [ ! -f "$DEPGRAPH" ]; then
  echo "ERROR: $DEPGRAPH not found. Run: scripts/generate-skill-depgraph.sh" >&2
  exit 1
fi

# Build Mermaid output
generate_mermaid() {
  echo "graph LR"

  # Classify skills by role for subgraph grouping
  # Read edges and emit links
  local edge_count
  edge_count=$(yq '.edges | length' "$DEPGRAPH")

  for i in $(seq 0 $((edge_count - 1))); do
    from=$(yq ".edges[$i].from" "$DEPGRAPH")
    to=$(yq ".edges[$i].to" "$DEPGRAPH")
    type=$(yq ".edges[$i].type" "$DEPGRAPH")

    # Normalize names for Mermaid node IDs (replace - with _)
    from_id=$(echo "$from" | tr '-' '_')
    to_id=$(echo "$to" | tr '-' '_')

    if [ "$type" = "hard" ]; then
      echo "  ${from_id}[\"/${from}\"] --> ${to_id}[\"/${to}\"]"
    else
      echo "  ${from_id}[\"/${from}\"] -.-> ${to_id}[\"/${to}\"]"
    fi
  done

  # Style leaf nodes (no outgoing edges)
  echo ""
  echo "  style metrics fill:#e8f5e9"
  echo "  style verify fill:#e8f5e9"
  echo "  style adjust_action_space fill:#e8f5e9"
  echo "  style spec_driven_workflow fill:#fff3e0"
}

MERMAID=$(generate_mermaid | awk '!seen[$0]++')

if $CHECK_MODE; then
  # Extract mermaid block from README between markers
  EXISTING=$(awk '/^```mermaid$/,/^```$/' "$README" | grep -v '^```' | head -100)

  if [ -z "$EXISTING" ]; then
    echo "❌ No mermaid block found in README.md" >&2
    exit 1
  fi

  if [ "$EXISTING" = "$MERMAID" ]; then
    echo "✅ README.md mermaid block is up to date" >&2
    exit 0
  else
    echo "❌ README.md mermaid block is out of date. Run: scripts/generate-skill-mermaid.sh" >&2
    diff <(echo "$EXISTING") <(echo "$MERMAID") >&2 || true
    exit 1
  fi
else
  echo "$MERMAID"
fi
