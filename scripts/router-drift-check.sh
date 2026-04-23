#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -z "${MANIFESTO_ROOT:-}" ]; then
  MANIFESTO_ROOT="$(
    cd "$SCRIPT_DIR/.." &&
      bash .claude/skills/shared/resolve-manifesto-root.sh
  )"
fi

CLASSIFIER_DIR="$MANIFESTO_ROOT/docs/research/routellm-phase3/classifier"
ANALYSIS_DIR="$MANIFESTO_ROOT/docs/research/routellm-phase3/analysis"
LOG_DIR="$MANIFESTO_ROOT/docs/research/routellm-phase3/logs"
RUN_DATE="$(date +%Y%m%d)"
REPORT_PATH="$ANALYSIS_DIR/drift-report-$RUN_DATE.json"
LOG_PATH="$LOG_DIR/drift-check-$RUN_DATE.log"

mkdir -p "$ANALYSIS_DIR" "$LOG_DIR"

if command -v uv >/dev/null 2>&1; then
  UV_BIN="$(command -v uv)"
elif [ -x "$HOME/.local/bin/uv" ]; then
  UV_BIN="$HOME/.local/bin/uv"
else
  echo "[drift-check] uv not found on PATH or at $HOME/.local/bin/uv" >>"$LOG_PATH"
  exit 1
fi

run_check() {
  cd "$CLASSIFIER_DIR"
  echo "[drift-check] started $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if ! "$UV_BIN" run python3 monitor_drift.py \
    --reference-days 7 \
    --output "$REPORT_PATH"; then
    echo "[drift-check] monitor_drift.py failed"
    return 1
  fi

  set +e
  python3 - "$REPORT_PATH" <<'PY'
import json
import sys
from pathlib import Path

report_path = Path(sys.argv[1])
try:
    with report_path.open() as f:
        report = json.load(f)
except (OSError, json.JSONDecodeError) as exc:
    print(f"[drift-check] failed to read report: {exc}", file=sys.stderr)
    sys.exit(1)
sys.exit(0 if report.get("drift", {}).get("alert") is True else 2)
PY
  ALERT_STATUS=$?
  set -e

  case "$ALERT_STATUS" in
    0)
      echo "[drift-check] alert=true; dispatching GitHub issue"
      if ! "$UV_BIN" run python3 alert_dispatcher.py --report "$REPORT_PATH"; then
        echo "[drift-check] alert_dispatcher.py failed"
        return 1
      fi
      return 2
      ;;
    2)
      echo "[drift-check] alert=false"
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

set +e
run_check >>"$LOG_PATH" 2>&1
STATUS=$?
set -e

case "$STATUS" in
  0)
    exit 0
    ;;
  2)
    exit 2
    ;;
  *)
    echo "[drift-check] error status=$STATUS" >>"$LOG_PATH"
    exit 1
    ;;
esac
