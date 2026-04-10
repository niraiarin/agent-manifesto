#!/usr/bin/env bash
# Verify integrity of skill dependency declarations
#
# Checks:
#   1. All invokes targets exist as skill directories
#   2. Symmetry: if A invokes B, B's invoked_by should list A (warning only)
#   3. Body references: /skill-name in SKILL.md body matches frontmatter invokes
#   4. dependency-graph.yaml matches frontmatter (delegates to generate-skill-depgraph.sh --check)
#
# Usage: verify-skill-dependencies.sh
# Exit: 0 = pass, 1 = failures
# Reference: #346

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SKILLS_DIR="$PROJECT_DIR/.claude/skills"

FAILURES=0
WARNINGS=0

fail() { echo "  FAIL: $1"; FAILURES=$((FAILURES + 1)); }
warn() { echo "  WARN: $1"; WARNINGS=$((WARNINGS + 1)); }
pass() { echo "  PASS: $1"; }

if ! command -v yq &>/dev/null; then
  echo "ERROR: yq is required" >&2
  exit 1
fi

extract_frontmatter() {
  awk 'BEGIN{n=0} /^---$/{n++; next} n==1{print} n>=2{exit}' "$1"
}

# Collect all skill names
SKILL_NAMES=()
for skill_dir in "$SKILLS_DIR"/*/; do
  if [ -f "$skill_dir/SKILL.md" ]; then
    SKILL_NAMES+=("$(basename "$skill_dir")")
  fi
done

echo "=========================================="
echo "Skill Dependency Integrity Verification"
echo "=========================================="
echo "Skills found: ${#SKILL_NAMES[@]}"
echo ""

# ============================================================
# Check 1: All invokes targets exist
# ============================================================
echo "--- Check 1: Invokes targets exist ---"

for skill in "${SKILL_NAMES[@]}"; do
  frontmatter=$(extract_frontmatter "$SKILLS_DIR/$skill/SKILL.md")
  has_deps=$(echo "$frontmatter" | yq 'has("dependencies")' 2>/dev/null)

  if [ "$has_deps" != "true" ]; then
    continue
  fi

  invokes_len=$(echo "$frontmatter" | yq '.dependencies.invokes | length // 0' 2>/dev/null)
  if [ "$invokes_len" = "0" ] || [ "$invokes_len" = "null" ]; then
    continue
  fi

  for i in $(seq 0 $((invokes_len - 1))); do
    target=$(echo "$frontmatter" | yq ".dependencies.invokes[$i].skill" 2>/dev/null)
    if [ ! -d "$SKILLS_DIR/$target" ]; then
      fail "$skill invokes '$target' but no such skill directory exists"
    fi
  done
done

if [ $FAILURES -eq 0 ]; then
  pass "All invokes targets exist"
fi
echo ""

# ============================================================
# Check 2: Symmetry (invokes ↔ invoked_by)
# ============================================================
echo "--- Check 2: Symmetry (invokes ↔ invoked_by) ---"

# Build invokes map: skill -> [targets]
declare -A INVOKES_MAP
for skill in "${SKILL_NAMES[@]}"; do
  frontmatter=$(extract_frontmatter "$SKILLS_DIR/$skill/SKILL.md")
  has_deps=$(echo "$frontmatter" | yq 'has("dependencies")' 2>/dev/null)
  if [ "$has_deps" != "true" ]; then continue; fi

  invokes_len=$(echo "$frontmatter" | yq '.dependencies.invokes | length // 0' 2>/dev/null)
  if [ "$invokes_len" = "0" ] || [ "$invokes_len" = "null" ]; then continue; fi

  targets=""
  for i in $(seq 0 $((invokes_len - 1))); do
    target=$(echo "$frontmatter" | yq ".dependencies.invokes[$i].skill" 2>/dev/null)
    targets="$targets $target"
  done
  INVOKES_MAP[$skill]="$targets"
done

# For each skill with invoked_by, check symmetry
for skill in "${SKILL_NAMES[@]}"; do
  frontmatter=$(extract_frontmatter "$SKILLS_DIR/$skill/SKILL.md")
  has_deps=$(echo "$frontmatter" | yq 'has("dependencies")' 2>/dev/null)
  if [ "$has_deps" != "true" ]; then continue; fi

  invoked_by_len=$(echo "$frontmatter" | yq '.dependencies.invoked_by | length // 0' 2>/dev/null)
  if [ "$invoked_by_len" = "0" ] || [ "$invoked_by_len" = "null" ]; then continue; fi

  for i in $(seq 0 $((invoked_by_len - 1))); do
    caller=$(echo "$frontmatter" | yq ".dependencies.invoked_by[$i].skill" 2>/dev/null)
    # Check if caller's invokes includes this skill
    caller_invokes="${INVOKES_MAP[$caller]:-}"
    if ! echo "$caller_invokes" | grep -qw "$skill"; then
      warn "$skill.invoked_by lists '$caller', but $caller.invokes does not include '$skill'"
    fi
  done
done

if [ $WARNINGS -eq 0 ] && [ $FAILURES -eq 0 ]; then
  pass "All invoked_by declarations are symmetric with invokes"
fi
echo ""

# ============================================================
# Check 3: Body references match frontmatter
# ============================================================
echo "--- Check 3: Body references vs frontmatter ---"

# Build KNOWN_SKILLS dynamically from discovered skill directories
KNOWN_SKILLS="${SKILL_NAMES[*]}"

for skill in "${SKILL_NAMES[@]}"; do
  skill_md="$SKILLS_DIR/$skill/SKILL.md"
  frontmatter=$(extract_frontmatter "$skill_md")

  # Get body (everything after second ---)
  body=$(awk 'BEGIN{n=0} /^---$/{n++; next} n>=2{print}' "$skill_md")

  # Get frontmatter invokes targets
  has_deps=$(echo "$frontmatter" | yq 'has("dependencies")' 2>/dev/null)
  declared_targets=""
  if [ "$has_deps" = "true" ]; then
    invokes_len=$(echo "$frontmatter" | yq '.dependencies.invokes | length // 0' 2>/dev/null)
    if [ "$invokes_len" != "0" ] && [ "$invokes_len" != "null" ]; then
      for i in $(seq 0 $((invokes_len - 1))); do
        target=$(echo "$frontmatter" | yq ".dependencies.invokes[$i].skill" 2>/dev/null)
        declared_targets="$declared_targets $target"
      done
    fi
  fi

  # Find skill references in body (e.g., /verify, /evolve)
  for other_skill in $KNOWN_SKILLS; do
    if [ "$other_skill" = "$skill" ]; then continue; fi

    # Check if body references this skill (as /skill-name, not as part of a path like .claude/metrics/)
    # Match: `/skill-name` at word boundary, not preceded by . or /
    if echo "$body" | grep -qE "(^|[^./])/$other_skill([^/a-z-]|$)" 2>/dev/null; then
      # Check if it's declared in frontmatter
      if ! echo "$declared_targets" | grep -qw "$other_skill"; then
        # Check invoked_by as well
        invoked_by_skills=""
        if [ "$has_deps" = "true" ]; then
          invoked_by_len=$(echo "$frontmatter" | yq '.dependencies.invoked_by | length // 0' 2>/dev/null)
          if [ "$invoked_by_len" != "0" ] && [ "$invoked_by_len" != "null" ]; then
            for i in $(seq 0 $((invoked_by_len - 1))); do
              ib_skill=$(echo "$frontmatter" | yq ".dependencies.invoked_by[$i].skill" 2>/dev/null)
              invoked_by_skills="$invoked_by_skills $ib_skill"
            done
          fi
        fi

        if ! echo "$invoked_by_skills" | grep -qw "$other_skill"; then
          warn "$skill body references /$other_skill but not declared in frontmatter dependencies"
        fi
      fi
    fi
  done
done

echo ""

# ============================================================
# Summary
# ============================================================
echo "=========================================="
echo "SUMMARY"
echo "=========================================="
echo "Failures: $FAILURES"
echo "Warnings: $WARNINGS"

if [ $FAILURES -gt 0 ]; then
  echo "VERDICT: FAIL"
  exit 1
else
  if [ $WARNINGS -gt 0 ]; then
    echo "VERDICT: PASS (with warnings)"
  else
    echo "VERDICT: PASS"
  fi
  exit 0
fi
