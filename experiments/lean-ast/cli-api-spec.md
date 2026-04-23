# Lean Metaprogram CLI — API Spec (Sub-A #656 成果物)

対象: Lean 4 metaprogram CLI (`lean-cli` 仮称) の入出力仕様。Parent #654 の Gap 1 (happy-path API) + Gap 10 (error contract) を統合。

## 設計原則

1. **Unix philosophy**: stdin/stdout/exit code で UNIX pipe friendly (jq の流儀を踏襲)
2. **Exit code 1:1 対応**: hook が JSON parse なしで fallback 判断可能
3. **Byte-preserving**: rewrite 操作は編集範囲外を完全保持 (Sub-E で実証予定)
4. **Idempotent read**: query 操作は副作用なし、並行呼び出し安全 (Sub-F で検証)

## 類似 CLI の API 体系比較

| CLI | Query pattern | Edit pattern | Output |
|---|---|---|---|
| `jq` | `jq '.foo' file.json` | `jq '.foo = "bar"' file.json` (stdout) | JSON to stdout |
| `yq` | `yq '.foo' file.yaml` | `yq -i '.foo = "bar"' file.yaml` (in-place flag) | YAML/JSON |
| `dasel` | `dasel -f x.toml '.foo'` | `dasel put -f x.toml -v "bar" foo` | Format preserve |
| `mlr` | `mlr --csv filter '$a>0' file.csv` | Pipeline-based | CSV/DKVP |

**採用方針**: `dasel` に近い subcommand スタイル (`lean-cli query`, `lean-cli edit`, `lean-cli insert`)。理由: Lean の edit 操作は単純な expression よりも構造的で、jq 風 inline expression だと Lean syntax が入れ子になり複雑化する。

## 本 project の典型ユースケース (5+ 件列挙)

| # | ユースケース | 発生頻度 | API primitive |
|---|---|---|---|
| U1 | **Axiom 名で列挙** (`Manifest/` 全 axiom の名前一覧) | 高 | `query --kind axiom` |
| U2 | **Theorem 本体の型シグネチャ取得** (特定定理の `:` 以降を読む) | 高 | `query --kind theorem --name <N>` |
| U3 | **Axiom への docstring 追加** (既存 axiom に `/-- ... -/` を前置) | 中 | `edit --prepend-doc <name> <text>` |
| U4 | **Theorem body 置換** (proof の書き換え) | 中 | `edit --replace-body <name> <expr>` |
| U5 | **Attribute 追加** (`@[simp]` を既存 def の前に insert) | 中 | `edit --prepend-attr <name> <attr>` |
| U6 | **新 axiom 宣言を挿入** (特定宣言の直前/直後) | 低-中 | `insert --before <name> <decl>` |
| U7 | **Namespace 整理** (namespace ブロックの再配置) | 低 | 複合操作 — Sub-A scope 外 |
| U8 | **Import の追加** (`import Foo.Bar` を header に) | 低 | `edit --add-import <module>` |

Sub-A は U1-U6 + U8 をカバー。U7 は複数 declaration を跨ぐ再構成なので将来 sub-issue で扱う。

## Happy-path API 設計

### Subcommand 一覧

```
lean-cli parse <file>                             # AST JSON を stdout
lean-cli query <file> [options]                   # 宣言列挙・抽出
lean-cli edit <file> [options]                    # in-place 編集
lean-cli insert <file> [options]                  # 宣言挿入
```

### `parse`: AST JSON 出力

```
$ lean-cli parse Manifest/Axioms.lean
{
  "file": "Manifest/Axioms.lean",
  "imports": ["Manifest.Ontology", "Mathlib.Data.Nat.Basic", ...],
  "commands": [
    {
      "kind": "axiom",
      "name": "session_bounded",
      "range": {"start": 3612, "stop": 3947},
      "typeRange": {"start": 3641, "stop": 3947},
      "doc": "T₀: セッションは有限時間で終了する",
      "attrs": []
    },
    ...
  ]
}
```

- `range`: 宣言全体 (docstring + attrs + declaration body)
- `typeRange`: `name : TYPE` の TYPE 部分 (body 抽出用)
- `kind` は enum: `axiom | theorem | def | opaque | inductive | structure | namespace | import | other`

### `query`: 宣言列挙・抽出

```
$ lean-cli query Manifest/Axioms.lean --kind axiom --name-pattern 'session_.*'
[
  {"name": "session_bounded", "kind": "axiom", "range": {...}, "typeText": "∀ (w : World) ..."},
  {"name": "session_no_shared_state", "kind": "axiom", ...}
]

$ lean-cli query Manifest/Axioms.lean --kind theorem --name context_finite --output-field type
∀ (w : World) (s : Session), ...
```

Options:
- `--kind <K>`: kind filter
- `--name-pattern <regex>`: name regex filter
- `--output-field {name|kind|range|type|body|doc|all}`: 特定フィールドのみ出力
- `--format {json|text}`: default json、text は `name:kind:range` 形式

### `edit`: 既存宣言の書き換え

```
# body 置換 (stdout は置換後 file 全体)
$ lean-cli edit Manifest/Foo.lean --replace-body foo 'by simp' > new_foo.lean

# in-place (`-i` flag)
$ lean-cli edit -i Manifest/Foo.lean --replace-body foo 'by simp'

# docstring 前置
$ lean-cli edit -i file.lean --prepend-doc bar "新しい docstring"

# attribute 前置
$ lean-cli edit -i file.lean --prepend-attr baz "@[simp]"

# import 追加 (header 末尾に追記)
$ lean-cli edit -i file.lean --add-import Foo.Bar
```

Byte-preserving 保証: 編集範囲外の byte は `cmp -b` で 100% 一致 (Sub-E #660 で実証)。

### `insert`: 宣言挿入

```
# 特定宣言の直前に新宣言
$ lean-cli insert -i file.lean --before existing_foo 'axiom new_foo : Nat'

# 直後
$ lean-cli insert -i file.lean --after existing_foo 'axiom new_foo : Nat'
```

## Error Contract

### Exit code と error_kind の 1:1 対応表

| Exit | `error_kind` | 意味 | Claude Code hook 挙動 |
|------|--------------|------|----------------------|
| 0 | `ok` | 成功 | CLI 出力を採用、Edit 不要 |
| 2 | `parse_failure` | Lean 文法エラー、parse 不可 | Edit に fallback |
| 3 | `type_error` | parse OK だが post-edit type check 失敗 | 編集取消、Edit に fallback |
| 4 | `partial_apply` | 複数編集中に一部失敗、部分適用状態 | Edit abort、user 通知 |
| 5 | `name_not_found` | `--replace-body foo` の foo が存在しない | Edit に fallback |
| 6 | `ambiguous_match` | name が複数宣言に一致 | Edit に fallback (曖昧) |
| 10 | `internal_error` | CLI bug (panic 等) | Edit に fallback、bug report 推奨 |
| 64 | `usage_error` | CLI 引数不正 | user 通知 (hook bug) |

**原則**: exit code ∈ {0, 2-6, 10, 64}。その他は未使用。

### Error JSON 形式 (stderr)

```json
{
  "error_kind": "type_error",
  "line": 42,
  "column": 10,
  "recoverable": true,
  "message": "type mismatch at `foo`: expected Nat, got String",
  "context": "def foo : Nat := \"hello\"",
  "hint": "checking 'replace-body foo' output"
}
```

必須フィールド:
- `error_kind`: enum (上記表参照)
- `line`, `column`: 1-based、エラー位置 (N/A なら null 可)
- `recoverable`: boolean — hook が Edit fallback 可能か
- `message`: 人間向けメッセージ

任意フィールド:
- `context`: エラー周辺の原文 snippet
- `hint`: 対処提案

### Exit code だけでの fallback 判断 (no JSON parse path)

Hook の簡易経路として、exit code のみで判断可能:

```bash
#!/usr/bin/env bash
# lean-cli-hook.sh (抜粋)
lean-cli edit -i "$file" --replace-body "$name" "$expr" 2>/tmp/err
case $? in
  0)  exit 0 ;;                                          # 成功、Edit 不要
  2|3|5|6) echo "[lean-cli] fallback to Edit tool" >&2 ; exit 1 ;;  # recoverable
  4|10) cat /tmp/err >&2 ; exit 2 ;;                    # abort with reason
  *)  exit 2 ;;                                         # unknown
esac
```

Recoverable (2,3,5,6) は exit code だけで分類可能。詳細理由は stderr JSON を見ずに済む。

## Hook Fallback フロー

```
PreToolUse (Edit on *.lean)
  ↓
lean-cli edit <equivalent args>
  ├─ exit 0: tool_input を書き換え、Edit 不要
  ├─ exit 2|3|5|6 (recoverable): Edit 継続、stderr を user 通知
  ├─ exit 4|10: Edit abort、stderr を user 表示 + bug report 推奨
  └─ exit 64: hook 引数 bug、Edit 継続
```

Fallback logic は deterministic (exit code → action)。JSON parse は「詳細情報が欲しい時」のみ。

## Unaddressable

- Complex 複合操作 (U7 Namespace 整理など) は Sub-A scope 外、将来 sub-issue で扱う
- Macro / notation を含む pretty-printing 時の byte-preserving は Sub-E の範疇 (Sub-A はインタフェース設計のみ)

## Gate 判定

### Gate 基準 (Sub-Issue #656 より)

**PASS**: 以下を全て満たす:
- 列挙した 5+ ユースケース全てが設計 API で表現可能
- Error contract JSON が必須フィールドを含む: `error_kind`, `line`, `column`, `recoverable`, `message`
- Exit code が error_kind と 1:1 対応
- Claude Code hook が exit code のみで fallback 判断可能

### 判定: **PASS**

| 基準 | 達成状況 |
|---|---|
| 5+ ユースケース | 7 件列挙 (U1-U6, U8 がカバー、U7 は scope 外) ✅ |
| Error JSON 必須フィールド | `error_kind`/`line`/`column`/`recoverable`/`message` 全て定義 ✅ |
| Exit code 1:1 対応 | 8 つの error_kind に 8 つの exit code (0, 2-6, 10, 64) ✅ |
| Exit code only fallback | Hook sample code で実証 (recoverable = {2,3,5,6}) ✅ |

### Addressable

なし。

### Unaddressable

- U7 (Namespace 整理) は Sub-A scope 外、将来 sub-issue (必要になった時点で起票)

## 次のアクション

- **Sub-G (#662)**: 本 API spec を前提に invocation path + hook integration を設計
- **Sub-E (#660)**: `edit --replace-body` の byte-preserving を 12 patterns で実証
- **Sub-F (#661)**: `query` (read-only) が concurrent 呼び出しで安全か検証
- **実装**: 本 spec に沿って `lean_exe «lean-cli»` を実装 (本研究の最終フェーズ、別 Parent Issue で起票予定)
