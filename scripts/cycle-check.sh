#!/usr/bin/env bash
# agent-spec-lib Day N cycle compliance check
# Day 54.1 (2026-04-21) で導入、Day 49-54 の Step 7 mandatory checklist 部分省略 再発防止。
#
# 用途:
#   bash scripts/cycle-check.sh             # 全 check
#   bash scripts/cycle-check.sh --quick     # breakdown + schema のみ (fast)
#
# 終了コード:
#   0  全 check PASS
#   1  addressable issue 検出 (commit 前に対処)
#   2  informational warning (attention、但 block せず)

set -u
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
MANIFEST="$REPO_ROOT/agent-spec-lib/artifact-manifest.json"
PENDING="$REPO_ROOT/docs/research/new-foundation-survey/11-pending-tasks.json"
SCHEMA_M="$REPO_ROOT/agent-spec-lib/artifact-manifest.schema.json"
SCHEMA_P="$REPO_ROOT/docs/research/new-foundation-survey/11-pending-tasks.schema.json"

MODE="${1:-full}"
EXIT=0
WARN=0

echo "=== agent-spec-lib cycle-check (mode=$MODE) ==="

# ----- Check 1: breakdown 整合 -----
ec=$(jq '.build_status.example_count' "$MANIFEST")
bs=$(jq '[.build_status.breakdown | to_entries[] | .value.examples] | add' "$MANIFEST")
if [ "$ec" = "$bs" ]; then
  echo "[1] OK  breakdown 整合: example_count=$ec = breakdown_sum=$bs"
else
  echo "[1] NG  breakdown 不整合: example_count=$ec / breakdown_sum=$bs"
  EXIT=1
fi

if [ "$MODE" = "--quick" ]; then exit $EXIT; fi

# ----- Check 2: day_plan 直近 entry の commit 欄 -----
last_done=$(jq -r '[.day_plan[] | select(.status == "done")] | sort_by(.day | if type == "number" then . else (split(".") | .[0] | tonumber) end) | .[-1]' "$PENDING")
last_day=$(echo "$last_done" | jq -r '.day')
last_commit=$(echo "$last_done" | jq -r '.commit // "null"')
if [ "$last_commit" = "null" ]; then
  echo "[2] WARN  Day $last_day の commit 欄が null、次 commit で埋める予定"
  WARN=1
else
  echo "[2] OK  Day $last_day commit=$last_commit"
fi

# ----- Check 3: 7-day empirical cycle -----
last_emp=$(jq -r '[.verifier_history[] | select(.round | test("Empirical"))] | .[-1]' "$MANIFEST")
last_emp_date=$(echo "$last_emp" | jq -r '.date')
last_emp_round=$(echo "$last_emp" | jq -r '.round')

today=$(date -u +%Y-%m-%d)
if date -j -f "%Y-%m-%d" "$last_emp_date" "+%s" >/dev/null 2>&1; then
  epoch_last=$(date -j -f "%Y-%m-%d" "$last_emp_date" "+%s")
  epoch_today=$(date -j -f "%Y-%m-%d" "$today" "+%s")
else
  epoch_last=$(date -d "$last_emp_date" "+%s")
  epoch_today=$(date -d "$today" "+%s")
fi
days_since=$(( (epoch_today - epoch_last) / 86400 ))

if [ "$days_since" -ge 7 ]; then
  echo "[3] WARN  7-day empirical overdue: last=$last_emp_date ($days_since days ago)"
  echo "          last round: $last_emp_round"
  echo "          必要アクション: /empirical-prompt-tuning を実行 (rule I)"
  WARN=1
elif [ "$days_since" -ge 5 ]; then
  echo "[3] ---  7-day empirical 近接: last=$last_emp_date ($days_since days ago、残 $((7-days_since)) days)"
else
  echo "[3] OK  7-day empirical 範囲内: last=$last_emp_date ($days_since days ago)"
fi

# ----- Check 4: long-deferred (Day N timing で未解消の pending items) -----
long_deferred=$(jq -r '.pending_items[] | select((.status == "pending" or .status == "deferred") and (.resolved_day == null)) | select(.timing | test("Day [0-9]+")) | {section, topic, timing}' "$PENDING" | jq -s 'length')

if [ "$long_deferred" -gt 0 ]; then
  echo "[4] WARN  long-deferred 候補 $long_deferred 件 (Day N timing で未解消):"
  jq -r '.pending_items[] | select((.status == "pending" or .status == "deferred") and (.resolved_day == null)) | select(.timing | test("Day [0-9]+")) | "    - [\(.section)] \(.topic) (timing: \(.timing))"' "$PENDING" | head -5
  [ "$long_deferred" -gt 5 ] && echo "    ... (残 $((long_deferred - 5)) 件、jq で完全表示可)"
  WARN=1
else
  echo "[4] OK  long-deferred なし"
fi

# ----- Check 5: schema validation -----
if command -v uv >/dev/null 2>&1; then
  m_result=$(UV_CACHE_DIR=/tmp/claude/uv-cache UV_TOOL_DIR=/tmp/claude/uv-tools UV_TOOL_BIN_DIR=/tmp/claude/uv-bin uv tool run --from check-jsonschema check-jsonschema --schemafile "$SCHEMA_M" "$MANIFEST" 2>&1 | tail -1)
  p_result=$(UV_CACHE_DIR=/tmp/claude/uv-cache UV_TOOL_DIR=/tmp/claude/uv-tools UV_TOOL_BIN_DIR=/tmp/claude/uv-bin uv tool run --from check-jsonschema check-jsonschema --schemafile "$SCHEMA_P" "$PENDING" 2>&1 | tail -1)

  if echo "$m_result" | grep -q "ok -- validation done"; then
    echo "[5a] OK  artifact-manifest.json schema"
  else
    echo "[5a] NG  artifact-manifest.json schema: $m_result"
    EXIT=1
  fi

  if echo "$p_result" | grep -q "ok -- validation done"; then
    echo "[5b] OK  11-pending-tasks.json schema"
  else
    echo "[5b] NG  11-pending-tasks.json schema: $p_result"
    EXIT=1
  fi
else
  echo "[5] WARN  uv not found、schema validation 未実行 (install uv or bypass)"
  WARN=1
fi

# ----- 結果 -----
echo ""
echo "=== Summary ==="
if [ "$EXIT" -ne 0 ]; then
  echo "FAIL: addressable issues 検出、commit 前に対処すること"
  exit 1
elif [ "$WARN" -ne 0 ]; then
  echo "WARNING: informational items あり、確認推奨 (block せず)"
  exit 2
else
  echo "ALL PASS"
  exit 0
fi
