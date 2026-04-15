#!/usr/bin/env bash
# Worktree Guard — PreToolUse: Edit, Write
#
# git worktree が存在する場合、main repo 内のファイル編集をブロックする。
# worktree で作業すべき状態なのに main repo を直接編集する誤操作を防止。
#
# 例外:
# - .claude/ 配下（hooks, skills, settings 等の構成ファイル）
# - MEMORY.md, memory/ 配下
# - scripts/ 配下（sync-counts.sh 等のインフラ）
# - tests/ 配下
#
# @traces D1, L1

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

# file_path が空なら（Edit/Write 以外が来た場合）スルー
[[ -z "$FILE_PATH" ]] && exit 0

# プロジェクトルートを取得
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0

# worktree が存在するか確認（main worktree 以外）
WORKTREE_COUNT=$(git worktree list 2>/dev/null | wc -l)
if [[ "$WORKTREE_COUNT" -le 1 ]]; then
  # worktree なし → 制約なし
  exit 0
fi

# ファイルが main repo 内かチェック
if [[ ! "$FILE_PATH" = "$PROJECT_ROOT"* ]]; then
  # main repo 外のファイル（worktree 内等）→ OK
  exit 0
fi

# 例外パス: main repo 内でも編集を許可するディレクトリ
REL_PATH="${FILE_PATH#$PROJECT_ROOT/}"
case "$REL_PATH" in
  .claude/*|scripts/*|tests/*|dist/*|README.md|CHANGELOG.md|depgraph*.json)
    # インフラファイルは main repo で編集可能
    exit 0
    ;;
esac

# worktree のリストを取得して案内に使う
WORKTREES=$(git worktree list 2>/dev/null | tail -n +2 | awk '{print $1}')

echo "BLOCKED: git worktree が存在する間は main repo のファイルを直接編集できません。" >&2
echo "" >&2
echo "  編集対象: $REL_PATH" >&2
echo "  main repo: $PROJECT_ROOT" >&2
echo "" >&2
echo "以下のいずれかで対処してください:" >&2
echo "  1. worktree 内の対応ファイルを編集する:" >&2
for wt in $WORKTREES; do
  echo "     $wt/$REL_PATH" >&2
done
echo "  2. worktree.sh pr で成果物を main repo にコピーしてから編集する" >&2
echo "  3. 不要な worktree を削除する: git worktree remove <path>" >&2
exit 2
