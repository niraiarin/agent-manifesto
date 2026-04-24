#!/usr/bin/env bash
# @traces [S1 §2.3] single-pass writeup compilation
#
# compile-paper.sh — render paper.tex → paper.pdf.
#
# Strategy: try latexmk first (fastest reliable), fall back to tectonic, then
# to raw pdflatex. If none available, exit 1 with a clear message.
#
# Usage:
#   scripts/compile-paper.sh input.tex output.pdf

set -euo pipefail

IN_TEX="${1:?usage: compile-paper.sh <input.tex> <output.pdf>}"
OUT_PDF="${2:?usage: compile-paper.sh <input.tex> <output.pdf>}"

if [ ! -f "$IN_TEX" ]; then
  echo "[compile] ERROR: input not found: $IN_TEX" >&2; exit 2
fi

BUILD_DIR=$(dirname "$OUT_PDF")/.latex-build
mkdir -p "$BUILD_DIR"

IN_ABS=$(cd "$(dirname "$IN_TEX")" && pwd)/$(basename "$IN_TEX")
OUT_ABS=$(cd "$(dirname "$OUT_PDF")" && pwd)/$(basename "$OUT_PDF")
BUILD_ABS=$(cd "$BUILD_DIR" && pwd)

if command -v latexmk >/dev/null 2>&1; then
  echo "[compile] using latexmk"
  (cd "$(dirname "$IN_TEX")" && latexmk -pdf -interaction=nonstopmode -halt-on-error \
    -output-directory="$BUILD_ABS" "$(basename "$IN_TEX")") || {
      echo "[compile] latexmk failed (see $BUILD_ABS/*.log)" >&2; exit 3;
    }
elif command -v tectonic >/dev/null 2>&1; then
  echo "[compile] using tectonic"
  tectonic -o "$BUILD_ABS" "$IN_ABS" || {
    echo "[compile] tectonic failed" >&2; exit 3;
  }
elif command -v pdflatex >/dev/null 2>&1; then
  echo "[compile] using pdflatex (2 passes)"
  (cd "$(dirname "$IN_TEX")" && pdflatex -interaction=nonstopmode -halt-on-error \
    -output-directory="$BUILD_ABS" "$(basename "$IN_TEX")" >/dev/null &&
   pdflatex -interaction=nonstopmode -halt-on-error \
    -output-directory="$BUILD_ABS" "$(basename "$IN_TEX")" >/dev/null) || {
      echo "[compile] pdflatex failed (see $BUILD_ABS/*.log)" >&2; exit 3;
    }
else
  echo "[compile] ERROR: none of {latexmk, tectonic, pdflatex} available" >&2
  echo "[compile] install via:  brew install --cask mactex-no-gui   or   brew install tectonic" >&2
  exit 2
fi

BASENAME=$(basename "$IN_TEX" .tex)
SRC_PDF="$BUILD_ABS/$BASENAME.pdf"
if [ ! -f "$SRC_PDF" ]; then
  echo "[compile] ERROR: expected output not produced: $SRC_PDF" >&2; exit 3
fi

cp "$SRC_PDF" "$OUT_ABS"
echo "[compile] wrote: $OUT_ABS"
