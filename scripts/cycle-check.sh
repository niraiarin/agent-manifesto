#!/usr/bin/env bash
# agent-spec-lib Day N cycle compliance check
# Day 54.1 (2026-04-21) で導入 (Day 49-54 の Step 7 部分省略 再発防止)。
# Day 78/81/88/102/104 で拡張、現 16 check (cycle hygiene + metadata 整合 + 9-step coverage 検証)。
# Check 1-6: breakdown / commit / empirical / long-deferred / schema / monotonic
# Check 7-11: date monotonic / hash format / day duplicate / breakdown keys / aging
# Check 12: 9-step complete (Day 69+) / Check 13: Step 6 ref (Day 81+)
# Check 14: doc-length lint (Day 88+) / Check 15: 9-step coverage (Day 102 audit prevention)
# Check 16: scope marker 検査 (Day 104 empirical #10 / Day 103+ false PASS 防御)
#
# 用途:
#   bash scripts/cycle-check.sh             # 全 check (full mode、15 check)
#   bash scripts/cycle-check.sh --quick     # breakdown 整合のみ (Check 1)、commit 直前 fast check
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

# ----- Check 13: Step 6 docs 反映 artifact ref (Day 81 N5 [Gap D] fix) -----
# Day 70+ で step 6 claimed の entry は、docs_reflection_commit field か
# scope に「同 commit に統合」/「後続 docs 反映」等の textual ref を要求
# (Day 74 で 8615340 separate commit pattern、Day 75-77 で scope 内統合 pattern の両方許容)
STEP6_MISSING=$(jq -r '
  .day_plan
  | map(select((.day | tostring | tonumber? // 0) >= 70))
  | map(select((.steps_completed // []) | any(. == 6)))
  | map(select((.docs_reflection_commit // null) == null))
  | map(select(((.scope // "") | test("後続 docs|docs 反映|同 commit に?統合|docs_reflection|Step 6 同 commit")) | not))
  | map("Day \(.day): Step 6 claimed but no docs_reflection_commit field nor textual ref in scope")
  | .[]
' "$PENDING" 2>/dev/null | head -3)

if [ -n "$STEP6_MISSING" ]; then
  echo "[13] WARN  Step 6 docs 反映の artifact ref 不在 (Day 70+、steps_completed に 6 含む entry):"
  echo "$STEP6_MISSING" | sed 's/^/    /'
  WARN=1
else
  echo "[13] OK  Step 6 docs 反映 artifact ref (Day 70+)"
fi

# ----- Check 14: doc-length lint integration (Day 88 P1 fix) -----
# orphan だった check-doc-length.sh を cycle-check で invoke。
# warn-only (super-strict は --strict mode、本 cycle-check では non-strict)
if [ -x "$SCRIPT_DIR/check-doc-length.sh" ]; then
  DL_OUT=$(bash "$SCRIPT_DIR/check-doc-length.sh" 2>&1)
  DL_WARN=$(echo "$DL_OUT" | grep -c "WARN" || true)
  if [ "$DL_WARN" -gt 0 ]; then
    echo "[14] WARN  check-doc-length: $DL_WARN warning detected (詳細は check-doc-length.sh 単独実行)"
    WARN=1
  else
    echo "[14] OK  check-doc-length: 全 PASS"
  fi
else
  echo "[14] ---  check-doc-length.sh not executable (Day 88 P1 integration が未配備)"
fi

# ----- Check 15: 9-step cycle coverage (Day 102 audit fix) -----
# 各 Day entry の steps_completed ∪ map(.step) steps_skipped が ≥ 8 step を cover
# (Step 4 は通常空ぶり許容、∴ 8 step 以上で OK)
# 不完全カバレッジ entry は WARN
INCOMPLETE_DAYS=$(jq -r '
  .day_plan
  | map(select(.status == "done"))
  | map(select((.day | tostring | tonumber? // 0) >= 90))
  | map({day: .day, covered: ((.steps_completed // []) + ((.steps_skipped // []) | map(.step)) | unique)})
  | map(select((.covered | length) < 8))
  | map("Day \(.day): covered \(.covered | length)/9 (\(.covered))")
  | .[]
' "$PENDING" 2>/dev/null | head -3)

if [ -n "$INCOMPLETE_DAYS" ]; then
  echo "[15] WARN  9-step cycle coverage 不完全 (steps_completed ∪ steps_skipped < 8、Day 90+):"
  echo "$INCOMPLETE_DAYS" | sed 's/^/    /'
  WARN=1
else
  echo "[15] OK  9-step cycle coverage (Day 90+ 全 entry ≥ 8 step coverage)"
fi

# ----- Check 16: scope text marker 検査 (Day 104 empirical #10 / iter 2 fix) -----
# Empirical #10 で Check 15 の濃度のみ検査の限界 (false PASS) を識別、要素真正性 check として追加。
# Day 103+ entry で steps_completed に Step 1/3/7 を含む場合、scope に対応 marker 必須化。
# Day 103 base (Day 102 audit 規律下の最初の Day、Day 91-101 legacy 除外)。
#
# Empirical #11 (Day 111) 知見:
#   - Check 14 (SCOPE_LIMIT 400) と互換: marker token cost ~30 chars (e.g. "reference read"+"TyDD"+"Step 7 mandatory checklist")、
#     budget 92% 余裕。Check 14 WARN は冗長 prose 起因であり Check 16 marker 必須化と conflict しない。
#   - Token monoculture 警告: Day 103-110 で `reference read`=5/8 hit dominant、`Principles.lean` `iter N` `対象…read/レビュー` は hit 0。
#     marker 多様化推奨 (artifact path + iter 番号 + subagent 種別など複数 token を組合せる)。
#   - 限界 (false marker attack): substring 一致のみのため `paper survey TyDD Step 7 mandatory checklist` 並べた偽 scope は PASS。
#     真の artifact-ref 検証は Check 17 候補 (pending_items: artifact-ref required) で別解決。
NO_MARKER_DAYS=$(jq -r '
  .day_plan
  | map(select(.status == "done"))
  | map(select((.day | tostring | tonumber? // 0) >= 103))
  | map(. as $entry | (.steps_completed // []) as $sc |
      [
        (if ($sc | any(. == 1)) and (($entry.scope // "") | test("paper survey|paper サーベイ|外部 paper|00-synthesis|Principles\\.lean|reference (read|内容)|subagent (dispatch)?|対象.*(read|レビュー)|iter [0-9]") | not)
         then "Day \($entry.day): Step 1 in completed but no paper survey marker in scope" else empty end),
        (if ($sc | any(. == 3)) and (($entry.scope // "") | test("TyDD|S1 (5 軸|構造)|S4 (5 principles|原則)|F/B/H|G1-G6|Section 10\\.2") | not)
         then "Day \($entry.day): Step 3 in completed but no TyDD evaluation marker in scope" else empty end),
        (if ($sc | any(. == 7)) and (($entry.scope // "") | test("Step 7|やり残し|mandatory checklist|cycle-check\\.sh|6 項目|empirical iter") | not)
         then "Day \($entry.day): Step 7 in completed but no mandatory checklist marker in scope" else empty end)
      ]
    )
  | flatten
  | .[]
' "$PENDING" 2>/dev/null | head -3)

if [ -n "$NO_MARKER_DAYS" ]; then
  echo "[16] WARN  Day 103+ で steps_completed の Step 1/3/7 が scope marker で裏付けられない:"
  echo "$NO_MARKER_DAYS" | sed 's/^/    /'
  WARN=1
else
  echo "[16] OK  Day 103+ scope marker 検証 (Step 1/3/7 token 裏付け)"
fi

# ----- Check 18: scope text marker for Step 5/9 (Empirical #12 / Day 119 negative gap fix) -----
# Empirical #12 (Day 119) で Check 16 が cover していない Step 5 (metadata commit) と
# Step 9 (handoff/最終後続) の hidden gap を識別 (Day 117 が triple gap 真陽性、Step 9 は 16/17 entry で marker zero = 94% invisibility)。
# Step 6 は Check 13 が既に owner、本 check では扱わない (責任分担明確化)。
# Day 120 base (Check 18 導入後 baseline、Day 103-119 は legacy 許容、Day 120+ で discipline 適用)。
NO_S59_MARKER=$(jq -r '
  .day_plan
  | map(select(.status == "done"))
  | map(select((.day | tostring | tonumber? // 0) >= 120))
  | map(. as $entry | (.steps_completed // []) as $sc |
      [
        (if ($sc | any(. == 5)) and (($entry.scope // "") | test("change_category[=:]|verifier_history|artifact-manifest|metadata commit|day_plan entry|metadata 更新") | not)
         then "Day \($entry.day): Step 5 in completed but no metadata commit marker in scope" else empty end),
        (if ($sc | any(. == 9)) and (($entry.scope // "") | test("backfill|update-handoff|handoff|commit hash|最終後続|後続作業|backfill-day-commit") | not)
         then "Day \($entry.day): Step 9 in completed but no handoff/backfill marker in scope" else empty end)
      ]
    )
  | flatten
  | .[]
' "$PENDING" 2>/dev/null | head -5)

if [ -n "$NO_S59_MARKER" ]; then
  echo "[18] WARN  Day 120+ で steps_completed の Step 5/9 が scope marker で裏付けられない:"
  echo "$NO_S59_MARKER" | sed 's/^/    /'
  WARN=1
else
  echo "[18] OK  Day 120+ scope marker 検証 (Step 5/9 token 裏付け)"
fi

# ----- Check 19: 本道 (Tooling/CI/Verification) aging warn (Day 123 反省) -----
# Phase 0 当初 scope の Week 5-8 (Tooling 層 / CI / Verification) が pending のまま N day 経過。
# 直近 14 day の day_plan で本道着手 (Tooling/CI/Verify token を scope に含む entry) が無ければ WARN。
# Scope discipline (CLAUDE.md): scope 拡張型 Day を 3 day 以上連続したら本道 1 Day 挿む。
RECENT_MAINSTREAM=$(jq -r '
  .day_plan
  | map(select(.status == "done"))
  | map(select((.day | tostring | tonumber? // 0) >= 110))
  | sort_by(.day | tostring | tonumber? // 0)
  | .[-14:]
  | map(select((.scope // "") | test("agent_verify|VcForSkill|SMT hammer|EnvExtension|lake test|lake lint|GitHub Actions|LeanDojo|Pantograph|再証明|CLEVER|self-benchmark|external benchmark|verification spot check|#print axioms")))
  | length
' "$PENDING" 2>/dev/null)

if [ -z "$RECENT_MAINSTREAM" ] || [ "$RECENT_MAINSTREAM" -eq 0 ]; then
  echo "[19] WARN  直近 14 day で本道 (Tooling/CI/Verification、Phase 0 Week 5-8) 進捗ゼロ"
  echo "    Scope discipline: scope 拡張型 Day を 3 day 以上連続したら本道 1 Day 挿む (CLAUDE.md 反省 rule)"
  WARN=1
else
  echo "[19] OK  直近 14 day で本道 entry $RECENT_MAINSTREAM 件"
fi

# baseline 更新 (EXIT=0/2 の場合のみ、FAIL 時は更新せず既存を保持)
if [ "$EXIT" -eq 0 ]; then
  printf '{"verifier_history_count":%d,"day_plan_count":%d,"last_checked":"%s"}\n' \
    "$current_vh" "$current_dp" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$COUNT_FILE"
fi

# ----- Run trace persistence (Day 140 + Day 141 Empirical #14 修正) -----
# cycle-check 実行を構造的に記録 = subagent の「実行した」自己申告に依存せず、
# log file の存在で証明可能。Day 141 Iter 2: `exit` field を `fail_flag` (raw EXIT) と
# `shell_exit` (final 0/1/2) に分離 (Empirical #14 A finding 対応)。
RUN_LOG_DIR="${REPO_ROOT}/.claude/metrics/cycle-check-runs"
mkdir -p "$RUN_LOG_DIR" 2>/dev/null
TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)
GIT_HEAD=$(cd "$REPO_ROOT" 2>/dev/null && git rev-parse --short HEAD 2>/dev/null || echo "unknown")
RUN_LOG_FILE="$RUN_LOG_DIR/${TIMESTAMP}.log"
# shell_exit を Summary 分岐と同 logic で事前計算
if [ "$EXIT" -ne 0 ]; then
  SHELL_EXIT=1
elif [ "$WARN" -ne 0 ]; then
  SHELL_EXIT=2
else
  SHELL_EXIT=0
fi
{
  printf '{"timestamp":"%s","git_head":"%s","fail_flag":%d,"shell_exit":%d,"warn":%d,"vh_count":%d,"dp_count":%d}\n' \
    "$TIMESTAMP" "$GIT_HEAD" "$EXIT" "$SHELL_EXIT" "$WARN" "$current_vh" "$current_dp"
} > "$RUN_LOG_FILE" 2>/dev/null

# ----- Check 20: 前回 run log の整合性検証 (Day 141 minimal + Day 142 full enforcement) -----
# Empirical #14 C 5 loophole 対応:
#   4-1: 0-byte file (touch 偽造) — Day 141
#   4-2: schema 完全性 (7 field 全存在) — Day 141
#   4-3: git_head が現 HEAD の祖先 (古い log の流用検出) — Day 142
#   4-4: timestamp monotonic (時計改竄 / copy 偽装検出) — Day 142
PREV_LOG=$(ls -t "$RUN_LOG_DIR"/*.log 2>/dev/null | sed -n '2p')
if [ -n "$PREV_LOG" ]; then
  CHK20_OK=true
  # 4-1: 0-byte file (touch 偽造)
  if [ ! -s "$PREV_LOG" ]; then
    echo "[20] WARN  前回 run log empty (touch 偽造の疑い): $(basename "$PREV_LOG")"
    CHK20_OK=false
    WARN=1
  fi
  # 4-2: schema 完全性 (jq で 7 field 全部存在確認)
  if [ "$CHK20_OK" = true ]; then
    for field in timestamp git_head fail_flag shell_exit warn vh_count dp_count; do
      if ! jq -e "has(\"$field\")" "$PREV_LOG" >/dev/null 2>&1; then
        echo "[20] WARN  前回 run log $(basename "$PREV_LOG") に '$field' field 欠損"
        CHK20_OK=false
        WARN=1
        break
      fi
    done
  fi
  # 4-3: git_head が現 HEAD の祖先 commit (古い log の流用 or fake hash 検出)
  if [ "$CHK20_OK" = true ]; then
    PREV_HEAD=$(jq -r '.git_head' "$PREV_LOG")
    if [ "$PREV_HEAD" != "unknown" ] && ! (cd "$REPO_ROOT" && git merge-base --is-ancestor "$PREV_HEAD" HEAD 2>/dev/null); then
      echo "[20] WARN  前回 log git_head '$PREV_HEAD' が現 HEAD の祖先でない (流用 or fake)"
      CHK20_OK=false
      WARN=1
    fi
  fi
  # 4-4: timestamp monotonic (前回 ts < 今回 ts、UTC ISO8601 形式の lexicographic 比較で OK)
  if [ "$CHK20_OK" = true ]; then
    PREV_TS=$(jq -r '.timestamp' "$PREV_LOG")
    if [[ "$PREV_TS" > "$TIMESTAMP" ]]; then
      echo "[20] WARN  前回 log timestamp 逆行: $PREV_TS > $TIMESTAMP (時計改竄 or copy 偽装)"
      CHK20_OK=false
      WARN=1
    fi
  fi
  # 4-5: verifier_history cross-ref (Day 143 完全 enforcement)
  # 最新 verifier_history entry に optional `cycle_check_log_hash` field があれば、
  # 対応 log file の SHA-256 と一致するか確認 (subagent が log を実 read+commit したことを構造証明)
  if [ "$CHK20_OK" = true ]; then
    LATEST_VH_HASH=$(jq -r '.verifier_history[-1].cycle_check_log_hash // empty' "$MANIFEST" 2>/dev/null)
    if [ -n "$LATEST_VH_HASH" ]; then
      ACTUAL_HASH=$(shasum -a 256 "$PREV_LOG" 2>/dev/null | awk '{print $1}')
      if [ "$LATEST_VH_HASH" != "$ACTUAL_HASH" ]; then
        echo "[20] WARN  最新 verifier_history.cycle_check_log_hash が前回 log hash と不一致"
        echo "    expected: $LATEST_VH_HASH"
        echo "    actual:   $ACTUAL_HASH"
        CHK20_OK=false
        WARN=1
      fi
    fi
  fi
  if [ "$CHK20_OK" = true ]; then
    echo "[20] OK  前回 run log 整合性 ($(basename "$PREV_LOG"))"
  fi
else
  echo "[20] OK  前回 run log なし (初回 run)"
fi

# ----- Check 21: 同一 scope marker への N 連敗 detection (PI-2、Day 149) -----
# 直近 14 verifier_history entry で pass_layers.implementation=fail が同一 scope marker に
# 対して 2 回以上で fail-flag。同一 marker = round / scope の先頭 prefix 一致 (Day NNN B / B' / C 等)。
# Day 144 (Axioms) / Day 144,146 (Observable) のような無計画 retry を構造的に検出。
N_RECENT=14
N_FAIL_THRESHOLD=2
RECENT_FAILS=$(jq --argjson n "$N_RECENT" '
  .verifier_history[-$n:]
  | map(select(.pass_layers.implementation == "fail" and .failed_attempt.marker != null))
  | map(.failed_attempt.marker)
  | group_by(.) | map({marker: .[0], count: length})
  | map(select(.count >= 2))
' "$MANIFEST" 2>/dev/null)
if [ -n "$RECENT_FAILS" ] && [ "$RECENT_FAILS" != "[]" ]; then
  N_HIT=$(echo "$RECENT_FAILS" | jq 'length')
  echo "[21] NG  同一 scope marker N 連敗 ($N_HIT marker、threshold=$N_FAIL_THRESHOLD):"
  echo "$RECENT_FAILS" | jq -r '.[] | "    marker=\(.marker) fail_count=\(.count) — 3 回目 retry 前に user 戦略相談"'
  EXIT=1
else
  echo "[21] OK  同一 scope marker N 連敗 なし (直近 $N_RECENT entry)"
fi

# ----- Check 22: pending_items decision_deadline 超過 detection (PI-3、Day 149) -----
# pending_items 各 entry の decision_deadline (Day#) field が現 Day# を超過、かつ status が
# pending/deferred の場合 ERROR (promote/retire/escalate 3 択を強制)。
# 永久滞留 catalog 防止。
CURRENT_DAY=$(jq -r '[.day_plan[].day | select(type == "number")] | max // 0' "$PENDING")
OVERDUE=$(jq -r --argjson cd "$CURRENT_DAY" '
  [.pending_items[]
   | select(.decision_deadline != null
            and .decision_deadline < $cd
            and (.status == "pending" or .status == "deferred"))
   | {topic: .topic, deadline: .decision_deadline, status: .status, id: (.id // "no-id")}]
' "$PENDING" 2>/dev/null)
if [ -n "$OVERDUE" ] && [ "$OVERDUE" != "[]" ]; then
  N_OVERDUE=$(echo "$OVERDUE" | jq 'length')
  echo "[22] NG  decision_deadline 超過 $N_OVERDUE 件 (current Day=$CURRENT_DAY、promote/retire/escalate 必須):"
  echo "$OVERDUE" | jq -r '.[] | "    [\(.id)] \(.topic) — deadline=Day\(.deadline) status=\(.status)"'
  EXIT=1
else
  echo "[22] OK  decision_deadline 超過 なし (current Day=$CURRENT_DAY)"
fi

# ----- 結果 -----
echo ""
echo "=== Summary ==="
if [ "$EXIT" -ne 0 ]; then
  echo "FAIL: addressable issues 検出、commit 前に対処すること"
  echo "Run log: $RUN_LOG_FILE"
  exit 1
elif [ "$WARN" -ne 0 ]; then
  echo "WARNING: informational items あり、確認推奨 (block せず)"
  echo "Run log: $RUN_LOG_FILE"
  exit 2
else
  echo "ALL PASS"
  echo "Run log: $RUN_LOG_FILE"
  exit 0
fi
