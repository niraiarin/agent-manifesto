#!/usr/bin/env bash
# rotate-decision-logs.sh — gzip decision log files older than N days.
#
# The live file (today's UTC date) is never touched. Files from the prior
# RETAIN_RAW_DAYS are kept uncompressed for easy jq analysis. Older files
# are gzip'd in place. Already-gzip'd files are left alone.
#
# Usage:
#   bash scripts/rotate-decision-logs.sh                 # default: 7 days retention
#   RETAIN_RAW_DAYS=3 bash scripts/rotate-decision-logs.sh
#   DECISION_LOG_DIR=/tmp/demo bash scripts/rotate-decision-logs.sh
#
# Idempotent. Run via cron / launchd on a daily schedule.

set -eu

RETAIN_RAW_DAYS="${RETAIN_RAW_DAYS:-7}"
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
LOG_DIR="${DECISION_LOG_DIR:-$REPO_ROOT/docs/research/routellm-phase3/logs}"

if [ ! -d "$LOG_DIR" ]; then
  echo "[rotate] no log dir at $LOG_DIR; nothing to do" >&2
  exit 0
fi

gzipped=0
untouched=0

# macOS-compatible: mtime measured in days via -mtime
# -mtime +N means "modified more than N days ago"
while IFS= read -r file; do
  [ -z "$file" ] && continue
  if [ ! -f "$file" ]; then
    continue
  fi
  if gzip -q "$file"; then
    gzipped=$((gzipped + 1))
    echo "[rotate] gzipped $file"
  else
    echo "[rotate] gzip failed for $file" >&2
  fi
done < <(find "$LOG_DIR" -type f -name 'decisions-*.jsonl' -mtime "+${RETAIN_RAW_DAYS}" 2>/dev/null)

while IFS= read -r file; do
  [ -z "$file" ] && continue
  untouched=$((untouched + 1))
done < <(find "$LOG_DIR" -type f -name 'decisions-*.jsonl' -mtime "-${RETAIN_RAW_DAYS}" 2>/dev/null)

echo "[rotate] retain_raw_days=$RETAIN_RAW_DAYS gzipped=$gzipped live_raw=$untouched log_dir=$LOG_DIR"
