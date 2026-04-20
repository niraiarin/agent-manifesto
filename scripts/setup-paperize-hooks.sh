#!/usr/bin/env bash
# setup-paperize-hooks.sh — /paperize warn-mode hooks セットアップ（人間が実行）
#
# L1 safety: LLM は .claude/hooks/ と .claude/settings.json を直接書けない
# (l1-file-guard.sh 強制)。人間が本スクリプトを実行することで hook を設置する。
#
# Installs:
#   1. .claude/hooks/paperize-jsonl-warn.sh  (SessionStart)
#      p2-verified.jsonl に N 件 (>0) 未処理エントリがあれば stderr に警告
#   2. .claude/hooks/paperize-stop-reminder.sh  (Stop)
#      セッション終了時に jsonl エントリがあれば /paperize 起動を促す
#
# Idempotent: 既に登録済みならスキップ。
#
# 使用方法:
#   bash scripts/setup-paperize-hooks.sh
#
# @traces P3, T2, D1

set -euo pipefail

BASE="$(git rev-parse --show-toplevel)"
HOOK_DIR="$BASE/.claude/hooks"
SETTINGS="$BASE/.claude/settings.json"
WARN_HOOK="$HOOK_DIR/paperize-jsonl-warn.sh"
STOP_HOOK="$HOOK_DIR/paperize-stop-reminder.sh"

mkdir -p "$HOOK_DIR"

# ---------- Hook file 1: SessionStart warn ----------
cat > "$WARN_HOOK" <<'HOOK_EOF'
#!/usr/bin/env bash
# paperize-jsonl-warn.sh — SessionStart hook.
# p2-verified.jsonl に未処理エントリがあれば警告する。
# @traces P3, D1

set -euo pipefail
BASE="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
JSONL="$BASE/.claude/metrics/p2-verified.jsonl"
[ -f "$JSONL" ] || exit 0
N=$(grep -c '' "$JSONL" 2>/dev/null || echo 0)
[ "$N" -gt 0 ] 2>/dev/null || exit 0

PAPERIZE_MODE=$(yq -r '.enforcement.mode // "warn"' "$BASE/paperize.yaml" 2>/dev/null || echo "warn")
case "$PAPERIZE_MODE" in
  skip) exit 0 ;;
esac

echo "[paperize] p2-verified.jsonl に $N 件の未処理検証トークンがあります" >&2
echo "[paperize] /paperize で論文化 → todos.md 保存 → jsonl flush を実行できます" >&2
HOOK_EOF
chmod +x "$WARN_HOOK"

# ---------- Hook file 2: Stop reminder ----------
cat > "$STOP_HOOK" <<'HOOK_EOF'
#!/usr/bin/env bash
# paperize-stop-reminder.sh — Stop hook.
# セッション終了時に jsonl エントリがあれば /paperize 起動を促す。
# @traces P3, D1

set -euo pipefail
BASE="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
JSONL="$BASE/.claude/metrics/p2-verified.jsonl"
[ -f "$JSONL" ] || exit 0
N=$(grep -c '' "$JSONL" 2>/dev/null || echo 0)
[ "$N" -gt 0 ] 2>/dev/null || exit 0

PAPERIZE_MODE=$(yq -r '.enforcement.mode // "warn"' "$BASE/paperize.yaml" 2>/dev/null || echo "warn")
case "$PAPERIZE_MODE" in
  skip) exit 0 ;;
esac

echo "[paperize] セッション終了: p2-verified.jsonl に $N 件の検証トークンが蓄積中" >&2
echo "[paperize] 次セッション開始前に /paperize 実行を推奨" >&2
HOOK_EOF
chmod +x "$STOP_HOOK"

echo "[setup] installed: $WARN_HOOK"
echo "[setup] installed: $STOP_HOOK"

# ---------- Register in settings.json ----------
if ! command -v jq >/dev/null 2>&1; then
  echo "[setup] ERROR: jq required for settings.json edit" >&2; exit 2
fi

# idempotent check
ALREADY_SS=$(jq '[.hooks.SessionStart[0].hooks[] | .command] | map(select(contains("paperize-jsonl-warn"))) | length' "$SETTINGS")
ALREADY_STOP=$(jq '[.hooks.Stop // [] | .[0].hooks[]? | .command] | map(select(contains("paperize-stop-reminder"))) | length' "$SETTINGS" 2>/dev/null || echo 0)

NEEDS_UPDATE=false
if [ "$ALREADY_SS" = "0" ]; then NEEDS_UPDATE=true; fi
if [ "$ALREADY_STOP" = "0" ]; then NEEDS_UPDATE=true; fi

if [ "$NEEDS_UPDATE" = "false" ]; then
  echo "[setup] hooks already registered in settings.json (idempotent skip)"
  exit 0
fi

TMP=$(mktemp)
jq '
  .hooks.SessionStart[0].hooks |= (
    if any(.command | contains("paperize-jsonl-warn")) then .
    else . + [{"type":"command","command":"bash $CLAUDE_PROJECT_DIR/.claude/hooks/paperize-jsonl-warn.sh"}]
    end
  )
  | .hooks.Stop = (
    if (.hooks.Stop // null) == null then
      [{"matcher":"","hooks":[{"type":"command","command":"bash $CLAUDE_PROJECT_DIR/.claude/hooks/paperize-stop-reminder.sh"}]}]
    elif any(.hooks.Stop[0].hooks[]?; .command | contains("paperize-stop-reminder")) then .hooks.Stop
    else
      (.hooks.Stop[0].hooks += [{"type":"command","command":"bash $CLAUDE_PROJECT_DIR/.claude/hooks/paperize-stop-reminder.sh"}] | .hooks.Stop)
    end
  )
' "$SETTINGS" > "$TMP"

# sanity: output must parse
jq empty "$TMP" || { echo "[setup] ERROR: jq produced invalid JSON"; rm -f "$TMP"; exit 3; }

mv "$TMP" "$SETTINGS"
echo "[setup] registered hooks in $SETTINGS"
echo "[setup] done. Next: commit .claude/settings.json と 2 hook files (compatible change)."
