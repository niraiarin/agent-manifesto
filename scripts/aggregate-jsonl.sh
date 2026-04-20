#!/usr/bin/env bash
# @traces [S2 §3.4] PaperOrchestra Agent Research Aggregator (Phase 1 + 4)
#
# Phase 1 (Discovery) + Phase 4 (Formatting) — deterministic portions only.
# Phase 2 (Extraction) and Phase 3 (Synthesis) are LLM-driven; they consume
# the manifest emitted here.
#
# Usage:
#   scripts/aggregate-jsonl.sh <output-dir> [jsonl-path] [git-range]
#
# Output:
#   <output-dir>/manifest.json
#   <output-dir>/evidence/p2-verified-snapshot.jsonl
#   <output-dir>/evidence/commits.md   (human-readable summary)
#   <output-dir>/evidence/sources.md   (touched-file index)

set -euo pipefail

OUTPUT_DIR="${1:?usage: aggregate-jsonl.sh <output-dir> [jsonl-path] [git-range]}"
JSONL_PATH="${2:-.claude/metrics/p2-verified.jsonl}"
GIT_RANGE="${3:-HEAD~20..HEAD}"

if ! command -v jq >/dev/null 2>&1; then
  echo "[aggregate] ERROR: jq required" >&2; exit 2
fi
if [ ! -f "$JSONL_PATH" ]; then
  echo "[aggregate] ERROR: jsonl not found: $JSONL_PATH" >&2; exit 2
fi
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "[aggregate] ERROR: not in a git repository" >&2; exit 2
fi

mkdir -p "$OUTPUT_DIR/evidence"

# ---------- Phase 1: Discovery ----------

# 1a: snapshot jsonl for evidence
cp "$JSONL_PATH" "$OUTPUT_DIR/evidence/p2-verified-snapshot.jsonl"

# 1b: verifications array (normalize fields across schema drift)
VERIFS_JSON=$(jq -s '[.[] | {
  epoch: (.epoch // null),
  timestamp: (.timestamp // null),
  files: (.files // []),
  verdict: (.verdict // "UNKNOWN"),
  evaluator: (.evaluator // null),
  evaluator_independent: (.evaluator_independent // null),
  k_rounds: (.k_rounds // null),
  pass_rate: (.pass_rate // null),
  margin: (.margin // null),
  criteria: (.criteria // []),
  source: (.source // null)
}]' "$JSONL_PATH")

VERIF_COUNT=$(echo "$VERIFS_JSON" | jq 'length')
PASS_COUNT=$(echo "$VERIFS_JSON" | jq '[.[] | select(.verdict=="PASS")] | length')

# 1c: distinct files across all verifications
FILES_TOUCHED_JSON=$(echo "$VERIFS_JSON" | jq '[.[].files[]] | unique')

# 1d: git log in range → commits array
#     body excluded at this phase (fetched on-demand in Phase 2)
if ! git rev-parse "$GIT_RANGE" >/dev/null 2>&1; then
  echo "[aggregate] WARN: git range $GIT_RANGE invalid, falling back to HEAD~5..HEAD" >&2
  GIT_RANGE="HEAD~5..HEAD"
fi

COMMITS_RAW=$(git log --format='%H%x1f%s%x1f%an%x1f%aI' "$GIT_RANGE" 2>/dev/null || true)
COMMITS_JSON="[]"
if [ -n "$COMMITS_RAW" ]; then
  COMMITS_JSON=$(printf '%s\n' "$COMMITS_RAW" \
    | jq -R 'split("\u001f") | {
        sha: .[0], subject: .[1], author: .[2], date: .[3]
      }' \
    | jq -s '.')
fi

# ---------- Phase 4: Formatting ----------

# 4a: manifest.json (single source of truth for Phase 2/3 LLM)
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
jq -n \
  --arg generated_at "$TIMESTAMP" \
  --arg jsonl_path "$JSONL_PATH" \
  --arg git_range "$GIT_RANGE" \
  --argjson verifications "$VERIFS_JSON" \
  --argjson files_touched "$FILES_TOUCHED_JSON" \
  --argjson commits "$COMMITS_JSON" \
  --argjson verif_count "$VERIF_COUNT" \
  --argjson pass_count "$PASS_COUNT" \
  '{
    schema_version: "1",
    generated_at: $generated_at,
    input: {
      jsonl_path: $jsonl_path,
      git_range: $git_range
    },
    summary: {
      verification_count: $verif_count,
      pass_count: $pass_count,
      distinct_file_count: ($files_touched | length),
      commit_count: ($commits | length)
    },
    verifications: $verifications,
    files_touched: $files_touched,
    commits: $commits
  }' > "$OUTPUT_DIR/manifest.json"

# 4b: human-readable commits.md
{
  echo "# Commits in range: $GIT_RANGE"
  echo ""
  echo "$COMMITS_JSON" | jq -r '.[] | "- \(.date | .[0:10])  `\(.sha | .[0:8])`  \(.subject) — \(.author)"'
} > "$OUTPUT_DIR/evidence/commits.md"

# 4c: human-readable sources.md (file → verification count)
{
  echo "# Files touched across $VERIF_COUNT verifications"
  echo ""
  echo "$VERIFS_JSON" \
    | jq -r '[.[].files[]] | group_by(.) | map({file: .[0], n: length}) | sort_by(-.n) | .[] | "- (\(.n)) \(.file)"'
} > "$OUTPUT_DIR/evidence/sources.md"

echo "[aggregate] manifest:  $OUTPUT_DIR/manifest.json"
echo "[aggregate] verifs=$VERIF_COUNT pass=$PASS_COUNT files=$(echo "$FILES_TOUCHED_JSON" | jq 'length') commits=$(echo "$COMMITS_JSON" | jq 'length')"
