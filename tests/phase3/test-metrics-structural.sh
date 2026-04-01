#!/usr/bin/env bash
set -uo pipefail
PASS=0; FAIL=0
BASE="$(git rev-parse --show-toplevel 2>/dev/null || echo /Users/nirarin/work/agent-manifesto)"

echo "=== Phase 3: V1-V7 Measurement Infrastructure Structural Tests ==="

check() {
  local name="$1" cond="$2"
  echo -n "$name... "
  if eval "$cond"; then echo "PASS"; PASS=$((PASS+1)); else echo "FAIL"; FAIL=$((FAIL+1)); fi
}

# V2: p4-metrics-collector.sh existence and tool-usage.jsonl schema
check "MT.4 V2 p4-metrics-collector.sh exists and is executable" \
  "[ -x '$BASE/.claude/hooks/p4-metrics-collector.sh' ]"

check "MT.5 V2 tool-usage.jsonl exists" \
  "[ -f '$BASE/.claude/metrics/tool-usage.jsonl' ]"

check "MT.6 V2 tool-usage.jsonl has required fields (timestamp, event, tool, session)" \
  "head -1 '$BASE/.claude/metrics/tool-usage.jsonl' 2>/dev/null | jq -e 'has(\"timestamp\") and has(\"event\") and has(\"tool\") and has(\"session\")' >/dev/null 2>&1"

# V4: p4-gate-logger.sh existence and session summary schema
check "MT.7 V4 p4-gate-logger.sh exists and is executable" \
  "[ -x '$BASE/.claude/hooks/p4-gate-logger.sh' ]"

check "MT.8 V4 sessions.jsonl exists" \
  "[ -f '$BASE/.claude/metrics/sessions.jsonl' ]"

check "MT.9 V4 sessions.jsonl has required fields (timestamp, event)" \
  "head -1 '$BASE/.claude/metrics/sessions.jsonl' 2>/dev/null | jq -e 'has(\"timestamp\") and has(\"event\")' >/dev/null 2>&1"

# V5: p4-v5-approval-tracker.sh and v5-approvals.jsonl schema
check "MT.10 V5 p4-v5-approval-tracker.sh exists and is executable" \
  "[ -x '$BASE/.claude/hooks/p4-v5-approval-tracker.sh' ]"

check "MT.11 V5 v5-approvals.jsonl exists" \
  "[ -f '$BASE/.claude/metrics/v5-approvals.jsonl' ]"

check "MT.12 V5 v5-approvals.jsonl has required fields (timestamp, event, result)" \
  "head -1 '$BASE/.claude/metrics/v5-approvals.jsonl' 2>/dev/null | jq -e 'has(\"timestamp\") and has(\"event\") and has(\"result\")' >/dev/null 2>&1"

# V7: p4-v7-task-tracker.sh and v7-tasks.jsonl schema
check "MT.13 V7 p4-v7-task-tracker.sh exists and is executable" \
  "[ -x '$BASE/.claude/hooks/p4-v7-task-tracker.sh' ]"

check "MT.14 V7 v7-tasks.jsonl exists" \
  "[ -f '$BASE/.claude/metrics/v7-tasks.jsonl' ]"

check "MT.15 V7 v7-tasks.jsonl has required fields (timestamp, event, subject)" \
  "head -1 '$BASE/.claude/metrics/v7-tasks.jsonl' 2>/dev/null | jq -e 'has(\"timestamp\") and has(\"event\") and has(\"subject\")' >/dev/null 2>&1"

# V1/V3: benchmark.json GQM schema
check "MT.16 V1/V3 benchmark.json exists" \
  "[ -f '$BASE/.claude/metrics/benchmark.json' ]"

check "MT.17 V1/V3 benchmark.json has v1_skill_quality and v3_output_quality" \
  "jq -e 'has(\"v1_skill_quality\") and has(\"v3_output_quality\")' '$BASE/.claude/metrics/benchmark.json' >/dev/null 2>&1"

check "MT.18 V1/V3 benchmark.json has _meta.version field" \
  "jq -e '._meta.version != null' '$BASE/.claude/metrics/benchmark.json' >/dev/null 2>&1"

# V6: skill:trace artifact-manifest.json reference
check "MT.19 V6 artifact-manifest.json exists" \
  "[ -f '$BASE/artifact-manifest.json' ]"

check "MT.20 V6 artifact-manifest.json is valid JSON" \
  "jq . '$BASE/artifact-manifest.json' >/dev/null 2>&1"

check "MT.21 V6 artifact-manifest.json has skill:trace entry" \
  "jq -e '.artifacts[] | select(.id == \"skill:trace\")' '$BASE/artifact-manifest.json' >/dev/null 2>&1"

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
