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
- **Week 1 からの持ち越し優先タスク** (Section 2 から、Day 5 終了時点の状態):
  - ⚠ **Day 5 部分達成** — 普遍 round-trip 定理 (Section 2.2)。Day 1 で signature + bounded 7³ 証明済、Day 5 で bounded 8³ 拡張 + 6 helper theorems 追加。**universal proof は Day 6/Week 3 へ繰り延べ** (consumeNat correctness + String/List interop で 100+ 行、Lean-Auto 統合 Week 6 で SMT 自動証明可能性あり、Section 2.10 で 🔴 格上げ済)
  - ✅ Day 2 解消 — `lean_lib AgentSpecTest` 分離 (Section 2.3、commit `58b75a0`)
  - ✅ Day 1 解消 — Core.lean に明示的 `import` 文追加 (Section 2.2、commit `a43eef4`)
  - 🔄 継続中 — Top-down / hole-driven 実装スタイル採用 (Section 2.6、Day 1-5 で実践)
  - ✅ **Day 1-5 完了** — FolgeID (GA-S2) Day 1 / Edge (GA-S4) Day 2 / EvolutionStep + SafetyConstraint (GA-S1) Day 3 / LearningCycle + Observable (GA-S1) Day 4 で **Section 1 Week 2-3 完了基準 (4 type class + dummy instance) 達成**。**Day 5 で順序関係完備** (LearningStage LE/LT + FolgeID PartialOrder/LT)。Edge dependent type 化は Week 4-5 (Section 2.8)、SafetyConstraint Bool→Prop は Day 4 で前倒し完了 (Section 2.9 🔴 解消)、**Pattern #7 hook 化は Day 5 で構造的解決** (Section 6.2.1 完全実装)。Ord (lex total order) は Day 6+/Week 4-5 へ繰り延げ

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

#### Day 7 想定 (参考、Day 6 完了後)

| ファイル | 内容 |
|---|---|
| `AgentSpec/Process/Evolution.lean` | `inductive Evolution` (Hypothesis 依存、step transition + EvolutionStep B4 4-arg post 統合、Section 2.9 残課題解消) |
| `AgentSpec/Process/HandoffChain.lean` | `inductive HandoffChain` (T1 一時性、handoff sequence 表現) |
| Test 2 ファイル | cross-process interaction test (Hypothesis × Failure × Evolution) 含む |

#### Day 8+ 想定 (参考、Provenance 層着手)

| ファイル | 内容 |
|---|---|
| `AgentSpec/Provenance/ResearchEntity.lean` | `inductive ResearchEntity` (02-data-provenance §4.1) |
| `AgentSpec/Provenance/ResearchActivity.lean` | `inductive ResearchActivity` |
| `AgentSpec/Provenance/ResearchAgent.lean` | `structure ResearchAgent` |
| `AgentSpec/Provenance/Mapping.lean` | `Hypothesis.toEntity` / `Failure.toEntity` / `Evolution.toActivity` 等 mapping 関数 |
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
| **Day 6** | **Process 層 hole-driven 着手** (Week 4-5 前倒し): `AgentSpec/Process/Hypothesis.lean` (inductive Hypothesis + dummy instance) + `AgentSpec/Process/Failure.lean` (inductive Failure + FailureReason inductive + dummy instance) + Test 2 ファイル **+ Day 5 評価 Section 12.13 から**: PROV-O vocabulary alignment in docstring (Option C、02-data-provenance §4.1 paper finding 顕在化を docstring 注記レベルで先行記録) **+ Day 1-5 確立パターン適用**: hole-driven minimal、universe u 明示、instance 明示命名 | Week 4-5 Process 層 (前倒し) / Section 2.X / 12.13 (PROV mapping) |
| **Day 7** | Process 層継続: `AgentSpec/Process/Evolution.lean` (Hypothesis 依存 inductive + EvolutionStep B4 4-arg post 統合、Section 2.9 残課題解消) + `AgentSpec/Process/HandoffChain.lean` (T1 一時性 inductive、handoff sequence) + Test 2 ファイル **+ Day 6 評価から**: cross-process interaction test (Hypothesis × Failure × Evolution の relation) | Week 4-5 Process 層 + Section 2.9 (B4 4-arg post 解消) |
| **Day 8+** | **Provenance 層着手**: `AgentSpec/Provenance/{ResearchEntity, ResearchActivity, ResearchAgent}.lean` の Lean 化 + mapping 関数 (`Hypothesis.toEntity` / `Failure.toEntity` 等) + 02-data-provenance §4.1-4.4 完全実装の段階的開始。または **Manifest 移植** (Week 3-4) または **Lean-Auto research/PoC** (Section 2.10 🔴 対応) を並行開始 | Week 3-4 (Manifest) / Week 4-5 (PROV-O) / Week 6 (Lean-Auto 前倒し) |

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

## マーク凡例

- ✅ **解消済** — 既に実装/記述で反映済み、または実態確認で解消を確認
- 🔄 **Week 2 着手予定** — Week 2 開始時に優先対処する項目
- ⏳ **後続 Week 対処予定** — Week 3 以降の計画済みタスク
- ❓ **判断待ち** — ユーザー判断が必要な項目

**更新方針**: Week 2 以降の各 Week 完了時に、完了項目にマーク (✅) を追加し、残タスクの再優先順位を見直す。新規発見タスクは適切な Section に追記。TyDD 合致度レビュー時は Section 12 を更新。各改訂時に本 Section 13 に履歴を追加。
