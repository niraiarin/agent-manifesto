#!/usr/bin/env bash
# generate-evolve-entry.sh — evolve-history.jsonl エントリの deterministic フィールドを自動生成
#
# Integrator が埋めるべき judgmental フィールドは placeholder として出力。
# 生成されたテンプレートは validate-evolve-entry.sh で事前検証可能。
#
# Usage:
#   bash scripts/generate-evolve-entry.sh [--run N] [--observer-findings N]
#     [--hyp-proposals N] [--verifier-pass N] [--verifier-fail N]
#     [--integrator-commits N] [--judge-evaluated N] [--judge-pass N]
#     [--judge-conditional N] [--judge-fail N] [--judge-avg F]
#
# Options:
#   --run N               Run 番号を指定（省略時は前回 +1）
#   --observer-findings N Observer 検出件数
#   --hyp-proposals N     Hypothesizer 提案件数
#   --verifier-pass N     Verifier PASS 件数
#   --verifier-fail N     Verifier FAIL 件数
#   --integrator-commits N Integrator コミット件数
#   --judge-evaluated N   Judge 評価件数
#   --judge-pass N        Judge PASS 件数
#   --judge-conditional N Judge CONDITIONAL 件数
#   --judge-fail N        Judge FAIL 件数
#   --judge-avg F         Judge 平均スコア
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
OBS_FINDINGS=""
HYP_PROPOSALS=""
VER_PASS=""
VER_FAIL=""
INT_COMMITS=""
JUDGE_EVALUATED=""
JUDGE_PASS=""
JUDGE_CONDITIONAL=""
JUDGE_FAIL=""
JUDGE_AVG=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --run) RUN_NUM="$2"; shift 2 ;;
    --observer-findings) OBS_FINDINGS="$2"; shift 2 ;;
    --hyp-proposals) HYP_PROPOSALS="$2"; shift 2 ;;
    --verifier-pass) VER_PASS="$2"; shift 2 ;;
    --verifier-fail) VER_FAIL="$2"; shift 2 ;;
    --integrator-commits) INT_COMMITS="$2"; shift 2 ;;
    --judge-evaluated) JUDGE_EVALUATED="$2"; shift 2 ;;
    --judge-pass) JUDGE_PASS="$2"; shift 2 ;;
    --judge-conditional) JUDGE_CONDITIONAL="$2"; shift 2 ;;
    --judge-fail) JUDGE_FAIL="$2"; shift 2 ;;
    --judge-avg) JUDGE_AVG="$2"; shift 2 ;;
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
  SESSION_ID=$(tail -1 "$TOOL_LOG" | jq -r '.session // .session_id // "unknown"' 2>/dev/null || echo "unknown")
fi

# Lean stats
AXIOMS=0
THEOREMS=0
SORRY=0
if [[ -d "$LEAN_DIR/Manifest" ]]; then
  # Match sync-counts.sh: top-level Manifest/*.lean only (NOT recursive)
  AXIOMS=$(grep '^axiom [a-z]' "$LEAN_DIR"/Manifest/*.lean 2>/dev/null | wc -l | tr -d ' ')
  THEOREMS=$(grep '^theorem ' "$LEAN_DIR"/Manifest/*.lean 2>/dev/null | wc -l | tr -d ' ')
  # sorry タクティクの実使用を検出（コメント・識別子内の言及は除外）
  SORRY=$({ grep -E '^\s*sorry\s*$|:=\s*sorry\s*$|\bby\s+sorry\b' "$LEAN_DIR"/Manifest/*.lean 2>/dev/null || true; } | wc -l | tr -d ' ')
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

# --- Build judge JSON (null if no judge args provided) ---
if [[ -n "$JUDGE_EVALUATED" ]]; then
  JUDGE_JSON="{'evaluated': int('${JUDGE_EVALUATED}'), 'pass': int('${JUDGE_PASS:-0}'), 'conditional': int('${JUDGE_CONDITIONAL:-0}'), 'fail': int('${JUDGE_FAIL:-0}'), 'avg_score': float('${JUDGE_AVG:-0}')}"
else
  JUDGE_JSON="None"
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
        'observer': {'findings_count': int('${OBS_FINDINGS:-0}'), 'model': 'sonnet'},
        'hypothesizer': {'proposals_count': int('${HYP_PROPOSALS:-0}'), 'model': 'opus'},
        'verifier': {'pass_count': int('${VER_PASS:-0}'), 'fail_count': int('${VER_FAIL:-0}'), 'model': 'sonnet'},
        'judge': ${JUDGE_JSON},
        'integrator': {'commits_count': int('${INT_COMMITS:-0}'), 'model': 'sonnet'}
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
