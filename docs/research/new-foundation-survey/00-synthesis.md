# 新研究基盤サーベイ統合まとめ

> 15 グループ精読ノート（01-06 + G1-G5）を横断的に統合した知見。
> 作成日: 2026-04-17（G1-G4 補遺、G5 (Atlas 関連) 補遺はいずれも同日追加）
> 対象: agent-manifesto プロジェクトの研究プロセス記録基盤を、GitHub Issue 依存から Lean 言語による型安全な tree structure + 半順序関係 + traceability 保証 + 自作 Pipeline に再設計するための先行研究知見の統合。
> 前提資産: `research/survey_type_driven_development_2025.md`（TyDD 1406 行、12 Recipes、Tag Index）、high-tokenizer プロジェクトの spec-driven workflow 実装（`Spec = (T, F, ≤, Φ, I)`）、`research/lean4-handoff.md`（Lean 4 学習 handoff、Atlas 12 プロジェクト提案書を含む）。

---

## 1. サーベイの全体像

### 1.1 対象とした 15 グループ・74 対象

| グループ | 対象数 | 行数 | 主題 |
|---|---|---|---|
| A: 知識グラフ・Zettelkasten | 7 | 708 | Zettelkasten, Roam, Obsidian, Tana, LogSeq, Foam/Dendron, TiddlyWiki |
| B: Data Provenance | 8 | 542 | W3C PROV, CWL, RO-Crate, Snakemake, Nextflow, Galaxy, MLflow, DVC |
| C: Lean 4 メタプログラミング | 8 | 878 | macro/syntax/elab, mathlib4 norm_cast, ProofWidgets4, Verso, doc-gen4, Aesop, Duper/Lean-Auto, Lake |
| D: Build Graph | 8 | 1017 | Bazel, Nix flake, Buck2, Doxygen, Sphinx, Pandoc filter, Unison, Dhall |
| E: Plain Text Issue Tracker | 8 | 812 | Bugs Everywhere, git-issue, SIT, git-bug, Org-mode, GH Issues/Discussions, Linear, Fossil |
| F: 既存 agent-manifesto 内資産 | 8 | 405 | /research, /trace, /generate-plugin, /spec-driven-workflow, /ground-axiom, /formal-derivation, Lean Manifest, scripts/hooks |
| G1: Lean 4 産業応用 (補遺) | 5 | 582 | AWS Cedar (lean-lang.org/use-cases), arxiv 2407.01688v1, AWS blog 2 件, Amazon Science |
| G2: AI 出力 Lean 4 検証 (補遺) | 7 | 622 | Mistral Leanstral, Harmonic Aristotle, AlphaProof, Lean Copilot, APOLLO, Goedel-Prover, VentureBeat |
| G3: 仕様生成・vericoding (補遺) | 6 | 598 | VERIFYAI, CLEVER NeurIPS 2025, VerifyThisBench, VeriBench ICML 2025, Vericoding, Atlas speclib |
| G4: Lean 4 サーベイ・メタ視点 (補遺) | 4 | 467 | AMO-Lean, Tang Survey 2501.18639, Kleppmann mainstreaming, LLM-Based Theorem Provers |
| G5-1: CSLib + Boole (補遺) | 1 | 606 | CSLib (speclib 現存実装) + Boole SMT ハンマー |
| G5-2: ATLAS Dafny POPL 2026 (補遺) | 1 | 423 | ATLAS (arxiv 2512.10173) — Dafny 82% の根本原因 |
| G5-3: VeriSoftBench (補遺) | 1 | 205 | arxiv 2602.18307 — リポジトリ規模ベンチマーク |
| G5-4: LeanDojo eco-system (補遺) | 1 | 331 | LeanDojo, LeanAgent, LeanProgress, Pantograph |
| G5-5: Lean4Lean 差分 (補遺) | 1 | 266 | Unique Typing 2026-01 proved, Carneiro 2019 no longer applicable |
| **合計** | **74** | **8462** | |

**公理系実測値** (2026-04-17 測定、CLAUDE.md のカウントコマンド準拠):
- axiom: 55 (core Manifest/)
- theorem: 1670 (core Manifest/)
- sorry: 0 (`by sorry` 実出現数)

### 1.2 グループ間の関係図

```
                       新研究基盤の設計目標
                              │
        ┌─────────────┼──────────────────┐
        │             │                  │
   [Canonical 表現]  [Pipeline]    [可観測性 + 同期]
        │             │                  │
   ┌────┼────┐    ┌──┼──┐         ┌────┼────┐
   │    │    │    │  │  │         │    │    │
   A    C    F    C  D  F         B    E    F
 知識  Lean  既存  Lean Build 既存  Prov  Issue 既存
  グ   メタ  資産  メタ Graph 資産  enance Track 資産
 ラフ                                         er
```

**カテゴリ間の関係**:
- **Canonical 表現**（A + C + F）: 何を Lean 型で表現するか（ノード型、半順序、退役、状態）
- **Pipeline**（C + D + F）: Lean source から SMT/Test/Codegen への構造的変換
- **可観測性 + 同期**（B + E + F）: provenance/lineage、Issue 同期、影響波及の機械化

### 1.3 既存資産との位置付け

- **TyDD サーベイ（既往）**: 型駆動開発の理論的・実装的基盤を 12 Recipes として確立済（B1-B6, C1-C3, F1-F8, H1-H11）
- **high-tokenizer**（既往）: `Spec = (T, F, ≤, Φ, I)` の動作実装、自己ホスティング Phase A-1 完了
- **本サーベイ**: 上記を前提に、研究プロセス記録の特殊用途に特化した知見を追加（Issue 降格、退役、provenance、Lean メタプロの研究 tree への適用）

---

## 2. 横断的知見の抽出

### 2a. Canonical を Lean に固定するために必要な要素

#### 比較表

| グループ | ノード型 | 半順序 ID | 退役表現 | edge type | 推奨パターン |
|---|---|---|---|---|---|
| A 知識グラフ | Tana supertag (型理論最近) | Folgezettel (Luhmann) | **全ツール欠落** | 弱い (backlink only) | Lean inductive + namespace |
| B Provenance | PROV Entity/Activity/Agent | wasDerivedFrom (推移的のみ) | wasInvalidatedAt (限定) | PROV 11 種 | inductive + WasDerivedFrom 型 |
| C Lean メタプロ | EnvExtension + attribute | structural relation (decide) | linter で warning 化 | -- | `@[research_node]` attribute |
| D Build Graph | Bazel target | deps (DAG) | -- | dep file (Buck2) | Lake target + Lean import graph |
| E Issue Tracker | Linear category (硬) + label (軟) | Linear sub-issue | retired = state | blocks/blocked-by/related | enum + state machine type |
| F 内部資産 | PropositionId / NodeId | manifest-trace coverage | retire field 未定義 | refs (artifact-manifest) | Ontology.lean に AssumptionId 追加 |

#### 最も有効なアプローチと根拠

**1. Tana supertag + Lean inductive + Dendron hierarchical naming の三段重ね**

A グループで Tana の supertag が「PKM ツールの中で最も型理論に近い」（A-3.3 U3）。これは Lean の `inductive ResearchNode` に直接マップ可能。Dendron の hierarchical naming は Lean namespace と完全同型（A-3.3 U2）— ファイルパスがそのまま研究 tree の構造的アドレスになる。

```lean
-- Tana supertag = Lean inductive constructor
-- Dendron hierarchical naming = Lean namespace
namespace Research.NewFoundation.GroupA
  inductive ResearchNode where
    | survey      (id : NodeID) (sources : List URL)
    | gap         (id : NodeID) (claim : Prop)
    | hypothesis  (id : NodeID) (claim : Prop) (parent : NodeID)
    | decomposition (id : NodeID) (children : List NodeID)
    | implementation (id : NodeID) (developmentFlag : Bool)
    | retired     (id : NodeID) (reason : RetirementReason) (replacedBy : Option NodeID)
end Research.NewFoundation.GroupA
```

**2. Folgezettel ID + Lean DecidableEq 半順序**

A の Folgezettel（`1a3 ≤ 1a` が文字列演算で判定可、A-3.3 U1）を Lean structure として再現。以下は**設計スケッチ**（PoC コンパイル未検証）:

```lean
-- 補助: Sum 型に BEq が自動 deriving されないため明示
instance [BEq α] [BEq β] : BEq (α ⊕ β) where
  beq
    | .inl x, .inl y => x == y
    | .inr x, .inr y => x == y
    | _, _ => false

structure FolgeID where
  path : List (Nat ⊕ Char)  -- "1a3" = [Sum.inl 1, Sum.inr 'a', Sum.inl 3]
  deriving Repr

-- isPrefixOf は Bool を返すため、LE (Prop) 用に `= true` で変換
instance : LE FolgeID := ⟨fun a b => a.path.isPrefixOf b.path = true⟩
```

これにより親子関係が型レベルで自動的に半順序を成す（A-4.3）。PROV の `wasDerivedFrom` 推移性（B-3.1）と組み合わせれば、研究 tree の整合性が compile-time に保証される。

**3. 退役の first-class 化（独自貢献領域）**

A の C1 共通課題（**全 PKM ツールで退役検出が欠落**）と B の gap analysis（PROV/CWL/RO-Crate 含む全対象で `retired` first-class 表現なし、B-3.7）が一致して指摘。これは agent-manifesto P3 の独自性を構造的に裏付ける（A-3.2 C1）。

以下は**設計スケッチ**（PoC コンパイル未検証、Phase 1 実装時に正式型チェック）:

```lean
-- Note: 以下は設計意図の表現であり、`rationale` や `references` 等は
-- ResearchNode の実装時に具体化される placeholder。

inductive RetirementReason where
  | refuted (evidence : Evidence)
  | superseded (replacedBy : NodeID)
  | scopeChange (rationale : String)
  | obsolete (reviewDate : Date)

-- 「active な node m が retired な node n を参照することは禁止」
-- 結論は `¬ m.references.contains n.id` で 01-knowledge-graph-tools.md §4.4 と統一:
theorem no_active_reference_to_retired :
  ∀ (n m : ResearchNode), n.isRetired → ¬ m.isRetired →
    ¬ m.references.contains n.id
```

Lean compiler が「退役済 entity への参照」を warning/error として検出（custom linter または elaborator）。これは Issue ベース運用では検出不可能だった機能（A-4.4）。

**4. Edge type の inductive 化**

A の Q5（edge type は全ツールで弱い）、B の PROV 11 edge types、E の Linear blocks/blocked-by/related の三系統を統合。以下は**設計スケッチ**（Phase 1 実装時に正式型チェック）:

```lean
-- 各 constructor で両端を明示引数として取る
inductive ResearchEdge : ResearchNode → ResearchNode → Type where
  | wasDerivedFrom (a b : ResearchNode) : ResearchEdge a b  -- B PROV
  | refines        (a b : ResearchNode) : ResearchEdge a b  -- A Folgezettel
  | refutes        (a b : ResearchNode) : ResearchEdge a b  -- 独自
  | blocks         (a b : ResearchNode) : ResearchEdge a b  -- E Linear
  | relates        (a b : ResearchNode) : ResearchEdge a b  -- E
  | wasReplacedBy  (a b : ResearchNode) : ResearchEdge a b  -- 退役
```

---

### 2b. deterministic 負荷を撤廃するための機械化パターン

#### 比較表

| グループ | 機械化対象 | 中核メカニズム | 関連定量データ |
|---|---|---|---|
| A | Backlink 同期 | Pipeline pure function（手動メンテ廃止） | Roam: 10k blocks 超で O(n²) 劣化 |
| B | Lineage 計算 | content hash（mtime 廃止） | DVC, Snakemake 6+, MLflow w/ DVC が移行 |
| C | Sub-Issues テーブル更新 | EnvExtension + `@[attribute]` 自動登録 | norm_cast/aesop が採用 |
| D | 影響波及 (D13) | reverse deps index + early cutoff | Skyframe / DICE / CA-Nix 全採用 |
| E | 状態遷移 | append-only event + reducer | SIT/git-bug/Fossil 独立収束 |
| F | 既存重複 | Gate 判定/修正ループ/グラフ走査の抽出分離 | 3 系統で重複検出 |

#### 最も有効なアプローチと根拠

**1. Attribute による environment extension（C-3.1 P2）**

C の P2 が指摘: norm_cast / simps / aesop / Lean-Auto がすべて採用するパターン。`@[research_node]` 属性を書くだけで自動的に index に登録される。これは「LLM が手で table を保守する」現状からの脱却に **直接的に有効**:

```lean
-- ユーザコード
@[research_node]
def Survey.luhmann.principleAtomic : ResearchNode := ...

-- 内部: EnvExtension が自動登録
-- 集約処理（Sub-Issues テーブル相当）は EnvExtension 走査で生成
```

**2. Append-only event + reducer による state 導出（E-3.1 A）**

SIT, git-bug, Fossil が独立に到達した CQRS / Event Sourcing パターン。新基盤の Lean canonical も `event log + foldEvents で snapshot 導出` とすべき:

```lean
def snapshot (events : List LeafEvent) : LeafSnapshot :=
  events.foldl applyEvent initialSnapshot
```

利点（E-3.1 A）:
- Merge conflict が CRDT で解ける
- 履歴が完全保持
- Schema 進化時に replay で再構築可能

**3. Content hash + Reverse deps index（D-3.1.2, D-4.4）**

D の 3.1.2 で **semantic hash**（Dhall normal-form, Unison AST hash）を抽出。これと Bazel の reverse query を組み合わせる:

```lean
def affectedBy (changed : SpecId) : Array SpecId :=
  manifestEntries.filter (·.inputs.contains changed)
```

これにより、`/research` の Step 6d（後続 Sub-Issue 再評価）が完全自動化される。`manifest-trace why <id>` で「なぜ再評価された」を Bazel aquery 相当で追跡可能（D-4.3）。

**4. Lake を build system として活用（D-4.5）**

D の 4.5 が指摘: Lean の `lake` build tool は既に SkyFunction 風 incremental（依存解決、`.olean` cache）を提供。**別途 Skyframe 相当を書く必要なく、Lean compiler 自体が Skyframe として機能する**。これは新基盤の最大のレバレッジ（複雑性を削減できる）。

**5. F-Section3 の 3 系統重複の抽出分離**

F の Section 3 で発見:
- 重複 1: Gate 判定パターン（`/research` Step 6c vs `/generate-plugin` verify gates）→ `gate-judgment-template.sh` 抽出
- 重複 2: 修正ループ（`/research` Step 1.5/3.5 vs `/formal-derivation` Phase 3）→ `repair-loop-engine.sh` 統一
- 重複 3: 依存グラフ走査（`propagate.sh successor-list` vs `depgraph.sh impact`）→ 共通 `graph-traverse.sh` 抽出

これらは新基盤への移行と同時に実施すれば、DRY と機械化を同時達成できる。

---

### 2c. judgmental タスクへの集中を可能にする支援機構

#### 比較表

| グループ | 支援機構 | 効果 |
|---|---|---|
| A | Tana live query / supertag | LLM がノード型を意識せずに作成 |
| B | RO-Crate Workflow Run profile 三層 | judgmental commitment の段階化（最小 → 中 → 完全） |
| C | ProofWidgets による interactive view | 研究 tree を React で graph 表示、judgmental 評価の対話化 |
| C | typed holes as LLM prompts | sorry の goal type を構造化プロンプト化（TyDD H4 既出） |
| D | Bazel aspects / Buck2 BXL | 後付けの judgmental 解析を attach |
| E | Linear 6 categories 強制 | judgmental 状態遷移の選択肢を限定 |
| F | Assumption 型（既存）+ 反証条件 | judgmental な外部事実を構造化 |

#### 最も有効なアプローチと根拠

**1. ProofWidgets による tree 可視化（C-4.5）**

C の 4.5 が示す通り、研究 tree の半順序関係を React で graph 表示できる:

```lean
@[widget_module]
def researchTreeWidget : Module where
  javascript := include_str ".lake/build/widget/research-tree.js"
```

LLM が judgmental 判定するときに、tree の現状をリアルタイム可視化できる。Obsidian の graph view と同じ UX を Lean 内で実現。

**2. Verso genre による文書統合（C-4.4）**

C の 4.4: `Research` という新 genre を Lean function として定義。block: `surveyBlock`, `gapBlock`, `hypothesisBlock`, `decompositionBlock`。各 block が型レベルで構造化されるため、LLM は「block 種別を意識せずに内容を埋める」ことに集中できる。

**3. RO-Crate 風の段階的 commitment（B-3.4）**

最小 conformance（Survey ノードのみ）→ 中間（Survey + Hypothesis）→ 完全（全 Spec lineage）の段階化。LLM は「現フェーズで必要な commitment レベル」のみに集中できる。

**4. Failure first-class（B-4.3）**

`Failure : ResearchEntity` を最初から型に組み込み、`whyFailed : Failure → FailureReason` を total function として要求。LLM の judgmental 判定（なぜ失敗したか）を構造化して記録。

```lean
inductive FailureReason where
  | hypothesisRefuted (evidence : Evidence)
  | implementationBlocked (blocker : Spec)
  | specInconsistent (inconsistency : InconsistencyProof)
  | retired (replacedBy : ResearchEntity)
```

---

## 3. アーキテクチャパターンの分類

### 3.1 全体アーキテクチャ（5 層）

C の 3.4 で提示されたレイヤ構造を、他グループの知見で補強:

```
┌─────────────────────────────────────────────────────────┐
│  Layer 5: Verso 文書（Survey / Gap / Hypothesis / Decomp）│
│           genre = ResearchGenre (C-4.4)                 │
│           Tana supertag 同型 (A-3.3 U3)                  │
├─────────────────────────────────────────────────────────┤
│  Layer 4: ProofWidgets (tree/graph/status UI) (C-4.5)    │
│           Obsidian graph view 相当 (A-1.3)              │
│           JSON RPC + React                              │
├─────────────────────────────────────────────────────────┤
│  Layer 3: doc-gen4（API ref 自動生成）(C-1.5)            │
├─────────────────────────────────────────────────────────┤
│  Layer 2: 研究 tree DSL（syntax + elab）(C-4.1)          │
│           @[research_node] / @[refines] (C-3.1 P2)       │
│           EnvExtension に集約                            │
│           PROV Entity/Activity/Agent (B-4.1)            │
│           Append-only event + reducer (E-3.1 A)         │
├─────────────────────────────────────────────────────────┤
│  Layer 1: Lake（custom target、incremental build）(C-4.3)│
│           Spec → AST → Lean → SMT → Test → Code         │
│           Skyframe 相当を Lean compiler に委譲 (D-4.5)   │
│           Reverse deps index in artifact-manifest (D-4.3)│
└─────────────────────────────────────────────────────────┘

外部接点 (一方向 export):
   ├→ GitHub Issue (developmentFlag = true の leaf のみ) (E-4.2)
   │   git-bug bridge パターン (E-3.2 G)
   │   Fossil global/local 分離 (E-3.2 E)
   ├→ JSON-LD / RO-Crate (B-4.7)
   │   外部 tool (WorkflowHub, Galaxy) との interop
   └→ Markdown view (人間閲覧、Tana lossless export 相当) (A-3.3 U4)
```

### 3.2 4 軸での既存システム分類

各グループの代表システムを 4 軸で分類:

| システム | Canonical | 半順序型化 | Incremental | 退役 first-class |
|---|---|---|---|---|
| Roam Research | DB | × | △ | × |
| Obsidian | Markdown | × | △ (graph view) | × |
| Tana | DB (proprietary) | △ (supertag) | ○ | × |
| Dendron | Markdown + schema | △ (naming) | ○ | × |
| W3C PROV | OWL/JSON-LD | △ (推移のみ) | × | △ (wasInvalidatedAt) |
| Snakemake | Python | △ (DAG) | ○ (rule level) | × |
| MLflow | DB + git | × | △ (run level) | △ (Registry stage) |
| DVC | git + lockfile | △ (DAG) | ○ (hash) | × |
| Bazel | BUILD (Starlark) | ○ (deps DAG) | ◎ (Skyframe) | × |
| Nix flake | Nix expression | ○ (immutable) | ◎ (CA store) | × |
| Buck2 | Starlark | ○ (DICE) | ◎ (dep files) | × |
| Unison | Content-addressed | ○ (hash) | ◎ | × |
| Dhall | total functional | ○ (semantic hash) | ◎ | × |
| git-bug | git object | × | △ | × |
| Fossil | SQLite + global/local | △ | △ | × |
| Linear | DB | △ (sub-issue) | × | △ (state) |
| **新基盤（提案）** | **Lean source** | **◎ (DecidableEq + 型)** | **◎ (Lake)** | **◎ (inductive constructor)** |

**新基盤の独自性**: 4 軸すべてで ◎ を取る既存システムは無い。**Canonical を Lean 文書とすることで 4 軸を同時に達成可能**。

### 3.3 Pipeline パターン

C の 4.3 + D の 3.1.1（依存の透明性階層）+ B の 3.2（二層分離）を統合:

```
[git tracked / metadata layer]
  Lean source (research tree DSL)
    ├→ Lake target: researchTree → tree.json
    ├→ Lake target: smtVerified → SMT proof artifact
    ├→ Lake target: testGen → pytest from FuncSpec
    ├→ Lake target: docGen → Verso HTML + doc-gen4
    ├→ Lake target: syncIssues → gh issue create/edit
    └→ Lake target: roCrateExport → JSON-LD provenance

[content-addressed / artifact layer]
  artifact-manifest.json (拡張版)
    + content_hash (SHA-256)
    + semantic_hash (Lean normal form)
    + inputs (依存 spec/artifact)
    + accessed_inputs (Buck2 dep files 相当)
    + invalidates (Skyframe reverse deps)
  artifact payload (external storage)
```

---

## 4. 能力分離の設計提案

### 4.1 分離すべき能力のリスト（13 件）

| # | 能力 | 説明 | 根拠グループ |
|---|---|---|---|
| 1 | **ResearchNode 型** | 型安全な node 表現、phase/edge/retire constructor | A-4.1, B-4.1, F |
| 2 | **Folgezettel ID** | 半順序を ID 自体に埋め込む structure | A-3.3 U1 |
| 3 | **Provenance Triple** | (Activity, Entity, Agent) の Lean 型 | B-4.1 |
| 4 | **Failure First-Class** | Failure を separate type、whyFailed 必須 | B-4.3 |
| 5 | **Retirement Linter** | 退役済 entity への参照を compile-time error | A-4.4, B-4.4 |
| 6 | **Edge Type Inductive** | wasDerivedFrom/refines/refutes/blocks/relates の inductive | A-Q5, B, E |
| 7 | **EnvExtension Auto-Register** | `@[research_node]` で自動 index 登録 | C-3.1 P2 |
| 8 | **Append-Only Event Log** | event を canonical、snapshot は reducer で導出 | E-3.1 A |
| 9 | **Type-Safe State Machine** | LifeCyclePhase 遷移を `AllowedTransition : Prop` で強制 | E-4.3 |
| 10 | **Bidirectional Codec (Lean → gh)** | leaf node のみ Issue 化、片方向 export、冪等 | E-4.2 |
| 11 | **Reverse Deps Index** | artifact-manifest 拡張、D13 影響波及機械化 | D-4.3, D-4.4 |
| 12 | **Semantic Hash** | format 揺れに強い同一性判定 | D-3.1.2 (Dhall, Unison) |
| 13 | **ProofWidget Visualizer** | tree の React 可視化 | C-4.5 |

### 4.2 各能力の独立性の根拠

**Folgezettel ID の独立性**: A-4.3 で示されるように、`structure FolgeID` + `LE` instance のみで成立。他能力に依存しない pure data 構造。

**Failure First-Class の独立性**: B-4.3 が示すように、`inductive ResearchEntity` の constructor として独立追加可能。既存の Survey/Gap/Hypothesis に影響しない（保存拡大）。

**EnvExtension Auto-Register の独立性**: C-1.2 (norm_cast) と C-1.6 (Aesop) で独立に検証された汎用パターン。研究固有ロジックに依存しない。

**Reverse Deps Index の独立性**: D-4.3 のように artifact-manifest に field 追加するのみで、既存の forward deps 計算と直交。

**Semantic Hash の独立性**: D-3.1.2 で Dhall と Unison が独立に同パターンに到達。Lean の `whnf` / `reduce` で実装可能。

### 4.3 能力間のインターフェース設計

**矢印の意味**: `A → B` は **「A が B の構築に使われる（= B は A に依存する）」** を示す。つまり矢印の起点が先に存在し、終点がそれを利用して構成される。4.2 節「FolgeID の独立性」は「FolgeID は他能力を必要とせず単独で成立する」意味であり、矢印起点として複数能力に使われることと矛盾しない。

```
[FolgeID #2] ─→ [ResearchNode #1] ─→ [ProvenanceTriple #3]
                     │
                     ├→ [EdgeTypeInductive #6] ─→ [RetirementLinter #5]
                     │                          └→ [FailureFirstClass #4]
                     │
                     ├→ [EnvExtension #7] ─→ [AppendOnlyEventLog #8]
                     │                    └→ [TypeSafeStateMachine #9]
                     │
                     └→ [SemanticHash #12] ─→ [ReverseDepsIndex #11]

[RetirementLinter #5, FailureFirstClass #4, TypeSafeStateMachine #9,
 ReverseDepsIndex #11] ─→ [BidirectionalCodec #10] ─→ [ProofWidgetVisualizer #13]
```

独立性の整理:
- 起点（他能力に依存しない）: #2 FolgeID, #12 SemanticHash（両方 pure data）
- 中間層: #1 ResearchNode, #6 EdgeType, #7 EnvExtension
- 応用層: #3-#5, #8-#9, #11
- 統合層: #10 Codec, #13 Visualizer（複数能力を consume）

### 4.4 段階的導入の順序（Phase 1-5）と D4 フェーズ順序との対応

D4（フェーズ順序: 安全 L1 → 検証 P2 → 可観測性 P4 → 統治 P3 → 動的調整）との対応関係:

| Phase | 能力 | D4 対応 | 理由 | 期待効果 |
|---|---|---|---|---|
| **Phase 1** | #1 ResearchNode 型 + #2 FolgeID + #6 EdgeType | **安全 L1** | Lean canonical の基礎。型と半順序がないと L1 安全保証が型レベルで強制できない。`lake build` で T₀ 無矛盾性（制約 C1）を継承 | 「研究 tree が Lean の型として表現される」状態を達成 |
| **Phase 2** | #5 Retirement Linter + #9 State Machine + #4 Failure First-Class | **検証 P2** | Phase 1 で定義された型の不変条件（退役、状態遷移、失敗）を compile-time に検証する層。L1 で敷かれた型基盤に検証を重ねる（D4 順序準拠） | 不正な参照・遷移・失敗処理が CI で失敗 |
| **Phase 3** | #11 Reverse Deps + #12 Semantic Hash + #7 EnvExtension + #8 Event Log + Lake 統合 | **可観測性 P4** | 検証可能な型の上に、incremental 評価と自動集約を構築。V-metrics の before/after 計測が可能化。D13 影響波及が機械化 | Gate 再評価が必要箇所のみ走る、cache hit 最大化、Sub-Issues テーブル自動化 |
| **Phase 4** | #3 Provenance Triple | **統治 P3** | Lineage 構造化により学習の統治（観察→仮説化→検証→統合→退役）が形式化。RO-Crate export で外部 interop | 研究プロセスの完全な再現性、統治可能性の獲得 |
| **Phase 5** | #10 Bidirectional Codec + #13 ProofWidget Visualizer | **動的調整** | 統治層の上で外部接点（GitHub Issue、UI）を動的に調整可能化。判断にフィードバックが返る | GitHub と Lean が共存、judgmental 判定の対話化、動的な行動空間調整（D8） |

**Phase 横断**: F-Section 4 の制約条件（C1-C5）は全 Phase に適用:
- C1: T₀ 無矛盾性継承（lake build Manifest で検査）— Phase 1 以降の前提
- C2: Gate 判定停止条件（addressable 単調減少）— Phase 2 以降で検証
- C3: Lean コンパイル前提（CI hook）— 全 Phase
- C4: Worktree 隔離 — 全 Phase
- C5: T6 人間権威（C-type assumption）— Phase 4 で特に重要

---

## 5. 定量データの統合表

### 5.1 規模・性能データ

| システム | 指標 | 値 | 出典 |
|---|---|---|---|
| Roam Research | backlink 性能劣化点 | 10k blocks 超で O(n²) | A-3.2 C3 |
| Obsidian | graph view 性能劣化点 | 数万〜十万ノード（forum 報告） | A-3.2 C3 |
| Dendron | schema 検証コスト | 中規模で許容、大規模未検証 | A-3.2 C3 |
| Tana | 待機リスト | 160k+ users | A-1.4 |
| Bazel | モノレポ実績 | Google scale (10⁹ files) | D-1.1.9 |
| Nix flake | 再現性 | byte-identical for >95% derivations | D-1.2.4 |
| Buck2 | DICE incremental | dep files で過剰再評価削減 | D-1.3.2 |
| Lean 4 lake | incremental | `.olean` cache、import graph | C-1.8 |
| Snakemake | DAG ノード上限 | 数千〜数万 (rule level) | B-1.4 |
| Nextflow | LevelDB | single-writer 制限 | B-1.5 |
| MLflow | Run + Artifact store | DB + S3 二層 | B-1.7 |
| DVC | content hash 移行 | mtime 廃止、SHA-256 採用 | B-3.3 |
| git-bug | Lamport clock | 因果順序保証 | E-1.4 |
| Fossil | global/local 分離 | event log 全 peer 共有 | E-1.8 |
| Linear | sub-issue + 6 categories | 状態カテゴリ強制 | E-1.7 |
| **TyDD survey** | 12 Recipes | (既出) | research/survey_type_driven_development_2025.md |
| **high-tokenizer** | TypeSpec/FuncSpec | 62 行 0 sorry | F |

### 5.2 採用されたアーキテクチャパターンの数

| パターン | 採用システム数 | グループ |
|---|---|---|
| Append-only event + reducer | 3 (SIT, git-bug, Fossil) | E |
| Content hash based cache | 4 (DVC, Snakemake 6+, Bazel, Nix) | B + D |
| Two-layer (metadata git / artifact CA) | 4 (DVC, MLflow, Nextflow, Galaxy) | B |
| EnvExtension + attribute | 4+ (norm_cast, simps, aesop, Lean-Auto) | C |
| Reverse deps index | 3 (Bazel, Skyframe, DICE) | D |
| Semantic hash | 2 (Dhall, Unison) | D |
| PROV Entity/Activity/Agent | 8+ (CWLProv, RO-Crate, BCO, ...) | B |

---

## 6. 未解決の課題と研究機会

### 6.1 優先度付き課題リスト

| 優先度 | 課題 | 報告グループ | 我々への影響 | 対策の方向性 |
|---|---|---|---|---|
| **P0** | 退役 first-class 表現なし | A-3.2 C1, B-3.7 | agent-manifesto P3 のコア要求が前例なし | 独自設計（4.1 #5 Retirement Linter） |
| **P0** | 失敗 first-class 表現なし | B-3.5, B-3.7 | judgmental 判定の構造化が未踏 | Failure 型 + whyFailed total function (4.1 #4) |
| **P0** | judgmental rationale の構造化 | B-5.2 | 「なぜそうしたか」が全先行研究で未解決 | typed holes as LLM prompts (TyDD H4) + Verso block |
| **P0** | 仕様等価性証明の壊滅的困難（CLEVER 0.621% = 1/161） | G3-1.2, G3-2.1 | 新基盤の自動化目標を再設定する必要 | Phase 0 で agent-spec-lib 構築、Atlas augment 戦略（4.4 + 7.5） |
| **P0** | 「正しい仕様の生成」が全研究で未解決 | G2-4.1, G3-2.1 | AI 自動化に過度に依存できない | T6 人間権威 + speclib + IDE 共同編集 |
| **P1** | edge type の弱さ | A-Q5, B PROV 11種 | 「派生」「反証」「依存」を区別したい | Edge type inductive (4.1 #6) |
| **P1** | 仮説 first-class 表現なし | B-3.7 | research-specific gap | inductive constructor として hypothesis 追加 |
| **P1** | semantic hash 計算コスト | D-5.2.1 | Lean normal form の重さ | Repr structural hash + 必要時のみ semantic |
| **P1** | dynamic dependency の Lean 表現 | D-5.2 | Skyframe restart 相当を Lean でどう表現 | 段階的: Phase 3 で要検証 |
| **P1** | Vericoding 言語選択の決定的影響 (Lean 26.8% vs Dafny 82.2%) | G3-1.5 | Lean の SMT 弱さは事実 | Lean-Auto, Duper, AMO-Lean compile_rules で補強 |
| **P1** | culture change が Lean 4 メインストリーム化の限定要因 | G4-1.3 | チーム/組織採用への抵抗 | agent-manifesto の構造的強制（hooks, T6, P3）で対処 |
| **P1** | Dafny 空証明 44.7% の SMT 優位性 → Lean 側 SMT 強化必須 | G5-2 | 同タスクで Lean の人間/LLM 労力が桁違い | Duper / Lean-Auto / Boole (LeanHammer) 統合を必須化 |
| **P1** | リポジトリ規模で Mathlib 特化モデルが崩壊 (Goedel 0% on non-Mathlib) | G5-3 | agent-spec-lib は独立学習が必要 | LeanDojo Benchmark 形式で domain-specific corpus 構築 |
| **P1** | `looseBVarRange` bug の unsound assumption 降格 | G5-5 | 特定の最適化路径が unsound | native_decide / reduceBool は新基盤で回避 |
| **P2** | 大規模 graph の Lean compile 性能 | A-Q4, D-3.1.3 | 数千ノード超でのスケール | Lake incremental + dep files |
| **P2** | Implementation2Spec / InputOutput2Spec / InterFramework は未実現 | G5 Atlas 7.4 | Atlas 提案の空白領域 → 新基盤の貢献候補 | MVP 範囲外、将来の研究 roadmap |
| **P2** | agent-spec-lib vs CSLib の依存関係設計 | G5-1 | 独立サブライブラリ か CSLib contrib か | 独立推奨（G5-1 Section 3 の 3 層設計）、CSLib を依存宣言 |
| **P2** | block 単位 vs page 単位 | A-Q1 | 引用粒度の選択 | MVP は page 単位、後で block 引用 |
| **P2** | 重複検出の意味的レイヤー | A-Q3 | 内容類似性の自動検出 | LLM 統合の今後の主戦場 |
| **P3** | bidirectional codec の merge 戦略 | A-Q6, E-5.2 | Issue 編集の Lean への反映 | 片方向 (Lean → gh) で開始、reverse は MVP 範囲外 |
| **P3** | Verso cross-document cross-reference | C-5.2 | experimental 段階 | 重要依存にしない、breaking change を許容 |

### 6.2 特に重要な研究機会

**1. 退役 + 失敗 + judgmental rationale の三位一体（P0 × 3）**

A-3.2 C1（PKM 全ツール退役欠落）+ B-3.5（失敗の secondary 化）+ B-5.2（judgmental rationale 未解決）は、すべて「研究プロセス特化の構造化要求」が先行研究にないことを示す。これは agent-manifesto 新基盤の **最大の独自貢献領域**。

```lean
inductive ResearchEntity where
  | survey       (sources : List URL)
  | gap          (claim : Prop) (rationale : Rationale)  -- judgmental 構造化
  | hypothesis   (claim : Prop) (rationale : Rationale)
  | decomposition (children : List EntityID) (rationale : Rationale)
  | implementation (developmentFlag : Bool) (rationale : Rationale)
  | failure      (cause : FailureReason) (rationale : Rationale)  -- first-class
  | retired      (reason : RetirementReason) (replacedBy : Option EntityID)  -- first-class
```

`Rationale` が全 constructor で必須化されることで、judgmental rationale の構造化が型レベルで強制される。

**2. Lean を build system として使う（D-4.5）**

D の 4.5 が示す通り、Lean の `lake` build tool は既に Skyframe 風 incremental engine を内蔵。これを「研究 tree の build system」として転用すれば、別途 Skyframe 実装を書く必要がない。**最大のレバレッジ機会**。

**3. high-tokenizer の Spec System を研究 tree に拡張**

F で確認した既存資産の再利用可能性（統合境界マトリクス 14/15 対象 ≈ 93%）+ research/survey_type_driven_development_2025.md の 12 Recipes + high-tokenizer の `Spec = (T, F, ≤, Φ, I)` を統合した上での新基盤設計は、ゼロから始めるより遥かに低リスク。

**4. RO-Crate 互換 export による外部 interop（B-4.7）**

最終的に Provenance Run Crate として export 可能にすれば、外部 tool（WorkflowHub, Galaxy）と interop できる。Lean tree → JSON-LD への schema-preserving 変換を Lean meta-program として実装可能。

---

## 7. 補遺: Lean 4 応用事例とサーベイ統合（グループ G1-G4）

`research/lean4-handoff.md` で引用された Lean 4 応用研究 22 リンクを 4 サブグループ（計 2269 行）で網羅した結果。新基盤研究の達成可能性、設計戦略、長期合理性に直接影響する知見を以下に統合する。

### 7.1 達成可能性の現実的評価（G3 が示す厳しい現実）

**CLEVER ベンチマーク (NeurIPS 2025) の核心結果**: 最先端 LLM でも 161 問中 **1 問 (0.6%)** しか End-to-End（自然言語 → 仕様 → 実装 → 証明）に成功しない（G3-1.2）。

**根本原因**: 仕様等価性証明（spec certification）が壊滅的に困難。LLM は「仕様を書く」(80%+ コンパイル成功) ことはできるが、「書いた仕様が正しい」ことを抽象的に推論できない（G3-2.1）。

**Vericoding ベンチマークの言語選択効果**: Lean 26.8% vs Dafny 82.2%（G3-1.5）— 言語選択が成功率に決定的影響。Lean は SMT 自動化が弱い分、人間/LLM の証明労力が必要。

**Atlas Computing の戦略提案**: 完全自動化を諦め、**人間 + speclib + IDE の augment 戦略** を推奨（G3-1.6）。これは agent-manifesto の T6（人間の最終決定権）と整合。

**新基盤研究への含意（最重要）**:
- 「Lean DSL を LLM だけで自動生成する」前提を採用しない
- **agent-spec-lib**（agent-manifesto 公理系の Lean 4 化、Mathlib 相当の domain library）構築を Phase 0 として必須化
- Atlas X3DH 風 IDE で人間-LLM 共同編集
- VeriBench の Trace-style エージェント（成功率 60%）を `/research` skill に組込む

### 7.2 産業応用の実証（G1 Cedar VGD パターン）

**Verification-Guided Development (VGD)**: AWS Cedar が示す本番システムでの Lean 採用パターン。

**核心定量データ**（G1-1.2, G1-2.1〜2.6）:
- **Lean Model : Rust 本番 = 1 : 9.4**（モデルは本番の約 1/10）
- **Proof : Model = 3.4 : 1**（証明は Lean モデルの 3.4 倍）
- **Validator soundness 証明: 18 人日**
- **性能オーバーヘッド: 5μs vs 7μs**（許容範囲）
- **Differential Random Testing で 21 bug 検出**
- **全証明検証 185 秒**（CI 統合可能）
- **Symbolic Compiler の健全性・完全性が Lean で証明済み**

**新基盤への直接適用**:
1. Lean モデル = 研究 tree DSL の type definitions + theorems（軽量）
2. Pipeline 実装 = Python/shell（重量）
3. **Differential Random Testing**: Pipeline 出力が Lean モデルの仕様を満たすかランダム入力で検証（21 bug の経験則）
4. Compiler 自体に証明をつけるパターン → 自作 Pipeline の各 stage（DSL→AST→Lean→SMT→Test→Code）に Lean 証明を付ける

### 7.3 AI × Lean 検証の最先端（G2）

**核心定量データ**（G2-1.1〜1.7）:
- **Mistral Leanstral**: FLTEval pass@2 = **26.3** (Claude Sonnet 23.7 を上回る)
- **Harmonic Aristotle**: IMO 2025 で **5/6 問正解**（金メダル相当）
- **AlphaProof (DeepMind)**: IMO 2024 で **28/42**（銀メダル）
- **Lean Copilot**: タクティクス自動化 **74.2%**
- **APOLLO (NeurIPS 2025)**: miniF2F で **84.9%**（8B 未満 SOTA）
- **Goedel-V2-32B**: miniF2F で **90.4%**

**LLM × Lean パターン分類**（G2-2.1, 2.2）:
- 粒度軸: tactic-level（Lean Copilot）/ theorem-level（AlphaProof, Aristotle）/ proof-search-level（APOLLO, Goedel）
- 協調モード: hammer / repair loop / decomposition / informal+formal hybrid

**新基盤への 4-layer 適用案**（G2-3.6）:
1. Tactic-level 補助（Lean Copilot 風）— 日常的な小規模 sorry 解消
2. Repair loop（APOLLO 風）— Pipeline で生成された Lean コードの自動修正
3. Lemma decomposition（Aristotle 風）— 大型研究目標の小さい補題への分解
4. Hammer pattern（Leanstral 風）— Mathlib + ATP の組み合わせ

**最重要未解決問題**: 「正しい仕様の生成」は AI でも未解決（G2-4.1）。これは G3 の CLEVER 結果と一致。

### 7.4 メタ視点: Lean 4 採用の長期的合理性（G4）

**4 source triangulation**（G4-2.4）:
- Mathlib 規模: **270,602 定理 / 772 貢献者**（Coq/Agda を上回るエコシステム）
- LLM prover SOTA: **miniF2F 95.08%**（BFS-Prover-V2）— Lean に集中投資が起きている
- コスト効率: **Leanstral コスト 93% 削減**
- メインストリーム化の限定要因: **Kleppmann 「culture change」** ← agent-manifesto の構造的強制設計（hooks, T6, P3）と整合

**結論**: 2026-2030 で Lean 4 採用は正しい賭け（G4-3.1）。

**AMO-Lean パターン**（G4-1.1, 3.2）:
- Mathlib 代数定理 → 書き換え規則 → コード最適化、各変換に Lean 証明
- `#compile_rules` で Lean 内のルールを実行可能形式に compile
- **新基盤への適用**: 公理系の theorem を `#compile_rules` で実行可能 lint/check に変換（運用ツール自動化）

### 7.5 4.4 段階的導入の更新案（G3 を踏まえた前置 Phase 0）

G3 の達成可能性評価を踏まえ、Section 4.4 の Phase 1-5 の前に **Phase 0** を追加することを推奨:

| Phase | 能力 | 理由 |
|---|---|---|
| **Phase 0 (新規)** | agent-spec-lib（公理系の Lean 4 化、Mathlib 相当の domain library） | G3 が示す通り、speclib なしの自動化は壊滅的に低い成功率（CLEVER 0.621% = 1/161）。先に「研究プロセスの語彙」を Lean 型として整備しないと、後続 Phase が機能しない |
| Phase 1-5 | (既存) | Phase 0 が整った前提で、Section 4.4 の通り進む |

### 7.6 新基盤研究の方法論的提言（G3-4.3 を踏襲）

G3 から導出される、本リサーチ自体の方法論への提言:

1. **「完全自動化」を初期目標としない** — Atlas augment 戦略を採用
2. **CLEVER 風の評価ベンチマークを早期に構築** — 自プロジェクトの研究プロセスを 10-20 サンプルで人手評価
3. **Vericoding の Dafny 実験結果を参照** — Lean が困難なら Dafny も併用検討（ただし TyDD サーベイの Lean 採用根拠は維持）
4. **VeriBench の Trace-style エージェント** — `/research` skill の Worker パターンに直接転用可能
5. **AMO-Lean パターン** — agent-manifesto 公理系を実行可能 lint に compile

### 7.7 Section 6.1 課題リストへの統合（実施済み）

7.1-7.4 で抽出された下記 4 件は、Section 6.1 の優先度付き課題リスト本体に直接統合済み:

| 優先度 | 課題 | 報告グループ |
|---|---|---|
| **P0** | 仕様等価性証明の壊滅的困難（CLEVER 0.621% = 1/161） | G3-1.2, G3-2.1 |
| **P0** | 「正しい仕様の生成」が全研究で未解決 | G2-4.1, G3-2.1 |
| **P1** | Vericoding 言語選択の決定的影響 (Lean 26.8% vs Dafny 82.2%) | G3-1.5 |
| **P1** | culture change が Lean 4 メインストリーム化の限定要因 | G4-1.3 |

詳細な対策の方向性は Section 6.1 を参照。

### 7.8 Atlas 12 プロジェクトの位置付け（G5 調査の根拠）

`research/lean4-handoff.md` Section 7 で整理された **Atlas Computing の 12 プロジェクト提案**（推定 21 人年・$6M）のうち、後続研究でカバーされた対象を新基盤研究の文脈でマッピング:

| Atlas プロジェクト | 後続実装 | 対応グループ | 新基盤への転用 |
|---|---|---|---|
| WorldModel (CSLib) | **CSLib + Boole** | G5-1 | Phase 0 の直接参照 |
| LegacyCode | 体系的研究は限定的（handoff 7.2 原文ママ）。ATLAS はアルゴリズム問題 (TACO) 限定で legacy 対象外 | G5-2 Section 5.1 | 部分: Task 分解パターンは転用候補 |
| InterAgent | Lean Copilot, APOLLO, LeanAgent | G2, G5-4 | `/research` Worker |
| InterFramework | Aeneas 等個別 | -- | 未実現、将来課題 |
| Autoformalization | VerifyThisBench, FVAPPS | G3 | 部分的 |
| Autoinformalization | -- | -- | 大規模評価少なし |
| Implementation2Spec | CLEVER (部分) | G3 | **未実現 — 新基盤の貢献領域** |
| InputOutput2Spec | -- | -- | **未実現 — 新基盤の貢献領域** |
| GenerateAndCheck | **ATLAS (Dafny)** 2.7K 合成 | G5-2 | 実装層で参照 |
| CorrectByConstruction | VeriBench, CLEVER | G2, G3 | 成功率依然低い |
| ProgramRepair | **VeriSoftBench** 2026 | G5-3 | リポジトリ規模評価 |
| ProgramEquivalence | -- | -- | 未実現 |

### 7.9 CSLib + Boole の speclib 位置付け（G5-1）

Atlas speclib の唯一の現存実装:
- **CSLib**: Stars **491** / Commits **436** / Releases **19** (2026-04 実測)
- **LeanHammer**: Mathlib **33.3%** / miniCTX **79.4%** — SMT ハンマー連携実装
- **CSLib 空白領域**: 研究プロセス / Failure・Hypothesis first-class / 人間介入表現 → **新基盤の独占領域**

**新基盤設計**: **agent-spec-lib = CSLib 依存の独立サブライブラリ**（3 層設計、8 週ロードマップを G5-1 Section 3 に記載）。

### 7.10 Dafny vs Lean の根本原因解明（G5-2）

G3 Vericoding で判明した **Lean 26.8% vs Dafny 82.2%** の根源:
- **Dafny は Z3/SMT 自動放電で miniF2F-Dafny の 44.7% が「空証明」で通る**
- Lean は明示的 tactic が必要 → 同タスクで労力が桁違い

**ATLAS の成果**:
- TACO-verified → **2.7K 検証済み Dafny 合成**
- Task 分解で **19K 訓練例抽出**
- Qwen 2.5 7B LoRA: **DafnyBench +24pt** (Pass@1 31.8%→55.8%, Pass@5/10 56.9%; 論文 abstract 表記「+23pt」は Pass@5/10 基準の丸め) / **DafnySynthesis +50pt (65.8%)**

**Lean 転用戦略**:
1. Task 分解パターン → `/research` Worker
2. Soundness / completeness lemma パターン → 新基盤の検証層
3. **Hybrid 案**: Dafny 実装層 + Lean 公理層（Phase 3 以降で検討）
4. **Duper / Lean-Auto / Boole の SMT 統合強化が必須**（Dafny 空証明 44.7% の差を埋める）

### 7.11 VeriSoftBench: リポジトリ規模ベンチマーク（G5-3）

既往 G3 ベンチマーク（CLEVER 161 問、VeriBench 等）は個別問題レベル。**VeriSoftBench (arXiv 2602.18307, 2026-02-20) は業界初のリポジトリ規模ベンチマーク**:
- **23 個の実世界 Lean 4 リポジトリから 500 proof obligation**
- **Gemini-3-Pro: Pass@8 curated 41.0% / full 34.8%**
- **Mathlib 特化 Goedel-Prover-V2 が Mathlib 外で 0% に崩壊**
- 平均 **37.93 project deps**（cross-module 依存が真の困難）

**4 層階層化コンテキスト（Library/Project/Local/Theorem）** が agent-manifesto の axiom/derivation/application 階層と構造的に一致。

**再帰評価提案**: `lean-formalization/Manifest/` を **24 番目のリポとして packaging し、55 axioms / 1670 theorems を自己ベンチマーク化**。新基盤の Phase 0-5 各段階の評価指標に転用。

### 7.12 LeanDojo eco-system: 観測レイヤ採用（G5-4）

**LeanDojo Benchmark (Lean 4 版)**: **122,517 定理 / 259,580 tactics / 167,779 premises**。

**核心傘下プロジェクトと新基盤への転用**:
- **LeanAgent (ICLR 2025, 250+ repo lifelong learning, EWC)** → `/research` の P3 退役・curriculum 重みに直接適用
- **LeanProgress (DeepSeek Coder 1.3B, 残ステップ予測 75.8% 精度, Mathlib4 +3.8%)** → **Gate 判定の打ち切り判断に直接適用可能**
- **ReProver (ByT5, "one GPU week")** → AI 補助の低コスト参照実装
- **Pantograph → LeanDojo-v2 で Docker-free 化** → 自作 Pipeline 統合の障壁低下

**差別化軸**: **LeanDojo = "AI for Lean" / 新基盤 = "Lean for AI Agent"**（agent governance 層）。

**新基盤提案**: agent-manifesto の Lean 公理系を **LeanDojo Benchmark 形式で逆提供**（conservative extension）し、AI for Lean コミュニティに返礼。

### 7.13 Lean4Lean 更新: カーネル信頼度の再評価（G5-5）

TyDD サーベイ S3 時点（2025-09）以降の進展:
- **Unique Typing Conjecture 2.7: 2026-01-31 proved**（injectivity modulo）
- **Church-Rosser / standardization**: 2026-Q1 proved
- **WITS 2026 (POPL 2026) Keynote**: Lean4Lean + Lennon-Bertrand "Verifying Dependent Type-checkers" 2 本立て → **dependent typechecker verification がサブコミュニティとして確立**

**新規に判明した soundness 懸念**:
- **`looseBVarRange_eq`** は v3 で "masked, not truly fixed; unsound assumption" に降格
- **2 件の新 Lean4 kernel issue**（#10475 infer_let fvar, #10511 Substring reflexivity）
- **Lean 3 → Lean 4 書き直しで Carneiro 2019 soundness proof が "no longer directly applicable"**
- **`divergences.md`**: 8 項目の意図的差異（`reduceBool` は "unsound by design"）

**新基盤への含意**:
- 新基盤の独自 axiom（AssumptionId, ResearchId 等）は **kernel soundness に直交** → 追加懸念なし
- **`native_decide` / `reduceBool` は lean4lean が意図的に検証しない → 安易導入 NG**
- P2/P4/T6/E1 は v3 冒頭の「cautionary tale」(`"not rewrite, but structurally ensure"`) と強く整合

### 7.14 G5 の Section 6.1 課題リストへの統合（実施済み）

G5 調査で新たに抽出された P1/P2 課題 5 件は Section 6.1 課題リスト本体に直接統合済み:

| 優先度 | 課題 | 報告グループ |
|---|---|---|
| **P1** | Dafny 空証明 44.7% の SMT 優位性 → Lean 側 SMT 強化の必要性 | G5-2 |
| **P1** | リポジトリ規模での Mathlib 特化モデルの崩壊 (Goedel 0% on non-Mathlib) | G5-3 |
| **P1** | `looseBVarRange` bug の unsound assumption 降格 → native_decide / reduceBool 要回避 | G5-5 |
| **P2** | Implementation2Spec, InputOutput2Spec, InterFramework は未実現 → 新基盤の貢献領域候補 | G5 (Atlas 7.4) |
| **P2** | agent-spec-lib vs CSLib 依存関係: 独立サブライブラリか contrib か | G5-1 |

詳細な対策は Section 6.1 を参照。

---

## 出典一覧

| 略称 | 正式名称 | ノートファイル |
|---|---|---|
| 01 | 知識グラフ・Zettelkasten ツール精読ノート | `01-knowledge-graph-tools.md` (708 行) |
| 02 | Data Provenance / Workflow Tracking 精読ノート | `02-data-provenance.md` (542 行) |
| 03 | Lean 4 メタプログラミング・DSL 設計精読ノート | `03-lean-metaprogramming.md` (878 行) |
| 04 | Type-Safe Document / Build Graph 精読ノート | `04-build-graph-systems.md` (1017 行) |
| 05 | Plain Text Issue Tracker 代替精読ノート | `05-plaintext-issue-tracker.md` (812 行) |
| 06 | 既存 agent-manifesto 内資産精読ノート | `06-internal-assets.md` (405 行) |
| G1 | Lean 4 産業応用 (Cedar/AWS) 精読ノート | `07-lean4-applications/G1-cedar-aws.md` (582 行) |
| G2 | AI 出力の Lean 4 検証精読ノート | `07-lean4-applications/G2-ai-verification.md` (622 行) |
| G3 | 仕様生成・vericoding 精読ノート | `07-lean4-applications/G3-spec-generation.md` (598 行) |
| G4 | Lean 4 サーベイ・メタ視点精読ノート | `07-lean4-applications/G4-meta-views.md` (467 行) |
| G5-1 | CSLib + Boole 精読ノート | `07-lean4-applications/G5-1-cslib-boole.md` (606 行) |
| G5-2 | ATLAS Dafny POPL 2026 精読ノート | `07-lean4-applications/G5-2-atlas-dafny.md` (423 行) |
| G5-3 | VeriSoftBench 精読ノート | `07-lean4-applications/G5-3-verisoftbench.md` (205 行) |
| G5-4 | LeanDojo eco-system 精読ノート | `07-lean4-applications/G5-4-leandojo.md` (331 行) |
| G5-5 | Lean4Lean 差分精読ノート | `07-lean4-applications/G5-5-lean4lean-delta.md` (266 行) |
| handoff | Lean 4 学習・サーベイ Handoff 資料 (Section 7: Atlas 提案書) | `research/lean4-handoff.md` (引用元) |
| TyDD | Type-Driven Development Survey (2025-2026) | `research/survey_type_driven_development_2025.md` (1406 行) |
| spec | high-tokenizer Spec System | `~/work/high-tokenizer/lean/SpecSystem/Basic.lean` (62 行) |
