#!/usr/bin/env bash
# Step 6: 退役処理 (deterministic 成分)
# TaskAutomationClass: deterministic → structural enforcement
# 根拠: deterministic_must_be_structural (TaskClassification.lean)
#
# judgmental 成分（陳腐化基準の適用、退役の最終判断）は LLM が担当。
# このスクリプトは deterministic 成分（候補検出、ファイル操作）のみを実行する。
set -euo pipefail

DEFAULT_MEMORY_DIR="$HOME/.claude/projects/-Users-nirarin-work-agent-manifesto/memory"
DEFAULT_STALE_DAYS=180  # 6ヶ月

usage() {
  cat <<'USAGE'
Usage:
  retirement.sh candidates [memory-dir] [stale-days]
  retirement.sh remove <file-path>

Actions:
  candidates  - List memory files not modified in <stale-days> days (default: 180)
  remove      - Remove a memory file and its MEMORY.md entry

Examples:
  retirement.sh candidates
  retirement.sh candidates .claude/projects/.../memory 90
  retirement.sh remove .claude/projects/.../memory/old_entry.md
USAGE
  exit 1
}

[[ $# -lt 1 ]] && usage

ACTION="$1"

case "$ACTION" in
  candidates)
    MEMORY_DIR="${2:-$DEFAULT_MEMORY_DIR}"
    STALE_DAYS="${3:-$DEFAULT_STALE_DAYS}"

    if [[ ! -d "$MEMORY_DIR" ]]; then
      echo "ERROR: Memory directory not found: $MEMORY_DIR"
      exit 1
    fi

    echo "=== 退役候補（${STALE_DAYS}日以上未更新） ==="
    FOUND=0
    for f in "$MEMORY_DIR"/*.md; do
      [[ "$(basename "$f")" == "MEMORY.md" ]] && continue
      [[ ! -f "$f" ]] && continue

      # macOS stat
      if stat -f %m "$f" > /dev/null 2>&1; then
        MOD_EPOCH=$(stat -f %m "$f")
      else
        MOD_EPOCH=$(stat -c %Y "$f")
      fi

      NOW_EPOCH=$(date +%s)
      AGE_DAYS=$(( (NOW_EPOCH - MOD_EPOCH) / 86400 ))

      if [[ "$AGE_DAYS" -ge "$STALE_DAYS" ]]; then
        echo "  [${AGE_DAYS}d] $(basename "$f")"
        FOUND=$((FOUND + 1))
      fi
    done

    if [[ "$FOUND" -eq 0 ]]; then
      echo "  (退役候補なし)"
    else
      echo ""
      echo "Found $FOUND candidate(s). LLM reviews each for retirement decision (judgmental)."
    fi
    ;;
  remove)
    [[ $# -lt 2 ]] && usage
    FILE_PATH="$2"

    if [[ ! -f "$FILE_PATH" ]]; then
      echo "ERROR: File not found: $FILE_PATH"
      exit 1
    fi

    BASENAME=$(basename "$FILE_PATH")
    DIR=$(dirname "$FILE_PATH")
    MEMORY_INDEX="${DIR}/MEMORY.md"

    # ファイル削除
    rm "$FILE_PATH"
    echo "Removed: $FILE_PATH"

    # MEMORY.md からエントリ削除
    if [[ -f "$MEMORY_INDEX" ]]; then
      # BASENAME を含む行を削除
      grep -v "$BASENAME" "$MEMORY_INDEX" > "${MEMORY_INDEX}.tmp" || true
      mv "${MEMORY_INDEX}.tmp" "$MEMORY_INDEX"
      echo "Removed entry from MEMORY.md"
    fi
    ;;
  *)
    usage
    ;;
esac
