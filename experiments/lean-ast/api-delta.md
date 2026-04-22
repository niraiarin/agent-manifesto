# Lean.Parser/Elab API Delta — Sub-B (#657) 成果物

対象: Lean 4 (`leanprover/lean4:v4.29.0`)

## 既存 ExtractDeps.lean で使用中の API

環境レベルの metadata 抽出のみ。ファイル parse は行わない。

| API | 用途 | 安定性 |
|---|---|---|
| `Lean.initSearchPath` | search path 初期化 | stable |
| `Lean.findSysroot` | Lean インストール位置取得 | stable |
| `Lean.importModules` | モジュール import → Environment | stable |
| `Lean.Environment.constants` | Environment の constant map | stable |
| `Lean.ConstantInfo` (+ `axiomInfo`/`thmInfo`/`defnInfo`/`opaqueInfo`/`inductInfo` variants) | 定数分類 | stable |
| `Lean.Expr.getUsedConstants` | 式が参照する定数の列挙 | stable |
| `Lean.Name` | 識別子名 | stable |
| `Lean.NameHashSet` | 名前集合 | stable |

## 新 CLI で追加で必要な API (3 categories)

### Category 1: Parser (ファイル → Syntax)

| API | 用途 | 安定性 | 備考 |
|---|---|---|---|
| `Lean.Parser.Module.parseHeader` | `import` ... ブロックを parse | stable | `InputContext → IO (TSyntax``Module.header × ModuleParserState × MessageLog)` |
| `Lean.Parser.Module.parseCommand` | 単一 command を parse (incremental) | stable | internal-ish だが export されている |
| `Lean.Parser.Module.testParseFile` | ファイル全体を parse (便宜関数) | **naming が test-prefix** | 実装自体は単純 (parseHeader + loop)、internal に見える命名だが public |
| `Lean.Parser.InputContext` | parse 入力 (file name + contents) | stable | `mkInputContext` で構築 |
| `Lean.Parser.ModuleParserState` | parser の逐次状態 | stable | incremental parse 用 |
| `Lean.Parser.TSyntax` (+ `Syntax`) | 構文木ノード | stable | |

### Category 2: Syntax / SourceInfo (byte-level range 取得)

| API | 用途 | 安定性 | 備考 |
|---|---|---|---|
| `Lean.Syntax.getRange?` | Syntax から byte range を取得 | stable | `canonicalOnly := false` で raw range |
| `Lean.Syntax.getRangeWithTrailing?` | trailing whitespace 含む range | stable | byte-preserving rewrite で重要 (Sub-E) |
| `Lean.Syntax.Range` | range 型 | stable | `{ start : String.Pos, stop : String.Pos }` |
| `Lean.Syntax.SourceInfo` | 各 Syntax ノードの source position | stable | ただし synthetic / original の 2 kind あり |
| `Lean.Syntax.SourceInfo.getRange?` | SourceInfo から Range | stable | |
| `String.Pos.byteIdx` | byte offset (UTF-8) | stable | Unicode 安全 |
| `Lean.Syntax.getArgs` / `getKind` / `.ident _ _ val _` | Syntax ノード走査 | stable | |

**重要**: `String.Range` は 2025 年に deprecate、`Lean.Syntax.Range` に置き換え。本研究は `Lean.Syntax.Range` を採用。

### Category 3: Elaborator (post-edit type check)

| API | 用途 | 安定性 | 備考 |
|---|---|---|---|
| `Lean.Elab.Command.elabCommand` | Syntax → type check 実施 | stable | `Syntax → CommandElabM Unit` |
| `Lean.Elab.Command.CommandElabM` | elab モナド | stable | |
| `Lean.Elab.Command.Context` / `State` | elab context | stable | |
| `Lean.MessageLog` | エラー / 警告収集 | stable | |

Elaborator は Sub-E (byte-preserving rewrite) の **post-edit validation** で使う。parse + rewrite だけなら Parser + SourceInfo で十分。query のみなら Elaborator 不要。

## 参照した sample / 実装例

- **ExtractDeps.lean** (本プロジェクト): `importModules` + `ConstantInfo` 走査の実例。parser/SourceInfo は使用していない。
- **Lean 4 本体 `Lean/Parser/Module.lean`**: `parseHeader` / `parseCommand` / `testParseFile` / `testParseModule` の定義と使用例。
- **Lean 4 本体 `Lean/Syntax.lean`**: `getRange?` / `SourceInfo` 定義。
- **doc-gen4** (leanprover/doc-gen4): `importModules` ベースの metadata 抽出 (read-only)。本研究の parser 部分とは異なる戦略。
- **`leanprover/lean4-samples`**: 2025 年 archive 済、参照しない。

## Smoketest 結果

詳細: `experiments/lean-ast/parse-smoketest/` (lakefile + ParseSmoketest.lean + sample.lean)

### sample.lean (Init-only imports, 7 commands)

```
$ time lake exe parse-smoketest sample.lean
{
  "file": "sample.lean",
  "headerRange": null,
  "commands": [
    {"kind": "Lean.Parser.Command.declaration", "name": "foo", "range": [36, 51]},
    {"kind": "Lean.Parser.Command.declaration", "name": "bar", "range": [53, 82]},
    {"kind": "Lean.Parser.Command.declaration", "name": "baz", "range": [84, 112]},
    {"kind": "Lean.Parser.Command.declaration", "name": "qux", "range": [114, 139]},
    {"kind": "namespace",                        "name": "Sample", "range": [141, 157]},
    {"kind": "Lean.Parser.Command.declaration", "name": "nested", "range": [159, 193]},
    {"kind": "Lean.Parser.Command.end",          "name": "Sample", "range": [195, 205]}
  ]
}
lake exe parse-smoketest sample.lean  0.16s user 0.25s system 77% cpu 0.529 total
```

### Byte range 正確性検証

```
$ head -c 51 sample.lean | tail -c +37
axiom foo : Nat
```
→ range `[36, 51]` から取り出した byte が元宣言と完全一致 ✓

### 実 Manifest ファイルでの parse 試験

`Manifest/Axioms.lean` では parse error 多数発生。原因: sample は `Init` のみ import したので、Manifest 側の imports (Mathlib, 内部 notation 等) が未解決で parse に失敗。

**含意**: 実運用 CLI は以下の手順が必要:
1. `parseHeader` で対象ファイルの `import` 宣言を取得
2. `importModules` でそれら依存を Environment に load
3. その Environment で `parseCommand` ループ

この「header-aware import resolution」は Sub-D (#659) の startup cost 計測対象。

## 未検証で残った項目

- Elaborator API の実コード呼び出し (Sub-E に委譲)
- `testParseFile` の命名 ("test" prefix) が将来 API 変更対象になる可能性 → 変更されたら `parseHeader` + `parseCommand` の自作 loop で代替可能 (同関数の実装は 15 行程度)
- 複数 `.lean` ファイルを batch 処理する際の Environment 再利用パターン

## Gate 判定

### Gate 基準 (Sub-Issue #657 より)

> **PASS**: 3 カテゴリ (Parser / Syntax-SourceInfo / Elaborator) 全てで使用例が特定され、サンプルコードで `parse → Syntax → SourceInfo.original range` 取得が動作
>
> **CONDITIONAL**: 3 カテゴリのうち 1 カテゴリで API が experimental / undocumented → 代替案 + 安定化タイミングを記録、追加 sub-issue で継続調査

### 判定: **CONDITIONAL**

| Category | 使用例特定 | smoketest 動作 |
|---|---|---|
| Parser | ✅ `parseHeader` / `parseCommand` / `testParseFile` 全て特定 | ✅ sample.lean parse 成功 |
| Syntax/SourceInfo | ✅ `Syntax.getRange?`, `SourceInfo.getRange?` 特定、byte-level 検証 | ✅ range `[36, 51]` が byte 単位で一致 |
| Elaborator | ✅ `Lean.Elab.Command.elabCommand` (stable) 特定、Lean 本体 `Elab/Frontend.lean` line 66 で使用例確認 | ⏸ **runtime smoketest 未実施** |

**理由**: Parser + SourceInfo は smoketest で byte-level 一致まで検証済。Elaborator は Lean 本体で stable API として使われていることは確認済だが、本 Sub-B の sample には elaborate パスが含まれず、runtime で call 検証が未完了。Gate PASS 基準は「3 カテゴリ全てで smoketest 動作」を明示しているため、厳密読みで CONDITIONAL に分類。

### CONDITIONAL の stabilization 計画

**Elaborator 検証の fork 先**: Sub-E (#660) byte-preserving rewrite PoC。

Sub-E は「body 置換後の type check」で `Lean.Elab.Command.elabCommand` を呼び出す必要があり、その際に runtime で Elaborator API が動作することが自然に検証される。Sub-E の Gate PASS が Elaborator 実地動作の stabilization を兼ねる。

**タイミング**: Sub-E の実施時 (Sub-B, Sub-C 完了後の Batch 2)。別 sub-issue の追加は不要 (Sub-E が吸収)。

### Addressable なし (CONDITIONAL 理由を記録した状態で残存 finding ゼロ)

Judge の指摘 (addressable: Elaborator runtime 未検証) は本 CONDITIONAL 分類により解消。Verifier は 0 addressable で PASS 判定だが、Gate 基準の厳密読みで安全側に倒す選択。

### 次のアクション

- **Sub-C (#658)**: lakefile placement 判断。本 smoketest は standalone lakefile で動作 → 同一 lakefile に追加も別 package も技術的に可能
- **Sub-E (#660)**: byte-preserving rewrite PoC。本研究の `getRangeWithTrailing?` + byte-level slice 戦略が使える。**加えて** Elaborator runtime smoketest を本 Sub-E の scope に含める (CONDITIONAL fork)
- **Sub-D (#659)**: startup cost 計測。Init-only で 0.16s user、Manifest imports 込みでどう変化するかが本 PoC の延長で計測可能
