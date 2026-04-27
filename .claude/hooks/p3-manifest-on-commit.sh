#!/usr/bin/env bash
# P3 Manifest-on-Commit (Section 6.2.1、Day 10 Subagent A1 対処で v2 拡張) — PreToolUse: Bash (git commit)
#
# Pattern #7 強制: agent-spec-lib/AgentSpec/{Spine,Proofs,Process,Provenance,Test/Cross}/ 配下の
# 新規 .lean ファイル (`A` ステータス) が staged された場合、
# agent-spec-lib/artifact-manifest.json も同 commit に staged されていることを要求。
#
# v2 拡張 (Day 10 Subagent A1 対処): regex に Provenance + Test/Cross を追加
#
# 設計判断 (11-pending-tasks Section 6.2.1):
# - 検出範囲: A1 狭 (新規ファイルのみ、既存修正は対象外)
# - 違反時動作: B2 block (exit 2)
# - 適用範囲: D1 new-foundation worktree のみ
# - bypass: E2 コミットメッセージに [no-manifest] タグで bypass 可
#
# @traces P3 (Pattern #7), Section 6.2.1, D1-D4 (構造的強制)

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

# git commit でなければ pass-through
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

# new-foundation worktree のみ対象 (D1)
if ! "${GIT_CMD[@]}" rev-parse --show-toplevel 2>/dev/null | xargs -I{} test -f "{}/agent-spec-lib/artifact-manifest.json"; then
  exit 0
fi

# bypass tag check (E2)
if echo "$COMMAND" | grep -qE '\[no-manifest\]'; then
  exit 0
fi

# 検出対象 layer (Day 10 v2 で Provenance + Test/Cross 追加)
DETECTION_REGEX='^agent-spec-lib/AgentSpec/(Spine|Proofs|Process|Provenance|Test/Cross)/.*\.lean$'

NEW_LEAN=$("${GIT_CMD[@]}" diff --cached --name-status 2>/dev/null \
  | awk -v re="$DETECTION_REGEX" '$1 == "A" && $2 ~ re {print $2}')

if [ -z "$NEW_LEAN" ]; then
  exit 0
fi

# manifest が staged されているか
MANIFEST_STAGED=$("${GIT_CMD[@]}" diff --cached --name-only 2>/dev/null \
  | grep -E '^agent-spec-lib/artifact-manifest\.json$')

if [ -n "$MANIFEST_STAGED" ]; then
  exit 0
fi

# B2: block
echo "P3 Pattern #7 違反: 新規 Spine/Proofs/Process/Provenance/Test/Cross 配下の .lean ファイルが staged されていますが、" >&2
echo "agent-spec-lib/artifact-manifest.json が同 commit に含まれていません。" >&2
echo "" >&2
echo "新規ファイル:" >&2
echo "$NEW_LEAN" | sed 's/^/  - /' >&2
echo "" >&2
echo "対処:" >&2
echo "  1. agent-spec-lib/artifact-manifest.json を更新して新規 artifact を追加" >&2
echo "  2. git add agent-spec-lib/artifact-manifest.json" >&2
echo "  3. 再度 commit" >&2
echo "" >&2
echo "例外的に manifest 不要な場合 (例: テストファイルのみの commit など):" >&2
echo "  コミットメッセージに [no-manifest] タグを含める (E2 bypass)" >&2
exit 2

# Traceability:
# Section 6.2.1: artifact-manifest 同 commit 反映の構造的強制
# Pattern #7: Day 1-4 で 4 連続違反 → Day 5 で hook 化により構造的解決
# Day 10 v2: Subagent A1 対処、regex に Provenance + Test/Cross 追加
# D1-D4 (Safety/Verification/Observability/Governance): 後続フェーズ依存性を保護
