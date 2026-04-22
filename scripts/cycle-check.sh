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

# ----- Check 1: breakdown 整合 (Day 59 F2 fix: sum=0 regression 検出 追加) -----
ec=$(jq '.build_status.example_count' "$MANIFEST")
bs=$(jq '[.build_status.breakdown | to_entries[] | .value.examples] | add' "$MANIFEST")
if [ "$ec" = "$bs" ]; then
  if [ "$ec" = "0" ]; then
    echo "[1] NG  breakdown sum=0 regression: example_count=0 で整合するが空の build_status は regression 兆候"
    EXIT=1
  else
    echo "[1] OK  breakdown 整合: example_count=$ec = breakdown_sum=$bs"
  fi
else
  echo "[1] NG  breakdown 不整合: example_count=$ec / breakdown_sum=$bs"
  EXIT=1
fi

if [ "$MODE" = "--quick" ]; then exit $EXIT; fi

# ----- Check 2: day_plan 直近 entry の commit 欄 (Day 59 F2 fix: null/missing 区別) -----
last_done=$(jq -r '[.day_plan[] | select(.status == "done")] | sort_by(.day | if type == "number" then . else (split(".") | .[0] | tonumber) end) | .[-1]' "$PENDING")
last_day=$(echo "$last_done" | jq -r '.day')
has_commit=$(echo "$last_done" | jq -r 'has("commit")')
last_commit=$(echo "$last_done" | jq -r '.commit // "__null__"')
if [ "$has_commit" != "true" ]; then
  echo "[2] WARN  Day $last_day に commit field が missing (構造欠損、意図的削除の可能性)"
  WARN=1
elif [ "$last_commit" = "__null__" ] || [ "$last_commit" = "null" ]; then
  echo "[2] WARN  Day $last_day の commit 値が null (未入力、次 commit で埋める予定)"
  WARN=1
else
  echo "[2] OK  Day $last_day commit=$last_commit"
fi

# ----- Check 3: 7-day empirical cycle -----
last_emp=$(jq -r '[.verifier_history[] | select(.round | test("Empirical"))] | .[-1]' "$MANIFEST")
last_emp_date=$(echo "$last_emp" | jq -r '.date')
last_emp_round=$(echo "$last_emp" | jq -r '.round')

today=$(date -u +%Y-%m-%d)
# macOS BSD date は -ju で UTC parse、GNU date は -u で UTC
if date -ju -f "%Y-%m-%d" "$last_emp_date" "+%s" >/dev/null 2>&1; then
  epoch_last=$(date -ju -f "%Y-%m-%d" "$last_emp_date" "+%s")
  epoch_today=$(date -ju -f "%Y-%m-%d" "$today" "+%s")
else
  epoch_last=$(date -u -d "$last_emp_date" "+%s")
  epoch_today=$(date -u -d "$today" "+%s")
fi
days_since=$(( (epoch_today - epoch_last) / 86400 ))

if [ "$days_since" -lt -1 ]; then
  # -1 以下は clock skew 許容範囲、-2 以下は明らかな future-date
  echo "[3] WARN  7-day empirical future-date detected: last=${last_emp_date} (days_since=${days_since}、clock skew / typo 疑い)"
  WARN=1
elif [ "$days_since" -ge 7 ]; then
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

# ----- Check 6: verifier_history + day_plan entry 数の monotonic check (Day 59 F2 fix) -----
# .claude/metrics/ に前回 count を記録し、減少していたら WARN
COUNT_FILE="$REPO_ROOT/.claude/metrics/cycle-check-counts.json"
mkdir -p "$(dirname "$COUNT_FILE")" 2>/dev/null

current_vh=$(jq '.verifier_history | length' "$MANIFEST")
current_dp=$(jq '.day_plan | length' "$PENDING")

if [ -f "$COUNT_FILE" ]; then
  prev_vh=$(jq -r '.verifier_history_count // 0' "$COUNT_FILE")
  prev_dp=$(jq -r '.day_plan_count // 0' "$COUNT_FILE")
  if [ "$current_vh" -lt "$prev_vh" ]; then
    echo "[6a] NG  verifier_history entry 数が減少: $prev_vh → $current_vh (意図的削除? 監査必要)"
    EXIT=1
  else
    echo "[6a] OK  verifier_history monotonic: $prev_vh → $current_vh"
  fi
  if [ "$current_dp" -lt "$prev_dp" ]; then
    echo "[6b] NG  day_plan entry 数が減少: $prev_dp → $current_dp (意図的削除? 監査必要)"
    EXIT=1
  else
    echo "[6b] OK  day_plan monotonic: $prev_dp → $current_dp"
  fi
else
  echo "[6] ---  monotonic check baseline 記録 (次回以降比較): vh=$current_vh dp=$current_dp"
fi

# ----- Check 7: verifier_history date monotonic (Day 68 G2 F3-1 fix) -----
# date 後戻りは history rewrite or typo の兆候、informational
non_monotonic_dates=$(jq -r '
  .verifier_history
  | [.[] | .date // empty]
  | . as $d
  | [range(0; length-1) | select($d[.] > $d[.+1]) | "index \(.): \($d[.]) > \($d[.+1])"]
  | .[]
' "$MANIFEST" 2>/dev/null | head -3)
if [ -n "$non_monotonic_dates" ]; then
  echo "[7] WARN  verifier_history date non-monotonic detected:"
  echo "$non_monotonic_dates" | sed 's/^/    /'
  WARN=1
else
  echo "[7] OK  verifier_history date monotonic"
fi

# ----- Check 8: day_plan commit hash format (Day 68 G2 F3-2 fix) -----
# commit field が valid hex (7+ char) でなければ typo 兆候
invalid_commits=$(jq -r '
  .day_plan
  | map(select(has("commit")) | select(.commit != null))
  | map(select(.commit | type == "string"))
  | map(select(.commit | test("^[a-fA-F0-9]{7,40}$") | not))
  | map("Day \(.day): commit=\"\(.commit)\"")
  | .[]
' "$PENDING" 2>/dev/null | head -3)
if [ -n "$invalid_commits" ]; then
  echo "[8] WARN  day_plan commit hash format invalid:"
  echo "$invalid_commits" | sed 's/^/    /'
  WARN=1
else
  echo "[8] OK  day_plan commit hash format"
fi

# ----- Check 9: day_plan day duplicate (status=done) (Day 68 G2 F3-3 fix) -----
# 同じ Day N が複数 done entry を持つのは整理不足、informational
done_dups=$(jq -r '
  [.day_plan[] | select(.status == "done") | .day]
  | group_by(.) | map(select(length > 1))
  | map("day \(.[0]) appears \(length) times")
  | .[]
' "$PENDING" 2>/dev/null | head -3)
if [ -n "$done_dups" ]; then
  echo "[9] WARN  day_plan duplicate days (status=done):"
  echo "$done_dups" | sed 's/^/    /'
  WARN=1
else
  echo "[9] OK  day_plan day uniqueness (status=done)"
fi

# ----- Check 10: breakdown keys 存在 (Day 68 G2 F3-4 fix) -----
# breakdown は AgentSpec/ 配下の relative path、対応 file が消えていれば stale entry
missing_files=""
while IFS= read -r key; do
  if [ ! -f "$REPO_ROOT/agent-spec-lib/AgentSpec/$key" ]; then
    missing_files+="$key"$'\n'
  fi
done < <(jq -r '.build_status.breakdown | keys[]' "$MANIFEST" 2>/dev/null)
missing_files=$(echo "$missing_files" | sed '/^$/d' | head -3)
if [ -n "$missing_files" ]; then
  echo "[10] WARN  breakdown keys に対応 file が存在しない:"
  echo "$missing_files" | sed 's/^/    /'
  WARN=1
else
  echo "[10] OK  breakdown keys 全て対応 file 存在"
fi

# ----- Check 11: long-deferred aging (Day 68 G2 F3-5 fix) -----
# pending/deferred entry の timing="Day NN+" 抽出、最新 done day と比較し
# AGING_THRESHOLD Day 以上経過していれば escalate prompt
# day field は number と string ("54.1" 等) 混在のため整数部で正規化 (Check 2 と同パターン)
last_done_day=$(jq -r '
  [.day_plan[] | select(.status == "done") | .day
   | if type == "number" then . else (split(".") | .[0] | tonumber) end]
  | sort | .[-1] // 0
' "$PENDING")
AGING_THRESHOLD=14
aging_items=$(jq -r --argjson last "$last_done_day" --argjson th "$AGING_THRESHOLD" '
  .pending_items[]
  | select((.status == "pending" or .status == "deferred") and (.resolved_day == null))
  | select(.timing != null and (.timing | type) == "string")
  | select(.timing | test("Day [0-9]+"))
  | (.timing | capture("Day (?<n>[0-9]+)") | .n | tonumber) as $tday
  | select($last - $tday >= $th)
  | "[\(.section)] \(.topic) (timing: \(.timing)、age: \($last - $tday) Day)"
' "$PENDING" 2>/dev/null | head -3)
if [ -n "$aging_items" ]; then
  echo "[11] WARN  long-deferred aging $AGING_THRESHOLD+ Day (escalate prompt):"
  echo "$aging_items" | sed 's/^/    /'
  WARN=1
else
  echo "[11] OK  long-deferred aging 範囲内 (< $AGING_THRESHOLD Day)"
fi

# ----- Check 12: 9-step cycle coverage (Day 69 再発防止) -----
# Day 69+ の done entry には steps_completed field で 9 step 実施記録を要求
# Day 68 以前は legacy (field 不在を許容)
STEP_TRACK_SINCE=69
last_done_entry=$(jq -r '
  [.day_plan[] | select(.status == "done")]
  | sort_by(.day | if type == "number" then . else (split(".") | .[0] | tonumber) end)
  | .[-1]
' "$PENDING")
last_day_for_steps=$(echo "$last_done_entry" | jq -r '.day | if type == "number" then . else (split(".") | .[0] | tonumber) end')

if [ "$last_day_for_steps" -ge "$STEP_TRACK_SINCE" ] 2>/dev/null; then
  steps_json=$(echo "$last_done_entry" | jq '.steps_completed // []')
  steps_count=$(echo "$steps_json" | jq 'unique | length')
  if [ "$steps_count" -eq 0 ]; then
    echo "[12] WARN  Day $last_day_for_steps: steps_completed field なし (9-step cycle tracking 未実施)"
    WARN=1
  elif [ "$steps_count" -lt 9 ]; then
    missing_steps=$(echo "$steps_json" | jq '[range(1;10)] - . | sort')
    echo "[12] WARN  Day $last_day_for_steps: 9-step cycle incomplete ($steps_count/9), missing steps: $missing_steps"
    WARN=1
  else
    echo "[12] OK  Day $last_day_for_steps: 9-step cycle complete (9/9)"
  fi
else
  echo "[12] ---  legacy day ($last_day_for_steps < $STEP_TRACK_SINCE、steps_completed tracking は Day $STEP_TRACK_SINCE+ で有効)"
fi

# baseline 更新 (EXIT=0/2 の場合のみ、FAIL 時は更新せず既存を保持)
if [ "$EXIT" -eq 0 ]; then
  printf '{"verifier_history_count":%d,"day_plan_count":%d,"last_checked":"%s"}\n' \
    "$current_vh" "$current_dp" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$COUNT_FILE"
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
