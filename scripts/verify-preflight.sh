#!/usr/bin/env bash
# verify-preflight.sh — /verify の決定論的事前チェック
#
# Verifier (LLM) が判断する前に、決定論的に検証可能な項目を自動チェックする。
# TaskClassification: deterministic → structural enforcement
#
# Usage:
#   bash scripts/verify-preflight.sh <file1> [file2 ...]
#   echo '["file1","file2"]' | bash scripts/verify-preflight.sh --stdin
#
# Output: JSON with pre-validated facts
# Exit: 0 = all checks pass, 1 = issues found
set -euo pipefail

BASE="$(cd "$(dirname "$0")/.." && pwd)"
LEAN_DIR="$BASE/lean-formalization"
ISSUES=0

# Parse file list
if [[ "${1:-}" == "--stdin" ]]; then
  FILES=$(python3 -c "import sys,json; [print(f) for f in json.loads(sys.stdin.read())]")
else
  FILES="$*"
fi

if [[ -z "$FILES" ]]; then
  echo '{"error": "No files specified"}' >&2
  exit 1
fi

echo "{"
echo "  \"preflight_checks\": {"

# --- Check 1: File existence ---
echo "    \"file_existence\": ["
FIRST=true
for f in $FILES; do
  [[ "$FIRST" == "true" ]] || echo ","
  FIRST=false
  if [[ -f "$BASE/$f" ]] || [[ -f "$f" ]]; then
    printf '      {"file": "%s", "exists": true}' "$f"
  else
    printf '      {"file": "%s", "exists": false}' "$f"
    ISSUES=$((ISSUES + 1))
  fi
done
echo ""
echo "    ],"

# --- Check 2: Lean definition name validation ---
# Extract Lean names referenced in staged .md files
LEAN_NAMES=""
for f in $FILES; do
  fp="$BASE/$f"
  [[ -f "$fp" ]] || fp="$f"
  [[ -f "$fp" ]] || continue
  if [[ "$fp" == *.md ]] || [[ "$fp" == *.lean ]]; then
    # Extract backtick-quoted identifiers that look like Lean names
    NAMES=$(grep -oE '`[a-z_][a-z_A-Z0-9]*`' "$fp" 2>/dev/null | tr -d '`' | sort -u || true)
    LEAN_NAMES="$LEAN_NAMES $NAMES"
  fi
done

echo "    \"lean_names\": ["
FIRST=true
for name in $(echo "$LEAN_NAMES" | tr ' ' '\n' | sort -u | head -20); do
  [[ -n "$name" ]] || continue
  [[ "$FIRST" == "true" ]] || echo ","
  FIRST=false
  FOUND=$(grep -rl "^\\(axiom\\|theorem\\|def\\|structure\\|inductive\\|class\\|opaque\\) $name" "$LEAN_DIR"/Manifest/*.lean 2>/dev/null | head -1 || true)
  if [[ -n "$FOUND" ]]; then
    printf '      {"name": "%s", "found": true, "file": "%s"}' "$name" "$(basename "$FOUND")"
  else
    printf '      {"name": "%s", "found": false}' "$name"
    # Not all backtick names are Lean definitions — don't count as issue
  fi
done
echo ""
echo "    ],"

# --- Check 3: Count consistency ---
THEOREMS=$(grep '^theorem ' "$LEAN_DIR"/Manifest/*.lean 2>/dev/null | wc -l | tr -d ' ')
AXIOMS=$(grep '^axiom [a-z]' "$LEAN_DIR"/Manifest/*.lean 2>/dev/null | wc -l | tr -d ' ')
echo "    \"count_consistency\": {"
echo "      \"theorems\": $THEOREMS,"
echo "      \"axioms\": $AXIOMS,"

# Check if sync-counts is in sync
SYNC_CHECK=$(cd "$BASE" && SYNC_SKIP_TESTS=1 bash scripts/sync-counts.sh --check 2>&1 || true)
if echo "$SYNC_CHECK" | grep -q "All files in sync"; then
  echo "      \"sync_status\": \"in_sync\""
else
  DRIFT_COUNT=$(echo "$SYNC_CHECK" | grep -c "^DIFF:" || true)
  echo "      \"sync_status\": \"drifted\","
  echo "      \"drift_count\": $DRIFT_COUNT"
  ISSUES=$((ISSUES + 1))
fi
echo "    },"

# --- Check 4: Risk classification (deterministic rules) ---
echo "    \"risk_classification\": ["
FIRST=true
for f in $FILES; do
  [[ "$FIRST" == "true" ]] || echo ","
  FIRST=false
  case "$f" in
    .claude/hooks/*|.claude/settings.json) RISK="critical" ;;
    lean-formalization/*|tests/*) RISK="high" ;;
    .claude/skills/*|.claude/agents/*|.claude/rules/*) RISK="moderate" ;;
    *.md|docs/*|scripts/*) RISK="low" ;;
    *) RISK="moderate" ;;
  esac
  printf '      {"file": "%s", "risk": "%s"}' "$f" "$RISK"
done
echo ""
echo "    ]"

# --- Summary ---
echo "  },"
echo "  \"issues\": $ISSUES,"
if [[ $ISSUES -eq 0 ]]; then
  echo "  \"verdict\": \"pass\""
else
  echo "  \"verdict\": \"issues_found\""
fi
echo "}"

[[ $ISSUES -eq 0 ]]
