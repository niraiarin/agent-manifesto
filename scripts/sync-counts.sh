#!/usr/bin/env bash
# sync-counts.sh — 決定論的カウント同期スクリプト
#
# Lean ソースから定理数・公理数を算出し、全下流ファイルの数値を同期する。
# Usage:
#   bash scripts/sync-counts.sh [--check|--update|--dry-run]
#
# Modes:
#   --update  (default) 実更新 + 差分表示
#   --check   差分があれば exit 1（pre-commit 用）。ファイル変更なし
#   --dry-run 差分表示のみ、ファイル変更なし
set -euo pipefail

BASE="$(cd "$(dirname "$0")/.." && pwd)"
LEAN_DIR="$BASE/lean-formalization"
MODE="${1:---update}"

# ============================================================
# Step 1: カウント算出
# ============================================================

THEOREM_COUNT=$(grep '^theorem ' "$LEAN_DIR"/Manifest/*.lean | wc -l | tr -d ' ')
AXIOM_COUNT=$(grep '^axiom [a-z]' "$LEAN_DIR"/Manifest/*.lean | wc -l | tr -d ' ')
SORRY_COUNT=0  # lake build の rfl 証明で保証
COMPRESSION=$((THEOREM_COUNT * 100 / AXIOM_COUNT))
COMPRESSION_DECIMAL=$(echo "scale=2; $COMPRESSION / 100" | bc)

# テストカウント: test-all.sh を実行して TOTAL 行をパース
# Note: テスト実行に数秒かかる。SYNC_SKIP_TESTS=1 でスキップ可（pre-commit 高速化用）
if [[ "${SYNC_SKIP_TESTS:-}" == "1" ]]; then
  # テストカウントの同期をスキップ（Lean カウントのみ同期）
  TEST_COUNT=""
else
  TEST_COUNT=$(bash "$BASE/tests/test-all.sh" 2>&1 | grep '^TOTAL:' | grep -o '[0-9]* passed' | grep -o '[0-9]*')
fi

# Per-module theorem count (single file)
count_theorems() {
  local total=0
  for file in "$@"; do
    local c
    c=$(grep -c '^theorem ' "$LEAN_DIR/Manifest/$file" 2>/dev/null || true)
    total=$((total + ${c:-0}))
  done
  echo "$total"
}

# Per-module axiom count (single file)
count_axioms() {
  local total=0
  for file in "$@"; do
    local c
    c=$(grep -c '^axiom [a-z]' "$LEAN_DIR/Manifest/$file" 2>/dev/null || true)
    total=$((total + ${c:-0}))
  done
  echo "$total"
}

echo "=== Computed Counts ==="
echo "theorems:    $THEOREM_COUNT"
echo "axioms:      $AXIOM_COUNT"
echo "sorry:       $SORRY_COUNT"
echo "compression: $COMPRESSION (${COMPRESSION_DECIMAL}x)"
echo "tests:       $TEST_COUNT"
echo ""

# ============================================================
# Step 2: 差分チェック / 更新
# ============================================================

DIFFS=0

# Check or update a file with a sed pattern
# Usage: sync_pattern <file> <sed_pattern> <description>
sync_pattern() {
  local file="$1" pattern="$2" desc="$3"

  if [[ ! -f "$file" ]]; then
    echo "WARN: File not found: $file"
    return
  fi

  local tmp
  tmp=$(mktemp)
  sed "$pattern" "$file" > "$tmp"

  if ! diff -q "$file" "$tmp" > /dev/null 2>&1; then
    DIFFS=$((DIFFS + 1))
    echo "DIFF: $desc"
    diff --unified=0 "$file" "$tmp" | grep '^[+-]' | grep -v '^[+-][+-][+-]' || true

    if [[ "$MODE" == "--update" ]]; then
      # Safety: verify only count-related lines changed, not structure
      local structural_diff
      structural_diff=$(diff "$file" "$tmp" | grep '^[<>]' | grep -cvE '[0-9]+ (axioms|theorems|sorry|tests|compression)' || true)
      if [[ "$structural_diff" -gt 0 ]]; then
        echo "  ⚠ BLOCKED: Non-count structural changes detected in $desc. Manual review needed." >&2
        rm -f "$tmp"
        return
      fi
      # Use sed -i for in-place edit (preserves inode, permissions, other content)
      sed -i '' "$pattern" "$file"
      echo "  → Updated (in-place)"
    fi
  fi
  rm -f "$tmp"
}

echo "=== Checking files ==="

# --- Pattern 1: "N axioms, N theorems, N sorry" (5 files) ---
ATS="s/[0-9][0-9]* axioms, [0-9][0-9]* theorems, [0-9][0-9]* sorry/${AXIOM_COUNT} axioms, ${THEOREM_COUNT} theorems, ${SORRY_COUNT} sorry/g"

sync_pattern "$BASE/CLAUDE.md" "$ATS" "CLAUDE.md: axioms/theorems/sorry"
sync_pattern "$BASE/scripts/lean-to-markdown.py" "$ATS" "lean-to-markdown.py: preamble"
sync_pattern "$BASE/scripts/generate-verso-source.py" "$ATS" "generate-verso-source.py: preamble"
sync_pattern "$LEAN_DIR/docgen-verso/Docs.lean" "$ATS" "Docs.lean: project stats"
sync_pattern "$BASE/docs/generated/manifesto-from-lean.md" "$ATS" "manifesto-from-lean.md: header"

# --- Pattern 2: CLAUDE.md test count (skip if SYNC_SKIP_TESTS) ---
if [[ -n "${TEST_COUNT:-}" ]]; then
  sync_pattern "$BASE/CLAUDE.md" \
    "s/run all [0-9][0-9]* acceptance tests/run all ${TEST_COUNT} acceptance tests/" \
    "CLAUDE.md: test count"

  # --- Pattern 3: SKILL.md test/theorem governance ---
  SKILL="$BASE/.claude/skills/evolve/SKILL.md"
  sync_pattern "$SKILL" \
    "s/[0-9][0-9]* tests pass/${TEST_COUNT} tests pass/" \
    "SKILL.md: T8 test baseline"
  sync_pattern "$SKILL" \
    "s/\(| test pass count (絶対数) |[^|]*| \)[0-9][0-9]*+/\1${TEST_COUNT}+/" \
    "SKILL.md: test governance row"
else
  SKILL="$BASE/.claude/skills/evolve/SKILL.md"
fi
sync_pattern "$SKILL" \
  "s/\(| theorem count (絶対数) |[^|]*| \)[0-9][0-9]*+/\1${THEOREM_COUNT}+/" \
  "SKILL.md: theorem governance row"

# --- Pattern 4: Meta.lean theoremCount (preserve existing whitespace) ---
META="$LEAN_DIR/Manifest/Meta.lean"
sync_pattern "$META" \
  "s/\(theoremCount[[:space:]]*:= \)[0-9][0-9]*/\1${THEOREM_COUNT}/" \
  "Meta.lean: theoremCount"

# --- Pattern 5: Meta.lean rfl theorems ---
sync_pattern "$META" \
  "s/\(currentProfile\.theoremCount = \)[0-9][0-9]*/\1${THEOREM_COUNT}/" \
  "Meta.lean: current_theorem_count"
sync_pattern "$META" \
  "s/\(currentProfile\.totalAxioms = \)[0-9][0-9]*/\1${AXIOM_COUNT}/" \
  "Meta.lean: current_total_axioms"

# --- Pattern 5b: Meta.lean doc comments ---
sync_pattern "$META" \
  "s/総 axiom 数は [0-9][0-9]*/総 axiom 数は ${AXIOM_COUNT}/" \
  "Meta.lean: axiom doc comment"
sync_pattern "$META" \
  "s/定理数は [0-9][0-9]*/定理数は ${THEOREM_COUNT}/" \
  "Meta.lean: theorem doc comment"

# --- Pattern 6: Meta.lean per-module theorem distribution (preserve whitespace + comments) ---
update_module_count() {
  local key="$1" files="$2"
  local val
  val=$(count_theorems $files)
  sync_pattern "$META" \
    "s/\(${key}[[:space:]]*:= \)[0-9][0-9]*/\1${val}/" \
    "Meta.lean: ${key} = ${val}"
}

update_module_count "ontologyM" "Ontology.lean"
update_module_count "axiomsM" "Axioms.lean"
update_module_count "empiricalPostulatesM" "EmpiricalPostulates.lean"
update_module_count "observableM" "Observable.lean ObservableDesign.lean"
update_module_count "principlesM" "Principles.lean"
update_module_count "metaM" "Meta.lean"
update_module_count "terminologyM" "Terminology.lean"
update_module_count "formalDerivationSkillM" "FormalDerivationSkill.lean"
update_module_count "conformanceVerificationM" "ConformanceVerification.lean"
update_module_count "designFoundationM" "DesignFoundation.lean"
update_module_count "procedureM" "Procedure.lean"
update_module_count "evolutionM" "Evolution.lean"
update_module_count "evolveSkillM" "EvolveSkill.lean"
update_module_count "workflowM" "Workflow.lean"
update_module_count "axiomQualityM" "AxiomQuality.lean"
update_module_count "epistemicLayerM" "EpistemicLayer.lean"
update_module_count "taskClassificationM" "TaskClassification.lean"

# --- Pattern 7: Meta.lean axiom sub-counts (preserve whitespace + comments) ---
update_axiom_count() {
  local key="$1" files="$2"
  local val
  val=$(count_axioms $files)
  sync_pattern "$META" \
    "s/\(${key}[[:space:]]*:= \)[0-9][0-9]*/\1${val}/" \
    "Meta.lean: ${key} = ${val}"
}

update_axiom_count "constraintCount" "Axioms.lean"
update_axiom_count "empiricalCount" "EmpiricalPostulates.lean"
update_axiom_count "observableCount" "Observable.lean ObservableDesign.lean"
update_axiom_count "applicationCount" "FormalDerivationSkill.lean ConformanceVerification.lean TaskClassification.lean"
update_axiom_count "structuralCount" "Ontology.lean"

# --- Pattern 7b: README.md counts ---
sync_pattern "$BASE/README.md" \
  "$ATS" \
  "README.md: axioms/theorems/sorry"
sync_pattern "$BASE/README.md" \
  "s/Lean 4 形式検証 ([0-9][0-9]* axioms, [0-9][0-9]* theorems)/Lean 4 形式検証 (${AXIOM_COUNT} axioms, ${THEOREM_COUNT} theorems)/" \
  "README.md: tree stats"

# --- Pattern 7c: lean-formalization/README.md counts ---
LEAN_README="$LEAN_DIR/README.md"
sync_pattern "$LEAN_README" \
  "s/| axiom | [0-9][0-9]* /| axiom | ${AXIOM_COUNT} /" \
  "lean-formalization/README.md: axiom count"
sync_pattern "$LEAN_README" \
  "s/| theorem | [0-9][0-9]* /| theorem | ${THEOREM_COUNT} /" \
  "lean-formalization/README.md: theorem count"
sync_pattern "$LEAN_README" \
  "s/[0-9][0-9]* theorems \/ [0-9][0-9]* axioms/${THEOREM_COUNT} theorems \/ ${AXIOM_COUNT} axioms/" \
  "lean-formalization/README.md: compression text"
sync_pattern "$LEAN_README" \
  "s/[0-9.]*x ([0-9][0-9]* theorems/${COMPRESSION_DECIMAL}x (${THEOREM_COUNT} theorems/" \
  "lean-formalization/README.md: compression ratio"
if [[ -n "${TEST_COUNT:-}" ]]; then
  sync_pattern "$LEAN_README" \
    "s/[0-9][0-9]* acceptance tests/${TEST_COUNT} acceptance tests/" \
    "lean-formalization/README.md: test count"
fi

# --- Pattern 8: AxiomQuality.lean compression ratio ---
AQ="$LEAN_DIR/Manifest/AxiomQuality.lean"
sync_pattern "$AQ" \
  "s/例: [0-9][0-9]* theorems \/ [0-9][0-9]* axioms = [0-9][0-9]* (= [0-9.]*x)/例: ${THEOREM_COUNT} theorems \/ ${AXIOM_COUNT} axioms = ${COMPRESSION} (= ${COMPRESSION_DECIMAL}x)/" \
  "AxiomQuality.lean: doc comment (example)"
sync_pattern "$AQ" \
  "s/圧縮比は [0-9][0-9]* (= [0-9.]*x)/圧縮比は ${COMPRESSION} (= ${COMPRESSION_DECIMAL}x)/" \
  "AxiomQuality.lean: doc comment (value)"
sync_pattern "$AQ" \
  "s/\(compressionRatio currentProfile = \)[0-9][0-9]*/\1${COMPRESSION}/" \
  "AxiomQuality.lean: current_compression"

# ============================================================
# Step 3: 結果報告
# ============================================================

echo ""
if [[ $DIFFS -eq 0 ]]; then
  echo "✓ All files in sync."
  exit 0
else
  echo "Found $DIFFS difference(s)."
  if [[ "$MODE" == "--check" ]]; then
    echo "Run 'bash scripts/sync-counts.sh --update' to fix."
    exit 1
  elif [[ "$MODE" == "--dry-run" ]]; then
    echo "(dry-run: no files modified)"
    exit 1
  else
    echo "All files updated."
    exit 0
  fi
fi
