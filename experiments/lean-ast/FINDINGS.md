# Lean AST CLI 実現可能性調査 (2026-04-23)

## Question

Claude Code の Edit tool は編集時に file 全体を context に読み込むため、JSON/YAML/TOML/CSV については jq/yq/dasel/mlr が context 効率で優位。**Lean 4 ファイルに対しても同様の構造的 CLI を導入できるか？**

目標: **Read/Write 代替として使うには 100% parse 成功が必須**（partial coverage は fallback 判断が困難で導入価値を失う）。

## 方法

- ast-grep に tree-sitter-lean ([Julian/tree-sitter-lean](https://github.com/Julian/tree-sitter-lean), 最後の実質 commit 2024-09-01) を custom language として登録
- `src/parser.c` + `src/scanner.c` を `cc -shared -fPIC -O2` で dylib 化 (macOS arm64)
- `sgconfig.yml` で lean を登録、expandoChar に Greek letter `μ` を採用 (Lean identifier regex の `[Ͱ-Ͽ]` に該当)
- pattern 例: `axiom μN : μT` で全 axiom 宣言を query

再現手順は `./sgconfig.yml` と以下:

```bash
git clone https://github.com/Julian/tree-sitter-lean.git
cd tree-sitter-lean
cc -shared -fPIC -O2 -I src src/parser.c src/scanner.c -o lean.dylib
cd .. && sg run --config sgconfig.yml --lang lean -p 'axiom μN : μT' /path/to/Manifest/
```

## 結果

### Axiom 捕捉率 (grep 基準 vs ast-grep)

| file | grep | ast-grep | ratio |
|---|---|---|---|
| Axioms.lean | 13 | 13 | 100% |
| ConformanceVerification.lean | 3 | 3 | 100% |
| EmpiricalPostulates.lean | 4 | 4 | 100% |
| ObservableDesign.lean | 16 | 16 | 100% |
| Ontology.lean | 1 | 1 | 100% |
| AxiomQuality.lean | 1 | 0 | 0% |
| EvolveSkill.lean | 1 | 0 | 0% |
| **FormalDerivationSkill.lean** | **17** | **0** | **0%** |
| **合計 (Manifest/)** | **57** | **38** | **67%** |

### 破綻箇所の特定

FormalDerivationSkill.lean を binary search:

- 1-230 行: ✅ 通る
- 1-250 行: ❌ 以降 cascade 破綻
- 1-300 行: ✅ 一時回復
- 1-330 行: ❌ 破綻
- 1-340 行: ✅ 回復
- 1-355 行: ❌ 以降 recover せず最後まで全滅

**振動パターン**から、単一の breaker ではなく、parse recovery が**特定の tactic proof 構文で再同期に失敗**し以降の宣言が ERROR ノードに吸収されていると推定。

### 犯人候補

```lean
theorem procedure_has_four_phases :
  ∀ (p : Phase),
    p = .leanConstruction ∨ p = .derivation ∨
    p = .correctionLoop ∨ p = .audit := by
  intro p; cases p <;> simp
```

- **`<;>` tactic combinator**: Lean 4 で 全 tactic proof 必須
- **multi-line type signature**: 長い命題で一般的
- **`.leanConstruction` anonymous constructor**: Lean 4 idiomatic
- **multi-clause `∨` with line break**: 複雑命題で不可避

単独で切り出して parse すると通るが、**前後の文脈**と組み合わさると cascade 破綻する挙動。

## Linter 抱き合わせ案の評価

「linter で壊す構文を ban すれば (A) が 100% に」という hybrid 案を検討したが不成立:

| 構文 | ban 可能性 | 理由 |
|---|---|---|
| `<;>` tactic combinator | ❌ | proof 書き分けの基本ツール |
| multi-line type sig | ❌ | 論理式が長いと不可避 |
| Unicode `∀`/`∨`/`→` | ❌ | Mathlib/stdlib 標準 |
| `.member` anonymous ctor | ❌ | Lean 4 idiomatic |

**壊しているのはオプショナルな advanced 機能ではなく日常構文**。linter で ban すると Lean として成立しない。

notation/macro_rules のような真の advanced 機能なら linter 抑止は可能だが、tree-sitter-lean の現実の失敗はそれよりずっと手前で起きている。

## 結論

- **(A) ast-grep + tree-sitter-lean: 不採用**
  - 100% coverage 要件を満たせない
  - linter hybrid でも成立しない (壊れ元が essential 構文)
  - tree-sitter は原理的に Lean の `notation`/`syntax`/`macro_rules` を完全 parse 不能
- **(B) Lean metaprogram CLI**: 100% 保証の唯一の path
  - Lean 本体の parser (`Lean.Parser` / `Lean.Elab`) を使うので構造上 100%
  - 投資コスト: 数日〜数週間（lake exe 化、JSON 入出力、edit primitive 設計）
- **短期方針**: Lean files は Edit/Write のまま。JSON/YAML/TOML/CSV は jq/yq/dasel/mlr (CLAUDE.md 既存ルール)

## 成果物

- `sgconfig.yml` — ast-grep custom language 設定（再現用）
- `.gitignore` — tree-sitter-lean upstream と dylib を除外

tree-sitter-lean 側へ grammar 改善 PR を送る選択肢もあるが、Lean 4 の動的構文拡張に追随するには upstream のメンテナンス負担が恒久的に生じる。投資対効果として (B) 自作の方が効率的。
