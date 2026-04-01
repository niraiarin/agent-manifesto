#!/usr/bin/env bash
# P3 Axiom Evidence Check — PreToolUse: Bash (git commit)
#
# 公理関連 Lean ファイルの変更時に、根拠メタデータの更新を確認する。
# D1（構造的強制）: normative ではなく structural に保証。
#
# D8（均衡探索）: 段階的厳格化
# - 1回目 → 警告
# - 2回目以降 → ブロック

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

# git commit 以外は無視
if ! echo "$COMMAND" | grep -qE 'git\s+commit'; then
  exit 0
fi

# Resolve git working directory for worktree support
GIT_DIR=""
if echo "$COMMAND" | grep -qE '^[[:space:]]*cd[[:space:]]+'; then
GIT_DIR=$(echo "$COMMAND" | sed -n 's/^[[:space:]]*cd[[:space:]][[:space:]]*\("\([^"]*\)"\|\([^ &;]*\)\).*/\2\3/p')
fi
GIT_CMD=(git)
if [ -n "$GIT_DIR" ] && [ -d "$GIT_DIR" ]; then
GIT_CMD=(git -C "$GIT_DIR")
fi

# 公理関連ファイルのパターン
AXIOM_FILES='lean-formalization/Manifest/(Axioms|EmpiricalPostulates|Observable)\.lean'

STAGED=$("${GIT_CMD[@]}" diff --cached --name-only 2>/dev/null)
if ! echo "$STAGED" | grep -qE "$AXIOM_FILES"; then
  exit 0
fi

# 公理関連ファイルの diff を取得
AXIOM_DIFF=$("${GIT_CMD[@]}" diff --cached -U0 2>/dev/null -- \
  'lean-formalization/Manifest/Axioms.lean' \
  'lean-formalization/Manifest/EmpiricalPostulates.lean' \
  'lean-formalization/Manifest/Observable.lean')

if [ -z "$AXIOM_DIFF" ]; then
  exit 0
fi

WARNINGS=""

# チェック 1: axiom 行が変更されているのに Basis が変更されていないか
AXIOM_CHANGED=$(echo "$AXIOM_DIFF" | grep -E '^\+axiom [a-z_]' | wc -l | tr -d ' ')
BASIS_CHANGED=$(echo "$AXIOM_DIFF" | grep -E '^\+.*Basis:' | wc -l | tr -d ' ')

if [ "$AXIOM_CHANGED" -gt 0 ] && [ "$BASIS_CHANGED" -eq 0 ]; then
  WARNINGS="${WARNINGS}  - axiom 宣言が変更されましたが Basis: が更新されていません\n"
fi

# チェック 2: 公理/Axiom Card が変更されているのに Last validated が更新されていないか
CARD_CHANGED=$(echo "$AXIOM_DIFF" | grep -E '^\+.*(Content:|Basis:|Source:|Refutation condition:|Layer:|Adopted:|Review cycle:|\[Axiom Card\])' | wc -l | tr -d ' ')
AXIOM_OR_CARD=$((AXIOM_CHANGED + CARD_CHANGED))
VALIDATED_CHANGED=$(echo "$AXIOM_DIFF" | grep -E '^\+.*Last validated:' | wc -l | tr -d ' ')

if [ "$AXIOM_OR_CARD" -gt 0 ] && [ "$VALIDATED_CHANGED" -eq 0 ]; then
  WARNINGS="${WARNINGS}  - 公理/Axiom Card が変更されましたが Last validated: が更新されていません\n"
fi

# チェック 3: Last validated が更新されている場合、日付が妥当か
if [ "$VALIDATED_CHANGED" -gt 0 ]; then
  TODAY=$(date +%Y-%m)
  VALIDATED_DATE=$(echo "$AXIOM_DIFF" | grep -E '^\+.*Last validated:' | head -1 | sed 's/.*Last validated:[[:space:]]*//' | tr -d ' ')
  if ! echo "$VALIDATED_DATE" | grep -q "^${TODAY}"; then
    WARNINGS="${WARNINGS}  - Last validated の日付が今月 (${TODAY}) ではありません: ${VALIDATED_DATE}\n"
  fi
fi

# 警告なしなら通過
if [ -z "$WARNINGS" ]; then
  exit 0
fi

# D8: 段階的厳格化
SESSION=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null)
STATE_FILE="/tmp/p3-axiom-evidence-warned-${SESSION}"

if [ -f "$STATE_FILE" ]; then
  echo "P3/Evidence: 公理変更コミット BLOCKED — 根拠メタデータの更新が必要です。" >&2
  printf "%b" "$WARNINGS" >&2
  echo "根拠を更新してから再度コミットしてください。" >&2
  exit 2
else
  touch "$STATE_FILE"
  echo "P3/Evidence: 公理関連ファイルが変更されています。以下を確認してください:" >&2
  printf "%b" "$WARNINGS" >&2
  echo "次回の分類なしコミットはブロックされます。" >&2
  exit 0
fi
