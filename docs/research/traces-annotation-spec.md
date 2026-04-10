# @traces アノテーション仕様

## 概要

`@traces` はファイルと命題 (PropositionId) の対応関係を機械判読可能な形式で宣言するアノテーション。
artifact-manifest.json の `refs` が宣言的な対応を定義するのに対し、`@traces` はファイル内容レベルで
「このファイルのこの部分がこの命題を実装/検証/準拠している」ことを明示する。

## フォーマット

### Markdown ファイル (SKILL.md, AGENT.md, rules/*.md)

```markdown
<!-- @traces P3, D9, T2 -->
```

HTML コメント内に記述。ファイルの先頭（frontmatter の直後）に 1 行で記載する。

### シェルスクリプト (hooks/*.sh, scripts/*.sh)

```bash
# @traces L1, T6, D1
```

シェルコメント内に記述。ファイルヘッダコメントの一部として記載する。

### テストファイル

テストファイルは `tests/trace-map.json` で管理する。`@traces` は補助的に使用可能だが、
`trace-map.json` が正（Single Source of Truth）。

## 文法

```
ANNOTATION := PREFIX SEPARATOR "@ traces" SPACE PROP_LIST
PREFIX     := "#" | "<!--"
SEPARATOR  := SPACE
SPACE      := " "+
PROP_LIST  := PROP_ID ("," SPACE? PROP_ID)*
PROP_ID    := [TEPLVD] [0-9]+
```

有効な PropositionId: T1-T8, E1-E2, P1-P6, L1-L6, D1-D18, V1-V7 (計 47 個)

## パース規則

1. 行頭の `#` または `<!--` に続く `@traces` キーワードを検出
2. `@traces` に続く命題 ID リストをカンマ区切りで分割
3. 各 ID を大文字正規化
4. 有効な PropositionId でないものは無視（警告を出力）

## 制約

- 1 ファイルにつき `@traces` 行は 1 つ（複数ある場合は全てマージ）
- `artifact-manifest.json` の `refs` と `@traces` は一致すべき（#371 hook で検証）
- `@traces` のない artifact は `refs` 未検証として層 4 カバレッジから除外

## 関連

- `artifact-manifest.json` の `refs`: 成果物→命題の宣言的対応（層 2）
- `tests/trace-map.json`: テスト→命題の JSON 対応（層 2）
- `@traces`: ファイル内容レベルの明示的対応（層 4）
