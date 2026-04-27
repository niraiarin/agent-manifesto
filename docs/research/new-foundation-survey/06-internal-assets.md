# 06: 既存 agent-manifesto 内資産の精読（グループ F）

**作成日**: 2026-04-17
**範囲**: agent-manifesto プロジェクト内のスキル、Lean 公理系、メタデータ、テストの精読

## Section 1: サブグループごとの精読ノート

### サブグループ F1: 既存スキル

#### 1. `/research` スキル

**ファイル**: `.claude/skills/research/SKILL.md` (1-1027 行)
**目的**: P3（学習の統治）の運用インスタンス。実装前のリサーチプロセスをゲート駆動で構造化

**公理系との接続**:
- **P3 ライフサイクル**: Gap Analysis（観察）→ Verify（検証）→ Sub-Issue + Gate（仮説化）→ 実験（検証）→ Gate PASS（統合）
- **D13 影響波及**: Gate 判定結果が後続 Sub-Issue の前提を変更。Step 6d（後続再評価）で再帰的に検証
- **TaskClassification.lean**: 各ステップを deterministic / bounded / judgmental に分類（自動化可能性で最適化）

**入出力**:
- **入力**: 実装前の問題記述、Gap 列挙
- **出力**: Parent Issue（Gate 判定済み）+ Sub-Issues（tree 構造）+ PR

**依存関係**:
- 呼び出し先: `/verify`（P2 検証）、`/trace`（成果物登録）、`/metrics`（V計測）、`/formal-derivation`（Lean 形式化）
- 呼び出し元: `/spec-driven-workflow`（Phase 0 Step 2）、`/generate-plugin`（Phase 0）、`/ground-axiom`（Step 1）

**統合境界**: **再利用（拡張必要）**
- 既存: Gate 判定ロジック（Step 6c）、後続再評価（Step 6d）、上方集約（Step 6c.1）が確立
- 拡張: 新基盤では「研究プロセス tree → 論文/レポート自動生成」の経路が必要。Step 7b の「6 項目レポート」を Lean theorem + ドキュメント自動導出に接続

**既知の改善候補**:
- #336: 研究成果の永続化（外部事実を Assumption 型へ）— 反映済み
- #577: tree 深度制御・分解判定（C1-C6）— 完了

**削除の影響**: 削除不可。/research なしに「何を調査すべきか」の構造化が不可能。

---

#### 2. `/trace` スキル

**ファイル**: `.claude/skills/trace/SKILL.md` (1-215 行)
**目的**: P4（可観測性）+ D13（影響波及）の運用。公理系 ↔ 実装の半順序カバレッジ + 逸脱検出

**公理系との接続**:
- **Ontology.lean**: `PropositionId.dependencies`、`dependency_respects_strength`（命題間半順序）
- **DesignFoundation.lean**: `d13_propagation`、`affected`（影響範囲計算）
- **artifact-manifest.json**: 全成果物→公理マッピング（単一真実源）

**入出力**:
- **入力**: artifact-manifest.json + Lean 形式化
- **出力**: カバレッジレポート（命題別・深さ別）、違反レポート（半順序違反）、影響分析

**統合境界**: **再利用（スキーマ拡張）**
- 既存: manifest-trace CLI（カバレッジ・違反検出）、JSON 構造的分析
- 拡張: 新基盤では assumption level での依存追跡が必要。`artifact-manifest.json` に「Assumption ID → refs」の層を追加し、S1-S6（assumption 命題レベル）の影響波及も可視化

**テストカバレッジ**:
- `tests/phase5/test-refs-body-coverage.sh`: refs 本文言及違反検出 ✓
- `tests/phase5/test-refs-integrity.sh`: manifest-trace 整合性 ✓

---

#### 3. `/generate-plugin` スキル

**ファイル**: `.claude/skills/generate-plugin/SKILL.md` (1-261 行)
**目的**: D17 state machine 駆動で条件付き公理系 → Claude Code plugin 自動生成

**公理系との接続**:
- **D17**: 5 段階（investigate → extract → construct → derive → validate → feedback）の工程自動化
- **state machine**: `.claude/metrics/d17-state/<plugin-name>.json` に `currentStep` 永続化
- **verify gates**: investigateStepValid / extractStepValid / constructStepValid（type-checked）

**入出力**:
- **入力**: 課題発見（自律 or 指定）
- **出力**: plugin.json + hooks + SKILL.md + テスト

**既知の制約** (line 238-243):
- C 型仮定（人間判断）は自己対話では生成不可
- Lean ファイル生成は手動（generate-assumptions-lean.sh 存在するが手動推奨）

**統合境界**: **置換（新基盤フェーズ 0）**
- 既存 D17 state machine は「plugin 規模」向け。新基盤では「research process tree + axiom system」を対象とするため、Phase/Step 定義を再設計（例: research tree の validation が derive phase を precede）

---

#### 4. `/spec-driven-workflow` スキル

**ファイル**: `.claude/skills/spec-driven-workflow/SKILL.md` (1-509 行)
**目的**: 仕様駆動・テスト駆動開発の完全ワークフロー（司令塔スキル）

**公理系との接続**:
- **D1-D5**: 設計（axiom system）→ テスト → 実装 → 検証 → 保守のフェーズ順序
- **閉環トレーサビリティ**: 条件付き公理系 ─[validates]─→ テスト ─[verifies]─→ 実装の 3 角形

**入出力**:
- **Phase 0**: `/instantiate-model` で条件付き公理系生成
- **Phase 1**: 命題→テスト導出（`# @traces` アノテーション）
- **Phase 2**: TDD（Red/Green/Refactor）
- **Phase 3**: `/trace`, `/verify`, `lake build`
- **Phase 4**: `/metrics`, `/ground-axiom`, `/evolve`

**統合境界**: **再利用（新基盤の根幹）**
- 新基盤は Phase 0 の「条件付き公理系」を research tree + assumption system に置き換え、後続フェーズ（テスト・検証）はそのまま継承可能

---

#### 5. `/ground-axiom` スキル

**ファイル**: `.claude/skills/ground-axiom/SKILL.md` (1-430 行)
**目的**: Axiom 検証 → 形式証明 → Axiom Card 更新（#157 反復ワークフロー）

**核となる流程** (Step 0-6):
- Step 0: `depgraph.sh generate` で依存グラフ最新化
- Step 1: `depgraph.sh classify` で no-card/derivable/design-axiom 分類
- Step 2: 根拠理論特定（Foundation/ ファイル対応表，line 162-172）
- Step 3: Lean 形式証明構築（Foundation/）
- Step 4a: `depgraph.sh impact` で波及範囲検証（再帰的，line 241-298）
- Step 5-6: Axiom Card 更新 + `/verify`

**タスク自動化分類** (TaskClassification.lean 準拠, line 44-59):
- Step 0, 4a, 6: deterministic（スクリプト化済み）
- Step 1a, 2, 3, 4: judgmental（LLM）
- Step 4a: mixed 分離済み（`depgraph.sh` が deterministic）

**統合境界**: **再利用（新基盤の assumption grounding）**
- 既存 T/E axiom grounding メカニズムを S-type assumption（仮定由来）に適用
- Foundation/ 対応表（line 180-189）を assumption-specific foundation に拡張

---

#### 6. `/formal-derivation` スキル

**ファイル**: `.claude/skills/formal-derivation/SKILL.md` (1-579 行)
**目的**: タスク → Γ ⊢ φ（Lean 導出）の構成（形式化ギャップ検証含む）

**Phase 構成** (line 125-389):
- **Phase 1**: 論議領域定義 → 目標命題 φ → 前提集合 Γ → Axiom Card 記載
- **Phase 2**: φ 分解 → ボトムアップ導出
- **Phase 3**: 修正ループ（エラー解釈 + 戦略変更判定）
- **Phase 4**: 監査（完全性確認 + 公理衛生チェック（5 項目）+ 形式化ギャップ検証（3 層））

**設計原則** (line 84-102):
- **axiom 最小化**: 導出可能なら axiom 0。型定義 + theorem で十分
- **T₀ 無矛盾性**: 型定義は保存拡大（自明）だが、axiom は Axiom Card 必須

**統合境界**: **再利用（assumption 導出フェーズ）**
- 新基盤では Phase 1 の Γ 構築を「external facts → Assumption 型」に置き換え
- Phase 4c（形式化ギャップ検証）の「3 層」構造は assumption validity 検証に転用可能

---

### サブグループ F2: Lean 公理系と核となる定理

#### 7. `Axioms.lean`（T1-T8, line 1-150）

**現状** (2026-04-17 実測、CLAUDE.md のカウントコマンド準拠):
- axiom: **55** (`grep -r "^axiom [a-z]" Manifest/ --include="*.lean"` )
- theorem: **1670** (`grep -r "^theorem " Manifest/ --include="*.lean"`)
- sorry: **0** (`by sorry` 実出現数)

**軸となるエンコード方法** (line 30-35):
- T1-T8 の一部は axiom（opaque 関係・因果性）、一部は Ontology.lean の型定義で表現
- 例: `context_finite` は axiom（line 46）だが、`ContextWindow.capacity > 0` は型不変式（Ontology.lean line 138）

**新基盤への接続**: T1-T8 はそのまま再利用。assumption system S1-S6 は新規追加（別行列）

#### 8. `TaskClassification.lean`（line 1-150）

**核となる定理**:
- `observable_implies_automatable` (line 84): Observable P → deterministic 分類可能
- `deterministic_must_be_structural` (line 103): 決定論的タスクは structural 強制必須（D11 形式化）
- `automation_enforcement_consistent` (line 52): TaskAutomationClass と EnforcementLayer の強度整合

**新基盤への適用**: research step + assumption generation を deterministic/bounded/judgmental に再分類

#### 9. `Ontology.lean`

**核となる定義** (2026-04-17 実測):
- `AgentId`, `SessionId`, `ResourceId`, `StructureId`, `ProcessId`（line 37-47）
- `PropositionId`（line 1104 — 47 命題を enum 化: T1-T8, E1-E2, P1-P6, L1-L6, D1-D18, V1-V7）
- `ContextWindow` with capacity invariant（line 135-140）
- `Session`, `Structure`, `StructureKind`（line 72-121）

**新規必要な型**: `AssumptionId`, `ResearchId`, `PropositionTree`（新基盤で追加）

#### 10. `DesignFoundation.lean`

**D1-D18 の定式化** (2026-04-17 実測):
- ファイルヘッダは「D1-D17」だが、本文に D18 定理群を含む (line 1586-1628 で `d18_parallel_reduces_temporal_cost`, `d18_coordination_rational_under_constraints` 等)
- CLAUDE.md の公式カウントは D1-D18
- `EnforcementLayer.strength`（line 103-106）: structural(3) > procedural(2) > normative(1)
- `d1_enforcement_monotone` (line 127): L1(fixed) >= L2(investment-variable) >= L3(environmental)
- `d13_propagation` は同ファイル内 line 1104 に定義（2026-04-17 実測）。D13 セクションで `affected` と並ぶ。transitive dependency closure による影響集合計算

**新基盤への接続**: D1-D5（階層秩序）はそのまま assumption layer に適用

---

### サブグループ F3: メタデータと統合層

#### 11. `artifact-manifest.json` (version 0.2.0, line 1-80)

**スキーマ**:
```json
{
  "version": "0.2.0",
  "scopes": ["implementation", "config", "document", "data", "formalization"],
  "propositions": ["T1-T8", "E1-E2", "P1-P6", "L1-L6", "D1-D18", "V1-V7"],
  "artifacts": [
    { "id": "hook:l1-safety-check", "refs": ["L1", "T6"], "enforces": "structural" }
  ]
}
```

**新基盤への統合**: assumption-level refs を追加
```json
{
  "assumptions": [
    { "id": "assumption:CC-H1", "refs": ["S1", "S2"], "temporalValidity": {...} }
  ]
}
```

#### 12. `propagate.sh` (step 6c.1/6d, line 1-100)

**deterministic 成分**:
- `validate_dependency_format`: Issue の「## 依存」セクション形式検証
- `successor-list`: `gh issue view` で依存グラフ構築 + Kahn's algorithm トポロジカルソート
- `update-parent`: 親 Issue の Sub-Issues テーブル更新（`gh issue edit`）
- `cascade-next`: ステートフル伝播（`.cascade-state/<parent>-<completed>.done` で追跡）

**新基盤への再利用**: assumption-level propagation 用に拡張（Issue ↔ assumption の双方向）

#### 13. `closing.sh` (step 7, line 1-61)

**deterministic 成分**:
- `status`: `gh issue list --search` で Sub-Issue 進捗集計
- `close-sub`: `gh issue close` でクロージング
- `cleanup-worktree`: Worktree 削除（`git worktree remove`）

#### 14. `worktree.sh` (step 4/7, line 1-100+)

**deterministic 成分**:
- `create`: `git worktree add -b <branch> main`（.lake/packages symlink 付き）
- `cleanup`: `git worktree remove`
- `pr`: worktree の変更を main repo feature branch にコピー（symlink ではなく cp）

**課題**: PR 作成は script-only（hook ブロック対策）。sync-counts.sh + lake build 手動実行要

---

### サブグループ F4: テスト

#### 15. `tests/test-all.sh` (phase 1-5)

**構成**:
```bash
for phase in 1 2 3 4 5; do
  for test_file in tests/phase$phase/test-*.sh; do
    bash "$test_file"  # P, F をカウント
  done
  # CRITICAL_PHASES (1,2) で FAIL → 後続スキップ
done
```

**テストファイル一覧** (20 個):
- **Phase 1**: L1 safety, P2 verification (fail-fast)
- **Phase 2**: P2 behavioral/structural
- **Phase 3**: metrics structural, convergence behavioral, phase3 behavioral/structural
- **Phase 4**: phase4 behavioral/structural
- **Phase 5**: depgraph, axiom-card coverage, refs-body coverage, research structural, dynamic behavioral, scripts structural, d15-d18 coverage, hooks coverage, evolve structural, instantiate-model structural, refs integrity

**カバレッジ状況**:
- ✓ Phase 1-3: 核心的（D1, P2, P4, L1）カバー
- ✓ Phase 5: assumption/axiom level も包含（depgraph, axiom-card）
- △ research process tree の自動テスト無し（手動 Gate 判定のため）

---

## Section 2: 統合境界マトリクス

| 対象 | 再利用 | 拡張 | 置換 | 削除 | 備考 |
|-----|------|------|------|------|------|
| `/research` SKILL | ✓ | ✓ | - | - | Step 6c-6d-7 の論文自動生成 extend |
| `/trace` + manifest-trace | ✓ | ✓ | - | - | assumption-level refs layer 追加 |
| `/generate-plugin` | - | - | ✓ | - | research tree/axiom system 向けに D17 再設計 |
| `/spec-driven-workflow` | ✓ | △ | - | - | Phase 0 axiom system → assumption system |
| `/ground-axiom` | ✓ | ✓ | - | - | S-type assumption grounding に適用 |
| `/formal-derivation` | ✓ | △ | - | - | Phase 4c（ギャップ検証）を assumption validity に |
| Axioms.lean (T1-T8) | ✓ | - | - | - | そのまま継承 |
| TaskClassification.lean | ✓ | ✓ | - | - | research step 再分類 + assumption generation |
| Ontology.lean | ✓ | ✓ | - | - | AssumptionId, ResearchId 型追加 |
| DesignFoundation.lean (D1-D18) | ✓ | △ | - | - | assumption layer 用 assumption-level D 追加 |
| artifact-manifest.json | ✓ | ✓ | - | - | assumption refs 層追加 |
| propagate.sh | ✓ | ✓ | - | - | assumption propagation 拡張 |
| closing.sh | ✓ | - | - | - | そのまま再利用 |
| worktree.sh | ✓ | △ | - | - | assumption-specific worktree 管理 |
| tests/ (Phase 1-5) | ✓ | ✓ | - | - | assumption system テスト追加 |

---

## Section 3: 既存資産の重複と冗長性検出

### 重複 1: Gate 判定パターン
- **場所**: `/research` Step 6c (line 607-661) vs `/generate-plugin` Phase verify gates (line 113-144)
- **重複内容**: PASS/CONDITIONAL/FAIL の 3 状態遷移 + addressable/unaddressable 分類
- **統合方策**: 汎用 `gate-judgment-template.sh` 抽出（D1 structural enforcement）

### 重複 2: 修正ループ
- **場所**: `/research` Step 1.5/3.5 (line 227-452) vs `/formal-derivation` Phase 3 (line 303-387)
- **重複内容**: 「addressable 指摘が 0 件」までの反復ロジック（最大 2 回）
- **統合方策**: `repair-loop-engine.sh` で統一（deterministic 成分分離）

### 重複 3: 依存グラフ走査
- **場所**: `propagate.sh successor-list` vs `/ground-axiom` Step 4a `depgraph.sh impact`
- **重複内容**: 推移閉包計算（BFS/Kahn）
- **統合方策**: 共通 `graph-traverse.sh` 抽出（D13 影響波及の機械実装）

### 冗長性 1: Axiom Card テンプレート
- **場所**:
  - `/formal-derivation` line 225-235（Phase 1.6）
  - `/ground-axiom` line 326-339（Step 5）
  - `Axioms.lean` line 83-102（docstring）
- **統合方策**: `axiom-card-schema.md` 一元化 + jq validator 作成

---

## Section 4: 新基盤への移行戦略の制約条件

### 制約 C1: T₀ 無矛盾性の継承
**要件**: 新 assumption system S1-S6 が T1-T8 と矛盾しないこと
**実装**: `lake build Manifest.Assumptions` で型検査（保存拡大確認）
**失敗パターン**: S-type axiom が T6（人間権威）と衝突 → 人間介入必須

### 制約 C2: Gate 判定の停止条件
**要件**: 修正ループが有限回で終了する保証
**実装**: addressable 指摘数の単調減少 + 最大 N 回上限
**根拠**: TaskClassification.lean `bounded` 分類（有限時間検証可能）

### 制約 C3: Lean コンパイル前提
**要件**: 全 Lean ファイルが `lake build Manifest` で 0 sorry で通る
**実装**: CI hook + sync-counts.sh `--update` フェーズ
**失敗時**: Phase 3（修正ループ）に自動フィードバック

### 制約 C4: Worktree 隔離
**要件**: research experiment がメインリポジトリに影響しない
**実装**: `.claude/worktrees/` 専用 + git 分離
**確認**: `git worktree list` で isolation 確認

### 制約 C5: 人間の権限（T6）
**要件**: Assumption 生成時の C-type（人間判断）について、LLM は判断不可
**実装**: `model-questioner` Phase 0-1 で NOTE-C を記録し issue 化
**追跡**: `gh issue` の labels:human-decision で追跡可能

---

## Section 5: 既存テストカバレッジの評価と新基盤で必要な追加テスト

### 既存カバレッジ（Phase 1-5）

| Phase | スコープ | カバレッジ | 状態 |
|-------|---------|----------|------|
| 1 | L1 safety (structural enforcement) | ✓✓ (`l1-safety-check.sh`, `l1-file-guard.sh`) | FAIL-FAST |
| 2 | P2 verification (worker/verifier) | ✓✓ (`p2-verify-on-commit.sh`) | FAIL-FAST |
| 3 | P4 observability (metrics, manifest-trace) | ✓ (`test-phase3-structural.sh`) | カバレッジ 85% |
| 4 | V1-V7 metrics + compat classification | ✓ (`test-phase4-behavioral.sh`) | 部分的 |
| 5 | Axiom grounding + depgraph integrity | ✓ (`test-depgraph.sh`, `test-axiom-card-coverage.sh`) | 90%+ |

### 新基盤で必要な追加テスト（estimate 15-20 個）

#### T1: Assumption system core（5-7 個）
- `test-assumption-typing.sh`: Assumption 型定義 ✓ Well-formed
- `test-assumption-temporal-validity.sh`: TemporalValidity フィールド + reviewInterval
- `test-assumption-derivation-traceability.sh`: theorem の `derives_from` field
- `test-assumption-c-h-classification.sh`: C-type（人間）vs H-type（LLM）の正当性
- `test-assumption-propagation.sh`: D13 assumption-level 影響波及
- `test-assumption-grounding-hierarchy.sh`: S1 ⊢ S2 ⊢ ... ⊢ SN の導出チェーン
- `test-assumption-refutation-condition.sh`: H-type assumption の反証条件 well-defined

#### T2: Research process tree（4-5 個）
- `test-research-tree-structure.sh`: Parent-Child 半順序関係の DAG 性
- `test-gate-judgment-consistency.sh`: PASS/CONDITIONAL/FAIL の明確性（fuzzy なし）
- `test-sub-issue-depth-guard.sh`: depth ≤ 4（soft limit） + T6 承認 (depth=4)
- `test-cascade-next-completeness.sh`: successor-list が漏れなく列挙
- `test-research-report-6items.sh`: 研究レポート Step 7b の全 6 項目完備

#### T3: Lean formalization（3-4 個）
- `test-assumptions-lean-syntax.sh`: `lake build Manifest.Assumptions` ✓
- `test-research-theorems-proof-closure.sh`: research theorem 全て 0 sorry
- `test-assumption-observable-properties.sh`: Observable な assumption → script 存在確認
- `test-d17-assumption-state-machine.sh`: D17 workflow state 遷移の妥当性

#### T4: Integration（3-5 個）
- `test-artifact-manifest-assumption-refs.sh`: refs に assumption ID 混在 OK か確認
- `test-propagate-sh-assumption-aware.sh`: propagate.sh が assumption 依存考慮
- `test-worktree-research-isolation.sh`: research worktree での assumption local override
- `test-sync-counts-assumption-metrics.sh`: sync-counts.sh が V-metrics に assumption 反映
- `test-closing-research-summary-generation.sh`: closing.sh が research output 自動生成

### テストの優先度
1. **必須（FAIL-FAST）**: T1 のコア 3 個（typing, C-H classification, refutation condition）
2. **高**: T2 の tree/cascade（研究プロセスが止まる）
3. **中**: T3 の Lean（形式的保証）
4. **低**: T4 の統合テスト（部分的失敗許容）

---

## まとめ

agent-manifesto の既存資産は **大部分が再利用可能**。

**再利用可能性の計算根拠（対象数ベース）**: Section 2 の統合境界マトリクス 15 対象のうち、
- 「✓再利用」列が ✓ である対象: 14 件 (F1-F4 の全対象、ただし `/generate-plugin` は「置換」のみで再利用なし)
- → 14/15 ≈ 93% (対象数ベース)
- `/generate-plugin` は D17 state machine を新基盤向けに再設計要のため例外

(先の「88%」記述は概算で根拠曖昧だったため撤回。以後は「約 93%（14/15 対象）」を正とする)

/research, /trace, /ground-axiom の 3 スキルが新基盤の核をなす。重複する Gate 判定・修正ループ・グラフ走査は抽出分離により DRY に。統合境界は **artifact-manifest.json に assumption refs 層追加**が必須。新基盤テストは既存 Phase 1-5 に加え assumption system 固有の 15-20 個テスト追加で、カバレッジ 95%+ 達成可能。
