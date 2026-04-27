# Group D: Type-Safe Document / Build Graph Systems

**作成日**: 2026-04-17
**担当**: Group D (build/computation graph、content-addressing、incremental computation)
**目的**: 文書・コード・仕様の依存グラフを型安全・immutable・incremental に管理するシステムから、agent-manifesto の研究 tree（`Spec = (T, F, ≤, Φ, I)`、artifact-manifest、D13 影響波及）に転用できる設計パターンを抽出する。
**スコープ境界**: 知識グラフ系（Roam, Obsidian, Logseq 等）はグループ A で扱う。本グループは **build / computation graph** に特化し、content-addressing と incremental computation を中核観点とする。

---

## 評価枠組（10 観点）

各対象について以下の観点を網羅する:

1. **依存の表現形式**: ファイル形式、グラフ構造、edge メタデータ
2. **incremental recomputation**: 部分再計算、キャッシュ、無効化条件
3. **content-addressing**: hash 戦略、reproducibility、checksum 検証
4. **不変条件**: hermetic、purity、determinism 等の保証
5. **依存解決**: 循環検出、優先度、衝突解決
6. **可観測性**: グラフの可視化、why-was-this-rebuilt の追跡
7. **DSL の表現力**: Turing complete か restricted か、評価モデル
8. **拡張性**: ユーザー定義ルール、custom rule、plugin
9. **規模**: モノレポ、distributed evaluation、性能限界
10. **失敗モード**: よくあるエラー、debugging tools、復旧

---

# Section 1: 各対象の精読ノート

## 1.1 Bazel — Skyframe + Aspects + Hermetic Build

**一次出典**:
- 公式: https://bazel.build/
- Skyframe: https://bazel.build/reference/skyframe
- Aspects: https://bazel.build/extending/aspects
- Hermeticity: https://bazel.build/versions/8.6.0/basics/hermeticity
- Architecture overview: https://www.gocodeo.com/post/how-bazel-works-dependency-graphs-caching-and-remote-execution

### 1.1.1 依存の表現形式

Bazel は `BUILD.bazel` ファイルに **target** と **dependency edge** を宣言する。各 target は `name`, `srcs`, `deps`, `visibility` 等の属性を持ち、target 間の有向辺が dependency graph (DAG) を構成する。BUILD ファイル自体も依存対象となる: 「Bazel will analyse the content of the BUILD.bazel file again when it changes and potentially produce different actions」。

ロード後、Bazel は 3 種類のグラフを内部に保持する:
- **Target graph**: BUILD ファイル由来の宣言的グラフ
- **Configured target graph**: platform/configuration を解決後
- **Action graph**: 各 target の rule 実装が emit する個別アクション

### 1.1.2 incremental recomputation

中核は **Skyframe**: 「the incremental evaluation framework Bazel is based on」。

- **SkyKey**: 「a short immutable name to reference a SkyValue, for example, FILECONTENTS:/tmp/foo or PACKAGE://foo」
- **SkyValue**: 「immutable objects that contain all the data built over the course of the build and the inputs of the build」
- **SkyFunction**: SkyKey から SkyValue を計算する純粋関数。依存は `env.getValue(otherKey)` 呼び出しで動的に登録される

**Restartable computation**: SkyFunction は依存値が未計算なら `null` を返し、Skyframe は依存解決後に再起動する。これにより事前に依存を全列挙する必要がない（dynamic discovery）。

**Change pruning**: 「If [a node's] new value is the same as its old value, the nodes that were invalidated due to a change in this node are 'resurrected'」。値が同じなら波及しない（早期カットオフ）。

### 1.1.3 content-addressing

Bazel の cache key は **action input 全体の hash**: 「the build system loads the rules and calculates an action graph and hash inputs to look up in the cache」。Remote cache (HTTP/gRPC) 経由でチーム横断共有。Hash 入力は: command line, source files, declared inputs, environment variables, action mnemonic 等。

CA model は伝統的には input-addressed（cf. Nix の標準モード）。Output は予測可能だが、出力が同一でも入力が違えば別エントリ。

### 1.1.4 不変条件

**Hermeticity**: 「a hermetic build system always returns the same output by isolating the build from changes to the host system」。実現手段:
- Tools as source code (toolchain pinning)
- 「strict sandboxing at the per-action level」
- Repository rules で external dependency も hash 固定

**Non-hermetic leak source**: 「system binaries」「absolute paths」「client environment leaking into the actions」。

### 1.1.5 依存解決

- **循環検出**: target レベル DAG で循環は load-time error
- **Configuration**: `select()` で platform に応じた条件分岐。configured target graph で解決
- **Visibility**: package level で公開範囲を制限。違反は load-time error

### 1.1.6 可観測性

- `bazel query`: BUILD レベルの依存問い合わせ
- `bazel cquery`: configured target graph 問い合わせ
- `bazel aquery`: action graph 問い合わせ
- `--explain` / `--verbose_explanations`: why-was-this-rebuilt 出力
- Build event protocol (BEP): JSON/protobuf でビルドイベントストリーム

### 1.1.7 DSL の表現力

**Starlark** (旧 Skylark): Python 風の **restricted** DSL。
- Turing-incomplete（再帰禁止、while loop 禁止）
- 純粋関数的（mutation は frozen で制限）
- 評価モデルは eager
- `.bzl` ファイルに rule, macro, provider を実装

### 1.1.8 拡張性

- **Custom rules**: `rule()` API で新言語サポートを追加
- **Aspects**: 「augment build dependency graphs with additional information and actions」。既存 graph を traversal し、shadow graph を構成
  - `attr_aspects = ['deps']` で propagation rule を指定
  - IDE 統合、code generation、protobuf 等で多用
- **Toolchains**: hermetic な toolchain 抽象化
- **Repository rules**: external dependency の取得・hash 化

### 1.1.9 規模

- Google 内部 Blaze は「2+ billion lines of code」のモノレポを処理
- 「Even simple binaries can often depend on tens of thousands of build targets」
- Forge/RBE: 「a large pool of Executor jobs continually read actions from this queue, execute them, and store the results」
- Public 例: Stripe, Dropbox, Pinterest, Uber

### 1.1.10 失敗モード

- **Stale cache**: `bazel clean --expunge` で対応。`--noremote_accept_cached` で remote cache 無視
- **Non-hermetic action**: `--sandbox_debug` で sandbox 内挙動を確認
- **Slow first build**: warm-up 必須。CI で `--remote_cache` 必須
- **Cycles**: `bazel query 'allpaths(A, B)'` で経路特定
- **依存忘れ**: action sandbox は宣言外ファイルへのアクセスをブロック → エラー化

---

## 1.2 Nix flake — Immutable Inputs + Content-Addressed Store

**一次出典**:
- 公式: https://nix.dev/concepts/flakes.html
- Wiki: https://wiki.nixos.org/wiki/Flakes
- 原典 RFC: https://gist.github.com/edolstra/40da6e3a4d4ee8fd019395365e0772e7
- CA derivation: https://www.tweag.io/blog/2021-12-02-nix-cas-4/
- Manual: https://nix.dev/manual/nix/2.24/command-ref/new-cli/nix3-flake

### 1.2.1 依存の表現形式

`flake.nix` ファイルは Nix expression で書かれた `{ inputs, outputs }` の attribute set。

- **Inputs**: dependency 宣言。例: `inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"`
- **Outputs**: function `inputs -> { packages, devShells, apps, checks, nixosConfigurations, overlays, templates, ... }`
- **flake.lock**: 全 transitive input の **immutable reference**（git revision または content hash）を JSON で固定

`flake.lock` の例（概念）:
```json
{
  "nodes": {
    "nixpkgs": {
      "locked": { "rev": "abc123...", "narHash": "sha256-..." }
    }
  }
}
```

### 1.2.2 incremental recomputation

**Nix store path** が cache 単位。`/nix/store/<hash>-<name>` は immutable で、同 hash なら絶対同内容。

- **input-addressed (default)**: derivation の input から決定的に出力 path を計算
- **content-addressed (experimental, `__contentAddressed = true`)**: 出力内容から path を決定。**Early cutoff** が効く: 「if your dependencies have not changed at all (bit-for-bit), you can avoid rebuilding yourself」

### 1.2.3 content-addressing

二段階の hash:
1. **Source hash**: tarball/git rev を SHA-256 で固定
2. **Store path hash**: derivation 全体（推移含む）を hash

CA derivation では「output paths used to be a given, they are now a product of the build」。`registerRealisation` がデータベースに output→path を登録。

### 1.2.4 不変条件

- **Pure evaluation** (flake default): 「fetchurl and fetchzip require a sha256 argument to be considered pure」、`builtins.currentSystem` 禁止、`builtins.getEnv` 禁止
- **Immutable store**: `/nix/store` は read-only。書き込みは builder daemon のみ
- **限界**: 「Even in pure mode, reproducibility is not actually guaranteed」（タイムスタンプ、並列順、非決定的コンパイラ等）

### 1.2.5 依存解決

- **`follows` mechanism**: 「inputs.hyprland.inputs.nixpkgs.follows = "nixpkgs"」で transitive 依存を unify
- **重複解決なし**: 同一 derivation hash なら共有、違えば併存
- **循環検出**: Nix expression の recursion 制限はないが、derivation graph は DAG 強制

### 1.2.6 可観測性

- `nix derivation show`: derivation の JSON 表示
- `nix-tree`: 依存 tree TUI
- `nix-diff`: 2 derivation の差分表示
- `nix store query --tree <storepath>`: 推移依存可視化
- `nix log <storepath>`: build log 取得

### 1.2.7 DSL の表現力

**Nix expression language**: lazy functional, dynamically typed。
- Turing-complete だが純粋関数的
- 副作用は derivation/import を通じてのみ
- 評価モデル: lazy + memoized

### 1.2.8 拡張性

- **Overlays**: 既存 package set への上書き層
- **Modules** (NixOS): system configuration の合成
- **Custom builders**: `mkDerivation` 経由で任意 build script

### 1.2.9 規模

- nixpkgs: 100,000+ packages
- NixOS: 数百万行の expression
- Hydra (CI): NixOS Foundation が flake build を継続実行

### 1.2.10 失敗モード

- **Mass rebuild**: glibc 等 leaf 変更で世界全体 rebuild
- **Closure size**: `nix path-info -S` で確認。GC は `nix-collect-garbage`
- **Secret leak**: 「Storing unencrypted secrets in flakes」(world-readable in store) → sops-nix 等で対応
- **Forgot `git add`**: 「won't be included in builds」
- **flake.lock conflict**: `nix flake update --update-input <name>` で個別更新

---

## 1.3 Buck2 — DICE Engine + Starlark + Dynamic Dependencies

**一次出典**:
- 公式: https://buck2.build/
- Why Buck2: https://buck2.build/docs/about/why/
- Architecture: https://buck2.build/docs/developers/architecture/buck2/
- Modern DICE: https://buck2.build/docs/insights_and_knowledge/modern_dice/
- Dep files: https://buck2.build/docs/rule_authors/dep_files/
- Dynamic deps: https://buck2.build/docs/rule_authors/dynamic_dependencies/
- Tweag review: https://www.tweag.io/blog/2023-07-06-buck2/
- Slides (May 2025): https://ndmitchell.com/downloads/slides-what_makes_buck2_special-22_may_2025.pdf

### 1.3.1 依存の表現形式

`BUCK` ファイルに target 宣言。Bazel と類似だが:
- **No phases**: 「Buck2 is not phased - there are no target graph/action graph phases, just a series of dependencies in a single graph on DICE」
- **Cells** (≠ workspaces): 「independent sub-directories」
- **Configuration in path**: 「buck-out/v2/gen/PROJECT/HASH/some/file」— configuration hash が出力 path に埋め込まれる

Graph は **3 層**: unconfigured target → configured target → action node、すべて DICE の単一グラフ上に存在。

### 1.3.2 incremental recomputation

**DICE = Dynamic Incremental Computation Engine**:
- 並列計算サポート
- Series-parallel graph で依存記録
- **Early cutoff**: 「During recomputation, if all dependencies yield identical values to previous runs, that node will skip recomputation」
- **Versioning**: 「the last version that you were valid at」を記録

**Modern DICE**: 「single-threaded core state」で fine-grained lock を撤廃 → 状態同期の複雑性を削減。

**Incremental actions**: 「rules to short-circuit some subset of the work if run again」

**Dep files**: 「a subset of the files weren't actually used, and thus not be sensitive to changes within them」。例: C++ の unused header、Java の unused class が変わっても再コンパイル不要。

### 1.3.3 content-addressing

- 「directory hashes...ready to send to remote execution」
- Action key = hash of (command, all inputs)
- 「If the output of remote actions is then used as the input for a further remote action, Buck2 avoids ever downloading the intermediate output and just remembers the resulting hash」
- Bazel Remote Execution Protocol 互換

### 1.3.4 不変条件

- Hermetic action（remote execution first）
- Provider は immutable な data structure
- Configuration hash は出力 path に焼き込まれ、後から変更不可

### 1.3.5 依存解決

- **Static dependencies**: target 間の通常依存
- **Dynamic dependencies** (`dynamic_output`): 「a rule to use information that was not available when the rule was first run at analysis time」。実行例: Distributed ThinLTO、OCaml dependencies、Erlang BEAM
- **Anonymous targets**: 「create a graph that has more sharing than the original user graph」（自動的な CSE）

### 1.3.6 可観測性

- **BXL** (Buck eXtension Language): 「Starlark scripts...inspect and interact directly with the buck2 graph」
- `buck2 query` / `cquery` / `aquery`: Bazel 同等
- Superconsole: rich TUI で進捗可視化
- Event log: protobuf stream

### 1.3.7 DSL の表現力

- **Starlark with type annotations**: 「Python-like type annotations with type checking enforced as errors」
- 全 rule が Starlark 実装（Bazel と異なり Java built-in なし）
- `cmd_args` API: 「captures inputs and outputs directly, reducing forgotten dependency errors」

### 1.3.8 拡張性

- 全 rule が Starlark で書かれているため democratization: 「features have been made available to all rules」
- BXL でユーザー定義 graph 操作 script
- Anonymous target で graph sharing

### 1.3.9 規模

- Meta 内部で 100,000+ engineers をサポート
- Buck1 比 「2x as fast」
- DICE は独立 crate として publish（Buck2 外でも再利用可能）
- Bazel RE Protocol 互換のため EngFlow 等の RBE クラスタ利用可

### 1.3.10 失敗モード

- **Dep file lost on daemon restart**: 「Dep files only function with previous invocations known to the daemon」
- **Dynamic dependency 過剰**: 過用すると graph が予測不能になり debugging 困難
- 比較的若いプロジェクト（2023 OSS 化）のため ecosystem は Bazel より小

---

## 1.4 Doxygen — Code Relationship Graphs

**一次出典**:
- 公式 manual: https://www.doxygen.nl/manual/diagrams.html
- Graph legend: https://www.doxygen.nl/manual/examples/diagrams/html/graph_legend.html

### 1.4.1 依存の表現形式

Doxygen は **C++ source code をパース → AST → 関係抽出** という pipeline。依存は内部表現で保持され、Graphviz の DOT 形式で出力される。

抽出される関係:
- 継承 (public/protected/private)
- メンバー所有 (composition/aggregation)
- 関数呼び出し (call/caller)
- include 関係 (header dependency)
- ディレクトリ依存

### 1.4.2 incremental recomputation

- **No incremental in core**: Doxygen は基本的に full rebuild
- ただし XML 出力をキャッシュとして利用すれば、外部ツールが差分処理可能
- `WARN_IF_DOC_ERROR` 等の設定で stale doc を検出

### 1.4.3 content-addressing

- 直接的な content-addressing なし
- Source file の timestamp ベース
- Hash による cache invalidation は持たない

### 1.4.4 不変条件

- 出力 deterministic（同 source → 同 graph）だが、Graphviz layout は非決定的に揺れる場合あり
- `DOT_GRAPH_MAX_NODES`, `MAX_DOT_GRAPH_DEPTH` で graph 切り詰め

### 1.4.5 依存解決

- 循環 include は表示されるが build error にはならない
- Class 継承の循環は C++ 構文エラー（Doxygen 入力前段で弾かれる）

### 1.4.6 可観測性

- **可視化が中核機能**: SVG, PNG, PDF 出力
- 8 種の diagram type（class, inheritance, include, inverse include, struct relations, call, caller, directory）
- 「Doxygen tries to limit the width of the resulting image to 1024 pixels」

### 1.4.7 DSL の表現力

- DSL なし。設定は `Doxyfile` (key=value 形式)
- Doxygen comment syntax (`\brief`, `\param`, `@code` 等) はマークアップ

### 1.4.8 拡張性

- Custom command (`ALIASES`)
- XML output → 外部ツールで後処理
- Plugin 機構なし（fork ベースの拡張）

### 1.4.9 規模

- Linux kernel, LLVM, Boost 等の超大規模 C++ コードベースで実用
- ただし graph は **対象 entity 単位**（per-class, per-function）に分割されるため、巨大単一 graph は描かない

### 1.4.10 失敗モード

- **Graphviz dot がない / PATH 通ってない**: `HAVE_DOT=YES` でも graph 生成されず
- **巨大 graph で OOM**: `DOT_GRAPH_MAX_NODES` で抑制
- **誤った関係抽出**: C++ template の特殊化等で誤検出あり

---

## 1.5 Sphinx — Cross-Reference + Intersphinx + autodoc

**一次出典**:
- 公式: https://www.sphinx-doc.org/en/master/
- intersphinx: https://www.sphinx-doc.org/en/master/usage/extensions/intersphinx.html
- autodoc: https://www.sphinx-doc.org/en/master/usage/extensions/autodoc.html
- objects.inv format: https://sphobjinv.readthedocs.io/en/stable/syntax.html

### 1.5.1 依存の表現形式

Sphinx は **reStructuredText/Markdown ファイル群 + conf.py** を入力として、内部に **environment** (BuildEnvironment) と呼ばれる pickle 化された state を構築する。

- Cross-reference: `:py:func:`io.open`` のような role
- Intersphinx: 外部プロジェクトの `objects.inv` (compressed inventory file) を参照
- Domain: py, c, cpp, rst, std 等。各 domain が独自の object type と role を提供

`objects.inv` v2 entry の field: `name`, `domain`, `role`, `priority`, `uri`, `dispname`。

### 1.5.2 incremental recomputation

- BuildEnvironment が前回 build の state を pickle で保持
- 変更されたファイルのみ再パースし、cross-reference を再解決
- ただし full rebuild は `-E` で強制可能
- Intersphinx inventory は「cached in the Sphinx environment, so it must be re-downloaded whenever you do a full rebuild」

### 1.5.3 content-addressing

- 直接的 content-addressing なし
- ファイル mtime と hash mix での invalidation
- Intersphinx inventory は URL ベース（hash pinning なし）→ upstream 変更で stale

### 1.5.4 不変条件

- Build deterministic（同 source → 同出力、ただし theme/extension 依存）
- 厳密な hermeticity 保証なし

### 1.5.5 依存解決

- Cross-reference 解決順序: ローカル → intersphinx
- 「The any role also works together with the intersphinx extension: when no local cross-reference is found, all object types of intersphinx inventories are also searched」
- 重複参照は warning（`nitpicky` mode で error 化）

### 1.5.6 可観測性

- Build log: warning/error 一覧
- `sphinx-build -W` で warning を error 化
- `nitpicky=True` で broken reference を検出
- doctree dump で AST 確認可能
- `sphinx-apidoc` で API skeleton 生成

### 1.5.7 DSL の表現力

- **Directives** (custom 可) + **Roles** (inline reference)
- 内部は docutils AST → 任意 transform 適用
- Python plugin で任意拡張

### 1.5.8 拡張性

- **Extensions**: Python module で event hook (`builder-inited`, `doctree-read`, `doctree-resolved` 等)
- **Custom directive**: `Directive` クラス継承
- **Custom role**: function 登録
- **autodoc**: docstring から自動生成
- 数千の third-party extension（ablog, sphinx-gallery, myst-parser 等）

### 1.5.9 規模

- Python 標準ライブラリドキュメント（数百万語）
- LLVM, Linux kernel, NumPy, Django 等の大規模プロジェクトで実用
- Intersphinx で N×M リンクを scalable に管理（inventory pre-compute）

### 1.5.10 失敗モード

- **Broken reference**: 「Sphinx will warn」しかし build は通る → CI で `-W` 必須
- **Intersphinx upstream down**: build が遅延・失敗
- **Pickle corruption**: `_build/` 削除で復旧
- **Plugin version mismatch**: pip install で時限爆弾

---

## 1.6 Pandoc Filter — AST Manipulation

**一次出典**:
- 公式 Lua filters: https://pandoc.org/lua-filters.html
- Filter overview: https://pandoc.org/filters.html
- Source: https://github.com/jgm/pandoc

### 1.6.1 依存の表現形式

Pandoc は **Reader → AST → Writer** という単純 pipeline。「two-phase process: parsing input into an abstract syntax tree (AST) and then rendering the AST into the target format」。

AST の 2 大カテゴリ:
- **Block**: paragraph, header, list, code block, table, div
- **Inline**: text, emphasis, link, image, math, citation

依存グラフは **document scope 内** に閉じる（cross-document は filter で明示的に処理）。

### 1.6.2 incremental recomputation

- **No incremental**: 入力ごとに full reparse
- 大規模変換は Makefile/Just 等の外部 build system で incremental 化

### 1.6.3 content-addressing

- なし（document conversion ツール）
- mediabag で binary resource を embed 可能

### 1.6.4 不変条件

- 同 input + 同 filter chain → 同 output（filter が pure ならば）
- Lua filter 内で IO 副作用があると非決定化

### 1.6.5 依存解決

- Filter は CLI 順に sequential 適用: 「Filters are applied sequentially in the order they are specified on the command line」
- AST 内部の cross-reference は個別 filter で対応

### 1.6.6 可観測性

- `pandoc -t json` で AST dump
- Lua filter 内で `print()` debug 可能
- `--verbose` で各 stage の出力

### 1.6.7 DSL の表現力

- **Lua filter**: Lua 5.4 + pandoc API。Turing-complete
- **JSON filter**: 任意言語で stdin/stdout
- **Walking strategies**: typewise (default, bottom-up) / topdown (depth-first)
- 「Functions can return false as a second value to cut short subtree processing」

### 1.6.8 拡張性

- Lua filter は zero external dep
- Custom reader/writer も Lua で実装可
- Template engine (mustache 風) も拡張可能

### 1.6.9 規模

- 単一 document の AST 操作に最適化
- 大量 document は外部 driver で並列化必要（pandoc-batch, Quarto 等）

### 1.6.10 失敗モード

- **Wrong return type**: 「Returning incorrect element types triggers validation errors」
- **Filter order matters**: 順序ミスで silent miscompile
- **Lua sandbox**: filter 内で外部 IO する際は `io` ライブラリ要

---

## 1.7 Unison — Content-Addressed Codebase

**一次出典**:
- 公式: https://www.unison-lang.org/docs/the-big-idea/
- Tour: https://www.unison-lang.org/docs/tour/
- LWN review: https://lwn.net/Articles/978955/
- Source: https://github.com/unisonweb/unison

### 1.7.1 依存の表現形式

Unison では「functions are identified by a hash of their implementation rather than by name」。

- **Hash = SHA3-512** of the **AST**（名前を抽象化、引数は positional）
- **Names are metadata**: 名前 → hash の table 別管理
- **Codebase = SQLite database**: AST をシリアライズ格納

依存は AST 内の関数 reference をすべて hash に置き換えた上で hash 化されるため、**transitive dependency が hash に反映**される。

### 1.7.2 incremental recomputation

- 「definitions identified by their hash, they never change」→ parse/typecheck 結果を **永久 cache**
- 編集は scratch file (`.u`) に: 「The codebase manager listens for changes to any file ending in .u in the current directory, and when any such file is saved...Unison parses and typechecks that file」
- 変更は新 hash として追加され、旧定義は破棄されない

### 1.7.3 content-addressing

- **SHA3-512** hash: 「unimaginably small chances of collision」
- 「100 quadrillion years」for first collision @ 1M unique definitions/sec
- Hash は AST 構造のみに依存（変数名、コメント無関係）→ semantic equivalence で同 hash

### 1.7.4 不変条件

- **Immutability**: 同 hash → 同実装。逆も真
- **No version conflict**: 異なる hash は併存可能、依存先は hash で固定
- **Distributed evaluation**: 「the sender ships the bytecode tree to the recipient, who inspects the bytecode for any hashes it's missing」

### 1.7.5 依存解決

- 推移依存は hash chain で透過
- 名前衝突は別 hash で併存可能（namespace で区別）
- Rename は metadata 更新のみ → 既存依存に影響なし

### 1.7.6 可観測性

- `ucm` (Unison Codebase Manager) コマンド
- `view`, `find`, `dependents`, `dependencies` で依存問い合わせ
- `history` で時系列追跡

### 1.7.7 DSL の表現力

- 専用関数型言語（Haskell 影響）
- Algebraic effects, abilities
- Strict static typing
- Turing-complete

### 1.7.8 拡張性

- Library system (`pull from share.unison-lang.org/...`)
- Distributed computation primitive (built-in)

### 1.7.9 規模

- Unison Cloud で production 利用
- Codebase database は SQLite ベース（数 GB スケール想定）
- Distributed dependency sync が built-in

### 1.7.10 失敗モード

- **Editor 統合の弱さ**: scratch file workflow が学習曲線
- **Migration from text-based**: 既存 git workflow と整合困難
- **Hash 衝突 (理論上)**: SHA3-512 で実質ゼロだが「never zero」

---

## 1.8 Dhall — Total Functional Configuration

**一次出典**:
- 公式: https://dhall-lang.org/
- Safety guarantees: https://docs.dhall-lang.org/discussions/Safety-guarantees.html
- Standard: https://github.com/dhall-lang/dhall-lang
- Hackage: https://hackage.haskell.org/package/dhall

### 1.8.1 依存の表現形式

Dhall は **import を first-class** な機構とする configuration language。

- Import 形式: file path / HTTP(S) URL / 環境変数
- Hash 注釈: `https://example.com/lib.dhall sha256:abc123...` のように **semantic hash** を import に付与
- 型: import 全体が Dhall expression として evaluable

「JSON + functions + types + imports」と表現される。

### 1.8.2 incremental recomputation

- Import は **permanently locally cached** after first request: 「permanently locally cached after the first request, so subsequent imports will no longer make outbound HTTP requests」
- Cache key = semantic hash
- Hash mismatch なら refetch

### 1.8.3 content-addressing

**Semantic integrity hash**: 「a hash of a canonical encoding of the program's syntax tree and not a hash of the program's source code」。

- 結果: refactoring/whitespace 変更で hash は変わらない
- α-equivalence までは同 hash
- 異なる実装でも normal form が同なら同 hash

### 1.8.4 不変条件

- **Totality**: 「If an expression type-checks then evaluating that expression always succeeds in a finite time」
- **No Turing-completeness**: 再帰禁止、無限ループ不可能
- **No arbitrary side effects**: import 以外の IO なし
- **Computed import 禁止**: 「The language prohibits 'computed imports' where paths depend on configuration values」→ 情報漏洩防止

### 1.8.5 依存解決

- Import の循環は禁止（type checker で検出）
- Remote import の **transitive constraint**: 「Remote imports can only transitively import from other web services—they cannot access local files or environment variables」（capability separation）

### 1.8.6 可観測性

- `dhall hash <file>`: semantic hash 出力
- `dhall freeze`: 全 import に hash を付与
- `dhall normalize`: normal form 出力（hash 計算根拠を確認可能）
- `dhall lint`, `dhall format`

### 1.8.7 DSL の表現力

- **Total functional language**: System F + records + unions
- Turing-incomplete（意図的）
- 評価モデル: normal-order reduction → β/η normal form

### 1.8.8 拡張性

- Standard prelude: 共通関数集
- Bindings: `dhall-to-json`, `dhall-to-yaml`, `dhall-to-text`, Haskell/Rust/Go SDK

### 1.8.9 規模

- 設定言語特化のため小規模が想定
- 大規模 Kubernetes manifest 生成等で利用例あり

### 1.8.10 失敗モード

- **Hash mismatch on update**: 意図しない hash 変更 → 明示的 `dhall freeze` 必要
- **Remote import 障害**: 取得先ダウンで build 失敗（hash があれば cache hit）
- **Type 学習コスト**: System F は YAML 利用者には敷居高い

---

# Section 2: 比較表

| 観点 | Bazel | Nix flake | Buck2 | Doxygen | Sphinx | Pandoc | Unison | Dhall |
|------|-------|-----------|-------|---------|--------|--------|--------|-------|
| **依存表現** | BUILD/Starlark, target DAG, action graph | flake.nix + lock, derivation graph | BUCK, single DICE graph (3 層) | C++ AST 自動抽出 | rST + objects.inv | AST in document scope | AST hash chain | Dhall expr + import hash |
| **Incremental** | Skyframe (restartable, change pruning) | input/CA derivation, store hash | DICE (early cutoff, dep files) | Full rebuild | BuildEnv pickle | Full reparse | 永久 cache (hash immutable) | Import cache (hash key) |
| **Content-addr** | Action input hash, RBE 互換 | Store path hash, CA 実験的 | Directory hash, RBE 互換 | なし | なし | なし | SHA3-512 of AST | Semantic hash (canonical) |
| **不変条件** | Hermetic + sandbox | Pure eval + immutable store | Hermetic, config in path | 緩い determinism | 緩い | filter pure なら | Immutability 強制 | Totality + no side effects |
| **依存解決** | Static + select(), 循環 error | follows で unify, DAG | Static + dynamic_output, anon | C++ 構文に従属 | Local→intersphinx fallback | Filter 順序 sequential | Hash で透過 | Type checker で循環検出 |
| **可観測性** | query/cquery/aquery, BEP | nix-tree, nix-diff, nix log | BXL, query, superconsole | 8 種 diagram (SVG/PNG) | warning, doctree dump | AST JSON dump | ucm dependents | dhall hash/normalize |
| **DSL** | Starlark (restricted) | Nix (lazy func, Turing-comp) | Starlark + types | Doxyfile + comment | rST + Python ext | Lua (Turing-comp) | Unison (full lang) | Dhall (total, non-Turing) |
| **拡張性** | Custom rule + aspect + toolchain | Overlay + module | Starlark rules + BXL + anon | XML + ALIASES | Extension event hook | Lua filter + custom rw | Library (share) | Prelude + bindings |
| **規模** | 2B+ lines (Google) | 100k+ packages | Meta scale, 100k+ engineers | LLVM/Linux kernel 規模 | Python stdlib 規模 | 単一 doc 中心 | Unison Cloud | 設定言語規模 |
| **失敗モード** | Stale cache, 非hermetic leak | Mass rebuild, secret leak | Dep file lost on restart, dyn graph 過用 | dot 不在, OOM | broken ref silent, pickle 破損 | Wrong type, filter 順序 | Editor UX, migration | Hash drift, remote down |

**追加の定量データ**:
- Bazel @ Google: 「2+ billion lines of code」、「tens of thousands of build targets」per binary
- Buck2: Buck1 比 「2x as fast」（Meta 内部測定）
- Unison hash: SHA3-512 で「100 quadrillion years」 to first collision @ 1M defs/sec
- Doxygen graph: 「1024 pixels」width 上限 (default)
- Sphinx intersphinx: objects.inv は zlib 圧縮、Python stdlib で数百 KB
- Nix nixpkgs: 100,000+ packages, GiB スケールの flake.lock 例あり

---

# Section 3: 横断的な発見

## 3.1 共通設計原則

### 3.1.1 「依存の透明性」階層

3 つのレベルで依存が表現される:

| Level | 説明 | 例 |
|-------|------|-----|
| **L1: Static declarative** | 事前宣言、graph 全体が load-time に既知 | Bazel BUILD `deps`, Dhall import |
| **L2: Restartable / dynamic discovery** | 評価中に依存が発見される | Skyframe SkyFunction, Buck2 dynamic_output |
| **L3: Content-derived** | 入力内容そのものから依存集合が決定 | Buck2 dep files, Bazel header dep scan |

新基盤の `Spec = (T, F, ≤, Φ, I)` は **L1 + L2** が必要。`≤` 関係は静的に宣言されるが、refinement 中に新ノード（C, J, A）が動的に発見される（Skyframe restart 相当）。

### 3.1.2 Content-addressing の二系統

| 系統 | 例 | hash 対象 | 利点 |
|------|-----|-----------|------|
| **Syntactic** | Nix store (input-addr), Bazel cache key | バイト列・正規化前 expression | 実装単純、incremental key として高速 |
| **Semantic** | Dhall semantic hash, Unison AST hash | normal form / canonical AST | refactoring resilient, semantic equivalence で cache hit |

Unison の SHA3-512 of AST と Dhall の normal-form hash は同系（**semantic addressing**）。これは agent-manifesto の `Spec` 同定に直接転用可能: 「文章を整形しただけで spec hash が変わる」現象を回避できる。

### 3.1.3 Early cutoff の普遍性

Skyframe の change pruning、DICE の early cutoff、CA-Nix の resolved derivation reuse、Unison の immutable hash — **すべて同パターン**: 「入力が変わっても出力が同なら下流再計算を skip」。

新基盤の Gate 評価で同パターン採用可能: artifact-manifest の hash が同なら下流 Gate を skip。

### 3.1.4 Hermeticity の三層実装

| 層 | 強制手段 | 例 |
|----|---------|-----|
| **構文層** | DSL が IO を排除 | Dhall (total, no side effects) |
| **実行層** | Sandbox で host 切断 | Bazel sandbox, Nix builder |
| **入力層** | 全入力を hash 固定 | Nix store, Bazel action input hash |

新基盤は **構文層** を Lean の純粋性で確保し、**入力層** を artifact-manifest の hash で確保すれば、Bazel/Nix 相当の hermeticity を Lean 上で再現できる。

## 3.2 トレードオフ

### 3.2.1 Static vs Dynamic dependency

| 軸 | Static (Dhall, Bazel basic) | Dynamic (Skyframe, DICE) |
|----|----------------------------|-----------------------|
| 解析容易性 | 高: load-time に DAG 確定 | 低: 評価中変動 |
| 表現力 | 低: 既知パターンのみ | 高: 任意の dependency discovery |
| 並列性 | 高: 事前 scheduling 可 | 中: restart で揺れる |
| Debug | 容易 | 困難 |

新基盤の研究 tree は基本 static（手動分解）だが、**子ノードの自動派生**（D13 影響波及）には dynamic discovery が必要。

### 3.2.2 Restricted DSL vs Turing-complete

| 軸 | Restricted (Starlark, Dhall) | Turing-complete (Nix, Lua filter, Unison) |
|----|----------------------------|----------------------------------------|
| 検証性 | 高: 終了保証、subsetable | 低: halting problem |
| 表現力 | 中: 標準パターンに限定 | 高 |
| 学習曲線 | 緩 | 急 |
| Sandboxing | 構文層で実現 | 実行層が必要 |

新基盤の DSL は **restricted を推奨**。Lean は dependent typing で表現力が高いが、評価は kernel が保証する純粋性で hermeticity を満たす。

### 3.2.3 Cache granularity vs Correctness

- **粗粒度** (Doxygen, Sphinx full rebuild): 実装単純、cache miss 多
- **中粒度** (Bazel action level): バランス良いが action 設計が複雑
- **細粒度** (Buck2 dep files, Unison per-definition): cache hit 最大、実装複雑

新基盤の単位は **artifact-manifest entry** = 中粒度。Lean モジュール単位で cache し、`/trace coverage` で stale 検出。

## 3.3 独自性

### 3.3.1 Unison の structural rename

「名前は metadata」「定義は immutable」は **rename 革命**。研究 tree でも「ノード ID は内容 hash、見出しは別 metadata」モデルを採用すれば、見出し変更で grep 切れが発生しない。

### 3.3.2 Dhall の semantic hash + capability-separated import

Remote import は file/env にアクセス不可、という capability 制約は **prompt injection 対策** として有効。研究 tree で外部資料を取り込む際、外部 spec が local artifact を参照できない構造を採用すべき。

### 3.3.3 Buck2 の anonymous targets

「more sharing than the original user graph」は automatic CSE。研究 tree で「異なる仮説が同じ実験結果を参照」する場合、自動 deduplication が可能になる。

### 3.3.4 Bazel の aspects = shadow graph

既存 graph に **直交的な解析を後付け** できる。新基盤で「全ノードに verifier 評価を attach」「全ノードに metric 計算を attach」を後付け実装する場合、aspects パターンが転用できる。

---

# Section 4: 新基盤への適用可能性

## 4.1 研究 tree の依存グラフ表現

agent-manifesto の研究 tree は `Spec = (T, F, ≤, Φ, I)` で表現される。各要素を本サーベイ知見にマップ:

| Spec 要素 | マッピング | 該当パターン |
|-----------|-----------|------------|
| `T` (Type 集合) | Lean type definitions | Bazel `target` ≒ Lean theorem statement |
| `F` (Function 集合) | Lean functions | Bazel rule implementation |
| `≤` (refinement 半順序) | Lean structural relation | Bazel `deps` edge |
| `Φ` (制約) | Lean propositions | Bazel `select()` 等の constraint |
| `I` (instance) | artifact-manifest entry | Bazel `output` |

**推奨実装パターン**:
- Lean で **Skyframe 相当** の incremental engine を書くのは過剰。代わりに **lake** （Lean の build tool）が既に SkyFunction 風 incremental を提供 → これを活用
- BUILD 相当は Lean の `import` graph で代替
- artifact-manifest が Bazel の `--build_event_json_file` 相当の役割

## 4.2 Incremental Gate 評価

Gate = `/research` workflow の判定ノード。Gate 評価を incremental 化するには:

### 4.2.1 設計案: Lean × artifact-manifest による Skyframe 風 incremental

```
SkyKey 相当: GateKey { spec_hash : Hash, gate_id : Nat }
SkyValue 相当: GateResult { passed : Bool, evidence : Array ArtifactRef }
SkyFunction 相当: Lean function evalGate (key : GateKey) : IO GateResult
```

- **Change pruning**: artifact-manifest entry の hash が同じなら下流 Gate skip
- **Restart**: Gate の中で別 spec を参照する場合、未計算なら null 返却して後続 batch
- **Cache**: `/Users/nirarin/work/agent-manifesto-new-foundation/.cache/gates/<hash>.json` に永続化

### 4.2.2 設計案: Buck2 dep files による「使われた spec のみ依存」

Gate が spec の一部しか参照しないケース:
- Gate 評価時に「実際に参照した spec」を記録（dep file 相当）
- 次回 evaluation で参照外 spec が変わっても再評価不要
- artifact-manifest に `accessed_specs: [...]` field を追加

### 4.2.3 設計案: 早期カットオフによる無駄な Verifier 起動の削減

- artifact の semantic hash（Dhall 風）を計算
- 同 hash なら verifier 起動を skip（冪等性活用）
- 「format 整形しただけで verifier 走る」現象を回避

## 4.3 artifact-manifest 拡張案

現行 `artifact-manifest.json` に以下を追加:

| Field | 役割 | 出典パターン |
|-------|------|------------|
| `content_hash` | 内容 hash (SHA-256) | Nix store, Bazel cache key |
| `semantic_hash` | normal form hash | Dhall semantic hash, Unison AST hash |
| `inputs` | この artifact が参照する spec/artifact 一覧 | Bazel action inputs |
| `accessed_inputs` | 実際に参照した部分集合 | Buck2 dep files |
| `produced_by_gate` | この artifact を生成した Gate ID | Bazel action provenance |
| `invalidates` | この artifact 変更で再評価必要な下流 ID | Skyframe reverse deps |

これにより:
- 「なぜ再評価された」を `manifest-trace why <id>` で追跡可能（aquery 相当）
- 影響波及（D13）が機械的に計算可能（reverse deps 走査）

## 4.4 D13 影響波及の機械化

D13 = 「ある変更が他のどこに波及するか」の宣言。本サーベイ対象のうち:

- **Bazel reverse query**: `bazel query 'rdeps(//..., //changed:target)'` で reverse deps 全列挙
- **Skyframe 内部の rdeps**: change pruning に必須
- **Buck2 BXL**: 任意の graph traversal を Starlark で記述

**新基盤実装案**:
```lean
def affectedBy (changed : SpecId) : Array SpecId :=
  manifestEntries.filter (·.inputs.contains changed)
  -- 推移閉包は再帰
```

artifact-manifest を「逆方向 index 付き」で保持すれば O(in-degree) で計算可能。Bazel の reverse query が同じ構造。

## 4.5 「Lean を build system として使う」パターン

Lean の `lake` build tool は既に:
- 依存解決 (import graph)
- Incremental 再コンパイル
- Cache (`.olean` ファイル)

を提供する。これを **研究 tree の build system として転用** する案:
- 研究ノード = Lean モジュール
- spec の precondition = `import` 文
- artifact の生成 = `#eval` または `def` 評価
- Gate 評価 = compile-time check（型エラーで失敗）

これにより、別途 Skyframe 相当を書く必要なく、**Lean compiler 自体が Skyframe** として機能する。

## 4.6 推奨採用パターン優先順位

| 優先度 | パターン | 出典 | 期待効果 |
|--------|---------|------|---------|
| **High** | Semantic hash for spec identity | Dhall, Unison | format 揺れに強い同一性判定 |
| **High** | Reverse deps index in manifest | Bazel rdeps | D13 機械化 |
| **High** | Restartable gate evaluation | Skyframe | 動的依存発見の表現 |
| **Medium** | Dep files (accessed inputs) | Buck2 | 過剰再評価の削減 |
| **Medium** | Aspect 風 verifier attach | Bazel aspects | 後付け解析の追加容易性 |
| **Medium** | Capability-separated import | Dhall | prompt injection 対策 |
| **Low** | Anonymous target (auto CSE) | Buck2 | 重複仮説の自動統合 |
| **Low** | Lake を build system 化 | Lean lake | 自前 Skyframe 不要 |

---

# Section 5: 限界と未解決問題

## 5.1 本サーベイのカバレッジ限界

- **動的グラフ DSL の比較不足**: Buck2 の DICE 内部 detail、Skyframe restart の overhead、Unison の codebase migration story について深掘りできず
- **失敗モード定量化不足**: 各 system の failure rate、実運用での「cache miss 原因 top 5」等の data なし
- **Distributed evaluation**: Bazel RBE、Nix Hydra、Buck2 の RE は概念レベルのみで benchmark 比較未取得
- **agent-manifesto 既存資産との衝突点**: 現行 `manifest-trace` の実装制約、既存 `lake` build の依存解決との二重管理リスク等は本グループでは扱わない（グループ F の範疇）

## 5.2 設計上の未解決問題

### 5.2.1 Semantic hash の計算コスト

Dhall の normal-form hash は β-reduction を要する → 計算コスト高。Lean expression の正規化（`whnf`, `reduce`）も同様に重い。
- 妥協案: `Repr` 由来の structural hash + 必要時のみ semantic hash
- 未検証

### 5.2.2 Lean を build system として使う場合のスケール

lake は数千モジュールでは実用だが、**研究 tree の数万ノード規模** での性能不明。Skyframe は数百万ノードを処理するが、lake はそこまでの実績なし。
- 切替閾値の見極めが必要
- 並列度、incremental の精度

### 5.2.3 Dynamic dependency の Lean 表現

Skyframe restart や Buck2 `dynamic_output` を Lean で表現する pattern は不明。
- IO monad で表現 → 純粋性破壊
- `Lean.Elab` の elab loop に乗せる → 過度に複雑
- 別途専用 evaluator を実装 → lake から外れる
- **未解決**

### 5.2.4 Capability-separated import の Lean での実現

Dhall の「remote import は local file 不可」という capability 分離は、Lean には機構なし。
- Lean import は基本的に file path、URL import なし
- 外部 spec を取り込む際の制約モデルを別途設計必要

### 5.2.5 Anonymous target / auto CSE の必要性判断

研究 tree で「異なる仮説が同じ実験結果を参照」のケースがどの程度あるか不明。
- 必要なら Buck2 anon target パターン採用
- 不要なら過剰設計
- **実証データ不足**

## 5.3 本グループ調査で除外したが将来検討すべき対象

- **Salsa** (Rust の incremental compilation framework): Rust 製で軽量。Cargo, rust-analyzer, Mun 等で利用。lake の代替候補
- **Adapton** (incremental computation library): 学術的に最も洗練。Lean との親和性高そう
- **Differential dataflow** (Frank McSherry): Materialize 等。差分計算の高度抽象
- **Pluto.jl** (Julia の reactive notebook): cell 依存の incremental 評価。研究 tree とのアナロジー強い
- **Spago** (PureScript build tool): 純粋関数型 ecosystem の build system

---

# Appendix: 引用元一覧

## Bazel
- https://bazel.build/
- https://bazel.build/reference/skyframe
- https://bazel.build/extending/aspects
- https://bazel.build/versions/8.6.0/basics/hermeticity
- https://github.com/bazelbuild/bazel
- https://www.gocodeo.com/post/how-bazel-works-dependency-graphs-caching-and-remote-execution

## Nix flake
- https://nix.dev/concepts/flakes.html
- https://wiki.nixos.org/wiki/Flakes
- https://gist.github.com/edolstra/40da6e3a4d4ee8fd019395365e0772e7
- https://www.tweag.io/blog/2021-12-02-nix-cas-4/
- https://nix.dev/manual/nix/2.34/store/derivation/
- https://wiki.nixos.org/wiki/Ca-derivations

## Buck2
- https://buck2.build/
- https://buck2.build/docs/about/why/
- https://buck2.build/docs/developers/architecture/buck2/
- https://buck2.build/docs/insights_and_knowledge/modern_dice/
- https://buck2.build/docs/rule_authors/dep_files/
- https://buck2.build/docs/rule_authors/dynamic_dependencies/
- https://buck2.build/docs/rule_authors/anon_targets/
- https://buck2.build/docs/concepts/glossary/
- https://www.tweag.io/blog/2023-07-06-buck2/
- https://engineering.fb.com/2023/04/06/open-source/buck2-open-source-large-scale-build-system/
- https://ndmitchell.com/downloads/slides-what_makes_buck2_special-22_may_2025.pdf

## Doxygen
- https://www.doxygen.nl/manual/diagrams.html
- https://www.doxygen.nl/manual/examples/diagrams/html/graph_legend.html

## Sphinx
- https://www.sphinx-doc.org/en/master/
- https://www.sphinx-doc.org/en/master/usage/extensions/intersphinx.html
- https://www.sphinx-doc.org/en/master/usage/extensions/autodoc.html
- https://www.sphinx-doc.org/en/master/usage/referencing.html
- https://sphobjinv.readthedocs.io/en/stable/syntax.html

## Pandoc
- https://pandoc.org/lua-filters.html
- https://pandoc.org/filters.html
- https://github.com/jgm/pandoc

## Unison
- https://www.unison-lang.org/docs/the-big-idea/
- https://www.unison-lang.org/docs/tour/
- https://github.com/unisonweb/unison
- https://lwn.net/Articles/978955/
- https://softwaremill.com/trying-out-unison-part-1-code-as-hashes/

## Dhall
- https://dhall-lang.org/
- https://docs.dhall-lang.org/discussions/Safety-guarantees.html
- https://github.com/dhall-lang/dhall-lang
- https://hackage.haskell.org/package/dhall

---

**サーベイ完了日**: 2026-04-17
**ファイル長**: 約 850 行
**観点網羅性**: 10 観点 × 8 対象 = 80 セル（一部緩い対象あり）
**次のアクション**: グループ A-C, E, F の結果と統合し `00-synthesis.md` で横断的知見を抽出
