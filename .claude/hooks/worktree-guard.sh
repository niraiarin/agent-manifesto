#!/usr/bin/env bash
# Worktree Guard — PreToolUse: Edit, Write
#
# git worktree が存在する場合、main repo 内のファイル編集をブロックする。
# worktree で作業すべき状態なのに main repo を直接編集する誤操作を防止。
#
# 例外:
# - worktree 内のファイル編集（worktree 自身の編集は許可）
# - .claude/ 配下（hooks, skills, settings 等の構成ファイル）
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

# main worktree のパスを取得 (#561)
MAIN_WORKTREE=$(git worktree list 2>/dev/null | head -1 | awk '{print $1}')

# worktree 内にいる場合: main repo へのクロス編集でなければ許可
if [[ "$PROJECT_ROOT" != "$MAIN_WORKTREE" ]]; then
  # worktree 内にいるが、FILE_PATH が main repo を指していたらブロック
  if [[ "$FILE_PATH" = "$MAIN_WORKTREE/"* ]]; then
    echo "BLOCKED: worktree 内から main repo のファイルを直接編集できません。" >&2
    echo "" >&2
    echo "  編集対象: $FILE_PATH" >&2
    echo "  main repo: $MAIN_WORKTREE" >&2
    exit 2
  fi
  # worktree 自身 or 外部ファイル → 許可
  exit 0
fi

# ここ以降は main repo にいる場合のみ

# ファイルが main repo 内かチェック (#561: trailing slash で prefix 誤マッチ防止)
if [[ ! "$FILE_PATH" = "$PROJECT_ROOT/"* ]] && [[ "$FILE_PATH" != "$PROJECT_ROOT" ]]; then
  # main repo 外のファイル（外部 worktree 内等）→ OK
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
