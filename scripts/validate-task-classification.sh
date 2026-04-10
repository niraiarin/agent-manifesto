#!/usr/bin/env bash
# validate-task-classification.sh — タスク分類テーブルの整合性検証 (#364 G4)
# TaskAutomationClass: deterministic → structural enforcement
# 根拠: deterministic_must_be_structural (TaskClassification.lean)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILL_MD="$SCRIPT_DIR/.claude/skills/research/SKILL.md"
LEAN_FILE="$SCRIPT_DIR/lean-formalization/Manifest/TaskClassification.lean"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

errors=0

# --- 検査 1: 分類テーブルと照合チェックリストの行数一致 ---
# 分類テーブルの行数: "## タスク自動化分類" から "### 照合" までの Step 行
table_count=$(sed -n '/^## タスク自動化分類/,/^### 照合/p' "$SKILL_MD" \
  | grep -cE '^\| Step [0-9]' || true)
# 照合チェックリストの行数: "### 照合チェックリスト" から次の "## " まで
checklist_count=$(sed -n '/^### 照合チェックリスト/,/^## [^#]/p' "$SKILL_MD" \
  | grep -cE '^\| Step [0-9]' || true)

echo "=== タスク分類テーブル整合性検証 ==="
echo ""
echo "  分類テーブルの行数:       $table_count"
echo "  照合チェックリストの行数: $checklist_count"
echo ""

if [[ "$table_count" -ne "$checklist_count" ]]; then
  echo -e "${RED}FAIL${NC}: テーブル行数($table_count) ≠ チェックリスト行数($checklist_count)"
  errors=$((errors + 1))
else
  echo -e "${GREEN}PASS${NC}: テーブル行数 = チェックリスト行数 ($table_count)"
fi

# --- 検査 2: チェックリストの定理が TaskClassification.lean に存在するか ---
echo ""
echo "--- 定理の接地検査 ---"

theorems=$(sed -n '/^### 照合チェックリスト/,/^##/p' "$SKILL_MD" \
  | grep -oE '`[a-z_]+`' | tr -d '`' | sort -u)

for thm in $theorems; do
  if grep -q "theorem $thm\|def $thm" "$LEAN_FILE"; then
    echo -e "  ${GREEN}✓${NC} $thm"
  else
    echo -e "  ${RED}✗${NC} $thm — TaskClassification.lean に未定義"
    errors=$((errors + 1))
  fi
done

echo ""
if [[ "$errors" -eq 0 ]]; then
  echo -e "${GREEN}=== 全検査 PASS ===${NC}"
  exit 0
else
  echo -e "${RED}=== $errors 件の不整合 ===${NC}"
  exit 1
fi
