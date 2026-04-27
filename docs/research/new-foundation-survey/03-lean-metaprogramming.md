# 03. Lean 4 メタプログラミング・DSL 設計（グループ C）

**作成日**: 2026-04-17
**著者**: Survey Group C agent
**目的**: agent-manifesto 新基盤（Lean 文書を canonical とする研究プロセス記録）の設計に向けて、Lean 4 で研究 tree DSL を設計・拡張する際の確立されたパターンを精読・整理する。
**スコープ**: TyDD 一般理論は `research/survey_type_driven_development_2025.md` で cover 済。本章は **Lean 4 固有のメタプログラミング/DSL 実装パターン**（macro/elab/syntax、tactic framework、build system 統合、文書 DSL、JSON IPC）に集中する。
**前提資産**:
- `~/work/high-tokenizer/lean/SpecSystem/Basic.lean`（62 行 0 sorry の TypeSpec / FuncSpec / 精緻化半順序）
- `lean-formalization/Manifest/`（55 axioms, 1670 theorems, 0 sorry — 2026-04-17 実測）
- `Spec = (T, F, ≤, Φ, I)` という設計枠組み

---

## 目次

- Section 1: 各対象の精読ノート
  - 1.1 Lean 4 macro / syntax / elab（公式 Metaprogramming book）
  - 1.2 mathlib4 メタプログラミングパターン（norm_cast、attribute extension）
  - 1.3 ProofWidgets4（tactic 状態の対話的 UI、JSON RPC）
  - 1.4 Verso（Lean 文書 DSL、genre アーキテクチャ）
  - 1.5 doc-gen4（自動 API 文書生成）
  - 1.6 Aesop（拡張可能ルールベース証明探索）
  - 1.7 Duper / Lean-Auto（飽和証明と外部 ATP ブリッジ）
  - 1.8 Lake（Lean ビルドシステム、custom target、facet）
- Section 2: 比較表（10 観点 × 全対象）
- Section 3: 横断的な発見
- Section 4: 新基盤への適用可能性
- Section 5: 限界と未解決問題

---

## Section 1: 各対象の精読ノート

### 1.1 Lean 4 macro / syntax / elab（公式 Metaprogramming book）

**主要出典**:
- Metaprogramming in Lean 4 book: <https://leanprover-community.github.io/lean4-metaprogramming-book/>
- Overview: <https://leanprover-community.github.io/lean4-metaprogramming-book/main/02_overview.html>
- Syntax 章: <https://leanprover-community.github.io/lean4-metaprogramming-book/main/05_syntax.html>
- Macros 章: <https://leanprover-community.github.io/lean4-metaprogramming-book/main/06_macros.html>
- DSLs 章: <https://leanprover-community.github.io/lean4-metaprogramming-book/main/08_dsls.html>
- MetaM 章: <https://leanprover-community.github.io/lean4-metaprogramming-book/main/04_metam.html>
- Tactics 章: <https://leanprover-community.github.io/lean4-metaprogramming-book/main/09_tactics.html>

#### 階層構造（4 つのモナド）

書籍は Lean 4 メタプログラミングを 4 つのモナドの hierarchy として整理する:

| モナド | 提供する能力 | 主な用途 |
|--------|-------------|---------|
| `CoreM` | 環境（declarations, imports）アクセス | 型情報なしの宣言操作 |
| `MetaM` | metavariable context、`isDefEq`、`whnf`、`reduce` | 型推論、unification、normalization |
| `TermElabM` | `Syntax → Expr` 変換、elaboration info | 項の意味付け |
| `TacticM` | `ReaderT Context $ StateRefT State TermElabM`、ゴールリスト | 証明状態の操作 |

階層的拡張なので `MetaM` の操作は `CoreM` の能力も利用でき、`TacticM` は `TermElabM` を経由して `MetaM`/`CoreM` の能力にアクセスできる。

#### syntax / macro / elab の選択基準

書籍は明確な指針を提供する:

> "as soon as types or control flow is involved a macro is probably not reasonable anymore."

つまり:

- **`syntax` 単独**: 字句的な記法の追加のみ（precedence、結合性指定）
- **`macro` / `macro_rules`**: 純粋な構文書き換え（type-directed でない）。`Syntax → MacroM Syntax`
- **`elab` / `elab_rules`**: 型情報、型推論、副作用（環境への登録、metavariable 操作）が必要

elaboration pipeline は 3 ステップで構成される:

1. **Parsing**: ソース文字列を syntax rule にマッチして `Syntax` 抽象構文木を生成
2. **Macro expansion**: 登録された macro が消えるまで反復的に `Syntax` を変換
3. **Elaboration**: 1 回の elab 関数が最終 `Syntax` を `Expr` に変換

#### 最小例: マクロでの新記法定義

```lean
macro l:term:10 " ⊕ " r:term:11 : term => `((!$l && $r) || ($l && !$r))
```

#### 最小例: optional splice を用いる let 拡張（hygiene 込）

```lean
syntax "mylet " ident (" : " term)? " := " term " in " term : term

macro_rules
  | `(mylet $x $[: $ty]? := $val in $body) => `(let $x $[: $ty]? := $val; $body)

#eval mylet x := 5 in x - 10  -- 0
```

ここで `$[: $ty]?` は optional splice、`$x:term` は category-tagged anti-quotation。`TSyntax` 型による型安全性が保証される。

#### 最小例: カスタム tactic（hypothesis から goal に一致するもの探索）

```lean
elab "custom_assump" : tactic =>
  Lean.Elab.Tactic.withMainContext do
    let goalType ← Lean.Elab.Tactic.getMainTarget
    let ctx ← Lean.MonadLCtx.getLCtx
    let matchingExpr ← ctx.findDeclM? fun decl => do
      let declType ← Lean.Meta.inferType decl.toExpr
      if ← Lean.Meta.isExprDefEq declType goalType
        then some decl.toExpr else none
    match matchingExpr with
    | some e => Lean.Elab.Tactic.closeMainGoal `custom_assump e
    | none => Lean.Meta.throwTacticEx `custom_assump goal m!"No matching hypothesis"
```

#### compile-time 検証

書籍は明確に述べる:

> "Lean provides no special compile-time guarantees for meta-level code. ... use the `partial` keyword when convinced termination holds, accepting that 'our function gets stuck in a loop, causing the Lean server to crash.'"

すなわち **メタコードそのもの** には特別な保証はない。一方、メタコードが生成する **対象コード** には Lean 本体の型検査が完全に効く。これは agent-manifesto 新基盤にとって重要: 研究 tree DSL を `elab` で `Expr` に変換すれば、tree 全体が Lean の型検査対象となる。

#### Hygiene（マクロ衛生）

`MonadQuotation` が macro scope を自動付与し、ユーザ変数の意図せざる shadowing を防ぐ:

> Generated names follow the pattern: `<name>._@.(<module>.<scopes>)*._hyg.<scopes>`

意図的に hygiene を破る場合は `mkIdent` を使う:

```lean
`(def $(mkIdent `foo) := 1)
```

#### 学習曲線

書籍は中級者向け（Lean 基礎知識前提、"Functional Programming in Lean" 推奨）。章間の依存関係あり: Expressions → MetaM → Syntax → Macros → Elaboration → DSLs → Tactics の順。

---

### 1.2 mathlib4 メタプログラミングパターン（norm_cast を例に）

**主要出典**:
- `Lean.Meta.Tactic.NormCast`: <https://leanprover-community.github.io/mathlib4_docs/Lean/Meta/Tactic/NormCast.html>
- mathlib4 wiki "Metaprogramming for dummies": <https://github.com/leanprover-community/mathlib4/wiki/Metaprogramming-for-dummies>
- `Mathlib.Tactic.NormNum.Core`: <https://leanprover-community.github.io/mathlib4_docs/Mathlib/Tactic/NormNum/Core.html>
- `Mathlib.Tactic.Simps.Basic`: <https://leanprover-community.github.io/mathlib4_docs/Mathlib/Tactic/Simps/Basic.html>

#### attribute による拡張可能 simp set

`norm_cast` は **環境拡張（environment extension）** に複数の simp set を保持し、`@[norm_cast]` attribute 経由でユーザがルールを宣言的に追加できるパターンの代表例:

```
structure NormCastExtension : Type where
  up : SimpExtension      -- coercion を上へリフト
  down : SimpExtension    -- coercion を葉へ押し下げ
  squash : SimpExtension  -- 推移的 coercion を圧縮
```

`Label` 列挙型でルールを 3 種に分類:

- `elim`: LHS に head coe が 0、internal coe が 1 以上
- `move`: LHS に head coe が 1、internal coe が 0、RHS に head coe が 0、internal coe が 1 以上
- `squash`: LHS に head coe が 1 以上、internal coe が 0、RHS に head coe がより少ない

API は 4 関数:

- `addElim` / `addMove` / `addSquash`: 明示的カテゴリ指定
- `addInfer`: 構造から自動分類

`AttributeKind := AttributeKind.global` がデフォルトで、global 環境への登録が成立する。

#### simp の役割

3 種それぞれが `SimpExtension` として保持され、simp の rewrite インフラを再利用する。これは「特化したサブシステムを `simp` の上に薄く構築する」パターンの典型。

#### 適用可能性

新基盤での適用例: 「研究ノードの分類タグ」（survey, gap, hypothesis, decomposition, implementation）を `@[research_node]` attribute で宣言し、environment extension に集約。`/trace` skill 相当の処理が environment を一覧するだけで完結する。

---

### 1.3 ProofWidgets4（tactic 状態の対話的 UI、JSON RPC）

**主要出典**:
- GitHub: <https://github.com/leanprover-community/ProofWidgets4>
- API: <https://leanprover-community.github.io/mathlib4_docs/ProofWidgets/Component/Panel/Basic.html>
- Lean 公式 widgets 例: <https://lean-lang.org/examples/1900-1-1-widgets/>
- Nawrocki paper: <https://voidma.in/assets/papers/23nawrocki_extensible_user_interface_lean_4.pdf>
- Ayers thesis Ch.5: <https://www.edayers.com/thesis/widgets>

#### アーキテクチャ

ProofWidgets は Lean 4 の組み込み user widget 機構の上に構築されたコンポーネントライブラリ。リポジトリは TypeScript（`widget/`）と Lean（`ProofWidgets/`）の二部構成:

> "include_str term elaborator to splice the minified JavaScript produced during the build (by tsc and Rollup) into ProofWidgets Lean modules."

すなわち TypeScript ソースを minify した JS を **Lean ソース内に文字列として埋め込み**、term elaborator が build artifact を Lean term に変換する。これは「外部 build 成果物を Lean ソースに inject する」パターン。

#### JSON RPC による IPC

> "An RPC is a Lean function callable from widget code (possibly remotely over the internet). By convention, the input data is represented as a structure, and since it will be sent over from JavaScript, FromJson and ToJson instances are needed."

infoview と server を分離するため:

- 入出力は `FromJson` / `ToJson` instance を持つ Lean structure
- `deriving FromJson, ToJson` で自動導出可能
- SSH / Gitpod 越しの remote 実行も可能

#### 限界

- Lake issue #86 により widget 1 個変更で全 widget 再ビルド
- TypeScript ツールチェーン依存（tsc, Rollup）
- 学習曲線: Lean + TypeScript + React パターンの 3 重知識が必要

#### 適用可能性

新基盤での「研究 tree の対話的可視化」（depth-tree, refinement DAG, 半順序関係の閲覧）に直接適用可能。`Spec = (T, F, ≤, Φ, I)` を JSON 化し、widget で graph view として表示できる。

---

### 1.4 Verso（Lean 文書 DSL、genre アーキテクチャ）

**主要出典**:
- 公式サイト: <https://verso.lean-lang.org/>
- GitHub: <https://github.com/leanprover/verso>
- Templates: <https://github.com/leanprover/verso-templates>
- Verso 自身による Lean Reference Manual: <https://lean-lang.org/doc/reference/latest/>
- DeepWiki: <https://deepwiki.com/leanprover/verso>

#### コンセプト: "Verso files are Lean files"

Verso は「Lean で書かれ、Lean で型検査される」ドキュメンテーション基盤:

> "Verso is a platform for writing documents, books, course materials, and websites with Lean. Every code example is type-checked. Every rendered page is interactive."

Markdown ライクな具象構文を持つが、parser は通常の Lean parser として実装され、document tree は Lean 型として表現される。Scribble と Sphinx に着想を得ている。

#### Genre アーキテクチャ

Verso は document の種別を **genre** として抽象化する。例:

- Manual（reference manual）
- Textbook（course material）
- Blog
- Mathematical Blueprint

各 genre は共通基盤（rendering, cross-referencing, code integration）を共有しつつ、独自の document model を持てる。Lean の type class / structure system を直接使う:

> "shared foundation for rendering, cross-referencing, and code integration, without requiring a single core model."

実例: Theorem Proving in Lean、Functional Programming in Lean、Mathematics in Lean、Lean reference manual / users' manual のすべてが Verso で記述。

#### 拡張モデル: ordinary Lean functions

> "Extensions are ordinary Lean functions, not a separate plugin system or templating language."

新しい block type、command、anchor 等を Lean function として実装する。例: `-- ANCHOR: XYZ` ... `-- ANCHOR_END: XYZ` で囲まれた Lean コードを document に埋め込み、同時にスタンドアロンファイルとしても export できる "extraction pass" を Manual genre に追加できる。

#### 出力フォーマット

主に HTML（hover, definition link, search, rendered proof state を含む experimental Lean-to-HTML renderer）。PDF 出力は明記なし。

#### 状態とリスク

> "currently undergoing change at a rapid pace"
> Cross-document cross-references は experimental
> Manual は in-progress

ただし Lean 公式チームが推進し、Lean reference manual 自身が Verso で記述されているため、stability は中期的に向上する見込み。

#### 適用可能性

新基盤の Survey / Gap / Hypothesis ドキュメントを Verso の genre として実装すれば、(a) 全コード例が Lean 型検査される、(b) `Spec = (T, F, ≤, Φ, I)` への cross-reference が型安全、(c) HTML 出力で interactive 閲覧、が同時に得られる。

---

### 1.5 doc-gen4（自動 API 文書生成）

**主要出典**:
- GitHub: <https://github.com/leanprover/doc-gen4>
- README: <https://github.com/leanprover/doc-gen4/blob/main/README.md>
- DeepWiki: <https://deepwiki.com/leanprover/doc-gen4/1-overview>

#### 機能

doc-gen4 は Lean 4 environment を解析し、宣言とそのメタデータを抽出して HTML を生成:

- 検索（`/find` endpoint）
- ホバー
- ソースリンク（`DOCGEN_SRC` 環境変数で github / local / vscode に切替可能）
- cross-reference（mathlib の `docs#Nat.add` 形式リンクを解決）

#### 起動方法

`docbuild/` という nested Lake project を作成し、その中で:

```bash
lake build YourLibraryName:docs
```

成果物は `docbuild/.lake/build/doc/index.html`。Same-origin policy のため `python3 -m http.server` 等で配信が必要。

#### docstring

> "In Lean 4, doc comments are a first class part of the syntax, so you can directly extract it from a declaration source."

`/-! ... -/` (module-level) と `/-- ... -/` (declaration-level) が AST レベルで保持される。

#### Verso との比較

doc-gen4 は **API リファレンス自動生成**に特化（コードから文書）。Verso は **手書き文書**（コードと共著）。両者は補完関係: Verso 文書から doc-gen4 ページへの hyperlink が可能（mathlib では実証済）。

#### 適用可能性

新基盤の axiom / theorem / Spec への自動 API 文書を doc-gen4 で生成し、Verso の survey 文書からリンク。研究 tree の **末端ノード**（実装）を Lake target として定義すれば、変更追跡と文書再生成が自動化される。

---

### 1.6 Aesop（拡張可能ルールベース証明探索）

**主要出典**:
- GitHub: <https://github.com/leanprover-community/aesop>
- README: <https://github.com/leanprover-community/aesop/blob/master/README.md>
- Frontend tactic: <https://leanprover-community.github.io/mathlib4_docs/Aesop/Frontend/Tactic.html>
- RuleSet: <https://leanprover-community.github.io/mathlib4_docs/Aesop/RuleSet.html>
- CPP 2023 paper: <https://dl.acm.org/doi/10.1145/3573105.3575671>
- PDF: <https://people.compute.dtu.dk/ahfrom/aesop-camera-ready.pdf>

#### 設計

> "Aesop performs a tree-based search over a user-specified set of proof rules, supports safe and unsafe rules, and uses a best-first search strategy with customisable prioritisation."

3 つのルールフェーズ:

1. **Normalisation rules**（`norm`）: penalty 順、subgoal は 0 または 1。`simp`, `unfold` 等の builder
2. **Safe rules**（`safe`）: 決定論的、適用後 backtrack なし。`constructors`, `cases`, `forward`, `destruct`
3. **Unsafe rules**（`unsafe`）: backtrack 可能、success probability（0-100%）必須。`apply` builder

#### attribute 構文

```
@[aesop <phase>? <priority>? <builder>? (rule_sets := [...])?]
```

複数ルール一括登録:

```
@[aesop unsafe [constructors 75%, cases 90%]]
inductive T ...
```

#### カスタム rule set

```
declare_aesop_rule_sets [r₁, ..., rₙ]
```

呼び出し時に動的調整も可能:

```
aesop (add safe foo, 10% cases Or) (erase A) (rule_sets := [A, B])
```

#### 適用可能性

新基盤で「研究 tree の精緻化探索」（hypothesis から spec へ詰める一連の判断を rule として登録、tree 探索で自動化）に応用可能。`@[research_step]` attribute を独自に作り、Aesop パターンの **safe / unsafe / norm 三層分類** をそのまま再利用するのが最も低コスト。

---

### 1.7 Duper / Lean-Auto（飽和証明と外部 ATP ブリッジ）

**主要出典**:
- Duper: <https://github.com/leanprover-community/duper>
- Lean-Auto: <https://github.com/leanprover-community/lean-auto>
- Duper paper (ITP 2024): <https://drops.dagstuhl.de/storage/00lipics/lipics-vol309-itp2024/LIPIcs.ITP.2024.10/LIPIcs.ITP.2024.10.pdf>
- Lean-Auto paper: <https://arxiv.org/pdf/2505.14929>

#### Duper

Lean 4 で書かれた superposition-based saturation prover。Lean の axiomatic foundation で直接 proof を生成。

```
duper [facts] {options}
```

- `portfolioInstance`: 0-24
- `portfolioMode`: true/false
- `preprocessing`: full / monomorphization / no_preprocessing

#### Lean-Auto

Lean 4 と外部 ATP（SMT, TPTP）のブリッジ:

- `set_option auto.smt true` → z3 ≥ 4.12.2 / cvc5 等を起動
- `set_option auto.tptp true` → zipperposition 等
- `set_option auto.native true` → ネイティブ backend

monomorphization が深い型理論を高階論理に翻訳。

#### Duper-Lean-Auto 統合

```lean
import Auto.Tactic
import Duper.Tactic
attribute [rebind Auto.Native.solverFunc] Auto.duperRaw
```

ベンチマークで "Lean-auto + Duper" は 36.6%（Aesop の 31.6% より +5.0%）の問題解決。

#### 拡張モデル

新 backend は次の constant を宣言し attribute で rebind:

```
Array Lemma → Array Lemma → MetaM Expr
```

#### 適用可能性

新基盤に **直接的な必要性は薄い**（agent-manifesto は SMT ベース証明を主用途としない）。ただし `Spec = (T, F, ≤, Φ, I)` の `Φ`（制約）を SMT で検証する pipeline を組む場合、Lean-Auto の attribute-based backend rebind パターンは参考になる。high-tokenizer の Z3 連携と類似。

---

### 1.8 Lake（Lean ビルドシステム）

**主要出典**:
- 公式 README: <https://github.com/leanprover/lean4/blob/master/src/lake/README.md>
- Reference: <https://lean-lang.org/doc/reference/latest/Build-Tools-and-Distribution/Lake/>
- DeepWiki: <https://deepwiki.com/leanprover/fp-lean/6.2-lake-build-system>

#### lakefile

```toml
name = "hello"
version = "0.1.0"
defaultTargets = ["hello"]

[[lean_lib]]
name = "Hello"

[[lean_exe]]
name = "hello"
root = "Main"
```

`lakefile.lean`（Lean DSL）または `lakefile.toml`（宣言的）の 2 形式。

#### Target types

- **Lean library** (`lean_lib`)
- **Binary executable** (`lean_exe`)
- **External library** (`extern_lib`、現在は deprecated。`target` + `moreLinkObjs`/`moreLinkLibs` 推奨)
- **Custom target** (`target «name» := <FetchM (Job α)>`)

カスタム target は IO action なので **任意のコード生成**を build 段階で実行できる。

#### Facets

> "A facet is an element built from another organizational unit."

例: module は olean / ilean / c / o の facet を持つ。library は static / shared facet を持つ。ユーザ定義 facet も可能で `lake build pkg:facet` で起動。

#### 依存関係

```lean
require "leanprover-community" / "mathlib"
```

`lake-manifest.json` に解決後 revision が記録される。`lake update` で更新。Path / Git URL 両対応:

```
from <path>
from git <url> [@ <rev>] [/ <subDir>]
```

#### Incremental build (trace-based)

> "Lake uses traces—a piece of data (generally a hash) which is used to verify whether a given target is up-to-date."

trace は source ファイル、toolchain、imports から導出。一致すれば再ビルドをスキップ。

#### Script

```lean
script greet (args) do
  IO.println "Hello, world!"
  return 0
```

`(args : List String) → ScriptM UInt32` で IO action として実行。

#### 適用可能性

新基盤の "DSL → AST → Lean → SMT → Test → Code" pipeline を Lake で表現:

- **入力**: Survey / Gap / Hypothesis を含む Lean 文書
- **custom target**: DSL を Lean に展開、SMT 検証実行、テスト生成、外部 codegen
- **trace**: source の content hash で incremental build
- **manifest**: `artifact-manifest.json` を `lake-manifest.json` の隣に配置、または同一機構に統合

`extraDepTarget` を使えば package build 前に **任意のコード生成**を実行できるため、研究 tree の deterministic 整合性チェックを build フェーズに移譲可能。

---

## Section 2: 比較表

凡例: ◎ = 強くサポート / 推奨 / 標準パターン、○ = サポート / 利用可能、△ = 限定的サポート、× = 該当なし、― = 文脈外

| 観点 | macro/elab/syntax | mathlib4 (norm_cast) | ProofWidgets4 | Verso | doc-gen4 | Aesop | Duper/Lean-Auto | Lake |
|------|-------------------|----------------------|---------------|-------|----------|-------|------------------|------|
| **1. syntax 拡張パターン** | ◎ 中核機能 | ○ attribute 拡張 | △ 主に runtime | ◎ document DSL | × 自動抽出 | ○ rule attribute | △ tactic syntax のみ | ○ lakefile.lean |
| **2. compile-time 検証** | ◎ Expr 段階 | ◎ simp lemma 検査 | △ runtime panel | ◎ コード例の型検査 | ○ docstring 検査 | △ rule 妥当性 | △ proof 検査 | ○ trace 検査 |
| **3. 型安全 DSL** | ◎ TSyntax | ◎ Label 列挙 | ○ structure + JSON | ◎ document AST | ○ Decl AST | ○ Rule structure | △ Lemma 配列 | ○ Package AST |
| **4. elab メタ計算** | ◎ TermElab/TacticElab | ◎ elab + Meta | ○ user_widget elab | ◎ 拡張は Lean fn | × | ◎ rule elab | ○ tactic elab | △ |
| **5. JSON / IPC** | △ Lean.Json 標準 | × | ◎ RPC 標準 | △ HTML 出力 | △ search index | × | ○ SMT 連携 | △ manifest |
| **6. build system 利用** | × | × | ◎ TypeScript build 統合 | ○ Lake target | ◎ Lake facet | × | × | ◎ 中核 |
| **7. Lean ↔ 外部 双方向** | △ macro+codegen | × | ◎ Lean ↔ JS | ○ Lean ↔ HTML | △ Lean → HTML | × | ◎ Lean ↔ ATP | ◎ Lean ↔ shell/外部 |
| **8. 文書自動生成** | × | × | △ widget UI | ◎ 中核機能 | ◎ 中核機能 | × | × | △ via doc-gen4 |
| **9. 拡張性 (stable API)** | ○ MacroM/TermElabM 安定 | ○ attribute 機構 | ○ widget API | ○ genre API | ○ facet | ◎ rule_sets | ○ rebind attribute | ◎ require/target |
| **10. 学習曲線** | △ 中級〜上級 | △ + simp 知識 | × Lean+TS+React | ○ Markdown 風 | ◎ 設定中心 | ○ tactic 利用者向け | △ ATP 知識 | ○ TOML/Lean DSL |

---

## Section 3: 横断的な発見

### 3.1 設計パターン

#### P1. **「Syntax → Macro → Elab」三段階の責務分離**

公式書籍が明示的に推奨するパターン: 字句的書き換えは macro、型情報を要する変換は elab、純粋な記法のみは syntax。新基盤での意味: 研究ノードの「タグ宣言」は macro で、「依存関係の type-checked 連結」は elab で実装すべき。

#### P2. **Attribute による environment extension の宣言的拡張**

`norm_cast` / `simps` / `aesop` がすべて採用するパターン:

1. `EnvExtension` で集約状態を保持
2. `@[my_attr]` attribute をユーザに公開
3. attribute が呼ばれると EnvExtension に登録
4. 主処理は EnvExtension を一覧して操作

これは「LLM が手で table を保守する」現状からの脱却に **直接的に有効**: `@[research_node]` を書けば自動的に index に登録される。

#### P3. **TypeScript / 外部 build artifact の Lean 文字列埋め込み**

ProofWidgets が採用: `include_str` term elaborator で minify 済 JS を Lean ソース内に取り込む。Lake build が JS を生成し、Lean compile 時に取り込まれる。

新基盤では、研究 tree の visualization、graph view、interactive issue UI を ProofWidgets パターンで構築可能。

#### P4. **Genre-based document architecture**

Verso が採用: 共通基盤（rendering, cross-ref, code integration）の上に複数の document type を構築。Lean type class でポリモルフィズムを実現。

新基盤の Survey / Gap / Hypothesis / Decomposition / Implementation を Verso genre として表現可能。

#### P5. **Trace-based incremental build with content hash**

Lake が採用: hash が一致すれば再ビルドスキップ。これは現行の `artifact-manifest.json` content-addressed approach と整合的。

#### P6. **Backend rebind via attribute（Lean-Auto / Duper）**

`attribute [rebind Auto.Native.solverFunc] Auto.duperRaw` のように、組み込みの拡張点を attribute で差し替える。**デフォルト実装と差し替え** の標準パターン。

### 3.2 ベストプラクティス

- **macro vs elab の境界**: 型を見るなら elab。書き換えだけなら macro
- **`partial def`** はメタコードで頻出（再帰的構文解析）。termination 証明なしで容認
- **`MetaM` の `withLocalDecl` / `forallMetaTelescopeReducing`** で安全に bound variable を扱う（loose bvars を作らない）
- **`isDefEq` を `whnf` 前に呼ぶな**: 必要なら自動で reduction される
- **Hygiene を意図的に破る場合** だけ `mkIdent` を使う
- **Aesop の `safe` rule で metavariable を assign すると 90% に降格**: ルール設計で意識
- **doc-gen4 と Verso は補完関係**: API ref + 手書き文書の両立

### 3.3 避けるべき罠

- **メタコード自体に compile-time guarantee はない**: 無限ループ → Lean server crash
- **macro で `term` を分解しようとする**: type 情報が無いので限界。早めに elab に切り替える
- **Aesop で metavariable を生成する rule を global に登録**: choice point 爆発の原因
- **doc-gen4 を直接ブラウザで開く**: same-origin policy で破綻
- **ProofWidgets の widget 1 個変更で全 widget 再ビルド**: Lake issue #86、開発フロー設計時に注意
- **Verso の cross-document cross-reference は experimental**: 重要な依存にしないか、将来の breaking change を許容
- **Duper の portfolio mode は重い**: 単発 instance 指定で実用化（`duper?` で script 生成）

### 3.4 アーキテクチャ統合戦略

新基盤を以下のレイヤで構成可能:

```
┌─────────────────────────────────────────────────┐
│  Layer 5: Verso 文書（Survey / Gap / Hypothesis）│
│           genre = ResearchGenre                 │
├─────────────────────────────────────────────────┤
│  Layer 4: ProofWidgets（tree / graph / status UI）│
│           JSON RPC + React                      │
├─────────────────────────────────────────────────┤
│  Layer 3: doc-gen4（API ref 自動生成）          │
├─────────────────────────────────────────────────┤
│  Layer 2: 研究 tree DSL（syntax + elab）        │
│           @[research_node] / @[refines]         │
│           EnvExtension に集約                   │
├─────────────────────────────────────────────────┤
│  Layer 1: Lake（custom target、incremental build）│
│           Spec → AST → Lean → SMT → Test → Code │
└─────────────────────────────────────────────────┘
```

---

## Section 4: 新基盤への適用可能性

### 4.1 研究 tree DSL の具体構文（提案）

`Spec = (T, F, ≤, Φ, I)` を骨格とする研究ノード DSL を、Lean 4 上で次のように設計できる:

```lean
import Lean
open Lean Elab Term Meta

-- Research node のカテゴリ列挙（mathlib4 NormCast.Label 風）
inductive ResearchPhase where
  | survey | gap | hypothesis | decomposition | implementation

-- Spec = (T, F, ≤, Φ, I) の Lean 表現（high-tokenizer SpecSystem.Basic と整合）
-- Note: TypeSpec, FuncSpec は high-tokenizer プロジェクト由来の型。
-- 新基盤に統合する際は以下のどちらかで依存を解決:
--   (a) lakefile.lean の `require` に high-tokenizer を追加し、`import SpecSystem.Basic`
--   (b) agent-manifesto 側に同型の型を再定義（移植 62 行）
-- 以下は (a) を前提としたスケッチ。未検証。
structure ResearchSpec where
  phase    : ResearchPhase
  typeSpec : TypeSpec
  funcSpec : Option (Σ A B, FuncSpec A B)
  refines  : List Name             -- 半順序の上位ノード
  phi      : List (Name → Prop)    -- 制約集合 Φ
  artifact : List String           -- I: artifact-manifest 参照
  deriving Inhabited

-- 独自 syntax category
declare_syntax_cat research_node

syntax "node " ident " : " term " refines " "[" ident,* "]" " in " research_node : research_node
syntax "leaf " ident " : " term " satisfies " term : research_node

-- term への接続
syntax "[research|" research_node "]" : term

-- Environment extension（norm_cast パターン踏襲）
initialize researchExt : SimplePersistentEnvExtension Name (Array Name) ←
  registerSimplePersistentEnvExtension {
    addEntryFn   := Array.push
    addImportedFn := fun arrs => arrs.foldl Array.append #[]
  }

-- attribute 経由でルール登録（aesop パターン）
syntax (name := researchNodeAttr) "research_node" : attr

initialize registerBuiltinAttribute {
  name := `researchNodeAttr
  descr := "Register a research node into the global tree"
  add   := fun decl _ _ => do
    modifyEnv (researchExt.addEntry · decl)
}

-- Elaboration（partial def 推奨）
partial def elabResearchNode : Syntax → TermElabM Expr
  | `(research_node| node $name:ident : $ty refines [$refs,*] in $body) => do
      -- 型検査：refines の各 Name が global env に存在し、phase が上位
      for r in refs.getElems do
        unless (← getEnv).contains r.getId do
          throwErrorAt r "unknown research node {r}"
      -- ResearchSpec への変換
      ...
  | `(research_node| leaf $name:ident : $ty satisfies $phi) => do
      ...
  | _ => throwUnsupportedSyntax

@[term_elab «[research|»]
def elabResearchTerm : TermElab := fun stx _ => do
  match stx with
  | `([research| $node:research_node]) => elabResearchNode node
  | _ => throwUnsupportedSyntax
```

### 4.2 半順序関係の compile-time 検証

high-tokenizer の `refines` 半順序（refl + trans の theorem）と組み合わせ、tree 全体の整合性を **Lean compiler に強制させる**:

```lean
-- 研究ノード間の精緻化（既存 SpecSystem.Basic を再利用）
def ResearchSpec.refines (lower upper : ResearchSpec) : Prop :=
  (lower.phase = upper.phase ∨ upper.phase < lower.phase) ∧
  (∀ x, x ∈ upper.phi → x ∈ lower.phi) ∧
  ... -- artifact, funcSpec も同様

-- elab 時にこの Prop の `decide` を要求
elab_rules : term
  | `([research| $node]) => do
      let expr ← elabResearchNode node
      -- decide による compile-time check
      let prop ← `(decide ($expr).refines_consistent)
      ...
```

これにより `Sub-Issues テーブル不整合` `参照不能` `退役忘れ` がコンパイルエラーになる。

### 4.3 自作 Pipeline と Lake 統合

```lean
-- lakefile.lean（抜粋）
package research where
  ...

target researchTree (pkg : NPackage _package.name) : FilePath := do
  let trace ← buildFileUnlessUpToDate pkg.dir / "tree.json" do
    -- Lean elab で集めた env extension を JSON に出力
    let cmd := "lake env lean --run scripts/dump-research-tree.lean"
    execute cmd
  return trace

target smtVerified (pkg : ...) : FilePath := do
  -- Spec.Φ を SMT で検証（Lean-Auto 経由 or 外部 z3）
  ...

target testGen (pkg : ...) : FilePath := do
  -- Spec.testSet からテスト導出
  ...
```

`lake build research:researchTree research:smtVerified research:testGen` で deterministic な再生成が走る。

### 4.4 文書統合（Verso + doc-gen4）

- **Verso genre**: `Research` という新 genre を Lean function として定義
  - block: `surveyBlock`, `gapBlock`, `hypothesisBlock`, `decompositionBlock`
  - cross-reference: `[ref|MyNode]` で `@[research_node]` 登録名を参照
  - rendering: HTML（hover で type info, click で doc-gen4 ページへ）
- **doc-gen4**: leaf node の API リファレンスを自動生成

### 4.5 ProofWidgets による interactive view

研究 tree の半順序関係を React で graph 表示。

```lean
@[widget_module]
def researchTreeWidget : Module where
  javascript := include_str ".lake/build/widget/research-tree.js"

structure ResearchTreeProps where
  nodes : Array {name : Name, phase : ResearchPhase, refines : Array Name}
  deriving FromJson, ToJson

-- 使い方
#widget researchTreeWidget with (toJson { nodes := ... })
```

### 4.6 GitHub Issue 降格パス

設計書の通り、leaf node のみが Issue 化される。

```lean
-- @[research_node] かつ phase = .implementation かつ developmentFlag = true のみが
-- Issue として export される
def exportToGithubIssue : ResearchSpec → IO Unit := ...

-- Lake target として組み込む
target syncIssues (pkg : ...) : FilePath := do
  -- env extension を走査し、leaf を gh CLI で sync
  ...
```

これにより Issue 階層は research tree から **derived view** となる。

---

## Section 5: 限界と未解決問題

### 5.1 Lean 4 メタプログラミングの一般的限界

1. **メタコード自体に termination 保証はない** → `partial def` 多用で stack overflow / infinite loop リスク
2. **エラーメッセージが unfriendly**: macro hygiene が ID に noise を加えるためデバッグ困難
3. **Lean 4 の安定性は core / mathlib に偏る**: ProofWidgets / Verso 等周辺ツールは API breaking 頻発
4. **メタコードの単体テストが困難**: 公式テスト framework が貧弱（`#guard_msgs` 程度）

### 5.2 Verso の現状リスク

- "currently undergoing change at a rapid pace"
- cross-document cross-reference が experimental
- PDF 出力なし（HTML のみ）
- カスタム genre の実装例が少ない（reference manual / FP in Lean / mathlib in Lean のソースを読む以外に資料が乏しい）

### 5.3 ProofWidgets のリスク

- **Lake issue #86**: widget 1 個変更で全 widget 再ビルド（DX 劣化）
- TypeScript / React / tsc / Rollup の知識が必要（Lean エンジニアの skill set と非典型）
- offline 配布が複雑（minify JS の埋め込み手続き）

### 5.4 doc-gen4 の限界

- **ブラウザで直接開けない**（same-origin policy）→ 簡易 HTTP server 必須
- nested project 構成（`docbuild/`）が初学者に直感的でない
- カスタム rendering（独自タグ、独自セクション）が困難

### 5.5 Aesop / Duper / Lean-Auto の適用範囲

- 研究 tree への直接適用は薄い（証明探索が主目的）
- ただし「精緻化探索」「制約 Φ の自動検証」に **間接的に**応用可能
- `@[aesop]` 風の attribute API パターンは新基盤に再利用すべき

### 5.6 Lake の深部問題

- カスタム target の deterministic 性は **trace の正確さに依存**
- 外部コマンド（gh, z3, Python）を呼ぶ target は trace 設計が難しい（IO の不確定性）
- `extraDepTarget` で run する code が partial / panic すると build 全体が壊れる

### 5.7 設計上の未解決問題

1. **研究 tree の cycle 検出をどこで行うか**: macro 段階？ elab 段階？ Lake target 段階？
2. **`developmentFlag` の意味論**: Lean term level？ attribute？ doc level？
3. **半順序 `≤` の compile-time 検査と runtime 検査のトレードオフ**: 全てを `decide` で型検査すると tree が大きくなった際の elab 時間爆発
4. **GitHub Issue との双方向同期**: Issue 側変更（コメント、close）を Lean 側にどう反映するか
5. **退役 (deprecation)**: `@[deprecated]` attribute はあるが、研究ノード向け semantics が定まっていない
6. **複数研究プロジェクト間での DSL 共有**: Verso genre のように分離するのが妥当か、共通 base + 拡張の hierarchy か

### 5.8 推奨される次の調査

- **Verso の textbook genre 実装** を `verso/examples/textbook/DemoTextbook.lean` から精読し、研究文書 DSL の参考に
- **Aesop の rule_sets 実装ソース** を読み、`@[research_node]` attribute 設計に直接適用
- **Lake の trace 計算ソース** を読み、外部コマンド成果物の trace 設計を学ぶ
- **mathlib4 の `Mathlib.Tactic.Simps.Basic`**（`@[simps]` 自動 lemma 生成）を読み、研究ノードからの自動コード生成パターンを学ぶ
- **ProofWidgets の `Component/Panel/Basic`** を読み、widget の型安全 props 設計を理解

---

## 付録: 参照 URL 一覧（Section 別）

### Section 1.1 - macro / syntax / elab
- <https://leanprover-community.github.io/lean4-metaprogramming-book/>
- <https://leanprover-community.github.io/lean4-metaprogramming-book/main/02_overview.html>
- <https://leanprover-community.github.io/lean4-metaprogramming-book/main/04_metam.html>
- <https://leanprover-community.github.io/lean4-metaprogramming-book/main/05_syntax.html>
- <https://leanprover-community.github.io/lean4-metaprogramming-book/main/06_macros.html>
- <https://leanprover-community.github.io/lean4-metaprogramming-book/main/08_dsls.html>
- <https://leanprover-community.github.io/lean4-metaprogramming-book/main/09_tactics.html>

### Section 1.2 - mathlib4 norm_cast
- <https://leanprover-community.github.io/mathlib4_docs/Lean/Meta/Tactic/NormCast.html>
- <https://github.com/leanprover-community/mathlib4/wiki/Metaprogramming-for-dummies>
- <https://leanprover-community.github.io/mathlib4_docs/Mathlib/Tactic/NormNum/Core.html>
- <https://leanprover-community.github.io/mathlib4_docs/Mathlib/Tactic/Simps/Basic.html>

### Section 1.3 - ProofWidgets4
- <https://github.com/leanprover-community/ProofWidgets4>
- <https://leanprover-community.github.io/mathlib4_docs/ProofWidgets/Component/Panel/Basic.html>
- <https://lean-lang.org/examples/1900-1-1-widgets/>
- <https://voidma.in/assets/papers/23nawrocki_extensible_user_interface_lean_4.pdf>
- <https://www.edayers.com/thesis/widgets>

### Section 1.4 - Verso
- <https://verso.lean-lang.org/>
- <https://github.com/leanprover/verso>
- <https://github.com/leanprover/verso-templates>
- <https://lean-lang.org/doc/reference/latest/>
- <https://deepwiki.com/leanprover/verso>

### Section 1.5 - doc-gen4
- <https://github.com/leanprover/doc-gen4>
- <https://github.com/leanprover/doc-gen4/blob/main/README.md>
- <https://deepwiki.com/leanprover/doc-gen4/1-overview>

### Section 1.6 - Aesop
- <https://github.com/leanprover-community/aesop>
- <https://github.com/leanprover-community/aesop/blob/master/README.md>
- <https://leanprover-community.github.io/mathlib4_docs/Aesop/Frontend/Tactic.html>
- <https://leanprover-community.github.io/mathlib4_docs/Aesop/RuleSet.html>
- <https://dl.acm.org/doi/10.1145/3573105.3575671>
- <https://people.compute.dtu.dk/ahfrom/aesop-camera-ready.pdf>

### Section 1.7 - Duper / Lean-Auto
- <https://github.com/leanprover-community/duper>
- <https://github.com/leanprover-community/lean-auto>
- <https://drops.dagstuhl.de/storage/00lipics/lipics-vol309-itp2024/LIPIcs.ITP.2024.10/LIPIcs.ITP.2024.10.pdf>
- <https://arxiv.org/pdf/2505.14929>

### Section 1.8 - Lake
- <https://github.com/leanprover/lean4/blob/master/src/lake/README.md>
- <https://lean-lang.org/doc/reference/latest/Build-Tools-and-Distribution/Lake/>
- <https://deepwiki.com/leanprover/fp-lean/6.2-lake-build-system>
