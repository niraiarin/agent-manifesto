#!/bin/bash
# brownfield-convergence.sh — Phase 1 収束判定スクリプト
# 使い方:
#   bash convergence.sh check <observations-dir>
#   bash convergence.sh add <observations-dir> <iteration> <unit> <decisions_found>
#
# observations-dir に JSON ファイルを蓄積し、収束を判定する。
# 収束条件: 増分率 (decisions_found / cumulative_total) < 0.05

set -euo pipefail

COMMAND="${1:-help}"
OBS_DIR="${2:-}"

usage() {
  echo "Usage:"
  echo "  $0 add <observations-dir> <iteration> <unit> <decisions_found>"
  echo "  $0 check <observations-dir>"
  echo "  $0 status <observations-dir>"
  exit 1
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

check_convergence() {
  local dir="$1"

  if [ ! -d "$dir" ]; then
    echo "No observations directory: $dir"
    exit 1
  fi

  # 最新の iteration を取得
  local latest
  latest=$(ls "$dir"/iteration-*.json 2>/dev/null | sort -t- -k2 -n | tail -1)

  if [ -z "$latest" ]; then
    echo "UNCONVERGED: No observations recorded"
    exit 1
  fi

  local rate
  rate=$(jq -r '.incremental_rate' "$latest")
  local iteration
  iteration=$(jq -r '.iteration' "$latest")

  # bc: 1 = condition true, 0 = false
  local converged
  converged=$(echo "$rate < 0.05" | bc -l)
  if [ "$converged" = "1" ]; then
    echo "CONVERGED: iteration=${iteration}, rate=${rate} (threshold: 0.05)"
    exit 0
  else
    echo "UNCONVERGED: iteration=${iteration}, rate=${rate} (threshold: 0.05)"
    exit 1
  fi
}

show_status() {
  local dir="$1"

  if [ ! -d "$dir" ]; then
    echo "No observations directory: $dir"
    exit 1
  fi

  echo "=== Convergence Status ==="
  for f in $(ls "$dir"/iteration-*.json 2>/dev/null | sort -t- -k2 -n); do
    local iter found cum rate
    iter=$(jq -r '.iteration' "$f")
    found=$(jq -r '.decisions_found' "$f")
    cum=$(jq -r '.cumulative_total' "$f")
    rate=$(jq -r '.incremental_rate' "$f")
    printf "  Iteration %2d: +%3d (total: %4d) rate: %s\n" "$iter" "$found" "$cum" "$rate"
  done

  check_convergence "$dir" 2>/dev/null || true
}

case "$COMMAND" in
  add)
    [ $# -lt 5 ] && usage
    add_observation "$2" "$3" "$4" "$5"
    ;;
  check)
    [ -z "$OBS_DIR" ] && usage
    check_convergence "$OBS_DIR"
    ;;
  status)
    [ -z "$OBS_DIR" ] && usage
    show_status "$OBS_DIR"
    ;;
  *)
    usage
    ;;
esac
