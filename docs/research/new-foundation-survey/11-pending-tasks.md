# 新基盤研究 後続タスク一覧

**作成日**: 2026-04-17 / **Day 29.1 schema reset**: 2026-04-20

## Role (Day 29.1 以降)

**forward-looking pending items + roadmap** 専用 file。以下を扱う:

- Phase ロードマップ (Week 2-8 の scope / 完了基準) — Section 1
- Week 1 時点で pending だった具体項目の**残**— Section 2 (2.1-2.10)
- Gap Analysis の Week 2 以降 items — Section 3
- Verifier Round informational 残件 — Section 7
- 実装ガイド (未着手 Day 以降) — Section 10.1
- Week boundary TyDD 合致度レビュー (Week 境界時のみ) — Section 12.1-12.5

**本 file は過去記録を蓄積しない**。per-Day narrative (着手前判断 / 評価 / 改訂 log) は:
- 実施済 commit → git log
- 決定ログ → Lean docstring D-entry
- archive (Day 6-29 過去分) → [11-pending-tasks-archive.md](./11-pending-tasks-archive.md)

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
  - ✅ **Day 1-28 + Day 29 section refactor 完了** (Day 25 Subagent I2 3 session 繰り延げ解消、comment-only behavior 不変、Day 11-29 = 19 Day 連続 rfl preference、Phase 0 累計 99.2% 維持、Day 30 WasDerivedFrom DAG 完了、Day 31 Q1 🟡 DecidableEq / Acyclic decidable / A-Maximal 予定)** — FolgeID (GA-S2) Day 1 / Edge (GA-S4) Day 2 / EvolutionStep + SafetyConstraint (GA-S1) Day 3 / LearningCycle + Observable (GA-S1) Day 4 で **Section 1 Week 2-3 完了基準 (4 type class + dummy instance) 達成**。**Day 5 で順序関係完備**。**Day 6-7 で Process 層 4 type 完備**。**Day 8 で Section 2.9 完全解消**。**Day 9 で Provenance 層 3 type**、**Day 10 で Provenance 層 4 type 完備 (PROV-O 三項統合完了 + EvolutionMapping 連携 path 確立)**、**Day 11 で PROV-O 3 main relation 完備**、**Day 12 で RetiredEntity + RetirementReason 4 variant 完備**、**Day 13 で PROV-O auxiliary + WasRetiredBy 3 structure 完備 (6 relation)**、**Day 14 で RetiredEntity linter A-Minimal 完備 (Lean 4 標準 `@[deprecated]` 4 fixture、強制化次元追加、Day 11-13 type/relation 軸と直交)**。**Pattern #7 hook 化は Day 5 構造的解決 + Day 6/7/8/9/10 で 5 度連続運用検証成功 + Day 10 v2 拡張 + Day 11 v2 初運用検証 + Day 12 v2 2 度目 + Day 13 v2 3 度目運用検証 = 運用定常化 + Day 14 MODIFY path 対応確認 = 七段階発展完了** (新規 file パターン + MODIFY path 両対応)。**Day 10 で layer architecture 完成形** (Spine + Process + Provenance + Cross test の 4 layer)。A-Compact custom attribute (Day 15) / A-Standard custom linter (Day 15+) / A-Maximal elaborator 型レベル強制 (Week 5-6) / ResearchActivity payload 拡充 / DecidableEq / transitionLegacy 削除 (Day 14 `@[deprecated]` モデル転用可能) / その他繰り延べ項目 は Day 15+ へ繰り延げ

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
| ✅ **Day 11 完了** | ~~PROV-O wasAttributedTo / wasGeneratedBy / wasDerivedFrom relation の Lean 化~~ — Day 11 で 3 separate structure (`WasAttributedTo` / `WasGeneratedBy` / `WasDerivedFrom`) として実装完了 (Q3 案 A、PROV-O 1:1 対応、Q4 案 A 引数 type 厳格) | 02-data-provenance §4.1 | Day 11 commit `11a32bd` で対処 |
| 🟢 Day 10+ | **ResearchActivity payload なし variants の payload 拡充** (investigate / decompose / refine / retire) — verify variant と同パターン | 02-data-provenance §4.1 | Day 10+ (Day 9 paper サーベイ評価で識別) |
| 🟢 Day 10+ 設計判断 | **HandoffChain 全体 embed 用 constructor** — `ResearchEntity.HandoffChain` 追加検討 (Subagent I3 Day 9) | Subagent I3 Day 9 | Day 10+ (Day 9 paper サーベイ評価で識別) |
| ✅ **Day 12 完了** | ~~02-data-provenance §4.4 退役の構造的検出 (RetiredEntity structure)~~ — Day 12 で `RetiredEntity` separate structure + `RetirementReason` 4 variant inductive (Refuted/Superseded/Obsolete/Withdrawn、PROV-O §4.4 1:1 対応) として実装完了 (Q3 案 A 4 variant 型化 + Q4 案 A separate、ResearchEntity 拡張不要 backward compatible) | 02-data-provenance §4.4 | Day 12 commit `49510c6` で対処 |
| ✅ **Day 13 完了** | ~~PROV-O auxiliary relations (WasInformedBy / ActedOnBehalfOf) + WasRetiredBy~~ — Day 13 で 3 separate structure (`WasInformedBy { activity, informer : ResearchActivity }` + `ActedOnBehalfOf { agent, on_behalf_of : ResearchAgent }` + `WasRetiredBy { entity : ResearchEntity, retired : RetiredEntity }`) として実装完了 (Q3 案 B 別 file 配置 ProvRelationAuxiliary.lean + Q4 案 A WasRetiredBy = Entity → RetiredEntity 2-arg、Day 12 RetiredEntity 再利用) | 02-data-provenance §4.1 + §4.4 | Day 13 commit `40ccd78` で対処 |
| ✅ **Day 14 A-Minimal 完了** | ~~RetiredEntity linter / elaborator (A-Minimal)~~ — Day 14 で Lean 4 標準 `@[deprecated "msg" (since := "2026-04-18")]` 4 fixture (Refuted / Superseded / Obsolete / Withdrawn variant) として実装完了 (test fixture のみ対象、production code backward compatible) | 02-data-provenance §4.4 + TyDD-G3 linter integration | Day 14 commit `13c4e77` で対処 |
| ✅ **Day 15 完了** | ~~A-Compact: custom attribute `@[retired]`~~ — Day 15 で Lean 4 elab macro (`macro_rules`) による Hybrid 実装完了 (`@[retired msg since]` → `@[deprecated msg (since := since)]` 展開、新 module `RetirementLinter.lean` で隔離、Day 14 backward compatible 維持) | TyDD-G3 + §4.4 (Day 14 段階的拡張パス第 2 段階) | Day 15 commit `17db6ef` で対処 |
| 🟡 Day 16 | **A-Standard: custom linter** — `Lean.Elab.Command` 拡張 (Day 15 macro 学習が前提準備) | TyDD-G3 + §4.4 | Day 16 メイン候補 |
| ✅ **Day 16 A-Compact 完了** | ~~transitionLegacy 削除 A-Compact~~ — Day 16 で `@[deprecated "Use new 4-arg transition" (since := "2026-04-19")]` 付与 + `TransitionReflexive` / `TransitionTransitive` を 4-arg signature 直接展開に refactor (cycle 内学習 transfer 2 段階別分野転用実例、Section 2.15 Day 9+ 繰り延べ課題 6 セッションを半解消) | TyDD + Day 14 `@[deprecated]` モデル Spine 層転用 | Day 16 commit `b678856` で対処 |
| ✅ **Day 17 完了** | ~~transitionLegacy 完全削除 A-Standard~~ — Day 17 で定義完全削除 + test 3 件削除 (既存 1 + Day 16 新規 2)、breaking change classification、`since := "2026-04-19"` 履行、Section 2.15 Day 9+ 9 セッション繰り延べ課題完全解消、cycle 内学習 transfer 2 段階別分野転用の Day 14→16→17 3 Day 完結、**Day 9-17 で初の Subagent 指摘ゼロ到達 (cycle 内学習 transfer 累積効果極致実例)** | TyDD + 段階的 deprecation → removal best practice 完遂 | Day 17 commit `a8bcf69` で対処 |
| ✅ **Day 18 A-Minimal 完了** | ~~A-Standard custom linter~~ — Day 18 で `elab "#check_retired " ident : command` + `Lean.Linter.isDeprecated` API 利用として実装完了 (新 module `RetirementLinterCommand.lean`、段階的 Lean 機能習得 3/4 段階目達成) | TyDD-G3 + §4.4 | Day 18 commit `f127774` で対処 |
| ✅ **Day 19 完了** | ~~A-Standard-Lite: namespace 検出拡張~~ — Day 19 で `#check_retired_in_namespace` command 追加 (Environment.constants + Name.isPrefixOf + Lean.Linter.isDeprecated 経由 NS 配下 any depth descendants 列挙)、Day 18 同 module MODIFY、Subagent I1/I2 即時対処 (rfl preference "9 Day" + docstring 表現訂正) | TyDD-G3 + §4.4 | Day 19 commit `682364d` で対処 |
| ✅ **Day 20 完了** | ~~A-Compact: nested namespace 再帰対応~~ — Day 20 で `#check_retired_in_namespace_with_depth NS N` command 追加 (Environment.constants + Name.components.length 差分で algebraic depth 計算)、Day 18-19 同 module MODIFY、Subagent I1 即時対処 (10 Day milestone 記載)、I2 Role.toCtorIdx 顕在化 Day 21+ 投資 / I3 連携テスト Day 21+ 継続 | TyDD-G3 + Day 19 Subagent I2 設計対応 | Day 20 commit `7fa8f51` で対処 |
| ✅ **Day 21 完了** | ~~A-Standard-Full A-Minimal~~ — Day 21 で `#check_retired_auto` (pre-defined watched namespaces hardcode list 一括 check) 完了。**Day 18-20 long-deferred Subagent I3 (Day 15 @[retired] × Day 18 #check_retired 連携テスト) も Day 21 改訂 100 で実装追加で同時解消** (4 セッション繰り延べ解消、A-Compact ← A-Standard A-Minimal 連携完全実証成功) | TyDD-G3 + Subagent I3 long-deferred 解消 | Day 21 commit `18c5e94` + 改訂 100 で対処 |
| ✅ **Day 22 完了** | ~~A-Standard-Full-Standard A-Minimal~~ — Day 22 で `SimplePersistentEnvExtension` + `register_retirement_namespace` command + `defaultWatchedRetirementNamespaces` で Day 21 hardcode list を additive 連結保持し backward compat 完全維持。`#check_retired_auto` を `getWatchedRetirementNamespaces env` 経由に rewire。**env iteration `map₁.toList` → `toList` correctness fix** で Day 18-21 同 module の 3 commands も同時改善 (output Day 21 までと変化なし＝対象が imported のみだったため) | TyDD-G3 + Lean 4 Environment API + correctness fix | Day 22 commit `e6d9b1f` で対処 |
| ✅ **Day 23 完了** | ~~multi-module import propagate test~~ — Day 23 で新 helper module `AgentSpec/Test/Provenance/RetirementWatchedFixture.lean` (test scope 専用) に `@[retired]` decorated fixture + `register_retirement_namespace` を含み、`AgentSpecTest.lean` と `RetirementLinterCommandTest.lean` で helper import 経由で Day 22 D10 `addImportedFn` の import 越境 propagate 動作を実コード実証。Day 22 Subagent informational I1 直接対処完了。Day 23 Subagent VERDICT PASS + 0 addressable + 4 informational 全件即時対処 | Day 22 D10 PersistentEnvExtension addImportedFn 動作実証 + Day 22 Subagent I1 短 cycle 解消 | Day 23 commit `7b95180` で対処 |
| ✅ **Day 24 完了** | ~~Role.toCtorIdx auto-gen helper root cause investigation~~ — Day 24 で temporary probe module で `Lean.Linter.deprecatedAttr.getParam?` 直接検査、root cause 特定: **Lean 4 4.29.0 upstream (since 2025-08-25) で `toCtorIdx` → `ctorIdx` rename、backward compat で旧名 deprecated alias 保持**。agent-spec-lib 側問題なし、本体 code 変更不要 (deriving 副産物のみ)。RetirementLinterCommand.lean D14 + ResearchAgent.lean Day 24 追記 + Test Day 24 section (+2 example: Role.ctorIdx rfl + toCtorIdx = ctorIdx rfl)、Subagent VERDICT PASS + 0 addressable + 1 informational 即時対処 (aggregated_example_count stale 更新) | Day 22 audit long-deferred 対応 2 例目 + Lean 4 deprecated alias alpha-equivalence rfl 実証 | Day 24 commit `b3be98d` で対処 |
| ✅ **Day 25 完了** | ~~multi-source register / duplicate handling~~ — Day 25 で新 helper module `RetirementWatchedFixture2.lean` (test scope 専用) に `@[retired]` decorated `importPropagateFixture2` + 独立 namespace register + 既存 namespace duplicate register を含み、Day 22 D10 `addEntryFn = arr.push name` が dedup しないことを実測確認 (watched 7 件 / total 8 retired、helper1 dup 1 件重複 count)。RetirementLinterCommand.lean D15 docstring (observe-first 方針) + Test Day 25 section (+1 example + 1 #check_retired_auto invocation)、Subagent VERDICT PASS + 0 addressable + 2 informational 即時対処 | Day 22 audit long-deferred 対応 3 例目 + observe-first 設計方針確立 | Day 25 commit `b9d0dd8` で対処 |
| ✅ **Day 26 完了** | ~~ResearchActivity payload 拡充 (Day 13-22 = 12 Day 連続繰り延げ最長 long-deferred candidate)~~ — Day 26 で `investigateOf (target : Hypothesis)` + `retireOf (entity : Hypothesis)` 2 variants backward compatible 追加 (Day 9 verify pattern 継続)、`isInvestigateOf` / `isRetireOf` accessor 追加。ResearchActivity.lean D4-D6 docstring + Test +11 example (inhabitation 4 + accessor rfl 4 + backward compat 3、example 22→33)。Subagent VERDICT PASS + **0 addressable + 0 informational = Day 17 ぶりの clean cycle 初実例** (Day 18 以降初、9 Day 連続 cycle 内即時修復の極致到達)。Pattern #7 hook 十九段階発展 (MODIFY path 9 度目) | Day 22 audit long-deferred 対応 4 例目 + clean cycle 初実例 | Day 26 commit `71e2593` で対処 |
| ✅ **Day 27 完了** | ~~残 variants (decompose / refine) payload 拡充~~ — Day 27 で `decomposeOf (parent child : Hypothesis)` + `refineOf (target refined : Hypothesis)` 2 variants backward compatible 追加、accessor `isDecomposeOf` / `isRefineOf` 追加、**5 variant 全 payload 対応 milestone 達成**。Test +10 example (example 33→43)、build 130 jobs 維持。P2 Subagent 省略 (Day 26 additive pattern already-validated) | 5 variant 全 payload milestone | Day 27 |
| ✅ **Day 28 完了** | ~~dedup 実装判断~~ — D16 presentation-layer dedup 採用 (`#check_retired_auto` に `.eraseDups`、storage 維持)。Day 25 test 期待値 total 8→7 / watched 7→6 NS 同期。build 130 jobs 維持、P2 Subagent 省略 (設計判断型、pattern-symmetric) | Day 25 observe-first 決着 | Day 28 |
| ✅ **Day 29 完了** | ~~section refactor~~ — RetirementLinterCommandTest.lean の section comment を refactor (Day 25 Subagent I2 = 3 session 繰り延べ解消)。各 Day section は baseline のみ、現状値はインライン分離。behavior/example 不変、build 130 jobs 維持、Subagent 省略 (comment-only、pattern-symmetric) | Day 25 Subagent I2 解消 | Day 29 |
| ✅ **Day 30 完了** | ~~WasDerivedFrom DAG 制約~~ — ProvRelation.lean に `TransDerived` inductive + `Acyclic` def + `TransDerived.empty_false` + `Acyclic.empty` 追加。Test +3 example (空 acyclic / 不在 / self-loop non-acyclic)。既存 structure 変更なし、build 130 jobs | Day 30 | commit |
| 🟡 Day 31 | DecidableEq 手動実装 or Acyclic decidable 版 or A-Maximal 前倒し | 残候補 | Day 31 |
| 🟡 Day 19+ | **Day 15 `@[retired]` macro fixture × Day 18 `#check_retired` 連携テスト追加** (Subagent I2 Day 18、A-Standard ← A-Compact 連携完全実証) | TyDD-G3 + Subagent I2 Day 18 | Day 19+ (Day 18 paper サーベイで新規識別) |
| 🟢 Week 5-6 | **A-Maximal: elaborator 型レベル強制** — compile error で退役違反 rejection | TyDD-G3 + §4.4 | Week 5-6 Tooling 層 (本丸案件) |
| 🟡 Day 16+ | **ResearchActivity payload 拡充** (investigate / decompose / refine / retire variants、verify variant と同パターン) — Day 13 WasRetiredBy 案 C で考察した拡張 | 02-data-provenance §4.1 (Day 13 paper サーベイで再認識) | Day 16+ (Day 9 paper サーベイから継続、Day 13-15 で繰り延べ明示) |
| 🟡 Week 6-7 | **02-data-provenance §4.7 RO-Crate 互換 export** — Lean tree → JSON-LD schema-preserving 変換 (Lean meta-program)、外部 tool (WorkflowHub, Galaxy) との interop 確保 | 02-data-provenance §4.7 | Week 6-7 (CI 整備時) (Day 6 paper サーベイ評価で識別) |
| 🟢 Week 5-6 | **02-data-provenance §4.5 Pipeline 段階表現** — DSL ≤ AST ≤ LeanSpec ≤ SMTSpec ≤ Tests ≤ Code を Spec 精緻化として Lean で表現 (Snakemake rule 対応) | 02-data-provenance §4.5 | Week 5-6 Tooling 層 (Day 6 paper サーベイ評価で識別) |
| 🟢 Day 7+ | **S6 Paper 1 (BST/AVL invariants)** — Hypothesis chain の order を invariant 付き structure 化 (Evolution と統合時) | S6 TyDe 2025 Paper 1 | Day 7+ (Evolution と統合) (Day 6 paper サーベイ評価で識別、Section 2.10 既存項目から Day 7+ に具体化) |

**根拠**: Section 12.10 Day 4 論文サーベイ評価結果テーブル。8 件の未活用 finding の優先度別対処計画。


> **Note (Day 29.1)**: Section 2.11-2.58 (Day 6-29 per-Day 着手前判断 + 評価) は [11-pending-tasks-archive.md](./11-pending-tasks-archive.md) へ退役。
> 過去の per-Day narrative は git log / 各 Lean file docstring D-entry でも参照可。

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
| **Day 11** ✅ | Day 10 議論で確定済 Q1-Q4 (Section 2.20): **Q1 A 案** = PROV-O relation 3 structure + **Q2 A-Minimal** = 3 structure + Test 2-3 + **Q3 案 A** = 3 separate structure (`WasAttributedTo` / `WasGeneratedBy` / `WasDerivedFrom`、PROV-O 1:1 対応) + **Q4 案 A** = 02-data-provenance §4.1 厳格 type (Entity × Agent / Entity × Activity / Entity × Entity): `AgentSpec/Provenance/ProvRelation.lean` (3 structure 統合配置) + `AgentSpec/Test/Provenance/ProvRelationTest.lean` (22 example、PROV-O triple set 統合 example 含む) + Subagent 遡及検証 PASS (改訂 49 で対処、addressable なし、informational 4 件) | Section 2.20 (Day 11 着手前判断) + Section 12.31-12.33 (Day 11 評価導出) + 02-data-provenance §4.1 (PROV-O §4.1 完全カバー到達) / commit `11a32bd` |
| **Day 12** ✅ | Day 11 議論で確定済 Q1-Q4 (Section 2.22): **Q1 A 案** = RetiredEntity (02-data-provenance §4.4 完全カバー) + **Q2 A-Minimal** = `structure RetiredEntity` + `inductive RetirementReason` + Test + **Q3 案 A** = RetirementReason 4 variant 型化 (`Refuted (failure : Failure)` / `Superseded (replacement : ResearchEntity)` / `Obsolete` / `Withdrawn`、Failure 経由も payload で両立) + **Q4 案 A** = separate structure 配置 (Day 11 ProvRelation パターン踏襲、ResearchEntity 拡張不要 backward compatible): `AgentSpec/Provenance/RetiredEntity.lean` (NEW、5 smart constructor + trivial + whyRetired) + `AgentSpec/Test/Provenance/RetiredEntityTest.lean` (NEW、22 example、Day 11 Subagent I3 教訓反映で全 example rfl preference 維持) + Subagent 検証 PASS (本 cycle 内即時実施、改訂 56 で I1+I2 即時対処) | Section 2.22 (Day 12 着手前判断) + Section 12.31-12.33 (Day 11 評価導出) + 02-data-provenance §4.4 (退役 entity の構造的検出) / commit `49510c6` |
| **Day 13** ✅ | Day 12 議論で確定済 Q1-Q4 (Section 2.24): **Q1 A 案** = PROV-O auxiliary relations + WasRetiredBy (relation 系 grouping) + **Q2 A-Minimal** = `WasInformedBy` + `ActedOnBehalfOf` + `WasRetiredBy` の 3 structure 1 ファイル統合 + Test + **Q3 案 B** = 新 `ProvRelationAuxiliary.lean` 別 file 配置 (3 main は ProvRelation.lean に維持、main / auxiliary を file 単位で構造化) + **Q4 案 A** = `WasRetiredBy { entity : ResearchEntity, retired : RetiredEntity }` (Entity 経由 2-arg relation、Day 11 ProvRelation 同パターン、Day 12 RetiredEntity 再利用): `AgentSpec/Provenance/ProvRelationAuxiliary.lean` (NEW、3 structure 統合配置) + `AgentSpec/Test/Provenance/ProvRelationAuxiliaryTest.lean` (NEW、24 example、Day 11 教訓継続で全 example rfl preference 維持) + Subagent 検証 PASS (本 cycle 内即時実施、改訂 61 で I1 即時対処) + Day 12 I1 教訓先回り適用 (version field 正しく設定で Subagent 検出 4→1 減少) | Section 2.24 (Day 13 着手前判断) + Section 12.37-12.39 (Day 13 評価導出) + 02-data-provenance §4.1 auxiliary + §4.4 retirement relation / commit `40ccd78` |
| **Day 14** ✅ | Day 13 議論で確定済 Q1-Q4 (Section 2.26): **Q1 A 案** = RetiredEntity linter / elaborator (新分野、Day 12-13 構造完備の強制化) + **Q2 A-Minimal** = Lean 4 標準 `@[deprecated]` 付与 + Test + **Q3 案 A** = `@[deprecated "退役済 entity - RetirementReason を確認 (Day 14 linter A-Minimal)" (since := "2026-04-18")]` を test fixture に手動付与 + **Q4 案 C** = production code docstring 使用例 + Test は rfl 確認のみ (Day 11-14 = 4 Day 連続 rfl preference 維持): `AgentSpec/Provenance/RetiredEntity.lean` MODIFY (4 deprecated fixture: refutedTrivialDeprecated / supersededTrivialDeprecated / obsoleteTrivialDeprecated / withdrawnTrivialDeprecated + docstring D1-D2 + 使用例) + `AgentSpec/Test/Provenance/RetiredEntityTest.lean` MODIFY (22→30 example、+8) + Subagent 検証 PASS (本 cycle 内即時実施、改訂 66 で I1 即時対処、Day 13-14 で検出項目数 1 安定) + Pattern #7 hook MODIFY path 対応確認 = 七段階発展完了 | Section 2.26 (Day 14 着手前判断) + Section 12.40-12.42 (Day 14 評価導出) + 02-data-provenance §4.4 (退役 entity 強制化) / commit `13c4e77` |
| **Day 15** ✅ | Day 14 議論で確定済 Q1-Q4 (Section 2.28): **Q1 A 案** + **Q2 A-Compact-Hybrid** + **Q3 案 B** + **Q4 案 A**: `AgentSpec/Provenance/RetirementLinter.lean` (NEW、macro_rules 定義、Lean 4 elab macro で `@[retired msg since]` → `@[deprecated msg (since := since)]` 展開) + `AgentSpec/Test/Provenance/RetirementLinterTest.lean` (NEW、9 example) + Day 14 backward compatible 完全維持 (production RetiredEntity.lean / RetiredEntityTest.lean 変更なし) + Subagent 検証 PASS + **I1 初 addressable 逆方向修正** (改訂 71、docstring ← 実装 align、Lean 4 parser 仕様根拠) + linter_status A-Minimal + A-Compact 完了 + version `0.15.0-week2-day15` + 初期 build error からの即時修復 ($msg:str 型注釈) + cycle 内学習 transfer cross-verification 発展 | Section 2.28 (Day 15 着手前判断) + Section 12.43-12.45 (Day 15 評価導出) + TyDD-G3 + 02-data-provenance §4.4 / commit `17db6ef` |
| **Day 16** ✅ | Day 15 議論で確定済 Q1-Q4 (Section 2.30): **Q1 B 案** + **Q2 A-Compact** + **Q3 案 A** + **Q4 案 A**: `AgentSpec/Spine/EvolutionStep.lean` MODIFY (transitionLegacy @[deprecated] 付与 + TransitionReflexive/Transitive 4-arg 直接展開 refactor) + `AgentSpec/Test/Spine/EvolutionStepTest.lean` MODIFY (+4 example: 9→13、deprecated 動作確認 + 新 signature 直接展開 proof) + Section 2.15 Day 9+ 繰り延べ 6 セッション課題 A-Compact で半解消 + Day 8 D3 暫定方針撤回 (Section 2.9 完結) + Subagent 検証 PASS + **I1 docstring 明文化 + I2 evaluator back-fill 対処** (改訂 76) + 新規 `deprecation_history` field + version `0.16.0-week2-day16` + Pattern #7 hook 九段階発展完了 + cycle 内学習 transfer 4 形態体系化完了 | Section 2.30 (Day 16 着手前判断) + Section 12.46-12.48 (Day 16 評価導出) + Section 2.15 (6 セッション繰り延べ半解消) + Section 2.9 (完結) + TyDD-G3 別分野転用 / commit `b678856` |
| **Day 17** ✅ | Day 16 議論で確定済 Q1-Q4 (Section 2.32): **Q1 A 案** + **Q2 A-Medium** (Section 2.32 「4 件削除」は誤記、実態 3 件) + **Q3 案 A** + **Q4 案 A** (deprecated 利用 example **3 件** 全削除、例 13→10): EvolutionStepTest.lean (MODIFY 先行、-3 example) + EvolutionStep.lean (MODIFY 後続、transitionLegacy 定義完全削除 + Day 17 D7 意思決定ログ) + artifact-manifest (deprecation_history.removal_actual + complete_lifecycle + section_2_15_completely_resolved_day17 + example_count 367→364) + version `0.17.0-week2-day17` + **breaking change** compatibility classification + Day 11-17 = **7 Day 連続 rfl preference 維持記録更新** + **Day 9-17 で初の Subagent 指摘ゼロ到達** (cycle 内学習 transfer 累積効果極致実例、quality loop 完全機能実証、maturity 到達) + Pattern #7 hook 十段階発展到達 (breaking change commit 対応確認) | Section 2.32 (Day 17 着手前判断) + Section 12.49-12.51 (Day 17 評価導出) + Section 2.15 Day 9+ 9 セッション繰り延べ課題完全解消 (agent-manifesto 内最長記録) + 段階的 deprecation → removal 工学的 best practice 4 Day 完結 (Day 14→15→16→17) + cycle 内学習 transfer 2 段階別分野転用の 3 Day 完結 (Day 14→16→17) / commit `a8bcf69` |
| **Day 18** ✅ | Day 17 議論で確定済 Q1-Q4 (Section 2.34): **Q1 A 案** + **Q2 A-Minimal** + **Q3 案 A** + **Q4 案 A**: `AgentSpec/Provenance/RetirementLinterCommand.lean` (NEW、`elab "#check_retired " ident : command` + `Lean.Linter.isDeprecated` API) + `AgentSpec/Test/Provenance/RetirementLinterCommandTest.lean` (NEW、6 example + 5 command invocation) + linter_status A-Standard A-Minimal Day 18 完了 (3/4 段階目) + version `0.18.0-week2-day18` + **段階的 Lean 機能習得 3/4 段階目達成** + Pattern #7 hook 十一段階発展到達 + Day 11-18 = 8 Day 連続 rfl preference 維持記録更新 + 初期 build error 即時修復 2 度目実例 (Day 15 parser 状態競合パターン継続) + **Day 17 指摘ゼロ持続性検証結果** (addressable 0 維持、informational 2 は design space richness、structural quality vs design space 区別明確化) | Section 2.34 (Day 18 着手前判断) + Section 12.52-12.54 (Day 18 評価導出) + TyDD-G3 段階的 Lean 機能習得 3/4 段階目 + Lean.Elab.Command + Lean.Linter.isDeprecated API / commit `f127774` |
| **Day 19** ✅ | Day 18 議論確定済 Q1-Q4 (Section 2.36): `RetirementLinterCommand.lean` MODIFY (`#check_retired_in_namespace` + Day 19 D4-D5 意思決定ログ) + `RetirementLinterCommandTest.lean` MODIFY (example 6→7、command invocations 5→8: RetiredEntity 4 retired / Failure 0 / EvolutionStep 0 (Day 17 削除再確認)) + linter_status A-Standard-Lite Day 19 完了 + version day19 + **Pattern #7 hook 十二段階発展到達** + **Day 11-19 = 9 Day 連続 rfl preference** + initial build error pattern 3 度目確立 + Subagent I1/I2 即時対処 (改訂 92)、I3 Day 20+ 継続 | Section 2.36 + Section 12.55-12.57 / commit `682364d` |
| **Day 20** ✅ | Day 19 議論確定済 Q1-Q4 (Section 2.38): `RetirementLinterCommand.lean` MODIFY (`#check_retired_in_namespace_with_depth` + Day 20 D6-D7) + Test MODIFY (example 7 維持、command invocations 8→11、3 invocations: RetiredEntity depth=1 4/Provenance depth=2 5 (Role.toCtorIdx 顕在化)/EvolutionStep depth=10 0 (Day 17 削除再々確認)) + linter_status A-Compact nested Day 20 完了 + version day20 + **Pattern #7 hook 十三段階発展到達** + **Day 11-20 = 10 Day 連続 rfl preference milestone** + Subagent I1 即時対処 / I2/I3 Day 21+ 繰り延べ | Section 2.38/2.39/2.40 + Section 12.58-12.60 + Day 19 Subagent I2 / commit `7fa8f51` |
| **Day 21** ✅ | Day 20 議論確定済 (Section 2.40): `RetirementLinterCommand.lean` MODIFY (`#check_retired_auto` + Day 21 D8-D9) + Test MODIFY (example 7、command invocations 11→12→13、+1 #check_retired_auto + 改訂 100 で +1 連携テスト invocation) + linter_status A-Standard-Full Day 21 完了 + version day21 + **Pattern #7 hook 十四段階発展到達** + **Day 11-21 = 11 Day 連続 rfl preference** + **改訂 100: Subagent initial FAIL → I1 即時対処 PASS / I2 docstring 即時 / I3 long-deferred 4 セッション解消で実装追加** (Day 15 @[retired] × Day 18 #check_retired 連携テスト追加、A-Compact ← A-Standard A-Minimal 連携完全実証成功) / I4 Day 22+ 投資 (Role.toCtorIdx) | Section 2.40/2.41/2.42 + Section 12.61-12.63 + Day 18-20 Subagent I3 解消 / commit `18c5e94` |
| **Day 22** ✅ | Day 21 議論確定済 Q1-Q4 (Section 2.42): `RetirementLinterCommand.lean` MODIFY (`SimplePersistentEnvExtension` + `register_retirement_namespace` + `defaultWatchedRetirementNamespaces` + `getWatchedRetirementNamespaces` + Day 22 D10-D12) + Test MODIFY (example 7→8、command invocations 13→15、+1 example: defaultWatchedRetirementNamespaces type-level、+1 register、+1 second auto check) + linter_status A-Standard-Full-Standard A-Minimal Day 22 完了 + version day22 + **Pattern #7 hook 十五段階発展到達** + **Day 11-22 = 12 Day 連続 rfl preference** + **env iteration map₁→toList correctness fix** (Day 18-21 同 module 3 commands 同時改善、output 変化なし) + Subagent PASS + I1 即時対処 (build_status.note 数値齟齬訂正) | Section 2.42/2.43/2.44 + Section 12.64-12.66 + Day 21 Subagent I4 / commit `e6d9b1f` |
| **Day 23** ✅ | Day 22 議論確定済 Q1-Q4 (Section 2.44): 新 helper module `RetirementWatchedFixture.lean` (NEW、test scope 専用) + `RetirementLinterCommand.lean` MODIFY (D13 docstring) + `RetirementLinterCommandTest.lean` MODIFY (example 8→9、command invocations 15→16、+1 example: importPropagateFixture 参照、+1 #check_retired invocation) + AgentSpecTest.lean import 追加 + linter_status multi-module import propagate test 完了 + version day23 + **Pattern #7 hook 十六段階発展到達** (新規 file + MODIFY 混在 pattern 初適用、両パターン運用 11 度目) + **Day 11-23 = 13 Day 連続 rfl preference** + Subagent PASS + 0 addressable + 4 informational 全件即時対処 (6 Day 連続 cycle 内即時修復) | Section 2.44/2.45/2.46 + Section 12.67-12.69 + Day 22 Subagent informational I1 / commit `7b95180` |
| **Day 24** ✅ | Day 23 議論確定済 Q1-Q4 (Section 2.46): RetirementLinterCommand.lean docstring MODIFY (D14 investigation log) + ResearchAgent.lean docstring MODIFY (Day 24 追記 toCtorIdx rename 注記) + RetirementLinterCommandTest.lean MODIFY (Day 24 section +2 example: Role.ctorIdx rfl + toCtorIdx = ctorIdx rfl、example 9→11、command invocations 16 維持) + linter_status Role.toCtorIdx investigation 解消完了 + version day24 + **Pattern #7 hook 十七段階発展到達** (MODIFY path 8 度目) + **Day 11-24 = 14 Day 連続 rfl preference** + Subagent PASS + 0 addressable + 1 informational 即時対処 (7 Day 連続 cycle 内即時修復) + **Day 22 audit long-deferred 対応 2 例目完遂** + Phase 0 累計 **99.2% 到達** | Section 2.46/2.47/2.48 + Section 12.70-12.72 + Day 22 audit long-deferred / commit `b3be98d` |
| **Day 25** ✅ | Day 24 議論確定済 Q1-Q4 (Section 2.48): 新 helper2 module `RetirementWatchedFixture2.lean` (NEW、test scope 専用、@[retired] importPropagateFixture2 + 独立 + duplicate register) + RetirementLinterCommand.lean docstring MODIFY (D15 observe-first 方針) + RetirementLinterCommandTest.lean MODIFY (Day 25 section +1 example + 1 #check_retired_auto invocation、example 11→12、command invocations 16→17) + AgentSpecTest.lean import 追加 + linter_status multi-source duplicate handling observe-first 完了 + version day25 + **Pattern #7 hook 十八段階発展到達** (新規 file + MODIFY 混在 pattern 2 度目) + **Day 11-25 = 15 Day 連続 rfl preference** + Subagent PASS + 0 addressable + 2 informational 即時対処 (8 Day 連続 cycle 内即時修復) + **Day 22 audit long-deferred 対応 3 例目完遂** (Day 22-24 = 3 session 繰り延げ解消) + Phase 0 累計 **99.2% 維持** | Section 2.48/2.49/2.50 + Section 12.73-12.75 + Day 22 Subagent informational I2 / commit `b9d0dd8` |
| **Day 26** | Day 25 議論で確定 Q1-Q4 (Section 2.50): 🔴 ResearchActivity payload 拡充 (Day 13-22 = 12 Day 連続繰り延べ、Day 24 audit 次 long-deferred candidate 解消、Day 27+ 長期化防止) | Section 2.49 + Section 12.73-12.75 + Day 24 audit 次 long-deferred |
| **Day 20+** | **Day 18 評価で繰り延べ + 新規識別項目**: 🟡 Day 15×Day 18 連携テスト (Subagent I2、A-Standard ← A-Compact 連携完全実証) / 🟡 ResearchActivity payload 拡充 (Day 13-15 から継続) / 🟢 A-Standard-Full elaborator hook (Day 19+ or Day 20+) / 🟢 ResearchEntity DecidableEq 手動実装 / 🟢 EvolutionStep 完全 4 member 化 / 🟢 G5-1 §3.4 step 2 LearningM indexed monad / 🟢 A-Maximal elaborator 型レベル強制 (Week 5-6 Tooling 層本丸、4/4 段階目) / 🟢 Day 14 + Day 15 両モデル cross-interaction test 拡張 / 🟢 WasDerivedFrom DAG 制約 (Subagent I2 Day 11、Section 2.21/.../2.35 継続) + **Day 6-17 評価繰り延べ項目**: 🟡 §4.6 Nextflow resume + Galaxy job cache / 🟡 Hypothesis rationale 型化 / 🟡 Failure payload 型化 / 🟡 Verdict payload 拡充 / 🟢 S6 Paper 1 BST/AVL invariants / 🟢 Evolution DecidableEq / 🟢 HandoffChain concat / 🟢 HandoffChain 全体 embed 用 constructor。または **Manifest 移植** (Week 3-4) または **Lean-Auto research/PoC** (Section 2.10 🔴) を並行開始 | Week 3-4 (Manifest) / Week 4-5 (LearningM) / Week 6 (Lean-Auto) / Section 2.10 + 2.12 + 2.13 + 2.15 + 2.17 + 2.19 + 2.21 + 2.23 + 2.25 + 2.27 + 2.29 + 2.31 + 2.33 + 2.35 |

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


> **Note (Day 29.1)**: Section 12.6-12.79 (Day 2-29 per-Day TyDD / 論文サーベイ評価) は [11-pending-tasks-archive.md](./11-pending-tasks-archive.md) へ退役。
> Week boundary 合致度レビューのみ Section 12.1-12.5 で保持。per-Day 評価は git log で参照。

## 13. 更新履歴

> **Note (Day 29.1)**: 改訂 1-124 の per-改訂 log は [11-pending-tasks-archive.md](./11-pending-tasks-archive.md) へ退役。
> 以降、本 Section は新 schema (Day 29.1 以降) 対応の改訂のみ記録。改訂番号は連続しない (archive 参照)。

- 2026-04-20 (**Day 29.1 schema reset**): 両 file の役割を再定義 (artifact-manifest = thin catalog / 11-pending-tasks = forward-looking pending)。per-Day narrative の archive 化、schema_role header 追加、jq recipes doc 新規。breaking change classification。

## マーク凡例

- ✅ **解消済** — 既に実装/記述で反映済み、または実態確認で解消を確認
- 🔄 **Week 2 着手予定** — Week 2 開始時に優先対処する項目
- ⏳ **後続 Week 対処予定** — Week 3 以降の計画済みタスク
- ❓ **判断待ち** — ユーザー判断が必要な項目

**更新方針**: Week 2 以降の各 Week 完了時に、完了項目にマーク (✅) を追加し、残タスクの再優先順位を見直す。新規発見タスクは適切な Section に追記。TyDD 合致度レビュー時は Section 12 を更新。各改訂時に本 Section 13 に履歴を追加。
