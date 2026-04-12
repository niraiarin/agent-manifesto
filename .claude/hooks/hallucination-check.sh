#!/usr/bin/env bash
# PoC: Hallucination Detection Hook — PreToolUse: Edit, Write
#
# Lean 定義名・数値引用のリアルタイム事実検証。
# .md ファイルへの Edit/Write 時に、引用された Lean 定義名と
# 数値（axiom/theorem/test count）の実在を検証する。
#
# Mode:
#   WARN  — stderr に警告を出すが exit 0（ブロックしない）
#   BLOCK — exit 2 でブロック
#
# 現在は WARN モードで動作（PoC フェーズ）。
# @traces L2

# Note: hooks must NOT use set -e (non-zero grep exits would crash the hook)
# Exit codes: 0 = allow, 2 = block. Any other exit = error.
set -u

MODE="${HALLUCINATION_HOOK_MODE:-WARN}"
# 本番配置: .claude/hooks/ → PROJECT_ROOT は ../..
# PoC/テスト: PROJECT_ROOT を環境変数で上書き可能
if [ -n "${HALLUCINATION_HOOK_PROJECT_ROOT:-}" ]; then
  PROJECT_ROOT="$HALLUCINATION_HOOK_PROJECT_ROOT"
else
  PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo ".")"
fi
LEAN_DIR="$PROJECT_ROOT/lean-formalization"

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

# Edit/Write 以外は無視
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# .md ファイルのみ検査（.lean は Lean コンパイラが検証）
if ! echo "$FILE_PATH" | grep -qE '\.md$'; then
  exit 0
fi

# 編集内容を取得
CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string // .tool_input.content // empty' 2>/dev/null)
if [ -z "$CONTENT" ]; then
  exit 0
fi

WARNINGS=""

# --- Check 1: Lean 定義名の実在検証 ---
# バッククォート内の Lean 定義名パターンを抽出
# パターン: `snake_case_name` で、Lean の定義名に見えるもの
# 除外: 短すぎるもの (3文字以下)、明らかなコマンド/パス、日本語
LEAN_NAMES=$(echo "$CONTENT" | grep -oE '`[a-z][a-z0-9_]+[a-z0-9]`' | tr -d '`' | sort -u | while read -r name; do
  # 3文字以下は除外
  [ ${#name} -le 3 ] && continue
  # 明らかなコマンド名・パスを除外
  echo "$name" | grep -qE '^(bash|grep|test|echo|exit|null|true|false|jq|sed|awk|wc|cat|head|tail|sort|uniq|find|git|lake|lean|cd|ls|rm|cp|mv|mkdir|chmod|diff|curl|wget|npm|bun|bunx|python)$' && continue
  # ファイルパスの一部を除外
  echo "$name" | grep -qE '(\.sh|\.json|\.md|\.lean|\.jsonl)' && continue
  echo "$name"
done)

if [ -n "$LEAN_NAMES" ]; then
  # Lean ファイルから全定義名を取得（キャッシュ考慮）
  CACHE_FILE="${TMPDIR:-/tmp}/lean-definitions-cache.txt"
  CACHE_AGE=300  # 5分

  if [ -f "$CACHE_FILE" ] && [ "$(find "$CACHE_FILE" -mmin -5 2>/dev/null)" ]; then
    LEAN_DEFS=$(cat "$CACHE_FILE")
  else
    LEAN_DEFS=$(grep -rhE '^(theorem|axiom|def|lemma|instance|class|structure|opaque|inductive) [a-zA-Z_][a-zA-Z0-9_]*' \
      "$LEAN_DIR"/Manifest/*.lean 2>/dev/null | \
      sed -E 's/^(theorem|axiom|def|lemma|instance|class|structure|opaque|inductive) ([a-zA-Z_][a-zA-Z0-9_]*).*/\2/' | \
      sort -u)
    echo "$LEAN_DEFS" > "$CACHE_FILE" 2>/dev/null || true
  fi

  # 各名前を検証
  while IFS= read -r name; do
    [ -z "$name" ] && continue
    # Lean 定義名のように見えるもの（snake_case でアンダースコアを含む）
    if echo "$name" | grep -qE '_'; then
      # Lean 定義として検証
      if ! echo "$LEAN_DEFS" | grep -qxF "$name"; then
        # SKILL.md/CLAUDE.md の既知セクション名やフィールド名は除外
        echo "$name" | grep -qE '^(failure_type|failure_subtype|tool_name|tool_input|file_path|new_string|session_id|tool_use_id|pass_count|fail_count|pass_rate|cost_per_improvement|session_cost|improvements_count|conservative_extension|compatible_change|breaking_change|action_space|proxy_classification|test_pass_rate|deferred_open|deferred_status|hypothesis_table_stats|evolve_cost_efficiency|total_improvements|definition_note|last_updated_run|opened_in_run|resolved_in_run)$' && continue
        WARNINGS="${WARNINGS}Lean definition '${name}' not found in formalization.\n"
      fi
    fi
  done <<< "$LEAN_NAMES"
fi

# --- Check 2: 数値引用の検証 ---
# "N axioms" / "N theorems" / "N tests" パターンを検出
check_count() {
  local pattern="$1"
  local actual="$2"
  local label="$3"

  local claimed
  claimed=$(echo "$CONTENT" | grep -oE "[0-9]+ ${pattern}" | head -1 | grep -oE '^[0-9]+')
  if [ -n "$claimed" ] && [ "$claimed" != "$actual" ]; then
    WARNINGS="${WARNINGS}${label} count mismatch: claimed ${claimed}, actual ${actual}.\n"
  fi
}

# 実際の値を取得
if [ -d "$LEAN_DIR/Manifest" ]; then
  ACTUAL_AXIOMS=$(grep -r "^axiom [a-z]" "$LEAN_DIR"/Manifest/ --include="*.lean" 2>/dev/null | wc -l | tr -d ' ')
  ACTUAL_THEOREMS=$(grep -r "^theorem " "$LEAN_DIR"/Manifest/ --include="*.lean" 2>/dev/null | wc -l | tr -d ' ')
fi
# テスト数: test-all.sh の結果から抽出（全実行は重いため、JSONL の最新値を使用）
ACTUAL_TESTS=$(tail -1 "$PROJECT_ROOT/.claude/metrics/evolve-history.jsonl" 2>/dev/null | jq -r '.tests.passed // empty' 2>/dev/null)
if [ -z "$ACTUAL_TESTS" ]; then
  ACTUAL_TESTS=$(grep -rc "^test_" "$PROJECT_ROOT/tests/"*.sh 2>/dev/null | awk -F: '{s+=$2}END{print s}')
fi

check_count "axioms?" "${ACTUAL_AXIOMS:-}" "Axiom"
check_count "theorems?" "${ACTUAL_THEOREMS:-}" "Theorem"
check_count "tests" "${ACTUAL_TESTS:-}" "Test"

# --- 結果出力 ---
if [ -n "$WARNINGS" ]; then
  if [ "$MODE" = "BLOCK" ]; then
    printf "Hallucination detected:\n%b" "$WARNINGS" >&2
    exit 2
  else
    # WARN モード: stderr に出力するが exit 0
    printf "[hallucination-hook WARN] %b" "$WARNINGS" >&2
    exit 0
  fi
fi

exit 0

# Traceability:
# L2: 情報整合境界 — 参照ファイルの実在性を検証し、幻覚（存在しないファイルへの参照）を検出
