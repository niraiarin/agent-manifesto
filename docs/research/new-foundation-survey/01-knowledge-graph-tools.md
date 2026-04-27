# 01: 知識グラフ・Zettelkasten ツール調査（グループ A）

**作成日**: 2026-04-17
**担当**: グループ A サーベイヤ
**目的**: ノード間の双方向リンク、block reference、backlink、graph view を「型安全な研究 tree + 半順序関係 + traceability」として表現する設計パターンを抽出する。

## サマリ

7 対象（Zettelkasten 原理、Roam、Obsidian、Tana、LogSeq、Foam/Dendron、TiddlyWiki）を精読した。観察された支配的な設計上の対立軸:

1. **アドレス空間**: 構造的アドレス（Folgezettel: `1a3b`）vs 内容アドレス（UID: `0e8f...`）
2. **粒度**: block 単位（Roam, LogSeq, Tana）vs page/file 単位（Obsidian, Foam, Dendron）
3. **schema**: 型なし wiki（Zettelkasten, Obsidian, Roam）vs schema 付き（Dendron, Tana）
4. **link 検証**: lazy / runtime（ほぼ全ツール）vs compile-time（無し — agent-manifesto の Lean 化が独自貢献領域）

新基盤への含意: Folgezettel ID（半順序の自然な表現）と Tana の supertag（型付きノード）を Lean DSL に抽出する価値が高い。逆に block-reference の魔法依存は agent-manifesto では「Lean 名前空間 + 構文的引用」で代替する設計が妥当。

---

## Section 1: 各対象の精読ノート

### 1.1 Zettelkasten 原理（Niklas Luhmann's method）

**出典**:
- Wikipedia: Zettelkasten — https://en.wikipedia.org/wiki/Zettelkasten
- zettelkasten.de Introduction — https://zettelkasten.de/introduction/
- Niklas Luhmann-Archiv Tutorial — https://niklas-luhmann-archiv.de/bestand/zettelkasten/tutorial
- Bob Doto: Folgezettel guide — https://writing.bobdoto.computer/how-to-use-folgezettel-in-your-zettelkasten-everything-you-need-to-know-to-get-started/
- Ernest Chiang: Original method — https://www.ernestchiang.com/en/posts/2025/niklas-luhmann-original-zettelkasten-method/
- zettelkasten.de Forum: Folgezettel vs duplex-numeric — https://forum.zettelkasten.de/discussion/3392/folgezettel-vs-duplex-numeric-arrangement
- zettelkasten.de Forum: Luhmann-ID Numbering — https://forum.zettelkasten.de/discussion/1739/questions-on-luhmann-id-numbering

#### 設計の核

Niklas Luhmann（1927–1998）は社会学者で、生涯に約 90,000 枚の zettel（カード）を 2 つの slip-box に蓄積し、58 冊の本と 600 以上の論文を生んだ。所蔵は Bielefeld 大学にあり、部分的にデジタル化されている。

**Folgezettel（continuation note）ID 体系**:
- 最初の zettel: `1`
- `1` の続きや内的展開: `1a`
- `1a` への注釈や子: `1a1`
- 無関係な新トピック: `2`

これにより `1 → 1a → 1a1` のような深さ優先の固定アドレスが得られる。`1` と `1a` の間に新しいカードを挿入することは **不可能**（順序の硬直性が「位置の意味」を保つ）。代わりに `1` から新カードへ、新カードから `1a` への明示的リンクで「論理的挿入」を表現する。

#### 10 観点での評価

1. **link 型**: 単方向（カード上に手書きで「siehe 1a3」と書く）。bidirectional は読み手が辿る運用で実現。型なし
2. **trace 可能性**: 紙上は手作業。デジタル化で逆引き可能になった
3. **退役検出**: 物理的には「破棄」が困難。陳腐化したカードも残し、新カードでの上書き的展開で扱う
4. **重複検出**: 人間の記憶と検索（Schlagwort-Register: keyword index）に依存
5. **階層 vs グラフ**: ハイブリッド。Folgezettel ID は局所的に階層的、cross-reference により大域的にグラフ
6. **形式化レベル**: 自然言語のみ。型システムなし
7. **データ永続化**: 物理カード。デジタル化はメタデータと画像
8. **API**: なし（原理）。後継ツールが API 化
9. **規模**: 90,000 枚で運用された実証的事例。固定位置ナンバリングは O(1) 検索（ID 既知時）
10. **LLM との統合**: なし（原理）

#### 新基盤への示唆

Folgezettel ID 体系は **半順序集合の自然な notation**。`1a3 ≤ 1a` という親子関係が文字列の prefix で機械的に判定できる。agent-manifesto の研究 tree が要する「派生関係の半順序」は、Folgezettel と同型な ID を Lean の structure として持てば、Lean のコンパイラが「無効な親子関係」をコンパイル時に拒否できる。

ただし **挿入不可** という硬直性は研究プロセスでは不適。Lean 上では `Insertion : (parent : NodeID) → (between : NodeID × NodeID) → NodeID` のような操作を許し、ID は内容に依存しないオートインクリメント（Roam 型 UID）にして、半順序関係を別の type field で持つのが合理的。

---

### 1.2 Roam Research

**出典**:
- David Bieber: Roam JSON Export Format — https://davidbieber.com/snippets/2020-04-25-roam-json-export/
- artpi/roam-research-private-api — https://github.com/artpi/roam-research-private-api
- Zsolt's blog: Deep Dive Into Roam's Data Structure — https://www.zsolt.blog/2021/01/Roam-Data-Structure-Query.html
- Ness Labs: Roam Research metacognition tool — https://nesslabs.com/roam-research
- thesweetsetup: Beginner's Guide to Roam Research — https://thesweetsetup.com/a-thorough-beginners-guide-to-roam-research/
- AirrSpace: How will Roam scale? — https://www.airr.io/space/60cdf659449de7c87157d6c5
- Goedel.io: TfT Performance Roam Research — https://www.goedel.io/p/tft-performance-roam-research
- Roam Research X (performance upgrade) — https://x.com/RoamResearch/status/1913239748593824116

#### 設計の核

Roam はブロック中心アーキテクチャ。すべてのコンテンツチャンク（段落、リスト項目）は UID 付きの **block** であり、page は単に block の root container である。

**Daily Notes**: その日の page が自動生成され、思いつきをまず流し込む。後で `[[Page Name]]` でリンクすると bidirectional になる。「分類より先に書く」ことを構造的に強制。

**Block Reference**: `((block-uuid))` で他の block を **transclude**（引用ではなくリアルタイム埋め込み）。リファクタ時に元 block を編集すれば全箇所に伝播する。

**JSON / EDN Export**: 公式 export は Markdown / JSON / EDN の 3 形式。EDN は lossless（リンク・block ref のセマンティクス完全保存）。db.json として private API 経由でも取得可。

#### 10 観点

1. **link 型**: bidirectional（自動 backlink 構築）。block 単位と page 単位の両方。型なし。tag (`#tag`) は別の dimension
2. **trace 可能性**: backlink パネルが自動更新。block ref を含むブロックが「Linked References」に表示される
3. **退役検出**: 明示なし。block 削除時に参照側は `((deleted))` 表示になる
4. **重複検出**: page 名衝突は強制的に同一 page として扱う。block 重複検出は無し
5. **階層 vs グラフ**: outliner 階層（indent によるツリー）の上にグラフ（リンク）を重ねる二重構造
6. **形式化レベル**: 自由テキスト + tag。型なし
7. **データ永続化**: クラウド。export は手動。EDN/JSON で構造化
8. **API**: 公式 public API なし。private API（artpi のリバースエンジニアリング）が存在
9. **規模**: 10,000 blocks 超で性能劣化報告。backlink 解決が **O(n²)** とされる事例。2026 年初頭に開いている block 数依存の性能改善
10. **LLM 統合**: 公式 RAG/AI なし。コミュニティで JSON export → LLM 入力

#### 新基盤への示唆

**Block reference の魔法依存** は研究プロセス記録には適さない。`((uuid))` は Lean では不可視の依存（コンパイラから見るとただの文字列）。代替として:
- Lean の **definition + 名前空間引用**（`Survey.knowledgeGraphs.luhmann`）で「引用」を型付きに
- transclusion は Lean メタプログラミング（`include`、`open`、tactic mode の `exact?`）で自然に表現可

**EDN export の lossless 性** は重要な設計教訓。新基盤の Lean 文書も「人間可読 + 完全な構造保存」両立を意識すべき（Lean source 自体が EDN 相当のロスレス表現）。

**Daily Notes パターン** は研究プロセスにおいて「観察ノート → 後で分類」のフローに対応。`docs/research/observations/YYYY-MM-DD.lean` を canonical な observation entry point とし、後段の hypothesis ノードへのリンクで構造化する設計が考えられる。

---

### 1.3 Obsidian

**出典**:
- Obsidian Help: Graph view — https://help.obsidian.md/plugins/graph
- Obsidian Developer Documentation: Vault — https://docs.obsidian.md/Plugins/Vault
- Obsidian Forum: Terabyte size scaling — https://forum.obsidian.md/t/terabyte-size-million-notes-vaults-how-scalable-is-obsidian/66674
- Graph Link Types plugin — https://github.com/natefrisch01/Graph-Link-Types
- blacksmithgu/obsidian-dataview — https://github.com/blacksmithgu/obsidian-dataview
- Issue #63: Links from dataview rendered in graph view — https://github.com/blacksmithgu/obsidian-dataview/issues/63
- Find orphaned files plugin — https://github.com/Vinzent03/find-unlinked-files
- obsidian-broken-links-cleaner — https://github.com/sarwarkaiser/obsidian-broken-links-cleaner

#### 設計の核

**Local-first Markdown vault**: ファイルは `.md` として OS のファイルシステム上に存在。Git 互換、外部ツールで編集可。

**Wikilink**: `[[Note Name]]` 構文。ファイル名で resolve（同名なら衝突解決ロジック）。subpath: `[[Note#Heading]]`、`[[Note#^block-id]]`（block reference は `^xxxxxx` の caret-id 付与必要）。

**Graph view**: vault 全体のリンク構造を force-directed layout で可視化。フィルタ（タグ、フォルダ、検索）対応。

**Frontmatter**: YAML metadata block。`tags`, `aliases`, 任意のキー値。Properties UI で型推論（text/number/date/checkbox/list）。

**Dataview plugin**: SQL ライクな DSL（DQL）または JavaScript（DataviewJS）で frontmatter / inline field をクエリしテーブル/リストレンダリング。**重要な制約**: Dataview が動的生成するリンクは graph view に **反映されない**（コードブロックは graph parser がスキップ）。これを補う Graph Link Types プラグインが PIXI.js + Dataview API で extension。

#### 10 観点

1. **link 型**: bidirectional（backlink パネル組込）。page・heading・block の 3 粒度。型なし wiki link、型付きは frontmatter / Dataview
2. **trace 可能性**: backlink 自動。リンク先 rename 時にリンク sync 設定可
3. **退役検出**: コミュニティプラグイン（find-unlinked-files, broken-links-cleaner）が補完。コアには無い
4. **重複検出**: 同名ファイルはエラー報告（user resolves）。内容類似は無し
5. **階層 vs グラフ**: フォルダ階層 + tag 階層 + リンクグラフの三重構造（互いに独立）
6. **形式化レベル**: Markdown + frontmatter（YAML スキーマなし）。Dataview で擬似的な型
7. **データ永続化**: 個別 `.md` ファイル。Git 完全互換。最大想定 ~1TB/year
8. **API**: Plugin API（TypeScript）。CodeMirror 6 ベース。Vault API、MetadataCache API、Workspace API
9. **規模**: 数十万ノートで実用報告。graph view は数万ノードでパフォーマンス低下
10. **LLM 統合**: Smart Connections, Copilot, Text Generator 等のサードパーティ。MCP server も登場

#### 新基盤への示唆

**Markdown + frontmatter のセマンティック分離** は新基盤に直接転用可。Lean では:
- 本文 = doc-comment（`/-! ... -/`）
- frontmatter = Lean structure として宣言的に記述
- 双方向参照は Lean の **依存型** として表現（参照先が存在しないとコンパイルエラー）

**Dataview と graph view の不整合** は重要な反面教師。動的に生成されるリンクと静的解析可能なリンクを分けると graph の真実性が壊れる。新基盤は **すべてのリンクを Lean source 内に静的に書く** ことで graph の正しさを構造的に保証する。

**Vault API の TypeScript 化** に相当する役割は、新基盤では Lean メタプログラミング + 自作 Pipeline が担う。「外部からの編集（GitHub Issue、エディタ）→ 内部表現の更新」を Pipeline 経由で透過的に。

---

### 1.4 Tana

**出典**:
- Tana docs: Supertags — https://tana.inc/docs/supertags
- Tana docs: Fields — https://tana.inc/docs/fields
- AI:PRODUCTIVITY: Mastering Tana Supertags — https://aiproductivity.ai/guides/tana-supertags-guide/
- RememberWork: Tana Review 2025 — https://rememberwork.com/tools/second-brain/tana
- jcfischer/supertag-cli — https://github.com/jcfischer/supertag-cli
- Cortex Futura: Tana Supertags + Search — https://www.cortexfutura.com/tana-supertags-plus-search-tana-fundamentals/
- Tana Ideas: Backup export — https://ideas.tana.inc/posts/17-complete-backup-export-and-import
- Tana docs: Import data — https://tana.inc/docs/import-data-into-tana
- tanainc/tana-import-tools — https://github.com/tanainc/tana-import-tools
- TfTHacker: Early thoughts on Tana — https://tfthacker.medium.com/early-thoughts-on-tana-13ea3421cd6b

#### 設計の核

Tana は outliner（block ベース）+ **supertag** + **fields**（型付きスキーマ）+ **live queries** の組み合わせ。Roam の block 中心性に Notion のスキーマ性を重ねた合成体。

**Supertag**: 任意の node に `#project`, `#person`, `#task` のような tag を付けると、その node が supertag 定義に従って **構造化オブジェクト** に格上げされる。supertag 定義は他の supertag を継承可（"is a" 関係）。

**Fields**: supertag 内に宣言された属性（"has a" 関係）。型: text, date, number, checkbox, instance（他 node 参照）, options, formula 等。

**Live Queries**: supertag/field を述語にした動的ビュー。「すべての `#task` で due date が来週」のようなクエリが live update。

**Export**: workspace 単位で Markdown / JSON。JSON は完全な internal model（references, inline refs, links, searches, commands, tags）。**JSON re-import は不可**（2026 時点）。

#### 10 観点

1. **link 型**: bidirectional, block 単位。supertag = 型付き relation の宣言。fields = key-typed 属性
2. **trace 可能性**: live queries による即時逆引き。reference panel が組込
3. **退役検出**: supertag 削除で全 instance に影響波及（warning あり）。内容陳腐化は無し
4. **重複検出**: なし。supertag instance の重複は許容
5. **階層 vs グラフ**: outliner 階層 + supertag 継承木 + reference graph の三層
6. **形式化レベル**: **PKM ツール内では最も型付きに近い**。supertag = nominal type、fields = record type
7. **データ永続化**: クラウド SaaS。local export 可だが re-import 不可
8. **API**: 公式 API なし。コミュニティ製 supertag-cli, MCP server あり。Input API（webhook）はある
9. **規模**: 待機リスト 160k+ という活発さ（2025 時点）。具体的 node 数上限は未公表
10. **LLM 統合**: 2026 年に multi-model AI 統合（Tana AI）。Supertag + AI で「`#meeting` の議事録 node を要約」のような動作可

#### 新基盤への示唆

**Supertag は Lean structure / class に直接対応**。研究プロセスのノードタイプ（Hypothesis, Experiment, Observation, Decision）を Lean の inductive type として定義し、各ノードを「型付きインスタンス」として扱える。これは型安全な PKM の純粋形。

**Field の継承** は Lean の type class や parent structure で表現可。`structure ResearchNode where ...` の上に `structure Hypothesis extends ResearchNode where claim : Prop` のように。

**Live Query の DSL** は Lean メタプログラミング（macro）で構築可。SQL/Datalog 風 syntax を Lean で実装し、コンパイル時に query plan を生成する設計が考えられる。

**JSON re-import 不可問題** は永続化設計の警鐘。新基盤は「Lean source = canonical、Pipeline = lossless transformer」とすることで、両方向の round-trip を保証する。

---

### 1.5 LogSeq

**出典**:
- LogSeq DeepWiki — https://deepwiki.com/logseq/logseq
- LogSeq DeepWiki: Database Schema — https://deepwiki.com/logseq/logseq/4.2-database-schema-and-validation
- LogSeq DeepWiki: Outliner Operations — https://deepwiki.com/logseq/logseq/3.4-query-system
- Logseq Datascript schema (gist) — https://gist.github.com/tiensonqin/9a40575827f8f63eec54432443ecb929
- LogSeq Discuss: ID links vs block IDs vs page IDs — https://discuss.logseq.com/t/what-are-id-links-vs-block-ids-vs-page-ids/1318
- LogSeq Discuss: Single query for page+block properties — https://discuss.logseq.com/t/single-query-for-both-page-properties-and-block-properties/27223
- LogSeq Discuss: Advanced queries explainer — https://discuss.logseq.com/t/how-advanced-queries-work-step-by-step-explainer/30544
- LogSeq Hub: Getting started with advanced queries — https://hub.logseq.com/features/av5LyiLi5xS7EFQXy4h4K8/getting-started-with-advanced-queries/8xwSRJNVKFJhGSvJUxs5B2
- LogSeq Volodymyr Pavlyshyn — https://volodymyrpavlyshyn.medium.com/logseq-personal-knowledge-graphs-with-db-power-85687d17cc4a

#### 設計の核

**Outliner + Datalog**: Roam 風アウトライナーに Datalog クエリエンジン（DataScript / Datomic dialect）を結合。**ローカルファースト**かつ Markdown / Org-mode ファイルを canonical（DB 版以前）。

**DataScript schema（主要属性）**:
- `:block/uuid` — unique identity
- `:block/parent` — ref, indexed（親 block）
- `:block/page` — ref, indexed（属する page）
- `:block/refs` — cardinality many（参照する block）
- `:block/tags` — cardinality many（tag/class）
- `:block/order` — fractional index（順序保存に CRDT 風アプローチ）
- `:block/namespace` — page の namespace（`computer/apple` のような hierarchical name）

**Page namespace**: `[[computer/apple]]` と `[[pie/apple]]` で同名 leaf を区別。namespace は階層と graph の橋渡し。

**Advanced Query**: Datalog で `find` / `where` / `pull` 構造。例:
```clojure
{:title "Tasks tagged project"
 :query [:find (pull ?b [*])
         :where [?b :block/refs ?p]
                [?p :block/name "project"]]}
```

**永続化の二系統**:
- **MD/Org 版**: `.md` ファイルが canonical。DB は cache
- **DB 版**: SQLite が canonical。MD は import/export 形式

#### 10 観点

1. **link 型**: bidirectional、block + page、namespace 付き、tag は型なし
2. **trace 可能性**: Datalog で完全に query 可能。`:block/refs` の逆引きが自動
3. **退役検出**: コア機能なし。コミュニティクエリで「孤立 block」抽出可
4. **重複検出**: 同名 page の namespace 区別はあるが、内容重複は無検出
5. **階層 vs グラフ**: outliner 階層 + namespace 階層 + ref graph の三層（Tana に類似）
6. **形式化レベル**: schema は DataScript で宣言的、ただし block content は free text
7. **データ永続化**: ローカル MD/Org（V1）または SQLite（DB 版）。Git 互換（MD 版）
8. **API**: Plugin API（JS）、`logseq.Editor`, `logseq.DB`, `logseq.UI`。Datalog query を外部から実行可
9. **規模**: 大規模 graph で性能良好（DataScript の indexed lookup 効率）。MD ファイル数万で運用報告
10. **LLM 統合**: コミュニティ plugin（GPT, Local LLM）多数。MCP server あり

#### 新基盤への示唆

**Datalog の表現力** は Lean のクエリ DSL 設計の参考になる。ただし Lean では:
- query = 型を持つ pure function（コンパイル時に decidable）
- 結果型 = `List ResearchNode` のような subset type（半順序の保存）
- 副作用なし → reproducibility が構造的

**DataScript schema の `cardinality many`** は Lean の `List` または `Finset` で自然に表現。`refs : List NodeID` を field として持てば、参照グラフが型レベルで宣言される。

**MD/DB の二重永続化問題** は教訓。新基盤は **Lean source を unique canonical** とし、他形式は derived view（artifact-manifest.json と同類）に固定すべき。

**Fractional index の CRDT 風順序** は分散編集環境では有用だが、agent-manifesto の単一 LLM ワークフローでは過剰。シンプルな `Nat` 順序で十分。

---

### 1.6 Foam / Dendron

**出典**:
- Foam GitHub — https://github.com/foambubble/foam
- Foam Graph Visualization docs — https://foambubble.github.io/foam/user/features/graph-visualization
- Foam DeepWiki — https://deepwiki.com/foambubble/foam
- Foam DeepWiki: VS Code Extension — https://deepwiki.com/foambubble/foam/2.3-vs-code-extension
- Dendron wiki: Schemas — https://wiki.dendron.so/notes/c5e5adde-5459-409b-b34d-a0d75cbb1052/
- Dendron wiki: Concepts — https://wiki.dendron.so/notes/c6fd6bc4-7f75-4cbb-8f34-f7b99bfe2d50/
- Dendron docs: Note Type System — https://docs.dendron.so/notes/E8ZUvTzJ7cVOyZtqHiIKX/
- Dendron docs: Easier Schemas — https://docs.dendron.so/notes/xSSUw9GWcnsF35y597Vof/
- Dendron Backlinks Panel — https://wiki.dendron.so/notes/yxkn87ohgomk0tgs12dppur/
- Markdown Guide: Dendron Reference — https://www.markdownguide.org/tools/dendron/
- Dendron Markdown Notes (open-vsx) — https://open-vsx.org/extension/dendron/dendron-markdown-notes
- Foam issue #604: Hierarchical notes — https://github.com/foambubble/foam/issues/604
- Kevin Slin: A Hierarchy First Approach — https://www.kevinslin.com/notes/3dd58f62-fee5-4f93-b9f1-b0f0f59a9b64/

#### Foam の設計

VSCode 拡張。Markdown + wikilink。**Roam-inspired** だが local-first / open-source。

- `[[wikilink]]` でリンク。autocomplete, navigation, rename 時の sync
- **FoamGraph**: workspace 監視、関係データを保持（links, backlinks, placeholders）
- Connections View: 現在 note の links / backlinks
- Graph Visualization: ノード = files + tags、edges = links または file-tag 関係
- **Placeholder**: 未存在のリンク先（broken link 候補）も明示的に表現

#### Dendron の設計

VSCode 拡張だが **hierarchical naming** を中核に置く点で Foam と決定的に異なる。

- ファイル名そのものが階層: `cli.git.commands.add.md`（`.` 区切り）
- **Schema**: `{name}.schema.yml` で hierarchy の型を定義。pattern matching で「`cli.*.commands.*` は CLI command type」を宣言
- redhat.vscode-yaml extension 経由で schema 編集時に validation
- **Note Type System**: schema とは独立に「single note の behavior」を frontmatter `type` field で指定。type = template + fields の組
- Backlinks Panel: 標準機能
- **lookup** コマンド: hierarchical name の autocomplete + 新規作成

#### 10 観点（Foam / Dendron 並記）

1. **link 型**: 両方とも bidirectional, page 単位, 型なし wiki link。Dendron は加えて **hierarchical name 自体が型情報**
2. **trace 可能性**: 両方とも backlink panel あり。Foam は FoamGraph で集約管理
3. **退役検出**: 両方とも broken link 検出可（Foam の placeholder, Dendron の lookup miss）
4. **重複検出**: Dendron は hierarchical name の prefix 衝突を検出。Foam は同名ファイルチェック
5. **階層 vs グラフ**: Foam は flat + graph、Dendron は **hierarchy first**（graph は二次的）
6. **形式化レベル**: Foam は型なし。Dendron は YAML schema で部分的型付け
7. **データ永続化**: 両方とも `.md` ファイル。Git 互換。VSCode workspace
8. **API**: Foam は VSCode extension API。Dendron は CLI + Plugin API
9. **規模**: 中規模（数千ノート）まで快適。Dendron は schema 検証コストあり
10. **LLM 統合**: コミュニティで GPT 連携。MCP は限定的

#### 新基盤への示唆

**Dendron の hierarchical naming は Lean の名前空間と完全に同型**。`cli.git.commands.add` は Lean の `Cli.Git.Commands.Add` namespace に直接対応。これは決定的に重要な設計教訓:

- Lean の名前空間 = Dendron の dotted-name = agent-manifesto 研究 tree の path
- `import Cli.Git.Commands.Add` がそのまま「依存宣言」
- ファイル名が ID として一意、rename はコンパイラが追跡

**Foam の Placeholder** は「未来のノード」を明示する設計として優秀。Lean では `axiom` または `opaque` で「証明予定」を表現でき、これが Placeholder の対応物。研究 tree の未確定ノードは `opaque ResearchNode (id : NodeID) : Type` で型レベルに宣言できる。

**Dendron schema の YAML** は Lean structure 宣言で完全に置換可能（むしろ型安全）。

---

### 1.7 TiddlyWiki

**出典**:
- TiddlyWiki Tagging — https://tiddlywiki.com/static/Tagging.html
- TiddlyWiki TranscludeWidget — https://tiddlywiki.com/static/TranscludeWidget.html
- TiddlyWiki ListWidget — https://tiddlywiki.com/static/ListWidget.html
- TiddlyWiki DataTiddlers — https://tiddlywiki.com/static/DataTiddlers.html
- TiddlyWiki Dev — https://tiddlywiki.com/dev/static/TiddlyWiki.html
- TiddlyWiki Dev: SyncAdaptorModules — https://tiddlywiki.com/dev/static/SyncAdaptorModules.html
- TiddlyWiki Dev: Data-Storage — https://tiddlywiki.com/dev/static/Data-Storage.html
- TiddlyWiki Dev: Core Application — https://tiddlywiki.com/dev/static/TiddlyWiki%2520Core%2520Application.html
- TiddlyWiki Grokipedia — https://grokipedia.com/page/TiddlyWiki
- val.packett: TiddlyPWA — https://val.packett.cool/blog/tiddlypwa/
- tiddly-gittly/TiddlyWiki-LLM-dataset — https://github.com/tiddly-gittly/TiddlyWiki-LLM-dataset

#### 設計の核

**Single-page wiki**: 1 つの HTML ファイルが全データを含む（self-contained）。ブラウザだけで動作。Node.js 版もあり、tiddler を個別ファイルに展開。

**Tiddler**: 全コンテンツ単位。title, type, fields（任意のキー値）, tags, body の構造。「tag 自身も tiddler」という再帰性。

**Transclusion**: `<$transclude tiddler="Foo"/>` widget で他 tiddler を動的に埋め込み。template と組み合わせると filter 結果のリストレンダリングが可能。

**Filter syntax**: `[tag[task]!tag[done]]` のような独自 DSL。tag, field, time, regex 等を組み合わせ可。

**SyncAdaptor**: 永続化の抽象化層。LocalFileAdaptor（Node.js fs）, TiddlyWebAdaptor（HTTP）, BrowserStorage（localStorage、5-10 MB 制限）等の plug-in 可能なバックエンド。

**Data Tiddler**: tiddler 内に key-value（DataTiddler）, JSON, CSV を格納し、ミニ DB として使う。

#### 10 観点

1. **link 型**: 双方向（自動 backlink）、tiddler 単位。tag = ref。型は field 単位（ただし field 型は弱い）
2. **trace 可能性**: filter で完全 query 可能。逆引き backlink あり
3. **退役検出**: コア機能なし。filter で構築可能（`[!has[tags]]` 等）
4. **重複検出**: title 衝突は新規作成不可エラー
5. **階層 vs グラフ**: フラット + tag graph + transclusion graph
6. **形式化レベル**: field の型は弱い（text, date, list の区別ぐらい）。schema 機構は無い
7. **データ永続化**: 単一 HTML（最も独自）または個別ファイル（Node.js 版）。SyncAdaptor で remote 対応
8. **API**: JavaScript module API。filter, widget, macro が拡張点
9. **規模**: 数千 tiddler で快適。HTML 単一ファイルは DOM 性能の制約あり
10. **LLM 統合**: TiddlyWiki-LLM-dataset プロジェクトなど初期段階

#### 新基盤への示唆

**Single-file self-contained** は研究プロセスの **portable artifact** として優秀な発想。Lean の場合「`Survey.lean` 1 ファイルに全研究記録を含める」設計と類比。ただし scaling では分割が必要。

**Tag = Tiddler の再帰性** は Lean の type-of-type（Type : Type 1）の階層と類比。ただし Lean は循環を排除する universe 階層を持ち、TiddlyWiki は循環許容（実用優先）。

**SyncAdaptor の抽象化** は新基盤 Pipeline の設計参考。「Lean source（canonical）」「GitHub Issue（read-only view）」「artifact-manifest.json（machine-readable export）」を SyncAdaptor 風 plugable な persistence layer として設計可能。

**Filter DSL** は Lean メタプログラミングで容易に再現可。`syntax "research:" "[" filter "]" : term` のような macro 拡張で。

---

## Section 2: 比較表（10 観点 × 7 対象）

凡例: ○=良好 / △=部分対応 / ×=未対応 / N/A=該当せず

| 観点 | Zettelkasten | Roam | Obsidian | Tana | LogSeq | Foam/Dendron | TiddlyWiki |
|---|---|---|---|---|---|---|---|
| 1. link 型: bidirectional | △ (手動) | ○ | ○ | ○ | ○ | ○ | ○ |
| 1. link 型: 粒度 | カード | block + page | page + heading + block | block | block + page | page | tiddler |
| 1. link 型: namespaced | × | × | × (folder) | × (supertag) | ○ (`a/b`) | ○ (Dendron `a.b`) | × |
| 1. link 型: 型付き | × | × | △ (frontmatter) | ○ (supertag/field) | △ (DataScript) | △ (Dendron schema) | × |
| 2. trace: backlink 自動 | × | ○ | ○ | ○ | ○ | ○ | ○ |
| 2. trace: rename 追従 | N/A | △ | ○ | ○ | ○ | ○ | △ |
| 2. trace: orphan 検出 | × | × | △ (plugin) | △ | △ (query) | ○ (Foam placeholder) | △ (filter) |
| 3. 退役: archive 機能 | △ | × | △ (folder) | × | × | × | × |
| 3. 退役: 陳腐化判定 | × | × | × | × | × | × | × |
| 4. 重複: title 衝突 | N/A | 強制 merge | error | 許容 | namespace 区別 | error | error |
| 4. 重複: 内容類似 | × | × | △ (plugin) | × | × | × | × |
| 5. 階層 vs グラフ | hybrid (Folgezettel) | outline + graph | folder + tag + graph | outline + supertag + graph | outline + ns + graph | Foam: graph / Dendron: hierarchy | flat + tag + transclusion |
| 6. 形式化レベル | text | text + tag | text + frontmatter | structure (supertag/field) | DataScript schema | YAML schema (Dendron) | weak fields |
| 6. 機械可読性 | △ (digitized) | ○ (JSON/EDN) | ○ (md+yaml) | ○ (JSON) | ○ (DataScript) | ○ (md+yaml) | ○ (HTML/JSON) |
| 7. 永続化: ファイル | 物理 | クラウド | `.md` | クラウド | `.md` or SQLite | `.md` | HTML or files |
| 7. 永続化: Git 互換 | N/A | × (export) | ○ | × (export) | ○ (MD 版) | ○ | △ (HTML diff 困難) |
| 7. local-first | N/A | × | ○ | × | ○ | ○ | ○ |
| 8. API: 公式 | N/A | × | ○ (plugin) | × (Input only) | ○ (plugin) | ○ (extension) | ○ (module) |
| 8. query 言語 | N/A | Roam Query | Dataview DQL | Tana Query | Datalog | Dendron Query | TW Filter |
| 9. 規模: 実証上限 | 90k cards | 10k blocks (劣化) | 100k+ notes | 不明 | 数万 nodes | 数千 nodes | 数千 tiddlers |
| 9. 検索性能 | O(1) (ID 既知) | O(n²) backlink | indexed | live query | Datalog index | text search | filter | 
| 10. LLM 統合事例 | × | community JSON | Smart Connections, MCP | Tana AI (2026) | community plugins | 限定的 | LLM-dataset 初期 |

---

## Section 3: 横断的な発見

### 3.1 共通パターン

**P1: Bidirectional link は普遍的だが、その型は弱い**
全ツールが backlink を実装するが、edge type（「派生する」「反証する」「依存する」等）を区別する型システムを持つものは無い。Tana の supertag が「ノード型」を導入するが、edge type は依然として弱い。

**P2: Block 単位の granularity が新世代の標準**
Roam, LogSeq, Tana は block UID を中心に据える。Obsidian も `^block-id` で追従。Foam, Dendron, TiddlyWiki は file/tiddler 単位に留まる。研究プロセスでは「文単位」「段落単位」の引用が必要なら block 単位、「セクション単位」で十分なら page 単位を選ぶ判断が必要。

**P3: Schema は後付けされる傾向**
Roam, LogSeq, Obsidian は schema-less から出発し、後発の Tana, Dendron が schema を中核に置く。これは研究コミュニティの試行錯誤が「型なしから始め、必要に応じて型付けへ移行」の方向に進化していることを示す。**新基盤は Lean を採用することで「最初から型付け」を選択できる利点がある**（後付けの schema migration コストを回避）。

**P4: 永続化の二重化は事故の元**
LogSeq (MD/DB), Tana (JSON export 不可逆) で観察される問題: 「canonical な永続化形式」と「derived な永続化形式」を混同すると round-trip 不能になる。**Lean source を唯一の canonical とし、他は derived view に徹する** 設計が必要。

### 3.2 共通課題

**C1: 退役・陳腐化検出の機能不全**
全ツールでコア機能として欠落。コミュニティ plugin で部分対応のみ。これは agent-manifesto の P3（学習の統治: ライフサイクルで「退役」フェーズが定義されている）の独自性を裏付ける。**新基盤は退役を一級市民として設計すべき**（例: `Retired : ResearchNode → Prop` axiom + 退役理由 field の必須化）。

**C2: 重複検出は title 衝突に留まる**
内容の意味的重複（同じことを違う言葉で書いた 2 ノード）の検出は皆無。LLM 統合の今後の主戦場だが、現状は手動。新基盤では Lean の definitional equality + propositional equality の chasm が同様の課題として立ち現れる可能性あり。

**C3: 大規模 graph での性能劣化**
Roam は 10k blocks 超で backlink O(n²) の問題。Obsidian の graph view も数万ノード超で減速。Dendron の schema 検証もコスト。**Lean のコンパイル時間が新基盤のスケール上限を決める** 可能性が高く、incremental compilation（Bazel/Nix 風）の設計が必須。

### 3.3 独自性のあるアプローチ

**U1: Folgezettel (Luhmann) — 構造的アドレス**
ID 自体が半順序関係を埋め込む。`1a3 ≤ 1a` が文字列演算で判定可。新基盤の Lean DSL で再現すれば、研究 tree の親子関係をコンパイル時に検証できる。

**U2: Dendron — Hierarchical naming = Type system 候補**
ファイル名そのものが namespace。Lean の名前空間機構と完全に同型。これは agent-manifesto の Lean 採用が技術的に正当である最強の根拠。

**U3: Tana — Supertag による "is a" + Field による "has a"**
PKM ツールの中で最も型理論に近い。supertag = nominal type, field = record member。Lean structure / class で自然に表現可能。

**U4: TiddlyWiki — SyncAdaptor の永続化抽象**
canonical store（in-memory）と persistence backend を分離する設計。新基盤 Pipeline で「Lean Module = canonical, GitHub Issue = SyncAdaptor 経由 read-only view」を再現できる。

**U5: LogSeq — Datalog as universal query**
PKM 上に Datalog を載せた最初の主流ツール。ただし Lean の依存型システムはより表現力が高く、LogSeq の Datalog query を Lean の pure function + decidable proposition で吸収可能。

---

## Section 4: 新基盤への適用可能性

agent-manifesto の Lean DSL 設計に直接転用できるパターンを抽出する。`Spec = (T, F, ≤, Φ, I)`（high-tokenizer の spec system）構造に対応付ける。

### 4.1 T（型）への含意 — ノード型システム

**採用候補**:
- **Tana 風 supertag** を Lean inductive type で表現:
  ```lean
  inductive ResearchNode where
    | observation (id : NodeID) (content : String) (timestamp : Date)
    | hypothesis (id : NodeID) (claim : Prop) (parent : NodeID)
    | experiment (id : NodeID) (hypothesis : NodeID) (gates : List Gate)
    | decision (id : NodeID) (rationale : String) (supersedes : List NodeID)
    | retired (id : NodeID) (reason : RetirementReason) (replacedBy : Option NodeID)
  ```
- **Dendron 風 hierarchical naming** を Lean namespace で:
  - `Research.KnowledgeGraphs.Luhmann` のような module path で研究 tree を構成
  - `import` がそのまま「依存宣言」
- **Foam 風 placeholder** を `opaque` または `axiom` で:
  - 未確定ノードは `opaque PendingResearch (id : NodeID) : Type` で型レベルに宣言

### 4.2 F（function）への含意 — ノード操作

**採用候補**:
- **Roam 風 transclusion** を Lean の `include`/`open`/`exact?` tactic で:
  - 「他ノードを引用」= Lean module の他 namespace を open
- **LogSeq 風 Datalog query** を Lean の pure function + decidable で:
  ```lean
  def descendantsOf (root : NodeID) (tree : ResearchTree) : List NodeID := ...
  theorem descendantsOf_partial_order : ∀ root tree n, n ∈ descendantsOf root tree → root ≤ n
  ```

### 4.3 ≤（半順序）への含意 — 派生関係

**採用候補**:
- **Folgezettel ID** を Lean の structure として（設計スケッチ、PoC 未検証）:
  ```lean
  -- Sum 型は BEq を自動 deriving しないため明示
  instance [BEq α] [BEq β] : BEq (α ⊕ β) where
    beq
      | .inl x, .inl y => x == y
      | .inr x, .inr y => x == y
      | _, _ => false

  structure FolgeID where
    path : List (Nat ⊕ Char)  -- "1a3" = [Sum.inl 1, Sum.inr 'a', Sum.inl 3]
    deriving Repr

  -- isPrefixOf は Bool を返すため LE (Prop) へ `= true` で変換
  instance : LE FolgeID := ⟨fun a b => a.path.isPrefixOf b.path = true⟩
  ```
- これにより親子関係が型レベルで自動的に半順序を成す

### 4.4 Φ（性質述語）への含意 — トレーサビリティ保証

**採用候補**:
- **Foam の placeholder 検出** を Lean compile-time error として:
  - 参照先が未定義なら `unknown identifier` エラー → orphan 構造的不可能
- **Obsidian の rename sync** を Lean の rename refactoring で:
  - Lean LSP の rename は全参照を更新
- **退役 (P3)** を述語として（設計スケッチ、Phase 2 で正式型検査）:
  ```lean
  def isRetired (n : ResearchNode) : Prop := match n with
    | .retired _ _ _ => True
    | _ => False

  -- 「active な node m が retired な node n を参照することは禁止」
  -- (00-synthesis.md §2a も同じ結論で統一)
  theorem no_active_reference_to_retired :
    ∀ (n m : ResearchNode), isRetired n → ¬ isRetired m →
      ¬ m.references.contains n.id
  ```

### 4.5 I（解釈/インスタンス）への含意 — Pipeline 設計

**採用候補**:
- **TiddlyWiki SyncAdaptor 抽象** を Pipeline の output 層に:
  ```
  Lean source (canonical)
    ├→ Markdown view (人間閲覧)
    ├→ JSON manifest (machine query)
    ├→ GitHub Issue (read-only PR 連携)
    └→ Graph SVG (visualization)
  ```
- **Tana export の lossless 性** を Lean source 自体で達成（Lean source = lossless）

### 4.6 横断採用パターン — Tag Index

| 設計要素 | 採用元 | Lean 表現 |
|---|---|---|
| Atomic node | Zettelkasten | `inductive ResearchNode` の単一 constructor |
| Folgezettel ID | Zettelkasten | `structure FolgeID` + 半順序 instance |
| Bidirectional link | Roam/Obsidian | 参照は単方向だが backlink は Pipeline が pure function で生成 |
| Block reference | Roam | Lean definition 引用（`Survey.luhmann.principleAtomic`） |
| Daily notes | Roam | `docs/research/observations/YYYY-MM-DD.lean` |
| Hierarchical name | Dendron | Lean namespace |
| Schema | Dendron/Tana | Lean structure / class |
| Placeholder | Foam | `opaque` または `axiom` |
| Datalog query | LogSeq | Lean pure function with decidable instance |
| SyncAdaptor | TiddlyWiki | Pipeline output 層の plugin 化 |
| Supertag (型付きノード) | Tana | `inductive ResearchNode` の constructor 群 |
| Live query | Tana | Lean macro で SQL/Datalog 風 syntax |
| Transclusion | Roam/TiddlyWiki | `import` + `open` |
| Filter DSL | TiddlyWiki | Lean macro |
| Retired ノード | （独自） | `.retired` constructor + `isRetired` 述語 |

---

## Section 5: 限界と未解決問題

### 5.1 本サーベイの限界

**L1: 一次出典への到達深度**
zettelkasten.de, Tana docs, LogSeq DeepWiki は深く参照したが、Roam の internal architecture（公式 API 不在）、Obsidian の graph view 実装内部（クローズドソース）は第三者解説依存。WebFetch で公式 docs を追加掘削する余地あり。

**L2: 定量データの不足**
- Tana の node 数上限: 公式数値なし（待機リスト 160k+ のみ）
- Obsidian の graph view 限界点: forum 報告は数万〜十万で曖昧
- Roam の O(n²) 主張: 単一第三者測定（Goedel.io）で複数源での確認が必要

**L3: LLM 統合事例のサーベイ深度**
本サーベイでは「あれば言及」レベルに留まる。Smart Connections (Obsidian), Tana AI, MCP server の具体実装は別途グループ B/E で深掘り余地。

**L4: 採用パターンの動作検証なし**
Section 4 で提案した Lean 表現は「設計可能性」のスケッチに留まり、PoC コンパイルは未実施。Group C（Lean メタプログラミング）の成果と統合して検証が必要。

### 5.2 未解決の設計問題

**Q1: Block 単位 vs Page 単位の選択基準**
研究プロセスで「文単位の引用」が必要な頻度は不明。新基盤の MVP では Page 単位（= Lean module 単位）で開始し、必要なら block 引用機構を後付けする漸進設計が妥当か。

**Q2: 退役 (Retired) と削除 (Deleted) の区別**
全 PKM ツールが「削除 = 完全消去」のみ実装。退役は agent-manifesto 独自の概念で、参考事例なし。Lean inductive type に retired constructor を入れる設計（4.1）が適切かは別途検討が必要。

**Q3: 重複検出の意味的レイヤー**
title 衝突を超えた「内容類似性」は LLM の出番だが、これを構造的に強制する方法は不明。Lean の definitional equality を使えるか、別途 SMT 検査が必要かは Group C/D の知見と統合して判断。

**Q4: 大規模研究 tree のコンパイル性能**
Roam が 10k blocks で劣化、Obsidian が graph view で数万 nodes で劣化を示すなら、Lean module 数千を超えた段階で incremental compilation 戦略が必須。Group D（build graph）と密接に関連。

**Q5: Edge type（リンクの種類）の表現**
全ツールが edge type を持たない（弱い）。「派生する」「反証する」「依存する」を Lean inductive で表現可能だが、双方向 link との整合性、graph view での視覚化方法は未検討。

**Q6: GitHub Issue (developmentFlag node) との同期意味論**
Issue 化された tree leaf が修正された際、Lean source への反映は手動か自動か。SyncAdaptor 抽象（4.5）で解決の方向性は見えるが、具体プロトコル未定義。Group E（plain text issue tracker）と統合して設計。

### 5.3 後続グループへの引継ぎ事項

- **Group B (Provenance)**: SyncAdaptor 抽象の lineage 表現と統合。本サーベイで言及した「永続化の二重化問題」は provenance 観点でも重要
- **Group C (Lean メタプログラミング)**: Section 4 の Lean 表現案を実装可能性で検証
- **Group D (Build graph)**: 大規模 graph 性能（Q4）と incremental compilation の関係
- **Group E (Plain text issue tracker)**: GitHub Issue 同期意味論（Q6）を補完
- **Group F (内部資産)**: 既存 `/trace`, `manifest-trace`, `artifact-manifest.json` が SyncAdaptor 候補として再利用可能か

---

## 参照 URL リスト（出典まとめ）

### Zettelkasten
- https://en.wikipedia.org/wiki/Zettelkasten
- https://zettelkasten.de/introduction/
- https://niklas-luhmann-archiv.de/bestand/zettelkasten/tutorial
- https://writing.bobdoto.computer/how-to-use-folgezettel-in-your-zettelkasten-everything-you-need-to-know-to-get-started/
- https://www.ernestchiang.com/en/posts/2025/niklas-luhmann-original-zettelkasten-method/
- https://forum.zettelkasten.de/discussion/3392/folgezettel-vs-duplex-numeric-arrangement
- https://forum.zettelkasten.de/discussion/1739/questions-on-luhmann-id-numbering

### Roam Research
- https://davidbieber.com/snippets/2020-04-25-roam-json-export/
- https://github.com/artpi/roam-research-private-api
- https://www.zsolt.blog/2021/01/Roam-Data-Structure-Query.html
- https://nesslabs.com/roam-research
- https://thesweetsetup.com/a-thorough-beginners-guide-to-roam-research/
- https://www.airr.io/space/60cdf659449de7c87157d6c5
- https://www.goedel.io/p/tft-performance-roam-research
- https://x.com/RoamResearch/status/1913239748593824116

### Obsidian
- https://help.obsidian.md/plugins/graph
- https://docs.obsidian.md/Plugins/Vault
- https://forum.obsidian.md/t/terabyte-size-million-notes-vaults-how-scalable-is-obsidian/66674
- https://github.com/natefrisch01/Graph-Link-Types
- https://github.com/blacksmithgu/obsidian-dataview
- https://github.com/blacksmithgu/obsidian-dataview/issues/63
- https://github.com/Vinzent03/find-unlinked-files
- https://github.com/sarwarkaiser/obsidian-broken-links-cleaner

### Tana
- https://tana.inc/docs/supertags
- https://tana.inc/docs/fields
- https://aiproductivity.ai/guides/tana-supertags-guide/
- https://rememberwork.com/tools/second-brain/tana
- https://github.com/jcfischer/supertag-cli
- https://www.cortexfutura.com/tana-supertags-plus-search-tana-fundamentals/
- https://ideas.tana.inc/posts/17-complete-backup-export-and-import
- https://tana.inc/docs/import-data-into-tana
- https://github.com/tanainc/tana-import-tools
- https://tfthacker.medium.com/early-thoughts-on-tana-13ea3421cd6b

### LogSeq
- https://deepwiki.com/logseq/logseq
- https://deepwiki.com/logseq/logseq/4.2-database-schema-and-validation
- https://deepwiki.com/logseq/logseq/3.4-query-system
- https://gist.github.com/tiensonqin/9a40575827f8f63eec54432443ecb929
- https://discuss.logseq.com/t/what-are-id-links-vs-block-ids-vs-page-ids/1318
- https://discuss.logseq.com/t/single-query-for-both-page-properties-and-block-properties/27223
- https://discuss.logseq.com/t/how-advanced-queries-work-step-by-step-explainer/30544
- https://hub.logseq.com/features/av5LyiLi5xS7EFQXy4h4K8/getting-started-with-advanced-queries/8xwSRJNVKFJhGSvJUxs5B2
- https://volodymyrpavlyshyn.medium.com/logseq-personal-knowledge-graphs-with-db-power-85687d17cc4a

### Foam / Dendron
- https://github.com/foambubble/foam
- https://foambubble.github.io/foam/user/features/graph-visualization
- https://deepwiki.com/foambubble/foam
- https://deepwiki.com/foambubble/foam/2.3-vs-code-extension
- https://wiki.dendron.so/notes/c5e5adde-5459-409b-b34d-a0d75cbb1052/
- https://wiki.dendron.so/notes/c6fd6bc4-7f75-4cbb-8f34-f7b99bfe2d50/
- https://docs.dendron.so/notes/E8ZUvTzJ7cVOyZtqHiIKX/
- https://docs.dendron.so/notes/xSSUw9GWcnsF35y597Vof/
- https://wiki.dendron.so/notes/yxkn87ohgomk0tgs12dppur/
- https://www.markdownguide.org/tools/dendron/
- https://github.com/foambubble/foam/issues/604
- https://www.kevinslin.com/notes/3dd58f62-fee5-4f93-b9f1-b0f0f59a9b64/

### TiddlyWiki
- https://tiddlywiki.com/static/Tagging.html
- https://tiddlywiki.com/static/TranscludeWidget.html
- https://tiddlywiki.com/static/ListWidget.html
- https://tiddlywiki.com/static/DataTiddlers.html
- https://tiddlywiki.com/dev/static/TiddlyWiki.html
- https://tiddlywiki.com/dev/static/SyncAdaptorModules.html
- https://tiddlywiki.com/dev/static/Data-Storage.html
- https://tiddlywiki.com/dev/static/TiddlyWiki%2520Core%2520Application.html
- https://grokipedia.com/page/TiddlyWiki
- https://val.packett.cool/blog/tiddlypwa/
- https://github.com/tiddly-gittly/TiddlyWiki-LLM-dataset

### 比較・横断
- https://www.golinks.com/blog/10-best-personal-knowledge-management-software-2026/
- https://www.atlasworkspace.ai/blog/knowledge-graph-tools
- https://infranodus.com/use-case/visualize-knowledge-graphs-pkm
