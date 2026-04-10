#!/usr/bin/env bash
# Generate .claude/skills/dependency-graph.yaml from SKILL.md frontmatter
#
# Usage: generate-skill-depgraph.sh [--check]
#   --check: verify existing graph matches generated output (exit 1 on diff)
#
# Requires: yq (https://github.com/mikefarah/yq)
# Reference: #346

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SKILLS_DIR="$PROJECT_DIR/.claude/skills"
OUTPUT="$SKILLS_DIR/dependency-graph.yaml"
CHECK_MODE=false

if [ "${1:-}" = "--check" ]; then
  CHECK_MODE=true
fi

if ! command -v yq &>/dev/null; then
  echo "ERROR: yq is required but not found. Install: brew install yq" >&2
  exit 1
fi

# Collect all SKILL.md files
SKILL_FILES=()
for skill_dir in "$SKILLS_DIR"/*/; do
  skill_md="$skill_dir/SKILL.md"
  if [ -f "$skill_md" ]; then
    SKILL_FILES+=("$skill_md")
  fi
done

if [ ${#SKILL_FILES[@]} -eq 0 ]; then
  echo "ERROR: No SKILL.md files found in $SKILLS_DIR" >&2
  exit 1
fi

# Extract frontmatter from a SKILL.md file (content between first --- and second ---)
extract_frontmatter() {
  local file="$1"
  awk 'BEGIN{n=0} /^---$/{n++; next} n==1{print} n>=2{exit}' "$file"
}

# Build the dependency graph YAML
GENERATED=$(mktemp)
trap 'rm -f "$GENERATED"' EXIT

cat > "$GENERATED" <<HEADER
# Skill Dependency Graph
# Auto-generated from SKILL.md frontmatter — do not edit manually
# Regenerate: scripts/generate-skill-depgraph.sh
# Verify:     scripts/generate-skill-depgraph.sh --check
# Reference:  #346
#
# Schema: .claude/skills/dependency-schema.yaml

generated_at: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
skill_count: ${#SKILL_FILES[@]}

HEADER

# Process each skill
echo "skills:" >> "$GENERATED"

for skill_md in $(printf '%s\n' "${SKILL_FILES[@]}" | sort); do
  skill_name=$(basename "$(dirname "$skill_md")")
  frontmatter=$(extract_frontmatter "$skill_md")

  # Extract dependencies using yq
  has_deps=$(echo "$frontmatter" | yq 'has("dependencies")' 2>/dev/null)

  echo "  $skill_name:" >> "$GENERATED"

  if [ "$has_deps" != "true" ]; then
    echo "    invokes: []" >> "$GENERATED"
    echo "" >> "$GENERATED"
    continue
  fi

  # Extract invokes
  invokes=$(echo "$frontmatter" | yq '.dependencies.invokes // []' 2>/dev/null)
  invokes_len=$(echo "$frontmatter" | yq '.dependencies.invokes | length // 0' 2>/dev/null)

  if [ "$invokes_len" = "0" ] || [ "$invokes_len" = "null" ]; then
    echo "    invokes: []" >> "$GENERATED"
  else
    echo "    invokes:" >> "$GENERATED"
    for i in $(seq 0 $((invokes_len - 1))); do
      skill=$(echo "$frontmatter" | yq ".dependencies.invokes[$i].skill" 2>/dev/null)
      type=$(echo "$frontmatter" | yq ".dependencies.invokes[$i].type" 2>/dev/null)
      phase=$(echo "$frontmatter" | yq ".dependencies.invokes[$i].phase" 2>/dev/null)
      condition=$(echo "$frontmatter" | yq ".dependencies.invokes[$i].condition // \"\"" 2>/dev/null)

      echo "      - skill: $skill" >> "$GENERATED"
      echo "        type: $type" >> "$GENERATED"
      echo "        phase: \"$phase\"" >> "$GENERATED"
      if [ -n "$condition" ] && [ "$condition" != '""' ] && [ "$condition" != "null" ]; then
        echo "        condition: \"$condition\"" >> "$GENERATED"
      fi
    done
  fi

  # Extract invoked_by (if present)
  invoked_by_len=$(echo "$frontmatter" | yq '.dependencies.invoked_by | length // 0' 2>/dev/null)
  if [ "$invoked_by_len" != "0" ] && [ "$invoked_by_len" != "null" ]; then
    echo "    invoked_by:" >> "$GENERATED"
    for i in $(seq 0 $((invoked_by_len - 1))); do
      skill=$(echo "$frontmatter" | yq ".dependencies.invoked_by[$i].skill" 2>/dev/null)
      phase=$(echo "$frontmatter" | yq ".dependencies.invoked_by[$i].phase" 2>/dev/null)
      expected=$(echo "$frontmatter" | yq ".dependencies.invoked_by[$i].expected_output // \"\"" 2>/dev/null)

      echo "      - skill: $skill" >> "$GENERATED"
      echo "        phase: \"$phase\"" >> "$GENERATED"
      if [ -n "$expected" ] && [ "$expected" != '""' ] && [ "$expected" != "null" ]; then
        echo "        expected_output: \"$expected\"" >> "$GENERATED"
      fi
    done
  fi

  # Extract agents (if present)
  agents_len=$(echo "$frontmatter" | yq '.dependencies.agents | length // 0' 2>/dev/null)
  if [ "$agents_len" != "0" ] && [ "$agents_len" != "null" ]; then
    echo "    agents:" >> "$GENERATED"
    for i in $(seq 0 $((agents_len - 1))); do
      agent=$(echo "$frontmatter" | yq ".dependencies.agents[$i].agent" 2>/dev/null)
      role=$(echo "$frontmatter" | yq ".dependencies.agents[$i].role" 2>/dev/null)

      echo "      - agent: $agent" >> "$GENERATED"
      echo "        role: \"$role\"" >> "$GENERATED"
    done
  fi

  echo "" >> "$GENERATED"
done

# Add computed edges section
echo "# Computed edges (flattened from skill invokes declarations)" >> "$GENERATED"
echo "edges:" >> "$GENERATED"

for skill_md in $(printf '%s\n' "${SKILL_FILES[@]}" | sort); do
  skill_name=$(basename "$(dirname "$skill_md")")
  frontmatter=$(extract_frontmatter "$skill_md")

  invokes_len=$(echo "$frontmatter" | yq '.dependencies.invokes | length // 0' 2>/dev/null)
  if [ "$invokes_len" = "0" ] || [ "$invokes_len" = "null" ]; then
    continue
  fi

  for i in $(seq 0 $((invokes_len - 1))); do
    target=$(echo "$frontmatter" | yq ".dependencies.invokes[$i].skill" 2>/dev/null)
    type=$(echo "$frontmatter" | yq ".dependencies.invokes[$i].type" 2>/dev/null)
    phase=$(echo "$frontmatter" | yq ".dependencies.invokes[$i].phase" 2>/dev/null)

    echo "  - from: $skill_name" >> "$GENERATED"
    echo "    to: $target" >> "$GENERATED"
    echo "    type: $type" >> "$GENERATED"
    echo "    phase: \"$phase\"" >> "$GENERATED"
  done
done

# Add summary statistics
echo "" >> "$GENERATED"
echo "# Summary" >> "$GENERATED"

total_edges=$(grep -c "^  - from:" "$GENERATED" || true)
hard_edges=$(grep -c "type: hard" "$GENERATED" || true)
# Divide by 2 because each edge has type in both skills and edges sections
hard_edges=$((hard_edges / 2))
soft_edges=$((total_edges - hard_edges))

echo "summary:" >> "$GENERATED"
echo "  total_skills: ${#SKILL_FILES[@]}" >> "$GENERATED"
echo "  total_edges: $total_edges" >> "$GENERATED"
echo "  hard_edges: $hard_edges" >> "$GENERATED"
echo "  soft_edges: $soft_edges" >> "$GENERATED"

# Detect bidirectional dependencies
echo "  bidirectional:" >> "$GENERATED"
python3 -c "
import sys
edges = []
with open('$GENERATED') as f:
    lines = f.readlines()

i = 0
while i < len(lines):
    line = lines[i].strip()
    if line.startswith('- from:'):
        fr = line.split(': ', 1)[1]
        to_line = lines[i+1].strip()
        to = to_line.split(': ', 1)[1]
        edges.append((fr, to))
        i += 4  # skip type and phase lines
    else:
        i += 1

# Find mutual edges
seen = set()
for a, b in edges:
    if (b, a) in seen:
        print(f'    - \"{a} <-> {b}\"')
    seen.add((a, b))
" >> "$GENERATED"

if $CHECK_MODE; then
  # Compare with existing file (ignoring generated_at timestamp)
  if [ ! -f "$OUTPUT" ]; then
    echo "ERROR: $OUTPUT does not exist. Run without --check first." >&2
    exit 1
  fi

  # Strip generated_at for comparison
  existing_stripped=$(grep -v '^generated_at:' "$OUTPUT")
  generated_stripped=$(grep -v '^generated_at:' "$GENERATED")

  if [ "$existing_stripped" = "$generated_stripped" ]; then
    echo "✅ dependency-graph.yaml is up to date" >&2
    exit 0
  else
    echo "❌ dependency-graph.yaml is out of date. Run: scripts/generate-skill-depgraph.sh" >&2
    diff <(echo "$existing_stripped") <(echo "$generated_stripped") >&2 || true
    exit 1
  fi
else
  # Output to stdout by default, copy to OUTPUT if writable
  if cp "$GENERATED" "$OUTPUT" 2>/dev/null; then
    echo "Generated $OUTPUT (${#SKILL_FILES[@]} skills, $total_edges edges)" >&2
  else
    cat "$GENERATED"
    echo "Output written to stdout (${#SKILL_FILES[@]} skills, $total_edges edges)" >&2
  fi
fi
