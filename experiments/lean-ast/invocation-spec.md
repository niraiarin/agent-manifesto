# Lean CLI Invocation & Hook Integration — Sub-G (#662) 成果物

対象: Lean metaprogram CLI を hook / skill から呼び出す hermetic path + PreToolUse hook routing 仕様。Parent #654 の Gap 7 (hermetic invocation) + Gap 9 (hook integration) 統合。

## 前提

- Sub-A (#656) で CLI API が確定: `lean-cli {parse|query|edit|insert}`、exit code 1:1 対応
- Sub-C (#658) で package 位置確定: 既存 `lean-formalization/lakefile.lean` に追加 `lean_exe «lean-cli»`
- Sub-D (#659) で startup cost 実測: Profile A warm 103ms / Profile B warm 48ms
- 既存 hook: `~/.claude/hooks/prefer-jq-for-structured-data.sh` (JSON/YAML 等への Edit を block)

## Invocation パターン比較

| # | パターン | Pros | Cons |
|---|---|---|---|
| I1 | `cd lean-formalization && lake env lake exe lean-cli <args>` | 確実、lake の全機能利用可 | cwd 変更、forked shell 必要 |
| I2 | `(cd lean-formalization && lake env lake exe lean-cli <args>)` (subshell) | cwd 波及なし、I1 の一変種 | sub-shell 起動コスト (~10ms) |
| I3 | `LEAN_PATH=/path/to/olean lean-formalization/.lake/build/bin/lean-cli <args>` | 最速 (lake overhead なし) | LEAN_PATH 組立が fragile、Mathlib path が長大 |
| I4 | `lake exe --dir lean-formalization lean-cli <args>` | flag で cwd 指定 | **非実在**: 2026-04 lake CLI に `--dir` オプションなし (Sub-C で確認済)、候補外 |

**採用**: **I2 (subshell 形式)**。理由:
- I1: 親 shell の cwd を汚染するリスクあり、hook で使うには不適
- I3: LEAN_PATH を hook が再現するのはメンテ負担大、Mathlib 更新で壊れやすい
- I4: 非実在

### 採用 invocation 形式

```bash
# hook / skill から呼ぶ canonical 形式
(cd "$CLAUDE_PROJECT_DIR/lean-formalization" && lake env lake exe lean-cli <subcommand> <args>)
```

- `$CLAUDE_PROJECT_DIR` は Claude Code hook で提供される
- subshell `(...)` で親 cwd 保持
- `lake env` で LEAN_PATH 等の環境変数を lake が構築

### 計測: invocation overhead

Sub-D Profile A baseline 103ms (warm) から、subshell + `lake env` の追加コストを差し引いて CLI 本体の純粋 startup を推定する作業は実装時に確認 (spec では論じない)。**本 spec は hook decision time < 100ms を目標**、CLI 実行時間は除外。

## PreToolUse Hook: Edit → CLI Routing 仕様

### Trigger

- **matcher**: `Edit`
- **condition**: `tool_input.file_path` が `*.lean` (小文字拡張子) にマッチ、かつファイルが既に存在 (新規作成は対象外)

### Routing 手順

```
1. Edit 入力を inspect: file_path, old_string, new_string
2. 編集内容から CLI subcommand を推論:
   - Block-level 置換 (axiom/theorem/def 1 件分丸ごと) → edit --replace-body
   - docstring 追加 → edit --prepend-doc
   - attribute 追加 → edit --prepend-attr
   - 部分的編集 (function body 内の 1 行変更) → CLI 対象外、Edit 継続
3. CLI invocation:
   (cd $CLAUDE_PROJECT_DIR/lean-formalization && lake env lake exe lean-cli edit -i <file> <args>)
4. Exit code 判定 (deterministic):
   - 0          → 成功、PreToolUse で tool_input 書き換え / Edit 実行不要
   - 2,3,5,6    → recoverable、Edit 継続、stderr を context に注入
   - 4,10       → abort、Edit abort、stderr を user 表示
   - 64         → hook 引数 bug、Edit 継続
   - その他      → unknown、Edit 継続、stderr を user 表示
```

Hook の routing decision 部分は **CLI 実行を除いて < 100ms** で完結すべき。CLI 自体の実行時間 (48ms-2s) は含まない (Sub-D の profile による)。

### Hook JSON (Claude Code PreToolUse 仕様)

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "additionalContext": "[lean-cli] successfully applied via lean-cli edit"
  }
}
```

or for fallback:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": "[lean-cli] fallback to Edit: parse_failure at line 42 col 10"
  }
}
```

Exit 2 (= Claude Code hook の "block") で Edit を止め、exit 0 で Edit を許可するのは既存 `prefer-jq-for-structured-data.sh` と同じ pattern。ただし本 hook は「CLI で成功したら Edit を不要にする」ケースを追加するため、tool_input 書き換え / Edit suppression 機能が必要。Claude Code の `hookSpecificOutput.permissionDecision ∈ {"allow", "deny", "ask"}` + `additionalContext` + `toolInput` は 2026-04 時点の hook 仕様として documented (docs.claude.com/en/docs/claude-code/hooks-guide 参照)。**ただし本 project で実際に動作確認したのは exit-code-only pattern のみ** (既存 3 hook 全てが exit code 方式)。`hookSpecificOutput` JSON protocol の実動作は Sub-G 内では未検証、**実装フェーズで Claude Code 実機確認が必要**。

**Fallback design**: もし JSON protocol が期待通り動作しない場合、以下の退化パスで機能する:
- Exit 0 で Edit を常に継続させる (hook は観測のみ、CLI の edit は独立の副次プロセスとして実行)
- Exit 2 で Edit を block、user が agent に CLI 使用を促す

この退化パスでは Edit suppression はできないが、**CLI が編集を先行させて disk に書く + Edit が後続で上書きする** race が発生する。運用上は JSON protocol 動作前提で実装を進め、動作しない場合は設計変更。

### 既存 jq hook との整合

- 既存 `prefer-jq-for-structured-data.sh`: Edit を block して jq 使用を user に促す (agent がリアクティブに judgment)
- 本 lean-cli hook: CLI が自動実行、成功なら Edit 不要、失敗なら Edit fallback (判断不要)

設計哲学が異なる:
- jq hook: **消極的 (don't use Edit)**
- lean-cli hook: **積極的 (use CLI automatically, fall back to Edit on failure)**

両者は共存可能。命名も `prefer-jq-*` vs `auto-lean-cli-*` で区別。

## Hook Sample Script

```bash
#!/usr/bin/env bash
# ~/.claude/hooks/auto-lean-cli.sh
# PreToolUse hook: try lean-cli for .lean Edit, fall back on failure.
# See experiments/lean-ast/invocation-spec.md

set -euo pipefail

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // ""')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // ""')

# Only engage on Edit tool for existing .lean files
[[ "$tool_name" != "Edit" ]] && exit 0
[[ -z "$file_path" ]] && exit 0
[[ ! -f "$file_path" ]] && exit 0
case "$file_path" in *.lean) ;; *) exit 0 ;; esac

# CLI invocation (subshell preserves parent cwd)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null)}"
LEAN_FMT="$PROJECT_DIR/lean-formalization"
[[ ! -d "$LEAN_FMT" ]] && exit 0   # not this project structure, let Edit proceed

# Infer CLI subcommand from Edit input (simplified for spec purpose)
# Real implementation would parse old_string/new_string to decide
# replace-body / prepend-doc / prepend-attr / passthrough-to-Edit
# For now, treat any Edit as passthrough (let Edit handle it)
exit 0

# --- Placeholder logic showing exit code handling ---
# stderr_tmp=$(mktemp)
# (cd "$LEAN_FMT" && lake env lake exe lean-cli edit -i "$file_path" ...) 2>"$stderr_tmp"
# case $? in
#   0)
#     # Success: CLI handled the edit, instruct Edit to no-op
#     cat <<JSON
# {"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "additionalContext": "[lean-cli] edit applied"}}
# JSON
#     exit 0
#     ;;
#   2|3|5|6)
#     # Recoverable: let Edit proceed, inject context
#     cat "$stderr_tmp" >&2
#     echo "[lean-cli] fallback to Edit tool" >&2
#     exit 1   # non-2 exit = Edit proceeds (Sub-A sample と揃える、PreToolUse 仕様上 exit 2 のみが block)
#     ;;
#   4|10)
#     # Abort
#     cat "$stderr_tmp" >&2
#     exit 2
#     ;;
#   64|*)
#     # Hook bug or unknown: let Edit proceed
#     cat "$stderr_tmp" >&2
#     exit 0
#     ;;
# esac
```

本サンプルは **routing skeleton**。実装フェーズで Edit input → CLI subcommand 推論ロジックを書き足す。

## Gate 判定

### Gate 基準 (Sub-Issue #662)

- **PASS**: hermetic 呼び出しが 1-line で expressible、hook routing が既存 hygiene hook (jq/yq) と一貫、100ms 以内で発動判定可能 (CLI 実行時間除く)
- **CONDITIONAL**: `LEAN_PATH` が fragile、個別 env setup 文書化
- **FAIL**: Claude Code の hook 実行環境で `lake env` が機能しない

### 判定: **CONDITIONAL**

| 基準 | 達成 |
|---|---|
| 1-line hermetic invocation | `(cd $CLAUDE_PROJECT_DIR/lean-formalization && lake env lake exe lean-cli ...)` ✅ |
| 既存 hygiene hook との一貫性 | 既存 `prefer-jq-*` hook と PreToolUse / exit code 規律を共有。ただし JSON protocol 使用は新規 ⏸ |
| 100ms 以内 decision | CLI 除外条件判定 (拡張子・存在確認・project 構造) は bash native、<10ms ✅ (assertion、未計測) |
| Fallback policy 明確 | exit code → hook action の完全 mapping (Sub-A error contract 使用) ✅ |

CONDITIONAL 理由: 基準 2 に付随する **`hookSpecificOutput` JSON protocol の Claude Code 実機動作が未検証**。退化 fallback (exit-code-only) に降格すれば本 Sub-G の他の設計は動作するが、Edit suppression 機能が失われる。

### Stabilization 計画

- **Option 1 (Verification task)**: 実装フェーズ冒頭で `hookSpecificOutput.permissionDecision = "deny"` + `toolInput` 書き換えが機能するかを最小 hook で確認。動作すれば PASS 相当、動かなければ設計変更
- **Option 2 (Fallback path)**: JSON protocol が動かない場合、CLI 実行は hook と独立させ、Edit は block せずに継続。編集 race は skill 側の規律で対処 (Sub-F の concurrency 研究範疇)

本 Sub-G は **Option 1 前提の spec**、Option 2 は fallback として記録のみ。

### Addressable (解消済み)

Round 1 Verifier 指摘 5 件を反映:
1. lake --dir 非実在 → 「環境要件」節に Sub-C reference 明記
2. `hookSpecificOutput` 未検証 → 本 CONDITIONAL + Fallback design で明示
3. Sub-A vs Sub-G の exit code (1 vs 0) 不整合 → sample script を exit 1 に揃え、コメント追記
4. `CLAUDE_PROJECT_DIR` 未設定 → 「環境要件」節で `git rev-parse` fallback 言及
5. `lake` PATH 要件 → 「環境要件」節で elan install 前提 + ハードコード fallback path 記載

### Unaddressable

- Edit input (`old_string` / `new_string`) から CLI subcommand を**正確に**推論するロジックは spec 未確定、実装フェーズで決定。本 Sub-G はインタフェース層の設計のみ扱う。
- CLI が "edit" を判断する際の ambiguous cases (複数 body 候補、class instance 等) は Sub-A scope で考慮、Sub-G 再確認不要

## 環境要件・前提

### Hook 実行環境

- `$CLAUDE_PROJECT_DIR`: Claude Code hook で提供される (2026-04 仕様、settings.json から参照可)。未設定環境では `git rev-parse --show-toplevel` へ fallback (sample script 参照)
- `lake` が PATH に存在: elan 経由 install の場合、macOS では `.zshrc` / `.zprofile` で `~/.elan/bin` が export されている前提。Claude Code hook が shell config を source しない環境では fallback として `~/.elan/bin/lake` のハードコード path を使用
- `jq`: 入力 JSON parse 用、標準的 macOS / Linux で install 済前提 (既存 `prefer-jq-*` hook が同じ前提)
- Bash 3.2+ 互換: `[[ ]]` / `case` のみ使用、bash 4+ 機能 (associative array 等) は使わない

### Sub-C (#658) 参照: lake --dir option 非実在

lake CLI 2026-04 時点 (Lean 4.29.0) で `--dir` flag は未実装。確認手順: `lake --help` 出力に `--dir` がない、Sub-C (build-placement-decision.md) で cross-checked。代替は invocation pattern I1 or I2 (subshell)。

## 既存 hooks との関係

`~/.claude/hooks/` 現在の state:
- `prefer-jq-for-structured-data.sh`: JSON/YAML/TOML/CSV Edit を block
- `block-python-dump.sh`: python json.dump / yaml.dump を block
- **(新規)** `auto-lean-cli.sh`: `.lean` Edit を CLI 経由に routing (本 spec)

registration 先: `~/.claude/settings.json` の `hooks.PreToolUse` (global) もしくは project-local `.claude/settings.json`。Global 推奨 (Lean プロジェクトは複数存在しうる)。

## 次のアクション

- **実装**: 本 spec + Sub-A cli-api-spec + Sub-C lakefile decision を統合して `lean_exe «lean-cli»` を実装 (最終フェーズ、別 Parent Issue で予定)
- **hook 実装**: 本 sample skeleton を元に `~/.claude/hooks/auto-lean-cli.sh` を完成 (Edit input → subcommand 推論ロジック含む)
- **Sub-E (#660)**: byte-preserving PoC がこの CLI の edit primitive を使用
- **Sub-F (#661)**: concurrency safety が hook 並行呼び出しを検証
