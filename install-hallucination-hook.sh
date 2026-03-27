#!/usr/bin/env bash
# hook-hallucination-detection 設置スクリプト
#
# 実行方法:
#   bash install-hallucination-hook.sh
#
# このスクリプトは以下を行う:
# 1. .claude/hooks/hallucination-check.sh をコピー
# 2. .claude/settings.json に PreToolUse hook を登録（WARN モード）
# 3. deferred-status.json を更新

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
# worktree から実行する場合、メインリポジトリの位置を推定
if echo "$PROJECT_ROOT" | grep -q '.claude/worktrees'; then
  MAIN_ROOT="$(echo "$PROJECT_ROOT" | sed 's|/.claude/worktrees/.*||')"
else
  MAIN_ROOT="$PROJECT_ROOT"
fi

echo "=== hook-hallucination-detection 設置 ==="
echo "メインリポジトリ: $MAIN_ROOT"
echo ""

# Step 1: Hook スクリプトをコピー
HOOK_SRC="$PROJECT_ROOT/.claude/hooks/hallucination-check.sh"
HOOK_DST="$MAIN_ROOT/.claude/hooks/hallucination-check.sh"

if [ ! -f "$HOOK_SRC" ]; then
  echo "ERROR: ソースファイルが見つかりません: $HOOK_SRC" >&2
  exit 1
fi

cp "$HOOK_SRC" "$HOOK_DST"
chmod +x "$HOOK_DST"
echo "1. Hook スクリプトをコピーしました: $HOOK_DST"

# Step 2: settings.json に登録
SETTINGS="$MAIN_ROOT/.claude/settings.json"
if [ ! -f "$SETTINGS" ]; then
  echo "ERROR: settings.json が見つかりません: $SETTINGS" >&2
  exit 1
fi

# 既に登録されているか確認
if grep -q 'hallucination-check' "$SETTINGS"; then
  echo "2. settings.json に既に登録済み（スキップ）"
else
  # PreToolUse の Edit/Write matcher に追加
  # jq で安全に追加
  TEMP_SETTINGS=$(mktemp)
  jq '.hooks.PreToolUse += [{
    "matcher": "Edit",
    "hooks": ["bash .claude/hooks/hallucination-check.sh"]
  }, {
    "matcher": "Write",
    "hooks": ["bash .claude/hooks/hallucination-check.sh"]
  }]' "$SETTINGS" > "$TEMP_SETTINGS"
  mv "$TEMP_SETTINGS" "$SETTINGS"
  echo "2. settings.json に PreToolUse hook を登録しました（Edit, Write matcher）"
fi

# Step 3: deferred-status.json を更新
DEFERRED="$MAIN_ROOT/.claude/metrics/deferred-status.json"
if [ -f "$DEFERRED" ]; then
  TEMP_DEFERRED=$(mktemp)
  jq '.items["hook-hallucination-detection"].status = "resolved" |
      .items["hook-hallucination-detection"].resolved_in_run = 63 |
      .items["hook-hallucination-detection"].note = "WARN mode で導入。G1 PASS (13/13, 0.051s), G2 FAIL (検出率3-6%), 全体 CONDITIONAL。#70 参照。" |
      .last_updated_run = 63' "$DEFERRED" > "$TEMP_DEFERRED"
  mv "$TEMP_DEFERRED" "$DEFERRED"
  echo "3. deferred-status.json を更新しました（hook-hallucination-detection → resolved）"
fi

echo ""
echo "=== 設置完了 ==="
echo ""
echo "確認手順:"
echo "  1. git diff .claude/settings.json で登録内容を確認"
echo "  2. echo '{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"/tmp/t.md\",\"new_string\":\"99 axioms\"}}' | bash .claude/hooks/hallucination-check.sh"
echo "  3. WARN メッセージが stderr に出力されることを確認"
echo ""
echo "BLOCK モードへの昇格:"
echo "  環境変数 HALLUCINATION_HOOK_MODE=BLOCK を設定"
