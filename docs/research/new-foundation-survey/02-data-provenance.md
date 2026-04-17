# Group B: Data Provenance / Workflow Tracking — 先行研究サーベイ

**作成日**: 2026-04-17
**担当**: Group B (Data Provenance & Workflow Tracking)
**目的**: agent-manifesto の研究プロセス記録基盤（Lean 文書 + 自作 Pipeline + `artifact-manifest.json` + `/trace`）の設計に向けて、科学計算/ML 領域における provenance 形式化、lineage 表現、immutable records、retraceability、失敗実験の記録、陳腐化検知の方式を抽出する。
**問い**: 研究プロセスの provenance をどう形式化し永続化するか？

## Section 1: 各対象の精読ノート

調査対象 8 件:
1. W3C PROV (PROV-DM, PROV-O, PROV-N, PROV-CONSTRAINTS)
2. Common Workflow Language (CWL) + CWLProv
3. ResearchObject + RO-Crate + Workflow Run Crate
4. Snakemake
5. Nextflow
6. Galaxy
7. MLflow
8. DVC

各観点 (10): lineage 表現 / immutable records / retraceability / 失敗実験 / 陳腐化検知 / 形式化レベル / データ永続化 / API・プログラマブル性 / incremental computation / 規模

---

### 1.1 W3C PROV (PROV-DM, PROV-O, PROV-N, PROV-CONSTRAINTS)

**1次出典**:
- PROV Overview: https://www.w3.org/TR/prov-overview/
- PROV-DM (Recommendation 2013-04-30): https://www.w3.org/TR/prov-dm/
- PROV-O (OWL ontology): https://www.w3.org/TR/prov-o/
- PROV-CONSTRAINTS: https://www.w3.org/TR/prov-constraints/
- Missier の拡張紹介: https://blogs.ncl.ac.uk/paolomissier/2021/02/07/w3c-prov-some-interesting-extensions-to-the-core-standard/

**位置づけ**: provenance を表現する W3C 標準。12 文書からなる「ファミリー」で、PROV-DM が概念モデル、PROV-O が OWL 表現、PROV-N が人間可読記法、PROV-CONSTRAINTS が validator のための制約集合。本基盤の語彙としての候補。

**lineage 表現**: 三項構造 `(Entity, Activity, Agent)` を中心に、Component 1–6 に分割（PROV-DM §5）:
- Component 1: Generation, Usage, Communication, Start, End, Invalidation
- Component 2: Derivation（および Revision, Quotation, Primary Source）
- Component 3: Attribution, Association, Delegation
- Component 4: Bundle（provenance-of-provenance）
- Component 5: Specialization, Alternate
- Component 6: Collection, Membership

主要 edge 型: `wasGeneratedBy(e, a)`, `used(a, e)`, `wasAttributedTo(e, ag)`, `wasDerivedFrom(e2, e1, a, g, u)`, `wasInformedBy(a2, a1)`, `actedOnBehalfOf(ag2, ag1)`, `wasAssociatedWith(a, ag, plan)`. すべての edge は optional ID + attributes を持てるため拡張可能（PROV-O §3.3 Qualified Terms）。

**immutable records**: PROV-DM は entity が「fixed aspects」を持つことを要求し、`wasInvalidatedAt` 関係で entity の lifespan 終端を表現する（§5.1.8）。PROV 自体は不変性を強制しないが、bundle が「provenance of provenance」を提供することで「いつ・誰が記録したか」を追跡可能（§2.2.2, §4.3）。改竄検知のための checksum メカニズムは PROV 自体では定義しない（CWLProv 等の上位プロファイルが付与）。

**retraceability**: `prov:Plan`（§3.2 PROV-O）が「実行されるべき手順の記述」として導入され、`wasAssociatedWith(a, ag, plan)` の plan 引数で活動の意図を記録できる。これにより「何の plan を実行しようとしたか」が provenance に組み込まれる。PROV-DM §5.2.1 は「derivation の包括的な記述が provenance-based reproducibility を促進する」と明記。

**失敗実験の記録**: PROV-DM は失敗を明示的にはサポートしない（PROV-DM §5 では完了 activity に焦点）。ただし `wasInvalidatedAt` を活用して「entity が無効化された理由」を attributes に含めることで、失敗エンティティの記録は表現可能。`PROV-DM` の汎用性により、ドメイン拡張（例: failure ステレオタイプ）として運用される。

**陳腐化検知**: PROV 単体には陳腐化検知の概念はない。derivation chain 上で source entity が `wasInvalidatedAt` を持つかどうか、または bundle の timestamps を SPARQL で query することで間接的に検出する。

**形式化レベル**: セマンティック（OWL 2 + RDF）。PROV-O は OWL 推論可能で、PROV-CONSTRAINTS は first-order logic の制約集合 24 件を定義。PROV-N は EBNF で形式定義された人間可読記法。Lean のような型レベル検証ではなく、validator は別実装（W3C は実装ノート公開）。

**データ永続化**: テキスト形式（PROV-N, PROV-XML, PROV-JSON, PROV-O Turtle/RDF/JSON-LD）。すべてプレーンテキストでバイナリ依存なし、git 互換。外部 DB は不要だが、SPARQL endpoint で query する場合は triplestore（例: Apache Jena）が必要。

**API / プログラマブル性**: SPARQL（PROV-O への RDF query）、PROV-AQ（access protocol）、PROV-LINKS（bundle linking）。実装ライブラリは ProvToolbox (Java), prov (Python), rdflib など豊富。

**incremental computation**: PROV はデータモデルであり実行エンジンではないため、incremental computation の概念は持たない。derivation chain の部分的取得は SPARQL query で実現。

**規模**: PROV のグラフは標準 RDF として linear scaling、triplestore で billions of triples まで実証。billion-scale provenance graph の事例は ProvAnalyzer や git provenance 研究で報告。

---

### 1.2 Common Workflow Language (CWL) + CWLProv

**1次出典**:
- CWL User Guide v1.2: https://www.commonwl.org/user_guide/
- CWLProv profile (GitHub): https://github.com/common-workflow-language/cwlprov/
- CWLProv prov.md: https://github.com/common-workflow-language/cwlprov/blob/main/prov.md
- CWLProv 論文 (GigaScience 2019): https://academic.oup.com/gigascience/article/8/11/giz095/5611001
- cwltool CWLProv 実装: https://cwltool.readthedocs.io/en/latest/CWLProv.html

**位置づけ**: 抽象ワークフロー仕様の OSS 標準。実行エンジン非依存（cwltool, Toil, Arvados, Cromwell 対応）。CWLProv は CWL 実行から PROV を抽出する profile。

**lineage 表現**: CWL は `Workflow` ↔ `CommandLineTool` の二層 DAG（YAML/JSON）。`inputs`/`outputs` の型と接続関係でグラフを構成。CWLProv は実行を W3C PROV にマップ:
- `wfprov:WorkflowEngine` (Agent) — cwltool process
- `wfprov:WorkflowRun`, `wfprov:ProcessRun` (Activity) — トップレベル/各ステップ
- データファイル (Entity) — `urn:hash:sha1:<hash>` URI で content-addressed
（CWLProv prov.md "Account section", "Data inputs section"）

**immutable records**: 入出力データは SHA1 ハッシュ URI で永続化。BagIt RO 構造（`metadata/manifest.json` に `sha256` ハッシュ）で全ファイルの整合性を検証可能（CWLProv 論文 "BagIt specification section"）。Research Object は immutable bag として扱われる。

**retraceability**: prospective provenance（CWL spec 自体）+ retrospective provenance（実行 trace）の両方を bundle 化。CWLProv Level 2 では「targeted components の inspection と automatic re-enactment」をサポート（論文 "Level 2" subsection）。partial rerun は推奨されているが具体的メカニズムは実装依存。

**失敗実験の記録**: CWLProv は失敗の表現に明示的指針がない（論文 "Reruns/Failures" 節は限定的）。cwltool は失敗時に exit code を含む report を生成するが、PROV graph 内の標準表現は将来課題。

**陳腐化検知**: 入力ファイルの SHA1 hash が変わると新規 entity になり、derivation chain が分岐する。陳腐化は明示的検知ではなく、新しい hash を持つ entity の存在で間接的にわかる。

**形式化レベル**: CWL 自体はテキスト仕様（YAML schema）+ JSON Schema 検証。CWLProv は W3C PROV のサブセット + ステレオタイプ拡張（`wfprov:` namespace）。型はシンプルな構造型で、依存型ではない。

**データ永続化**: BagIt フォーマットの研究オブジェクト。`data/` (payload), `metadata/manifest.json` (checksums), `metadata/provenance/primary.cwlprov.{nt,json,xml}` (PROV)。tarball で配布可能、git 互換。

**API / プログラマブル性**: cwltool CLI、Python ライブラリ、SPARQL via PROV-O。`prov` Python ライブラリで PROV-N/JSON 編集可能。

**incremental computation**: CWL ランナーごとに異なる。cwltool は基本的に全実行、Toil/Arvados は intermediate の caching を持つ。CWLProv は実行記録のみで再実行ポリシーは持たない。

**規模**: 大規模 NGS pipeline（数千ジョブ）で実用。CWL を採用する Galaxy/Arvados で peta-scale データ処理事例あり。

---

### 1.3 ResearchObject framework + RO-Crate (+ Workflow Run Crate)

**1次出典**:
- RO-Crate ホーム: https://www.researchobject.org/ro-crate/
- RO-Crate 1.2 spec: https://www.researchobject.org/ro-crate/specification.html
- Workflow Run RO-Crate: https://www.researchobject.org/workflow-run-crate/
- Provenance Run Crate profile: https://www.researchobject.org/workflow-run-crate/profiles/provenance_run_crate/
- PLOS One 2024 論文: https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0309210
- arXiv preprint: https://arxiv.org/html/2312.07852v1

**位置づけ**: 研究成果物（コード、データ、論文、ワークフロー）を JSON-LD + schema.org で metadata 化し、ディレクトリツリーとしてパッケージングする軽量標準。RO-Crate は Research Object community effort の現行版。

**lineage 表現**: JSON-LD ベース、`ro-crate-metadata.json` がエントリーポイント。schema.org の `CreateAction`, `instrument`, `object`, `result` プロパティで activity 表現。Workflow Run Crate (WRROC) は 3 層の profile を提供（profile collection page）:
- **Process Run Crate**: 単一ツール実行（最小粒度）
- **Workflow Run Crate**: ワークフロー実行（superset of Process Run）
- **Provenance Run Crate**: ステップ別 internal details（superset of Workflow Run）

Provenance Run Crate は「各ステップ実行を CreateAction として記録、`instrument` で実行ツールを参照」（仕様 §3）。

**immutable records**: RO-Crate は配布パッケージ（ZIP/directory）として immutable に運用される慣行。spec 自体は SemVer に従い、major で term 削除可（specification §"Versioning"）。checksum は profile によって規定（Workflow Run Crate は通常 `sha256` を `contentSize` 等と並べて記述）。

**retraceability**: prospective + retrospective provenance を同一 crate 内で表現。`SoftwareApplication` + `Workflow` + `CreateAction` + `params` で実行を完全記述可能。Workflow Hub での共有・再実行を前提に設計。

**失敗実験の記録**: schema.org の `ActionStatusType` (CompletedActionStatus, FailedActionStatus) を `CreateAction.actionStatus` に設定可能。Provenance Run Crate spec で失敗 action の表現が想定される。

**陳腐化検知**: profile 自体は陳腐化検知を持たないが、`hasPart` 関係 + checksum で「included file が変わった」検知が可能。ワークフロー再実行時に diff 検出は外部ツール（例: Galaxy, COMPSs）が担う。

**形式化レベル**: JSON-LD + schema.org 語彙 + RO-Crate 拡張 (`ro-crate-metadata.json`)。OWL レベルの semantic、Lean のような型レベル検証ではない。conformance は profile 単位（"MUST/SHOULD" 文言）。

**データ永続化**: ディレクトリ構造（`ro-crate-metadata.json` + payload files）。ZIP として配布可。git 互換、git-lfs と組み合わせて大ファイル対応。外部 DB 不要。

**API / プログラマブル性**: Python `rocrate` library、JS `ro-crate-html`、Galaxy/Nextflow plugin (nf-prov)、StreamFlow/WfExS/Sapporo/Autosubmit 対応（Workflow Run Crate ホーム "Implemented systems"）。

**incremental computation**: RO-Crate 自体はパッケージング規格、incremental の概念なし。実装側（Galaxy 等）が caching を担う。

**規模**: WorkflowHub で数千の workflow crate を配布。COMPSs で数万ステップの workflow を Provenance Run Crate として export 実績。

---

### 1.4 Snakemake

**1次出典**:
- 公式 docs: https://snakemake.readthedocs.io/
- 公式サイト: https://snakemake.github.io/
- F1000Research 論文 (Mölder 2021): https://pmc.ncbi.nlm.nih.gov/articles/PMC8114187/
- Reports docs: https://snakemake.readthedocs.io/en/stable/snakefiles/reporting.html
- Provenance metadata 論文 (CEUR Vol 2357): https://ceur-ws.org/Vol-2357/paper8.pdf

**位置づけ**: Python ベースの DAG ワークフロー管理。`Snakefile` に `rule` を宣言、wildcards で generic 化、依存は出力ファイルパスから自動解決。

**lineage 表現**: rule の `input`/`output` 関係から DAG を自動構築（F1000 論文 §2.1）。「DAG 構築は job 数に linear time、通常実行時間と比べて negligible」。wildcards `{country}` 等で generic rule を多インスタンス化。`Figure 3b` に DAG 例示。

**immutable records**: Snakemake は実行ログを `.snakemake/log/` に保存。output ファイルの mtime + content hash（オプション）で変更検出。HTML report (Snakemake 5.1+) は self-contained で実行時の input/output/parameter/software/code を埋め込み（reporting.html）。

**retraceability**: container/conda env の指定で再現環境を保証（Snakemake 7+ で auto-containerization、generated Dockerfile が conda envs を deploy）。`--report` で生成される HTML には DAG + node 別の input/output/code/runtime stats が含まれ、別環境での再実行を支援。

**失敗実験の記録**: 失敗時は exit code 非ゼロで停止。`--keep-going`, `--rerun-incomplete` で部分成功を保持。失敗ジョブのログは `.snakemake/log/` に永続化。F1000 論文では failure recovery メカニズムは詳述されていない（手動 rerun が基本）。

**陳腐化検知**: 入力ファイルが output より新しい場合、または code/params が変わった場合に再実行（make-like semantics）。`--list-changes {code,input,params,version}` で staleness を列挙。`--summary` で全 output の status を表示。

**形式化レベル**: Python DSL（rule は Python statement）。type system は Python の duck typing。形式検証はない。LSP/Snakefmt で構文検査のみ。

**データ永続化**: Snakefile（プレーンテキスト Python）、`config.yaml`、`.snakemake/` メタデータ。HTML report は self-contained zip。git 互換、外部 DB 不要。

**API / プログラマブル性**: Python API（`snakemake.workflow.Workflow`）、CLI、Jupyter integration。`benchmark:` directive で自動計測。

**incremental computation**: 基本的な make-like recomputation。input が変わると下流のみ rerun。`--touch` で出力 mtime のみ更新。新しい cache (Snakemake 6+) は content hash based。

**規模**: F1000 §3.5 の scaling test: 11 jobs で 0.5s/90MB、90,000 jobs で 37s/1.1GB。HPC（SLURM 等）と Kubernetes 統合で peta-scale 実績（COVID-19 解析等）。

---

### 1.5 Nextflow

**1次出典**:
- 公式 docs (Seqera): https://docs.seqera.io/nextflow
- Cache and resume: https://www.nextflow.io/docs/latest/cache-and-resume.html
- "Demystifying Nextflow resume" (Seqera blog): https://seqera.io/blog/demystifying-nextflow-resume/
- "Caching behavior analysis" (2022): https://www.nextflow.io/blog/2022/caching-behavior-analysis.html

**位置づけ**: Groovy/Nextflow DSL で記述する dataflow 型ワークフローエンジン。reactive paradigm（channels で非同期データ移動）。HPC + cloud 両対応。

**lineage 表現**: `process` を `channel` で接続したグラフ（implicit DAG）。「データ依存が実行フローを暗黙的に決定」（公式 overview）。各 process の input/output channels がエッジ。

**immutable records**: 各タスクは hash 化された work directory（`work/<XX>/<hash>/`）に隔離。hash 入力には Session ID, Task name, container image, conda env, CPU architecture, inputs, eval commands, script, referenced global variables が含まれる（cache-and-resume docs §"Hash"）。ファイル hash は **path + last modified timestamp + size**。LevelDB に index 化（.nextflow/cache）。

**retraceability**: `-resume` で前回 run の hash を照合し、既存の work dir 出力を再利用。session ID 指定で過去の特定 run から resume 可。container/conda 統合で環境を再現。

**失敗実験の記録**: ハッシュ衝突時に「incrementing component」を hash に追加して新 dir を作成（retry 用）。失敗タスクは work directory に exit code とログが残る。`-with-trace` で trace.txt（task 別の status, runtime, exit code）を出力。

**陳腐化検知**: 入力ファイルの path/mtime/size のいずれかが変わると hash mismatch → re-execute。Seqera blog は「mtime を変えるだけで cache miss する」notorious 問題を指摘。

**形式化レベル**: Groovy DSL、最低限の型注釈。形式検証はない。`nextflow inspect` で metadata 抽出のみ。

**データ永続化**: `.nf` スクリプト（プレーンテキスト）、`nextflow.config`、`work/` (cache、通常 `.gitignore` 化)、`.nextflow/cache/<session>/db/` (LevelDB)。LevelDB は **single reader/writer** 制限あり、cloud cache は S3 backed で複数同時アクセス可（cache-and-resume docs §"Limitations"）。

**API / プログラマブル性**: nf-prov plugin で Workflow Run RO-Crate / BCO export。`-with-report`, `-with-timeline`, `-with-dag` で各種 report 出力。

**incremental computation**: 各 task 個別の hash based caching。partial graph re-execution は -resume で自動。

**規模**: nf-core community pipeline（数百のワークフロー、数千の users）。AWS Batch / Kubernetes / SLURM で peta-scale。caching で 80% 以上の job skip 達成（Seqera caching analysis 2022）。

---

### 1.6 Galaxy

**1次出典**:
- Galaxy Hub: https://galaxyproject.org/
- 2024 update 論文 (NAR): https://academic.oup.com/nar/article/52/W1/W83/7676834
- PMC 版: https://pmc.ncbi.nlm.nih.gov/articles/PMC11223835/
- Job cache 2026 ニュース: https://galaxyproject.org/news/2026-03-04-galaxy-job-cache/

**位置づけ**: Web UI 中心の data analysis platform。tool wrapper + workflow editor で再現可能な解析を支援。500K+ users, 1M+ jobs/月（NAR 2024）。

**lineage 表現**: `History` という linear/tree-like 構造で全 dataset と job を記録。各 dataset は input job + parameters + output position を保持。Workflow editor で graph 表示・編集可能。

**immutable records**: history は user 操作で append-only に成長（dataset の hide/delete はあるが、provenance metadata は保持）。job caching（2026-03 introduced）は「再利用を明示的に記録、auditability と reproducibility を維持」（job cache news）。

**retraceability**: history → workflow extraction（"extract workflow from history" 機能）。Workflow を import/share/rerun でき、同じ tool version + params で再現。Histories は **RO-Crate** または **BioComputeObject (BCO, IEEE 2791-2020)** として export 可能（NAR 2024 §"Workflows"）。

**失敗実験の記録**: 失敗 job も history に残り、stderr/stdout を確認できる。Workflow invocation の error report は UI 経由で詳細閲覧可。

**陳腐化検知**: tool version 変更時は history に古い version 記録が残るため、再実行時に明示的に新 version との差分を見られる。job cache は input + tool version + params の hash で照合。

**形式化レベル**: tool は XML wrapper（input/output 型、param 制約）。workflow は Galaxy 独自 JSON。型システムは Galaxy datatype hierarchy（OOP-style）。形式検証はない。

**データ永続化**: PostgreSQL backend（job/dataset/history テーブル）、object store（local FS, S3, iRODS）。RO-Crate / BCO export はファイル形式。Server-centric で local-first ではない。

**API / プログラマブル性**: REST API（BioBlend Python lib）、tool shed、workflow API。RO-Crate / BCO export で標準フォーマット出力。

**incremental computation**: job cache（2026-03+）で同一 hash の job をスキップ。Galaxy job cache news 曰く「環境責任にも貢献、provenance はバイパスせず明示的に reuse 記録」。

**規模**: NAR 2024 で 500K+ users、1M+ jobs/月。usegalaxy.* インスタンス群で TB-PB 規模データ処理。

---

### 1.7 MLflow

**1次出典**:
- 公式 docs: https://mlflow.org/docs/latest/
- ML Tracking: https://mlflow.org/docs/latest/ml/tracking
- ML Projects: https://mlflow.org/docs/latest/ml/projects/
- OneUptime guide (2026): https://oneuptime.com/blog/post/2026-01-28-configure-mlflow-projects/view

**位置づけ**: Databricks 発の ML lifecycle 管理プラットフォーム。4 components: Tracking, Projects, Models, Registry。

**lineage 表現**: 概念階層: **Experiment ⊃ Run ⊃ {params, metrics, tags, artifacts}**（Tracking docs §"Concepts"）。Run 同士は **parent/child run** 関係（nested run）で tree を構成（FAQ: "child run for each fold in cross-validation"）。Model は Run から派生し、Registry に登録。lineage は run-id 参照ベース。

**immutable records**: Run は完了後 immutable（status: RUNNING, FINISHED, FAILED, KILLED）。tags は後から追加可能だが metric/param は基本 append-only。artifact は backend store（S3 等）に格納、checksum は MLflow 自体は強制しないが backend に依存。

**retraceability**: **MLflow Projects** が再現性を担保（MLproject YAML）:
- entry points + parameters（型定義 + default 値）
- environment: `conda_env` (conda.yaml) または `docker_env`（両者排他）
- `mlflow run <uri>` で git URI から直接実行可、git commit hash を Run に自動記録
（Projects docs）

**失敗実験の記録**: Run の `status` フィールドに `FAILED`/`KILLED` を記録。stack trace は tag/artifact に保存可能。失敗 run も Experiment 内に永続化される。

**陳腐化検知**: MLflow 単体には input dataset の陳腐化検知なし（DVC 統合で補う）。Models Registry の stage 遷移（Staging→Production→Archived）でモデルの陳腐化を表現。

**形式化レベル**: REST API + Python/R/Java SDK。MLproject は YAML schema。型は MLflow Models flavor system（pyfunc, sklearn, etc.）。形式検証はない。

**データ永続化**: 二層: **Backend Store**（metadata: file system or PostgreSQL/MySQL/SQLite）+ **Artifact Store**（large files: local FS, S3, Azure Blob, GCS）。デフォルトは `mlruns/` ディレクトリ（local-first 可能）。

**API / プログラマブル性**: 言語別 SDK 充実、REST API、UI、Tracking Server。MLflow Projects で reproducible run。Search API で run filtering（SQL-like syntax）。

**incremental computation**: なし（MLflow は実験管理に特化、ワークフロー engine ではない）。Pipelines (deprecated) や Recipes が存在したが現在は外部 orchestrator (Airflow, Prefect) との統合が主流。

**規模**: Databricks platform で数千万 run の管理実績。OSS 版でも数十万 run まで一般的。SQL backend で billion-scale tag/metric query 可能。

---

### 1.8 DVC (Data Version Control)

**1次出典**:
- Get Started: https://doc.dvc.org/start
- Pipelines: https://doc.dvc.org/user-guide/pipelines/defining-pipelines
- Internal Files: https://dvc.org/doc/user-guide/project-structure/internal-files
- repro command: https://doc.dvc.org/command-reference/repro

**位置づけ**: git に薄く乗せたデータ + パイプライン versioning ツール。実データは外部ストレージに置き、git は metadata（`.dvc` files, `dvc.yaml`, `dvc.lock`）のみ管理。

**lineage 表現**: `dvc.yaml` に stages（cmd, deps, outs, params, metrics, plots）を宣言。stage 間で「output が他 stage の input になる」ことで自動 DAG 構築（dvc dag コマンドで可視化）。`dvc.lock` に各 stage の deps/outs の checksum + cmd を保存。

**immutable records**: content-addressable storage（`.dvc/cache/`）。各ファイルは MD5 hash でアドレス化（例: `22a1a2931c8370d3aeedd7183606fd7f`）。git に commit された `.dvc`/`dvc.lock` で全 history が復元可能。

**retraceability**: `dvc repro` で `dvc.yaml` の指定 stage を再実行（依存変更時のみ）。`dvc checkout` + git checkout で過去の状態に戻す。「100GB ファイルの version 切替が 1 秒未満」（DVC docs）。

**失敗実験の記録**: `dvc exp` (experiments) サブシステムで失敗実験も branch like に保存（git branch を作らず、ephemeral commit として）。`dvc exp show` で失敗実験を比較可能。

**陳腐化検知**: `dvc status` で stage の状態を `new`/`modified`/`deleted` で報告。dependency hash が `dvc.lock` と一致しなければ「需要 rerun」。`dvc update` で imported data の最新 version 取得。

**形式化レベル**: YAML schema（`dvc.yaml`, `.dvc` files）。型は無し（cmd は shell string）。形式検証は YAML schema validation のみ。

**データ永続化**: テキスト metadata (`.dvc`, `dvc.yaml`, `dvc.lock`) は git tracked。実データは local cache（`.dvc/cache`）+ remote (S3, Azure, GCS, SSH, GDrive 等)。完全 local-first 可能（remote なし運用）。

**API / プログラマブル性**: CLI 中心、Python API（`dvc.api`）、`dvc plots` で可視化。`dvc exp` で hyperparameter search 自動化。

**incremental computation**: `dvc.lock` の hash 比較で changed stage のみ rerun。下流も自動 invalidate。「make-like だが content hash based」（DVC docs）。

**規模**: 100GB+ ファイル取り扱い実証。S3 remote で TB 規模 OK。billion-file 級 dataset での性能はチェックサム計算がボトルネック（DVC issues #2891, #1568）。

---

## Section 2: 比較表（10 観点 × 8 対象）

| 観点 | PROV | CWL/CWLProv | RO-Crate (WRROC) | Snakemake | Nextflow | Galaxy | MLflow | DVC |
|---|---|---|---|---|---|---|---|---|
| **lineage 表現** | (E,A,Ag) 三項 + 6 component | DAG (Workflow⊃Tool) + PROV mapping | JSON-LD `CreateAction` + 3-level profile | rule DAG (input→output) | channel-process dataflow DAG | History tree + workflow graph | Experiment⊃Run, parent/child | dvc.yaml stage DAG |
| **immutable records** | 概念のみ (bundle で provenance-of-prov) | SHA1 URI + BagIt manifest sha256 | profile 別 checksum, SemVer | mtime + opt content hash | task hash (LevelDB) | history append-only + DB | Run status FROZEN | MD5 content-addressed |
| **retraceability** | Plan + derivation chain | prospective + retrospective in Bag | crate (workflow + run) 同梱 | conda/container + HTML report | -resume + container | RO-Crate/BCO export | MLproject + git commit | dvc repro + git checkout |
| **失敗実験の記録** | 標準では未対応 (拡張で表現) | 限定的、cwltool ログのみ | `FailedActionStatus` (schema.org) | exit code + log, --keep-going | exit code in trace, retry hash | history に失敗 job 残存 | status FAILED, stack trace tag | dvc exp で ephemeral 保存 |
| **陳腐化検知** | SPARQL query で間接的 | 入力 hash の変化 | 標準では未対応 | `--list-changes`, summary | hash mismatch → rerun | tool version diff | なし (DVC 統合で補う) | `dvc status` で詳細 report |
| **形式化レベル** | OWL + 24 制約 (PROV-CONSTRAINTS) | YAML schema + PROV-O ステレオタイプ | JSON-LD + schema.org | Python DSL (型なし) | Groovy DSL | XML tool wrapper + JSON workflow | YAML + REST schema | YAML schema |
| **データ永続化** | RDF/XML/JSON-LD/PROV-N | BagIt directory | dir + JSON-LD, ZIP配布 | Snakefile + .snakemake/ | .nf + LevelDB cache | PostgreSQL + obj store | Backend (DB) + Artifact (FS/S3) | git + content-addressed cache |
| **API/programmability** | SPARQL, ProvToolbox, prov.py | cwltool, prov lib | rocrate (Py), nf-prov, plugin 多 | Python API + CLI | Groovy API, plugin | REST + BioBlend | 多言語 SDK + REST | CLI + dvc.api (Py) |
| **incremental computation** | N/A (data model のみ) | runner 依存 (Toil でキャッシュ) | N/A (パッケージ規格) | make-like (mtime/hash) | hash-based per-task | job cache (2026-03) | N/A (実験管理) | content hash diff |
| **規模** | billions of triples (triplestore) | Toil/Arvados で peta-scale | WorkflowHub で数千 crate | 90K jobs/37s benchmark | nf-core peta-scale | 500K+ users, 1M+ jobs/月 | 数千万 run (Databricks) | 100GB+ ファイル, TB remote |

---

## Section 3: 横断的な発見

### 3.1 共通モデル: PROV を中心とした収束

W3C PROV (2013) が事実上の lingua franca となり、新しい profile（CWLProv, Workflow Run Crate, BCO）はすべて PROV の Entity/Activity/Agent を基底語彙として再利用している。本基盤の `Spec = (T, F, ≤, Φ, I)` の `≤` (精緻化半順序) と PROV の `wasDerivedFrom` は構造的に対応する（`Spec1 ≤ Spec2` ⇔ `Spec2 wasDerivedFrom Spec1`）。

### 3.2 二層分離パターン: Metadata / Artifact

DVC, MLflow, Nextflow, Galaxy はいずれも **メタデータ（小・git 互換・テキスト）** と **アーティファクト（大・content-addressed・外部ストレージ）** を物理的に分離している。
- DVC: git tracks `.dvc`, content-addressed cache stores data
- MLflow: Backend Store (DB) + Artifact Store (S3)
- Nextflow: `.nf` + `.nextflow/cache` LevelDB index
- Galaxy: PostgreSQL metadata + object store payload

agent-manifesto への含意: **Lean 文書 (T) は git tracked、artifact-manifest.json は content-addressed で external storage** という二層が自然に整合する。

### 3.3 Hash based vs mtime based: 進化の方向性

旧世代（make, 旧 Snakemake）は mtime based、現代（DVC, Nextflow, Snakemake 6+, MLflow with DVC）は **content hash based** に移行。理由:
- mtime はファイルシステム間で不安定（cp, rsync で変わる）
- 真の content equality を反映しない
- distributed/cloud 環境で再現性を失う

agent-manifesto への含意: 自作 Pipeline は **content hash based cache** を最初から採用すべき。Lean ファイル + spec + artifact を SHA-256 で hash 化し、re-derivation の判断に使う。

### 3.4 三層 profile アプローチ (Workflow Run Crate)

Workflow Run RO-Crate の 3 層 (Process / Workflow / Provenance) は **粒度別の段階的 commitment** という強力なパターンを示す:
- 最小 conformance（Process Run Crate: 単一実行のみ）
- 中間 conformance（Workflow Run Crate: ワークフロー全体）
- 完全 conformance（Provenance Run Crate: ステップ別 internal details）

各上位プロファイルが下位の superset であることが保証されている。本基盤の研究 tree も「最小: Survey ノードのみ」「中間: Survey + Hypothesis」「完全: 全 Spec lineage」のような段階的 conformance を採用できる。

### 3.5 失敗実験の永続化: 共通の弱点

PROV、CWL、RO-Crate、Snakemake、Galaxy のいずれも **失敗の表現が secondary**。DVC `dvc exp` と MLflow（`status: FAILED`）が比較的明示的だが、根本原因分析（why failed）の構造化は手動 tag/note に依存。本基盤では **失敗ノードを first-class** にする差別化機会がある（次節）。

### 3.6 独自性のあるアプローチ

- **Nextflow incrementing hash**: retry 時に hash を増分させて衝突回避（task の異なる実行を同じ key 空間で区別）。本基盤の re-derivation 識別に応用可能。
- **Galaxy job cache provenance**: 「reuse を明示的に記録、provenance はバイパスしない」という方針は重要。cache hit を「ノード再利用」として lineage に組み込む設計。
- **MLflow Projects + git commit auto-record**: code version を provenance に強制連動。同じパターンを Lean spec の git commit hash 自動埋め込みで再現可能。
- **DVC dvc.lock**: stage 別の入力/出力 hash + cmd を **lockfile** として git tracked にする。Cargo.lock 等と同じ思想。本基盤の「Spec snapshot lockfile」設計に直接転用可能。

### 3.7 不足機能 (gap analysis)

| 機能 | PROV | CWL | RO-Crate | Snakemake | Nextflow | Galaxy | MLflow | DVC |
|---|---|---|---|---|---|---|---|---|
| 型レベル検証 (Lean-class) | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |
| 失敗 first-class | ✗ | ✗ | △ | △ | △ | △ | ○ | ○ |
| 半順序関係 explicit | △ | ✗ | ✗ | ✗ | ✗ | ✗ | △ | ✗ |
| 退役 (deprecation) 検出 | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | △ | ✗ |
| 仮説 (hypothesis) 表現 | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |
| Plan vs Run の区別 | ○ (Plan class) | ○ (prospective/retro) | ○ (workflow/run profile) | ✗ | ✗ | △ | △ | ✗ |

→ 本基盤の独自貢献の余地: **型安全な hypothesis ノード**, **失敗 first-class**, **退役の構造的検出**, **半順序の明示的型化**。

---

## Section 4: 新基盤への適用可能性 (agent-manifesto への転用案)

### 4.1 PROV 三項を Lean 型で実体化

```
inductive ResearchEntity : Type where
  | Survey | Gap | Hypothesis | Decomposition | Spec | Implementation | Failure

inductive ResearchActivity : Type where
  | Investigate | Decompose | Refine | Verify | Retire

structure ResearchAgent where
  identity : String  -- LLM session ID, human ID
  role : Role        -- Researcher | Reviewer | Verifier

-- PROV-style edges (型レベルで強制)
inductive WasDerivedFrom : ResearchEntity → ResearchEntity → Type
inductive WasGeneratedBy : ResearchEntity → ResearchActivity → Type
inductive WasAttributedTo : ResearchEntity → ResearchAgent → Type
```

PROV の汎用性に Lean の型安全性を加える。`WasDerivedFrom` を非対称関係として宣言し、半順序の axiom を定理化（既存 `Manifest/` の `≤` 公理と接続）。

### 4.2 二層分離: Lean tree + content-addressed manifest

- **Layer 1 (git tracked)**: `research-tree/<node-id>.lean` ファイル群、各 entity は型 instance、edge は宣言。Lean compiler が graph の整合性を検証（cycle 検出は依存型で阻止）。
- **Layer 2 (artifact-manifest.json + cache)**: 各 node の実行ログ、出力ファイル、外部リンクを SHA-256 hash でアドレス化。`artifact-manifest.json` を git tracked、payload は別ストレージ。

これにより PROV-DM の bundle 思想と DVC の二層分離を統合した形になる。

### 4.3 失敗 first-class: Failure を separate type

MLflow/DVC の弱点（失敗の post-hoc 化）を回避し、`Failure : ResearchEntity` を最初から型に組み込む。`whyFailed : Failure → FailureReason` を total function として要求し、根本原因を構造化記録。

```
inductive FailureReason where
  | HypothesisRefuted (evidence : Evidence)
  | ImplementationBlocked (blocker : Spec)
  | SpecInconsistent (inconsistency : InconsistencyProof)
  | Retired (replacedBy : ResearchEntity)
```

### 4.4 退役の構造的検出

PROV の `wasInvalidatedAt` 概念を Lean 型で強化:
```
structure RetiredEntity where
  entity : ResearchEntity
  retiredAt : Timestamp
  retiredBy : ResearchAgent
  successor : Option ResearchEntity  -- 後継があれば
  reason : RetirementReason
```

Lean compiler が「退役済 entity への参照」を warning/error として検出（custom linter または elaborator）。これは Issue ベース運用では検出不可能だった機能。

### 4.5 自作 Pipeline = Snakemake/DVC の retrofit

DVC の `dvc.yaml` stage モデルを参考に、自作 Pipeline 段階を `Spec` の精緻化として Lean で表現:

```
DSL  ≤  AST  ≤  LeanSpec  ≤  SMTSpec  ≤  Tests  ≤  Code
```

各 ≤ ステップは Snakemake rule に対応。content hash (Spec のハッシュ) で incremental rerun を判定。

### 4.6 Nextflow resume 的 incremental + Galaxy job cache 的 explicit 記録

cache hit を「reuse activity」として lineage に明示記録（Galaxy job cache 方針）。再利用された node にも `WasReusedBy` edge を張り、計算スキップが provenance graph で見えるようにする。

### 4.7 RO-Crate 互換 export

最終的に Provenance Run Crate として export 可能にすることで、外部 tool（WorkflowHub, Galaxy）との interop を確保。Lean tree → JSON-LD への schema-preserving 変換を Lean meta-program として実装。

---

## Section 5: 限界と未解決問題

### 5.1 各先行研究の根本的限界

1. **PROV**: 抽象 data model のみ。ストレージ、検証、UI、incremental 等は実装側に丸投げ。「何を記録するか」は規定するが「どう運用するか」の指針が薄い。
2. **CWL/CWLProv**: 失敗の表現が secondary、partial rerun の標準化がない。CWL 自体は依存解決のみで semantic な意図表現が弱い。
3. **RO-Crate**: パッケージング規格に留まり、執筆中の研究（in-flight research）の表現は対象外。完成形の archival 中心。
4. **Snakemake**: Python DSL の柔軟性が形式検証を阻む。input/output の型が無く、shell command が opaque。
5. **Nextflow**: LevelDB single-writer 制限、mtime based file hash の脆さ、Groovy 学習コスト。
6. **Galaxy**: Server-centric で local-first 不可。学術機関 hosted instance 前提。
7. **MLflow**: ML 実験管理に特化、研究プロセス全体（仮説、文献、議論）は対象外。lineage は Run 階層のみで、artifact 間の derivation 表現が弱い。
8. **DVC**: data + pipeline 中心、研究プロセス（hypothesis, decomposition）の表現は想定外。git に依存（git なしでは機能限定）。

### 5.2 全対象に共通する未解決問題

- **判断・意図の記録**: なぜその hypothesis を立てたか、なぜそのアプローチを選んだか、という **judgmental rationale** の構造化は全対象で未解決。Plan/CreateAction の `description` フィールドに自然言語で書かれるのみ。
- **退役・陳腐化**: 自動検出は限定的。MLflow Registry の stage が最も近いが、研究文脈には不十分。
- **仮説の表現**: hypothesis as first-class entity は **どの先行研究にも存在しない**。実験管理ツールは「実験 = run」を仮定し、仮説は param として暗黙化。
- **半順序の明示化**: PROV の `wasDerivedFrom` は推移的だが反対称性は強制されない。「どちらがより精緻化されたか」の partial order は実装側の解釈に委ねられる。
- **形式検証**: 全対象が semantic-level（OWL, JSON-LD, YAML schema）で停止。compile-time の型レベル検証は未踏領域。

### 5.3 本基盤が向き合うべき技術的課題

1. **Lean tree のスケール**: 数千ノード規模の Lean ファイル群を compile する時間 (Lean 4 elaborator の性能)。incremental compilation の活用が必須。
2. **JSON-LD/RO-Crate との bidirectional 変換**: 外部 interop のため、Lean ↔ JSON-LD の lossless mapping が必要。
3. **失敗の根本原因分類**: `FailureReason` を sound かつ exhaustive にするには domain knowledge が必要（V1-V7 の violation taxonomy と統合？）。
4. **マルチエージェント協調**: 複数 LLM session が同時に tree を更新する際の merge 戦略。Nextflow LevelDB single-writer の轍を踏まないため、git merge ベースが現実的か。
5. **存在検証 vs 構成検証**: PROV は存在のみ記録し、構成を強制しない。Lean では「prov chain が closed であること」を型で要求できるが、運用負荷とのバランス設計が必要。

---

## 引用一覧 (1次出典)

### W3C PROV
- [PROV Overview (Note, 2013)](https://www.w3.org/TR/prov-overview/)
- [PROV-DM (Recommendation, 2013)](https://www.w3.org/TR/prov-dm/)
- [PROV-O (Recommendation, 2013)](https://www.w3.org/TR/prov-o/)
- [PROV-CONSTRAINTS](https://www.w3.org/TR/prov-constraints/)
- [Missier extensions notes](https://blogs.ncl.ac.uk/paolomissier/2021/02/07/w3c-prov-some-interesting-extensions-to-the-core-standard/)

### CWL / CWLProv
- [CWL User Guide v1.2](https://www.commonwl.org/user_guide/)
- [CWLProv repo](https://github.com/common-workflow-language/cwlprov/)
- [CWLProv prov.md](https://github.com/common-workflow-language/cwlprov/blob/main/prov.md)
- [CWLProv GigaScience 2019](https://academic.oup.com/gigascience/article/8/11/giz095/5611001)
- [cwltool CWLProv docs](https://cwltool.readthedocs.io/en/latest/CWLProv.html)

### RO-Crate / Workflow Run Crate
- [RO-Crate site](https://www.researchobject.org/ro-crate/)
- [RO-Crate 1.2 spec](https://www.researchobject.org/ro-crate/specification.html)
- [Workflow Run RO-Crate](https://www.researchobject.org/workflow-run-crate/)
- [Provenance Run Crate](https://www.researchobject.org/workflow-run-crate/profiles/provenance_run_crate/)
- [PLOS One 2024](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0309210)
- [arXiv 2312.07852](https://arxiv.org/html/2312.07852v1)

### Snakemake
- [Snakemake docs](https://snakemake.readthedocs.io/)
- [Mölder 2021 F1000 PMC](https://pmc.ncbi.nlm.nih.gov/articles/PMC8114187/)
- [Reports docs](https://snakemake.readthedocs.io/en/stable/snakefiles/reporting.html)
- [Provenance metadata paper, CEUR Vol 2357](https://ceur-ws.org/Vol-2357/paper8.pdf)

### Nextflow
- [Nextflow docs (Seqera)](https://docs.seqera.io/nextflow)
- [Cache and resume](https://www.nextflow.io/docs/latest/cache-and-resume.html)
- [Demystifying resume blog](https://seqera.io/blog/demystifying-nextflow-resume/)
- [Caching analysis blog 2022](https://www.nextflow.io/blog/2022/caching-behavior-analysis.html)

### Galaxy
- [Galaxy hub](https://galaxyproject.org/)
- [NAR 2024 update](https://academic.oup.com/nar/article/52/W1/W83/7676834)
- [PMC version](https://pmc.ncbi.nlm.nih.gov/articles/PMC11223835/)
- [Job cache 2026](https://galaxyproject.org/news/2026-03-04-galaxy-job-cache/)

### MLflow
- [MLflow docs](https://mlflow.org/docs/latest/)
- [Tracking](https://mlflow.org/docs/latest/ml/tracking)
- [Projects](https://mlflow.org/docs/latest/ml/projects/)
- [OneUptime guide 2026](https://oneuptime.com/blog/post/2026-01-28-configure-mlflow-projects/view)

### DVC
- [Get Started](https://doc.dvc.org/start)
- [Pipelines](https://doc.dvc.org/user-guide/pipelines/defining-pipelines)
- [Internal Files](https://dvc.org/doc/user-guide/project-structure/internal-files)
- [repro command](https://doc.dvc.org/command-reference/repro)
