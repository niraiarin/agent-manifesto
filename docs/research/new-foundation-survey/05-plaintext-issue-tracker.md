# Group E: Plain Text Issue Tracker — Survey Notes

**作成日**: 2026-04-17
**担当**: Group E（Plain Text Issue Tracker / 状態機械 / Lean → GitHub Issue 同期）
**位置付け**: `00-survey-plan.md` グループ E。研究 tree 末端の `developmentFlag` つき leaf node のフォーマット、状態遷移、Lean canonical → GitHub Issue 同期パターンの一次資料蓄積。
**非スコープ**: build system（D に委譲）、知識グラフ（A に委譲）、Lean メタプログラミング（C に委譲）。本文書は **issue/ticket 構造** に集中する。

---

## 用語マッピング

agent-manifesto 新基盤の用語に翻訳しながら読むこと:

| 外部ツール用語 | 本基盤での対応 |
| --- | --- |
| issue / bug / ticket | `developmentFlag` つき leaf node（実装ノード） |
| operation / artifact | Lean canonical の append-only event |
| state / status | leaf node の `LifeCycleState`（type-safe enum） |
| label / tag | leaf node の categorical metadata |
| comment | append-only `Discussion` event |
| sync / bridge | Lean canonical → `gh issue` の片方向 codec |
| remote / upstream | GitHub Issue（read-only 表示・PR 連携層） |

---

## 対象選定の注記

`00-survey-plan.md` に列挙された対象のうち、以下は本ノートで精読対象から外した:
- **gtm / git-ticket**: 機能的に `git-issue` (dspinellis) と `SIT` でカバーされる。git-native な ticket 永続化パターンは両対象の精読で十分。独立調査による追加知見は限界。代替として **Fossil-scm** を詳細精読に昇格（tickets + wiki + repo 統合の独自性が高いため）。
- **Lean4 ProofWidget for interactive issue UI**: グループ C (Lean 4 メタプログラミング) で ProofWidgets4 として扱うため、重複回避

---

## Section 1: 各対象の精読ノート

### 1.1 Bugs Everywhere (be)

**一次資料**:
- 公式 ReadTheDocs: https://bugs-everywhere.readthedocs.io/en/latest/
- Free Software Directory: https://directory.fsf.org/wiki/Bugs_Everywhere
- LWN.net 記事 (2008): https://lwn.net/Articles/281849/
- GitHub fork (aaiyer): https://github.com/aaiyer/bugseverywhere

**設計概要**: 分散 VCS（Bazaar / Darcs / Git / Mercurial / Arch / Monotone）に対するバグデータベースの **薄い重ね合わせ**。プロジェクトのトップレベルに `.be/` ディレクトリを作り、bug を「テキストファイルを含むディレクトリ」として表現する。VCS 不在でも動作可能（"can also function with no VCS at all"）。

**1. テキスト永続化フォーマット**
- 1 bug = 1 directory（`.be/bugs/<bug-uuid>/`）
- 内部にメタデータファイル（severity, status, summary, ...）と `comments/` サブディレクトリ
- ファイル単位で読み書きされるため diff/patch が VCS と整合する

**2. 状態遷移**
- 既定 status: `open`, `assigned`, `test`, `closed`, `wontfix`, `disabled`, ...
- severity: `wishlist`, `minor`, `serious`, `critical`, `fatal`
- カスタム状態は config で追加可能だが、状態機械（許される遷移）を **enforce する仕組みがない**。任意遷移。

**3. ローカルファースト性**
- VCS のブランチに完全に同調する。bug がコードのブランチと一緒に流れる
- merge conflict は文字レベル: 「2 ブランチで severity を変えると、手動編集が必要な conflict」（LWN）
- これは CRDT 的設計の不在を示し、後発の git-bug が解決した課題

**4. Git との関係**
- VCS-agnostic。git は単なる選択肢。`.be/` は通常のワーキングツリーの一部
- git-bug が refs namespace を使うのと対照的に、be は **working tree commit** に依存する

**5. 他ツール連携**
- HTML エクスポート、メールインターフェース、libbe の Python API
- GitHub Issues 等への bridge は薄い

**6. メタデータ**: severity, status, target (milestone 相当), assigned, summary, creator, time, extra strings/links

**7. 依存・関係表現**: `target` で milestone 相当をグループ化できるが、blocks/blocked-by/parent/child のネイティブ表現は **弱い**

**8. 検索・query**: `be list` の filter による status/severity 絞り込み、tag query

**9. コメント / 履歴**: comments は append（新ファイル）。ただしファイル mutation は技術的に可能

**10. 同期パターン**: VCS push/pull に乗る。外部 issue tracker 同期は薄い

**新基盤への含意**: **反例**として有用。「バグを working tree のファイルに置く」設計は、VCS ブランチを切り替えるたびに bug list が変わる、severity 変更で merge conflict、という課題を露呈した。新基盤も似たことをすると同じ罠にはまる → **append-only event 形式 + 状態は再生による導出** を採るべき（fossil / git-bug / SIT が共通する解決策）。

---

### 1.2 git-issue (dspinellis)

**一次資料**:
- リポジトリ: https://github.com/dspinellis/git-issue
- README: https://github.com/dspinellis/git-issue/blob/master/README.md
- 主実装: https://github.com/dspinellis/git-issue/blob/master/git-issue.sh
- Manpage: https://github.com/dspinellis/git-issue/blob/master/git-issue.1

**設計概要**: pure shell script の git-native issue tracker。issue は別リポジトリ `.issues/` に格納され、独自に `.git/` を持つ。各 issue は SHA path で配置され、ファイル単位のメタデータを持つ。

**1. テキスト永続化フォーマット**
- 階層パス: `.issues/issues/<sha[0:2]>/<sha[2:]>/`（git の object store と同じ scheme）
- 各 issue ディレクトリのファイル:
  - `description`: 1 行サマリ + 本文
  - `tags`: 1 行 1 タグ（`open`/`closed` 含む）
  - `milestone`: マイルストーン名
  - `assignee`, `watchers`: メールアドレスのリスト
  - `duedate` (ISO-8601), `weight` (整数), `timespent`, `timeestimate` (秒)
  - `comments/<sha>/`: 各コメントは独立した commit
  - `attachments/`: 添付ファイル

**2. 状態遷移**: `open`/`closed` のみ。`gi close` が `open` タグを削除する。**カスタム state は tags で表現するしかない**（明示的な state machine はない）

**3. ローカルファースト性**: 完全。`.issues/.git/` は通常の git 操作で push/pull 可能

**4. Git との関係**: heavy。各 issue 操作 = 独立した git commit。SHA = issue ID = commit ID（最初の commit）

**5. 他ツール連携**: GitHub と GitLab への bidirectional 同期（`gi import`, `gi create`, `gi exportall`）。認証は `GH_CURL_AUTH` 環境変数

**6. メタデータ**: tags, milestone, assignee, watchers, due/weight/time

**7. 依存・関係**: ネイティブ表現なし（README / search に登場せず）

**8. 検索・query**: `gi list` の filter（tag/milestone）。git log で履歴検索

**9. コメント / 履歴**: 各 comment は独立 commit。git log で完全な audit trail

**10. 同期**: 双方向 GitHub/GitLab sync。`imports/` ディレクトリで外部 ID マッピング保持

**新基盤への含意**:
- **shell script 1 本で実装**できる粒度の設計は、Lean 自作 Pipeline からの codec として十分小さい目標
- **SHA path 配置**は immutable artifact の自然な表現。新基盤の event hash と整合
- **タグだけで state を表現**は弱い。新基盤は Lean enum で type-safe にすべき
- **`imports/` ディレクトリで外部 ID マッピング**は新基盤でも `lean-id ↔ gh-number` マッピングを永続化する patrón として再利用できる

---

### 1.3 SIT (Serverless Information Tracker)

**一次資料**:
- リポジトリ: https://github.com/sit-fyi/sit
- Linux Journal 記事: https://www.linuxjournal.com/content/foss-project-spotlight-sit-serverless-information-tracker
- 公式サイト: https://sit.fyi/
- modules ドキュメント: https://github.com/sit-fyi/sit/blob/master/doc/modules.md
- 議論: https://news.ycombinator.com/item?id=26912758

**設計概要**: 「情報追跡」一般化された append-only ツール。元は Serverless **Issue** Tracking、後に汎化。`No external database is required`、ファイルが medium。issue tracking はモジュールとして分離。

**1. テキスト永続化フォーマット**
- `.sit/` ディレクトリにすべて格納
- **records** = immutable, additive-only のファイル群
- 各 record はディレクトリ + ファイルセット
- JSON 形式の宣言的 record（"every change as an immutable, additive-only set of files"）

**2. 状態遷移**
- 状態は **records から reducer で導出**（state は格納しない）
- reducer = JavaScript（`.sit/module/MODULE/reducers/*.js`）
- 状態機械は reducer のロジックとして表現されるが、型システムによる enforce はない

**3. ローカルファースト性**: 第一原理。"sporadically connected parties to continue collaborating seamlessly"。同期は git/Dropbox/Keybase/USB 何でも可

**4. Git との関係**: **独立**。git に依存せず、git の上にも乗せられる（git でも Dropbox でも USB でも）

**5. 他ツール連携**: モジュール機構（reducers + CLI subcommands + web overlays）。プラグイン的拡張

**6. メタデータ**: モジュール側で自由定義。core は record の identity / timestamp のみ

**7. 依存・関係**: モジュール側で reducer によって表現

**8. 検索・query**: web overlay または CLI からの reduced state に対する query

**9. コメント / 履歴**: records は immutable append-only。**履歴 = records の連鎖**

**10. 同期**: ファイル転送ベース。独立した複数 peer が同じ records を持てば必ず同じ state に reduce される

**新基盤への含意**（**最も重要な参照源の一つ**）:
- **State = fold(reducer, events)** の哲学は、Lean canonical との整合性が高い
  - `LifeCycleState = foldEvents (init: Initial) (events: List Event)`
  - これは `Spec = (T, F, ≤, Φ, I)` の `Φ`（充足関係）と直結
- **records が medium** という設計は、「Lean canonical の hash が unique key」という新基盤と一致
- **JS reducer の代わりに Lean function** で state を導出すれば、type-safe な状態機械が完成
- **モジュール機構**は新基盤の「研究 tree タイプごとに異なる reducer を提供」する patrón として参照可能

---

### 1.4 git-bug (git-bug/git-bug)

**一次資料**:
- リポジトリ: https://github.com/git-bug/git-bug
- model.md（部分的に LLM 経由で取得）: https://github.com/git-bug/git-bug/blob/master/doc/model.md
- pkg.go.dev (Lamport): https://pkg.go.dev/github.com/MichaelMure/git-bug/util/lamport
- HN 議論 (2025): https://news.ycombinator.com/item?id=43971620

**設計概要**: git に **オブジェクトとして** issue を埋め込む（ファイルとしてではない）。`refs/bugs/*` namespace を使い、operation-based CRDT + Lamport 時計で merge を構造的に解決。CLI / TUI / Web / 各種 bridge を持つ。

**1. テキスト永続化フォーマット**
- ファイルとしてではなく **git object（blob/tree/commit）として格納**
- **OperationPack** = JSON 配列の Operation を含む git blob
- 各 OperationPack は同一 author の編集セッション 1 単位
- 識別子は git object hash

**2. 状態遷移**
- Operations: `Create`, `AddComment`, `EditComment`, `SetTitle`, `SetStatus`, `Label`, `SetMetadata` など
- `SetStatus` で `open`/`closed` のみ（カスタム status はネイティブ非対応）
- 状態は **Operations を時系列順に空状態に適用** = "snapshot"
- 順序: (1) git DAG topology → (2) Lamport clock → (3) hash tiebreak

**3. ローカルファースト性**: 完全。offline で編集、後で `git push refs/bugs/*` で同期

**4. Git との関係**: 最も deep。`refs/bugs/<bug-id>` でブランチを管理。working tree を汚さない

**5. 他ツール連携**: GitHub / GitLab / Jira への **bridge**（双方向同期）。CLI / TUI / Web UI / GraphQL API も完備

**6. メタデータ**: Identity（暗号鍵で署名された user）, labels, status, title, comments, files

**7. 依存・関係**: 既定では薄い。labels で擬似的に表現可能

**8. 検索・query**: 専用の query language。CLI で filter

**9. コメント / 履歴**:
- Operations は **append-only**
- `EditComment` も新 Operation として追加され、reducer が最新を採用
- 履歴は完全保持

**10. 同期パターン**:
- bridge 抽象（importer / exporter）
- Lamport clock は **DAG 制約と不変条件** を持つ: 親 commit の clock < 子 commit の clock。違反は reject
- 衝突は CRDT で merge 可能（`SetTitle` 二重設定など）

**新基盤への含意**（**最も近い参照モデル**）:
- **Operation as event + reducer による snapshot** は新基盤の Lean canonical と直接対応:
  ```
  Lean: structure ResearchTreeOp where ...
        def applyOp : NodeState → ResearchTreeOp → NodeState
        def snapshot (ops : List ResearchTreeOp) : NodeState := ops.foldl applyOp initial
  ```
- **Lamport + DAG 制約**は分散編集を構造的に enforce する。Lean 側で `LamportCmp` 述語を unfold すれば検証可能
- **`refs/bugs/<id>` namespace** は、新基盤が GitHub Issue とは独立した永続化層を持つ場合に直接 model できる
- **bridge 抽象**は新基盤の `Lean → gh issue` codec の理論モデルとして優秀:
  - importer: GitHub Issue → Lean event 群
  - exporter: Lean event 群 → GitHub Issue body / comments
  - 双方向ではなく **片方向（exporter のみ）** に限定すれば codec 設計が簡素化される

---

### 1.5 Org-mode TODO

**一次資料**:
- 公式 Manual Workflow states: https://orgmode.org/manual/Workflow-states.html
- Tracking TODO state changes: https://orgmode.org/manual/Tracking-TODO-state-changes.html
- Drawers: https://orgmode.org/manual/Drawers.html
- TODO dependencies: https://orgmode.org/manual/TODO-dependencies.html
- org-depend.el: https://orgmode.org/worg/org-contrib/org-depend.html
- Progress Logging: https://orgmode.org/manual/Progress-Logging.html

**設計概要**: plain text Org ファイル内の見出しに `TODO`/`DONE` キーワードを付与し、property drawer / LOGBOOK drawer でメタデータと履歴を保持。Emacs ベースだが、フォーマットは plain text として独立した価値を持つ。**研究プロセスの永続化フォーマットとして最も成熟したもの**の一つ。

**1. テキスト永続化フォーマット**:
- 1 outline tree = 1 ファイル
- 各見出しに `:PROPERTIES:` drawer（key-value）と `:LOGBOOK:` drawer（履歴）が associate
- メタデータは見出し直下の drawer に格納
- 例:
  ```org
  ** TODO Investigate Lamport clock semantics
  :PROPERTIES:
  :ID: 5f2a-...
  :CATEGORY: research
  :BLOCKER: 4d18-...
  :END:
  :LOGBOOK:
  - State "TODO"  from "PROPOSED"  [2026-04-17 Fri 10:00] \\
    Initial gap analysis complete.
  :END:
  ```

**2. 状態遷移**
- カスタム state machine: `(setq org-todo-keywords '((sequence "TODO(t)" "FEEDBACK(f@/!)" "VERIFY(v)" "|" "DONE(d!)" "CANCELED(c@)")))`
- `|` で actionable / completed を分離
- `(t)` shortcut, `(f@/!)` enter-時 note + leave-時 timestamp
- 並列ワークフロー（type vs sequence）も可
- per-file 設定: `#+TODO: ...` でファイル先頭に宣言可能

**3. ローカルファースト性**: 単一テキストファイル。git / Dropbox / 何でも同期可

**4. Git との関係**: agnostic。テキストファイルなので普通に versioned

**5. 他ツール連携**:
- agenda view（複数ファイル横断）
- Capture（外部から quick add）
- Babel（コード実行）
- Export（HTML / LaTeX / Markdown / ICS など）

**6. メタデータ**: PROPERTIES drawer の任意 key-value、`SCHEDULED`/`DEADLINE` timestamps、`PRIORITY`, `:tag1:tag2:`

**7. 依存・関係表現**（**新基盤に直接 import すべき設計**）:
- `ORDERED` property: 子要素を順序強制
- `BLOCKER` property: 他 entry の ID を指定して blocking
  - `:BLOCKER: previous-sibling` または `:BLOCKER: 5f2a-... 6e3b-...`
- `org-enforce-todo-dependencies`: 親が DONE になるには子が全 DONE
- `NOBLOCKING`: 例外
- `org-depend.el`: 状態変化トリガー（`org-trigger-hook`）と blocker（`org-blocker-hook`）の hook

**8. 検索・query**: agenda カスタム query、tags-todo search、property query

**9. コメント / 履歴**:
- LOGBOOK drawer に append（`!` = timestamp、`@` = note + timestamp）
- 各 state transition がエントリ
- mutable だが慣習的に append

**10. 同期パターン**: 外部 issue tracker への bridge は弱い（org2gh 等のサードパーティ）

**新基盤への含意**（**最も実用設計が成熟した参照源**）:
- **state transition 表記** `KEYWORD(shortcut@/!)` は宣言的で簡潔。Lean の state machine 定義の参考に
- **`:BLOCKER:` property** で entry ID 指定 → 新基盤の dependency 表現に直接 import 可能。Lean では `dependsOn : List NodeId` フィールド
- **PROPERTIES drawer** = 新基盤の leaf node 構造体に対応する自然な表現
- **LOGBOOK drawer** = append-only event log の patrón。`org-log-into-drawer` のように **history と current state を視覚的に分離** する設計は新基盤の Lean canonical でも採用すべき
- **org-enforce-todo-dependencies** の hook 機構 = `applyTransition` 関数で型レベル enforce 可能

---

### 1.6 GitHub Discussions vs Issues

**一次資料**:
- 公式 docs Discussions: https://docs.github.com/en/discussions
- GraphQL API Discussions guide: https://docs.github.com/en/graphql/guides/using-the-graphql-api-for-discussions
- Issues REST API changelog (2025-03): https://github.blog/changelog/2025-03-06-github-issues-projects-api-support-for-issues-advanced-search-and-more/
- REST API for issue types (2025-03): https://github.blog/changelog/2025-03-18-github-issues-projects-rest-api-support-for-issue-types/
- Sub-issues blog: https://github.blog/engineering/architecture-optimization/introducing-sub-issues-enhancing-issue-management-on-github/
- 学術論文: https://link.springer.com/article/10.1007/s10664-021-10058-6
- DEV community: https://dev.to/mishmanners/github-issues-or-github-discussions-whats-the-difference-and-when-should-you-use-each-one-4lhd

**設計概要**: GitHub の 2 つの conversation primitive。
- **Issues**: tracked work（タスク、バグ、scope 化された仕事）
- **Discussions**: open-ended conversation（質問、アイデア、show & tell）

**1. テキスト永続化フォーマット**: Markdown body + structured fields（title, labels, assignees, milestones, projects）。Discussions は **category** に属し、**answerable category** では answer 指定可

**2. 状態遷移**:
- Issues: `open`/`closed`、closed には `state_reason` (`completed`, `not_planned`, `duplicate`, `reopened`)
- 2025 から **Issue Types**（一般 preview）: `Bug`, `Feature`, `Task` などの type 分類
- Discussions: `open` のみ。**closed されない**（FAQ として残す設計）

**3. ローカルファースト性**: ゼロ。全部 GitHub の central server。offline 不可

**4. Git との関係**: 完全に **external store**。git repo とは独立した API

**5. 他ツール連携**: REST API (Issues), GraphQL API (両方)。webhook、Projects 統合、PR との link

**6. メタデータ**: title, body, labels, assignees, milestone, project field, state, state_reason, issue_type、Discussions は category, answer

**7. 依存・関係**:
- 2024+ **sub-issues**（一般提供 2025-08）。各 sub-issue は **1 親のみ**
- **dependencies (blocks/blocked-by)** も 2025-08 一般提供
- `gh-issue-ext` などのサードパーティ拡張で拡張的サポート

**8. 検索・query**: GitHub Search syntax（`label:bug state:open`）、GraphQL filter、advanced search API

**9. コメント / 履歴**: コメントは mutable（編集履歴は別 query）。`timeline_events` で全イベント取得可（label 追加、close、reopen 等）

**10. 同期パターン**:
- API 完備
- webhook で push 通知
- 双方向同期は外部ツールの責務（git-bug bridge 等）

**新基盤への含意**:
- **Issue Types**（2025 新機能）は新基盤の type-safe enum と整合させる機会:
  - Lean side: `LeafNodeType = Implementation | Investigation | Defect`
  - GitHub side: 対応する Issue Type を export 時に設定
- **Sub-issues は 1 親のみ**という制約は新基盤の研究 tree（DAG ではなく **木**）と一致 → 同期しやすい
- **Dependencies**（blocks/blocked-by, 2025-08 GA）が来たので、Lean canonical の dependsOn を export できるようになった
- **Discussions vs Issues** の二分は新基盤の「research process（gap, hypothesis）」 vs 「development node (`developmentFlag`)」の二分と相似:
  - 新基盤の **大部分は Lean に保持し**、
  - **Discussions 化したい未解決の問い** と **Issue 化したい末端の実装** に分けて GitHub に降ろす設計が可能
- **timeline_events API** で「Issue で起きた変化」を取得できる → 新基盤側の event log と双方向比較可能

---

### 1.7 Linear / Plane

**一次資料**:
- Linear workflow docs: https://linear.app/docs/configuring-workflows
- Linear GraphQL: https://linear.app/developers/graphql
- Linear schema: https://github.com/linear/linear/blob/master/packages/sdk/src/schema.graphql
- Linear changelog: https://linear.app/changelog
- Working with GraphQL API: https://developers.linear.app/docs/graphql/working-with-the-graphql-api

**設計概要**: API-first な commercial issue tracker。GraphQL ネイティブ、状態カテゴリの厳密化、Cycles（時間ボックス）、Initiatives（roadmap 後継）が特徴。

**1. テキスト永続化フォーマット**: 完全 SaaS。Markdown body のみが「テキスト」。それ以外は構造化フィールド

**2. 状態遷移**:
- 状態は **6 categories** に縛られる: `triage`, `backlog`, `unstarted`, `started`, `completed`, `canceled`
- 各 category の中で任意の名前の status を作れる（例: completed カテゴリの "Duplicate"）
- categories 自体は組み替え不可 → **type-safe な phase ordering**
- 既定: `Backlog → Todo → In Progress → Done → Canceled`

**3. ローカルファースト性**: なし

**4. Git との関係**: external。PR と link 可能

**5. 他ツール連携**: GraphQL API（first-class）、webhooks、Slack/GitHub/Sentry/Figma 連携

**6. メタデータ**: title, description, state, assignee, labels, priority, estimate, cycle, project, initiative, parent, child

**7. 依存・関係**: parent / child（issue hierarchy）, blocks / blocked-by, related, duplicate of

**8. 検索・query**: GraphQL filter language。views で永続化

**9. コメント / 履歴**: comments は mutable、history は activity feed として取得

**10. 同期パターン**: GraphQL の `issueUpdate` mutation で external -> Linear、webhook で Linear -> external

**新基盤への含意**:
- **6 categories の制約**は新基盤の状態機械設計の **教科書的 reference**:
  ```lean
  inductive PhaseCategory where
    | Triage | Backlog | Unstarted | Started | Completed | Canceled

  structure LifeCycleState where
    category : PhaseCategory
    customLabel : String
    -- Lean compiler enforces category invariants
  ```
- **categories は組み替え不可** = type-safe な phase ordering の実例。新基盤も Lean enum で硬く縛れる
- **GraphQL schema-first** な設計は、Lean canonical → GraphQL mutation 生成という codec として実装可能
- **Cycles** = time-boxed iteration の概念は、`/research` の sprint と相同
- **Initiatives**（旧 Roadmap）= 戦略的 grouping は研究 tree の上位ノードと相同

---

### 1.8 Fossil-scm (tickets)

**一次資料**:
- 公式: https://fossil-scm.org/
- 技術概要: https://fossil-scm.org/home/doc/tip/www/tech_overview.wiki
- Bug-Tracking 設計論: https://fossil-scm.org/home/doc/trunk/www/bugtheory.wiki
- Wikipedia: https://en.wikipedia.org/wiki/Fossil_(software)

**設計概要**: D. Richard Hipp（SQLite 作者）による statically-self-contained DVCS + bug tracker + wiki + forum。**全データを単一 SQLite ファイル** に格納し、ticket は **append-only artifact** として global state、レンダリング/スキーマは **local state** という二分が秀逸。

**1. テキスト永続化フォーマット**:
- すべて単一 SQLite DB（`.fossil`）に格納
- ticket の **永続化形式は artifact**: 「timestamp, ticket ID, name/value pairs を含むテキスト」
- artifact は immutable な hash-identified blob
- TICKET テーブルは artifact からの **派生キャッシュ**（再生可能）

**2. 状態遷移**:
- 状態は repo ごとの TICKET schema と report で定義
- core はあくまで name/value pair の append。state machine は repo local
- 「tickets do not branch」設計上の制約。状態は timestamp 順に積まれる

**3. ローカルファースト性**: 完全。SQLite ファイル 1 個で完結。push/pull で artifact 同期

**4. Git との関係**: 独自 DVCS。git とは別系統。artifact モデルは git と相同（hash-identified, content-addressed）

**5. 他ツール連携**: TH1 / Tcl スクリプティング、CGI、JSON API

**6. メタデータ**: name/value pair として任意定義（schema は repo local）

**7. 依存・関係**: ネイティブ表現は薄い。name/value で表現する慣習

**8. 検索・query**: SQL（TICKET テーブルに SQL を書ける）。**最も powerful な query 環境**

**9. コメント / 履歴**:
- artifact は append-only & immutable
- amendment は新 artifact として追加。古い artifact は変えない
- TICKET テーブルは「artifact を timestamp 順に replay」して再生

**10. 同期パターン**: artifact の sync。**global vs local** 分離が決定的:
  - global: artifact（ID + name/value pair の event log）
  - local: TICKET schema, web report, レンダリング規則
- schema 変更時は **replay algorithm が自動で TICKET テーブルを再構築**

**新基盤への含意**（**最も哲学的に近い参照源**）:
- **global state（event log）/ local state（schema, view）の分離** は新基盤に直接 import すべき:
  - **Lean canonical = global state**（再生可能、不変、hash-identified）
  - **GitHub Issue 表示 = local state**（rendering rule、各 client で独自）
- **schema 変更で replay** は新基盤の Lean canonical の進化（version up）にも適用可能
- **append-only artifact + replay** は git-bug の operation-based CRDT と本質的に同型
- **SQL 直接 query** は強力だが、Lean なら **型安全な query** が可能（mathlib の Finset query パターン等）

---

## Section 2: 比較表（10 観点 × 全対象）

凡例: ◎ = 強い / ○ = 中 / △ = 弱い / × = 非対応

| 観点 \ 対象 | be | git-issue | SIT | git-bug | Org-mode | GH Issues/Discussions | Linear | Fossil tickets |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| **1. テキスト永続化** | dir/file（plain） | dir/file (SHA path) | JSON records | git blob (JSON OperationPack) | 1 file outline | API only | API only | SQLite + artifact |
| **2. 状態遷移** | open/closed/etc 任意 | tag-based 2状態 | reducer 導出 | open/closed (CRDT) | カスタム state machine ◎ | open/closed + state_reason + Issue Types | 6 categories 強制 ◎ | repo local schema |
| **3. ローカルファースト** | ◎ (VCS と同調) | ◎ | ◎ (file medium) | ◎ (refs/bugs) | ◎ (single file) | × | × | ◎ (SQLite) |
| **4. Git との関係** | working tree | 独立 .git in .issues | agnostic | refs namespace ◎ | agnostic | external | external | 独自 DVCS |
| **5. 他ツール連携** | △ | ○ (gh/gl bridge) | ○ (modules) | ◎ (bridges) | ○ (capture/babel) | ◎ (REST/GraphQL) | ◎ (GraphQL first) | ○ (CGI/JSON) |
| **6. メタデータ** | severity/status/target | tags/milestone/assignee/etc | module-defined | identity/labels/status | PROPERTIES drawer 任意 | labels/assignees/milestone/Project field | labels/priority/cycle/initiative | name/value (任意) |
| **7. 依存・関係** | △ (target のみ) | × | reducer 次第 | △ (label 擬似) | ◎ (BLOCKER/ORDERED) | ○ (sub-issue 1親、blocks GA 2025-08) | ◎ (parent/child/blocks/related) | △ |
| **8. 検索・query** | filter | tag/milestone filter | reducer + web | query language | agenda + tags-todo | GitHub Search + GraphQL | GraphQL filter | **SQL ◎** |
| **9. コメント・履歴** | append (file mut可) | commit per comment ◎ | append-only ◎ | append-only ◎ | LOGBOOK append | mutable + timeline_events | mutable + activity | append-only artifact ◎ |
| **10. 同期パターン** | VCS push/pull | bidirectional GH/GL | file copy | bridge 抽象 | weak | API + webhook | GraphQL + webhook | artifact sync |

**注目すべきパターン**:
- **append-only event + 再生で state 導出** = SIT, git-bug, Fossil（**収束した設計**）
- **状態機械の表現力** = Org-mode > Linear > 他
- **依存表現** = Linear ≥ Org-mode > GH Issues > 他
- **永続化の独立性** = Fossil ≥ git-bug > SIT > git-issue ≥ Org-mode > be >> Linear / GH

---

## Section 3: 横断的な発見

### 3.1 収束した設計パターン

**(A) Append-only event log + reducer による state 導出**
- SIT (records + reducers), git-bug (Operations + snapshot), Fossil (artifacts + TICKET replay) が独立に到達
- これは **CQRS / Event Sourcing の小型版**
- 新基盤も **Lean canonical = event log + foldEvents で snapshot 導出** とすべき
- 利点:
  - merge conflict が CRDT で解ける
  - 履歴が完全保持
  - schema 進化時に replay で再構築可能

**(B) Lamport / 因果順序による分散整合**
- git-bug が refs/bugs と Lamport を組み合わせる
- 新基盤も「Lean canonical を peer 間で配布」する場合は適用可能
- ただし agent-manifesto の主流 worktree が単一なら overkill。**まず単一 source-of-truth を前提に**

**(C) 状態カテゴリ / state machine の二層化**
- Linear: 6 categories（不変） × カスタム status 名（可変）
- Org-mode: actionable / completed の `|` 区切り × 任意のキーワード
- GH Issues: open/closed × state_reason
- 新基盤への含意: **Lean enum で硬い categorical 層 + 文字列 label の柔らかい層** の二層設計

**(D) 親子 + blocks/blocked-by の二系統**
- Org-mode: `ORDERED`(parent) + `BLOCKER`(任意)
- Linear: parent/child + blocks/blocked-by + related
- GH Issues: sub-issues（2025+, 1 親制約） + dependencies (2025-08 GA)
- 新基盤の研究 tree は **木構造**を採るので sub-issue 親子は自然。**blocks** は別系統で必要

### 3.2 独自性のある設計

**(E) Fossil の global/local 分離**
- Global: event log（artifact）= 全 peer 共有
- Local: schema + rendering = 各 peer 独自
- 新基盤の **Lean canonical（global）/ GitHub Issue 表示（local）** に完全に対応
- これを採用すれば「rendering rule の変更」が global state を変えない設計になる

**(F) Org-mode の `(@/!)` 表記**
- 状態定義時に「enter で note 要求 / leave で timestamp」を 1 行で書ける
- 宣言的かつ簡潔。新基盤の Lean DSL に取り込むと表現が圧縮できる:
  ```lean
  states := [
    .new "PROPOSED",
    .new "INVESTIGATING" |>.requireNoteOnEnter |>.timestampOnLeave,
    .new "IMPLEMENTED",
    .terminal "VERIFIED" |>.timestampOnEnter,
    .terminal "RETIRED" |>.requireNoteOnEnter
  ]
  ```

**(G) git-bug の bridge 抽象**
- importer / exporter インタフェース
- 新基盤は **exporter のみ実装**（Lean → GitHub）して codec を最小化できる
- importer（GitHub → Lean）は不要（単方向で OK）

### 3.3 Unconverged / 未収束な設計

**(H) コメント history の mutable vs immutable**
- 厳密 immutable: SIT, git-bug, Fossil（再生でしか変えられない）
- mutable: Linear, GH（編集 API + history は別 query）
- 一見便利な mutable は audit trail を弱める。**新基盤は immutable 一択**

**(I) ローカル DB の選択**
- ファイルツリー: be, git-issue, SIT, Org-mode
- git object: git-bug
- SQLite: Fossil
- 新基盤には **ファイルツリー（Lean source）+ build artifact (Lake)** が既にある → そこに event log を追加する設計が自然

**(J) 状態遷移の enforcement 強度**
- 型レベル enforce: なし（既存ツール群）
- runtime enforce + override 可能: Org-mode, Linear
- 完全自由: be, git-issue, SIT
- 新基盤は **Lean 型レベル enforce + override 不可** が可能 → これは既存ツールに対する **明確な進歩**

---

## Section 4: 新基盤への適用可能性

### 4.1 研究 tree 末端の Issue ノード設計

`developmentFlag` つき leaf node の Lean 表現案（既存ツールから抽出した patrón に基づく）:

```lean
-- カテゴリは硬い enum（Linear-style）
inductive LifeCyclePhase where
  | Proposed       -- まだ作業開始前
  | Investigating  -- 調査中
  | Specifying     -- 仕様確定中
  | Implementing   -- 実装中
  | Reviewing      -- レビュー中
  | Verified       -- 検証完了
  | Retired        -- 退役済み
  | Cancelled      -- 中止

-- カテゴリ内のカスタム label（Linear の category-内 status と同じ）
structure LifeCycleState where
  phase : LifeCyclePhase
  label : String  -- 例: "Implementing/awaiting-CI"
  enteredAt : Timestamp

-- Org-mode BLOCKER 相当
structure LeafDependency where
  blockerId : NodeId
  kind : BlockerKind  -- .hardBlock | .softRef | .relates

-- Fossil/git-bug 風の event log
inductive LeafEvent where
  | created (id : NodeId) (initialPhase : LifeCyclePhase)
  | transitioned (from to : LifeCyclePhase) (note : Option String) (at : Timestamp)
  | commented (author : Identity) (body : String) (at : Timestamp)
  | dependencyAdded (dep : LeafDependency)
  | dependencyRemoved (dep : LeafDependency)
  | labelAdded (label : String)
  | labelRemoved (label : String)

-- snapshot は events.foldl applyEvent initial で導出（git-bug / SIT 流）
def snapshot (events : List LeafEvent) : LeafSnapshot := ...
```

### 4.2 Lean → GitHub Issue codec

git-bug の bridge と Fossil の global/local 分離を組み合わせた設計:

**設計原則**:
1. **片方向 export のみ**（Lean → gh issue）。reverse import は不要
2. **Lean canonical = global state**、GitHub Issue body = **rendering 結果**（local view）
3. 各 leaf node に対し `gh-mapping.json` で `lean-id ↔ gh-issue-number` を保持（git-issue の `imports/` 流）
4. Lean event を **GitHub timeline_events と一対一対応** させない（Lean が source of truth）。代わりに:
   - Issue body = `snapshot.summary` の Markdown 化
   - Issue state = `snapshot.phase` の `open`/`closed` map
   - Issue labels = `snapshot.labels` ∪ `snapshot.phase.toString()`
   - Issue comments = `events.filterMap (.commented?)`
5. **冪等性**: 再 export しても snapshot が同じなら Issue body は変わらない（content-hash 比較）
6. Issue Types (2025+) を使って `LifeCyclePhase` を type 化

**codec のシグネチャ**:
```lean
structure GhExportSpec where
  ghIssueNumber : Option Nat  -- 既存なら number、新規なら None
  title : String
  body : String  -- Markdown
  state : GhState
  labels : List String
  issueType : GhIssueType
  comments : List GhComment

def Leaf.toGhExportSpec : LeafSnapshot → GhExportSpec
```

そして `gh issue create` / `gh issue edit` を呼ぶ deterministic スクリプトで実体化。

### 4.3 状態機械の Lean 表現

Org-mode の宣言的記法を inspiration に、**Lean 型レベルで遷移可能性を強制**:

```lean
-- 許される遷移を型レベルで定義（unfold 可能な述語）
inductive AllowedTransition : LifeCyclePhase → LifeCyclePhase → Prop where
  | proposed_to_investigating : AllowedTransition .Proposed .Investigating
  | investigating_to_specifying : AllowedTransition .Investigating .Specifying
  | specifying_to_implementing : AllowedTransition .Specifying .Implementing
  | implementing_to_reviewing : AllowedTransition .Implementing .Reviewing
  | reviewing_to_verified : AllowedTransition .Reviewing .Verified
  | reviewing_to_implementing : AllowedTransition .Reviewing .Implementing  -- rework
  | any_to_cancelled : AllowedTransition p .Cancelled
  | verified_to_retired : AllowedTransition .Verified .Retired

-- 遷移を Lean が拒否できる
def transition (current : LifeCyclePhase) (next : LifeCyclePhase)
    (proof : AllowedTransition current next) : LifeCyclePhase := next
```

これは既存ツールにはない **type-safe な state machine の enforcement**。Lean compiler が拒否するため、不正遷移は CI 段階で発見される。

### 4.4 依存伝播と blocked 検出

Org-mode の `BLOCKER` + `org-enforce-todo-dependencies` を Lean で:

```lean
def Leaf.canTransition (snapshot : LeafSnapshot) (allLeaves : Map NodeId LeafSnapshot) : Bool :=
  snapshot.dependencies.all fun dep =>
    match allLeaves.find? dep.blockerId with
    | none => false  -- 不在の blocker は遷移を許さない（git-issue の魔法依存問題を解決）
    | some blockerSnap =>
      match dep.kind with
      | .hardBlock => blockerSnap.phase == .Verified || blockerSnap.phase == .Retired
      | .softRef => true
      | .relates => true
```

「`#NNN を参照` の魔法依存により、退役・参照不能の検出が機械的にできない」という現行課題（00-survey-plan.md）に対する **Lean 型レベルの解**。

### 4.5 イベントログの永続化と GitHub 同期の分離

Fossil の global/local 分離を採用:

```
lean-formalization/
  Research/
    Tree/
      <node-id>.lean        ← global state（events のリスト + snapshot）
      <node-id>.events.json ← deterministic な event log のシリアライズ
  
gh-export/
  mappings.json             ← lean-id ↔ gh-issue-number
  rendered/<node-id>.md     ← export 直前の rendered Markdown（diff 用）
  log/<timestamp>.jsonl     ← 過去の export 履歴（ローカル監査用）
```

`gh-export/` は **local state**（再生可能、global state からのみ生成）。これは新基盤の `/research` スキル propagate.sh の発展形と整合する。

---

## Section 5: 限界と未解決問題

### 5.1 調査の限界

1. **WebFetch の 403/404**: bugs-everywhere readthedocs と git-bug の `doc/model.md` 直接 fetch は failed。LLM 経由の検索結果から推論。**完全な OperationPack の JSON schema は未確認**（一次資料リンクは記載済み、直接の確認は未実施）。
2. **SIT の reducer 詳細**: JS 実装の具体例は web 経由で確認できなかった。`https://sit.fyi/` の二次 fetch は未実施。
3. **Plane**（Linear の OSS 対抗）は Linear と類似と推定して Linear のみ精読。Plane 独自の設計は未調査。
4. **Lean4 ProofWidget for interactive issue UI**: 計画の対象に含まれていたが、issue UI 用途の事例は見つからず。グループ C（Lean メタプログラミング）に委譲が妥当。

### 5.2 設計上の未解決問題

1. **mutable vs immutable comment**:
   - 完全 immutable は audit trail に強いが、typo 修正が painful
   - GitHub Issue 側は mutable なので、export 時に Lean event を「commenter / body / timestamp」で 1:1 マップしてしまうと、後の Lean 側 edit が GitHub に反映されない
   - 解決案: GitHub 側 comment を **Lean event の最新スナップショットの再生結果** とし、特定の Lean event ID には bind しない（rendering と event を分離）

2. **GitHub の sub-issue 1 親制約 vs 新基盤の研究 tree**:
   - 研究 tree が strict tree なら問題なし
   - もし複数親（DAG）を許すなら、GitHub への export 時に **代表親** を選ぶ規則が必要

3. **Lamport clock の必要性**:
   - 単一 worktree なら不要
   - 複数 worktree / 並列 agent で同じ leaf node を編集する場合に必要
   - agent-manifesto の現行運用は単一だが、将来の並列化を想定するか要決定

4. **dependsOn が壊れた blocker を指す場合**:
   - Org-mode は警告のみ
   - Lean では「不在の blocker = transition 不可」とする方が型安全だが、experiment 中の暫定的な無効 ref も許したい場合の妥協が必要

5. **Issue Types（GitHub 2025）と LifeCyclePhase の mapping**:
   - GitHub の Issue Type は org 単位の限定リスト
   - Lean の `LeafNodeType`（Investigation / Implementation / Defect / ...）と GitHub Issue Type が 1:1 でない場合のフォールバック規則が必要

6. **rendering の安定性**:
   - 同じ Lean snapshot から **常に同じ Markdown を生成** することが冪等性の前提
   - Markdown 生成器は deterministic でなければならない（Lean の `ToString` 派生 + 順序保証）

### 5.3 後続研究への送り

- **Group C (Lean meta)** へ: 状態機械の Lean DSL 化（`syntax`/`elab` で Org-mode 風の宣言的構文を実現）
- **Group D (build graph)** へ: event log の incremental rebuild（Bazel/Nix の content-addressing と統合）
- **Group F (内部資産)** へ: 既存の `.claude/skills/research/scripts/propagate.sh` と `closing.sh` をこの設計に置換するための diff 計画

---

## Sources（一次資料 URL 一覧）

### Bugs Everywhere
- https://bugs-everywhere.readthedocs.io/en/latest/
- https://directory.fsf.org/wiki/Bugs_Everywhere
- https://lwn.net/Articles/281849/
- https://github.com/aaiyer/bugseverywhere

### git-issue (dspinellis)
- https://github.com/dspinellis/git-issue
- https://github.com/dspinellis/git-issue/blob/master/README.md
- https://github.com/dspinellis/git-issue/blob/master/git-issue.sh
- https://github.com/dspinellis/git-issue/blob/master/git-issue.1

### SIT
- https://github.com/sit-fyi/sit
- https://github.com/sit-fyi/issue-tracking
- https://github.com/sit-fyi/sit/blob/master/doc/modules.md
- https://www.linuxjournal.com/content/foss-project-spotlight-sit-serverless-information-tracker
- https://sit.fyi/

### git-bug
- https://github.com/git-bug/git-bug
- https://github.com/git-bug/git-bug/blob/master/doc/model.md
- https://pkg.go.dev/github.com/MichaelMure/git-bug/util/lamport
- https://news.ycombinator.com/item?id=43971620
- https://news.ycombinator.com/item?id=33730417
- https://news.ycombinator.com/item?id=17782121

### Org-mode
- https://orgmode.org/manual/Workflow-states.html
- https://orgmode.org/manual/Tracking-TODO-state-changes.html
- https://orgmode.org/manual/Drawers.html
- https://orgmode.org/manual/TODO-dependencies.html
- https://orgmode.org/worg/org-contrib/org-depend.html
- https://orgmode.org/manual/Progress-Logging.html
- https://www.nongnu.org/org-edna-el/

### GitHub Discussions / Issues
- https://docs.github.com/en/discussions
- https://docs.github.com/en/graphql/guides/using-the-graphql-api-for-discussions
- https://docs.github.com/en/issues/planning-and-tracking-with-projects/understanding-fields/about-parent-issue-and-sub-issue-progress-fields
- https://github.blog/changelog/2025-03-06-github-issues-projects-api-support-for-issues-advanced-search-and-more/
- https://github.blog/changelog/2025-03-18-github-issues-projects-rest-api-support-for-issue-types/
- https://github.blog/engineering/architecture-optimization/introducing-sub-issues-enhancing-issue-management-on-github/
- https://link.springer.com/article/10.1007/s10664-021-10058-6
- https://github.com/jwilger/gh-issue-ext

### Linear
- https://linear.app/docs/configuring-workflows
- https://linear.app/developers/graphql
- https://github.com/linear/linear/blob/master/packages/sdk/src/schema.graphql
- https://developers.linear.app/docs/graphql/working-with-the-graphql-api
- https://linear.app/changelog

### Fossil-scm
- https://fossil-scm.org/
- https://fossil-scm.org/home/doc/tip/www/tech_overview.wiki
- https://fossil-scm.org/home/doc/trunk/www/bugtheory.wiki
- https://fossil-scm.org/home/doc/trunk/www/whyallinone.md
- https://en.wikipedia.org/wiki/Fossil_(software)
