#!/usr/bin/env bash
# setup-traces-hook.sh — @traces ↔ refs 整合性 hook のセットアップスクリプト
# 人間が実行する: bash scripts/setup-traces-hook.sh
# Hook は .claude/hooks/ に設置され、settings.json への登録が必要
set -euo pipefail

BASE="$(git rev-parse --show-toplevel)"
HOOK_DIR="$BASE/.claude/hooks"
HOOK_FILE="$HOOK_DIR/p4-traces-integrity-check.sh"

cat > "$HOOK_FILE" << 'HOOKEOF'
#!/usr/bin/env bash
# p4-traces-integrity-check.sh — @traces ↔ artifact-manifest.json refs 整合性チェック
# PreToolUse: Edit/Write で traceable artifact を変更する際に発動
# D1 (構造的強制) + P4 (可観測性)
# @traces P4, D1, D13

set -euo pipefail

TOOL_INPUT="${CLAUDE_TOOL_INPUT:-}"
FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty' 2>/dev/null || true)

# ファイルパスがなければスキップ
[ -z "$FILE_PATH" ] && exit 0

BASE="$(git rev-parse --show-toplevel 2>/dev/null || echo "")"
[ -z "$BASE" ] && exit 0

MANIFEST="$BASE/artifact-manifest.json"
[ -f "$MANIFEST" ] || exit 0

# ファイルパスを相対パスに変換
REL_PATH="${FILE_PATH#$BASE/}"

# artifact-manifest.json で path が一致するエントリを検索
ENTRY=$(jq -c --arg p "$REL_PATH" '.artifacts[] | select(._comment == null) | select(.path == $p)' "$MANIFEST" 2>/dev/null || true)
[ -z "$ENTRY" ] && exit 0

# traceable type チェック (skill, hook, agent, rule のみ)
TYPE=$(echo "$ENTRY" | jq -r '.type')
case "$TYPE" in
  skill|hook|agent|rule) ;;
  *) exit 0 ;;
esac

ID=$(echo "$ENTRY" | jq -r '.id')
REFS=$(echo "$ENTRY" | jq -r '.refs[]' 2>/dev/null | sort -u)

# ファイルから @traces を抽出
TRACES=""
if [ -f "$FILE_PATH" ]; then
  TRACES=$(grep -h '^<!-- @traces\|^# @traces' "$FILE_PATH" 2>/dev/null \
    | sed 's/.*@traces[[:space:]]*//' \
    | sed 's/[[:space:]]*-->.*//' \
    | tr ',' '\n' \
    | sed 's/^[[:space:]]*//' \
    | sed 's/[[:space:]]*$//' \
    | tr '[:lower:]' '[:upper:]' \
    | grep '^[TEPLVD][0-9]\{1,2\}$' \
    | sort -u || true)
fi

# @traces がない場合（新規ファイルで Edit 初回など）
if [ -z "$TRACES" ]; then
  echo "[p4-traces-integrity] WARNING: $ID に @traces がありません。refs: $(echo $REFS | tr '\n' ', ')" >&2
  exit 0
fi

# refs との一致チェック
REFS_SORTED=$(echo "$REFS" | sort -u)
TRACES_SORTED=$(echo "$TRACES" | sort -u)

if [ "$REFS_SORTED" != "$TRACES_SORTED" ]; then
  ONLY_REFS=$(comm -23 <(echo "$REFS_SORTED") <(echo "$TRACES_SORTED") | tr '\n' ',' | sed 's/,$//')
  ONLY_TRACES=$(comm -13 <(echo "$REFS_SORTED") <(echo "$TRACES_SORTED") | tr '\n' ',' | sed 's/,$//')
  echo "[p4-traces-integrity] WARNING: $ID の @traces ↔ refs が不一致" >&2
  [ -n "$ONLY_REFS" ] && echo "  refs にあるが @traces にない: $ONLY_REFS" >&2
  [ -n "$ONLY_TRACES" ] && echo "  @traces にあるが refs にない: $ONLY_TRACES" >&2
  exit 0
fi

exit 0
HOOKEOF

chmod +x "$HOOK_FILE"
echo "Hook installed: $HOOK_FILE"
echo ""
echo "次のステップ: settings.json に以下を追加してください:"
echo '  {"hooks":{"PreToolUse":[{"matcher":"Edit","hooks":["bash .claude/hooks/p4-traces-integrity-check.sh"]},{"matcher":"Write","hooks":["bash .claude/hooks/p4-traces-integrity-check.sh"]}]}}'
