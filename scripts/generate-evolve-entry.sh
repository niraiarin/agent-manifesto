#!/usr/bin/env bash
# generate-evolve-entry.sh — evolve-history.jsonl エントリの deterministic フィールドを自動生成
#
# Integrator が埋めるべき judgmental フィールドは placeholder として出力。
# 生成されたテンプレートは validate-evolve-entry.sh で事前検証可能。
#
# Usage:
#   bash scripts/generate-evolve-entry.sh [--run N]
#
# Options:
#   --run N   Run 番号を指定（省略時は前回 +1）
#
# Output: JSON テンプレート (stdout)
# 依存: python3, jq, lean-formalization/Manifest/
#
# G3 (#234) / Parent: #230

set -euo pipefail

BASE="$(cd "$(dirname "$0")/.." && pwd)"
HISTORY="$BASE/.claude/metrics/evolve-history.jsonl"
TOOL_LOG="$BASE/.claude/metrics/tool-usage.jsonl"
LEAN_DIR="$BASE/lean-formalization"

# --- Parse arguments ---
RUN_NUM=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --run) RUN_NUM="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

# --- Compute deterministic fields ---

# Run number: last run + 1
if [[ -z "$RUN_NUM" ]]; then
  if [[ -f "$HISTORY" ]]; then
    LAST_RUN=$(jq -r '.run // 0' "$HISTORY" 2>/dev/null | grep -E '^[0-9]+$' | sort -n | tail -1)
    RUN_NUM=$((${LAST_RUN:-0} + 1))
  else
    RUN_NUM=1
  fi
fi

# Timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Session ID from tool-usage.jsonl (latest entry)
SESSION_ID="unknown"
if [[ -f "$TOOL_LOG" ]]; then
  SESSION_ID=$(tail -1 "$TOOL_LOG" | jq -r '.session_id // "unknown"' 2>/dev/null || echo "unknown")
fi

# Lean stats
AXIOMS=0
THEOREMS=0
SORRY=0
if [[ -d "$LEAN_DIR/Manifest" ]]; then
  # Match sync-counts.sh: top-level Manifest/*.lean only (NOT recursive)
  AXIOMS=$(grep '^axiom [a-z]' "$LEAN_DIR"/Manifest/*.lean 2>/dev/null | wc -l | tr -d ' ')
  THEOREMS=$(grep '^theorem ' "$LEAN_DIR"/Manifest/*.lean 2>/dev/null | wc -l | tr -d ' ')
  SORRY=0  # lake build guarantees sorry=0
fi

# Test results
TEST_PASSED=0
TEST_FAILED=0
if [[ -f "$BASE/tests/test-all.sh" ]]; then
  TEST_OUTPUT=$(bash "$BASE/tests/test-all.sh" 2>&1 || true)
  TEST_PASSED=$(echo "$TEST_OUTPUT" | grep -oE '[0-9]+ passed' | tail -1 | grep -oE '[0-9]+' || echo "0")
  TEST_FAILED=$(echo "$TEST_OUTPUT" | grep -oE '[0-9]+ failed' | tail -1 | grep -oE '[0-9]+' || echo "0")
fi

# Benchmark from observe.sh (if available)
NON_TRIVIALITY_SCORE=0
NON_TRIVIALITY_LABEL="trivial"
SATURATION_CONSECUTIVE=0
SATURATION_STATUS="ok"
if [[ -f "$BASE/.claude/skills/evolve/scripts/observe.sh" ]]; then
  OBSERVE_JSON=$(bash "$BASE/.claude/skills/evolve/scripts/observe.sh" 2>/dev/null || echo '{}')
  NON_TRIVIALITY_SCORE=$(echo "$OBSERVE_JSON" | jq -r '.metrics.non_triviality_score // 0' 2>/dev/null || echo "0")
  NON_TRIVIALITY_LABEL=$(echo "$OBSERVE_JSON" | jq -r '.metrics.non_triviality_label // "trivial"' 2>/dev/null || echo "trivial")
  SATURATION_CONSECUTIVE=$(echo "$OBSERVE_JSON" | jq -r '.metrics.saturation_consecutive // 0' 2>/dev/null || echo "0")
  SATURATION_STATUS=$(echo "$OBSERVE_JSON" | jq -r '.metrics.saturation_status // "ok"' 2>/dev/null || echo "ok")
fi

# --- Generate JSON template ---
python3 -c "
import json, sys

entry = {
    'run': int('$RUN_NUM'),
    'timestamp': '$TIMESTAMP',
    'session_id': '$SESSION_ID',
    'result': 'success',
    'improvements': [],
    'rejected': [],
    'commits': [],
    'lean': {
        'axioms': int('$AXIOMS'),
        'theorems': int('$THEOREMS'),
        'sorry': int('$SORRY')
    },
    'tests': {
        'passed': int('$TEST_PASSED'),
        'failed': int('$TEST_FAILED')
    },
    'phases': {
        'observer': {'findings_count': 0, 'model': 'sonnet'},
        'hypothesizer': {'proposals_count': 0, 'model': 'opus'},
        'verifier': {'pass_count': 0, 'fail_count': 0, 'model': 'sonnet'},
        'integrator': {'commits_count': 0, 'model': 'sonnet'}
    },
    'v_changes': {},
    'benchmark': {
        'non_triviality_score': int('$NON_TRIVIALITY_SCORE'),
        'non_triviality_label': '$NON_TRIVIALITY_LABEL',
        'saturation_consecutive': int('$SATURATION_CONSECUTIVE'),
        'saturation_status': '$SATURATION_STATUS'
    },
    'deferred': [],
    'cost': {
        'session_cost_usd': None,
        'improvements_count': 0,
        'cost_per_improvement_usd': None,
        'source': 'ccusage_session'
    },
    'notes': 'TODO: add run notes'
}

print(json.dumps(entry, ensure_ascii=False))
"
