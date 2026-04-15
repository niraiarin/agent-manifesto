#!/bin/bash
# brownfield-convergence.sh — Phase 1 収束判定スクリプト
# 使い方:
#   bash convergence.sh add <observations-dir> <iteration> <unit> <decisions_found>
#   bash convergence.sh add-detailed <observations-dir> <iteration> <unit> <pd-details.json> [--mode philosophy] [--validation]
#   bash convergence.sh check <observations-dir> [--mode philosophy]
#   bash convergence.sh status <observations-dir> [--mode philosophy]
#
# observations-dir に JSON ファイルを蓄積し、収束を判定する。
# 収束条件: 2 回連続で増分率 < 0.03 (capture-recapture 推定で 95%+ coverage に対応)
# 根拠: #525 — ECC/ClaudeCodeCLI の capture-recapture 分析で確立
#
# add-detailed: PD 詳細 JSON ファイルを受け取り、iteration ファイルに埋め込む (#457)
#   pd-details.json 形式: [{"id":"PD-001","content":"...","source":"code_analysis","confidence":"high"}]
#
# --mode philosophy: 設計思想・原則・トレードオフ・活用パターンを抽出する観察モード (#477)
#   philosophy モードは独立した累計カウンタと iteration ファイルを使用する。
#   同じファイルに異なる「問い」を向けることで、異なる層の情報を抽出する。

set -euo pipefail

COMMAND="${1:-help}"
OBS_DIR="${2:-}"

usage() {
  echo "Usage:"
  echo "  $0 add <observations-dir> <iteration> <unit> <decisions_found>"
  echo "  $0 add-detailed <observations-dir> <iteration> <unit> <pd-details.json> [--mode philosophy]"
  echo "  $0 check <observations-dir> [--mode philosophy]"
  echo "  $0 status <observations-dir> [--mode philosophy]"
  exit 1
}

# モード判定: 引数から --mode を探す
# 有効なモード: normal, philosophy
parse_mode() {
  local mode="normal"
  local next_is_mode=false
  for arg in "$@"; do
    if [ "$arg" = "--mode" ]; then
      next_is_mode=true
    elif [ "$next_is_mode" = true ]; then
      mode="$arg"
      next_is_mode=false
    fi
  done
  if [ "$next_is_mode" = true ]; then
    echo "ERROR: --mode requires a value (normal or philosophy)" >&2
    exit 1
  fi
  if [ "$mode" != "normal" ] && [ "$mode" != "philosophy" ]; then
    echo "ERROR: unknown mode '$mode'. Valid modes: normal, philosophy" >&2
    exit 1
  fi
  echo "$mode"
}

# モード別のファイルプレフィックス
mode_prefix() {
  local mode="$1"
  if [ "$mode" = "philosophy" ]; then
    echo "philosophy-"
  else
    echo ""
  fi
}

# モード別の累計カウンタファイル
cumulative_file() {
  local dir="$1" mode="$2"
  if [ "$mode" = "philosophy" ]; then
    echo "$dir/cumulative-philosophy.txt"
  else
    echo "$dir/cumulative.txt"
  fi
}

add_observation() {
  local dir="$1" iteration="$2" unit="$3" found="$4"

  mkdir -p "$dir"

  # 累計を計算
  local cumulative=0
  if [ -f "$dir/cumulative.txt" ]; then
    cumulative=$(cat "$dir/cumulative.txt")
  fi
  cumulative=$((cumulative + found))

  # 増分率を計算
  local rate="1.00"
  if [ "$cumulative" -gt 0 ]; then
    rate=$(echo "scale=4; $found / $cumulative" | bc)
  fi

  # 記録
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  cat > "$dir/iteration-${iteration}.json" <<ENDJSON
{
  "iteration": ${iteration},
  "unit": "${unit}",
  "timestamp": "${timestamp}",
  "decisions_found": ${found},
  "cumulative_total": ${cumulative},
  "incremental_rate": ${rate}
}
ENDJSON

  echo "$cumulative" > "$dir/cumulative.txt"
  echo "Iteration ${iteration}: found=${found}, cumulative=${cumulative}, rate=${rate}"
}

add_detailed_observation() {
  local dir="$1" iteration="$2" unit="$3" pd_file="$4"
  local mode
  mode=$(parse_mode "$@")

  if [ ! -f "$pd_file" ]; then
    echo "ERROR: PD details file not found: $pd_file"
    exit 1
  fi

  # PD 詳細 JSON を検証 (配列であること)
  if ! jq -e 'type == "array"' "$pd_file" > /dev/null 2>&1; then
    echo "ERROR: PD details file must be a JSON array: $pd_file"
    exit 1
  fi

  local found
  found=$(jq 'length' "$pd_file")

  mkdir -p "$dir"

  # モード別の累計カウンタ
  local cum_file
  cum_file=$(cumulative_file "$dir" "$mode")
  local prefix
  prefix=$(mode_prefix "$mode")

  # 累計を計算
  local cumulative=0
  if [ -f "$cum_file" ]; then
    cumulative=$(cat "$cum_file")
  fi
  cumulative=$((cumulative + found))

  # 増分率を計算
  local rate="1.00"
  if [ "$cumulative" -gt 0 ]; then
    rate=$(echo "scale=4; $found / $cumulative" | bc)
  fi

  # 記録 (PD 詳細を含む)
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  local iter_file="$dir/${prefix}iteration-${iteration}.json"

  # --validation フラグの検出
  local is_validation="false"
  for arg in "$@"; do
    if [ "$arg" = "--validation" ]; then
      is_validation="true"
      break
    fi
  done

  if [ "$mode" = "normal" ]; then
    jq -n \
      --argjson iteration "$iteration" \
      --arg unit "$unit" \
      --arg timestamp "$timestamp" \
      --argjson pds "$(cat "$pd_file")" \
      --argjson found "$found" \
      --argjson cumulative "$cumulative" \
      --arg rate "$rate" \
      --argjson validation "$is_validation" \
      '{
        iteration: $iteration,
        unit: $unit,
        timestamp: $timestamp,
        platform_decisions: $pds,
        decisions_found: $found,
        cumulative_total: $cumulative,
        incremental_rate: ($rate | tonumber),
        validation: $validation
      }' > "$iter_file"
  else
    jq -n \
      --argjson iteration "$iteration" \
      --arg unit "$unit" \
      --arg timestamp "$timestamp" \
      --arg mode "$mode" \
      --argjson pds "$(cat "$pd_file")" \
      --argjson found "$found" \
      --argjson cumulative "$cumulative" \
      --arg rate "$rate" \
      '{
        iteration: $iteration,
        unit: $unit,
        timestamp: $timestamp,
        mode: $mode,
        platform_decisions: $pds,
        decisions_found: $found,
        cumulative_total: $cumulative,
        incremental_rate: ($rate | tonumber)
      }' > "$iter_file"
  fi

  echo "$cumulative" > "$cum_file"
  echo "Iteration ${iteration} [${mode}]: found=${found}, cumulative=${cumulative}, rate=${rate} (detailed)"
}

check_convergence() {
  local dir="$1"
  local mode
  mode=$(parse_mode "$@")
  local prefix
  prefix=$(mode_prefix "$mode")

  if [ ! -d "$dir" ]; then
    echo "No observations directory: $dir"
    exit 1
  fi

  # 最新 2 件の iteration を取得 (2 consecutive check)
  local files
  files=$(ls "$dir"/${prefix}iteration-*.json 2>/dev/null | sed 's/.*iteration-\([0-9]*\)\.json/\1 &/' | sort -n -k1 | sed 's/^[0-9]* //')

  if [ -z "$files" ]; then
    echo "UNCONVERGED [${mode}]: No observations recorded"
    exit 1
  fi

  local latest
  latest=$(echo "$files" | tail -1)
  local rate
  rate=$(jq -r '.incremental_rate' "$latest")
  local iteration
  iteration=$(jq -r '.iteration' "$latest")

  local file_count
  file_count=$(echo "$files" | wc -l | tr -d ' ')

  # 収束条件: 2 回連続で rate < 0.03
  # 根拠: capture-recapture 推定で 95%+ coverage (#525)
  local threshold="0.03"

  if [ "$file_count" -lt 2 ]; then
    echo "UNCONVERGED [${mode}]: iteration=${iteration}, rate=${rate} (need 2+ iterations for 2-consecutive check, threshold: ${threshold})"
    exit 1
  fi

  local prev_latest
  prev_latest=$(echo "$files" | tail -2 | head -1)
  local prev_rate
  prev_rate=$(jq -r '.incremental_rate' "$prev_latest")
  local prev_iteration
  prev_iteration=$(jq -r '.iteration' "$prev_latest")

  # bc: 1 = condition true, 0 = false
  local curr_below prev_below
  curr_below=$(echo "$rate < $threshold" | bc -l)
  prev_below=$(echo "$prev_rate < $threshold" | bc -l)

  # validation iteration の有無を確認
  local latest_is_validation
  latest_is_validation=$(jq -r '.validation // false' "$latest")

  if [ "$curr_below" = "1" ] && [ "$prev_below" = "1" ]; then
    if [ "$latest_is_validation" = "true" ]; then
      echo "CONVERGED [${mode}]: validation PASS — iter ${prev_iteration} (rate=${prev_rate}) + validation iter ${iteration} (rate=${rate}) < ${threshold}"
      exit 0
    else
      echo "CONVERGED_PENDING_VALIDATION [${mode}]: 2 consecutive < ${threshold} — iter ${prev_iteration} (rate=${prev_rate}) + iter ${iteration} (rate=${rate}). Run a validation iteration (--validation) with no scope restriction to confirm."
      exit 2
    fi
  elif [ "$curr_below" = "1" ]; then
    echo "UNCONVERGED [${mode}]: iteration=${iteration}, rate=${rate} < ${threshold} but prev iter ${prev_iteration} rate=${prev_rate} >= ${threshold} (need 2 consecutive)"
    exit 1
  else
    echo "UNCONVERGED [${mode}]: iteration=${iteration}, rate=${rate} (threshold: ${threshold}, need 2 consecutive)"
    exit 1
  fi
}

show_status() {
  local dir="$1"
  local mode
  mode=$(parse_mode "$@")
  local prefix
  prefix=$(mode_prefix "$mode")

  if [ ! -d "$dir" ]; then
    echo "No observations directory: $dir"
    exit 1
  fi

  echo "=== Convergence Status [${mode}] ==="
  for f in $(ls "$dir"/${prefix}iteration-*.json 2>/dev/null | sed 's/.*iteration-\([0-9]*\)\.json/\1 &/' | sort -n -k1 | sed 's/^[0-9]* //'); do
    local iter found cum rate
    iter=$(jq -r '.iteration' "$f")
    found=$(jq -r '.decisions_found' "$f")
    cum=$(jq -r '.cumulative_total' "$f")
    rate=$(jq -r '.incremental_rate' "$f")
    printf "  Iteration %2d: +%3d (total: %4d) rate: %s\n" "$iter" "$found" "$cum" "$rate"
  done

  check_convergence "$dir" "$@" 2>/dev/null || true
}

case "$COMMAND" in
  add)
    [ $# -lt 5 ] && usage
    add_observation "$2" "$3" "$4" "$5"
    ;;
  add-detailed)
    [ $# -lt 5 ] && usage
    add_detailed_observation "$2" "$3" "$4" "$5" "${@:6}"
    ;;
  check)
    [ -z "$OBS_DIR" ] && usage
    check_convergence "$OBS_DIR" "${@:3}"
    ;;
  status)
    [ -z "$OBS_DIR" ] && usage
    show_status "$OBS_DIR" "${@:3}"
    ;;
  *)
    usage
    ;;
esac
