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

echo "=== Done ==="
echo "Output in: $SCRIPT_DIR/$OUTPUT_DIR-multi/"
echo "Serve with: python3 -m http.server 8000 -d $SCRIPT_DIR/$OUTPUT_DIR-multi/"
