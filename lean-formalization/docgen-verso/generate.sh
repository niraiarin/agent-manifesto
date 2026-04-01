#!/usr/bin/env bash
# Generate Agent Manifesto HTML documentation using Verso
# Usage: ./generate.sh [output-dir]
#
# Prerequisites:
#   - Lean 4 v4.25.0 (via elan)
#   - Run `lake update` first if lake-manifest.json doesn't exist
#
# Output is written to _out/html-multi/ by default.
# Serve locally with: python3 -m http.server 8000 -d _out/html-multi

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

export PATH="$HOME/.elan/bin:$PATH"

OUTPUT_DIR="${1:-_out/html}"

echo "=== Building Verso documentation ==="
lake build

echo "=== Generating HTML ==="
lake exe docs --output "$OUTPUT_DIR"

echo "=== Integrating Graph View ==="
GRAPH_SRC="$SCRIPT_DIR/../../docs/graph-view"
if [ -d "$GRAPH_SRC" ]; then
  for target_dir in "$OUTPUT_DIR/html-single" "$OUTPUT_DIR/html-multi"; do
    if [ -d "$target_dir" ]; then
      mkdir -p "$target_dir/graph-view"
      cp "$GRAPH_SRC/graph-view.html" "$target_dir/graph-view/index.html"
      cp "$GRAPH_SRC/depgraph.json" "$target_dir/graph-view/"
      cp "$GRAPH_SRC/positions.json" "$target_dir/graph-view/"
      cp "$GRAPH_SRC/source-map.json" "$target_dir/graph-view/"
      echo "  Graph View assets copied to $target_dir/graph-view/"
    fi
  done
  # Navigation link is injected via Main.lean extraContents (no sed needed)
else
  echo "  Warning: docs/graph-view/ not found, skipping Graph View integration"
fi

echo "=== Done ==="
echo "Output in: $SCRIPT_DIR/$OUTPUT_DIR-multi/"
echo "Serve with: python3 -m http.server 8000 -d $SCRIPT_DIR/$OUTPUT_DIR-multi/"
