# 新研究基盤サーベイ計画

**作成日**: 2026-04-17
**目的**: agent-manifesto プロジェクトの研究プロセス記録を GitHub Issue 依存から脱却し、Lean 言語による型安全な tree structure + 半順序関係 + traceability 保証 + 自作 Pipeline に再設計するための先行研究サーベイ。

## 問題設定

現行の `/research` スキルには以下の構造的限界がある:
- Sub-Issues テーブル更新、Tree Context、依存関係、成果物との関連付けが Issue 内テキストの手動メンテナンスに依存
- LLM が deterministic な作業（テーブル整合性、依存伝播、参照保守）に負荷を取られ、judgmental タスクに集中できない
- "#NNN を参照" の魔法依存により、退役・参照不能の検出が機械的にできない
- マニフェスト T1/T2、P3、P4、D13 と整合的でない（既存の Lean 公理系 + /trace + artifact-manifest.json を活用すべき）

## 目標基盤の特徴

- **Canonical は Lean 文書**: 研究プロセスの全記録（Survey, Gap, Hypothesis, Decomposition, Implementation）を Lean 型として表現
- **自作 Pipeline**: DSL → AST → Lean → SMT → Test → Code の精緻化パイプライン
- **GitHub Issue は降格**: tree 末端の `developmentFlag` つき実装ノードのみ Issue 化。Issue は read-only 表示・PR 連携レイヤー
- **deterministic 負荷の撤廃**: テーブル整合、依存伝播、参照保守を Lean コンパイラと自作 Pipeline で構造的に強制
- **judgmental への集中**: LLM は仮説生成、精読、比較検討、設計判断に専念

## カバー済み領域（高確度）

以下は `research/survey_type_driven_development_2025.md`（high-tokenizer プロジェクトからの参考文献）で既に包括的に精読済み。本サーベイではこれらを前提として扱い、重複調査しない。

- **TyDD 理論と実装**: 8 ソース精読（ICPC 2026 "The Way of Types"、Lean-Auto、Lean4Lean、Liquid Haskell、Idris 2 QTT、TyDe 2025、Effect-TS、TyDe workshop history）
- **TyDe 2025 papers**: 4 論文精読（NbE performance, conatural numbers semiring, gradual metaprogramming, opaque definitions）
- **12 実装 Recipes**: Z3 refinement type encoding、Lean-Auto VBS tactic、pytest 生成、LLM プロンプト、bidirectional codec、opaque TypeSpec 等
- **Design patterns B1-B6, C1-C3, F1-F8, H1-H11** 等の Tag Index

## 前進資産（本プロジェクト外部）

- `research/survey_type_driven_development_2025.md`: TyDD サーベイ（1406 行）
- **high-tokenizer プロジェクト** (`~/work/high-tokenizer/`): spec-driven workflow の動作事例
  - `lean/SpecSystem/Basic.lean` (62 行, 0 sorry): TypeSpec / FuncSpec / 精緻化半順序
  - `lean/SpecSystem/Theory.lean` (131 行): ConceptDepth, compression capacity
  - `pipeline/` (Python): DSL parser, AST, codegen (Lean/Python/SMT), LLM refine loop
  - `specs/`: spec_system_core.spec, dsl_spec.spec, dsl_parser.spec（自己ホスティング）
  - `docs/ref/spec_system.md`: `Spec = (T, F, ≤, Φ, I)` 設計

## サーベイ対象（6 グループ）

### グループ A: 知識グラフ・Zettelkasten ツール

**問い**: ノード間の双方向リンク、block reference、backlink、graph view をどう型安全に表現するか？

対象:
- Zettelkasten 原理（Niklas Luhmann's method）: 原子ノート、スリップボックス
- Roam Research: block reference、daily notes、graph overview
- Obsidian: bidirectional linking、graph view、Canvas、Dataview plugin
- Tana: super-tags、query builder、block-level semantics
- LogSeq: outliner + graph、block embeddings、page properties
- Foam / Dendron: Markdown ベース、hierarchical naming、VSCode 統合
- TiddlyWiki: single-page wiki、tiddler-level granularity、tagging model

**抽出観点**: link 型、trace 可能性、退役検出、重複検出、階層/グラフ選択

### グループ B: Data Provenance / Workflow Tracking

**問い**: 科学計算・ML 実験で研究プロセスの provenance をどう形式化し永続化するか？

対象:
- W3C PROV (Prov-O, Prov-DM): Entity / Activity / Agent の three-way relationship
- Common Workflow Language (CWL): 抽象ワークフロー仕様、実行エンジン非依存
- ResearchObject framework: 研究成果物のパッケージング、RO-Crate
- Snakemake: DAG-based workflow、rules、incremental execution
- Nextflow: reactive workflow、data-driven、containerization
- Galaxy: web-based workflow、share/reproduce
- MLflow: experiment tracking、model registry、artifact store
- DVC (Data Version Control): git-like for data、pipeline reproducibility

**抽出観点**: lineage 表現、immutable records、retraceability、失敗した実験の記録、陳腐化検知

### グループ C: Lean 4 メタプログラミング・DSL 設計

**問い**: Lean 4 で研究 tree を表現する DSL をどう設計・拡張するか？ メタプログラミング能力を最大活用するパターン

対象:
- mathlib4 のメタプログラミングパターン: tactic framework、simp lemmas、norm_cast
- ProofWidget: リッチな UI for Lean proofs（David Thrane Christiansen）
- Lean 4 macro, elab, syntax 拡張: `macro`, `syntax`, `elab` コマンド、BNF notation
- Verso: Lean 4 用ドキュメンテーション DSL
- doc-gen4 / mathlib4 docstring tooling: 自動文書生成
- Aesop: extensible rule-based proof search
- Duper: saturation prover

**抽出観点**: syntax 拡張の基本パターン、compile-time 検証、型安全 DSL、elab でのメタ計算、Lean を build system として使うパターン

### グループ D: Type-Safe Document / Build Graph

**問い**: 文書・コード・仕様の依存グラフを型安全・immutable・incremental に管理するシステム

対象:
- Bazel: BUILD ファイル、依存グラフ、hermetic build、remote caching
- Nix flake: immutable inputs、content-addressed store、reproducible
- Buck2: Meta の build system、dependency graph、Starlark DSL
- Doxygen call graph: C++ の関係図生成
- Sphinx: cross-reference、intersphinx、autodoc
- Pandoc filter: 文書間変換、AST 操作
- Unison language: content-addressed codebase、structural dependency

**抽出観点**: 依存の表現、incremental recomputation、content-addressing、不変条件

### グループ E: Plain Text Issue Tracker 代替

**問い**: Issue を plain text/file として永続化し、状態遷移を管理する方式

対象:
- Bugs Everywhere: distributed bug tracker、bugs along code
- git-issue: issue as git artifact
- SIT (Serverless Information Tracker): append-only, plain text
- gtm / git-ticket: git-native ticket management
- Org-mode TODO: Emacs、state machines、agenda
- GitHub Discussions vs Issues: メタモデルの違い
- Linear / Plane: メタモデル参考（cycle, roadmap）
- Lean4 ProofWidget for interactive issue UI

**抽出観点**: テキスト永続化フォーマット、状態遷移、ローカルファースト、他ツールとの連携、Git との関係

### グループ F: 既存 agent-manifesto 内資産の精読

**問い**: 新基盤に再利用できる既存資産は何か？ 何を削除・置換すべきか？

対象:
- `.claude/skills/trace/`: /trace skill と `manifest-trace coverage`
- `.claude/skills/generate-plugin/`: D17 state machine
- `.claude/skills/spec-driven-workflow/`: 仕様駆動開発
- `.claude/skills/ground-axiom/`, `.claude/skills/formal-derivation/`
- `lean-formalization/Manifest/`: 55 axioms, 1670 theorems, 0 sorry (2026-04-17 実測), TaskClassification.lean
- `artifact-manifest.json`: 成果物メタデータ
- `.claude/skills/research/scripts/`: propagate.sh, closing.sh, worktree.sh, issue-template.sh
- `.claude/hooks/`: 既存フック

**抽出観点**: 新基盤との統合境界、既存テストカバレッジ、公理系との整合、削除可能な重複

## 実施方法

- **並列実施**: グループ A-E は外部 URL アクセスが必要なため、general-purpose / claude-code-guide agent で並列実施
- **グループ F は内部**: Explore agent で agent-manifesto 内を直接調査
- **各グループの成果物**: `01-group-A.md` から `06-group-F.md`（各 300-500 行想定）
- **統合**: `00-synthesis.md` で横断的知見を抽出（前回の deep-research-survey と同じ 5 Parts 構造を踏襲）

## 精度基準（前回サーベイと同等）

- 各グループで 5-8 対象精読
- 横断的知見の抽出（比較表、定量データ、アーキテクチャパターン分類）
- Verifier 独立検証 2 ラウンド（addressable=0 + 修正後変更なし）
- 統合まとめの Gap Analysis 入力可能性（`Spec = (T, F, ≤, Φ, I)` の各要素について、外部の知見から導出される制約・機会を洗い出す）

## Deliverables

- `00-survey-plan.md`（本ファイル）
- `01-knowledge-graph-tools.md`（グループ A）
- `02-data-provenance.md`（グループ B）
- `03-lean-metaprogramming.md`（グループ C）
- `04-build-graph-systems.md`（グループ D）
- `05-plaintext-issue-tracker.md`（グループ E）
- `06-internal-assets.md`（グループ F）
- `00-synthesis.md`（統合まとめ）
- Verifier 検証記録（`99-verifier-rounds.md`）

## 非スコープ

- TyDD 理論（既に `research/survey_type_driven_development_2025.md` で cover 済）
- Deep Research 領域（前回の `docs/research/deep-research-survey/` で cover 済）
- LLM 推論最適化（本サーベイの目的と直交）
