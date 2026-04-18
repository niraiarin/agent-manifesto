# 新基盤研究 後続タスク一覧

**作成日**: 2026-04-17
**目的**: Phase 0 Week 1 完了時点で、「後続 Week / 以降の作業」「仮実装」「後回し判断」として記録した全項目を一元化し、後で後続タスクに反映できる状態にする。
**範囲**: セッションログ全体（サーベイ段階〜Gap Analysis〜Phase 0 Week 1 re-do 完了まで）
**参照**: `10-gap-analysis.md`（104 Gap + 10 Warning の根拠）、`99-verifier-rounds.md`（Verifier 検証履歴）

---

## 1. Phase 0 ロードマップ残タスク (Week 2-8)

G5-1 Section 3.5 の 8 週ロードマップ（Week 1 完了、Week 2 以降未着手）:

### Week 2-3: Spine 層
- `AgentSpec/Spine/EvolutionStep.lean`
- `AgentSpec/Spine/SafetyConstraint.lean`
- `AgentSpec/Spine/LearningCycle.lean`
- `AgentSpec/Spine/Observable.lean`
- **完了基準**: 4 type class + dummy instance
- **注意**: G5-1 当初計画は `Cslib.LTS` 再利用だが、GA-I5 により CSLib 依存は Week 6 延期。Week 2-3 では Mathlib 既存型または独自定義で代替（Core.lean 冒頭の `/-!` コメント参照）
- **Week 1 からの持ち越し優先タスク** (Section 2 から、Day 10 終了時点の状態):
  - ⚠ **Day 5 部分達成** — 普遍 round-trip 定理 (Section 2.2)。Day 1 で signature + bounded 7³ 証明済、Day 5 で bounded 8³ 拡張 + 6 helper theorems 追加。**universal proof は Day 6/Week 3 へ繰り延べ** (consumeNat correctness + String/List interop で 100+ 行、Lean-Auto 統合 Week 6 で SMT 自動証明可能性あり、Section 2.10 で 🔴 格上げ済)
  - ✅ Day 2 解消 — `lean_lib AgentSpecTest` 分離 (Section 2.3、commit `58b75a0`)
  - ✅ Day 1 解消 — Core.lean に明示的 `import` 文追加 (Section 2.2、commit `a43eef4`)
  - 🔄 継続中 — Top-down / hole-driven 実装スタイル採用 (Section 2.6、Day 1-10 で実践)
  - ✅ **Day 1-5 Spine 層完了 + Day 6-7 Process 層完備 + Day 8 Section 2.9 完全解消 + Day 9 Provenance 層 3 type + Day 10 Provenance 4 type 完備 (PROV-O 三項統合完了)** — FolgeID (GA-S2) Day 1 / Edge (GA-S4) Day 2 / EvolutionStep + SafetyConstraint (GA-S1) Day 3 / LearningCycle + Observable (GA-S1) Day 4 で **Section 1 Week 2-3 完了基準 (4 type class + dummy instance) 達成**。**Day 5 で順序関係完備**。**Day 6-7 で Process 層 4 type 完備**。**Day 8 で Section 2.9 完全解消**。**Day 9 で Provenance 層 3 type**、**Day 10 で Provenance 層 4 type 完備 (PROV-O 三項統合完了 + EvolutionMapping 連携 path 確立)**。**Pattern #7 hook 化は Day 5 構造的解決 + Day 6/7/8/9/10 で 5 度連続運用検証成功 + Day 10 v2 拡張** (Section 6.2.1 完全 closure + 運用安定性確立 + governance evolution、Provenance/Test/Cross detection 追加)。**Day 10 で layer architecture 完成形** (Spine + Process + Provenance + Cross test の 4 layer)。Ord (lex total order) / S6 BST/AVL invariants / DecidableEq 手動実装 / payload 拡充 / transitionLegacy 削除 / EvolutionStep 4 member 化 / LearningM / PROV-O relation の Lean 化 / RetiredEntity は Day 11+ へ繰り延げ

### Week 3-4: Manifest 移植
- 既存 `lean-formalization/Manifest/` の T1-T8, P1-P6 を `AgentSpec/Manifest/` 配下に整理
- docstring 強化
- **完了基準**: 既存 55 axioms（2026-04-17 実測）すべて import 可
- 実施方針: GA-I7 で (b) 再定義方針を採用（Lake cross-project require は避ける）

### Week 4-5: Process 層 (Day 6+ で前倒し開始)

**Day 6 (推奨案、Minimal + PROV vocabulary alignment in docstring)**:
- `AgentSpec/Process/Hypothesis.lean` (inductive Hypothesis、claim type、refines/refutes 関係)
- `AgentSpec/Process/Failure.lean` (inductive Failure + FailureReason 4 variant、02-data-provenance §4.3 first-class Failure)
- 各 docstring に PROV mapping 注記 (`Hypothesis ↦ ResearchEntity.Hypothesis` 等、Day 8+ で実装)
- Test 2 ファイル

**Day 7+ (Hypothesis/Failure 完備後)**:
- `AgentSpec/Process/Evolution.lean` (EvolutionStep B4 4-arg post 統合、Section 2.9 残課題解消)
- `AgentSpec/Process/HandoffChain.lean` (T1 一時性 inductive、handoff sequence)

**当初予定の追加 (Day 8+ または別 Week で配置)**:
- `AgentSpec/Process/ResearchNode.lean` (GA-S1 umbrella)
- `AgentSpec/Process/Provenance.lean` (GA-S3)
- `AgentSpec/Process/Retirement.lean` (GA-S5)
- `AgentSpec/Process/State.lean` (GA-S7)
- `AgentSpec/Process/Rationale.lean` (GA-S8)

**注**: FolgeID (GA-S2) と Edge (GA-S4) は Day 1-2 で `AgentSpec/Spine/` 配下に既に実装済 (元 `Process/` 配置案から Spine 層へ移動)。

- **完了基準**: `.claude/skills/handoff` の state machine が型として表現される + Hypothesis/Failure/Evolution/HandoffChain inductive 完備

### Week 5-6: Tooling 層
- `agent_verify` tactic 実装 (GA-C26)
- `VcForSkill` VCG (GA-C26)
- SMT hammer bridge (GA-C7): LeanHammer / Duper / Lean-Auto / Boole
- EnvExtension Auto-Register (GA-C9)
- Call-site obligation generation (GA-C22)
- **完了基準**: 少なくとも 5 定理を hammer で自動証明

### Week 6-7: CI 整備
- `lake test` target 作成 (GA-I9, GA-I11)
- `lake lint` target 作成 (GA-I11)
- `lake exe checkInitImports`
- GitHub Actions 統合
- `.claude/hooks/` の新基盤対応 (GA-I12)
- CSLib / LeanHammer / LeanDojo 依存追加 (GA-I5)
- Python 依存管理 (uv / pyproject.toml) (GA-T7)
- LeanDojo Python API 統合 (GA-I6)
- Pantograph 採用 (GA-I13)
- **完了基準**: GitHub Actions green

### Week 7-8: Verification
- 既存 1670 theorems のうち代表 100+ を新構造下で再証明
- CLEVER 風自己評価 10-20 サンプル (GA-M1)
- 既存 GitHub Issue → Lean canonical の migration 戦略決定 (GA-T3)
- MEMORY.md の Lean 化 migration (GA-T6)
- Self-benchmark (manifesto を 24 番目 repo) (GA-E1)
- 外部ベンチマーク比較 (FLTEval / miniF2F / DafnyBench / CLEVER / VeriBench) (GA-E7)
- 3-level Verify strategy L1/L2 実装 (GA-M12, GA-M13)
- **完了基準**: 再証明率 > 80%, 自己評価 > 60%

---

## 2. Phase 0 Week 1 時点で仮実装・後回しした具体項目

### 2.1 `agent-spec-lib/lakefile.lean`

| 項目 | 現状 | 後続計画 |
|---|---|---|
| LeanHammer / Lean-Auto / Duper / CSLib require | コメントアウト | Week 6 で有効化 (GA-C7, GA-I5) |
| `weak.linter.unreachableTactic = true` | 設定のみ、直接的な termination 保護効果は限定的 | Week 5-6 で fuel pattern + stack depth 制限を実装 (GA-C31) |
| `$schema` URI (artifact-manifest.json) | `https://agent-manifesto.internal/schemas/...` で非解決可能 | agent-manifesto 本体の manifest schema 整備時に同期 (Week 6-7) |
| `@[default_target]` 以外の target | `lean_lib AgentSpec` のみ | Week 6 で `lake exe test` / `lake exe lint` target 追加 |

### 2.2 `agent-spec-lib/AgentSpec/Core.lean`

| マーク | 項目 | 現状 | 後続計画 |
|---|---|---|---|
| 🔄 Day 2-5 進行中 | `SemVer` 以外の型 | **Day 1 で FolgeID 追加済**。NodeID, ResearchNode, Edge は Day 2-5 で追加 | Day 2 で Edge (GA-S4), Day 3-5 で Spine 層 type class |
| 🔄 Day 4-5 着手予定 | 普遍 round-trip 定理 `∀ v, parse (render v) = some v` | **Day 1 で def signature + bounded 7³=343 ケース証明済** (Proofs/RoundTrip.lean)。universal proof は後続 | Day 4-5 で induction 証明本体を `roundTripUniversal_proved` として実装 |
| ✅ 基盤実装済 | `Ord SemVer` lexicographic | Week 1 (β) で実装済、SemVer 専用 | Week 4-5 で `ResearchSpec` Lattice (GA-S15) に拡張（本項目は存置、拡張版が別タスク） |
| ⏳ Week 4-5 | `SemVer` への Hoare-style 4-arg post | 未適用 | Week 4-5 で `ResearchSpec` で適用 (GA-S11, TyDD-B4) |
| ⏳ Week 4-5 | `SemVer` の Multiplicity Grading {0,1,ω} | 未適用 | Week 4-5 で検討 (GA-S16, TyDD-F3)、Lean 4 の QTT 非直接対応のため typeclass 模倣が必要 |
| ✅ Day 1 解消 | `import` 文の明示化 (/verify Round 1 指摘 7) | Day 1 で `Init.Data.Nat.Basic` 等 5 件を explicit import | commit `a43eef4`。将来の依存変更への耐性確保 |
| ⏳ Day 5 または Week 3 | Core.lean の `Decidable` 実装を `inferInstanceAs` に統一 | Core.lean L162-168 は `by unfold LE.le instLE` パターンのまま、FolgeID は `inferInstanceAs` で統一済み | Day 1 で確立した Section 10.2 パターン #4 の遡及適用。既存 build は動作するが一貫性のため |

### 2.3 `agent-spec-lib/AgentSpec/Test/CoreTest.lean`

| マーク | 項目 | 現状 | 後続計画 |
|---|---|---|---|
| ✅ Day 2 解消 | Test/本番ライブラリの混在 | Day 2 で `lean_lib AgentSpecTest` 別 target を新設、`AgentSpec.lean` から Test import を全削除、`AgentSpecTest.lean` に集約 | commit `58b75a0`。`lake build AgentSpec` (production-only 7 jobs) と `lake build AgentSpecTest` (test-only 9 jobs) で完全分離 |
| ✅ 実態解消済 | example 8 のコメント不整合 (旧記述) | 実態確認で `(DecidableEq 使用)` + `by decide` 整合。/verify Round 1 指摘 6 で「更新漏れ」として報告済み | 記述を更新し解消（本 Section 12 改訂 2 で反映） |
| ⏳ Week 6-7 | Property-based test (Hypothesis 風) | 未実装、`decide` + 有限量化のみ | Week 6-7 で TyDD Recipe 7 適用 (GA-M4 DRT) |

### 2.4 `agent-spec-lib/artifact-manifest.json`

| マーク | 項目 | 現状 | 後続計画 |
|---|---|---|---|
| ⏳ Week 6-7 | `$schema` URI | 架空の URL | agent-manifesto 本体 schema 整備時に実在する URL に差し替え |
| ⏳ Week 4 | JSON スキーマの Lean 型化 (TyDD-J5 Self-hosting preview) | 未実装 — 第 3 回 TyDD 合致度レビューで "微調整候補 (ζ)" として識別 | Week 4 で J5 Self-hosting の一部として Lean `structure ArtifactManifestEntry` 定義。Week 1 内で skeleton 追加も可能だが、JSON ↔ Lean の双方向同期が必要で scope 超過と判断 |
| ⏳ Week 4 | assumption refs layer | `assumptions: []` 空 | Week 4 で assumption 生成時に充填 (GA-I1 の拡張) |
| ⏳ Week 6-7 | agent-manifesto 本体 schema との divergence (/verify Round 1 指摘 8) | 新基盤は `propositions_referenced` キー、本体は `propositions` キー。共通 validator/parser が不可 | Week 6-7 の CI 整備時に statement schema を共通化、または新基盤独自 schema を公式 subschema として明示 |

### 2.5 `README.md`

| 項目 | 現状 | 後続計画 |
|---|---|---|
| G5-1 Week 1 完了基準の「縮小定義」 | README で「Cslib 依存は Week 6 延期」と明示 | Week 6 で Cslib 依存追加時に元の基準に戻る |
| TyDD-H7 3-level verify (L1/L2) | 宣言的に記載のみ | Week 6 で L2 (Z3 SMT)、Week 7 で L1 (pytest) 実装 |

### 2.6 実装スタイル（第 3 回 TyDD レビューで識別）

| マーク | 項目 | 現状 | 後続計画 |
|---|---|---|---|
| 🔄 **Week 2 着手** | **Top-down / hole-driven development** (TyDD-S1 benefit #7) | bottom-up で `Core.lean` を一括記述 | Week 2 Day 1 以降の型定義で `_` placeholder + `#check` ベースの hole-driven スタイルを実施。実装ガイド Section 10 に具体手順記載 |

### 2.7 /verify Round 1 新規指摘（2026-04-17 追加）

/verify Round 1 (logprob pairwise + Subagent multi-evaluator) で検出された指摘は 8 件（addressable 2 件 + informational 6 件）。addressable 2 件は commit `c8f39e1` で即時修正済。informational 6 件の内訳と対応先は以下:

| マーク | /verify 指摘 # | 項目 | Section 吸収先 | 後続計画 |
|---|---|---|---|---|
| ✅ 修正済 | 指摘 1 (addressable) | README example 数 22 → 24 (3 箇所) | Section 2.7 | commit `c8f39e1` で全 3 箇所更新済 |
| ✅ 修正済 | 指摘 2 (addressable) | artifact-manifest codec 方向「render ∘ parse」→「parse ∘ render」 | Section 2.7 | commit `c8f39e1` で修正済 |
| ⏳ Week 6-7 | 指摘 3 (informational) | `$schema` URL 非解決可能 | Section 7（Round 3 指摘 5 と重複） | Week 6-7 の schema 整備時に同期 |
| 🔄 Week 2 | 指摘 4 (informational) | テスト/本番混在 (`lean_lib AgentSpecTest` 未分離) | Section 2.3（Round 3 指摘 3 と重複） | Week 2 Day 2 で分離 |
| ⏳ 後続 | 指摘 5 (informational) | README TyDD 表 (13 行) と Section 12.2 の分類軸乖離 | Section 2.7 | Week 2 以降のドキュメント整理時に統一 |
| ✅ 本改訂 2 で解消 | 指摘 6 (informational) | Section 2.3 example 8 の旧状態記述 | Section 2.3 | 改訂 2 で「✅ 実態解消済」マークに更新 |
| 🔄 Week 2 | 指摘 7 (informational) | Core.lean に明示的 `import` 文追加 | Section 2.2, 2.7 | Week 2 実装時に対処 |
| ⏳ Week 6-7 | 指摘 8 (informational) | artifact-manifest schema divergence (本体 vs 新基盤) | Section 2.4 | Week 6-7 で common schema 整備 |

**吸収先の凡例**: Section 2.7 に独立項目として新規記載されたのは指摘 1, 2, 5, 7 の 4 件（本テーブル以外に Section 2.3, 2.4 および Section 7 に吸収された指摘は重複記載を避けるため該当 Section に配置）。

### 2.8 `agent-spec-lib/AgentSpec/Spine/Edge.lean` Refinement upgrade (Day 2 TyDD 評価から導出)

Day 2 TyDD 評価 (Section 12.6) で識別された S4 P2 (Refinement Types) と F8 (FiberedTypeSpec) の未活用を Week 4-5 で対処。

| マーク | 項目 | 現状 (Day 2) | 後続計画 |
|---|---|---|---|
| 🔴 Week 4-5 | **S4 P2 Refinement: no-self-loop を型レベルで強制** | `Edge.isSelfLoop : Edge → Bool` で実行時判定、不正値 (src = dst) の構築は許容 | `inductive ResearchEdge : (src dst : ResearchNode) (h : src ≠ dst) → EdgeKind → Type` で構築段階で型チェッカが排除 |
| 🟡 Week 4-5 | **F8 FiberedTypeSpec: EdgeKind を fiber 化** | `structure Edge { src dst : FolgeID, kind : EdgeKind }` で kind は plain field | `inductive ResearchEdge : (k : EdgeKind) → ResearchNode → ResearchNode → Type` で kind ごと不変条件を constructor で強制（例: `wasReplacedBy` は `src` が retired 状態であることを require） |
| 🟢 Week 6 以降 | **Recipe 11 BiTrSpec: Edge ↔ PROV-JSON codec** | codec なし | `def Edge.toProvJson : Edge → Json` + `def Edge.fromProvJson : Json → Option Edge` + round-trip 定理 |
| 🟢 Week 6-7 | **PROV-strict mode と research-mode の語彙分離** | 6 variant が混在 (PROV: wasDerivedFrom/wasReplacedBy、research: refines/refutes/blocks/relates) | `inductive ProvEdgeKind` と `inductive ResearchEdgeKind` を分離、`Edge` は両方の sum type |

**根拠**: Section 12.6 Day 2 TyDD 評価結果テーブル。S4 P2 が「最大改善余地」、F8 が中優先候補。

### 2.9 `agent-spec-lib/AgentSpec/Spine/{EvolutionStep,SafetyConstraint}.lean` 改善余地 (Day 3 TyDD 評価から導出)

Day 3 TyDD 評価 (Section 12.8) で識別された改善余地を Day 4 着手前または Week 4-5 で対処。

| マーク | 項目 | 現状 (Day 3) | 後続計画 |
|---|---|---|---|
| 🔴 **Day 4 着手前** | **SafetyConstraint Bool→Prop refactor の前倒し** | `class SafetyConstraint S where safe : S → Bool`、Week 4-5 で Prop refactor 計画 | 代案: 最初から `class SafetyConstraint S where safe : S → Prop; safeDec : DecidablePred safe` で開始すれば全 instance 書換不要。S1 benefit #9 (less scary refactoring) を強化 |
| 🟡 Day 4 | **EvolutionStep に `Decidable transition` instance 追加** | `transition : S → S → Prop` だけ、Decidable なし | LearningCycle 統合時に `decide` で test するため必要。Day 4 LearningCycle 設計時に追加 |
| 🟡 Day 4 | **SafeState smart constructor `SafeState.mk`** | `⟨s, proof⟩` で構築可能だが、Prop 形式 refactor 後に proof 構築が冗長化 | `def SafeState.mk (s : S) (h : safe s = true) : SafeState S := ⟨s, h⟩` の事前定義 |
| 🟡 Day 4 | **cross-class interaction test** (Day 3 /verify R1 A2) | EvolutionStep + SafetyConstraint 両方を要求するテストなし | Day 4 LearningCycle で `[EvolutionStep S] [SafetyConstraint S]` の同時要求 example 追加 |
| 🟢 Day 4 検討 | **Hypothesis/Verdict/Observable opaque 先行宣言** | EvolutionStep の future member が type 未定義のため計画コメントのみ | `opaque Hypothesis : Type` 等の placeholder 型を Day 4 段階で先行宣言、hole-driven 完全化 |

**根拠**: Section 12.8 Day 3 TyDD 評価結果テーブル。SafetyConstraint Bool→Prop refactor の前倒しは S1 benefit #9 への影響が最大。

### 2.10 Spine 層 paper-grounded 改善提案 (Day 4 論文サーベイ評価から導出)

Day 4 論文サーベイ評価 (Section 12.10) で識別された未活用 paper findings の対処計画。

| マーク | 項目 | 根拠 paper | 対処タイミング |
|---|---|---|---|
| 🟡 Day 5 検討 | **LearningStage.le の Prop 形式併設** (`LE LearningStage` instance + Bool 関数の両立、FolgeID パターン踏襲) | S4 (refinement vs abstract) | Day 5 |
| 🟡 Week 4-5 | **Recipe 10 (Opaque TypeSpec)** — `SafetyConstraint.safe` を opaque にして proof search 制御 | N4 (Opaque Definitions) | Week 4-5 |
| 🟡 Week 4-5 | **PROV-O 三項統合** — LearningCycle.currentStage transition を `WasGeneratedBy` として表現 | 02-data-provenance §4.1 | Week 4-5 (Process 層) |
| 🟡 Week 4-5 | **S6 Paper 1 BST/AVL invariants** — LearningStage 順序関係を invariant 付き structure 化 | S6 Paper 1 | Week 4-5 |
| 🔴 **Week 6 前倒し** | **VBS tactic chain / Lean-Auto 統合** — Day 5 で必要性顕在化 (bounded 8³ で `decide` heartbeat 頭打ち、10³ timeout)、universal round-trip proof と bounded 拡張のために | S2 Recipe 4-6 | **Week 6 (Section 12.13 で格上げ)** |
| 🟢 Week 6-7 | **S7 Schedule combinators** — `LearningStage.next` の retry/budget 合成 | S7 Effect-TS | Week 6-7 |
| 🟢 Week 6-7 | **Cedar DRT pattern** — LearningStage 5×5 = 25 transition の組合せ DRT | G1 Cedar VGD | Week 6-7 (GA-M4) |
| 🟢 将来研究 | **S5 QTT Multiplicity** — stage progression を linear で (Lean 4 不可) | S5 Idris 2 | Lean 4 QTT 対応待ち |
| 🟢 将来研究 | **N2 Conatural Numbers** — retirement 後の永続退役を coinductive で | N2 ELTE | Lean 4 cubical 対応待ち |
| 🟢 Week 7-8 | **S3 Lean4Lean TrSpec correspondence** — reference semantics 対応保証 | S3 | Week 7-8 |
| 🟡 Week 5-6 | **02-data-provenance §4.6 Nextflow resume + Galaxy job cache** — `WasReusedBy` edge による cache hit を lineage に明示記録 (incremental rerun 判定基盤) | 02-data-provenance §4.6 | Week 5-6 Tooling 層 (Day 7 paper サーベイ評価で識別) |
| 🟢 Week 6-7 | **02-data-provenance §4.2 二層分離** (Lean tree + content-addressed manifest) — Process 層 entity の SHA-256 hash アドレス化 | 02-data-provenance §4.2 | Week 6-7 CI 整備時 (Day 7 paper サーベイ評価で識別) |
| 🟢 Day 8+ | **Spine + Process 層 cross-layer integration test** — 別 file (Q4 案 A 確定) | 内部規範踏襲 (Day 4 fullSpineExample → Day 7 fullProcessExample の layer 横断 transfer) | Day 8+ (Day 7 paper サーベイ評価で識別) |
| 🟢 Week 6 | **G3 CSLib spine bisimulation** — Spine 層 type class と CSLib LTS の bisimilarity 確立 | G3 CSLib | Week 6 CSLib 移行時 (Day 7 paper サーベイ評価で識別) |
| 🟡 Week 4-5 | **G5-1 §3.4 ステップ 2 LearningM indexed monad** — Day 4 LearningCycle + Day 8 Verdict + Hypothesis を組合わせて indexed monad 化 | G5-1 §3.4 step 2 | Week 4-5 Tooling 層 (Day 8 paper サーベイ評価で識別) |
| 🟡 Week 4-5 | **EvolutionStep に hypothesis / observation accessor 追加** — G5-1 §3.4 step 1 完全 4 member | G5-1 §3.4 step 1 完全形 | Week 4-5 (Day 8 paper サーベイ評価で識別) |
| 🟢 Day 9+ | **Verdict payload 拡充** — `refuted (evidence : Evidence)` 等 (Failure と同パターン)、Q3 案 A から案 C への移行 | Day 8 D1 案 A→C 移行検討 | Day 9+ Provenance 層 (Day 8 paper サーベイ評価で識別) |
| 🟢 Day 9+ | **transitionLegacy deprecated 削除** — Day 8 で derive、Day 9+ で利用箇所を新 4-arg signature に移行後削除 | Day 8 D2 derive 設計 | Day 9+ (Day 8 paper サーベイ評価で識別) |
| ✅ **Day 10 完了** | ~~EvolutionStep transition → ResearchActivity.verify mapping~~ — Day 10 で `EvolutionMapping.transitionToActivity` (Q4 案 A free function) として実装完了 | G5-1 §3.4 step 2 / 02-data-provenance §4.1 | Day 10 commit `b652347` で対処 |
| 🟡 Day 11+ | **PROV-O wasAttributedTo / wasGeneratedBy / wasDerivedFrom relation の Lean 化** — PROV-O 関係 (Entity ↔ Activity ↔ Agent) を inductive で表現 | 02-data-provenance §4.1 | Day 11+ (Day 10 paper サーベイ評価で識別) |
| 🟢 Day 10+ | **ResearchActivity payload なし variants の payload 拡充** (investigate / decompose / refine / retire) — verify variant と同パターン | 02-data-provenance §4.1 | Day 10+ (Day 9 paper サーベイ評価で識別) |
| 🟢 Day 10+ 設計判断 | **HandoffChain 全体 embed 用 constructor** — `ResearchEntity.HandoffChain` 追加検討 (Subagent I3 Day 9) | Subagent I3 Day 9 | Day 10+ (Day 9 paper サーベイ評価で識別) |
| 🟡 Day 8+ | **02-data-provenance §4.4 退役の構造的検出** — `RetiredEntity` structure + Lean compiler による退役済 entity 参照の warning/error 検出 (custom linter または elaborator) | 02-data-provenance §4.4 | Day 8+ Provenance 層 (Day 6 paper サーベイ評価で識別) |
| 🟡 Week 6-7 | **02-data-provenance §4.7 RO-Crate 互換 export** — Lean tree → JSON-LD schema-preserving 変換 (Lean meta-program)、外部 tool (WorkflowHub, Galaxy) との interop 確保 | 02-data-provenance §4.7 | Week 6-7 (CI 整備時) (Day 6 paper サーベイ評価で識別) |
| 🟢 Week 5-6 | **02-data-provenance §4.5 Pipeline 段階表現** — DSL ≤ AST ≤ LeanSpec ≤ SMTSpec ≤ Tests ≤ Code を Spec 精緻化として Lean で表現 (Snakemake rule 対応) | 02-data-provenance §4.5 | Week 5-6 Tooling 層 (Day 6 paper サーベイ評価で識別) |
| 🟢 Day 7+ | **S6 Paper 1 (BST/AVL invariants)** — Hypothesis chain の order を invariant 付き structure 化 (Evolution と統合時) | S6 TyDe 2025 Paper 1 | Day 7+ (Evolution と統合) (Day 6 paper サーベイ評価で識別、Section 2.10 既存項目から Day 7+ に具体化) |

**根拠**: Section 12.10 Day 4 論文サーベイ評価結果テーブル。8 件の未活用 finding の優先度別対処計画。

### 2.11 Process 層 Day 6+ 着手計画 (Day 5 評価 → Day 6 議論で確定)

Day 5 完結性整備後の Day 6 着手前判断議論で以下に確定。

#### Day 6 設計判断 (確定済)

| 判断ポイント | 採用案 | 理由 |
|---|---|---|
| **Q1 Day 6 全体方針** | **Option C: Process 層着手** (Manifest 移植 / Spine 拡充 / Lean-Auto research を退ける) | Spine 完備 → Process が natural / EvolutionStep B4 解決 / Day 1-5 リズム維持 / paper finding 活用 |
| **Q2 Process 層 scope** | **Minimal**: Day 6 で Hypothesis + Failure (2 inductive) のみ完備 (Medium = +Evolution signature は不採用) | Evolution は Hypothesis/Failure 依存、Day 7 で同時設計の方が一貫性確保 / Day 1-5 の "2 type per Day" 安定リズム維持 |
| **Q3 PROV-O 統合 timing** | **Option C: Vocabulary alignment in docstring only** (Day 8+ で実装) | Day 6 scope 制御 + paper finding (02-data-provenance §4.1) の docstring 顕在化で coordination cost 最小化 / TyDD-S1 (types first 強型) 遵守 |

#### Day 6 想定 deliverables

| ファイル | 内容 |
|---|---|
| `AgentSpec/Process/Hypothesis.lean` | `inductive Hypothesis` (claim 表現、refines/refutes/blocks 関係) + Unit dummy instance + docstring に PROV mapping (`Hypothesis ↦ ResearchEntity.Hypothesis`) 注記 |
| `AgentSpec/Process/Failure.lean` | `inductive Failure` + `inductive FailureReason` (4 variant: HypothesisRefuted / ImplementationBlocked / SpecInconsistent / Retired、02-data-provenance §4.3 参照) + docstring に PROV mapping 注記 |
| `AgentSpec/Test/Process/HypothesisTest.lean` | 6-8 example (constructor / DecidableEq / refines 関係) |
| `AgentSpec/Test/Process/FailureTest.lean` | 6-8 example (constructor / FailureReason variant / Failure → FailureReason 抽出) |
| `agent-spec-lib/artifact-manifest.json` | 4 新規 entries (Pattern #7 hook 強制で同 commit) |

#### Day 7 着手前判断結果 (確定済、Day 6 完了後の議論結果)

| 判断ポイント | 採用案 | 理由 |
|---|---|---|
| **Q1 Day 7 全体 scope** | **Minimal** (Day 7 plan 通り、Evolution + HandoffChain 2 type + cross-process test) | Day 1-6 リズム維持 (2 type per Day)、scope 制御 |
| **Q2 cross-process test scope** | **案 A**: 1-2 件 fullSpineExample-like example (Hypothesis × Failure × Evolution × HandoffChain) | scope 制御、Day 8+ で拡張可能 |
| **Q3 EvolutionStep B4 4-arg post 統合 timing** | **案 B**: Day 7 では Evolution signature のみ、B4 完全統合は Day 8+ (Verdict 型確定後) | Verdict 型は Process/ 配下で新規定義必要。Day 7 で Verdict 追加すると 3 type で scope 超過。Verdict は Provenance 層実装と関連 |
| **Q4 cross-class composition test の置き場所** | **案 A**: 別 test ファイル (新規 EvolutionTest = Process 統合、既存 LearningCycleTest = Spine 統合) | Day 1-6 構造踏襲、Spine と Process の責務分離 |

#### Day 7 想定 (確定版、Q1-Q4 採用案反映)

| ファイル | 内容 |
|---|---|
| `AgentSpec/Process/Evolution.lean` | `inductive Evolution` (Hypothesis 依存、step transition signature)。**EvolutionStep B4 4-arg post 統合 signature 宣言のみ**、完全統合は Day 8+ (Q3 案 B)。Hypothesis chain order を **S6 Paper 1 BST/AVL invariants** で型レベル強制は **Day 7 では未着手**、Section 2.10 で Day 8+ Evolution 拡張時に検討 |
| `AgentSpec/Process/HandoffChain.lean` | `inductive HandoffChain` (T1 一時性、handoff sequence 表現) |
| `AgentSpec/Test/Process/EvolutionTest.lean` | Evolution 単独 test + **cross-process test 1-2 件** (Hypothesis × Failure × Evolution × HandoffChain、Day 4 fullSpineExample パターン踏襲、Q2 案 A、Section 2.12 🟡 解消) |
| `AgentSpec/Test/Process/HandoffChainTest.lean` | HandoffChain 単独 test + LearningCycle/Observable 統合は **Day 8+ で別 test file** (Q4 案 A、Spine と Process の責務分離) |
| `agent-spec-lib/artifact-manifest.json` | 4 新規 entries (Pattern #7 hook 強制、Day 6 同パターン) |

#### Day 7 で意識する改善事項 (Day 6 評価から導出、Section 2.12 / 2.10 連携)

| 優先度 | 項目 | Day 7 反映 |
|---|---|---|
| 🟡 中 | **cross-process interaction test** (Hypothesis × Failure × Evolution × HandoffChain) | EvolutionTest で Q2 案 A (1-2 件、Section 2.12 🟡 解消) |
| 🟡 中 | **EvolutionStep B4 4-arg post の I/O type 確定** | **Day 7 では signature 宣言のみ、完全統合は Day 8+ (Q3 案 B、Verdict 型確定後)、Section 2.9 部分解消** |
| 🟡 中 | **HandoffChain の T1 一時性 inductive 表現** | HandoffChain.lean (Section 2.11 Day 7 確定) |
| 🟢 低 | **S6 Paper 1 BST/AVL invariants** | **Day 7 では未着手、Day 8+ Evolution 拡張時に検討 (Q1 Minimal で scope 制御)** |

#### Day 8+ 想定 (Day 6-7 評価 Section 12.16 / 12.20 / 2.10 / 2.13 改善反映)

| ファイル | 内容 |
|---|---|
| `AgentSpec/Provenance/ResearchEntity.lean` | `inductive ResearchEntity` (02-data-provenance §4.1) |
| `AgentSpec/Provenance/ResearchActivity.lean` | `inductive ResearchActivity` |
| `AgentSpec/Provenance/ResearchAgent.lean` | `structure ResearchAgent` |
| `AgentSpec/Provenance/Verdict.lean` (**Day 7 Q3 案 B からの delegation**) | `inductive Verdict` (proven / refuted / inconclusive 等)、Day 8+ で新規定義し EvolutionStep B4 4-arg post 完全統合の前提に |
| `AgentSpec/Provenance/Mapping.lean` | `Hypothesis.toEntity` / `Failure.toEntity` / `Evolution.toActivity` / `Handoff.toAgent` 等 mapping 関数。**Hypothesis rationale Refinement 強化** (Option String → Option Evidence、Section 2.12 🟡 解消) と **Failure payload 型化** (各 variant payload を専用型に、Section 2.12 🟡 解消) を同時実施 |
| `AgentSpec/Provenance/RetiredEntity.lean` | **02-data-provenance §4.4 退役の構造的検出** (Section 2.10 🟡 paper-grounded、RetiredEntity structure + Lean linter または elaborator) |
| `AgentSpec/Spine/EvolutionStep.lean` (**Day 7 評価 Section 2.13 から**) | **B4 4-arg post 完全統合**: `transition : (pre : S) → (input : Hypothesis) → (output : Verdict) → (post : S) → Prop` に refactor (Section 2.9 完全解消) |
| `AgentSpec/Process/Evolution.lean` (**Day 7 評価 Section 2.13 から**) | **S6 Paper 1 BST/AVL invariants** 適用: Evolution chain order を invariant 付き structure 化、`refineWith` constructor に proof 引数追加 |
| `AgentSpec/Test/Cross/SpineProcessTest.lean` (**Day 7 paper サーベイ Section 12.19 から、Q4 案 A 別 file**) | Spine + Process layer cross-layer integration test (`fullSpineExample` × `fullProcessExample` の同時利用) |
| **代替**: Manifest 移植 (Week 3-4) または Lean-Auto research/PoC (Section 2.10 🔴) を並行開始 | |

**根拠**: Day 5 評価 Section 12.13 paper finding (02-data-provenance §4.1 PROV-O) + Section 12.14 TyDD 評価 (paper × pattern 合流) + Section 6.2.1 Pattern #7 hook 効力範囲 (Process 配下も対象) を統合。

### 2.12 Process 層 Day 6 評価から導出した改善余地

Day 6 TyDD 評価 (Section 12.17) で識別された改善余地を Day 7+ で対処。

| マーク | 項目 | 現状 (Day 6) | 後続計画 |
|---|---|---|---|
| 🟡 Day 7 | **Process 層 cross-process test** — Hypothesis × Failure × Evolution の relation test | Day 6 で Hypothesis + Failure 独立 test (12 + 17 examples) のみ、cross-process 関係は未検証 | Day 7 Evolution 実装と同時に 1-2 cross-process example 追加 (Day 4 fullSpineExample パターン踏襲) |
| 🟡 Day 8+ | **Hypothesis rationale Refinement 強化** | `rationale : Option String` (弱 refinement) | Day 8+ Provenance 層で `rationale : Option Evidence` 型化 (S4 P2 強化) |
| 🟡 Day 8+ | **Failure payload 型化** | 各 variant payload は Day 6 hole-driven String | Day 8+ Provenance 層で各専用型に refactor: `Evidence` (HypothesisRefuted) / `Spec` (ImplementationBlocked) / `InconsistencyProof` (SpecInconsistent) / `ResearchEntity` (Retired) |
| 🟢 metadata 整備時 | **artifact-manifest AgentSpecTest entry に example_count 等フィールド追加** (Subagent I2) | 他 test entries には example_count あるが AgentSpecTest root には不在、集計の網羅性で Day 5 以前と非対称 | Day 7 metadata commit で追加 |

**根拠**: Section 12.17 Day 6 TyDD 評価結果テーブル。Process 層 hole-driven 設計の Day 7 / Day 8+ refactor 計画を集約。

### 2.13 Process 層 Day 7 評価から導出した改善余地

Day 7 TyDD 評価 (Section 12.20) で識別された改善余地を Day 8+ で対処。

| マーク | 項目 | 現状 (Day 7) | 後続計画 |
|---|---|---|---|
| 🟡 Day 8+ | **Verdict 型 + EvolutionStep B4 4-arg post 完全統合** (Section 2.9 完全解消) | Day 7 で signature 宣言なし (Q3 案 B 確定方針)、Verdict 型は未定義 | Day 8+ Provenance 層と同時実装、Verdict 型を Process/ または Provenance/ 配下で新規定義し、`(pre : S) → (input : Hypothesis) → (output : Verdict) → (post : S) → Prop` で Hoare 4-arg post 完全形 |
| 🟡 Day 8+ | **S6 Paper 1 BST/AVL invariants 適用** — Evolution chain order 強型化 | Day 7 では Evolution は inductive 2 constructor のみ、chain order は recursive accessor (`stepCount`) で抽出 | Day 8+ Evolution 拡張時に `inductive Evolution { initial, refineWith (h : prev.stepCount < n + 1 → ...) }` 等で order を type-level で強制 |
| 🟢 Day 8+ 検討 | **Evolution DecidableEq 手動実装** — recursive inductive で `deriving DecidableEq` 不可、Hypothesis DecidableEq + recursive equation で手動実装可能 | Day 7 では Inhabited / Repr のみ deriving、DecidableEq 省略 | Day 8+ で必要時に手動実装 (テストで decide による比較が必要になる場面で) |
| 🟢 Day 8+ 検討 | **HandoffChain `concat` 操作** — chain 同士の連結 (現状の `append` は handoff 単独追加のみ) | `append : HandoffChain → Handoff → HandoffChain` のみ | Day 8+ で `concat : HandoffChain → HandoffChain → HandoffChain` を List.append 風に追加検討 |

**根拠**: Section 12.20 Day 7 TyDD 評価結果テーブル。Q3 案 B (Day 7 では Day 8+ 委譲) で意図的に Day 7 から外した項目を明示。

### 2.15 Day 8 評価から導出した改善余地 (Day 9+ 対処)

Day 8 TyDD 評価 (Section 12.23) で識別された改善余地を Day 9+ で対処。

| マーク | 項目 | 現状 (Day 8) | 後続計画 |
|---|---|---|---|
| 🟡 Day 9+ | **Provenance 層継続** — ResearchEntity / ResearchActivity / ResearchAgent + Mapping 関数 | Day 8 で Verdict のみ先行配置 (新 namespace AgentSpec.Provenance) | Day 9+ で 02-data-provenance §4.1 完全実装、Hypothesis/Failure/Evolution/Handoff の mapping 関数 (Q3 Option C で延期した PROV mapping を完成) |
| 🟡 Day 9+ | **Verdict payload 拡充** — `refuted (evidence : Evidence)` 等 (Failure と同パターン)、Day 8 D1 案 A→案 C 移行 | Verdict 3 variant minimal (payload なし) | Day 9+ Provenance 層実装時に検討 (Evidence 型新規定義と同時) |
| 🟢 Day 9+ | **transitionLegacy deprecated 削除** | Day 8 で derive (∃ h v, transition pre h v post) として残置、後方互換性確保 | Day 9+ で利用箇所 (TransitionReflexive/Transitive) を新 4-arg signature に移行後、deprecated 削除 |
| 🟢 Week 4-5 | **EvolutionStep 完全 4 member 化** — G5-1 §3.4 step 1 完全形 (hypothesis/observation accessor 追加) | Day 8 で transition (4-arg post) のみ | Week 4-5 で `hypothesis : S → Option Hypothesis` / `observation : S → Observable` accessor 追加 (G5-1 §3.4 step 1 完全形) |
| 🟢 Week 4-5 | **G5-1 §3.4 step 2 LearningM indexed monad** | Day 4 LearningCycle + Day 8 Verdict + Hypothesis を組合わせる前段階 | Week 4-5 Tooling 層で indexed monad `LearningM (s : LearningStage) (α : Type u) := ...` 実装 |

**根拠**: Section 12.23 Day 8 TyDD 評価結果テーブル。S4 P5 + B4 新規強適用後の次の改善余地を集約。

### 2.17 Day 9 評価から導出した改善余地 (Day 10+ 対処)

Day 9 TyDD 評価 (Section 12.26) で識別された改善余地を Day 10+ で対処。

| マーク | 項目 | 現状 (Day 9) | 後続計画 |
|---|---|---|---|
| 🟡 Day 10 | **ResearchAgent (Provenance 層 4 type 目)** | Day 8 Verdict + Day 9 ResearchEntity + ResearchActivity = 3 type、ResearchAgent 未実装 | Day 10 メイン候補、02-data-provenance §4.1 PROV-O 三項目最後の type |
| 🟡 Day 10+ | **EvolutionStep transition → ResearchActivity.verify mapping** | Day 8 EvolutionStep B4 4-arg post と Day 9 ResearchActivity.verify (input : Hypothesis, output : Verdict) は signature 整合のみ、実際の mapping 関数なし | Day 10+ で `def EvolutionStep.transitionToActivity ... : ResearchActivity` 等の mapping 実装 |
| 🟢 Day 10+ | **ResearchEntity DecidableEq 手動実装** | Day 9 では Inhabited / Repr のみ deriving、DecidableEq は Evolution recursive のため省略 | Day 10+ で手動実装検討 (全 4 constructor の DecidableEq) |
| 🟢 Day 10+ | **ResearchActivity payload なし variants の payload 拡充** | investigate / decompose / refine / retire は payload なし | Day 10+ で 02-data-provenance §4.1 詳細化に基づき payload 設計 |
| 🟢 Day 10+ 設計判断 | **HandoffChain 全体 embed 用 constructor** | ResearchEntity.Handoff は Handoff 単体、HandoffChain 全体は embed 不可 | Day 10+ で `ResearchEntity.HandoffChain` 追加 vs `Handoff` 単体維持を設計判断 |

**根拠**: Section 12.26 Day 9 TyDD 評価結果テーブル。S4 4/5 + 5 強適用維持後の次の改善余地を集約。Day 9 TyDD 評価では追加実装修正なし (全て Day 10+ で対処、S4 P4 + Q1 Minimal scope 遵守)。

### 2.19 Day 10 評価から導出した改善余地 (Day 11+ 対処)

Day 10 TyDD 評価 (Section 12.29) で識別された改善余地を Day 11+ で対処。

| マーク | 項目 | 現状 (Day 10) | 後続計画 |
|---|---|---|---|
| 🟡 Day 11+ | **PROV-O wasAttributedTo / wasGeneratedBy / wasDerivedFrom relation の Lean 化** | Day 10 で ResearchEntity / Activity / Agent (3 nodes) は完備、relation (edges) は未定義 | Day 11+ で 02-data-provenance §4.1 PROV-O relation を inductive で実装 |
| 🟡 Day 11+ | **02-data-provenance §4.4 RetiredEntity** (退役 entity の構造的検出、Lean linter / elaborator) | 未着手 | Day 11+ Provenance 層完成時 |
| 🟢 Day 11+ | **ResearchEntity DecidableEq 手動実装** | Day 9-10 で省略 (Evolution recursive 制約) | Day 11+ で必要時に手動実装 |
| 🟢 Day 11+ | **ResearchActivity payload なし variants の payload 拡充** (investigate / decompose / refine / retire) | Day 9-10 で payload なし維持 | Day 11+ で payload 設計 (verify variant と同パターン) |
| 🟢 Day 11+ | **transitionLegacy deprecated 削除** | Day 8 で derive、後方互換性のため残置 | Day 11+ で利用箇所 (TransitionReflexive/Transitive) を新 4-arg signature に移行後削除 |
| 🟢 Week 4-5 | **EvolutionStep 完全 4 member 化** (G5-1 §3.4 step 1 完全形) | Day 8 で transition 4-arg post 統合のみ、hypothesis/observation accessor 未追加 | Week 4-5 で `hypothesis : S → Option Hypothesis` + `observation : S → Observable` 追加 |
| 🟢 Week 4-5 | **G5-1 §3.4 step 2 LearningM indexed monad** | Day 10 で transitionToActivity 連携 path 確立、indexed monad 本体は未実装 | Week 4-5 Tooling 層で `LearningM (s : LearningStage) (α : Type u)` 実装 (連携 path 完備で本格実装可能) |

**根拠**: Section 12.29 Day 10 TyDD 評価結果テーブル。Day 10 PROV-O 4 type 完備 + Pattern #7 hook v2 拡張後の次の改善余地を集約。Day 10 TyDD 評価では追加実装修正なし (Day 9 同パターン継続、全て Day 11+ で対処)。

### 2.20 Day 11 着手前判断結果 (確定済、Day 10 完了後の議論結果)

#### Day 11 全体方針 (Q1-Q4 採用案、確定済)

| 判断ポイント | 採用案 | 理由 |
|---|---|---|
| **Q1 Day 11 main scope** | **A 案: PROV-O relation 3 inductive** (wasAttributedTo / wasGeneratedBy / wasDerivedFrom) | Day 1-10 リズム維持、Day 10 4 type 完備の自然な続き、PROV-O 完全実装に向けた重要 step。B 案 (RetiredEntity + linter) は新分野、C 案 (payload 拡充) は refactor 中心、D/E は Day rhythm と異なる |
| **Q2 A 案 sub-scope** | **A-Minimal**: 3 structure/inductive + Test 2-3 ファイル | 2-3 type per Day rhythm、Maximal (RetiredEntity 同時) は別 Day |
| **Q3 relation design** | **案 A**: 3 separate structure (`WasAttributedTo` / `WasGeneratedBy` / `WasDerivedFrom`)、PROV-O 1:1 対応 | 02-data-provenance §4.1 PROV-O 100% 忠実、TyDD-S1、各 relation の semantic 区別が明確。案 B (1 unified inductive) は variant 増加、案 C (RelationKind enum) は型安全性低下 |
| **Q4 relation の引数 type** | **案 A**: 02-data-provenance §4.1 通り厳格 type | TyDD-S1 + S4 P5 explicit assumptions、wasAttributedTo : Entity × Agent / wasGeneratedBy : Entity × Activity / wasDerivedFrom : Entity × Entity |

#### Day 11 想定 deliverables (確定版、Q1-Q4 反映)

| ファイル | 内容 |
|---|---|
| `AgentSpec/Provenance/ProvRelation.lean` (NEW、3 structure 統合配置) | `structure WasAttributedTo { entity : ResearchEntity, agent : ResearchAgent }` + `structure WasGeneratedBy { entity : ResearchEntity, activity : ResearchActivity }` + `structure WasDerivedFrom { entity : ResearchEntity, source : ResearchEntity }` + smart constructors + trivial fixtures + Inhabited / Repr deriving (DecidableEq は ResearchEntity recursive 制約で省略) |
| `AgentSpec/Test/Provenance/ProvRelationTest.lean` (NEW) | 3 relation 構築 + accessor + smart constructor + fixture + Inhabited (推定 18-25 example) |
| `agent-spec-lib/artifact-manifest.json` | 2 新規 entries (ProvRelation + Test) + verifier_history Day 11 R1 entry (Pattern #7 hook v2 強制で同 commit) |
| `agent-spec-lib/AgentSpec.lean` / `AgentSpecTest.lean` | 各 1 import 追加 |

#### 層依存性 (Day 11)

ProvRelation は ResearchEntity + ResearchAgent + ResearchActivity (全て Provenance 層) を import。Day 8-10 で確立した layer architecture 内 (Provenance 層内部) の依存で、新たな層依存性問題なし。

#### Day 11 で意識する改善事項 (Day 10 評価から導出、Section 2.19 連携)

| 優先度 | 項目 | Day 11 反映 |
|---|---|---|
| 🟡 中 | **PROV-O wasAttributedTo / wasGeneratedBy / wasDerivedFrom relation の Lean 化** | **Day 11 メイン成果 (Q1 A 案)** |
| 🟡 中 | **02-data-provenance §4.4 RetiredEntity** | Day 11 では未着手 (Q2 A-Minimal scope 制御、Day 12+) |
| 🟢 低 | **その他 Day 6-10 評価繰り延ばし項目** | Day 11 では未着手 (DecidableEq / payload 拡充 / transitionLegacy 削除 / EvolutionStep 4 member 化 / LearningM) |

#### 主要決定

- Day 11 メイン成果 = **PROV-O relation 3 structure** (wasAttributedTo / wasGeneratedBy / wasDerivedFrom、PROV-O 100% 忠実、TyDD-S1)
- relation design = 3 separate structure (1 ファイル統合配置 ProvRelation.lean、Q3 案 A、引数 type は PROV-O §4.1 通り厳格)
- DecidableEq 省略 (ResearchEntity recursive 制約継承、Day 12+ 検討)
- RetiredEntity / その他 Day 6-10 評価繰り延ばし項目は Day 12+ または Week 4-5 へ

---

### 2.18 Day 10 着手前判断結果 (確定済、Day 9 完了後の議論結果)

#### Day 10 全体方針 (Q1-Q4 採用案、確定済)

| 判断ポイント | 採用案 | 理由 |
|---|---|---|
| **Q1 Day 10 main scope** | **B 案: ResearchAgent + EvolutionStep transition → ResearchActivity.verify mapping** | Day 1-9 リズム維持、Day 8/9 連携 path 確立、Provenance 層完成 (4 type + transition→activity mapping)。A 案 (ResearchAgent のみ) は 1 type で物足りない、C 案 (Manifest 移植) は Day rhythm と異なる、D 案 (Lean-Auto research) は実装段階に入らず |
| **Q2 B 案 sub-scope** | **B-Medium**: ResearchAgent + transition → activity mapping (signature + 実装 + test) | Day 6-7 と同パターン (2 type 相当)、Maximal (RetiredEntity 追加) は scope 超過 |
| **Q3 ResearchAgent design** | **案 A**: `structure ResearchAgent { identity : String, role : Role }` + `inductive Role { Researcher, Reviewer, Verifier }` (02-data-provenance §4.1 PROV-O 通り) | TyDD-S1 types-first、PROV-O 100% 忠実、Role inductive で Day 10+ 拡充容易。案 B (identity のみ) は Role 後付けが冗長、案 C (LLM/Human inductive) は別設計で T1 一時性との連携は Day 11+ で検討 |
| **Q4 transition → activity mapping signature** | **案 A**: `def EvolutionStep.transitionToActivity (h : Hypothesis) (v : Verdict) : ResearchActivity := .verify h v` (free function、input/output のみ) | Q1 Minimal scope 制御、Day 9 ResearchActivity.verify との直接整合、案 B (transition proof 引数) は overspec、Day 11+ で必要時拡張可能 |

#### Day 10 想定 deliverables (確定版、Q1-Q4 反映)

| ファイル | 内容 |
|---|---|
| `AgentSpec/Provenance/ResearchAgent.lean` (NEW、Q3 案 A) | `structure ResearchAgent { identity : String, role : Role }` + `inductive Role { Researcher, Reviewer, Verifier }` (02-data-provenance §4.1 通り) + `toEntity` Mapping (本ファイル内 namespace AgentSpec.Process 配下に配置 — Q4 案 A 同パターン)。**注**: ResearchAgent は Process 層 type ではないため、`toEntity` は ResearchEntity に新 constructor `ResearchEntity.Agent (a : ResearchAgent)` を追加することで対応 (ResearchEntity 5 constructor へ拡張) — または ResearchAgent を ResearchEntity に embed しない別設計 (PROV-O では Entity と Agent は別概念) を採用 |
| `AgentSpec/Provenance/ResearchEntity.lean` (modify) | **Day 10 で 5 constructor 拡張**: `Agent (a : ResearchAgent)` constructor 追加 (PROV-O 三項目の Agent も Entity の一種として embed)、または **ResearchEntity は Process 4 type のまま維持** (PROV-O 区別を保つ) — 設計判断は実装時に Day 10 評価で決定 |
| `AgentSpec/Provenance/EvolutionMapping.lean` (NEW、Q4 案 A) | `def EvolutionStep.transitionToActivity (h : Hypothesis) (v : Verdict) : ResearchActivity := .verify h v` (free function、Day 8 EvolutionStep B4 4-arg post と Day 9 ResearchActivity.verify を結合) |
| `AgentSpec/Test/Provenance/ResearchAgentTest.lean` (NEW) | ResearchAgent 構築 + Role 3 variant + DecidableEq + toEntity (推定 12-16 example) |
| `AgentSpec/Test/Provenance/EvolutionMappingTest.lean` (NEW) | transitionToActivity の Hypothesis/Verdict 全組合わせ + verify variant 整合検証 (推定 6-8 example) |
| `agent-spec-lib/artifact-manifest.json` | 4 新規 entries (Pattern #7 hook 強制で同 commit) + verifier_history Day 10 R1 entry |

#### 層依存性の考察 (Day 10)

EvolutionMapping.lean は EvolutionStep (Spine) + Hypothesis (Process) + Verdict (Provenance) + ResearchActivity (Provenance) を import。これは Day 8/9 の layer architecture (Spine = core abstraction) と整合的、新たな層依存性問題なし。

ResearchAgent → ResearchEntity の embed 判断は Day 10 実装時に決定:
- **embed する場合**: ResearchEntity を 5 constructor に拡張、`Agent.toEntity = .Agent` Mapping を ResearchEntity.lean に追加
- **embed しない場合**: PROV-O では Entity と Agent は別概念、ResearchAgent は独立 structure として維持

#### Day 10 で意識する改善事項 (Day 9 評価から導出、Section 2.17 連携)

| 優先度 | 項目 | Day 10 反映 |
|---|---|---|
| 🟡 中 | **ResearchAgent (Provenance 層 4 type 目)** | **Day 10 メイン成果 (Q1 B 案)** |
| 🟡 中 | **EvolutionStep transition → ResearchActivity.verify mapping** | **Day 10 副成果 (Q1 B 案 / Q4 案 A)、Day 8/9 連携 path 確立** |
| 🟢 低 | **ResearchEntity DecidableEq 手動実装** | Day 10 では未着手 (Q1 Minimal scope 制御、Day 11+) |
| 🟢 低 | **ResearchActivity payload なし variants の payload 拡充** | Day 11+ |
| 🟢 低 | **HandoffChain 全体 embed 用 constructor** | Day 10 ResearchEntity 5 constructor 拡張時に同時検討 |

#### 主要決定

- Day 10 メイン成果 = **ResearchAgent (Provenance 層 4 type 完備)** + **EvolutionStep transition → ResearchActivity.verify mapping** (Q1 B 案、Day 8/9 連携 path 確立)
- ResearchAgent design = `structure { identity, role : Role }` + `inductive Role { Researcher, Reviewer, Verifier }` (02-data-provenance §4.1 PROV-O 100% 忠実)
- transition → activity mapping = free function `transitionToActivity (h : Hypothesis) (v : Verdict) : ResearchActivity := .verify h v` (Q4 案 A 案 B は overspec)
- ResearchEntity 5 constructor 拡張 (Agent embed) は Day 10 実装時に決定 (PROV-O Entity/Agent 区別の方針判断)
- DecidableEq 手動実装 / payload 拡充 / HandoffChain 全体 embed は Day 11+ へ繰り延べ (Q1 Minimal scope 制御)

---

### 2.16 Day 9 着手前判断結果 (確定済、Day 8 完了後の議論結果)

#### Day 9 全体方針 (Q1-Q4 採用案、確定済)

| 判断ポイント | 採用案 | 理由 |
|---|---|---|
| **Q1 Day 9 main scope** | **A 案: Provenance 層継続** (ResearchEntity + ResearchActivity + Mapping) | Day 6-7 リズム維持 (Process 層着手と同パターン)、Day 8 で Verdict 先行配置済の自然な続き、合致率 +4 想定。B 案 (Verdict payload + transitionLegacy 削除) は refactor のみで物足りない、C 案 (Manifest 移植 55 axioms) は Day rhythm と異なる、D 案 (Lean-Auto research) は実装段階に入らず |
| **Q2 A 案 sub-scope** | **A-Minimal**: ResearchEntity + ResearchActivity 2 type + Mapping 関数 | 2 type per Day rhythm 維持 (Day 6-7 と同サイズ)、ResearchAgent は Day 10+ に繰り延げ (3 type + Mapping は scope 超過) |
| **Q3 ResearchEntity design** | **案 A**: `inductive ResearchEntity { Hypothesis (h : Hypothesis), Failure (f : Failure), Evolution (e : Evolution), Handoff (h : Handoff) }` (4 constructor、既存 Process type を embed) | TyDD-S1 types-first 遵守、既存 Process type 再利用、Mapping 関数が natural (`Hypothesis.toEntity = .Hypothesis`)。案 B (opaque variant + lookup) は indirection 増大、案 C (02-data-provenance §4.1 通り 7 variant) は scope 超過 (Day 10+ で拡充検討) |
| **Q4 Mapping 関数 signature** | **案 A**: Process side method (`Hypothesis.toEntity : Hypothesis → ResearchEntity` 等) | Process 層の type ごとに `.toEntity` 提供、Lean 4 の dot notation で利用側 idiomatic (`hyp.toEntity`)。案 B (Provenance side wrapper) は冗長、案 C (両方向) は Day 9 scope 超過 |

#### Day 9 想定 deliverables (確定版、Q1-Q4 反映)

| ファイル | 内容 |
|---|---|
| `AgentSpec/Provenance/ResearchEntity.lean` (NEW) | `inductive ResearchEntity { Hypothesis (h : Hypothesis), Failure (f : Failure), Evolution (e : Evolution), Handoff (h : Handoff) }` (Q3 案 A 4 constructor + 既存 Process type embed) + DecidableEq/Inhabited/Repr deriving (recursive な箇所は手動検討) + accessor / fixture |
| `AgentSpec/Provenance/ResearchActivity.lean` (NEW) | `inductive ResearchActivity { Investigate, Decompose, Refine, Verify (input : Hypothesis) (output : Verdict), Retire }` (02-data-provenance §4.1 5 variant、Verify は B4 4-arg post と整合) + 同上 deriving |
| `AgentSpec/Process/Hypothesis.lean` (modify) | `def Hypothesis.toEntity : Hypothesis → ResearchEntity := .Hypothesis` (Q4 案 A) を追加。**注**: import 順序で Provenance.ResearchEntity を Process.Hypothesis から import する必要あり、層依存性は Day 8 EvolutionStep と同パターン (Q4 案 A D4 受容方針) |
| `AgentSpec/Process/Failure.lean` (modify) | `def Failure.toEntity : Failure → ResearchEntity := .Failure` を追加 |
| `AgentSpec/Process/Evolution.lean` (modify) | `def Evolution.toEntity : Evolution → ResearchEntity := .Evolution` を追加 |
| `AgentSpec/Process/HandoffChain.lean` (modify) | `def Handoff.toEntity : Handoff → ResearchEntity := .Handoff` を追加 (Handoff 単体で entity 化、HandoffChain は List embed しない) |
| `AgentSpec/Test/Provenance/ResearchEntityTest.lean` (NEW) | 4 constructor 構築 + 4 toEntity Mapping (Q4 案 A) + DecidableEq + cross-process embed test (推定 12-16 example) |
| `AgentSpec/Test/Provenance/ResearchActivityTest.lean` (NEW) | 5 variant 構築 + Verify variant の Hypothesis/Verdict 連携 test + DecidableEq (推定 8-12 example) |
| `agent-spec-lib/artifact-manifest.json` | 4 新規 entries (ResearchEntity + ResearchActivity + 2 test) + 4 modify entries (Process .lean に toEntity 追加) (Pattern #7 hook 強制で同 commit) |

#### 層依存性の考察 (Day 9)

Day 9 で **Process → Provenance** import が新たに追加される。これは Day 8 で確立した **Spine → Process / Provenance** import (Q4 案 A D4) の **逆方向** (Process → Provenance) で、循環依存リスクが懸念される:
- Day 8: `EvolutionStep.lean` (Spine) imports `Hypothesis.lean` (Process) + `Verdict.lean` (Provenance)
- Day 9: `Hypothesis.lean` (Process) imports `ResearchEntity.lean` (Provenance)

これらは循環していない (Process → Provenance のみ、Provenance → Process はなし)。確認方針:
- ResearchEntity.lean は Process types を import (`import AgentSpec.Process.{Hypothesis, Failure, Evolution, HandoffChain}`)
- Process types は ResearchEntity を import (`import AgentSpec.Provenance.ResearchEntity`)
- これは循環依存になる ❌

**解決策**: Mapping 関数は ResearchEntity.lean 内に置く (Process side method ではなく Provenance side staticでも `Hypothesis.toEntity` 名前空間を使う):

    -- ResearchEntity.lean 内で:
    def AgentSpec.Process.Hypothesis.toEntity (h : Hypothesis) : ResearchEntity := .Hypothesis h

これにより Process → Provenance import が不要 (ResearchEntity.lean のみが Process を import)。Q4 案 A の意図 (Process 層 type ごとに `.toEntity`) は守られる (dot notation も機能)。

#### Day 9 で意識する改善事項 (Day 8 評価から導出、Section 2.15 連携)

| 優先度 | 項目 | Day 9 反映 |
|---|---|---|
| 🟡 中 | **Provenance 層継続** (ResearchEntity + ResearchActivity + Mapping) | **Day 9 メイン成果 (Q1 A 案、Q2 A-Minimal)** |
| 🟢 低 | **ResearchAgent** | Day 10+ へ繰り延げ (Q2 A-Minimal scope 制御) |
| 🟢 低 | **Verdict payload 拡充** (案 A→C 移行) | Day 9 では未着手 (Q1 A 案優先、Day 10+ で検討) |
| 🟢 低 | **transitionLegacy deprecated 削除** | Day 9 では未着手 (利用箇所更新後、Day 10+) |
| 🟢 低 | **EvolutionStep 完全 4 member 化 / LearningM** | Week 4-5 (Day 9 scope 外) |

#### 主要決定

- Day 9 メイン成果 = **Provenance 層継続** (ResearchEntity + ResearchActivity 2 type + Mapping、Q1 A 案 / Q2 A-Minimal)
- ResearchEntity は **既存 Process type を embed する 4 constructor 設計** (Q3 案 A、TyDD-S1 遵守)
- Mapping 関数は **Process side `.toEntity` method** (Q4 案 A) だが、**実装は ResearchEntity.lean 内に配置** (循環依存回避、namespace `AgentSpec.Process.Hypothesis` への extension method 形式)
- ResearchAgent / Verdict payload 拡充 / transitionLegacy 削除 / EvolutionStep 4 member 化 / LearningM は Day 10+ または Week 4-5 へ繰り延げ

---

### 2.14 Day 8 着手前判断結果 (確定済、Day 7 完了後の議論結果)

#### Day 8 全体方針 (Q1-Q4 採用案、確定済)

| 判断ポイント | 採用案 | 理由 |
|---|---|---|
| **Q1 Day 8 main scope** | **B 案: Verdict + EvolutionStep B4 4-arg post 統合** | Day 1-7 リズム維持 (1 type + refactor)、Section 2.9 完全解消、scope 適切。A 案 (Provenance 3-4 type) は scope 超過、C 案 (cross-layer test のみ) は物足りない、D 案 (Lean-Auto research) は実装段階に入らず |
| **Q2 B 案 sub-scope** | **B-Medium**: Verdict + EvolutionStep refactor + Spine+Process cross-layer test | C 案 (Spine+Process test、Day 7 paper サーベイから導出) も同時取込み、Day 8 で 2 大成果 (B4 完全統合 + cross-layer test) |
| **Q3 Verdict design** | **案 A**: `inductive Verdict { proven, refuted, inconclusive }` (3 variant minimal) | hole-driven、Day 9+ で payload 拡充可能 (Failure と同パターン) |
| **Q4 B4 4-arg post signature** | **案 A**: `transition : (pre : S) → (input : Hypothesis) → (output : Verdict) → (post : S) → Prop` (Hypothesis/Verdict separate args) | S4 P5 explicit assumptions 遵守、より細かい制御 |

#### Day 8 想定 deliverables (確定版、Q1-Q4 反映)

| ファイル | 内容 |
|---|---|
| `AgentSpec/Provenance/Verdict.lean` (NEW、新 namespace `AgentSpec.Provenance`) | `inductive Verdict { proven, refuted, inconclusive }` (Q3 案 A 3 variant minimal) + DecidableEq/Inhabited/Repr deriving + trivial fixture + PROV mapping in docstring (`ResearchActivity` の output) |
| `AgentSpec/Spine/EvolutionStep.lean` (modify) | **Q3 案 B 完了**: `transition : S → S → Prop` を **Q4 案 A B4 4-arg post**: `transition : (pre : S) → (input : Hypothesis) → (output : Verdict) → (post : S) → Prop` に refactor (Section 2.9 完全解消)。後方互換のため `transitionLegacy : S → S → Prop` を残すか検討 (確定: Q1 Minimal で残す、deprecated 注記付き) |
| `AgentSpec/Test/Provenance/VerdictTest.lean` (NEW) | Verdict 構築 / DecidableEq / Inhabited / fixture (推定 8-10 example) |
| `AgentSpec/Test/Spine/EvolutionStepTest.lean` (modify) | B4 4-arg post の新 transition signature の test 追加 (推定 4-6 example) |
| `AgentSpec/Test/Cross/SpineProcessTest.lean` (NEW、Q4 案 A 別 file) | **Q2 B-Medium**: Spine + Process cross-layer integration test (`fullSpineExample` × `fullProcessExample` 同時利用、推定 4-6 example、Day 7 paper サーベイ Section 12.19 から) |
| `agent-spec-lib/artifact-manifest.json` | 4 新規 entries (Verdict + 3 test、Pattern #7 hook 強制で同 commit) |

#### Day 8 で意識する改善事項 (Day 7 評価から導出、Section 2.13 / 2.10 連携)

| 優先度 | 項目 | Day 8 反映 |
|---|---|---|
| 🟡 中 | **Verdict 型 + EvolutionStep B4 4-arg post 完全統合** | **Day 8 メイン成果 (Q1 B 案)、Section 2.9 完全解消** |
| 🟡 中 | **Spine + Process cross-layer integration test** | **Day 8 副成果 (Q2 B-Medium)、Section 12.19 paper サーベイから** |
| 🟢 低 | **S6 Paper 1 BST/AVL invariants** | **Day 8 では未着手 (Q1 Minimal scope 制御、Day 9+ Evolution 拡張時)** |
| 🟢 低 | **Evolution DecidableEq / HandoffChain concat** | Day 9+ 検討 (Day 8 scope 制御) |
| 🟡 Day 9+ | **Provenance 層 ResearchEntity / ResearchActivity / ResearchAgent + Mapping 関数** | Day 9+ (Day 8 で Verdict のみ Provenance 配下に先行配置) |

#### 主要決定

- Day 8 は **Verdict 型新規定義 + EvolutionStep B4 4-arg post 完全統合** (Section 2.9 完全解消) が**メイン成果**
- **Spine + Process cross-layer integration test** (Day 7 paper サーベイ Section 12.19 から導出) を**副成果**として同時実装 (Q2 B-Medium、Q4 案 A 別 file)
- Verdict は新 namespace `AgentSpec.Provenance` に先行配置 (Day 9+ で ResearchEntity/Activity/Agent + Mapping を追加してこの namespace を完成させる)
- S6 Paper 1 / DecidableEq / concat は Day 9+ へ繰り延べ (Q1 Minimal scope 制御)

---

## 3. Gap Analysis で「Week 2 以降」と明示した項目

### 3.1 高リスク（high、実装必須）

全 19 件。GA-S 系が基盤、GA-C/M/E 系が能力・評価層。

| Gap | 概要 | 予定 Week |
|---|---|---|
| GA-S1 | ResearchNode umbrella（S2-S20 統合） | Week 2 着手 |
| GA-S2 | FolgeID 型と半順序 | Week 2 |
| GA-S3 | Provenance Triple | Week 3 |
| GA-S2 | FolgeID + 半順序 | **Day 1 で hole-driven signature + prefix partial order 実装済** (Spine/FolgeID.lean)。PartialOrder/Ord instance と Day 5 拡充が残 |
| GA-S4 | Edge Type Inductive | **Day 2 で hole-driven 迂回実装** (Spine/Edge.lean): `inductive EdgeKind` 6 variant + `structure Edge { src dst : FolgeID, kind : EdgeKind }` + isSelfLoop/reverse + 全 6 variant involutivity test。Week 4-5 で `inductive ResearchEdge : ResearchNode → ResearchNode → Type` (dependent type) に refactor 予定 |
| GA-S5 | Retirement first-class | Week 4 |
| GA-S6 | Failure first-class | Week 4 |
| GA-S8 | Rationale 型 | Week 4 |
| GA-C1 | agent-spec-lib umbrella | 継続実装 |
| GA-C2 | Bidirectional Codec (round-trip 証明付) | Week 1 で個別 example + 125 ケース、**Day 1 で `def roundTripUniversal` signature + 3 theorem + 343 ケース bounded 証明追加**（Proofs/RoundTrip.lean）。universal proof は Day 4-5 |
| GA-C7 | SMT ハンマー統合 | Week 6 |
| GA-C9 | EnvExtension Auto-Register | Week 5-6 |
| GA-C12 | Perspective Generation | Week 5-6 |
| GA-C13 | Iterative Search Loop | Week 5-6 |
| GA-C14 | Saturation Detection | Week 5-6 |
| GA-C15 | Schema-Driven Extraction | Week 5-6 |
| GA-M1 | CLEVER 風自己評価 | Week 7-8 |
| GA-M2 | Atlas augment 戦略（X3DH IDE） | Week 6-7 |
| GA-E5 | 仕様等価性自動検証 | Week 7-8（CLEVER 0.621% の現実を踏まえ限定的） |
| GA-E6 | 中間段階可観測性 | Week 6-7 |

### 3.2 中リスク（medium、Week 2-8 で逐次）

60 件超。GA-S15, GA-S16, GA-S17, GA-S18, GA-S19, GA-S20 等の型基盤は Week 2-5、GA-C3-C6, C10-C11, C16-C20, C22-C26, C28-C32, C34, C35, C37 の能力層は Week 3-6、GA-M3-M4, M7-M15 の手法層は Week 3-7、GA-E1-E4, E7, E9 の評価層は Week 5-8、GA-I1, I4, I7, I9-I12 の統合層は Week 2-7、GA-T1-T2, T5-T6 の移行層は Week 7-8。

### 3.3 低リスク（low、優先度低）

22 件。GA-S14, GA-S19, GA-C8, GA-C21, GA-C27, GA-C33, GA-C36, GA-E8, GA-E10, GA-I2-I3, I5-I6, I8, I13-I14, GA-T3-T4, T7-T8。MVP 後または必要時に対応。

---

## 4. スコープ外確定項目（将来再検討の余地あり）

Gap Analysis で **スコープ外確定** と判定したもの:

| 項目 | 確定理由 | 再検討条件 |
|---|---|---|
| GA-E11 (Human-in-the-loop metrics) | GA-M2 augment で実質カバー、運用フェーズ課題 | 運用開始後、メトリクス不足が顕在化したとき |
| GA-T9 (CSLib upstream 貢献戦略) | Phase 5 以降の発展課題、MVP 不要 | Phase 5 完了 + コミュニティフィードバックあり |
| Implementation2Spec (Atlas 未実現 #1) | 新基盤 MVP スコープ外 | 将来の研究貢献候補 |
| InputOutput2Spec (Atlas 未実現 #2) | 同上 | 同上 |
| InterFramework (Atlas 未実現 #3) | 同上 | 同上 |
| TyDD-D1-D5 (Types=Compression quotes) | 哲学的根拠、Gap 直結せず | — |
| TyDD-S1-S8 (Source summaries) | Recipe 参照元、個別 Gap 不要 | — |
| TyDD-N1-N4 (TyDe 2025 deep dives) | G1-G5 で間接参照済 | — |
| TyDD-L8-L10 (Combinatorics/Conatural/mutual recursion) | agent-manifesto スコープ外 | — |
| CompressedTerm (TyDD-H5) | high-tokenizer 固有の研究課題 | — |
| ユーザーの事前知識への適応 (Co-STORM) | deep-research-survey Gap Analysis でスコープ外 | 別研究機会 |
| モデル非依存ルーティング | project_local_llm_routing.md 別研究 | — |
| 外部 Deep Research API 委譲 (OpenAI/Perplexity) | 自プロジェクトの能力獲得目的に反する | — |

---

## 5. 検証・品質保証の強化タスク

Week 1 時点の検証手段の弱点（ユーザーとの議論で判明）:

| 観点 | 現状 | 後続タスク |
|---|---|---|
| 独立検証の 4 条件 | 2/4 (contextSeparated + framingIndependent のみ) | CI + 別モデル族による evaluatorIndependent 達成は Week 6-7 |
| Behavior test | 24 件 example + 125 ケース有限量化 | Property-based test (Hypothesis 風) 導入、Week 6-7 |
| Differential Random Testing | なし | Cedar VGD パターン (21 bug 検出実績) を Week 7-8 で適用 (GA-M4) |
| CI | なし | Week 6-7 で GitHub Actions 統合 (GA-I11) |
| Self-benchmarking | なし | Week 7-8 で VeriSoftBench 形式の再帰評価 (GA-E1) |
| 外部 benchmark 比較 | なし | Week 7-8 で FLTEval / miniF2F / CLEVER 等と照合 (GA-E7) |
| Time-to-proof metrics | なし | Week 6-7 で `metrics` skill 拡張 (GA-E8) |
| 仕様等価性の自動検証 | なし（CLEVER 0.621% の根本困難） | Atlas augment 戦略で人間介入必須 (GA-E5, GA-M2) |

---

## 6. Linter / Hooks / 設定の未対処

### 6.1 Lean 文書の Linter（ユーザー要望、後回し指示）

**ユーザー要求**（本セッション中）: 「lean 文書では、数式と英語のみ許可する」

設計提案（ユーザーが「後でいいや」と判断し保留）:
- **対象範囲**: A (`agent-spec-lib/` のみ) / B (`lean-formalization/` も含む) / C (全 .lean)
- **実装レイヤ**: X (hook IDE-time) / Y (lake exe build-time) / Z (両方)
- **既存日本語コメント影響**: 今すぐ英訳 / Week 2 以降に分散 / Week 6-7 で一括

許可すべき Unicode 範囲（設計案）:
- ASCII (U+0000-U+007F), Latin Extended (U+0080-U+024F), Greek (U+0370-U+03FF), General Punctuation (U+2000-U+206F), Letterlike Symbols (U+2100-U+214F), Arrows (U+2190-U+21FF), Mathematical Operators (U+2200-U+22FF), Supplemental Math Operators (U+2A00-U+2AFF), Mathematical Alphanumeric Symbols (U+1D400-U+1D7FF)

禁止範囲:
- Hiragana (U+3040-U+309F), Katakana (U+30A0-U+30FF), CJK Unified Ideographs (U+4E00-U+9FFF), Hangul (U+AC00-U+D7AF), Halfwidth Katakana (U+FF65-U+FF9F)

**対処タイミング未定**（ユーザー判断待ち）。

### 6.2 `.claude/hooks/` の新基盤対応

- 既存 hook は Issue ベース前提（worktree-guard.sh 等）
- 新基盤の Lean canonical 前提に改訂 (GA-I12)
- Week 6-7 予定

#### 6.2.1 Pattern #7 構造的強制 hook (Day 2 TyDD 評価から導出, 🟡 Day 5 または Week 3)

**現状の問題**: Section 10.2 Pattern #7（artifact-manifest.json 同 commit 反映）が
Day 1 / Day 2 ともに別 commit に分離。原因は P3 hook が manifest 必須化していないため。

**改善案**: pre-commit hook を追加し、以下を強制:
- staged 変更に `agent-spec-lib/AgentSpec/Spine/`, `Proofs/`, `Process/` 配下の `.lean`
  新規ファイル (`A` ステータス) が含まれる場合
- `agent-spec-lib/artifact-manifest.json` も同じ commit に staged されていることを要求
- 違反時は Reject + 「Section 10.2 Pattern #7 違反: artifact-manifest.json を同 commit に追加してください」

**実装場所候補**: `.claude/hooks/p3-manifest-on-commit.sh` (新規)

**根拠**: Section 12.6 Day 2 TyDD 評価結果。Day 1 / Day 2 で 2 ラウンド連続違反したため構造的強制が妥当。

### 6.3 Claude Code settings.json

- 新基盤固有の permissions / env vars が未定義
- Week 6-7 で CI 整備時に同時対応

### 6.4 Git commit 互換性分類 hook

- 既存 `.claude/hooks/` で P3 互換性分類を強制（conservative extension / compatible change / breaking change）
- 新基盤関連 commit はすべて `conservative extension` として記録（既存ファイルを変更せず、新規追加のみ）

---

## 7. Verifier Round で informational 扱いとした指摘残件

全 5 ラウンド（サーベイ 3 + 補遺 2 + Gap Analysis 3 + Week 1 × 4）を通じて informational として保留した項目:

### サーベイ Round 1 informational
- 指摘 4: SurveyG ablation の指標名明示（`Coverage -5.9` vs `Critical Analysis -5.9` の区別）
- 指摘 11: Phase 別 Gate 基準（Parent Issue 時点の記載は要件外）

### G5 補遺 Round 1 informational
- 指摘 4: 「22 リンク」の根拠（実測 19 ユニーク）
- 指摘 5: CLEVER 0.6% vs 0.621% の表記揺れ（対処済）

### Gap Analysis Round 1 informational
- 指摘 4: theorem カウント 1670 vs Meta.lean 1588 の齟齬 — 測定範囲の差
- 指摘 6: CLAUDE.md 「53 axioms」旧値は agent-manifesto 本体の問題

### Week 1 Verifier Round 3 informational
- 🔄 指摘 3: テストコードが本番ライブラリ (`AgentSpec`) に直接 import → **Week 2 で `lean_lib AgentSpecTest` 分離** (Section 2.3 と連動)
- ✅ 指摘 4: example 8 (DecidableEq テスト) のコメントと `rfl` 証明手段の不整合 — 実態確認で解消済 (`decide` 使用 + `(DecidableEq 使用)` コメントで整合)
- ⏳ 指摘 5: `$schema` URL が非解決可能 (`agent-manifesto.internal` ドメイン) → Week 6-7 で本体 schema 整備時に同期

### /verify Round 1 (2026-04-17 実施) informational 4 件
- 指摘 3: `$schema` URI 非解決可能 → 上記 Round 3 指摘 5 と重複 (⏳ Week 6-7)
- 指摘 4: AgentSpec.lean のテスト混在 → Round 3 指摘 3 と重複 (🔄 Week 2)
- 指摘 5: README TyDD 表 (13 行) と Section 12.2 (12 項目) の分類軸乖離 → ⏳ Week 2 以降のドキュメント整理
- 指摘 6: Section 2.3 の旧状態記述 → ✅ 本改訂 2 で更新済
- 指摘 7: Core.lean に明示的 `import` 文なし → 🔄 Week 2 (Section 2.2 項目追加済)
- 指摘 8: artifact-manifest schema divergence (本体 vs 新基盤) → ⏳ Week 6-7 (Section 2.4 項目追加済)

---

## 8. タグ別クロスリファレンス

### GA-S (Structure) 残タスク
- 実装済: S1 umbrella (部分), S18 (Gradual Refinement Type の SemVer 版), S15 (Ord instance で基盤)
- 残: S2 (FolgeID), S3 (Provenance), S4 (Edge), S5 (Retirement), S6 (Failure), S7 (State), S8 (Rationale), S9 (Assumption S-type), S10 (ResearchGoal), S11 (Hoare 4-arg), S12 (PropositionId 拡張), S13 (SelfGoverning), S14 (EnforcementLayer), S16 (Multiplicity), S17 (FiberedTypeSpec), S19 (Phantom scope), S20 (Dynamic dependency)

### GA-C (Capability) 残タスク
- 実装済: C1 umbrella (部分), C2 (Bidirectional Codec、Week 2 で普遍定理), C32 (Capability-separated import、独立パッケージで達成), C27 (Trusted code 最小化、native_decide 非使用)
- 残: C3 (Reverse Deps Index), C4 (Semantic Hash), C5 (Content-addressed storage), C6 (Event Log), C7 (SMT hammer), C8 (ProofWidget), C9 (EnvExt Auto-Register), C10 (Typed Holes), C11 (Coverage Verification), C12-C21 (#599 前リサーチ由来), C22-C26 (TyDD Recipe 由来), C28-C31 (G1/G5 由来), C33-C37 (追加)

### GA-M (Methodology) 残タスク
全 15 件未着手 (Week 2-8)

### GA-E (Evaluation) 残タスク
全 10 件未着手 (Week 5-8)

### GA-I (Integration) 残タスク
- 実装済: I1 (artifact-manifest 基本構造), I7 (high-tokenizer 再定義方針)
- 残: I2-I6, I8-I14 (Week 2-7)

### GA-T (Transition) 残タスク
- T1 (#599 再起動) は新基盤完成後
- T2 (Phase 0 ロードマップ) は本 phase で消化中
- T3-T8 は Week 6-8

### GA-W (Warning) 適用状況
- W1-W10 すべて「守るべき警告」として全 Week で意識
- Week 1 時点: W4 (sorry 蓄積回避) / W7 (termination) / native_decide 回避 すべて遵守

---

## 9. 優先度マトリクス（後続タスク選定の指針）

| 優先度 | 判定基準 | Gap 群 | 推奨 Week |
|---|---|---|---|
| **P0** | 新基盤の根幹、後回し不可 | GA-S1, S2, S4, S5, S6, S8, C1, C2 普遍定理 | Week 2-4 |
| **P1** | 高リスク Gap、deterministic 負荷撤廃に必須 | GA-C7, C9, M1, M2, E5, E6 | Week 5-7 |
| **P2** | 中リスク Gap、完成度を上げる | GA-S3, S7, S10-S20, C3-C6, C10-C37 の medium 群, M3-M15, E1-E4, E7, E9, I1-I12 の medium 群, T1-T2, T5-T6 | Week 3-8 |
| **P3** | 低リスク Gap、将来対応 | GA-S14, S19, C8, C21, C27, C33, C36, E8, E10, I2-I6, I8, I13-I14, T3-T4, T7-T8 | MVP 後 |
| **保留** | スコープ外確定、再検討条件付 | GA-E11, T9, Atlas 未実現 3 projects | 条件達成時 |
| **未定** | ユーザー判断待ち | Lean 文書 linter (日本語禁止) | 指示待ち |

---

## 10. 実装ガイド（Week 2 以降向け）

### 10.1 Week 2 Day 別作業手順（Week 1 持ち越し + Spine 層着手）

Week 1 の仮実装項目を Week 2 で優先対処しつつ、Spine 層の型宣言を段階的に進める:

| Day | 作業内容 | 関連 Section / Gap |
|-----|---------|------------------|
| **Day 1** | Core.lean に明示的 `import` 文追加 (Mathlib 等) / Top-down で FolgeID signature 先行定義 (`structure FolgeID` + `instance : LE FolgeID` 予約) / 普遍 round-trip 定理の induction 証明開始 (`String.toList` / `Nat.toString` 補題収集) | Section 2.2 🔄 / 2.6 🔄 |
| **Day 2** ✅ | `lean_lib AgentSpecTest` に分離 (lakefile.lean に別 lib target 追加、`Test/CoreTest.lean` + `Test/Spine/FolgeIDTest.lean` + Day 2 追加の `Test/Spine/EdgeTest.lean` を集約) / Edge Type (GA-S4) inductive 型宣言 signature 実装 | Section 2.3 ✅ / GA-S4 ✅ / commit `58b75a0` |
| **Day 3** | Spine 層 `EvolutionStep.lean`, `SafetyConstraint.lean` の type class 宣言 + dummy instance (**Day 1 確立パターン適用**: segment abbrev → structure → Bool helper → instLE 明示命名 → Decidable via `inferInstanceAs`) **+ Day 2 評価から**: S1 5 軸意識 / S4 P2 Refinement (state transition 事前条件) / B4 Hoare 4-arg post | Week 2-3 Spine 層 / Section 10.2 / 12.6 |
| **Day 4** | Spine 層 `LearningCycle.lean`, `Observable.lean` の type class 宣言 + dummy instance (**Day 1 確立パターン適用**) **+ Day 2 評価から**: F2 Lattice (LearningCycle 収束) / H7 minimal viable pipeline / S4 P5 explicit assumptions **+ Day 3 評価から**: cross-class interaction test (`[EvolutionStep S] [SafetyConstraint S]` の同時要求) を LearningCycle 合成時に追加 | Week 2-3 Spine 層 / Section 10.2 / 12.6 |
| **Day 5** | FolgeID (GA-S2) の `PartialOrder`/`Ord` instance 追加 + behavior example 拡充 / Verifier Round 1 検証 **+ Day 2 評価から**: F2 Lattice 完全形 / H1 Multiplicity-annotated refinement (path Linear 表現検討) / Section 6.2.1 hook 実装検討 | Week 2-3 Spine 層 + GA-S2 / Section 12.6 / 6.2.1 |
| **Day 6** ✅ | **Process 層 hole-driven 着手** (Week 4-5 前倒し): `AgentSpec/Process/Hypothesis.lean` (inductive Hypothesis + dummy instance) + `AgentSpec/Process/Failure.lean` (inductive Failure + FailureReason inductive + dummy instance) + Test 2 ファイル **+ Day 5 評価 Section 12.13 から**: PROV-O vocabulary alignment in docstring (Option C、02-data-provenance §4.1 paper finding 顕在化を docstring 注記レベルで先行記録) **+ Day 1-5 確立パターン適用**: hole-driven minimal、universe u 明示、instance 明示命名 | Week 4-5 Process 層 (前倒し) / Section 2.11 / 12.16-12.18 (paper × pattern × principle 合流 3 度目達成) / commit `917c752` |
| **Day 7** ✅ | Process 層継続 (Day 6 議論で確定済 Q1-Q4): `AgentSpec/Process/Evolution.lean` (Hypothesis 依存 inductive、**Q3 案 B**: EvolutionStep B4 4-arg post signature 宣言のみ、完全統合は Day 8+ Verdict 型確定後) + `AgentSpec/Process/HandoffChain.lean` (T1 一時性 inductive、handoff sequence) + Test 2 ファイル **+ Day 6 評価 Section 12.17 / 2.12 から (Q2 案 A 1-2 件 / Q4 案 A 別ファイル)**: 🟡 cross-process interaction test 1-2 件 (Hypothesis × Failure × Evolution × HandoffChain、Day 4 fullSpineExample パターン) / 🟡 EvolutionStep B4 4-arg post 部分対処 (signature のみ Day 7、完全統合 Day 8+) / 🟡 HandoffChain T1 一時性 inductive 表現 / S6 Paper 1 BST/AVL invariants は **Day 8+ Evolution 拡張時 (Q1 Minimal scope 制御)** | Week 4-5 Process 層 + Section 2.9 部分解消 + Section 2.12 (Day 6 評価導出) + Section 2.10 (Day 8+ S6 Paper 1) / commit `941b25c` |
| **Day 8** ✅ | Day 7 議論で確定済 Q1-Q4 (Section 2.14): **Q1 B 案** = Verdict 型新規定義 + EvolutionStep B4 4-arg post 完全統合 (Section 2.9 完全解消) **+ Q2 B-Medium** = Spine + Process cross-layer integration test (Day 7 paper サーベイ Section 12.19 から導出、Q4 案 A 別 file): `AgentSpec/Provenance/Verdict.lean` (Q3 案 A 3 variant minimal: proven/refuted/inconclusive) + `AgentSpec/Spine/EvolutionStep.lean` refactor (Q4 案 A: Hypothesis/Verdict separate args) + `AgentSpec/Test/Provenance/VerdictTest.lean` + `AgentSpec/Test/Cross/SpineProcessTest.lean` + `AgentSpec/Test/Spine/EvolutionStepTest.lean` modify | Section 2.9 完全解消 + Section 2.14 (Day 8 着手前判断) + Section 12.19-12.21 (Day 7 評価導出) / commit `0f78fa6` |
| **Day 9** ✅ | Day 8 議論で確定済 Q1-Q4 (Section 2.16): **Q1 A 案** = Provenance 層継続 + **Q2 A-Minimal** = ResearchEntity + ResearchActivity 2 type + Mapping + **Q3 案 A** = ResearchEntity 4 constructor (既存 Process type embed) + **Q4 案 A** = Process side `.toEntity` method (実装は循環依存回避のため ResearchEntity.lean 内に配置): `AgentSpec/Provenance/{ResearchEntity, ResearchActivity}.lean` + 4 toEntity Mapping + `AgentSpec/Test/Provenance/{ResearchEntityTest, ResearchActivityTest}.lean` + verifier_history Day 1-9 一括補完 + Subagent I2 即時実装修正対処 | Section 2.16 (Day 9 着手前判断) + Section 12.22-12.27 (Day 8-9 評価導出) + 02-data-provenance §4.1 (PROV-O 実装) / commit `fa5b373` |
| **Day 10** ✅ | Day 9 議論で確定済 Q1-Q4 (Section 2.18): **Q1 B 案** = ResearchAgent + EvolutionStep transition → ResearchActivity.verify mapping (Day 8/9 連携 path 確立) + **Q2 B-Medium** = signature + 実装 + test + **Q3 案 A** = `structure ResearchAgent { identity, role : Role }` + `inductive Role { Researcher, Reviewer, Verifier }` + **Q4 案 A** = free function `transitionToActivity (h : Hypothesis) (v : Verdict) : ResearchActivity := .verify h v`: `AgentSpec/Provenance/{ResearchAgent, EvolutionMapping}.lean` + **ResearchEntity.lean 5 constructor 拡張完了 (Day 10 D2、Agent embed)** + `AgentSpec/Test/Provenance/{ResearchAgentTest, EvolutionMappingTest}.lean` + Subagent A1 即時実装修正対処 (hook v2 配置) + Subagent I2 docstring 即時修正 | Section 2.18 (Day 10 着手前判断) + Section 12.28-12.30 (Day 10 評価導出) + 02-data-provenance §4.1 (PROV-O 三項統合 4 type 完備) / commit `b652347` |
| **Day 11** | Day 10 議論で確定済 Q1-Q4 (Section 2.20): **Q1 A 案** = PROV-O relation 3 structure + **Q2 A-Minimal** = 3 structure + Test 2-3 + **Q3 案 A** = 3 separate structure (`WasAttributedTo` / `WasGeneratedBy` / `WasDerivedFrom`、PROV-O 1:1 対応) + **Q4 案 A** = 02-data-provenance §4.1 厳格 type (Entity × Agent / Entity × Activity / Entity × Entity): `AgentSpec/Provenance/ProvRelation.lean` (3 structure 統合配置) + `AgentSpec/Test/Provenance/ProvRelationTest.lean` | Section 2.20 (Day 11 着手前判断) + Section 12.28-12.30 (Day 10 評価導出) + 02-data-provenance §4.1 (PROV-O relation Lean 化) |
| **Day 12+** | **02-data-provenance §4.4-4.7 完全実装** (RetiredEntity / cache lineage / RO-Crate export) + **Day 6-10 評価から繰り延べ項目** (Day 11 で扱わなかったもの): 🟡 02-data-provenance §4.4 退役の構造的検出 (RetiredEntity) / 🟡 §4.6 Nextflow resume + Galaxy job cache / 🟡 Hypothesis rationale 型化 / 🟡 Failure payload 型化 / 🟡 Verdict payload 拡充 / 🟢 transitionLegacy deprecated 削除 / 🟢 EvolutionStep 完全 4 member 化 / 🟢 G5-1 §3.4 step 2 LearningM indexed monad / 🟢 S6 Paper 1 BST/AVL invariants / 🟢 Evolution DecidableEq / 🟢 HandoffChain concat / 🟢 ResearchEntity DecidableEq 手動実装 / 🟢 ResearchActivity payload なし variants の payload 拡充 / 🟢 HandoffChain 全体 embed 用 constructor。または **Manifest 移植** (Week 3-4) または **Lean-Auto research/PoC** (Section 2.10 🔴) を並行開始 | Week 3-4 (Manifest) / Week 4-5 (PROV-O 完全実装 + LearningM) / Week 6 (Lean-Auto) / Section 2.10 + 2.12 + 2.13 + 2.15 + 2.17 + 2.19 |

### 10.2 Week 2 Day 1 で確立した実装パターン（Day 3-5 Spine 層 + Day 6+ Process 層に適用）

Day 1 の FolgeID 実装と /verify Round 2 で確立した規範パターン。Day 3-5 で追加する
EvolutionStep, SafetyConstraint, LearningCycle, Observable の各 type class にも適用する。

| # | パターン | 根拠 | 違反時の症状 |
|---|---|---|---|
| 1 | `abbrev Segment := X ⊕ Y` で segment 型を先行宣言 | TyDD-S1 Types first | structure 直書きは abstraction 欠如 |
| 2 | `def f_list : List X → ... := ...` を先に書き、`def f : T → ... := f_list t.path` で structure 経由呼び出し | `decide` の structure pattern reduction stuck 回避（Day 1 で発生） | `by decide` が reduction stuck で失敗 |
| 3 | `instance instLE : LE T := ⟨...⟩` と **明示命名** | unfold の anonymous instance 名依存を回避 | /verify Round 1 A1 指摘 (anonymous instance の名前推定は脆弱) |
| 4 | `instance (a b : T) : Decidable (a ≤ b) := inferInstanceAs (...)` | `by unfold` の脆弱性除去 | Round 1 A1 と同根本原因 |
| 5 | Prop signature は `def` で宣言（`abbrev` 禁止） | hole-driven opaque identity 保持 | /verify Round 1 A2 指摘 (後続 proof 時の型チェック identity) |
| 6 | `sorry` / `axiom` / `native_decide` / `partial def` 使用禁止 | GA-W4 / GA-C27 / GA-W7 | Verifier による build 拒否 |
| 7 | 新 module 追加時は artifact-manifest.json に同 commit で反映 (id, path, refs, provides_*, week<N>_status) | P3 /trace 構造整合性 | artifact-manifest と実コードの乖離 |
| 8 | Lean 4 予約語 (`from`, `to`, `match`, `let`, `do`, `where`, `then`, `else`, `fun`, etc.) を field 名・variable 名・identifier に使用しない (Day 2 で確立) | Lean 4 parser エラー | `unexpected token 'from'; expected '_', '}', identifier or term` 等 |

**既存コードへの遡及適用**: Core.lean の `by unfold LE.le instLE` パターンは Day 1 以前の実装で残存。
Day 3-5 で Spine 層に同パターンを適用しないだけでなく、Core.lean 自体も `inferInstanceAs` へ
統一する選択肢がある（Section 2.2 参照）。Day 5 または Week 3 の余裕時に対処。

### 10.3 各 Week 開始時のルーチン

各 Week の開始時に本ファイルの該当セクションを参照し、以下の手順で進める:

1. **該当 Week の Phase 0 タスク**（Section 1）を確認
2. **Gap Analysis の対応 GA- タグ**（Section 3 / `10-gap-analysis.md`）を参照
3. **Week 1 の仮実装から置換すべき項目**（Section 2）があれば優先対処
4. **TyDD/TDD 原則**（`07-lean4-applications/G5-1-cslib-boole.md` Section 3）に沿って型駆動で実装
5. **Verifier 検証**（Round 1-2 は必須、addressable = 0 まで）
6. **artifact-manifest.json 更新**（依存・refs・codec_completeness・tydd_alignment）
7. **commit**（conservative extension / compatible change / breaking change のいずれかを明記、P3 互換性分類 hook 遵守）

---

## 11. 関連ドキュメント

- `10-gap-analysis.md`: 104 Gap + 10 Warning の詳細、GA- タグ Index、umbrella Gap、クロスリファレンス
- `99-verifier-rounds.md`: Verifier 全検証履歴（サーベイ 3 + 補遺 2 + Gap Analysis 3 + Week 1 × 4）
- `00-synthesis.md`: 15 グループ統合まとめ（Section 7 に Atlas 12 projects 対応表、G5 補遺）
- `07-lean4-applications/G5-1-cslib-boole.md`: 8 週ロードマップ根拠、CSLib/Boole 分析
- `07-lean4-applications/G5-2-atlas-dafny.md`: Dafny 成功要因（Z3 空証明 44.7%）、Lean への転用戦略
- `07-lean4-applications/G1-cedar-aws.md`: VGD パターン、Differential Random Testing
- `../../../agent-spec-lib/README.md`: Phase 0 Week 1 進捗 + 8 週ロードマップ
- `../../../agent-spec-lib/artifact-manifest.json`: 依存 edge + TyDD 合致度マトリクス
- `../../../../research/survey_type_driven_development_2025.md`: TyDD 12 Recipes + Tag Index
- `../../../../research/lean4-handoff.md`: Atlas 12 projects 提案書
- `../../../.claude/handoffs/handoff-599-pending-rebase.md`: #599 新基盤待機状態、16 Gap の持ち越し

---

## 12. TyDD 合致度追跡

本セッション中に 3 回の TyDD サーベイ合致度レビューを実施。各 Week 完了時にこの Section を更新する。

### 12.1 レビュー履歴

| レビュー回 | 日付 | Week | 合致率 | 主な判定 |
|---|---|---|---|---|
| 1 | 2026-04-17 | Week 1 最小プレースホルダ | ~30% (推定) | TyDD/TDD 原則から外れている → re-do へ |
| 2 | 2026-04-17 | Week 1 re-do (SemVer + parse + example) | 61.5% (8/13) | F6 完全化、Recipe 11 達成、F2 未実装 |
| 3 | 2026-04-17 | Week 1 TyDD 完全合致版 (α+β+γ) | **92.3% (12/13)** | **実質的完全合致達成** |
| 4 (/verify) | 2026-04-17 | /verify Round 1 (logprob + Subagent multi-evaluator) | 92.3% 維持 | logprob pairwise PASS (A margin 0.623) + Subagent Round 1 FAIL (addressable 2) → Round 2 PASS (数値誤記・codec 方向を修正後)。P2 検証トークン書込済 (evaluator_independent: true, 3/4 conditions) |

### 12.2 Week 1 完了時の合致状況

**評価分母の定義**: Week 1 scope に含まれる評価対象は 13 tag/recipe（下記「完全合致 12 項目」+「部分合致 1 項目」）。分母 13 は **Week 1 開始時点で scope 対象と判定された tag** であり、「scope 外の tag」（後述）は分母に含めない。本 Section 12.3 benefit 達成状況（分母 10 benefit × evaluable 9）とは別軸の評価。

**完全合致 12 項目 (12/13 = 92.3%)**: S1, S4, D1-D5, F2 (予備), F6, G1-G6, H3, H7, J4, J7, Recipe 11, Recipe 12

※ 項目数の内訳: S1 (1) + S4 (1) + D1-D5 (5) + F2 (1) + F6 (1) + G1-G6 (6) + H3 (1) + H7 (1) + J4 (1) + J7 (1) + Recipe 11 (1) + Recipe 12 (1) = 21 sub-items。ただし TyDD カテゴリ (S/D/F/G/H/J) 単位で集計すると S1, S4, D*, F2, F6, G*, H3, H7, J4, J7, R11, R12 の 12 カテゴリ分類となる。本「12 項目」はカテゴリ集計ベース。

**部分合致 1 項目 (Week 4 で本格化)**:
- **TyDD-J5 Self-hosting recursion**: artifact-manifest.json が JSON のまま、Lean 型化は Week 4 予定 (Section 2.4 の (ζ))

**合致率**: 完全合致 12 / (完全合致 12 + 部分合致 1) = **12/13 = 92.3%**

**Week 1 scope 外の tag**:
- B1, B3-B6 (Pipeline 必要)
- C1-C3 (LLM 統合必要)
- E1-E5 (Lean-Auto / SMT 必要)
- F1, F3-F5, F7-F8 (Pipeline / 後続 Process 層必要)
- H1-H11 の scope 外多数
- I1-I7 の scope 外多数
- J1-J3, J6 (N=1 で適用不可 / Python 層必要)
- Recipe 1-10 (SMT / pytest / LLM 必要)

### 12.3 TyDD 10 benefits (S1) の達成状況

| # | Benefit | Week 1 状態 |
|---|---|---|
| 1 | Deeper understanding of problem domain | ✓ SemVer の理解が深まった |
| 2 | More thoughtful design | ✓ structure 設計 |
| 3 | Easier mental models | ✓ SemVer は mental model |
| 4 | Better collaboration through contracts/APIs | ✓ artifact-manifest.json + README |
| 5 | Maintainability | ✓ |
| 6 | Clearer path towards implementation | ✓ |
| 7 | Top-down / hole-driven development | ⚠ Week 2 以降の実装スタイルで意識 (Section 2.6) |
| 8 | Higher confidence in correctness | ✓ 24 examples + 125 cases |
| 9 | Less scary refactoring | ✓ |
| 10 | Pleasure when programming | N/A (個人的感情) |

達成: 8/10 (benefit #7 は Week 2 以降で本格採用、benefit #10 は評価対象外)

### 12.4 Week 2 以降の合致度目標

| Week | 完了時の目標合致率 | 新規に合致する項目 |
|---|---|---|
| Week 2-3 (Spine 層) | 14/13 以上 ※ scope 拡大 | 新 tag が scope に入り、分母も増加。F1 Pipeline 予備、B4 Hoare 4-arg (ResearchSpec 定義時) |
| Week 3-4 (Manifest 移植) | 継続的改善 | F5 TypeSpec.toFuncSpec、J5 完全版 (preview) |
| Week 4-5 (Process 層) | high-scope 項目ほぼ全達成 | B4, F2 (lattice 完全版), F8 FiberedTypeSpec, H1 multiplicity |
| Week 5-6 (Tooling) | C1-C3, E1-E5, H2-H4, H7 L2, Recipe 1-10 達成 | SMT / LLM 統合で大幅拡大 |
| Week 6-7 (CI) | H7 L1 達成、G4 CI 化 | PBT / DRT / benchmark |
| Week 7-8 (Verification) | 全 scope 項目達成 | J1 descriptive coding (N > 1 で実施)、J3 two-layer |

### 12.5 レビュー方針

- 各 Week 完了時に本セクションを更新
- 新規 tag との合致状況を追跡
- 未合致項目は **本ファイル Section 2 の 2.X に移動**して理由を記録
- Week 8 完了時に Phase 0 全体の合致度を総括

### 12.6 Day 2 TyDD / サーベイ視点評価結果（2026-04-18 実施）

Day 2 (`58b75a0` Edge Type + lib 分離) を `survey_type_driven_development_2025.md` の
Tag Index (S1-S8, F1-F8, B1-B6, C1-C3, G1-G6, H1-H11, Recipe 1-12) と
Atlas/Cedar/CLEVER/CSLib 視点から評価。

#### 達成度サマリ

| 評価軸 | スコア | 備考 |
|---|---|---|
| S1 (Way of Types) 5 軸 | **5/5 ✓** | design / communicate / guide / verify / tool support 全て充足 |
| S1 10 benefits | **8/10 ✓** | #9 弱（Week 4-5 大規模 refactor 予定）、#10 N/A |
| S4 5 principles | 1 強 / 3 弱 / 1 N/A | **P2 Refinement 未活用が最大改善余地** |
| F1-F8 / B1-B6 / H1-H11 Recipes | 0 強 / 11 将来候補 | Phase 0 Week 2 段階として妥当（Week 4-5 で本格適用） |
| G1-G6 anti-pattern 回避 | 4/4 該当箇所 ✓ | sorry 0 / smart sorry 不使用 / over-spec 回避 / silent skip 回避 |
| Section 10.2 パターン適合 | 6 適用 / 1 部分違反 / 1 構造的違反 | #3 deriving は anonymous instance 自動命名、#7 artifact-manifest 同 commit が hook 化未対応 |

#### 強み (Day 2 評価で確認)

1. GA-S4 hole-driven 迂回の妥当性 — ResearchNode 未定義下での Edge 先行定義は S1 benefit #7 の典型実践
2. PROV (wasDerivedFrom, wasReplacedBy) + 研究領域固有 (refines, refutes, blocks, relates) の 6 variant hybrid
3. involutivity 全 6 variant 検証 — kind 非依存関数とはいえ、「向き反転は kind 不変」の意図を test で明示
4. lib 分離 — 4 ラウンド連続で flag された指摘の構造的解消

#### 改善余地（優先度順）

| 優先度 | 項目 | 対処タイミング | 関連 Section |
|---|---|---|---|
| 🔴 高 | **S4 P2 Refinement 未活用** — `isSelfLoop` Bool 関数を型レベル制約 (`{e : Edge // e.src ≠ e.dst}` または dependent type) に昇格 | **Week 4-5 ResearchNode 定義時** | Section 2.8 (新設) |
| 🟡 中 | **F8 FiberedTypeSpec への移行** — `inductive ResearchEdge : (k : EdgeKind) → ResearchNode → ResearchNode → Type` で kind ごと不変条件を型レベル強制 | Week 4-5 | Section 2.8 (新設) |
| 🟡 中 | **Pattern #7 構造的強制** — Spine/Proofs 層新規ファイル時に artifact-manifest 同 commit 強制 (pre-commit hook) | Day 5 または Week 3 | Section 6.2 (拡張) |
| 🟢 低 | PROV-strict mode と research-mode の語彙分離 | Week 6-7 | — |
| 🟢 低 | Recipe 11 BiTrSpec 適用 (Edge ↔ PROV-JSON codec) | Week 6 以降 | — |

#### Day 3-5 で意識すべき改善事項

| Day | TyDD 適用候補 |
|---|---|
| **Day 3** (EvolutionStep, SafetyConstraint) | S1 5 軸 / S4 P2 Refinement (state transition の事前条件) / B4 Hoare 4-arg post |
| **Day 4** (LearningCycle, Observable) | F2 Lattice (LearningCycle 収束) / H7 minimal viable pipeline / S4 P5 explicit assumptions |
| **Day 5** (FolgeID PartialOrder/Ord 拡張) | F2 Lattice 完全形 / H1 Multiplicity-annotated refinement (FolgeID path Linear 表現検討) |

#### 結論

Day 2 は **TyDD 基盤段階として S1 軸 5/5 達成**だが、**S4 (Refinement) と F2/F8 (Lattice/Fibered) の活用は意図的に Week 4-5 へ繰り延べ**。Phase 0 ロードマップに照らせば計画通り。Pattern #7 構造的違反は次セッション以降で hook 化を検討すべき技術的負債。

### 12.7 Day 2 終了時点の累計合致度サマリ（2026-04-18 時点）

Section 12.2 は Week 1 完了時点の合致状況を記録。本 Section 12.7 は **Day 2 終了時点の累計**を記録する（Day 別追跡）。

#### Day 2 累計合致状況

**評価対象**: Week 1 + Week 2 Day 1-2 で scope に入った tag/recipe。Week 2-3 Spine 層着手により分母が拡大（Section 12.4 目標通り）。

**完全合致 14 項目** (Week 1 12 + Day 1-2 で 2 追加):
- Week 1 由来 (12): S1, S4, D1-D5, F2 (予備), F6, G1-G6, H3, H7, J4, J7, Recipe 11, Recipe 12 (Section 12.2 参照)
- Day 1-2 で追加合致 (2):
  - **GA-S2 完全実装** (Spine/FolgeID.lean): prefix partial order + DecidableEq/Inhabited/Repr。`PartialOrder` instance は Day 5 拡充
  - **GA-S4 hole-driven 迂回実装** (Spine/Edge.lean): inductive 6 variant + structure。dependent type 化は Week 4-5 (Section 2.8)

**部分合致 1 項目**: TyDD-J5 Self-hosting (Section 12.2 と同様、Week 4 で本格化)

**Day 2 で改善余地として識別された項目** (Section 12.6):
- S4 P2 Refinement (Edge no-self-loop 型レベル強制) — 🔴 Week 4-5 で対処
- F8 FiberedTypeSpec (Edge kind-fibered 化) — 🟡 Week 4-5 で対処
- Pattern #7 構造的強制 — 🟡 Day 5 または Week 3

**Day 2 累計合致率**: 14/15 = **93.3%** (分子: 完全合致、分母: 完全 + 部分。Section 12.2 の 12/13 = 92.3% から +1.0pt 改善)

#### Section 12.4 Week 2-3 目標との中間照合

Section 12.4 は「Week 2-3 (Spine 層) 完了時の目標合致率: 14/13 以上 ※ scope 拡大」と設定。
Day 2 終了時点では **14/15 = 93.3%**（分子 14 を達成、分母も拡大）。

**残 Day 3-5 で追加目標**:
- Day 3-4 で EvolutionStep / SafetyConstraint / LearningCycle / Observable type class 4 件 → 完全合致 +4 想定
- Day 5 で FolgeID PartialOrder/Ord 拡張 → F2 Lattice 寄与強化
- Section 2.8 の Edge Refinement upgrade → Week 4-5 の S4 P2 / F8 達成への先行投資

**Day 5 終了時想定目標**: 18/19 = 94.7% (分子 +4、分母 +4 想定、Edge Refinement upgrade を分母外として保留)

#### Section 12.3 TyDD 10 benefits の Day 2 時点更新

| # | Benefit | Week 1 | Day 2 |
|---|---|---|---|
| 1 | Deeper understanding | ✓ SemVer | ✓ SemVer + FolgeID + Edge (Folgezettel + PROV) |
| 2 | Thoughtful design | ✓ structure | ✓ + hole-driven 迂回設計 (Edge Week 4-5 計画) |
| 3 | Easier mental models | ✓ SemVer | ✓ + graph theory モデル (FolgeID prefix order, Edge) |
| 4 | Collaboration via API | ✓ | ✓ + artifact-manifest 10 entries |
| 5 | Maintainability | ✓ | ✓ + lib 分離 (production / test) |
| 6 | Clearer path | ✓ | ✓ + Section 2.8 Refinement upgrade 計画 |
| 7 | Top-down / hole-driven | ⚠ Week 2 以降 | **✓ Day 1-2 で実践** (FolgeID, Edge) |
| 8 | Higher confidence | ✓ 24 examples + 125 cases | ✓ 50 examples + 343 cases + 全 6 variant involutivity |
| 9 | Less scary refactoring | ✓ | ⚠ Week 4-5 dependent type 化が大規模 (影響範囲は型レベル限定) |
| 10 | Pleasure | N/A | N/A |

**Day 2 達成**: 9/10 (Day 2 で benefit #7 が ⚠→✓ に昇格、benefit #9 が ✓→⚠ に降格)

### 12.8 Day 3 TyDD / サーベイ視点評価結果（2026-04-18 実施）

Day 3 (`58b75a0`+`...` EvolutionStep + SafetyConstraint) を Tag Index と Atlas/Cedar/CLEVER/CSLib 視点から評価。

#### 達成度サマリ（Day 2 比）

| 評価軸 | Day 2 | Day 3 | 変化 |
|---|---|---|---|
| S1 5 軸 | 5/5 | 5/5 | 維持 |
| S1 10 benefits | 8/10 | 8/10 | 維持（#7 ✓ 維持、#9 ⚠ 継続） |
| S4 5 principles 強適用 | 1/5 | **2/5** | **P2 が初の強適用達成** ✓ |
| F/B/H/Recipes 強適用 | 0 | 0 | 維持（B3, B4, F7, F8, H4, H10 の将来候補増加） |
| G1-G6 anti-pattern 回避 | 4/4 該当 | 4/4 該当 | 維持 |
| Section 10.2 適合 | 6 適用 / 1 部分 / 1 構造違反 | **5 適用 / 0 違反 / 1 構造違反** | Pattern #3 厳格化（deriving 不使用、明示 instance 命名） |

#### Day 3 で前進した項目

1. **S4 P2 Refinement の初の強適用** — `SafeState S := { s : S // safe s = true }` は Day 2 評価で「最大改善余地」と識別された項目。Day 3 で SafetyConstraint と同時実装することで evaluation→implementation のフィードバックループが機能した
2. **`doSafeOperation` test の設計** — 単なる instance test を超えて「safe state のみ受理する関数」の使用例を提示し、refinement type の生きた価値を実証（B3 Call-site obligation の最小実例）
3. **Pattern #8 派生** — `refl` を class member 外に出した判断（Lean 4 tactic shadow 回避）

#### 改善余地（優先度順）

| 優先度 | 項目 | 対処タイミング | 関連 Section |
|---|---|---|---|
| 🔴 高 | **SafetyConstraint Bool→Prop refactor の前倒し** — Day 3 で Bool 採用、Week 4-5 で Prop refactor 計画。代案: 最初から `class SafetyConstraint S where safe : S → Prop; safeDec : DecidablePred safe` で開始すれば全 instance 書換不要。S1 benefit #9 を弱める | **Day 4 着手前に判断** | Section 2.9（新設） |
| 🟡 中 | **EvolutionStep に Decidable transition がない** — Prop は decidable とは限らず `decide` で test できない。Day 3 では Unit の `True` で回避、Day 4 LearningCycle 統合時に必要 | Day 4 | Section 2.9 |
| 🟡 中 | **SafeState の smart constructor 不在** — Bool→Prop refactor 後に `⟨s, proof⟩` の proof 構築が冗長化 | Day 4 | Section 2.9 |
| 🟡 中 | **Pattern #7 構造的違反 3 連続** — Day 1, 2, 3 で artifact-manifest 別 commit。hook 化必要性増大 | Day 5 または Week 3 | Section 6.2.1 |
| 🟢 低 | **Hypothesis/Verdict/Observable の opaque 先行宣言** — hole-driven 完全化のため `opaque Hypothesis : Type` 等を Day 4 段階で placeholder 化する案 | Day 4 検討 | Section 2.9 |

#### Day 4 で意識すべき改善事項

| Day 3 評価から導出 | 反映先 |
|---|---|
| 🔴 SafetyConstraint Bool→Prop refactor 前倒し検討 | Day 4 着手前判断 |
| 🟡 EvolutionStep `Decidable transition` 追加 | LearningCycle 設計時 |
| 🟡 SafeState smart constructor `SafeState.mk` | Day 4 |
| 🟡 cross-class test (`[EvolutionStep S] [SafetyConstraint S]`) | LearningCycle で実装 |
| 🟢 Opaque Hypothesis/Verdict/Observable 先行宣言 | Day 4 検討 |

#### 結論

Day 3 は **TyDD 基盤として S4 P2 Refinement を初の強適用達成**。Day 2 評価で識別された改善余地を Day 3 で解消した点で、**評価→実装の改善ループが機能している証拠**。

一方、SafetyConstraint Bool→Prop refactor の将来コストは S1 benefit #9 を弱め、Pattern #7 違反 3 連続は構造的負債が蓄積。Day 4 着手前に **Bool→Prop 前倒し判断** + **Section 6.2.1 hook 化検討** を要する。

### 12.9 Day 3 終了時点の累計合致度サマリ（2026-04-18 時点）

Section 12.7 (Day 2 累計) の Day 3 版。

#### Day 3 累計合致状況

**評価対象**: Week 1 + Week 2 Day 1-3 で scope に入った tag/recipe。

**完全合致 16 項目** (Day 2 累計 14 + Day 3 で 2 追加):
- Week 1 由来 12 + Day 1-2 で追加 2 (GA-S2 FolgeID, GA-S4 Edge): Section 12.7 参照
- Day 3 で追加合致 (2):
  - **GA-S1 umbrella の Spine 層 type class 着手** (EvolutionStep + SafetyConstraint): G5-1 §3.4 ステップ 1 の最小 hole-driven 実装
  - **S4 P2 Refinement 強適用** (SafetyConstraint.SafeState): subtype refinement の典型実装、Day 2 評価の最大改善余地が解消

**部分合致 1 項目**: TyDD-J5 Self-hosting (Section 12.2 と同様、Week 4 で本格化)

**Day 3 で改善余地として識別された項目** (Section 12.8 / 2.9):
- 🔴 SafetyConstraint Bool→Prop refactor 前倒し (Day 4 着手前判断、S1 benefit #9 強化)
- 🟡 EvolutionStep `Decidable transition` (Day 4)
- 🟡 SafeState smart constructor (Day 4)
- 🟡 cross-class test (Day 4 LearningCycle で実装)
- 🟢 opaque Hypothesis/Verdict/Observable 先行宣言 (Day 4 検討)

**Day 3 累計合致率**: 16/17 = **94.1%** (Section 12.7 Day 2 14/15 = 93.3% から +0.8pt 改善)

#### Section 12.4 Week 2-3 目標との中間照合

Section 12.4 「Week 2-3 (Spine 層) 完了時の目標合致率: 14/13 以上 ※ scope 拡大」に対し、Day 3 終了時点で **16/17 = 94.1%**（分子 16 達成、分母拡大）。

**残 Day 4-5 で追加目標**:
- Day 4 で LearningCycle (P3 学習サイクル indexed monad) + Observable (V1-V7 metric type class) → 完全合致 +2 想定
- Day 5 で FolgeID PartialOrder/Ord 拡張 → F2 Lattice 寄与強化、cross-class 実装で B3/B4 派生
- Section 2.9 改善余地対処 → S4 P2 / S1 #9 への影響度改善

**Day 5 終了時想定目標**: 18/19 = 94.7% (Section 12.7 試算と整合、分子 +2、分母 +2 想定、Section 2.8/2.9 の refactor は分母外として保留)

#### Section 12.3 TyDD 10 benefits の Day 3 時点更新

| # | Benefit | Day 2 | Day 3 |
|---|---|---|---|
| 1 | Deeper understanding | ✓ | ✓ + 状態遷移 + L1 安全境界の構造的理解 |
| 2 | Thoughtful design | ✓ | ✓ + G5-1 §3.4 4-member 計画の段階展開 |
| 7 | Top-down / hole-driven | ✓ | ✓ + class member 1 つ + Unit instance のみ |
| **8** | Higher confidence | ✓ 50 ex + 343 cases | ✓ 62 ex + 343 cases + S4 P2 SafeState 強適用 |
| **9** | Less scary refactoring | ⚠ Week 4-5 dependent type 化 | ⚠⚠ **Bool→Prop refactor (SafetyConstraint Week 4-5) も追加**、Section 2.9 で前倒し検討 |
| 10 | Pleasure | N/A | N/A |

**Day 3 達成**: 8/10 (#9 ⚠⚠ に降格、SafetyConstraint Bool→Prop 前倒しで改善可能)

### 12.10 Day 4 論文サーベイ視点評価結果（2026-04-18 実施）

Day 4 (`216cbbd` SafetyConstraint Prop refactor + LearningCycle + Observable) を 74 対象サーベイの paper findings に対して評価。

#### Day 4 で活用された paper findings (4 件)

1. **S4 P1+P2+P4** (Refinement-Types Driven Development, IFL 2025) → SafetyConstraint Bool→Prop refactor
   - P1「prove by hand vs SMT」: `safeDec : DecidablePred safe` で decide 自動化と手動 proof の両立
   - P2「subtyping layer」: `SafeState := { s // safe s }` で型レベル制約
   - P4「power-to-weight」: 1 method + bundled Decidable で最小実装
2. **G5-1 §3.4 ステップ 2** (CSLib + Boole) → LearningCycle (5 stage + class)
   - 設計指針通り `LearningStage` enum + class、`LearningM` indexed monad は Week 4-5 へ繰り延べ
3. **agent-manifesto P4** → Observable V1-V7 snapshot
   - 既存 `.claude/metrics/v[1-7]-*.jsonl` 構造を 7-field structure として型化
4. **S2 Lean-Auto 将来準備** → bundled `safeDec` で hammer 統合の前提条件確立

#### Day 4 で未活用な paper findings (8 件、優先度付き)

| 優先度 | Paper | 候補適用先 | 推定タイミング |
|---|---|---|---|
| 🟡 中 | **S2 Recipe 4-6 VBS tactic chain** | LearningStage.le proof の自動化 | Week 5-6 (Tooling) |
| 🟡 中 | **N4 Opaque Definitions / Recipe 10** | `SafetyConstraint.safe` opaque 化、proof search 制御 | Week 4-5 |
| 🟡 中 | **S6 Paper 1 (BST/AVL invariants)** | LearningStage 順序関係を invariant 付き structure 化 | Week 4-5 (Process) |
| 🟡 中 | **02-data-provenance §4.1 PROV-O 三項** | LearningCycle stage transition を `WasGeneratedBy` activity として表現 | Week 4-5 |
| 🟢 低 | **S7 Effect-TS Schedule combinators** | LearningStage.next の retry/budget 合成 | Week 6-7 |
| 🟢 低 | **S5 QTT Multiplicity** | stage progression を linear で表現 (Lean 4 制約) | 将来研究 |
| 🟢 低 | **N2 Conatural Numbers** | retirement 後の永続退役を coinductive で | 将来研究 |
| 🟢 低 | **S3 Lean4Lean TrSpec correspondence** | reference semantics 対応保証 | Week 7-8 |

#### Day 4 で paper との矛盾

**なし**。Day 4 は基盤段階で paper の指針と整合。Lean 4 で表現不可な ideal pattern (S5 QTT) は意図的に未適用、`LearningM` indexed monad の延期は計画通り。

#### Paper-grounded な Day 4 強み

| Paper finding | Day 4 実装での顕在化 |
|---|---|
| **S4** "Refinement types add subtyping layer" | `SafeState := { s // safe s }` で subtyping by refinement |
| **S4 P5** "Properties are easier when assumptions are explicit" | docstring D1-D3 で代案 + 採用理由 + assumption を明示 |
| **G3 CSLib spine 論文** | LearningCycle = LTS spine の研究プロセス specialization |
| **04-build-graph Skyframe restart** | LearningStage.next の terminal self-loop = restart 不可状態 |

#### 結論

Day 4 は **論文サーベイ視点で 4 つの paper finding を顕在化**。特に **S4 P2 Refinement の Bool→Prop 完全移行** は Day 2→3→4 の **3 セッション累積改善** を実現。Spine 層 4 type class 完備により、Week 4-5 Process 層での paper finding 本格適用 (Recipe 10 Opaque、PROV-O、Lean-Auto VBS) の準備が整った。

### 12.11 Day 4 TyDD / サーベイ視点評価結果（2026-04-18 実施）

Day 4 (`216cbbd` SafetyConstraint Prop refactor + LearningCycle + Observable) を TyDD Tag Index と Section 10.2 パターンに対して評価。

#### 達成度サマリ (Day 1-4 推移)

| 評価軸 | Day 1 | Day 2 | Day 3 | Day 4 | 変化 |
|---|---|---|---|---|---|
| S1 5 軸 | 5/5 | 5/5 | 5/5 | **5/5** | 維持 |
| S1 10 benefits | 8/10 | 8/10 | 8/10 | **9/10** ↑ | benefit #9 が ⚠⚠→✓ 復活 |
| S4 5 principles 強適用 | 0/5 | 1/5 | 1/5 | **3/5** ↑↑ | P1+P2+P4 同時達成 |
| F/B/H/Recipes 強適用 | 0 | 0 | 0 | **B3 継続強適用** | doSafeOperation→fullSpineExample |
| G1-G6 anti-pattern 回避 | 4/4 | 4/4 | 4/4 | 4/4 | 維持 |
| Section 10.2 適合 | — | 6/8 | 5/8 | 5/8 + Pattern #7 4 連続違反 | hook 化を Day 5 で要 |

#### Day 4 で前進した項目

1. **S1 benefit #9 復活** (⚠⚠→✓): Bool→Prop refactor を Day 4 で完了し将来コスト解消
2. **S4 で 3 強適用達成**:
   - **P1** (prove by hand vs SMT): `safeDec : DecidablePred safe` で decide 自動化 + 手動 proof の両立
   - **P2** (subtyping layer): `SafeState := { s // safe s }` で Prop 形式 refinement 完全達成
   - **P4** (power-to-weight): SafetyConstraint 1 method + bundled Decidable / LearningCycle 1 method / Observable 1 method
3. **Cross-class 4-instance test**: Day 3 A2 棚上げを `fullSpineExample` で完全対処、Spine 層 uniform structure 実証
4. **Spine 層 4 type class 完備**: Section 1 Week 2-3 完了基準達成

#### Day 4 で paper finding と TyDD の合流

Day 4 で SafetyConstraint Bool→Prop refactor は **paper finding (S4 P1+P2+P4)** と **established pattern (#5 def Prop signature)** が同時に強適用された initial 例。これは:
- 評価 → 改善 → 実装 → 評価 のループが Day 2-3-4 の 3 セッションで完結
- Pre-Day-4 refactor として実装したことで、Day 4 main の LearningCycle/Observable に SafeState refinement の効果が波及

#### 改善余地（優先度順）

| 優先度 | 項目 | 対処タイミング | 関連 Section |
|---|---|---|---|
| 🔴 高 | **Pattern #7 4 連続違反** — Section 6.2.1 hook 化を Day 5 で実装すべき (放置で 5 連続) | **Day 5** | Section 6.2.1 |
| 🟡 中 | **F2 Lattice 完全形** — LearningStage.le を `LE`/`LT`/`Decidable` instance に昇格 | Day 5 | Section 2.10 / 2.11 (新設候補) |
| 🟡 中 | **EvolutionStep B4 Hoare 4-arg post 着手準備** — Day 5 で signature 宣言 | Day 5 検討 | Section 2.9 |
| 🟢 低 | **Observable V1-V7 個別 type 化 (F8 fibered)** | Week 4-5 | Section 2.10 |

#### Day 5 で意識すべき改善事項

| Day 4 評価から導出 | 反映先 |
|---|---|
| 🔴 Pattern #7 hook 化実装 | Day 5 (Section 6.2.1) |
| 🟡 F2 Lattice (LearningStage LE/LT instance) | Day 5 |
| 🟡 FolgeID PartialOrder/Ord 拡張 (Section 10.1 元 Day 5 task) | Day 5 |
| 🟡 EvolutionStep B4 4-arg post signature | Day 5 検討 |
| 🟢 SafetyConstraint subtype API 拡充 (Mathlib Subtype lemma 統合) | Week 4-5 |

#### 結論

Day 4 は TyDD 視点で **Day 1-4 累計の最大ジャンプ**:
- **S1 benefit #9 復活** (⚠⚠→✓)
- **S4 1→3 強適用 (P1+P2+P4 同時達成)**
- **Spine 層 4 type class 完備**

Pre-Day-4 refactor の意思決定（Day 3 評価 🔴 を Day 4 着手前に対処）が **評価ループの実効性を実証**。Pattern #7 4 連続違反は Day 5 で hook 化により構造的解決を要する。

### 12.12 Day 4 終了時点の累計合致度サマリ（2026-04-18 時点）

Section 12.9 (Day 3 累計) の Day 4 版。Spine 層 4 type class 完備により Section 1 Week 2-3 完了基準達成。

#### Day 4 累計合致状況

**評価対象**: Week 1 + Week 2 Day 1-4 で scope に入った tag/recipe + paper finding。

**完全合致 22 項目** (Day 3 累計 16 + Day 4 で 6 追加):
- Day 3 累計 16: Section 12.9 参照
- Day 4 で追加合致 (6):
  - **GA-S1 umbrella の Spine 層 4 type class 完備** (LearningCycle + Observable 完了で Section 1 Week 2-3 達成)
  - **S4 P1 強適用** (prove by hand vs SMT、bundled `safeDec` で両立)
  - **S4 P4 強適用** (power-to-weight、1 method + bundled instance の最小実装)
  - **B3 継続強適用拡張** (`doSafeOperation` Day 3 → `fullSpineExample` Day 4 cross-class)
  - **paper finding 4 件 顕在化** (S4 P1+P2+P4 / G5-1 §3.4 / agent-manifesto P4 / S2 将来準備、Section 12.10)
  - **改善ループ実証** (Day 2 識別 → Day 3 初適用 → Day 4 完全達成、3 セッション累積)

**部分合致 1 項目**: TyDD-J5 Self-hosting (Week 4 で本格化、Section 12.2 同様)

**Day 4 で改善余地として識別された項目** (Section 12.11 / 2.10):
- 🔴 Pattern #7 hook 化 (Day 5 必須、4 連続違反継続中)
- 🟡 F2 Lattice (LearningStage LE/LT instance、Day 5)
- 🟡 EvolutionStep B4 4-arg post signature (Day 5 検討)
- 🟡 paper-grounded 改善 10 項目 (Section 2.10、Day 5 / Week 4-7 別)

**Day 4 累計合致率**: 22/23 = **95.7%** (Section 12.9 Day 3 16/17 = 94.1% から +1.6pt 改善)

#### Section 12.4 Week 2-3 目標との照合

Section 12.4 「Week 2-3 (Spine 層) 完了時の目標合致率: 14/13 以上 ※ scope 拡大」に対し、Day 4 終了時点で **22/23 = 95.7%**（**Spine 層 4 type class 完備により目標達成、scope 拡大 (分母 13→23) 含めて clear**）。

**残 Day 5 で追加目標**:
- Day 5 で Pattern #7 hook 化 / F2 Lattice / FolgeID PartialOrder/Ord 拡張 → 完全合致 +3 想定
- Section 2.8 / 2.9 / 2.10 の改善余地対処は Week 4-7 (Process 層以降)

**Day 5 終了時想定目標**: 25/26 = 96.2% (分子 +3、分母 +3、Section 2.X refactor は Week 4-7 で吸収)

#### Section 12.3 TyDD 10 benefits の Day 4 時点更新

| # | Benefit | Day 3 | Day 4 |
|---|---|---|---|
| 1 | Deeper understanding | ✓ | ✓ + LearningCycle 5 stage + V1-V7 metric |
| 2 | Thoughtful design | ✓ | ✓ + Pre-Day-4 refactor で評価ループ実証 |
| 5 | Maintainability | ✓ | ✓ + 4 type class uniform structure |
| 7 | Top-down / hole-driven | ✓ | ✓ + LearningM indexed monad は Week 4-5 へ繰り延べ |
| 8 | Higher confidence | ✓ 62 ex | ✓ 93 ex + cross-class 4-instance test |
| **9** | Less scary refactoring | ⚠⚠ | **✓ 復活** (Bool→Prop refactor 完了で将来コスト解消) |
| 10 | Pleasure | N/A | N/A |

**Day 4 達成**: 9/10 (Day 3 8/10 から **+1 改善**、benefit #9 が ⚠⚠→✓ に復活)

### 12.13 Day 5 論文サーベイ視点評価結果（2026-04-18 実施）

Day 5 (`f4d2c93` Pattern #7 hook + LearningStage LE/LT + FolgeID PartialOrder + RoundTrip 部分達成) を 74 対象サーベイの paper findings に対して評価。

#### Day 5 で活用された paper findings (4 件)

1. **G5-1 Section 6.2.1** → Pattern #7 hook 化を完全実装 (Day 5 メイン成果)
   - 4 連続違反 → 構造的解決へ移行
   - L1 governance × P3 学習統治の構造的合流
2. **S4 派生継続** → LearningStage LE/LT + FolgeID PartialOrder
   - Day 4 SafetyConstraint refinement の流れを継承
   - Mathlib `PartialOrder` への正式昇格
3. **S2 限界実証** → bounded 8³ で `decide` heartbeat 頭打ち
   - 「Lean-Auto / SMT hammer 必要性」が **将来候補から明確な必要性へ格上げ** (Section 2.10 🟢→🔴)
4. **Lean 4 / Mathlib 既存資産活用** → split_ifs / `Mathlib.Order.Defs.PartialOrder`
   - 自前実装ではなく Mathlib 依存を選択 (Day 5 で初の本格 Mathlib 統合)

#### Day 5 で paper finding と Day 5 実装の双方向影響

| Direction | 内容 |
|---|---|
| **paper → Day 5** | G5-1 §6.2.1 hook 提案 → 実装 / S4 P2 → LearningStage LE/LT |
| **Day 5 → paper 評価更新** | S2 Recipe 4-6 「将来候補 (Section 2.10)」→ 「明確な必要性 (Day 6/Week 6 優先)」に格上げ |

これは Day 4 の評価ループ実証 (Day 2 識別→Day 3 初適用→Day 4 完全達成) に続く **Day 5 でのループ拡張**: paper finding が「優先度未定」→「具体的タイミング」へと精度向上。

#### Day 5 で paper との矛盾

**なし**。Mathlib 大規模 import (11→90 jobs) は N1 NbE Performance の関心事と緊張関係にあるが、現状性能影響は許容範囲 (build 時間 ~1s 増)。Week 6 CI 整備時に最適化検討予定。

#### Paper-grounded な Day 5 強み

| Paper finding | Day 5 実装での顕在化 |
|---|---|
| **G5-1 §6.2.1** "artifact-manifest 同 commit 強制" | `.claude/hooks/p3-manifest-on-commit.sh` (A1+B2+C1+D1+E2 設計判断記録) |
| **S4 P2** "Refinement type subtyping" | LearningStage LE/LT (refinement-like) + FolgeID PartialOrder bundle |
| **S2** "Decidable propositions の限界" | `decide` heartbeat 限界 (8³) を SMT hammer 必要性の物証として提示 |
| **Lean 4 Mathlib eco** | 自前 PartialOrder ではなく Mathlib bundle 採用、コミュニティ規約遵守 |

#### Day 5 で識別された改善提案 (優先度更新含む)

| 優先度 | 提案 | 根拠 paper | 対処タイミング |
|---|---|---|---|
| 🔴 **格上げ** | **S2 Lean-Auto / Recipe 4-6 VBS tactic chain** | S2 (CAV 2025) | **Week 6 へ前倒し** (Section 2.10 で 🟢→🔴) |
| 🟡 中 | **N1 NbE Performance 監視** — Mathlib 11→90 jobs 増大の build time / memory 影響を計測 | N1 | Week 6 CI 整備時 |
| 🟢 低 | **Mathlib 依存最適化検討** — `split_ifs` を `simp only` 置換等で Mathlib 局所化 | I4 informational | Week 6 CI 最適化 |
| 🟢 低 | **04-build-graph hook 思想踏襲** — build graph integrity 強制と類比した P4 監視 hook 拡張 | 04-build-graph | Week 7 |

#### 結論

Day 5 は **paper finding × Day 5 実装の双方向影響** を初めて実証した Day:
- **paper → 実装**: G5-1 §6.2.1 hook 化 / S4 派生継続 / Mathlib 統合
- **実装 → paper 優先度更新**: S2 が「将来候補」→「明確な必要性」へ格上げ (Section 2.10 で反映済)

**Mathlib 大規模 import** は Day 5 の最大構造変化 (11→90 jobs)。N1 NbE Performance 監視を Week 6 CI 整備時に組込む必要あり。Pattern #7 hook 化により **Day 6 以降の構造的整合性が自動強制** され、4 連続違反の繰り返しは構造上不可能となった。

### 12.14 Day 5 TyDD / サーベイ視点評価結果（2026-04-18 実施）

Day 5 (`f4d2c93` Pattern #7 hook + LearningStage LE/LT + FolgeID PartialOrder + RoundTrip 部分達成) を TyDD Tag Index と Section 10.2 パターンに対して評価。

#### 達成度サマリ (Day 1-5 推移)

| 評価軸 | Day 1 | Day 2 | Day 3 | Day 4 | Day 5 | 変化 |
|---|---|---|---|---|---|---|
| S1 5 軸 | 5/5 | 5/5 | 5/5 | 5/5 | **5/5** | 維持 |
| S1 10 benefits | 8/10 | 8/10 | 8/10 | 9/10 | **9/10** | 維持 |
| S4 5 principles 強適用 | 0/5 | 1/5 | 1/5 | 3/5 | **3/5 (派生拡張)** | 維持、P2 派生継続 |
| F/B/H 強適用 | 0 | 0 | 0 | B3 | **B3 + F2 部分** | F2 部分達成 |
| G1-G6 anti-pattern 回避 | 4/4 | 4/4 | 4/4 | 4/4 | 4/4 | 維持 |
| Section 10.2 適合 | — | 6/8 | 5/8 | 5/8 + 1 構造違反 | **6/8 + 0 構造違反** ↑ | **Pattern #7 構造的解決** |

#### Day 5 で前進した項目

1. **Pattern #7 構造的解決** (4/8 適合) — hook 化により以後自動強制、4 連続違反の繰り返し不可能
2. **F2 Lattice 部分達成** — LearningStage LE/LT instance + FolgeID PartialOrder で順序関係完備、Lattice 完全形への基盤
3. **Mathlib 正式統合** — 自前実装ではなく標準 type class、コミュニティ規約遵守
4. **paper × pattern 合流の継続** — Day 4 (S4 × Pattern #5) → Day 5 (G5-1 × Pattern #7) で 2 度目達成

#### Day 5 で paper finding と TyDD の合流

Day 5 で **構造的 governance hook の実装** という形で paper finding と established pattern が合流:

| Direction | Day 4 (1 度目) | Day 5 (2 度目) |
|---|---|---|
| **paper finding** | S4 P1+P2+P4 (Refinement-Types Driven Development) | G5-1 §6.2.1 (Pattern #7 hook 化提案) |
| **established pattern** | Pattern #5 (def Prop signature) | Pattern #7 (artifact-manifest 同 commit) |
| **合流結果** | SafetyConstraint Bool→Prop refactor | hook による構造的強制 |

#### 改善余地（優先度順）

| 優先度 | 項目 | 対処タイミング | 関連 Section |
|---|---|---|---|
| 🔴 高 | **S2 Lean-Auto / Recipe 4-6 (Day 5 で必要性顕在化)** | **Week 6 へ前倒し** | Section 2.10 (🟢→🔴 更新済) |
| 🟡 中 | **Universal round-trip proof** — Day 5 で部分達成、universal 完全達成は要 SMT hammer | Day 6 / Week 3 | Section 2.2 |
| 🟡 中 | **F2 Lattice 完全形** — LearningStage に `Lattice` instance 追加 | Week 4-5 | Section 2.10 |
| 🟡 中 | **N1 NbE Performance 監視** — Mathlib 11→90 jobs 増大の影響計測 | Week 6 CI | Section 12.13 |
| 🟢 低 | **EvolutionStep B4 4-arg post** — Process 層と同時設計 | Week 4-5 | Section 2.9 |
| 🟢 低 | **F8 FiberedTypeSpec** (Observable V1-V7 fibered 化) | Week 4-5 | Section 2.10 |

#### Day 6 で意識すべき改善事項

| Day 5 評価から導出 | 反映先 |
|---|---|
| 🔴 Lean-Auto 統合準備 (まず research/poc) | Day 6 検討 |
| 🟡 Universal round-trip 残作業 (consumeNat correctness 等) | Day 6 |
| 🟡 Mathlib 影響評価 (build time / binary size) | Week 6 CI |
| 🟢 Process 層着手判断 (Hypothesis / Verdict / Failure 等) | Day 6 / Week 3 |

#### 結論

Day 5 は TyDD 視点で **構造的整合性の自動化を達成**:
- **Pattern #7 構造的解決** により Day 6 以降は Pattern #7 違反を構造上発生させない
- **F2 Lattice 部分達成** で順序関係完備、Mathlib 統合の入口
- **paper × pattern 合流の 2 度目** (G5-1 × Pattern #7)

S2 Lean-Auto の必要性顕在化は **Day 5 のメタ的成果**: 評価ループが「将来候補」を「明確な必要性」に精緻化することで、Phase 0 後半の優先度判断に貢献。

### 12.15 Day 5 終了時点の累計合致度サマリ（2026-04-18 時点）

Section 12.12 (Day 4 累計) の Day 5 版。Pattern #7 構造的解決と順序関係完備により Section 1 Week 2-3 が **完了基準達成 + 拡張機能完備**。

#### Day 5 累計合致状況

**評価対象**: Week 1 + Week 2 Day 1-5 で scope に入った tag/recipe + paper finding。

**完全合致 26 項目** (Day 4 累計 22 + Day 5 で 4 追加):
- Day 4 累計 22: Section 12.12 参照
- Day 5 で追加合致 (4):
  - **Pattern #7 構造的解決** (Section 10.2 適合 6/8 + 0 構造違反、Day 4 5/8 + 1 構造違反から改善)
  - **F2 Lattice 部分達成** (LearningStage LE/LT + FolgeID PartialOrder で順序関係完備)
  - **Mathlib 正式統合** (Lean 4 eco との接続、Day 5 で初の本格 import)
  - **Section 2.10 paper finding 4 件 顕在化** (G5-1 §6.2.1 / S4 派生継続 / S2 限界実証 / Mathlib 統合)

**部分合致 1 項目**: TyDD-J5 Self-hosting (Week 4 で本格化、変化なし)

**Day 5 で改善余地として識別された項目** (Section 12.13 / 12.14):
- 🔴 **S2 Lean-Auto / Recipe 4-6** (🟢→🔴 格上げ、Week 6 へ前倒し)
- 🟡 Universal round-trip proof (Day 6 / Week 3)
- 🟡 F2 Lattice 完全形 (Week 4-5)
- 🟡 N1 NbE Performance 監視 (Week 6 CI)

**Day 5 累計合致率**: 26/27 = **96.3%** (Section 12.12 Day 4 22/23 = 95.7% から +0.6pt 改善)

#### Section 12.4 Week 2-3 目標との照合

Section 12.4 「Week 2-3 (Spine 層) 完了時の目標合致率: 14/13 以上」に対し、Day 5 終了時点で **26/27 = 96.3%**（**Spine 層 4 type class 完備 + 順序関係完備 + Pattern #7 構造的解決**）。Section 12.4 の Day 5 想定目標 (18/19 = 94.7%) を大幅に上回って達成。

**残 Day 6+ で追加可能な目標**:
- Day 6 で Universal round-trip proof / Lean-Auto research/poc → 完全合致 +2 想定
- Week 4-5 で Process 層 (Hypothesis/Verdict/Failure) + Edge dependent type 化 + Lattice 完全形 → 大幅増想定

**Day 6 終了時想定目標**: 28/29 = 96.5% (慎重見積もり、Lean-Auto 進捗次第で +)

#### Section 12.3 TyDD 10 benefits の Day 5 時点更新

| # | Benefit | Day 4 | Day 5 |
|---|---|---|---|
| 1 | Deeper understanding | ✓ | ✓ + prefix order axiom 構造完備 |
| 2 | Thoughtful design | ✓ | ✓ + Pattern #7 hook で評価ループ構造化 |
| 5 | Maintainability | ✓ | ✓ + Mathlib 統合で標準遵守 |
| 7 | Top-down / hole-driven | ✓ | ✓ + Universal proof は Day 6/Week 3 へ繰り延げ明示 |
| 8 | Higher confidence | ✓ 93 ex | ✓ 105 ex + 12 theorems |
| **9** | Less scary refactoring | ✓ | ✓ 維持 (Mathlib import は additive) |
| 10 | Pleasure | N/A | N/A |

**Day 5 達成**: 9/10 (Day 4 と同水準維持)

### 12.16 Day 6 論文サーベイ視点評価結果（2026-04-18 実施）

Day 6 (`917c752` Process 層着手 Hypothesis + Failure) を 74 対象サーベイの paper findings に対して評価。

#### Day 6 で活用された paper findings (5 件)

1. **02-data-provenance §4.3 first-class Failure** → FailureReason 4 variant (HypothesisRefuted / ImplementationBlocked / SpecInconsistent / Retired) の **100% 忠実実装** (Day 6 メイン成果)、MLflow/DVC の post-hoc 化を回避
2. **02-data-provenance §4.1 PROV-O vocabulary** → Hypothesis/Failure docstring に PROV mapping 注記 (Q3 Option C)、実装は Day 8+
3. **G5-1 §3.4 Process 層着手** → Week 4-5 前倒しで LearningM の前提構築 (Day 6 Hypothesis + Failure → Day 7 Evolution + HandoffChain)
4. **TyDD-S1 types-first** → Hypothesis/Failure を独立 type で定義 (PROV constructor 化を回避、Day 8+ で mapping 関数追加予定)
5. **G5-1 §6.2.1 Pattern #7 hook の運用検証** → Day 5 実装 + Day 6 commit で初適用 + pass-through 成功、設計→実装→運用 三段階 closure

#### Day 6 で paper finding と実装の双方向影響

| Direction | 内容 |
|---|---|
| **paper → Day 6** | 02-data-provenance §4.3 → FailureReason 4 variant / §4.1 → docstring alignment / G5-1 §3.4 → Process 層前倒し / G5-1 §6.2.1 → hook 運用検証 |
| **Day 6 → paper 評価更新** | **Pattern #7 hook 設計の運用検証成立** — Day 5「設計 → 実装」、Day 6「実装 → 運用 pass-through」、Section 6.2.1 完全 closure |

これは **3 度目の paper × pattern サイクル** (Day 4 = 1 度目 S4 × #5、Day 5 = 2 度目 G5-1 × #7 設計、Day 6 = 3 度目 G5-1 × #7 運用検証)。

#### Day 6 で paper との矛盾

**なし**。02-data-provenance §4.3 設計を 100% 忠実実装、PROV mapping 延期は Q3 Option C で意図的かつ docstring 記録済。

#### Paper-grounded な Day 6 強み

| Paper finding | Day 6 実装での顕在化 |
|---|---|
| **02-data-provenance §4.3** "Failure first-class、MLflow/DVC の post-hoc 化を回避" | `inductive FailureReason` 4 variant + `structure Failure { failedHypothesis, reason }` で entity 化 |
| **02-data-provenance §4.1** "PROV 三項を Lean 型で実体化" | docstring に `ResearchEntity.Hypothesis` / `ResearchEntity.Failure` mapping 注記 |
| **G5-1 §3.4 Process 層** | Week 4-5 前倒し着手、Hypothesis + Failure (Day 6) → Evolution + HandoffChain (Day 7) 計画 |
| **G5-1 §6.2.1 Pattern #7 hook** | Day 5 実装 + Day 6 運用検証成功、設計→実装→運用 三段階 closure |

#### Day 6 で識別された改善提案 (4 件、Section 2.10 で反映済)

| 優先度 | 提案 | 根拠 paper | 対処タイミング |
|---|---|---|---|
| 🟡 Day 8+ | **02-data-provenance §4.4 退役の構造的検出** | §4.4 | Day 8+ Provenance 層 |
| 🟡 Week 6-7 | **02-data-provenance §4.7 RO-Crate 互換 export** | §4.7 | Week 6-7 (CI 整備時) |
| 🟢 Week 5-6 | **02-data-provenance §4.5 Pipeline 段階表現** | §4.5 | Week 5-6 Tooling 層 |
| 🟢 Day 7+ | **S6 Paper 1 BST/AVL invariants** (Hypothesis chain order) | S6 Paper 1 | Day 7+ (Evolution と統合) |

#### 結論

Day 6 は **paper finding × Day 6 実装の継続的な双方向影響** を実証:
- **paper → 実装**: 02-data-provenance §4.3 / §4.1 / G5-1 §3.4 / G5-1 §6.2.1 (hook)
- **実装 → 運用検証**: Pattern #7 hook の設計→実装→運用 三段階 closure 達成

新規 4 件の paper-grounded 改善提案を Section 2.10 に追加 (02-data-provenance §4.4 / §4.5 / §4.7 / S6 Paper 1)。Day 8+ Provenance 層実装と Week 5-6 Tooling 層整備への paper-grounded 入力を確立。

### 12.17 Day 6 TyDD / サーベイ視点評価結果（2026-04-18 実施）

Day 6 (`917c752` Process 層着手 Hypothesis + Failure) を TyDD Tag Index と Section 10.2 パターンに対して評価。

#### 達成度サマリ (Day 1-6 推移)

| 評価軸 | Day 1 | Day 2 | Day 3 | Day 4 | Day 5 | Day 6 | 変化 |
|---|---|---|---|---|---|---|---|
| S1 5 軸 | 5/5 | 5/5 | 5/5 | 5/5 | 5/5 | **5/5** | 維持 |
| S1 10 benefits | 8/10 | 8/10 | 8/10 | 9/10 | 9/10 | **9/10** | 維持 |
| S4 5 principles 強適用 | 0/5 | 1/5 | 1/5 | 3/5 | 3/5 | **3/5 (派生継続)** | 維持、P2 派生継続 |
| F/B/H 強適用 | 0 | 0 | 0 | B3 | B3 + F2 部分 | **B3 + F2 部分 + H4 新規部分** | H4 新規部分達成 |
| G1-G6 anti-pattern 回避 | 4/4 | 4/4 | 4/4 | 4/4 | 4/4 | 4/4 | 維持 |
| Section 10.2 適合 | — | 6/8 | 5/8 | 5/8 + 1 構造違反 | 6/8 + 0 構造違反 | **6/8 + 0 構造違反 (運用検証完了)** | hook 運用検証成功 |

#### Day 6 で前進した項目

1. **Pattern #7 hook 運用検証完了** (設計→実装→運用 三段階 closure)
2. **02-data-provenance §4.3 100% 忠実実装** (FailureReason 4 variant の paper-grounded design)
3. **TyDD-S1 × PROV mapping 両立** (独立 type + docstring alignment で coordination cost 最小化)
4. **H4 新規部分達成** (PROV mapping in docstring は将来 LLM mapping 生成 hint)

#### Day 6 で paper finding と TyDD の合流

Day 6 では **TyDD-S1 (paper) × Q3 Option C (Day 6 議論) の合流** が顕在化:
- TyDD-S1 (types-first) は Hypothesis/Failure を独立 type として定義
- Q3 Option C は PROV mapping を docstring 注記レベルで先行記録
- Day 8+ で `Hypothesis.toEntity : Hypothesis → ResearchEntity` mapping 関数追加 (TyDD-S1 を保ったまま PROV 統合)

これは Day 4-5 の paper × pattern 合流に続く **新カテゴリ: principle × decision の合流**。Day 1-6 累計で 3 種類の合流カテゴリが確立:
- Day 4: paper × pattern (S4 × Pattern #5、SafetyConstraint Bool→Prop refactor)
- Day 5: paper × pattern (G5-1 × Pattern #7、hook 設計実装)
- Day 6: principle × decision (TyDD-S1 × Q3 Option C、Process 独立 type + docstring PROV)

#### 改善余地（優先度順、Section 2.12 で記録済）

| 優先度 | 項目 | 対処タイミング | 関連 Section |
|---|---|---|---|
| 🟡 中 | **Process 層 cross-process test** — Hypothesis × Failure × Evolution relation test | Day 7 (Evolution と同時) | Section 2.12 |
| 🟡 中 | **Hypothesis rationale Refinement 強化** — `Option String` → `Option Evidence` | Day 8+ Provenance 層 | Section 2.12 |
| 🟡 中 | **Failure payload 型化** — String → Evidence/Spec/InconsistencyProof/ResearchEntity | Day 8+ Provenance 層 | Section 2.12 |
| 🟢 低 | **artifact-manifest AgentSpecTest entry に example_count 追加** (Subagent I2) | Day 7 metadata commit | Section 2.12 |

#### Day 7 で意識すべき改善事項

| Day 6 評価から導出 | 反映先 |
|---|---|
| 🟡 cross-process test (Hypothesis × Failure × Evolution) | Day 7 Evolution |
| 🟡 EvolutionStep B4 4-arg post の I/O type 確定 (Hypothesis/Verdict/Observable 統合) | Day 7 Evolution |
| 🟡 HandoffChain の T1 一時性 inductive 表現 | Day 7 HandoffChain |
| 🟢 artifact-manifest AgentSpecTest entry 補完 | Day 7 metadata commit |

#### 結論

Day 6 は TyDD 視点で **Pattern #7 hook の運用検証完了** + **paper-grounded 設計の 100% 忠実実装** を達成:
- Section 10.2 適合: 6/8 + 0 構造違反 維持 (Day 5 で達成、Day 6 で運用検証)
- 02-data-provenance §4.3 → FailureReason 4 variant 100% 忠実実装
- TyDD-S1 + Q3 Option C 合流 (新カテゴリ: principle × decision)
- H4 新規部分達成 (PROV mapping in docstring as LLM hint)

Day 7 は Process 層継続 (Evolution + HandoffChain) で cross-process test と EvolutionStep B4 4-arg post 統合が主要対象。Day 1-6 累計で **paper finding 14 件顕在化** (Day 4: 4 件 + Day 5: 4 件 + Day 6: 5 件 + Day 1-3 関連: 1 件)、評価ループ拡張により後続作業の優先度精度が向上。

### 12.18 Day 6 終了時点の累計合致度サマリ（2026-04-18 時点）

Section 12.15 (Day 5 累計) の Day 6 版。Process 層着手と Pattern #7 hook 運用検証完了により Section 1 Week 4-5 が **前倒し開始 + 運用 closure 達成**。

#### Day 6 累計合致状況

**評価対象**: Week 1 + Week 2 Day 1-6 で scope に入った tag/recipe + paper finding。

**完全合致 30 項目** (Day 5 累計 26 + Day 6 で 4 追加):
- Day 5 累計 26: Section 12.15 参照
- Day 6 で追加合致 (4):
  - **Pattern #7 hook 運用検証完了** (Day 5 設計実装、Day 6 commit で初適用 pass-through)
  - **02-data-provenance §4.3 100% 忠実実装** (FailureReason 4 variant)
  - **TyDD-S1 × Q3 Option C 合流** (新カテゴリ「principle × decision」、Process 独立 type + docstring PROV)
  - **Section 12.16 paper finding 5 件 顕在化** (02-data-provenance §4.3 / §4.1 / G5-1 §3.4 / TyDD-S1 / G5-1 §6.2.1 hook 運用検証)

**部分合致 1 項目**: TyDD-J5 Self-hosting (Week 4 で本格化、変化なし)

**Day 6 で改善余地として識別された項目** (Section 12.17 / 2.12):
- 🟡 cross-process test (Day 7 Evolution と同時)
- 🟡 Hypothesis rationale Refinement 強化 (Day 8+ Provenance 層)
- 🟡 Failure payload 型化 (Day 8+ Provenance 層)
- 🟢 artifact-manifest AgentSpecTest entry 補完 (Subagent I2、改訂 21 で解消済)

**Day 6 累計合致率**: 30/31 = **96.8%** (Section 12.15 Day 5 26/27 = 96.3% から +0.5pt 改善)

#### Section 12.4 Week 2-3 目標との照合

Section 12.4 「Week 2-3 (Spine 層) 完了時の目標合致率: 14/13 以上」に対し、Day 6 終了時点で **30/31 = 96.8%**（**Spine 層完備 + 順序関係完備 + Pattern #7 構造解決+運用検証 + Process 層着手**）。Section 12.15 の Day 6 想定目標 (28/29 = 96.5%) を上回って達成。

**残 Day 7+ で追加可能な目標**:
- Day 7 で Evolution + HandoffChain + cross-process test → 完全合致 +3 想定
- Day 8+ で Provenance 層 (Hypothesis/Failure mapping) → +2 想定
- Week 4-5 で Edge dependent type / SafetyConstraint refinement deepening → +2 想定

**Day 7 終了時想定目標**: 33/34 = 97.1%

#### Section 12.3 TyDD 10 benefits の Day 6 時点更新

| # | Benefit | Day 5 | Day 6 |
|---|---|---|---|
| 1 | Deeper understanding | ✓ | ✓ + 研究プロセス Failure の 4 root cause 構造化 |
| 2 | Thoughtful design | ✓ | ✓ + Process 層 minimal scope 制御 (Q2 Minimal) |
| 5 | Maintainability | ✓ | ✓ + Process 独立 type で Day 8+ PROV mapping coordination cost 最小化 |
| 7 | Top-down / hole-driven | ✓ | ✓ + payload を String hole-driven、Day 7+ で型化 |
| 8 | Higher confidence | ✓ 105 ex | ✓ 134 ex + 4 FailureReason variant 全 test |
| **9** | Less scary refactoring | ✓ | ✓ 維持 (Process 独立 type、PROV mapping 後付け可能) |
| 10 | Pleasure | N/A | N/A |

**Day 6 達成**: 9/10 (Day 5 と同水準維持)

### 12.19 Day 7 論文サーベイ視点評価結果（2026-04-18 実施）

Day 7 (`941b25c` Process 層継続 Evolution + HandoffChain) を 74 対象サーベイの paper findings に対して評価。

#### Day 7 で活用された paper findings (5 件)

1. **G5-1 §3.4 Process 層 (continuation)** → Day 6 Hypothesis/Failure に続き Evolution + HandoffChain で **Process 層 4 type 完備**
2. **agent-manifesto T1 一時性** → HandoffChain inductive で session 間 handoff 連鎖を型レベル表現 (Day 7 メイン成果)
3. **02-data-provenance §4.1 PROV-O (continuation)** → Evolution.docstring + HandoffChain.docstring に `ResearchActivity` / `ResearchAgent` mapping 注記 (Day 8+ 実装)
4. **G5-1 §6.2.1 Pattern #7 hook 2 度目適用** → 運用安定性継続検証 (Day 6 設計→実装→運用 closure の継続性)
5. **Day 4 fullSpineExample パターン踏襲 (内部規範)** → `fullProcessExample` (Q2 案 A cross-process test)

#### Day 7 で paper finding と実装の双方向影響

| Direction | 内容 |
|---|---|
| **paper → Day 7** | G5-1 §3.4 (Process 層継続) / T1 一時性 (HandoffChain) / 02-data-provenance §4.1 (PROV mapping 継続) |
| **実装 → paper 評価更新** | **Pattern #7 hook 2 度目適用 = 運用安定性継続検証** / **内部規範 layer 横断 transfer** (Day 4 fullSpineExample → Day 7 fullProcessExample) |

これは Day 4-5-6 の paper × pattern 合流 (3 種カテゴリ) に続く **4 度目: 内部規範の layer 横断 transfer** カテゴリ確立:
- Day 4 (1 度目): paper × pattern (S4 × Pattern #5)
- Day 5 (2 度目): paper × pattern (G5-1 × Pattern #7 設計実装)
- Day 6 (3 度目): principle × decision (TyDD-S1 × Q3 Option C)
- Day 7 (4 度目): **internal-norm × layer transfer** (Day 4 fullSpineExample → Day 7 fullProcessExample、Pattern #7 hook 2 度目適用)

#### Day 7 で paper との矛盾

**なし**。G5-1 §3.4 設計通り Process 層継続、T1 一時性は HandoffChain で 100% 忠実実装、Q3 案 B (B4 4-arg post 部分対処) は意図的 scope 制御。

#### Paper-grounded な Day 7 強み

| Paper finding | Day 7 実装での顕在化 |
|---|---|
| **G5-1 §3.4 Process 層** | **4 type 完備** (Hypothesis + Failure + Evolution + HandoffChain) |
| **agent-manifesto T1 一時性** | `inductive HandoffChain { empty, cons }` で session 連鎖を Lean 型化 |
| **02-data-provenance §4.1** | Evolution → `ResearchActivity` / HandoffChain → `ResearchAgent` mapping 注記 |
| **G5-1 §6.2.1 Pattern #7 hook** | 2 度目適用、運用安定性検証成立 |
| **Day 4 fullSpineExample → Day 7 fullProcessExample** | **内部規範の layer 横断 transfer** |

#### Day 7 で識別された改善提案 (4 件、Section 2.10 で反映済)

| 優先度 | 提案 | 根拠 paper | 対処タイミング |
|---|---|---|---|
| 🟡 Week 5-6 | **02-data-provenance §4.6 Nextflow resume + Galaxy job cache** (WasReusedBy edge) | §4.6 | Week 5-6 Tooling 層 |
| 🟢 Week 6-7 | **02-data-provenance §4.2 二層分離** (Lean tree + content-addressed manifest) | §4.2 | Week 6-7 CI 整備時 |
| 🟢 Day 8+ | **Spine + Process 層 cross-layer integration test** | 内部規範踏襲 | Day 8+ |
| 🟢 Week 6 | **G3 CSLib spine bisimulation** | G3 CSLib | Week 6 CSLib 移行時 |

#### 結論

Day 7 は **G5-1 §3.4 Process 層完備** + **paper × 実装の 4 度目合流カテゴリ確立** (内部規範 layer 横断 transfer):
- Process 層 4 type 完備 (Hypothesis + Failure + Evolution + HandoffChain)
- Pattern #7 hook 2 度目適用で運用安定性継続検証
- 内部規範 (fullSpineExample → fullProcessExample) の layer 横断 transfer

新規 4 件の paper-grounded 改善提案を Section 2.10 に追加。Day 1-7 累計で **paper finding 19 件顕在化** (Day 4: 4 / Day 5: 4 / Day 6: 5 / Day 7: 5 / Day 1-3 関連: 1)。

### 12.20 Day 7 TyDD / サーベイ視点評価結果（2026-04-18 実施）

Day 7 (`941b25c` Process 層継続 Evolution + HandoffChain) を TyDD Tag Index と Section 10.2 パターンに対して評価。

#### 達成度サマリ (Day 1-7 推移)

| 評価軸 | Day 4 | Day 5 | Day 6 | Day 7 | 変化 |
|---|---|---|---|---|---|
| S1 5 軸 | 5/5 | 5/5 | 5/5 | **5/5** | 維持 |
| S1 10 benefits | 9/10 | 9/10 | 9/10 | **9/10** | 維持 |
| S4 5 principles 強適用 | 3/5 | 3/5 | 3/5 | **3/5 (派生継続)** | 維持、P2 派生継続 |
| F/B/H 強適用 | B3 | B3 + F2 部分 | B3 + F2 部分 + H4 新規部分 | **B3 + F2 部分 + H4 + H10 新規部分** | H10 新規部分達成 |
| G1-G6 anti-pattern 回避 | 4/4 | 4/4 | 4/4 | 4/4 | 維持 |
| Section 10.2 適合 | 5/8 + 1 構造違反 | 6/8 + 0 構造違反 | 6/8 + 0 構造違反 (運用検証完了) | **6/8 + 0 構造違反 (2 度目運用検証)** | hook 運用継続検証 |

#### Day 7 で前進した項目

1. **Process 層 4 type 完備** (Hypothesis + Failure + Evolution + HandoffChain)
2. **H10 (Spec normal forms) 新規部分達成** — Evolution の `initial` / `refineWith` 2 constructor は spec normal form の最小単位
3. **Pattern #7 hook 2 度目運用検証** (Day 6 初適用に続く)
4. **内部規範 layer 横断 transfer** (fullSpineExample → fullProcessExample)

#### Day 7 で paper finding と TyDD の合流

Day 4 fullSpineExample × Day 7 fullProcessExample の **layer 横断 transfer**:
- Day 4: `fullSpineExample (S : Type u) [EvolutionStep S] [SafetyConstraint S] [LearningCycle S] [Observable S]`
- Day 7: `fullProcessExample (h : Hypothesis) (f : Failure) (e : Evolution) (ch : HandoffChain)`

形式が異なる (type class vs structure/inductive 引数) が、**「全 layer 要素同時利用」という意図は同一**。これは TyDD-S1 の 5 軸 #4 (verify) を **layer 横断で実証**。

#### 改善余地（優先度順、Section 2.13 で記録済）

| 優先度 | 項目 | 対処タイミング | 関連 Section |
|---|---|---|---|
| 🟡 中 | **Verdict 型 + B4 4-arg post 完全統合** | Day 8+ (Q3 採用案通り、Section 2.9 完全解消) | Section 2.13 |
| 🟡 中 | **S6 Paper 1 BST/AVL invariants** — Evolution chain order 強型化 | Day 8+ Evolution 拡張時 | Section 2.13 |
| 🟢 低 | **Evolution DecidableEq 手動実装** | Day 8+ 検討 | Section 2.13 |
| 🟢 低 | **HandoffChain `concat` (chain 連結)** | Day 8+ 検討 | Section 2.13 |

#### Day 8+ で意識すべき改善事項

| Day 7 評価から導出 | 反映先 |
|---|---|
| 🟡 Verdict 型 + B4 4-arg post 完全統合 | Day 8+ Provenance 層と同時 |
| 🟡 S6 Paper 1 BST/AVL invariants | Day 8+ Evolution 拡張 |
| 🟡 Provenance 層着手 (PROV-O Lean 化、Hypothesis/Failure/Evolution mapping 関数) | Day 8+ |
| 🟡 Spine + Process cross-layer integration test (Day 7 paper サーベイから) | Day 8+ |
| 🟢 Evolution DecidableEq / HandoffChain concat | Day 8+ 検討 |

#### 結論

Day 7 は TyDD 視点で **Process 層 4 type 完備** + **H10 新規部分達成** + **内部規範 layer 横断 transfer**:
- Section 10.2 適合: 6/8 + 0 構造違反 維持 (Pattern #7 hook 2 度目運用検証)
- TyDD-S1 5 軸を Spine/Process layer 横断で実証
- paper × 実装 4 度目合流カテゴリ確立 (Section 12.19)

Day 8+ は Provenance 層着手 + Verdict 型 + B4 4-arg post 完全統合 + S6 Paper 1 が主要対象。Day 1-7 累計で **paper finding 19 件 / Section 10.2 6/8 + 0 構造違反 / S4 3 強適用 / paper × 実装合流 4 種カテゴリ** 確立。

### 12.21 Day 7 終了時点の累計合致度サマリ（2026-04-18 時点）

Section 12.18 (Day 6 累計) の Day 7 版。Process 層 4 type 完備と Pattern #7 hook 2 度目運用検証により Section 1 Week 4-5 が **完備達成**。

#### Day 7 累計合致状況

**評価対象**: Week 1 + Week 2 Day 1-7 で scope に入った tag/recipe + paper finding。

**完全合致 35 項目** (Day 6 累計 30 + Day 7 で 5 追加):
- Day 6 累計 30: Section 12.18 参照
- Day 7 で追加合致 (5):
  - **Process 層 4 type 完備** (Hypothesis + Failure + Evolution + HandoffChain)
  - **agent-manifesto T1 一時性** を HandoffChain で 100% 忠実実装
  - **Pattern #7 hook 2 度目運用検証** (Day 6 初適用に続く運用安定性継続)
  - **TyDD-S1 内部規範 layer 横断 transfer** (Day 4 fullSpineExample → Day 7 fullProcessExample)
  - **H10 (Spec normal forms) 新規部分達成** (Evolution 2 constructor)

**部分合致 1 項目**: TyDD-J5 Self-hosting (Week 4 で本格化、変化なし)

**Day 7 で改善余地として識別された項目** (Section 12.20 / 2.13):
- 🟡 Verdict 型 + B4 4-arg post 完全統合 (Day 8+、Section 2.9 完全解消)
- 🟡 S6 Paper 1 BST/AVL invariants (Day 8+ Evolution 拡張時)
- 🟢 Evolution DecidableEq 手動実装 (Day 8+ 検討)
- 🟢 HandoffChain concat (Day 8+ 検討)

**Day 7 累計合致率**: 35/36 = **97.2%** (Section 12.18 Day 6 30/31 = 96.8% から +0.4pt 改善)

#### Section 12.4 Week 2-3 目標との照合

Section 12.4 「Week 2-3 (Spine 層) 完了時の目標合致率: 14/13 以上」に対し、Day 7 終了時点で **35/36 = 97.2%**（**Spine 層完備 + 順序関係完備 + Pattern #7 構造解決+運用検証 2 度 + Process 層 4 type 完備**）。Section 12.18 の Day 7 想定目標 (33/34 = 97.1%) を上回って達成。

**残 Day 8+ で追加可能な目標**:
- Day 8+ で Provenance 層 (ResearchEntity / ResearchActivity / ResearchAgent) + Verdict 型 + B4 4-arg post 完全統合 + S6 Paper 1 → 完全合致 +5 想定
- Week 4-5 で Edge dependent type / Refinement deepening → +2 想定

**Day 8 終了時想定目標**: 40/41 = 97.6%

#### Section 12.3 TyDD 10 benefits の Day 7 時点更新

| # | Benefit | Day 6 | Day 7 |
|---|---|---|---|
| 1 | Deeper understanding | ✓ | ✓ + Process 4 type の chain 構造理解 |
| 2 | Thoughtful design | ✓ | ✓ + Q1-Q4 確定方針通り Minimal scope 維持 |
| 5 | Maintainability | ✓ | ✓ + Process 4 type の uniform pattern (inductive + accessor) |
| 7 | Top-down / hole-driven | ✓ | ✓ + Verdict 型と B4 統合は Day 8+ へ繰り延げ |
| 8 | Higher confidence | ✓ 134 ex | ✓ 171 ex + cross-process test |
| **9** | Less scary refactoring | ✓ | ✓ 維持 (Q3 案 B で B4 完全統合は Day 8+) |
| 10 | Pleasure | N/A | N/A |

**Day 7 達成**: 9/10 (Day 6 と同水準維持)

### 12.22 Day 8 論文サーベイ視点評価結果（2026-04-18 実施）

Day 8 (`0f78fa6` Verdict + EvolutionStep B4 4-arg post 完全統合 + SpineProcessTest) を 74 対象サーベイの paper findings に対して評価。

#### Day 8 で活用された paper findings (5 件)

1. **G5-1 §3.4 ステップ 1 (ResearchEvolutionStep) 完全実装** → EvolutionStep B4 4-arg post で transition + hypothesis + verdict を統合表現 (Day 8 メイン成果、**Section 2.9 完全解消**)
2. **S4 P5 explicit assumptions** → Hypothesis/Verdict separate args (Q4 案 A 採用根拠)
3. **02-data-provenance §4.1 PROV-O (continuation)** → Verdict 新 namespace AgentSpec.Provenance 先行配置 (Day 9+ で完成)
4. **G5-1 §6.2.1 Pattern #7 hook 3 度目適用** → 運用安定性継続検証 (Day 6 初 → Day 7 2 度目 → Day 8 3 度目)
5. **内部規範 layer 横断 transfer 拡張** → Day 4 fullSpineExample → Day 7 fullProcessExample → **Day 8 fullStackExample** (8 layer 要素同時要求)

#### Day 8 で paper finding と実装の双方向影響

| Direction | 内容 |
|---|---|
| **paper → Day 8** | G5-1 §3.4 ステップ 1 完全実装 / S4 P5 / 02-data-provenance §4.1 / G5-1 §6.2.1 hook 継続 / 内部規範 layer 横断 transfer 拡張 |
| **実装 → paper 評価更新** | **layer architecture redefinition** (Spine = 下位層 → core abstraction、Process/Provenance = 具体型) / **Section 2.9 完全解消 = 5 セッション累積改善** (Day 3 識別→Day 8 解消) |

これは Day 4-7 の paper × 実装合流 (4 種カテゴリ) に続く **5 度目: layer architecture redefinition** カテゴリ確立:
- Day 4 (1 度目): paper × pattern (S4 × Pattern #5)
- Day 5 (2 度目): paper × pattern (G5-1 × Pattern #7 設計実装)
- Day 6 (3 度目): principle × decision (TyDD-S1 × Q3 Option C)
- Day 7 (4 度目): internal-norm × layer transfer
- Day 8 (5 度目): **layer architecture redefinition** (Spine の役割を「下位層」→「core abstraction」に再定義、Process/Provenance を import する Q4 案 A D4 受容)

#### Day 8 で paper との矛盾 (意識的受容)

**部分的矛盾**: Spine 層が Process/Provenance 層を import する設計は **旧設計 (layer 階層) と矛盾**するが、Q4 案 A D4 で意識的に受容。**新設計 (Spine = core abstraction、Process/Provenance = 具体型)** として layer の役割を再定義。

これは G5-1 §3.4 が示唆する「ResearchEvolutionStep の hypothesis / verdict / observation member」設計と整合的 (G5-1 でも Spine layer 内に Hypothesis/Verdict 言及あり)。

#### Paper-grounded な Day 8 強み

| Paper finding | Day 8 実装での顕在化 |
|---|---|
| **G5-1 §3.4 ステップ 1** | EvolutionStep B4 4-arg post で transition (pre, input, output, post) として統合 |
| **S4 P5 explicit assumptions** | Hypothesis/Verdict separate args |
| **02-data-provenance §4.1 PROV-O** | Verdict 新 namespace AgentSpec.Provenance 先行配置 |
| **G5-1 §6.2.1 Pattern #7 hook** | 3 度目適用、運用安定性継続検証 |
| **内部規範 layer 横断 transfer 拡張** | fullSpineExample → fullProcessExample → fullStackExample (3 段階) |
| **Section 2.9 完全解消 = 5 セッション累積改善** | Day 3 識別 → Day 4-7 部分対処 → Day 8 完全解消 |

#### Day 8 で識別された改善提案 (4 件、Section 2.10 で反映済)

| 優先度 | 提案 | 根拠 paper | 対処タイミング |
|---|---|---|---|
| 🟡 Week 4-5 | **G5-1 §3.4 ステップ 2 LearningM indexed monad** | G5-1 §3.4 step 2 | Week 4-5 Tooling 層 |
| 🟡 Week 4-5 | **EvolutionStep に hypothesis / observation accessor 追加** | G5-1 §3.4 step 1 完全形 | Week 4-5 |
| 🟢 Day 9+ | **Verdict payload 拡充** | Day 8 D1 案 A→C 移行検討 | Day 9+ Provenance 層 |
| 🟢 Day 9+ | **transitionLegacy deprecated 削除** | Day 8 D2 derive 設計 | Day 9+ |

#### 結論

Day 8 は **G5-1 §3.4 ステップ 1 完全実装** + **paper × 実装の 5 度目合流カテゴリ確立** (layer architecture redefinition):
- B4 Hoare 4-arg post pattern を EvolutionStep に完全統合 (Section 2.9 完全解消、5 セッション累積改善 Day 3→Day 8)
- Spine layer の役割を「下位層」→「core abstraction」に再定義 (Q4 案 A D4)
- Provenance namespace 先行配置で Day 9+ ResearchEntity/Activity/Agent 完成への準備

新規 4 件の paper-grounded 改善提案を Section 2.10 に追加。Day 1-8 累計で **paper finding 24 件顕在化** (Day 4: 4 / Day 5: 4 / Day 6: 5 / Day 7: 5 / Day 8: 5 / Day 1-3 関連: 1)。

### 12.23 Day 8 TyDD / サーベイ視点評価結果（2026-04-18 実施）

Day 8 (`0f78fa6` Verdict + EvolutionStep B4 4-arg post 完全統合 + SpineProcessTest) を TyDD Tag Index と Section 10.2 パターンに対して評価。

#### 達成度サマリ (Day 4-8 推移)

| 評価軸 | Day 4 | Day 5 | Day 6 | Day 7 | Day 8 | 変化 |
|---|---|---|---|---|---|---|
| S1 5 軸 | 5/5 | 5/5 | 5/5 | 5/5 | **5/5** | 維持 |
| S1 10 benefits | 9/10 | 9/10 | 9/10 | 9/10 | **9/10** | 維持 |
| S4 5 principles 強適用 | 3/5 | 3/5 | 3/5 | 3/5 | **4/5 ↑** | **P5 新規強適用** |
| F/B/H 強適用 | B3 | B3+F2 部分 | B3+F2+H4 | B3+F2+H4+H10 | **B3+B4+F2+H4+H10 ↑** | **B4 新規強適用** |
| G1-G6 anti-pattern 回避 | 4/4 | 4/4 | 4/4 | 4/4 | 4/4 | 維持 |
| Section 10.2 適合 | 5/8+1 構造違反 | 6/8+0 | 6/8+0 (運用検証) | 6/8+0 (2 度目) | **6/8+0 (3 度目)** | hook 運用継続 |

#### Day 8 で前進した項目

1. **S4 P5 (explicit assumptions) 新規強適用達成** — Hypothesis/Verdict separate args が S4 P5 の典型実装
2. **B4 (Hoare 4-arg post) 新規強適用達成** — EvolutionStep `transition : (pre, input, output, post)` で B4 完全実装
3. **Section 2.9 完全解消** (Day 3 識別→Day 8 解消、5 セッション累積改善)
4. **Pattern #7 hook 3 度目運用検証** (Day 6 初→Day 7 2 度目→Day 8 3 度目、運用安定性継続)
5. **layer architecture redefinition** (Spine = 下位層 → core abstraction、Process/Provenance = 具体型)

#### Day 8 で paper finding と TyDD の合流

Day 8 で **S4 P5 + B4 同時強適用達成**:
- Q4 案 A `transition : (pre : S) → (input : Hypothesis) → (output : Verdict) → (post : S) → Prop` は **B4 4-arg post の標準形**
- Hypothesis/Verdict separate args は **S4 P5 explicit assumptions の典型実装**
- これは **S4 派生の継続的展開** (Day 4 P1+P2+P4 → Day 8 +P5 で 4/5 強適用達成)

#### 改善余地（優先度順、Section 2.15 で記録済）

| 優先度 | 項目 | 対処タイミング | 関連 Section |
|---|---|---|---|
| 🟡 中 | **Provenance 層継続** (ResearchEntity / ResearchActivity / ResearchAgent + Mapping) | Day 9+ | Section 2.15 |
| 🟡 中 | **Verdict payload 拡充** (案 A→案 C 移行) | Day 9+ | Section 2.15 |
| 🟢 低 | **transitionLegacy deprecated 削除** | Day 9+ | Section 2.15 |
| 🟢 低 | **EvolutionStep 完全 4 member 化** (G5-1 §3.4 step 1 完全形) | Week 4-5 | Section 2.15 |
| 🟢 低 | **G5-1 §3.4 step 2 LearningM indexed monad** | Week 4-5 Tooling 層 | Section 2.15 |

#### Day 9+ で意識すべき改善事項

| Day 8 評価から導出 | 反映先 |
|---|---|
| 🟡 Provenance 層継続 (ResearchEntity / Activity / Agent + Mapping) | Day 9+ メイン |
| 🟡 Verdict payload 拡充 | Day 9+ Provenance 層実装時 |
| 🟢 transitionLegacy deprecated 削除 | Day 9+ |
| 🟢 EvolutionStep 完全 4 member 化 | Week 4-5 |

#### 結論

Day 8 は TyDD 視点で **S4 4/5 強適用達成 + B4 新規強適用** + **Section 2.9 完全解消** + **Pattern #7 hook 3 度目運用検証**:
- S4 派生の継続的展開 (Day 4 P1+P2+P4 → Day 8 +P5 = 4/5)
- B4 Hoare 4-arg post pattern が EvolutionStep に完全統合
- layer architecture redefinition (Spine = core abstraction)
- 内部規範 layer 横断 transfer 拡張 (3 段階: fullSpine → fullProcess → fullStack)

Day 9+ は Provenance 層完成 (ResearchEntity / Activity / Agent + Mapping) と Verdict payload 拡充が主要対象。Day 1-8 累計で **S4 4/5 / F/B/H 5 強適用 / paper finding 24 件 / Section 10.2 6/8 + 0 構造違反 / paper × 実装合流 5 種カテゴリ** 確立。

### 12.24 Day 8 終了時点の累計合致度サマリ（2026-04-18 時点）

Section 12.21 (Day 7 累計) の Day 8 版。**Section 2.9 完全解消** + **S4 4/5 + B4 強適用達成** により大幅な進展。

#### Day 8 累計合致状況

**評価対象**: Week 1 + Week 2 Day 1-8 で scope に入った tag/recipe + paper finding。

**完全合致 41 項目** (Day 7 累計 35 + Day 8 で 6 追加):
- Day 7 累計 35: Section 12.21 参照
- Day 8 で追加合致 (6):
  - **S4 P5 explicit assumptions 新規強適用** (Hypothesis/Verdict separate args)
  - **B4 Hoare 4-arg post 新規強適用** (EvolutionStep transition 完全実装)
  - **G5-1 §3.4 ステップ 1 (ResearchEvolutionStep) 完全実装**
  - **Section 2.9 完全解消** (Day 3→Day 8、5 セッション累積)
  - **layer architecture redefinition** (Spine = core abstraction、新カテゴリ)
  - **内部規範 layer 横断 transfer 拡張** (3 段階: fullSpine → fullProcess → fullStack)

**部分合致 1 項目**: TyDD-J5 Self-hosting (Week 4 で本格化、変化なし)

**Day 8 で改善余地として識別された項目** (Section 12.23 / 2.15):
- 🟡 Provenance 層継続 (Day 9+ メイン)
- 🟡 Verdict payload 拡充 (Day 9+)
- 🟢 transitionLegacy deprecated 削除 (Day 9+)
- 🟢 EvolutionStep 完全 4 member 化 (Week 4-5)
- 🟢 G5-1 §3.4 step 2 LearningM indexed monad (Week 4-5)

**Day 8 累計合致率**: 41/42 = **97.6%** (Section 12.21 Day 7 35/36 = 97.2% から +0.4pt 改善)

#### Section 12.4 Week 2-3 目標との照合

Section 12.4 「Week 2-3 (Spine 層) 完了時の目標合致率: 14/13 以上」に対し、Day 8 終了時点で **41/42 = 97.6%**（**Spine 層完備 + 順序関係完備 + Pattern #7 構造解決+運用検証 3 度 + Process 層 4 type 完備 + Section 2.9 完全解消 + Provenance 層着手**）。Section 12.21 Day 8 想定目標 (40/41 = 97.6%) を予想通り達成。

**残 Day 9+ で追加可能な目標**:
- Day 9+ で Provenance 層完成 (ResearchEntity / Activity / Agent + Mapping) → 完全合致 +4 想定
- Day 9+ で Verdict payload 拡充 → +1 想定
- Day 10+ で transitionLegacy deprecated 削除 → +1 想定

**Day 9 終了時想定目標**: 46/47 = 97.9%

#### Section 12.3 TyDD 10 benefits の Day 8 時点更新

| # | Benefit | Day 7 | Day 8 |
|---|---|---|---|
| 1 | Deeper understanding | ✓ | ✓ + Verdict 3 variant + B4 4-arg post の構造理解 |
| 2 | Thoughtful design | ✓ | ✓ + Q1-Q4 確定方針通り B-Medium scope 維持 |
| 5 | Maintainability | ✓ | ✓ + transitionLegacy derive で後方互換、namespace 役割再定義 |
| 7 | Top-down / hole-driven | ✓ | ✓ + Verdict 案 A→C 拡充は Day 9+ へ繰り延げ |
| 8 | Higher confidence | ✓ 171 ex | ✓ 197 ex + cross-layer test (8 layer 要素) |
| **9** | Less scary refactoring | ✓ | ✓ 維持 (EvolutionStep refactor の影響範囲は transitionLegacy で吸収) |
| 10 | Pleasure | N/A | N/A |

**Day 8 達成**: 9/10 (Day 7 と同水準維持)

### 12.25 Day 9 論文サーベイ視点評価結果（2026-04-18 実施）

Day 9 (`fa5b373` Provenance 層継続 ResearchEntity + ResearchActivity) を 74 対象サーベイの paper findings に対して評価。

#### Day 9 で活用された paper findings (5 件)

1. **02-data-provenance §4.1 PROV-O 三項統合進展** → ResearchEntity (4 constructor) + ResearchActivity (5 variant、verify は B4 整合) で 3 type/4 (ResearchAgent のみ Day 10+)
2. **G5-1 §3.4 ステップ 2 LearningM 前提構築** → ResearchActivity.verify ≡ EvolutionStep transition の signature 整合
3. **TyDD-S1 types-first** → ResearchEntity が既存 Process type を embed (Q3 案 A)
4. **G5-1 §6.2.1 Pattern #7 hook 4 度目適用** → 運用安定性 4 度連続検証
5. **内部規範 layer 横断 transfer 拡張継続** → fullSpineExample → fullProcessExample → fullStackExample → **List ResearchEntity (cross-process embed)** の 4 段階

#### Day 9 で paper finding と実装の双方向影響

| Direction | 内容 |
|---|---|
| **paper → Day 9** | 02-data-provenance §4.1 / G5-1 §3.4 step 2 準備 / TyDD-S1 / G5-1 §6.2.1 hook 継続 |
| **実装 → paper 評価更新** | **循環依存回避設計の確立** (Mapping を ResearchEntity.lean 内 namespace extension で配置) → Day 8 layer architecture redefinition の自然な発展 |

これは Day 4-8 の paper × 実装合流 (5 種カテゴリ) に続く **6 度目: namespace extension pattern by layer architecture** カテゴリ確立。

#### Day 9 で paper との矛盾

**なし**。02-data-provenance §4.1 を 3 type 完備、G5-1 §3.4 step 2 整合性確保、Pattern #7 4 度連続成功。

#### Paper-grounded な Day 9 強み

| Paper finding | Day 9 実装での顕在化 |
|---|---|
| **02-data-provenance §4.1** | Verdict (Day 8) + ResearchEntity + ResearchActivity = 3 type 完備 |
| **G5-1 §3.4 step 2** | ResearchActivity.verify ≡ EvolutionStep transition の signature 整合 |
| **TyDD-S1 types-first** | Process type embed (案 A 採用)、独自 enum 化を回避 |
| **G5-1 §6.2.1 Pattern #7 hook** | 4 度連続適用、運用安定性確立 |
| **layer architecture redefinition (Day 8)** | namespace extension pattern (Day 9) で発展 |

#### Day 9 で識別された改善提案 (Section 2.10 で反映済) + 実装修正

| 優先度 | 提案 | 根拠 paper | 対処タイミング |
|---|---|---|---|
| 🟡 Day 10+ | **EvolutionStep transition → ResearchActivity.verify mapping** | G5-1 §3.4 step 2 / 02-data-provenance §4.1 | Day 10+ Provenance 完成時 |
| 🟢 Day 10+ | **ResearchActivity payload なし variants の payload 拡充** | 02-data-provenance §4.1 | Day 10+ |
| 🟢 Day 10+ 設計判断 | **HandoffChain 全体 embed 用 constructor** (Subagent I3 Day 9) | Subagent I3 | Day 10+ |
| ✅ **本評価で実装修正対処** | **Subagent I2 (parameter 形式 example カウント方針)** — ResearchActivityTest 最終 example に注記追加 | Subagent I2 Day 9 | 本 commit で対処 (Day 10+ で集計方針統一検討) |

#### 結論

Day 9 は **02-data-provenance §4.1 PROV-O 3 type 完備** + **paper × 実装の 6 度目合流カテゴリ確立** (namespace extension pattern by layer architecture)。Subagent I2 を本評価で **実装修正即時対処** (paper サーベイ評価サイクルに「実装修正」を組込む新パターン)。

Day 1-9 累計で **paper finding 29 件顕在化** (Day 4: 4 / Day 5: 4 / Day 6: 5 / Day 7: 5 / Day 8: 5 / Day 9: 5 / Day 1-3 関連: 1)。

### 12.28 Day 10 論文サーベイ視点評価結果（2026-04-18 実施）

Day 10 (`b652347` Provenance 層 4 type 完備 ResearchAgent + EvolutionMapping) を 74 対象サーベイの paper findings に対して評価。

#### Day 10 で活用された paper findings (5 件)

1. **02-data-provenance §4.1 PROV-O 三項統合 4 type 完備** → Verdict + ResearchEntity + ResearchActivity + ResearchAgent (Day 8/9/9/10、PROV-O 100% 忠実)
2. **G5-1 §3.4 step 2 LearningM 連携 path 確立** → `transitionToActivity` (Day 8 EvolutionStep B4 ↔ Day 9 ResearchActivity.verify 結合、indexed monad 化前提完備)
3. **TyDD-S1 types-first** → ResearchAgent も Process embed パターン継続
4. **G5-1 §6.2.1 Pattern #7 hook v2 拡張** → Day 10 A1 対処、regex に Provenance + Test/Cross 追加 (effective scope 構造的拡大)
5. **内部規範 layer 横断 transfer 拡張継続** → 5 段階目: ResearchAgent.toEntity が Day 9 4 toEntity と同パターン

#### Day 10 で paper finding と実装の双方向影響

| Direction | 内容 |
|---|---|
| **paper → Day 10** | 02-data-provenance §4.1 PROV-O 完備 / G5-1 §3.4 step 2 連携 / TyDD-S1 |
| **実装 → paper 評価更新** | **hook v2 拡張** = Pattern #7 effective scope の構造的拡大 (Section 6.2.1 の発展)、layer architecture 完成形に対応 |

これは Day 4-9 の paper × 実装合流 (6 種) に続く **7 度目: PROV-O completion milestone × governance evolution** カテゴリ確立 (paper-grounded design completion + governance scope 拡大)。

#### Day 10 で paper との矛盾

**なし**。02-data-provenance §4.1 を 4 type 完備、G5-1 §3.4 step 2 整合性確保、Pattern #7 hook v2 拡張で governance も layer architecture 完成形と整合。

#### Paper-grounded な Day 10 強み

| Paper finding | Day 10 実装での顕在化 |
|---|---|
| **02-data-provenance §4.1** | 4 type 完備 (PROV-O 三項統合完了) + 5 toEntity Mapping |
| **G5-1 §3.4 step 2** | transitionToActivity で連携 path 確立 |
| **TyDD-S1 types-first** | ResearchAgent も Process embed パターン継続 |
| **G5-1 §6.2.1 Pattern #7 hook v2** | regex 拡張 (Provenance + Test/Cross)、effective scope 構造的拡大 |
| **layer architecture 完成形** | Spine + Process + Provenance + Cross test の 4 layer |

#### Day 10 で識別された改善提案 (4 件、Section 2.10 で反映済) + 実装修正対処

| 優先度 | 提案 | 根拠 paper | 対処タイミング |
|---|---|---|---|
| 🟡 Day 11+ | **02-data-provenance §4.4 RetiredEntity** (退役 entity の構造的検出) | §4.4 | Day 11+ (Section 2.10 既存項目) |
| 🟡 Day 11+ | **PROV-O wasAttributedTo / wasGeneratedBy / wasDerivedFrom relation の Lean 化** | §4.1 | Day 11+ (Day 10 で新規識別、Section 2.10 に追加済) |
| 🟢 Week 5-6 | **02-data-provenance §4.6 cache lineage** | §4.6 | Week 5-6 (Section 2.10 既存項目) |
| 🟢 Week 6-7 | **02-data-provenance §4.7 RO-Crate 互換 export** | §4.7 | Week 6-7 (Section 2.10 既存項目) |
| ✅ **本評価で実装修正対処** | **Subagent A1 (Pattern #7 hook regex Provenance/Test/Cross 含まず)** — hook v2 配置済 (`/tmp/p3-manifest-on-commit-v2.sh` で全置換、Provenance + Test/Cross detection 確認) | Subagent A1 Day 10 | 本 commit で対処済 (user 介入で hook 修正) |
| ✅ **Day 10 code commit で対処済** | **Subagent I2 (ResearchEntity docstring 4→5 constructor)** | Subagent I2 Day 10 | Day 10 code commit `b652347` 内で対処 |

#### 結論

Day 10 は **PROV-O 三項統合 4 type 完備** + **Pattern #7 hook v2 拡張** + **paper × 実装 7 度目合流カテゴリ確立** (PROV-O completion milestone × governance evolution)。Subagent A1 の即時実装修正は Day 9 同パターンで継続実行 (paper サーベイ評価サイクルに「実装修正」を組込む新パターンの 2 度目適用)。

Day 1-10 累計で **paper finding 34 件顕在化** (Day 4: 4 / Day 5: 4 / Day 6: 5 / Day 7: 5 / Day 8: 5 / Day 9: 5 / Day 10: 5 / Day 1-3 関連: 1)。

### 12.29 Day 10 TyDD / サーベイ視点評価結果（2026-04-18 実施）

Day 10 (`b652347` Provenance 層 4 type 完備) を TyDD Tag Index と Section 10.2 パターンに対して評価。

#### 達成度サマリ (Day 4-10 推移)

| 評価軸 | Day 4 | Day 5 | Day 6 | Day 7 | Day 8 | Day 9 | Day 10 | 変化 |
|---|---|---|---|---|---|---|---|---|
| S1 5 軸 | 5/5 | 5/5 | 5/5 | 5/5 | 5/5 | 5/5 | **5/5** | 維持 |
| S1 10 benefits | 9/10 | 9/10 | 9/10 | 9/10 | 9/10 | 9/10 | **9/10** | 維持 |
| S4 5 principles 強適用 | 3/5 | 3/5 | 3/5 | 3/5 | 4/5 | 4/5 | **4/5** | 維持 |
| F/B/H 強適用 | B3 | +F2 部分 | +H4 | +H10 部分 | +B4 | (5 強適用) | **5 強適用継続** | 維持 |
| G1-G6 anti-pattern 回避 | 4/4 | 4/4 | 4/4 | 4/4 | 4/4 | 4/4 | 4/4 | 維持 |
| Section 10.2 適合 | 5/8+1 構造違反 | 6/8+0 | 6/8+0 (運用検証) | 6/8+0 (2 度目) | 6/8+0 (3 度目) | 6/8+0 (4 度目) | **6/8+0 (5 度目、v2 拡張で effective scope 拡大)** | hook v2 拡張 |

#### Day 10 で前進した項目

1. **PROV-O 三項統合 4 type 完備** (TyDD-S1 types-first を 4 type で実証)
2. **EvolutionMapping (Day 8/9 連携 path)** が Q4 案 A free function で minimal
3. **Pattern #7 hook v2 拡張** (Subagent A1 即時実装修正対処、layer architecture 完成形対応)
4. **layer architecture 完成形** (Spine + Process + Provenance + Cross test の 4 layer 完備)

#### Day 10 で paper finding と TyDD の合流

Day 9 で確立した **namespace extension pattern × TyDD-S1** を Day 10 で **PROV-O 4 type 完備に拡張**:
- ResearchAgent.toEntity も Day 9 同パターン (namespace extension で循環依存回避)
- ResearchEntity 5 constructor 拡張は backward compatible (TyDD-S1 維持)
- EvolutionMapping は EvolutionStep import 不要で層依存性最小 (TyDD-S1 + Day 8 layer architecture 整合)

**Section 10.2 Pattern #7 hook の三段階発展**:
- **Day 5**: hook 設計 + 構造的 closure
- **Day 6/7/8/9**: 4 度連続運用検証 (運用安定性)
- **Day 10**: v2 拡張 (governance evolution、layer architecture 完成形対応)

#### 改善余地（優先度順、Section 2.19 で記録済）

| 優先度 | 項目 | 対処タイミング | 関連 Section |
|---|---|---|---|
| 🟡 中 | **PROV-O wasAttributedTo / wasGeneratedBy / wasDerivedFrom relation** | Day 11+ | Section 2.19 |
| 🟡 中 | **02-data-provenance §4.4 RetiredEntity** | Day 11+ | Section 2.19 |
| 🟢 低 | **ResearchEntity DecidableEq 手動実装** | Day 11+ | Section 2.19 |
| 🟢 低 | **ResearchActivity payload なし variants の payload 拡充** | Day 11+ | Section 2.19 |
| 🟢 低 | **transitionLegacy deprecated 削除** | Day 11+ | Section 2.19 |
| 🟢 低 | **EvolutionStep 完全 4 member 化** | Week 4-5 | Section 2.19 |
| 🟢 低 | **G5-1 §3.4 step 2 LearningM indexed monad** (連携 path 完備で本格実装可能) | Week 4-5 | Section 2.19 |

#### Day 10 TyDD 評価で識別された実装修正 (即時対処なし)

Day 10 TyDD 評価では **追加実装修正なし** (Day 9 同パターン継続):
- ResearchEntity DecidableEq 部分実装 → Day 11+ 全体実装の方が一貫性
- 既存 Subagent A1/I2 は paper サーベイ評価で対処済 (改訂 43)

S4 P4 power-to-weight + Q1 Minimal scope 制御を遵守、全て Day 11+ で対処判断。

#### 結論

Day 10 は TyDD 視点で **Day 9 の S4 4/5 + 5 強適用維持** + **PROV-O 4 type 完備 (TyDD-S1 実証)** + **Pattern #7 hook v2 拡張 (governance evolution)**:
- layer architecture 完成形 (Spine + Process + Provenance + Cross test の 4 layer)
- Day 8/9 連携 path 確立 (transitionToActivity)
- Section 10.2 Pattern #7 hook の三段階発展完了 (設計→運用検証→拡張)

Day 11 は PROV-O relation の Lean 化 + RetiredEntity が主要候補。Day 1-10 累計で **S4 4/5 / F/B/H 5 強適用 / paper finding 34 件 / Section 10.2 6/8 + 0 構造違反 (5 度連続) / paper × 実装合流 7 種カテゴリ** 確立。

### 12.30 Day 10 終了時点の累計合致度サマリ（2026-04-18 時点）

Section 12.27 (Day 9 累計) の Day 10 版。**Provenance 層 4 type 完備 (PROV-O 三項統合完了)** + **Pattern #7 hook v2 拡張** + **layer architecture 完成形**。

#### Day 10 累計合致状況

**評価対象**: Week 1 + Week 2 Day 1-10 で scope に入った tag/recipe + paper finding。

**完全合致 51 項目** (Day 9 累計 46 + Day 10 で 5 追加):
- Day 9 累計 46: Section 12.27 参照
- Day 10 で追加合致 (5):
  - **02-data-provenance §4.1 PROV-O 三項統合 4 type 完備** (Verdict + ResearchEntity + ResearchActivity + ResearchAgent)
  - **G5-1 §3.4 step 2 LearningM 連携 path 確立** (transitionToActivity = EvolutionStep B4 ↔ ResearchActivity.verify)
  - **Pattern #7 hook v2 拡張** (Provenance + Test/Cross 検出可能、effective scope 構造的拡大)
  - **Section 10.2 Pattern #7 hook の三段階発展完了** (Day 5 設計 + Day 6/7/8/9 運用検証 + Day 10 v2 拡張)
  - **layer architecture 完成形** (Spine + Process + Provenance + Cross test の 4 layer)

**部分合致 1 項目**: TyDD-J5 Self-hosting (Week 4 で本格化、変化なし)

**Day 10 累計合致率**: 51/52 = **98.1%** (Section 12.27 Day 9 46/47 = 97.9% から +0.2pt 改善)

#### Section 12.27 Day 10 想定目標との照合

Section 12.27 Day 10 想定目標 (49/50 = 98.0%) を **予想を上回って達成** (+1 件追加合致)。これは Pattern #7 hook v2 拡張が想定外の paper-grounded 進歩 (Section 10.2 完成形対応) として加算されたため。

**残 Day 11+ で追加可能な目標**:
- Day 11+ で PROV-O relation + RetiredEntity → 完全合致 +2 想定
- Day 11+ で DecidableEq / payload 拡充 / transitionLegacy 削除 → +3 想定
- Week 4-5 で EvolutionStep 4 member 化 + LearningM → +2 想定

**Day 11 終了時想定目標**: 53/54 = 98.1% (新規追加見込み 2、現状維持)

#### Section 12.3 TyDD 10 benefits の Day 10 時点更新

| # | Benefit | Day 9 | Day 10 |
|---|---|---|---|
| 1 | Deeper understanding | ✓ | ✓ + PROV-O 三項統合の構造理解 + hook v2 拡張の effective scope 設計 |
| 2 | Thoughtful design | ✓ | ✓ + Day 10 D2 ResearchEntity 5 constructor 拡張判断 |
| 5 | Maintainability | ✓ | ✓ + hook v2 で governance scope 自動的に追従可能化 |
| 7 | Top-down / hole-driven | ✓ | ✓ + PROV-O relation / DecidableEq は Day 11+ へ繰り延げ |
| 8 | Higher confidence | ✓ 240 ex | ✓ 278 ex + EvolutionMapping universal property |
| **9** | Less scary refactoring | ✓ | ✓ 維持 (5 constructor 拡張は backward compatible) |
| 10 | Pleasure | N/A | N/A |

**Day 10 達成**: 9/10 (Day 9 と同水準維持)

---

### 12.26 Day 9 TyDD / サーベイ視点評価結果（2026-04-18 実施）

Day 9 (`fa5b373` Provenance 層継続 ResearchEntity + ResearchActivity) を TyDD Tag Index と Section 10.2 パターンに対して評価。

#### 達成度サマリ (Day 4-9 推移)

| 評価軸 | Day 4 | Day 5 | Day 6 | Day 7 | Day 8 | Day 9 | 変化 |
|---|---|---|---|---|---|---|---|
| S1 5 軸 | 5/5 | 5/5 | 5/5 | 5/5 | 5/5 | **5/5** | 維持 |
| S1 10 benefits | 9/10 | 9/10 | 9/10 | 9/10 | 9/10 | **9/10** | 維持 |
| S4 5 principles 強適用 | 3/5 | 3/5 | 3/5 | 3/5 | 4/5 | **4/5 (派生継続)** | 維持 |
| F/B/H 強適用 | B3 | +F2 部分 | +H4 | +H10 部分 | +B4 | **5 強適用継続** | 維持 |
| G1-G6 anti-pattern 回避 | 4/4 | 4/4 | 4/4 | 4/4 | 4/4 | 4/4 | 維持 |
| Section 10.2 適合 | 5/8+1 構造違反 | 6/8+0 | 6/8+0 (運用検証) | 6/8+0 (2 度目) | 6/8+0 (3 度目) | **6/8+0 (4 度目)** | hook 4 度連続検証 |

#### Day 9 で前進した項目

1. **Provenance 層 3 type 完備** (Verdict + ResearchEntity + ResearchActivity)
2. **namespace extension pattern 確立** (Process → Provenance 循環依存回避設計)
3. **Pattern #7 hook 4 度目運用検証** (Day 6/7/8/9 で 4 度連続成功)
4. **内部規範 layer 横断 transfer 拡張継続** (4 段階: fullSpine → fullProcess → fullStack → List ResearchEntity)

#### Day 9 で paper finding と TyDD の合流

Day 9 で **Lean 4 namespace extension パターン × TyDD-S1 (types-first)** が新たに合流:
- ResearchEntity.lean 内で `namespace AgentSpec.Process` を再 open して `Hypothesis.toEntity` 等を定義
- Process 層 → Provenance 層 import が不要 (循環依存回避)
- TyDD-S1 (Process type を独立保持) を Mapping 後付けで両立

#### 改善余地（優先度順、Section 2.17 で記録済）

| 優先度 | 項目 | 対処タイミング | 関連 Section |
|---|---|---|---|
| 🟡 中 | **ResearchAgent (Provenance 層 4 type 目)** | Day 10 メイン候補 | Section 2.17 |
| 🟡 中 | **EvolutionStep transition → ResearchActivity.verify mapping** | Day 10+ | Section 2.17 |
| 🟢 低 | **ResearchEntity DecidableEq 手動実装** | Day 10+ | Section 2.17 |
| 🟢 低 | **ResearchActivity payload なし variants の payload 拡充** | Day 10+ | Section 2.17 |
| 🟢 低 | **HandoffChain 全体 embed 用 constructor** (Subagent I3 Day 9) | Day 10+ 設計判断 | Section 2.17 |

#### Day 9 TyDD 評価で識別された実装修正 (即時対処なし)

Day 9 TyDD 評価では **追加実装修正なし**:
- ResearchEntity DecidableEq 部分実装 (Hypothesis variant のみ) → 複雑、Day 10+ で全体実装の方が一貫性
- ResearchActivity 各 payload なし variant に対称的 isXxx 関数 → Q1 Minimal scope 維持、Day 10+ payload 拡充時に同時追加が natural

S4 P4 power-to-weight + Q1 Minimal scope 制御を遵守、全て Day 10+ で対処判断。

#### 結論

Day 9 は TyDD 視点で **S4 4/5 + 5 強適用維持** + **Pattern #7 hook 4 度連続検証** + **namespace extension pattern × TyDD-S1 合流**:
- Day 8 の S4 P5 + B4 強適用達成を Day 9 でも維持
- Provenance 層 3 type 完備、Lean 4 namespace extension で循環依存回避
- TyDD-S1 (Process type 独立保持) + Mapping 後付けで両立

Day 10 は ResearchAgent 着手 + EvolutionStep transition → ResearchActivity.verify mapping が主要候補。Day 1-9 累計で **paper finding 29 件 / S4 4/5 / F/B/H 5 強適用 / Section 10.2 6/8 + 0 構造違反 / paper × 実装合流 6 種カテゴリ** 確立。

### 12.27 Day 9 終了時点の累計合致度サマリ（2026-04-18 時点）

Section 12.24 (Day 8 累計) の Day 9 版。**Provenance 層 3 type 完備** + **namespace extension pattern 確立** + **paper サーベイ評価サイクル + 実装修正組込み新パターン**。

#### Day 9 累計合致状況

**評価対象**: Week 1 + Week 2 Day 1-9 で scope に入った tag/recipe + paper finding。

**完全合致 46 項目** (Day 8 累計 41 + Day 9 で 5 追加):
- Day 8 累計 41: Section 12.24 参照
- Day 9 で追加合致 (5):
  - **02-data-provenance §4.1 PROV-O 3 type 完備** (Verdict + ResearchEntity + ResearchActivity)
  - **G5-1 §3.4 step 2 LearningM 前提構築** (verify ≡ EvolutionStep B4 整合)
  - **namespace extension pattern × TyDD-S1 合流** (循環依存回避設計、Day 8 layer architecture redefinition の発展)
  - **Pattern #7 hook 4 度連続運用検証** (運用安定性確立)
  - **Subagent I2 即時実装修正対処** (paper サーベイ評価サイクル新パターン)

**部分合致 1 項目**: TyDD-J5 Self-hosting (Week 4 で本格化、変化なし)

**Day 9 累計合致率**: 46/47 = **97.9%** (Section 12.24 Day 8 41/42 = 97.6% から +0.3pt 改善)

#### Section 12.24 Day 9 想定目標との照合

Section 12.24 Day 9 想定目標 (46/47 = 97.9%) を **予想通り達成**。

**残 Day 10+ で追加可能な目標**:
- Day 10 で ResearchAgent + transition → activity mapping → 完全合致 +2 想定
- Day 10+ で DecidableEq / payload 拡充 / HandoffChain 全体 embed → +3 想定

**Day 10 終了時想定目標**: 49/50 = 98.0%

#### Section 12.3 TyDD 10 benefits の Day 9 時点更新

| # | Benefit | Day 8 | Day 9 |
|---|---|---|---|
| 1 | Deeper understanding | ✓ | ✓ + Provenance 3 type の構造理解 + namespace extension pattern |
| 2 | Thoughtful design | ✓ | ✓ + Q1-Q4 確定方針通り A-Minimal scope 維持 + 循環依存回避設計 |
| 5 | Maintainability | ✓ | ✓ + namespace extension で Process 層独立性維持 |
| 7 | Top-down / hole-driven | ✓ | ✓ + ResearchAgent / payload 拡充は Day 10+ へ繰り延げ |
| 8 | Higher confidence | ✓ 197 ex | ✓ 240 ex + Cross-process embed (List ResearchEntity) |
| **9** | Less scary refactoring | ✓ | ✓ 維持 (循環依存回避で Process 層 API 不変) |
| 10 | Pleasure | N/A | N/A |

**Day 9 達成**: 9/10 (Day 8 と同水準維持)

---

## 13. 更新履歴

- 2026-04-17 (初版): Phase 0 Week 1 TyDD 完全合致達成後
- 2026-04-17 (改訂 1): TyDD 合致度追跡 Section 12 追加、Section 2.6 (実装スタイル) 追加、Section 2.4 に Lean 型 preview の記録、α/β/γ 実装後の現状反映
- 2026-04-17 (**改訂 2**): /verify Round 1 実施後の Week 2 以降への反映
  - Section 2.2-2.6 各項目にマーク (✅/🔄/⏳) 追加
  - Section 2.2 に `import` 文明示化項目追加 (/verify 指摘 7)
  - Section 2.3 example 8 コメント不整合を ✅ 解消済にマーク
  - Section 2.4 に schema divergence 項目追加 (/verify 指摘 8)
  - Section 2.7 (新規): /verify Round 1 指摘 1-8 の記録
  - Section 1 Week 2-3 に「Week 1 からの持ち越し優先タスク」追記
  - Section 7 Week 1 Verifier Round 3 の各指摘にマーク、/verify Round 1 結果を追記
  - Section 10.1 (新規): Week 2 Day 1-5 の具体的作業手順
  - Section 12.1 にレビュー回 4 (/verify) 追加
- 2026-04-17 (**改訂 3**): Week 2 Day 1 実施後の後続タスクへの反映 (commit `a43eef4` 以降)
  - Section 2.2 の `SemVer 以外の型` / `普遍 round-trip 定理` / `import 明示化` の現状と後続計画を Day 1 反映後に更新
  - Section 2.2 に新規項目「Core.lean `Decidable` 実装の `inferInstanceAs` 統一」追加 (Day 1 /verify R1 A1 指摘の遡及適用、Day 5 または Week 3 対処)
  - Section 2.3 の Test 混在項目に **`Test/Spine/FolgeIDTest.lean`** を含める旨追記
  - Section 3.1 に GA-S2 追加（Day 1 実装済）、GA-C2 進捗を Day 1 状態に更新
  - Section 10.1 Day 2 に「FolgeIDTest も移動」補足、Day 3-4 に「Day 1 確立パターン適用」参照追加、Day 5 内容を PartialOrder/Ord 拡充に変更
  - Section 10.2 (新規): Day 1 で確立した 7 規範パターン（Day 3-5 全体に適用）
- 2026-04-18 (**改訂 4**): Week 2 Day 2 実施後の後続タスクへの反映 (commit `58b75a0` 以降)
  - Section 2.3 Test 混在項目を **✅ Day 2 解消** にマーク（`lean_lib AgentSpecTest` 別 target 新設）
  - Section 3.1 GA-S4 進捗を「Day 2 hole-driven 迂回実装」に更新（FolgeID endpoint、Week 4-5 で dependent type 化予定）
  - Section 10.1 Day 2 を **✅ 完了マーク** + EdgeTest 集約と commit 参照追加
  - Section 10.2 に Pattern #8 (Lean 4 予約語回避) 追加
  - Section 13 改訂 4 ログ追加
- 2026-04-18 (**改訂 5**): Day 2 TyDD / サーベイ視点評価結果の反映
  - Section 12.6 (新規): Day 2 TyDD 達成度評価（S1 5/5、S1 benefits 8/10、S4 1/5 強適用、改善余地優先度付き）
  - Section 2.8 (新規): Edge Refinement upgrade 計画（S4 P2 / F8 / Recipe 11 / PROV-strict mode）
  - Section 6.2.1 (新規): Pattern #7 構造的強制 hook 提案（Day 1/2 連続違反への対処）
  - Section 10.1 Day 3-5 列に Day 2 評価から導出した TyDD 適用候補追記
- 2026-04-18 (**改訂 6**): Day 2 完結性整備 (A-D 4 項目)
  - A: 99-verifier-rounds.md に Phase 0 Week 2 Day 1-2 検証セクション追加（Day 1 R1 FAIL → R2 PASS、Day 2 R1 PASS、累計サマリ）
  - B: Section 1 Week 2-3 持ち越し優先タスクのマーク更新（Day 2 解消 / Day 1 解消 / Day 4-5 残 / 継続中 / Day 1-2 進行）
  - C: Section 12.7 (新規) Day 2 終了時点の累計合致度サマリ（14/15 = 93.3%）+ Section 12.4 中間照合 + benefits 10 の Day 2 更新（9/10 達成、benefit #7 ⚠→✓ 昇格）
  - D: Edge.lean docstring に Day 2 意思決定ログ D1-D5 を集約（enum 採用 / src-dst 採用 / Bool 関数選択 / kind 不変 reverse / deriving 容認）
- 2026-04-18 (**改訂 7**): Day 3 TyDD / サーベイ視点評価結果の反映
  - Section 12.8 (新規): Day 3 TyDD 達成度評価（S1 5/5 維持、S4 P2 が 1→2 強適用に前進、Pattern #3 厳格化）
  - Section 2.9 (新規): EvolutionStep + SafetyConstraint 改善余地（Bool→Prop refactor 前倒し、Decidable transition、smart constructor、cross-class test、opaque placeholder）
  - 主要発見: Day 2 評価で識別された S4 P2 改善余地が Day 3 で初の強適用達成 → 評価→実装の改善ループが機能している証拠
  - Day 4 着手前判断事項: 🔴 SafetyConstraint Bool→Prop 前倒し / 🟡 Section 6.2.1 hook 化検討（Pattern #7 違反 3 連続）
- 2026-04-18 (**改訂 8**): Day 3 後続影響の metadata 反映
  - artifact-manifest.json: version 0.3→0.4-week2-day3、propositions に GA-S1 追加
    artifacts に 4 エントリ追加 (Spine/{EvolutionStep, SafetyConstraint} + Test/Spine/{EvolutionStepTest, SafetyConstraintTest})
    build_status: AgentSpec 7→9 jobs / AgentSpecTest 9→13 jobs / example 50→62
    breakdown 拡充 + 既存 FolgeIDTest example_count 11→10 修正 (実態確認)
  - README.md: Phase 0 Week 2 Day 3 完了セクション新設、累計指標 (4 type families)、
    Day 3 で達成した TyDD 進展 (S4 P2 強適用 / B3 最小実例 / Pattern #8 派生)
- 2026-04-18 (**改訂 9**): Day 3 完結性整備 (改訂 6 と同パターン、A-D 4 項目)
  - A: 99-verifier-rounds.md に Phase 0 Week 2 Day 3 検証セクション追加（Day 3 R1 PASS、addressable A1 doSafeOperation 置換 / A2 Day 4 棚上げ、informational 5 件）+ Day 1-3 累計サマリ表
  - B: Section 1 Week 2-3 持ち越し優先タスクのマーク更新（Day 3 進行を追記、SafetyConstraint Bool→Prop 前倒し検討明示）
  - C: Section 12.9 (新規) Day 3 終了時点の累計合致度サマリ（16/17 = 94.1%、Day 2 累計 +0.8pt）+ Section 12.4 中間照合 + benefits 10 の Day 3 更新（8/10、#9 ⚠⚠ 降格・要前倒し判断）
  - D: EvolutionStep.lean / SafetyConstraint.lean の意思決定ログは作成時に各 docstring D1-D3 として既に集約済 (Edge.lean パターン踏襲)。本改訂では追加作業なし
- 2026-04-18 (**改訂 10**): Day 4 論文サーベイ視点評価結果の反映
  - Section 12.10 (新規): Day 4 論文サーベイ視点評価（活用 4 件 + 未活用 8 件 + paper 矛盾なし）
    - 活用: S4 P1+P2+P4 / G5-1 §3.4 ステップ 2 / agent-manifesto P4 / S2 将来準備
    - 未活用: S2 VBS / N4 Opaque / S6 Paper 1 / 02-data-provenance / S7 Schedule / S5 QTT / N2 Conatural / S3 TrSpec
    - 主要発見: S4 P2 Refinement Bool→Prop 完全移行は Day 2→3→4 の 3 セッション累積改善を実現
  - Section 2.10 (新規): Spine 層 paper-grounded 改善提案 (10 項目、優先度・タイミング別)
- 2026-04-18 (**改訂 11**): Day 4 TyDD 視点評価結果の反映
  - Section 12.11 (新規): Day 4 TyDD 達成度評価 (Day 1-4 推移表含む)
    - S1 5 軸 5/5 維持、benefits 8/10 → 9/10 (#9 ⚠⚠→✓ 復活)
    - S4 1/5 → 3/5 強適用 (P1+P2+P4 同時達成)
    - Cross-class 4-instance test で Day 3 A2 完全対処
    - Spine 層 4 type class 完備 (Section 1 Week 2-3 完了基準達成)
  - 主要発見: paper finding と established pattern が同時強適用された initial 例
  - Day 5 改善事項: 🔴 Pattern #7 hook 化 (4 連続違反) / 🟡 F2 Lattice / 🟡 B4 Hoare 4-arg
- 2026-04-18 (**改訂 12**): Day 4 後続影響の metadata 反映
  - artifact-manifest.json: version 0.4→0.5-week2-day4
    AgentSpecTest dependencies に 4 新規 test ファイル追加
    SafetyConstraint エントリを Day 4 Prop refactor に更新 (provides_classes / tydd_alignment 拡充: S4 P1+P2+P4 強適用記録 / SafeState.mk smart constructor 追加)
    SafetyConstraintTest example_count 8→10 + test_targets 更新 (smart constructor 反映)
    artifacts に 4 エントリ追加 (Spine/{LearningCycle, Observable} + Test/Spine/{LearningCycleTest, ObservableTest})
    build_status: AgentSpec 9→11 jobs / AgentSpecTest 13→17 jobs / example 62→93
    spine_layer_completeness フィールド追加 (Section 1 Week 2-3 完了基準達成記録)
    breakdown 拡充 + LearningCycleTest 23→22 修正 (実態 22)
  - README.md: Phase 0 Week 2 Day 4 完了セクション新設、累計指標 (4 type class 完備)、
    Day 4 で達成した TyDD 進展 (S1 #9 復活 / S4 3 強適用 / cross-class 4-instance / Spine 完備)
- 2026-04-18 (**改訂 13**): Day 4 完結性整備 (改訂 6/9 と同パターン、A-D 4 項目)
  - A: 99-verifier-rounds.md に Phase 0 Week 2 Day 4 検証セクション追加（Day 4 R1 PASS、addressable A1 reducible 文書化、informational I1/I3/I4 対処、I2/I5 不要）+ Pre-Day-4 refactor 詳細 + Day 4 main 詳細 + Day 1-4 累計サマリ表 (5 commits per Day で Day 4 は最大列幅)
  - B: Section 1 Week 2-3 持ち越し優先タスクのマーク更新（Day 4 で **Section 1 完了基準達成** を明示、SafetyConstraint Bool→Prop は Day 4 で前倒し完了 → Section 2.9 🔴 解消）
  - C: Section 12.12 (新規) Day 4 終了時点の累計合致度サマリ（22/23 = 95.7%、Section 12.9 Day 3 16/17 = 94.1% から +1.6pt 改善、Spine 層 4 type class 完備により Section 12.4 Week 2-3 目標達成）+ Section 12.3 TyDD benefits の Day 4 更新（9/10、#9 ⚠⚠→✓ 復活）
  - D: LearningCycle.lean / Observable.lean / SafetyConstraint.lean (Day 4 Prop refactor 反映) の意思決定ログは作成・修正時に各 docstring D1-D3 として既に集約済 (Edge.lean パターン踏襲)。本改訂では追加作業なし
- 2026-04-18 (**改訂 14**): Day 5 論文サーベイ視点評価結果の反映
  - Section 12.13 (新規): Day 5 論文サーベイ視点評価
    - 活用された paper findings (4 件): G5-1 §6.2.1 hook 化 / S4 派生継続 / S2 限界実証 / Mathlib 統合
    - paper finding と実装の双方向影響: paper → 実装 + 実装 → paper 優先度更新 (S2 格上げ)
    - 矛盾なし、Mathlib 11→90 jobs は N1 監視を Week 6 CI で組込み必要
  - Section 2.10 更新: S2 Lean-Auto / Recipe 4-6 を 🟢→🔴 格上げ (Day 5 で必要性顕在化、Week 6 へ前倒し)
  - 主要発見: paper finding が「優先度未定」→「具体的タイミング」へ精度向上 (Day 4 評価ループ実証に続くループ拡張)
- 2026-04-18 (**改訂 15**): Day 5 TyDD 視点評価結果の反映
  - Section 12.14 (新規): Day 5 TyDD 達成度評価 (Day 1-5 推移表含む)
    - S1 5/5 維持、benefits 9/10 維持
    - S4 3/5 強適用維持 (P2 派生継続: SafetyConstraint refinement → LearningStage LE/LT)
    - F2 Lattice 部分達成 (LearningStage + FolgeID で順序関係完備)
    - Section 10.2 適合: 5/8 + 1 構造違反 → **6/8 + 0 構造違反** (Pattern #7 構造的解決)
  - 主要発見: paper × pattern 合流の 2 度目達成 (Day 4 S4 × Pattern #5 → Day 5 G5-1 × Pattern #7)
  - Day 6 改善事項: 🔴 Lean-Auto 統合準備 / 🟡 Universal round-trip 残作業 / 🟡 Mathlib 影響評価
- 2026-04-18 (**改訂 16**): Day 5 後続影響の metadata 反映
  - artifact-manifest.json: version 0.5→0.6-week2-day5
    FolgeID: Mathlib dependencies 追加、6 Day 5 theorems 追加、LT/PartialOrder instance 追加
    RoundTrip: 6 Day 5 helper theorems 追加、bounded 7³→8³ (512 ケース)、universal 残課題明示 + Lean-Auto Week 6 へ繰り延げ記録
    LearningCycle: Day 5 LE/LT/Decidable instance 追加、tydd_alignment_day5 (F2 部分達成)
    FolgeIDTest example_count 10→16、LearningCycleTest 22→28、各 day5_additions 詳細記録
    breakdown FolgeID 0→6 theorems / RoundTrip 3→9 theorems
    build_status: AgentSpec 11→90 jobs (Mathlib 推移依存) / AgentSpecTest 17→96
    theorem_count 3→15、example_count 93→105、finite_bounded_universal_cases 343→512
    governance_hook フィールド追加 (Pattern #7 構造的解決記録)、N1 監視を Week 6 CI で組込み必要明記
  - README.md: Phase 0 Week 2 Day 5 完了セクション新設、Day 5 4 項目詳細、累計指標 (Mathlib 推移依存影響含む)、Day 5 で達成した TyDD 進展 (Pattern #7 構造的解決 / F2 部分達成 / paper × pattern 合流 2 度目 / S2 必要性顕在化)
- 2026-04-18 (**改訂 17**): Day 5 完結性整備 (改訂 6/9/13 と同パターン、A-D 4 項目)
  - A: 99-verifier-rounds.md に Phase 0 Week 2 Day 5 検証セクション追加
    Day 5 R1 PASS (logprob A 全体 margin 0.049、Subagent PASS)
    addressable A1 (lt_iff_le_not_ge) はビルド成功 (90/96 jobs) で resolve
    informational 5 件のうち I3 (Mathlib 非対称設計) は意図的、I4 (Mathlib 依存最適化) は Week 6 CI 整備時、その他は安全性影響なし
    Day 5 4 項目詳細 (hook 化 + LearningStage LE/LT + FolgeID PartialOrder + RoundTrip 部分達成)
    Day 1-5 累計サマリ表 (Day 4-5 は 5 commits/Day で最大列幅、paper サーベイ評価列追加)
  - B: Section 1 Week 2-3 持ち越し優先タスクのマーク更新
    Day 5 で順序関係完備 (LearningStage LE/LT + FolgeID PartialOrder/LT)
    Pattern #7 hook 化は Day 5 で構造的解決 (Section 6.2.1 完全実装)
    Universal round-trip は Day 5 部分達成 (bounded 8³ + 6 helper)、Day 6/Week 3 + Lean-Auto Week 6 で完全達成へ
    Ord (lex total order) は Day 6+/Week 4-5 へ繰り延げ
  - C: Section 12.15 (新規) Day 5 終了時点の累計合致度サマリ
    26/27 = 96.3% (Section 12.12 Day 4 22/23 = 95.7% から +0.6pt 改善)
    Section 12.4 Week 2-3 目標 (14/13 以上) を大幅に上回って達成、Section 12.4 Day 5 想定目標 (18/19 = 94.7%) も上回り
    Section 12.3 TyDD benefits の Day 5 更新 (9/10 維持)
  - D: FolgeID.lean / LearningCycle.lean / RoundTrip.lean の意思決定ログは作成・修正時に各 docstring に既に集約済 (Day 5 拡張部分の意思決定はコメントで記録)、本改訂では追加作業なし
- 2026-04-18 (**改訂 18**): Day 6 着手前判断議論結果の反映 (Process 層計画確定)
  - Section 1 Week 4-5 Process 層: Day 6+ 前倒し開始計画に更新
    - Day 6 = Hypothesis + Failure (Minimal)
    - Day 7+ = Evolution + HandoffChain
    - Day 8+ = Provenance 層 (PROV-O Lean 化)
    - 既存 ResearchNode/Provenance/Retirement/State/Rationale は Day 8+ または別 Week
    - FolgeID/Edge は既に Day 1-2 で Spine 層配置済 (元 Process/ 案から移動) を明記
  - Section 10.1 に Day 6 / Day 7 / Day 8+ 行追加
    - Day 6 詳細: Hypothesis + Failure + Test 2 + PROV vocabulary alignment in docstring
    - Day 7 詳細: Evolution + HandoffChain + cross-process test
    - Day 8+ 候補: Provenance 層 / Manifest 移植 / Lean-Auto research の並行
  - Section 2.11 (新規): Process 層 Day 6+ 着手計画
    - Q1 Option C (Process 着手) / Q2 Minimal / Q3 Vocabulary alignment in docstring を確定
    - Day 6 / 7 / 8+ deliverables 表
    - 各判断ポイントの理由記録
  - 主要決定: PROV-O 統合は Day 8+ に分離 (Day 6 scope 制御 + TyDD-S1 遵守)
- 2026-04-18 (**改訂 19**): Day 6 論文サーベイ視点評価結果の反映 + 改善提案 4 件追加
  - Section 12.16 (新規): Day 6 論文サーベイ視点評価
    - 活用された paper findings (5 件): 02-data-provenance §4.3 (FailureReason 4 variant 100% 忠実実装) / §4.1 (PROV vocabulary in docstring) / G5-1 §3.4 (Process 層前倒し) / TyDD-S1 (types-first) / G5-1 §6.2.1 (hook 運用検証)
    - paper × pattern 合流 3 度目達成 (Day 4 = 1 度目、Day 5 = 2 度目 hook 設計、Day 6 = 3 度目 hook 運用検証)
    - 矛盾なし、Pattern #7 hook 設計→実装→運用 三段階 closure 達成
  - Section 2.10 拡張: 4 件の改善提案追加
    - 🟡 02-data-provenance §4.4 退役の構造的検出 (Day 8+ Provenance 層)
    - 🟡 02-data-provenance §4.7 RO-Crate 互換 export (Week 6-7 CI 整備時)
    - 🟢 02-data-provenance §4.5 Pipeline 段階表現 (Week 5-6 Tooling 層)
    - 🟢 S6 Paper 1 BST/AVL invariants (Day 7+ Evolution と統合)
  - 主要発見: Pattern #7 hook の設計→実装→運用 三段階 closure 達成、Day 8+ Provenance 層と Week 5-7 Tooling 層への paper-grounded 入力を確立
- 2026-04-18 (**改訂 20**): Day 6 TyDD 視点評価結果の反映 + 改善提案 4 件追加
  - Section 12.17 (新規): Day 6 TyDD 達成度評価 (Day 1-6 推移表含む)
    - S1 5/5 維持、benefits 9/10 維持
    - S4 3/5 強適用維持 (P2 派生継続: refinement → LE/LT → Hypothesis structure)
    - F/B/H 強適用: B3 + F2 部分 + **H4 新規部分達成** (PROV mapping in docstring as LLM hint)
    - Section 10.2 適合: 6/8 + 0 構造違反 維持 (Day 5 設計実装、Day 6 運用検証完了)
  - 主要発見: 新カテゴリ「principle × decision」合流達成 (TyDD-S1 × Q3 Option C)
    - Day 4: paper × pattern (S4 × Pattern #5)
    - Day 5: paper × pattern (G5-1 × Pattern #7 設計実装)
    - Day 6: principle × decision (TyDD-S1 × Q3 Option C、Process 独立 type + docstring PROV)
  - Section 2.12 (新規): Process 層 Day 6 評価から導出した改善余地 (4 項目)
    - 🟡 cross-process test (Day 7 Evolution と同時)
    - 🟡 Hypothesis rationale 型化 (Day 8+ Provenance 層)
    - 🟡 Failure payload 型化 (Day 8+ Provenance 層)
    - 🟢 artifact-manifest AgentSpecTest entry 補完 (Day 7 metadata commit、Subagent I2 対処)
  - Day 7 改善事項: cross-process test / EvolutionStep B4 4-arg post / HandoffChain T1 一時性 / metadata 補完
- 2026-04-18 (**改訂 21**): Day 6 後続影響の metadata 反映 + Subagent I2 対処
  - README.md: Phase 0 Week 2 Day 6 完了セクション新設
    - Day 6 2 項目詳細 (Hypothesis structure / Failure first-class entity)
    - 累計指標表 (Day 5 vs Day 6、Process 層着手で 2 type 追加、92+100 jobs)
    - Day 6 で達成した TyDD/paper 進展 (02-data-provenance §4.3 100% 忠実 / Pattern #7 hook 運用検証 / TyDD-S1 × Q3 Option C 合流 / H4 新規部分 / paper finding 14 件累計)
  - artifact-manifest.json: AgentSpecTest entry に aggregated_example_count / aggregated_sorry_count / aggregated_axiom_count + aggregation_note 追加 (Subagent I2 対処、Section 2.12 🟢 解消)
  - 注: artifact-manifest.json の Day 6 主要 metadata (version, 4 新規 entries, build_status) は Day 6 code commit `917c752` に既に含まれているため本改訂では README + I2 のみ追加対応
- 2026-04-18 (**改訂 22**): Day 6 完結性整備 (改訂 6/9/13/17 と同パターン、A-D 4 項目)
  - A: 99-verifier-rounds.md に Phase 0 Week 2 Day 6 検証セクション追加
    Day 6 R1 PASS (logprob A 全体 margin 0.073 + Subagent PASS)
    addressable 0、informational 3 件 (I1 Inhabited Failure 対称性 +1 example で対処、I2 改訂 21 で解消、I3 Day 7+ で意義明確化)
    Day 6 2 項目詳細 (Hypothesis + Failure)
    Pattern #7 hook 初の適用 commit pass-through 確認
    Day 1-6 累計サマリ表 (Day 4-6 は paper サーベイ評価列含めて 5 commits/Day で最大列幅)
  - B: Section 1 Week 2-3 持ち越し優先タスクのマーク更新
    Day 6 で Process 層着手を明示 (Hypothesis + Failure 2 inductive、02-data-provenance §4.3 100% 忠実)
    Pattern #7 hook 化は Day 5 構造的解決 + Day 6 運用検証完了 (Section 6.2.1 完全 closure)
    Process 層継続は Day 7、Provenance 層は Day 8+ へ繰り延べ明示
  - C: Section 12.18 (新規) Day 6 終了時点の累計合致度サマリ
    30/31 = 96.8% (Section 12.15 Day 5 26/27 = 96.3% から +0.5pt 改善)
    Section 12.15 Day 6 想定目標 (28/29 = 96.5%) を上回って達成
    Section 12.3 TyDD benefits の Day 6 更新 (9/10 維持)
    Day 7 終了時想定目標: 33/34 = 97.1%
  - D: Hypothesis.lean / Failure.lean の意思決定ログは作成時に各 docstring D1-D3 として既に集約済 (Day 6 コード作成時)、本改訂では追加作業なし
- 2026-04-18 (**改訂 23**): Day 7 着手前後続ドキュメント反映 (Day 6 評価結果を Day 7+ 計画に統合)
  - Section 10.1 Day 6 行に ✅ + commit `917c752` 参照追加 (完了マーク)
  - Section 10.1 Day 7 行に Day 6 評価 Section 12.17 / 2.12 から導出した改善余地を統合:
    - 🟡 cross-process interaction test (Hypothesis × Failure × Evolution、Day 4 fullSpineExample パターン)
    - 🟡 EvolutionStep B4 4-arg post の I/O type 確定 (Section 2.9 残課題解消)
    - 🟡 HandoffChain T1 一時性 inductive 表現
    - 🟢 S6 Paper 1 BST/AVL invariants (Hypothesis chain order を invariant 付き structure 化、Section 2.10 paper-grounded)
  - Section 10.1 Day 8+ 行に Day 6 評価 Section 12.16 / 2.10 paper-grounded 改善を統合:
    - 🟡 02-data-provenance §4.4 退役の構造的検出 (RetiredEntity + Lean linter)
    - 🟡 Hypothesis rationale Refinement 強化 (Option String → Option Evidence)
    - 🟡 Failure payload 型化 (各 variant payload を Evidence/Spec/InconsistencyProof/ResearchEntity に refactor)
  - Section 2.11 Day 7 想定 deliverables を確定版に拡充:
    - Evolution.lean: B4 4-arg post 統合 + S6 Paper 1 BST/AVL invariants 候補
    - HandoffChain.lean: T1 一時性 + LearningCycle/Observable 統合
    - Test 2 ファイル (cross-process interaction test 含む)
    - artifact-manifest.json (Pattern #7 hook 強制で同 commit)
  - Section 2.11 Day 7 で意識する改善事項表 (4 項目、Section 2.12 / 2.10 連携) 追加
  - Section 2.11 Day 8+ deliverables に RetiredEntity.lean 追加 + Mapping.lean に Hypothesis/Failure 型化を統合明記
  - 主要決定: Day 7 は Day 6 評価で識別された 4 改善余地 (3 中 + 1 低) を全て吸収する設計
- 2026-04-18 (**改訂 24**): Day 7 着手前判断議論結果の反映 (Q1-Q4 採用案確定)
  - Section 2.11 Day 7 着手前判断結果 (新規) を確定:
    - **Q1 全体 scope = Minimal** (Day 7 plan 通り、Evolution + HandoffChain 2 type、Day 1-6 リズム維持)
    - **Q2 cross-process test scope = 案 A** (1-2 件 fullSpineExample-like、Hypothesis × Failure × Evolution × HandoffChain)
    - **Q3 EvolutionStep B4 4-arg post 統合 = 案 B** (Day 7 では signature のみ、完全統合は Day 8+ Verdict 型確定後、Section 2.9 部分解消)
    - **Q4 cross-class test 置き場所 = 案 A** (別 test ファイル、Spine と Process の責務分離)
  - Section 2.11 Day 7 想定 deliverables を Q1-Q4 反映で specific 化:
    - Evolution.lean: Day 7 では signature のみ、S6 BST/AVL invariants は Day 8+ Evolution 拡張時 (Q1 Minimal scope 制御)
    - HandoffChain.lean: T1 一時性 inductive (LearningCycle/Observable 統合は Day 8+ Q4 案 A)
    - EvolutionTest: cross-process test 1-2 件 (Q2 案 A、Section 2.12 🟡 解消)
    - HandoffChainTest: 単独 test (Spine 統合は Day 8+ 別 test file、Q4 案 A)
  - Section 2.11 Day 7 改善事項表に Day 7 反映列追加 (Q1-Q4 採用案明示)
  - Section 10.1 Day 7 行に Q1-Q4 採用案を統合 (signature のみ / 1-2 件 / Day 8+ 拡張)
  - 主要決定: Day 7 scope は Minimal 維持、Verdict 型と S6 Paper 1 は Day 8+ で扱う
- 2026-04-18 (**改訂 25**): Day 7 論文サーベイ視点評価結果の反映 + 改善提案 4 件追加
  - Section 12.19 (新規): Day 7 論文サーベイ視点評価
    - 活用された paper findings (5 件): G5-1 §3.4 Process 層継続 / agent-manifesto T1 一時性 / 02-data-provenance §4.1 PROV-O 継続 / G5-1 §6.2.1 Pattern #7 hook 2 度目適用 / Day 4 fullSpineExample 内部規範踏襲
    - paper × 実装合流 4 度目カテゴリ確立: 内部規範 layer 横断 transfer (Day 4 fullSpineExample → Day 7 fullProcessExample)
    - 矛盾なし、Process 層 4 type 完備
  - Section 2.10 拡張: 4 件の改善提案追加
    - 🟡 02-data-provenance §4.6 Nextflow resume + Galaxy job cache (WasReusedBy edge、Week 5-6)
    - 🟢 02-data-provenance §4.2 二層分離 (Lean tree + content-addressed manifest、Week 6-7)
    - 🟢 Spine + Process 層 cross-layer integration test (Day 8+ 別 file)
    - 🟢 G3 CSLib spine bisimulation (Week 6 CSLib 移行時)
  - 主要発見: 内部規範 layer 横断 transfer により Spine/Process の uniform structure 検証、Day 1-7 累計 paper finding 19 件
- 2026-04-18 (**改訂 26**): Day 7 TyDD 視点評価結果の反映 + 改善提案 4 件追加
  - Section 12.20 (新規): Day 7 TyDD 達成度評価 (Day 4-7 推移表含む)
    - S1 5/5 維持、benefits 9/10 維持、S4 3/5 強適用維持
    - F/B/H 強適用: B3 + F2 部分 + H4 + **H10 新規部分達成** (Evolution 2 constructor は spec normal form 最小単位)
    - Section 10.2 適合: 6/8 + 0 構造違反 維持 (Pattern #7 hook 2 度目運用検証)
  - 主要発見: layer 横断 transfer 達成 (Day 4 fullSpineExample → Day 7 fullProcessExample)
    TyDD-S1 5 軸 #4 (verify) を Spine/Process layer 横断で実証
  - Section 2.13 (新規): Process 層 Day 7 評価から導出した改善余地 (4 項目)
    - 🟡 Verdict 型 + B4 4-arg post 完全統合 (Day 8+、Section 2.9 完全解消)
    - 🟡 S6 Paper 1 BST/AVL invariants (Day 8+ Evolution 拡張時)
    - 🟢 Evolution DecidableEq 手動実装 (Day 8+ 検討)
    - 🟢 HandoffChain concat (chain 連結、Day 8+ 検討)
  - Day 8+ 改善事項: Verdict 型 / S6 Paper 1 / Provenance 層 / Spine+Process cross-layer test
- 2026-04-18 (**改訂 27**): Day 7 後続影響の metadata 反映 (README のみ追加対応)
  - README.md: Phase 0 Week 2 Day 7 完了セクション新設
    - Day 7 2 項目詳細 (Evolution inductive Q3 案 B / HandoffChain inductive T1 一時性)
    - 累計指標表 (Day 6 vs Day 7、Process 層 4 type 完備、94+104 jobs)
    - Day 7 で達成した TyDD/paper 進展:
      - Process 層 4 type 完備 / agent-manifesto T1 一時性 100% 忠実
      - Pattern #7 hook 2 度目適用 (運用安定性継続検証)
      - 内部規範 layer 横断 transfer (fullSpineExample → fullProcessExample)
      - H10 (Spec normal forms) 新規部分達成
      - paper × 実装 4 度目合流カテゴリ確立 (internal-norm × layer transfer)
      - paper finding 19 件累計
  - 注: artifact-manifest.json の Day 7 主要 metadata (version 0.8、4 新規 entries、
    build_status 94+104、example 171、process_layer_progress / governance_hook 2 度目 /
    cross_process_test フィールド) は Day 7 code commit `941b25c` に既に含まれている
    ため本改訂では README のみ追加対応 (Day 6 改訂 21 同パターン、Pattern #7 hook 強制
    で manifest は code commit に統合される構造)
- 2026-04-18 (**改訂 28**): Day 7 完結性整備 (改訂 6/9/13/17/22 と同パターン、A-D 4 項目)
  - A: 99-verifier-rounds.md に Phase 0 Week 2 Day 7 検証セクション追加
    Day 7 R1 PASS (logprob A 全体 margin 0.232 + Subagent PASS)
    addressable A1 (Inhabited 解決パス注記) + A2 (cross-process simp 使用理由) を docstring 追加で対処
    informational 4 件 (I1 集計確認 / I2 HandoffChain DecidableEq 一貫性 / I3 signature 宣言なし許容 / I4 hook 運用検証記録済) は対処不要
    Day 7 2 項目詳細 (Evolution Q3 案 B / HandoffChain T1 一時性)
    Pattern #7 hook 2 度目適用 pass-through 確認 (運用安定性継続検証)
    Day 1-7 累計サマリ表 (Day 4-7 は paper サーベイ評価列含めて 5 commits/Day で最大列幅)
  - B: Section 1 Week 2-3 持ち越し優先タスクのマーク更新
    Day 6-7 で Process 層 4 type 完備を明示 (Hypothesis + Failure + Evolution + HandoffChain)
    Pattern #7 hook 化は Day 5 構造的解決 + Day 6 初適用 + Day 7 2 度目運用検証 (Section 6.2.1 完全 closure + 運用安定性継続)
    B4 4-arg post は Day 7 部分対処 (Q3 案 B、signature なし)、完全統合 Day 8+ Verdict 型確定後
    Ord / S6 BST/AVL invariants / Provenance 層は Day 8+ へ繰り延げ
  - C: Section 12.21 (新規) Day 7 終了時点の累計合致度サマリ
    35/36 = 97.2% (Section 12.18 Day 6 30/31 = 96.8% から +0.4pt 改善)
    Section 12.18 Day 7 想定目標 (33/34 = 97.1%) を上回って達成
    Section 12.3 TyDD benefits の Day 7 更新 (9/10 維持)
    Day 8 終了時想定目標: 40/41 = 97.6%
  - D: Evolution.lean / HandoffChain.lean の意思決定ログは作成時に各 docstring D1-D4 として既に集約済 (Day 7 コード作成時、Subagent A1 注記の D4 追加含む)、本改訂では追加作業なし
- 2026-04-18 (**改訂 29**): Day 8+ 着手準備 — Day 7 評価結果を Day 8+ 計画に統合
  - Section 10.1 Day 7 行に ✅ + commit `941b25c` 参照追加 (完了マーク)
  - Section 10.1 Day 8+ 行に Day 7 評価 Section 12.20 / 2.13 から導出した改善余地を統合:
    - 🟡 Verdict 型新規定義 + EvolutionStep B4 4-arg post 完全統合 (Section 2.9 完全解消)
    - 🟡 S6 Paper 1 BST/AVL invariants (Evolution chain order 強型化)
    - 🟢 Evolution DecidableEq 手動実装
    - 🟢 HandoffChain concat
    - 🟢 Spine + Process cross-layer integration test (Q4 案 A 別 file、Day 7 paper サーベイから)
    - mapping 関数に `Evolution.toActivity` / `Handoff.toAgent` 追加明記
  - Section 2.11 Day 8+ 想定 deliverables 拡充:
    - Verdict.lean (新規、Q3 案 B からの delegation): `inductive Verdict` (proven/refuted/inconclusive 等)
    - EvolutionStep.lean refactor: B4 4-arg post 完全統合 (Section 2.9 完全解消)
    - Evolution.lean refactor: S6 Paper 1 BST/AVL invariants 適用
    - Test/Cross/SpineProcessTest.lean (新規、Q4 案 A 別 file): Spine + Process cross-layer integration test
  - 主要決定: Day 8+ は Day 7 評価で識別された 4 改善余地 (Verdict + B4 / S6 / DecidableEq / concat) と Day 7 paper サーベイから導出 1 件 (Spine+Process cross-layer test) を全て吸収する設計
- 2026-04-18 (**改訂 30**): Day 8 着手前判断議論結果の反映 (Q1-Q4 採用案確定)
  - Section 2.14 (新規): Day 8 着手前判断結果
    - **Q1 main scope = B 案** (Verdict + EvolutionStep B4 4-arg post 統合、Section 2.9 完全解消)
    - **Q2 sub-scope = B-Medium** (上記 + Spine+Process cross-layer test、Day 7 paper サーベイから導出)
    - **Q3 Verdict design = 案 A** (3 variant minimal: proven/refuted/inconclusive)
    - **Q4 B4 4-arg post signature = 案 A** (Hypothesis/Verdict separate args、S4 P5 explicit assumptions)
  - Section 2.14 Day 8 想定 deliverables を Q1-Q4 反映で specific 化:
    - Verdict.lean (新 namespace AgentSpec.Provenance に先行配置)
    - EvolutionStep.lean refactor (B4 4-arg post 完全統合)
    - VerdictTest / EvolutionStepTest modify / SpineProcessTest (Q4 案 A 別 file)
    - artifact-manifest.json 4 新規 entries (Pattern #7 hook 強制)
  - Section 2.14 Day 8 改善事項表 (5 項目、Section 2.13 / 2.10 連携)
  - Section 10.1 Day 8+ 行を Day 8 / Day 9+ に分割
    - Day 8 行: Q1-Q4 採用案 (Verdict + B4 完全統合 + cross-layer test)
    - Day 9+ 行: Provenance 層継続 (ResearchEntity/Activity/Agent + Mapping)
  - 主要決定: Day 8 メイン成果 = Section 2.9 完全解消、副成果 = Spine+Process cross-layer test、S6/DecidableEq/concat は Day 9+ へ繰り延げ
- 2026-04-18 (**改訂 31**): Day 8 論文サーベイ視点評価結果の反映 + 改善提案 4 件追加
  - Section 12.22 (新規): Day 8 論文サーベイ視点評価
    - 活用された paper findings (5 件):
      - G5-1 §3.4 ステップ 1 (ResearchEvolutionStep) 完全実装 → EvolutionStep B4 4-arg post 統合 (Section 2.9 完全解消)
      - S4 P5 explicit assumptions → Hypothesis/Verdict separate args
      - 02-data-provenance §4.1 PROV-O → Verdict 新 namespace 先行配置
      - G5-1 §6.2.1 Pattern #7 hook 3 度目適用 → 運用安定性継続
      - 内部規範 layer 横断 transfer 拡張 → fullStackExample 8 layer 要素
    - paper × 実装合流 5 度目カテゴリ確立: layer architecture redefinition
      (Spine = 下位層 → core abstraction、Process/Provenance = 具体型)
    - 部分的矛盾 (意識的受容): Spine→Process/Provenance 依存は Q4 案 A D4 で受容
    - Section 2.9 完全解消 = 5 セッション累積改善 (Day 3 識別→Day 8 解消)
  - Section 2.10 拡張: 4 件の改善提案追加
    - 🟡 G5-1 §3.4 ステップ 2 LearningM indexed monad (Week 4-5 Tooling 層)
    - 🟡 EvolutionStep に hypothesis / observation accessor 追加 (Week 4-5)
    - 🟢 Verdict payload 拡充 (Day 9+ Provenance 層)
    - 🟢 transitionLegacy deprecated 削除 (Day 9+)
  - 主要発見: layer architecture redefinition により layer 役割を再定義、
    Section 2.9 完全解消は 5 セッション累積改善の代表例
    Day 1-8 累計 paper finding 24 件
- 2026-04-18 (**改訂 32**): Day 8 TyDD 視点評価結果の反映 + 改善提案 5 件追加
  - Section 12.23 (新規): Day 8 TyDD 達成度評価 (Day 4-8 推移表含む)
    - S1 5/5 維持、benefits 9/10 維持
    - S4 5 principles: 3/5 → **4/5 ↑** (P5 explicit assumptions 新規強適用)
    - F/B/H 強適用: B3 + B4 + F2 部分 + H4 + H10 部分 (**B4 Hoare 4-arg post 新規強適用**)
    - Section 10.2 適合: 6/8 + 0 構造違反 維持 (Pattern #7 hook 3 度目運用検証)
  - 主要発見: S4 P5 + B4 同時強適用達成 (Q4 案 A signature の典型実装)
    Day 4 P1+P2+P4 → Day 8 +P5 で 4/5 強適用達成 (S4 派生の継続的展開)
  - Section 2.15 (新規): Day 8 評価から導出した改善余地 (5 項目)
    - 🟡 Provenance 層継続 (ResearchEntity/Activity/Agent + Mapping、Day 9+)
    - 🟡 Verdict payload 拡充 (案 A→C 移行、Day 9+)
    - 🟢 transitionLegacy deprecated 削除 (Day 9+)
    - 🟢 EvolutionStep 完全 4 member 化 (G5-1 §3.4 step 1 完全形、Week 4-5)
    - 🟢 G5-1 §3.4 step 2 LearningM indexed monad (Week 4-5 Tooling 層)
  - Day 9+ 改善事項: Provenance 層継続 / Verdict payload / transitionLegacy 削除 / EvolutionStep 4 member 化
- 2026-04-18 (**改訂 33**): Day 8 後続影響の metadata 反映 (README のみ追加対応)
  - README.md: Phase 0 Week 2 Day 8 完了セクション新設
    - Day 8 3 項目詳細:
      - Verdict 3 variant inductive (新 namespace AgentSpec.Provenance、Q3 案 A 先行配置)
      - EvolutionStep B4 4-arg post 完全統合 (Q4 案 A、layer architecture redefinition)
      - Spine + Process cross-layer test (新 namespace AgentSpec.Test.Cross、Q2 B-Medium)
    - 累計指標表 (Day 7 vs Day 8、95+107 jobs、example 197)
    - Day 8 で達成した TyDD/paper 進展:
      - Section 2.9 完全解消 (5 セッション累積改善 Day 3→Day 8)
      - S4 4/5 強適用達成 (P5 新規)、B4 新規強適用
      - Pattern #7 hook 3 度目適用、layer architecture redefinition
      - 内部規範 layer 横断 transfer 拡張 (3 段階)
      - paper × 実装 5 度目合流カテゴリ、paper finding 24 件累計
  - 注: artifact-manifest.json の Day 8 主要 metadata (version 0.9、4 新規 entries、
    EvolutionStep refactor 反映、build_status 95+107、example 197、
    spine_layer_completeness / provenance_layer_started / governance_hook 3 度目 /
    cross_process_test Q2 B-Medium / section_2_9_b4_4arg_post 完全解消) は
    Day 8 code commit `0f78fa6` に既に含まれているため本改訂では README のみ追加対応
    (Day 6-7 改訂 21/27 同パターン、Pattern #7 hook 強制で manifest は code commit に統合)
- 2026-04-18 (**改訂 34**): Day 8 完結性整備 (改訂 6/9/13/17/22/28 と同パターン、A-D 4 項目)
  - A: 99-verifier-rounds.md に Phase 0 Week 2 Day 8 検証セクション追加
    Day 8 R1 PASS (logprob A 全体 margin 0.051 + Subagent PASS)
    addressable A1 (manifest EvolutionStep entry Day 8 未反映) を即対処
    informational 3 件 (内訳コメント微差 / universe u 利点薄 / isRefuted inconclusive ケース欠) は対処不要
    Day 8 3 項目詳細 (Verdict / EvolutionStep refactor / SpineProcessTest)
    Pattern #7 hook 3 度目適用 pass-through 確認 (運用安定性継続検証成功)
    Day 1-8 累計サマリ表 (Day 4-8 は 5 commits/Day で最大列幅)
  - B: Section 1 Week 2-3 持ち越し優先タスクのマーク更新
    Day 8 で Section 2.9 完全解消 (5 セッション累積改善 Day 3→Day 8) 明示
    Pattern #7 hook 化: Day 5 構造解決 + Day 6/7/8 で 3 度運用検証成功
    Provenance 層着手 (Day 8 で Verdict 先行配置)
    Provenance 層継続 (ResearchEntity / Activity / Agent + Mapping) は Day 9+ へ繰り延べ
  - C: Section 12.24 (新規) Day 8 終了時点の累計合致度サマリ
    41/42 = 97.6% (Section 12.21 Day 7 35/36 = 97.2% から +0.4pt 改善)
    Section 12.21 Day 8 想定目標 (40/41 = 97.6%) を予想通り達成
    Section 12.3 TyDD benefits の Day 8 更新 (9/10 維持)
    Day 9 終了時想定目標: 46/47 = 97.9%
  - D: Verdict.lean / EvolutionStep.lean refactor / SpineProcessTest.lean の意思決定ログは作成・修正時に各 docstring に既に集約済 (Day 8 コード作成時、Subagent A1 対処の manifest 更新含む)、本改訂では追加作業なし
- 2026-04-18 (**改訂 35**): Day 9+ 着手準備 — Day 8 評価結果を Day 9+ 計画に統合
  - Section 10.1 Day 8 行に ✅ + commit `0f78fa6` 参照追加 (完了マーク)
  - Section 10.1 Day 9+ 行に Day 8 評価 Section 12.23 / 2.15 から導出した改善余地を統合:
    - 🟡 Verdict payload 拡充 (案 A→C 移行)
    - 🟢 transitionLegacy deprecated 削除
    - 🟢 EvolutionStep 完全 4 member 化 (G5-1 §3.4 step 1)
    - 🟢 G5-1 §3.4 step 2 LearningM indexed monad (Week 4-5)
  - Section 10.1 Day 9+ 行の関連 Section に 2.15 追加 (Day 6-8 評価導出 = 2.10 + 2.12 + 2.13 + 2.15)
  - 主要決定: Day 9+ メイン = Provenance 層継続 (ResearchEntity / Activity / Agent + Mapping)、副候補 = Verdict payload 拡充 + EvolutionStep 完全 4 member 化 + LearningM indexed monad
- 2026-04-18 (**改訂 36**): Day 9 着手前判断議論結果の反映 (Q1-Q4 採用案確定)
  - Section 2.16 (新規): Day 9 着手前判断結果
    - **Q1 main scope = A 案** (Provenance 層継続: ResearchEntity + ResearchActivity + Mapping)
    - **Q2 sub-scope = A-Minimal** (2 type + Mapping、ResearchAgent は Day 10+ 繰り延げ)
    - **Q3 ResearchEntity design = 案 A** (4 constructor、既存 Process type embed)
    - **Q4 Mapping signature = 案 A** (Process side `.toEntity` method、実装は ResearchEntity.lean 内で循環依存回避)
  - Section 2.16 Day 9 想定 deliverables を Q1-Q4 反映で specific 化:
    - ResearchEntity.lean (新規、Q3 案 A 4 constructor)
    - ResearchActivity.lean (新規、5 variant: Investigate/Decompose/Refine/Verify/Retire)
    - 4 Process .lean modify (toEntity 追加)
    - ResearchEntityTest / ResearchActivityTest (新規 2 test ファイル)
    - artifact-manifest.json 4 新規 + 4 modify (Pattern #7 hook 強制)
  - Section 2.16 層依存性の考察:
    - Process → Provenance import が新規追加だが、Mapping を ResearchEntity.lean 内に配置することで循環依存回避
    - Day 8 EvolutionStep の Q4 案 A D4 受容方針と整合
  - Section 10.1 Day 9+ 行を Day 9 / Day 10+ に分割
    - Day 9 行: Q1-Q4 採用案 (Provenance 2 type + Mapping + 4 Process modify)
    - Day 10+ 行: ResearchAgent + Day 6-8 評価から繰り延べ項目 (02-data-provenance §4.4-4.7、Verdict payload 拡充、transitionLegacy 削除、EvolutionStep 4 member 化、LearningM、S6、DecidableEq、concat)
  - 主要決定: Day 9 メイン = ResearchEntity + ResearchActivity 2 type + Mapping、ResearchAgent / Verdict payload / transitionLegacy / EvolutionStep 4 member / LearningM は Day 10+ または Week 4-5 へ繰り延げ
- 2026-04-18 (**改訂 37**): Day 9 論文サーベイ視点評価結果の反映 + 改善提案 3 件追加 + Subagent I2 実装修正
  - Section 12.25 (新規): Day 9 論文サーベイ視点評価
    - 活用された paper findings (5 件):
      - 02-data-provenance §4.1 PROV-O 3 type 完備 (ResearchAgent のみ Day 10+)
      - G5-1 §3.4 step 2 LearningM 前提構築 (ResearchActivity.verify ≡ EvolutionStep transition 整合)
      - TyDD-S1 types-first (Process embed 案 A)
      - G5-1 §6.2.1 Pattern #7 hook 4 度目適用
      - 内部規範 layer 横断 transfer 拡張継続 (4 段階)
    - paper × 実装合流 6 度目カテゴリ確立: namespace extension pattern by layer architecture
      (Day 8 layer architecture redefinition の自然な発展)
    - 矛盾なし、Provenance 層 3 type 完備
  - Section 2.10 拡張: 3 件の改善提案追加
    - 🟡 EvolutionStep transition → ResearchActivity.verify mapping (Day 10+)
    - 🟢 ResearchActivity payload なし variants の payload 拡充 (Day 10+)
    - 🟢 HandoffChain 全体 embed 用 constructor (Day 10+ 設計判断、Subagent I3)
  - **実装修正 (Subagent I2)**: ResearchActivityTest 最終 example に parameter 形式の
    docstring 注記追加 (Day 10+ で集計方針統一検討と明記)
  - 新パターン: paper サーベイ評価サイクルに「実装修正」を組込む (Subagent I2 即時対処)
  - 主要発見: Provenance 層 3 type 完備、Day 9 で namespace extension pattern 確立、
    Day 1-9 累計 paper finding 29 件
- 2026-04-18 (**改訂 38**): Day 9 TyDD 視点評価結果の反映 + 改善提案 5 件追加 (実装修正なし)
  - Section 12.26 (新規): Day 9 TyDD 達成度評価 (Day 4-9 推移表含む)
    - S1 5/5 維持、benefits 9/10 維持、S4 4/5 強適用維持、F/B/H 5 強適用維持
    - Section 10.2 適合: 6/8 + 0 構造違反 維持 (Pattern #7 hook 4 度連続検証)
  - 主要発見: namespace extension pattern × TyDD-S1 合流
    (ResearchEntity.lean 内で Process namespace 再 open、循環依存回避 + TyDD-S1 維持)
  - Section 2.17 (新規): Day 9 評価から導出した改善余地 (5 項目、全て Day 10+ 対処)
    - 🟡 ResearchAgent (Day 10 メイン候補)
    - 🟡 EvolutionStep transition → ResearchActivity.verify mapping (Day 10+)
    - 🟢 ResearchEntity DecidableEq 手動実装 (Day 10+)
    - 🟢 ResearchActivity payload なし variants の payload 拡充 (Day 10+)
    - 🟢 HandoffChain 全体 embed 用 constructor (Day 10+ 設計判断)
  - 実装修正なし: S4 P4 power-to-weight + Q1 Minimal scope 制御を遵守、
    全て Day 10+ で対処判断 (TyDD 評価サイクルでの「実装修正なし」も新パターン)
  - Day 10 改善事項: ResearchAgent / EvolutionStep transition mapping / DecidableEq /
    payload 拡充 / HandoffChain 全体 embed
- 2026-04-18 (**改訂 39**): Day 9 後続影響の metadata 反映 (README のみ追加対応)
  - README.md: Phase 0 Week 2 Day 9 完了セクション新設
    - Day 9 2 項目詳細 (ResearchEntity 4 constructor + 4 toEntity Mapping / ResearchActivity 5 variant)
    - 累計指標表 (Day 8 vs Day 9、97+111 jobs、example 240)
    - Day 9 で達成した TyDD/paper 進展:
      - 02-data-provenance §4.1 PROV-O 3 type 完備
      - G5-1 §3.4 step 2 LearningM 前提構築 (verify ≡ EvolutionStep B4 整合)
      - namespace extension pattern × TyDD-S1 合流 (循環依存回避設計)
      - Pattern #7 hook 4 度連続運用検証 (運用安定性確立)
      - 内部規範 layer 横断 transfer 拡張継続 (4 段階)
      - Subagent I2 即時実装修正対処 (paper サーベイ評価サイクル新パターン)
      - paper × 実装 6 度目合流カテゴリ確立 (namespace extension pattern by layer architecture)
      - paper finding 29 件累計
    - verifier_history Day 1-9 一括補完 (4 → 14 entries) も明示
  - 注: artifact-manifest.json の Day 9 主要 metadata (version 0.10、4 新規 entries、
    build_status 97+111、example 240、provenance_layer_progress / governance_hook 4 度目 /
    cross_process_test 更新 / prov_mapping_status フィールド + verifier_history 拡充) は
    Day 9 code commit `fa5b373` に既に含まれているため本改訂では README のみ追加対応
    (Day 6-8 改訂 21/27/33 同パターン)
- 2026-04-18 (**改訂 40**): Day 9 完結性整備 (改訂 6/9/13/17/22/28/34 と同パターン、A-D 4 項目)
  - A: 99-verifier-rounds.md に Phase 0 Week 2 Day 9 検証セクション追加
    Day 9 R1 PASS (logprob A 全体 margin 0.601 + Subagent PASS)
    informational 3 件: I1 verifier_history Day 1-9 一括追加 / I2 即時実装修正対処 (paper サーベイ評価サイクル新パターン) / I3 Day 10+ 設計判断
    Day 9 2 項目詳細 (ResearchEntity / ResearchActivity)
    Pattern #7 hook 4 度目適用 pass-through 確認 (運用安定性 4 度連続)
    Day 1-9 累計サマリ表 (Day 9 で paper サーベイ評価列に I2 即時実装修正注記)
  - B: Section 1 Week 2-3 持ち越し優先タスクのマーク更新
    Day 9 で Provenance 層 3 type 完備 + namespace extension pattern 確立を明示
    Pattern #7 hook 化: Day 5 構造解決 + Day 6/7/8/9 で 4 度連続運用検証
    ResearchAgent / EvolutionStep transition mapping ほか Day 10+ 繰り延べ明示
  - C: Section 12.27 (新規) Day 9 終了時点の累計合致度サマリ
    46/47 = 97.9% (Section 12.24 Day 8 41/42 = 97.6% から +0.3pt 改善)
    Section 12.24 Day 9 想定目標 (46/47 = 97.9%) を予想通り達成
    Section 12.3 TyDD benefits の Day 9 更新 (9/10 維持)
    Day 10 終了時想定目標: 49/50 = 98.0%
  - D: ResearchEntity.lean / ResearchActivity.lean の意思決定ログは作成時に各 docstring D1-D3 として既に集約済 (循環依存回避設計の D2 含む)、本改訂では追加作業なし
- 2026-04-18 (**改訂 41**): Day 10+ 着手準備 — Day 9 評価結果を Day 10+ 計画に統合
  - Section 10.1 Day 9 行に ✅ + commit `fa5b373` 参照追加 (完了マーク)
    + verifier_history Day 1-9 一括補完 + Subagent I2 即時実装修正対処を明示
  - Section 10.1 Day 10+ 行に Day 9 評価 Section 12.27 / 2.17 から導出した改善余地を統合:
    - 🟡 ResearchAgent (Day 10 メイン候補)
    - 🟡 EvolutionStep transition → ResearchActivity.verify mapping (verify ≡ B4 連携 path)
    - 🟢 ResearchEntity DecidableEq 手動実装
    - 🟢 ResearchActivity payload なし variants の payload 拡充
    - 🟢 HandoffChain 全体 embed 用 constructor (Subagent I3 Day 9)
  - Section 10.1 Day 10+ 行の関連 Section に 2.17 追加
    (Day 6-9 評価導出 = 2.10 + 2.12 + 2.13 + 2.15 + 2.17)
  - 主要決定: Day 10+ メイン = Provenance 層完成 (ResearchAgent + EvolutionStep transition mapping)、副候補 = DecidableEq 手動実装 + payload 拡充
- 2026-04-18 (**改訂 42**): Day 10 着手前判断議論結果の反映 (Q1-Q4 採用案確定)
  - Section 2.18 (新規): Day 10 着手前判断結果
    - **Q1 main scope = B 案** (ResearchAgent + EvolutionStep transition → ResearchActivity.verify mapping)
    - **Q2 sub-scope = B-Medium** (signature + 実装 + test、Day 6-7 と同パターン)
    - **Q3 ResearchAgent design = 案 A** (structure + inductive Role 3 variant、PROV-O 100% 忠実)
    - **Q4 transition mapping signature = 案 A** (free function、input/output のみ、Q1 Minimal scope 制御)
  - Section 2.18 Day 10 想定 deliverables 詳細:
    - ResearchAgent.lean (新規、Q3 案 A)
    - EvolutionMapping.lean (新規、Q4 案 A、free function)
    - ResearchEntity.lean 5 constructor 拡張検討 (Agent embed は実装時判断)
    - ResearchAgentTest / EvolutionMappingTest (新規 2 test)
    - artifact-manifest.json 4 新規 entries + verifier_history Day 10 R1
  - Section 2.18 層依存性考察 (EvolutionMapping は Spine + Process + Provenance 全 import、Day 8/9 layer architecture と整合)
  - Section 10.1 Day 10+ 行を Day 10 / Day 11+ に分割
  - 主要決定: Day 10 メイン = Provenance 層 4 type 完備 + Day 8/9 連携 path 確立
- 2026-04-18 (**改訂 43**): Day 10 論文サーベイ視点評価結果の反映 + 改善提案 4 件 + Subagent A1/I2 実装修正対処
  - Section 12.28 (新規): Day 10 論文サーベイ視点評価
    - 活用された paper findings (5 件):
      - 02-data-provenance §4.1 PROV-O 三項統合 4 type 完備
      - G5-1 §3.4 step 2 LearningM 連携 path 確立 (transitionToActivity)
      - TyDD-S1 types-first (Process embed)
      - G5-1 §6.2.1 Pattern #7 hook v2 拡張 (Provenance + Test/Cross 追加)
      - 内部規範 layer 横断 transfer 拡張継続 (5 段階目)
    - paper × 実装合流 7 度目カテゴリ確立: PROV-O completion milestone × governance evolution
    - 矛盾なし
  - Section 2.10 拡張: 1 件の改善提案追加 (PROV-O wasAttributedTo 等 relation の Lean 化、Day 11+)
    + EvolutionStep transition → ResearchActivity.verify mapping を ✅ Day 10 完了マーク
  - **実装修正対処** (paper サーベイ評価サイクル新パターン 2 度目):
    - Subagent A1 (hook regex): hook v2 配置で対処済 (user 介入で /tmp/restore-and-fix-hook-day10-v2.sh 実行)
    - Subagent I2 (docstring): Day 10 code commit 内で対処済
  - 主要発見: Pattern #7 hook v2 拡張で effective scope 構造的拡大 (Day 10 layer architecture 完成形に対応)
    Day 1-10 累計 paper finding 34 件
- 2026-04-18 (**改訂 44**): Day 10 TyDD 視点評価結果の反映 + 改善提案 7 件追加 (実装修正なし)
  - Section 12.29 (新規): Day 10 TyDD 達成度評価 (Day 4-10 推移表含む)
    - S1 5/5 維持、benefits 9/10 維持、S4 4/5 強適用維持、F/B/H 5 強適用継続
    - Section 10.2 適合: 6/8 + 0 構造違反 維持 (Pattern #7 hook 5 度連続検証 + v2 拡張)
  - 主要発見: Section 10.2 Pattern #7 hook の三段階発展完了
    (Day 5 設計→Day 6/7/8/9 運用検証→Day 10 v2 拡張、governance evolution)
  - Section 2.19 (新規): Day 10 評価から導出した改善余地 (7 項目、全て Day 11+ 対処)
    - 🟡 PROV-O wasAttributedTo / wasGeneratedBy / wasDerivedFrom relation の Lean 化 (Day 11+)
    - 🟡 02-data-provenance §4.4 RetiredEntity (Day 11+)
    - 🟢 ResearchEntity DecidableEq 手動実装 (Day 11+)
    - 🟢 ResearchActivity payload なし variants の payload 拡充 (Day 11+)
    - 🟢 transitionLegacy deprecated 削除 (Day 11+)
    - 🟢 EvolutionStep 完全 4 member 化 (Week 4-5、G5-1 §3.4 step 1 完全形)
    - 🟢 G5-1 §3.4 step 2 LearningM indexed monad (Week 4-5、連携 path 完備で本格実装可能)
  - 実装修正なし (Day 9 同パターン継続): S4 P4 power-to-weight + Q1 Minimal scope 制御遵守
  - Day 11 改善事項: PROV-O relation / RetiredEntity / DecidableEq / payload 拡充 / transitionLegacy 削除
- 2026-04-18 (**改訂 45**): Day 10 後続影響の metadata 反映 (README + hook v2 配置完了)
  - README.md: Phase 0 Week 2 Day 10 完了セクション新設
    - Day 10 3 項目詳細 (ResearchAgent + EvolutionMapping + ResearchEntity 5 constructor 拡張)
    - 累計指標表 (Day 9 vs Day 10、99+115 jobs、example 278、Provenance 4 type 完備)
    - Day 10 で達成した TyDD/paper 進展:
      - PROV-O 三項統合 4 type 完備
      - Day 8/9 連携 path 確立 (transitionToActivity)
      - Pattern #7 hook v2 拡張 (Subagent A1 対処)
      - Section 10.2 Pattern #7 hook の三段階発展完了 (設計→運用検証→拡張)
      - layer architecture 完成形 (4 layer)
      - paper × 実装 7 度目合流カテゴリ (PROV-O completion milestone × governance evolution)
      - paper finding 34 件累計
  - **Pattern #7 hook v2 配置完了** (本改訂で記録):
    - hook script v2 (clean version、regex Provenance + Test/Cross 含む) を /tmp/p3-manifest-on-commit-v2.sh として準備
    - user 介入で /tmp/restore-and-fix-hook-day10-v2.sh 実行
    - new-foundation worktree + main repo 両方の hook を v2 で完全置換
    - Day 11+ commit で Provenance/Test/Cross 配下の新規 .lean に対しても hook が機能
  - 注: artifact-manifest.json の Day 10 主要 metadata は Day 10 code commit `b652347` に既に含まれているため本改訂では README + hook v2 配置のみ追加対応 (Day 6-9 改訂 21/27/33/39 同パターン)
- 2026-04-18 (**改訂 46**): Day 10 完結性整備 (改訂 6/9/13/17/22/28/34/40 と同パターン、A-D 4 項目)
  - A: 99-verifier-rounds.md に Phase 0 Week 2 Day 10 検証セクション追加
    Day 10 R1 PASS (logprob A 全体 margin 2.335 過去最高 + Subagent PASS)
    addressable A1 (hook regex Provenance/Test/Cross 含まず) は paper サーベイ評価で hook v2 配置で対処済
    informational 3 件: I1 例数 manifest 一致 (Subagent 誤計数) / I2 docstring code commit 内対処済 / I3 import 明示済対処不要
    Day 10 3 項目詳細 (ResearchAgent + EvolutionMapping + ResearchEntity 5 constructor 拡張)
    Pattern #7 hook 5 度目適用 + v2 拡張 (Day 5 設計→Day 6/7/8/9 運用→Day 10 v2 拡張の三段階発展完了)
    Day 1-10 累計サマリ表 (Day 10 で margin 2.335 過去最高と注記)
  - B: Section 1 Week 2-3 持ち越し優先タスクのマーク更新
    Day 10 で Provenance 層 4 type 完備 (PROV-O 三項統合完了) + EvolutionMapping 連携 path 確立を明示
    Pattern #7 hook 化: Day 5 構造解決 + Day 6/7/8/9/10 で 5 度連続運用検証 + Day 10 v2 拡張 (governance evolution)
    layer architecture 完成形 (4 layer: Spine + Process + Provenance + Cross test)
    PROV-O relation / RetiredEntity / DecidableEq / payload 拡充 ほか Day 11+ へ繰り延べ明示
  - C: Section 12.30 (新規) Day 10 終了時点の累計合致度サマリ
    51/52 = 98.1% (Section 12.27 Day 9 46/47 = 97.9% から +0.2pt 改善)
    Section 12.27 Day 10 想定目標 (49/50 = 98.0%) を予想以上に達成 (+1 件、hook v2 加算)
    Section 12.3 TyDD benefits の Day 10 更新 (9/10 維持)
    Day 11 終了時想定目標: 53/54 = 98.1% (現状維持)
  - D: ResearchAgent.lean / EvolutionMapping.lean / ResearchEntity.lean (5 constructor 拡張) の意思決定ログは作成・修正時に各 docstring D1-D3 として既に集約済 (Subagent I2 docstring 修正含む)、本改訂では追加作業なし
- 2026-04-18 (**改訂 47**): Day 11+ 着手準備 — Day 10 評価結果を Day 11+ 計画に統合
  - Section 10.1 Day 10 行に ✅ + commit `b652347` 参照追加 (完了マーク)
    + Subagent A1/I2 即時実装修正対処 + Day 10 D2 ResearchEntity 5 constructor 拡張完了を明示
  - Section 10.1 Day 11+ 行に Day 10 評価 Section 12.30 / 2.19 から導出した改善余地を統合:
    - 🟡 PROV-O relation Lean 化 (wasAttributedTo / wasGeneratedBy / wasDerivedFrom)
    - その他 Day 6-10 評価繰り延ばし項目 (RetiredEntity / DecidableEq / payload 拡充 / transitionLegacy 削除 / EvolutionStep 4 member / LearningM)
  - Section 10.1 Day 11+ 行の関連 Section に 2.19 追加
    (Day 6-10 評価導出 = 2.10 + 2.12 + 2.13 + 2.15 + 2.17 + 2.19)
  - 主要決定: Day 11+ メイン候補 = PROV-O relation Lean 化 (Day 10 4 type 完備の自然な続き)、副候補 = RetiredEntity / DecidableEq
- 2026-04-18 (**改訂 48**): Day 11 着手前判断議論結果の反映 (Q1-Q4 採用案確定)
  - Section 2.20 (新規): Day 11 着手前判断結果
    - **Q1 main scope = A 案** (PROV-O relation 3 inductive)
    - **Q2 sub-scope = A-Minimal** (3 structure + Test 2-3 ファイル)
    - **Q3 relation design = 案 A** (3 separate structure、PROV-O 1:1 対応)
    - **Q4 引数 type = 案 A** (PROV-O §4.1 厳格 type、Entity × Agent / Entity × Activity / Entity × Entity)
  - Section 2.20 Day 11 想定 deliverables 詳細:
    - ProvRelation.lean (新規、3 structure 統合配置)
    - ProvRelationTest.lean (新規)
    - artifact-manifest.json 2 新規 entries + verifier_history Day 11 R1
    - DecidableEq 省略 (ResearchEntity recursive 制約継承)
  - Section 2.20 層依存性考察: Provenance 層内部依存のみ、新たな問題なし
  - Section 10.1 Day 11+ 行を Day 11 / Day 12+ に分割
  - 主要決定: Day 11 メイン = PROV-O relation 3 structure (PROV-O 100% 忠実)、RetiredEntity ほか Day 12+ 繰り延べ

## マーク凡例

- ✅ **解消済** — 既に実装/記述で反映済み、または実態確認で解消を確認
- 🔄 **Week 2 着手予定** — Week 2 開始時に優先対処する項目
- ⏳ **後続 Week 対処予定** — Week 3 以降の計画済みタスク
- ❓ **判断待ち** — ユーザー判断が必要な項目

**更新方針**: Week 2 以降の各 Week 完了時に、完了項目にマーク (✅) を追加し、残タスクの再優先順位を見直す。新規発見タスクは適切な Section に追記。TyDD 合致度レビュー時は Section 12 を更新。各改訂時に本 Section 13 に履歴を追加。
