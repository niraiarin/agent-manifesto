# Lean Doc Comment Style Guide

Verso 自動生成パイプラインが正しい HTML を出力するために、
Lean doc comment が満たすべきフォーマット標準。

**設計原則**: 各ルールは Verso の制約から逆算して導出されている。
ルールの根拠は「Verso のパーサー/レンダラーがどう動くか」であり、
「現在の Lean ファイルがどうなっているか」ではない。

## 1. 見出し（Headings）

### Verso の動作

`#doc (Manual) "Title" =>` が `h1` を生成する。
以降、doc comment 内の `#` = `h2`, `##` = `h3`, `###` = `h4`。
各見出しは `<section>` を生成し、URL フラグメント（アンカー）を持つ。

見出しテキストはスラグ化される（`Slug.lean:asSlug`）:
- ASCII 英数字 + `_-` のみ保持
- **CJK/Unicode は全て `___` に置換**
- 同一スラグは "Duplicate tag" ビルドエラー

| ルール | Verso 制約 | 根拠 |
|--------|-----------|------|
| H1: 各ファイルの最初の `/-!` は `#` で開始 | `#` = `h2`（`#doc` の `h1` の次）。`##` で始めると `h3` になり階層が飛ぶ | Html.lean: sub-parts increment headerLevel by 1 |
| H2: モジュール doc 内の見出しは `#` と `##` のみ | `###` = `h4` 以降は可読性が急落。Verso UI のサイドバー TOC は 2-3 階層が最適 | Html.lean: nested Parts |
| H3: 見出しに ASCII の区別文字を含める | CJK 文字は全て `___` に置換されるため、**同一文字数の CJK 見出しはスラグが衝突する**。`## L1 安全境界` と `## L2 脅威認識` は ASCII 部分 (`L1`, `L2`) で区別される。`## 安全境界` (4文字) と `## 脅威認識` (4文字) は同一スラグになる | Slug.lean: asSlug + mangle。特殊文字 (`<>()→⊢` 等) は名前付き置換 (`_LT_` 等)、その他の非 ASCII は `___` |
| H4: 宣言 doc comment (`/-- -/`) 内に見出しを書かない | 見出しは新しい `Part` を作り、後続の宣言をその子に飲み込む | Parser.lean: `#` starts new Part |
| H5: Lean doc comment は全て英語で書く。見出しに `:()§—–₀` を含めない | Verso の sluggify は非 ASCII を `___`、`:` を `_COLON_`、`()` を `_LPAR__RPAR_` に変換し URL が不可読になる。形式仕様は英語が標準 | Slug.lean: asSlug + mangle |

### 正しい例

```lean
/-!
# Axioms T1-T8: Base Theory

## T1 セッションの一時性

...

## T2 構造の永続性

...
-/
```

### 誤った例

```lean
/-!
## 設計方針        ← H1 違反: 最初の見出しが ## (#=h2 を飛ばして h3)
### 詳細           ← H2 違反: ### 使用
## 遵守義務        ← H3 違反: CJK のみ（他の CJK 4文字見出しと衝突）
-/

/-- ## Session     ← H4 違反: 宣言 doc 内に見出し
    Encodes T1. -/
structure Session where ...
```

## 2. アンダースコアと強調

### Verso の動作

`_text_` → `<em>`（イタリック）、`*text*` → `<strong>`（ボールド）。
**シングル** デリミタ。Markdown の `**bold**` ではない。

`generate-verso-source.py` が `**bold**` → `*bold*` に自動変換する。
bare `_` は emphasis トリガーとなり、コードブロック内でもパースされうる。

| ルール | Verso 制約 | 根拠 |
|--------|-----------|------|
| U1: Lean 識別子にアンダースコアを含む場合、必ずバッククォートで囲む | bare `session_bounded` → `_bounded` が emphasis 開始と誤認される | Parser.lean:288-299: `_` is inline special |
| U2: 強調には `**bold**` を使う（`*bold*` ではない） | スクリプトが `**` → `*` に変換。doc comment 内で `*text*` と書くと Lean コメント内の `*` と衝突する可能性がある | Markdown 慣習との互換 |
| U3: `_emphasis_` を使わない | スクリプトの自動エスケープが `_word_` をバッククォート化し意図と異なる出力になる | escape_verso_special の動作 |

### 正しい例

```lean
/-- `session_bounded` 公理は **T1** の形式化。
    `no_cross_session_memory` も参照。 -/
```

### 誤った例

```lean
/-- session_bounded 公理は *T1* の形式化。
    _no_cross_session_memory_ も参照。 -/
```

## 3. テーブル

### Verso の動作

Verso は Markdown パイプテーブル構文を持たない。
`:::table +header` ディレクティブのみ（Table.lean）。

`generate-verso-source.py` が Markdown テーブル → `:::table` に変換する。
変換には: (1) ヘッダ行、(2) セパレータ行、(3) データ行 の3部構成が必要。

| ルール | Verso 制約 | 根拠 |
|--------|-----------|------|
| T1: Markdown パイプテーブルを使う（Verso 記法は書かない） | スクリプトが変換する。Verso 記法を直接書くとダブル変換される | generate-verso-source.py の変換ロジック |
| T2: テーブルの前後に空行を置く | 空行がないと前後のテキストとマージされ、パイプ検出 regex が失敗する | regex: `r'\s*\|.*\|'` |
| T3: セパレータ行は各列最低 3 ハイフン (`---`) | 短すぎるとテーブルとして認識されない可能性 | 標準 Markdown 慣習 |
| T4: セパレータ行だけを単独で書かない | `\|---\|` は `is_ascii_art_line()` にマッチし、コードブロック化される | ASCII art 検出との競合 |

## 4. 宣言 doc comment の配置

### Verso の動作（正確にはスクリプトの動作）

`generate-verso-source.py` は以下の regex で doc comment を抽出する:
```
/\-\-(.*?)\-/\s*\n(keyword\s+[^\n]+)
```
`-/` の直後の行に宣言キーワードが来ることを要求する。

| ルール | 制約 | 根拠 |
|--------|------|------|
| P1: `-/` と宣言キーワードの間に空行を置かない | 空行があると regex がマッチせず、宣言が文書から**無言で脱落**する | Pattern 1 regex |
| P2: `/--` の前に空行を置く（トップレベル宣言） | 前のコードブロックや文と区別するため | 可読性 + パーサー安定性 |
| P3: structure/inductive 内のフィールド doc comment は空行不要 | フィールド間に空行を入れると Lean の構文が崩れる | Lean 構文の制約 |

### 正しい例

```lean
-- 前の宣言

/-- セッションの状態。T1 により必ず終了する。 -/
inductive SessionStatus where
  /-- アクティブなセッション -/
  | active
  /-- 終了したセッション -/
  | terminated
```

### 誤った例

```lean
/-- セッションの状態。 -/

inductive SessionStatus where   ← P1 違反: -/ と inductive の間に空行
```

## 5. 特殊文字

### Verso の動作

`[text]` → リンク構文、`{name}` → ディレクティブ構文として Verso がパースする
（Parser.lean:299）。

| ルール | Verso 制約 | 根拠 |
|--------|-----------|------|
| S1: `[]` や `[text]` はバッククォートで囲む | `[text]` は Verso リンクとしてパースされる | Parser.lean |
| S2: `{}` はバッククォートで囲む | `{text}` は Verso ディレクティブとしてパースされる | Parser.lean |

### 正しい例

```lean
/-- リスト `[s]` 内のセッション。`{ctx}` はコンテキスト。 -/
```

## 6. コードブロック

### Verso の動作

` ``` ` で囲まれたコードブロック内では `_` は emphasis として**解釈されない**。
コードブロック内の内容は raw テキストとして扱われる（検証済み）。

したがって、**コードブロック内のアンダースコア識別子にエスケープは不要**。
バッククォートで囲むと `<pre>` 内にバッククォートがそのまま表示される。

| ルール | Verso 制約 | 根拠 |
|--------|-----------|------|
| C1: コードブロック内の識別子をエスケープしない | ` ``` ` 内は raw テキスト。バッククォートで囲むと `<pre>` に漏れる | Parser.lean: fenced block は inline parsing をスキップ |
| C2: ASCII art ダイアグラムは明示的に ` ``` ` で囲む | 自動検出に頼らない（box-drawing 文字のみ検出で ASCII `+\|-` は検出しない） | is_ascii_art_line の制限 |

## 7. 公理カード（プロジェクト固有）

Verso の制約ではなく、プロジェクトのメタデータ抽出の一貫性のための規約。

| ルール | 根拠 |
|--------|------|
| A1: manifesto 由来の axiom（T1-T8, E1-E2）は `[公理カード]` で始める。形式化固有の axiom は対象外 | メタデータ抽出の識別子 |
| A2: 必須フィールド: 所属, 内容, 根拠, ソース, 反証条件 | 全公理カードで同一構造を保証 |
| A3: T₀ の反証条件は `適用なし (T₀)` | フィールドの存在/不在でパーサーが分岐しないようにする |

## ルール一覧

| ID | ルール | 重大度 | 自動検出 |
|----|--------|--------|---------|
| H1 | 最初の `/-!` は `#` で開始 | Error | Yes |
| H2 | モジュール doc 内の見出しは `#` と `##` のみ | Error | Yes |
| H3 | 見出しに ASCII 区別文字を含める | Error | Yes（スラグ衝突検出） |
| H4 | 宣言 doc 内に見出しを書かない | Error | Yes |
| U1 | アンダースコア識別子はバッククォート | Warning | Partial |
| U2 | 強調は `**bold**` | Warning | No |
| T1 | Markdown テーブル使用 | Info | No |
| T2 | テーブル前後に空行 | Warning | Partial |
| T3 | セパレータ 3 ハイフン以上 | Warning | Yes |
| T4 | セパレータ単独禁止 | Error | Yes |
| P1 | `-/` と宣言の間に空行なし | Error | Yes |
| P2 | `/--` の前に空行（トップレベル） | Warning | Yes |
| P3 | フィールド doc は空行不要 | Info | No |
| S1 | `[]` をバッククォート | Warning | Partial |
| S2 | `{}` をバッククォート | Warning | Partial |
| H5 | 英語で書く。見出しに `:()§—–₀` を含めない | Error | Yes |
| C1 | コードブロック内の識別子をエスケープしない | Error | Yes |
| C2 | ASCII art は明示的にコードブロック | Warning | No |
| A1 | axiom は `[公理カード]` で始める | Warning | Yes |
| A2 | 公理カード 5 フィールド必須 | Warning | Yes |
| A3 | T₀ 反証条件は `適用なし` | Warning | Yes |
