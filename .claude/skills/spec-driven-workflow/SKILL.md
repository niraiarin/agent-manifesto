---
name: spec-driven-workflow
user-invocable: true
description: >
  仕様駆動・テスト駆動開発の完全ワークフロー。条件付き公理系（Lean 設計書）の
  生成から、テスト計画導出、実装、閉環トレーサビリティ検証、保守運用までを
  一貫して実行する。既存スキル群を統合した開発ライフサイクルの司令塔。
  「仕様駆動」「spec-driven」「テスト駆動」「TDD」「ワークフロー」
  「開発ライフサイクル」「development workflow」で起動。
dependencies:
  invokes:
    - skill: instantiate-model
      type: hard
      phase: "Phase 0 Step 1"
    - skill: research
      type: hard
      phase: "Phase 0 Step 2"
    - skill: formal-derivation
      type: hard
      phase: "Phase 2 Step 4"
    - skill: trace
      type: hard
      phase: "Phase 3 Step 1"
    - skill: verify
      type: hard
      phase: "Phase 3 Step 2"
    - skill: metrics
      type: hard
      phase: "Phase 4 Step 3"
    - skill: ground-axiom
      type: hard
      phase: "Phase 4 Step 4"
    - skill: evolve
      type: hard
      phase: "Phase 4 Step 5"
---
<!-- @traces D1, D2, D3, D4, D5, P2, P3, P4 -->

# Spec-Driven Development Workflow

条件付き公理系を設計書とする仕様駆動・テスト駆動開発の完全ワークフロー。

## Manifesto Root Resolution

このスキルは agent-manifesto リポジトリのファイル（Lean 形式化、docs/、scripts/、tests/）を参照する。
実行前に以下でリポジトリルートを解決すること:

```bash
MANIFESTO_ROOT=$(bash .claude/skills/shared/resolve-manifesto-root.sh 2>/dev/null || echo "")
```

解決できない場合はユーザーに案内する。以降の `lean-formalization/`、`docs/`、`scripts/`、`tests/` への参照は `${MANIFESTO_ROOT}/` を前置して解決する。

## 思想

```
設計書 = T₀ ∪ Γ\T₀(requirements, constraints) ⊢ D_project
```

設計書は自然言語文書ではなく **条件付き公理系（Lean 文書）** である。
人間による解読性は最低優先度。公理系の厳密定義が全ての起点となる。

成果物に含まれる全ての主張は、条件付き公理系の命題に帰着可能でなければならない。
これを **閉環トレーサビリティ** と呼ぶ。

```
条件付き公理系 ─[validates]─→ テスト ─[verifies]─→ 実装
       ↑                                              │
       └──────────────[justifies]──────────────────────┘
```

## 先行研究基盤

| 分野 | 研究 | 本ワークフローでの対応 |
|---|---|---|
| RT 古典 | Ramesh & Jarke (2001) 4リンク型 | validates / verifies / justifies / Axiom Card |
| 仕様駆動 | Event-B 段階的精緻化 | 公理系 → テスト → 実装の精緻化チェーン |
| 形式検証 | seL4 3段階精緻化 | Lean 型検査 = Satisfy リンクの自動検証 |
| DbC | Meyer (1997) 共配置原則 | `# @traces` アノテーション |
| 影響分析 | D13 推移的閉包 | `manifest-trace impact` |

詳細: `docs/research/items/requirements-traceability-survey.md`

## Lean 形式化との対応

| ワークフローの概念 | Lean ファイル | 定理/定義 |
|---|---|---|
| 閉環の完全性 | Traceability.lean | `TraceMatrix.closedLoop` |
| 命題カバレッジ | Traceability.lean | `fullPropositionCoverage` |
| テストリンク | Traceability.lean | `fullTestLinkage` |
| 実装正当性 | Traceability.lean | `fullArtifactJustification` |
| D13 影響→テスト | Traceability.lean | `impactedTests`, `impactedArtifacts` |
| 閉環→影響カバー | Traceability.lean | `closedLoop_implies_impact_covered` |
| 命題依存 | Ontology.lean | `PropositionId.dependencies` |
| 強度順序 | Ontology.lean | `PropositionCategory.strength` |
| 互換性分類 | Ontology.lean | `CompatibilityClass` |
| バージョン遷移 | Evolution.lean | `VersionTransition` |

## 使用するツール

| Phase | ツール | 役割 |
|---|---|---|
| 0 | `/instantiate-model` | 条件付き公理系の生成 |
| 0 | `/research` | 実装前リサーチ（Gap Analysis → Gate 判定） |
| 1 | `/formal-derivation` | Γ ⊢ φ の導出構成 |
| 2 | `trace-map.json` + `# @traces` | テスト→命題マッピング |
| 2 | `scripts/trace-coverage.sh` | カバレッジ確認 |
| 3 | `/trace` | 半順序カバレッジ + 逸脱検出 |
| 3 | `/verify` | P2 独立検証 |
| 4 | `manifest-trace impact` | D13 ファイルレベル影響分析 |
| 4 | `/metrics` | V1–V7 計測 |
| 5 | `/evolve` | 構造の漸進的改善 |
| 5 | `/ground-axiom` | 公理の数学的根拠検証 |

---

## ワークフロー

### Phase 0: 設計 — 条件付き公理系の生成

**目的**: プロジェクトの要件と制約を、基底理論 T₀ の保存拡大として形式化する。

**手順**:

1. **ビジョンの聞き取り** — `/instantiate-model` を起動し、人間のビジョンを段階的に引き出す

   質問テンプレート DB（`references/question-templates.json`）を参照して、
   ドメインに応じた質問を体系的に投げかける。全ての質問は公理系の層
   （T: 制約 / C: 契約 / H: 仮定 / D: 導出）に対応している。

   **全ドメイン共通の質問カテゴリ**:

   | カテゴリ | 問いの例 | 公理系での位置 |
   |---|---|---|
   | 物理的制約 | 時間制約は? データの精度限界は? | T (constraint) — 否定不可能 |
   | 法的制約 | GDPR, HIPAA 等の規制は? 監査要件は? | T (constraint) — 法的義務 |
   | 契約的制約 | SLA は? 予算・期間の制約は? | C — 統括責任者の決定 |
   | 仮定 | まだ検証されていない前提は? 外部システムの信頼性は? | H (hypothesis) — 明示管理 |
   | 機能要件 | 主要な入出力は? 正常系シナリオ3つは? | D (derivation) — 制約から導出 |
   | 安全境界 | 絶対にやってはいけないことは? 最悪シナリオは? | L1 (safety) — 固定境界 |

   ドメイン固有の質問テンプレートも DB に蓄積されている（IoT 監視, Web アプリ,
   データパイプライン, CLI ツール 等）。新しいドメインに遭遇した場合は、
   聞き取り後に質問テンプレートを DB に追記して蓄積する。

2. **Gap Analysis** — `/research` で技術的ギャップを構造化
   - 未知の技術要素を Sub-Issue + Gate で管理
   - FAIL は早期に検出（fail-fast）

3. **条件付き公理系の生成** — `/instantiate-model` が Lean 文書を出力
   ```
   T₀ (base theory: T1-T8, E1-E2)
   ∪ Γ\T₀ (project conditions: requirements + constraints)
   ⊢ D_project (derived obligations)
   ```

4. **保存拡大性の確認** — `lake build` で型検査
   - 新規 `axiom` 宣言を確認: T₀ の保存拡大であることを検証
   - `CompatibilityClass` を明記

5. **質問テンプレートの更新** — 新しいドメインの場合、聞き取りで得た
   質問パターンを `references/question-templates.json` の `domains` に追加する

**成果物**:
- `lean-formalization/Manifest/Project/<ProjectName>.lean` — 条件付き公理系
- Parent Issue + Sub-Issues（`/research` の出力）
- `references/question-templates.json` の更新（新ドメインの場合）

**チェックポイント**:
- [ ] `lake build` が 0 sorry で通る
- [ ] 全 axiom に Axiom Card（Layer / Basis / Refutation condition）がある
- [ ] 保存拡大性: 新規 axiom が T₀ と矛盾しないことを確認

---

### Phase 1: テスト計画 — 命題からのテスト導出

**目的**: 条件付き公理系の各命題に対して、検証可能なテストケースを系統的に導出する。

**手順**:

1. **命題一覧の抽出** — 条件付き公理系から全 PropositionId を列挙

2. **テストケースの導出** — 各命題に対して:
   - **axiom**: 「この axiom が否定されたら失敗するテスト」を設計
   - **theorem**: Lean コンパイル自体がテスト（0 sorry で検証済み）
   - **def/structure**: 主要な性質の property-based test を設計

3. **命題IDの付与** — テストに `# @traces` アノテーションを追加
   ```bash
   # @traces L1,T6
   check "S1.5 deny list has 10+ entries" ...
   ```
   または `trace-map.json` に外部マッピングを記載:
   ```json
   { "S1.5": { "primary": "L1", "secondary": ["T6"] } }
   ```

4. **カバレッジ確認** — `scripts/trace-coverage.sh` を実行
   ```bash
   bash scripts/trace-coverage.sh
   # Coverage: N / M (X.X%)
   ```

**成果物**:
- テストスクリプト群（`tests/` 配下）
- `tests/trace-map.json` — テスト→命題マッピング
- `# @traces` アノテーション（テストファイル内）

**チェックポイント**:
- [ ] 全命題に少なくとも1つのテストが対応（`trace-coverage.sh` で 100%）
- [ ] 高強度命題（T/E、strength ≥ 4）は複数テストでカバー
- [ ] テスト命名が Phase.Axis.Seq 規則に従う

---

### Phase 2: 実装 — テスト駆動で成果物を構築

**目的**: テストを先に書き、テストが通るように実装する（TDD）。

**手順**:

1. **Red** — テストを書く（まだ FAIL する）
   - `# @traces` でどの命題を検証するか明記
   - structural test（存在確認）→ behavioral test（動作確認）の順

2. **Green** — テストが通る最小の実装を書く
   - 成果物（hook, skill, rule 等）を作成
   - `artifact-manifest.json` に refs を追加:
     ```json
     { "id": "hook:my-hook", "refs": ["L1", "D1"], "path": ".claude/hooks/my-hook.sh" }
     ```

3. **Refactor** — `/simplify` でコード品質を確認

4. **形式化** — 必要に応じて `/formal-derivation` で Lean 定理を追加
   - 実装の正しさを型レベルで保証

5. **Traceability.lean の更新** — TraceMatrix に新しいリンクを追加
   - PropTestLink: 命題→テスト
   - TestArtifactLink: テスト→実装
   - ArtifactPropLink: 実装→命題

**成果物**:
- 実装ファイル群
- `artifact-manifest.json` の更新
- Traceability.lean の更新（該当する場合）

**チェックポイント**:
- [ ] 全テストが PASS
- [ ] `artifact-manifest.json` の refs が正確
- [ ] `manifest-trace coverage` でカバレッジギャップなし

---

### Phase 3: 検証 — 閉環の確認と独立レビュー

**目的**: 閉環トレーサビリティの完全性と実装の正しさを独立に検証する。

**手順**:

1. **閉環トレーサビリティの検証**
   ```bash
   # カバレッジ（命題→テストの網羅性）
   bash scripts/trace-coverage.sh

   # 半順序違反（依存方向の整合性）
   manifest-trace violations

   # 全体健全性
   manifest-trace health
   ```

2. **独立検証** — `/verify` でサブエージェントによるレビュー
   - 自分が書いたコードを自分でレビューしない（E1, P2）
   - リスクレベルに応じた検証手段:
     - Low: サブエージェント
     - Medium: 別モデル
     - High: 人間レビュー

3. **Lean ビルド**
   ```bash
   export PATH="$HOME/.elan/bin:$PATH" && lake build Manifest
   # 0 sorry を確認
   ```

4. **受入テスト**
   ```bash
   bash tests/test-all.sh
   ```

5. **互換性分類** — コミットメッセージに明記
   - `conservative extension`: 既存が全て有効。追加のみ
   - `compatible change`: ワークフロー継続可能。一部前提が変化
   - `breaking change`: 一部ワークフローが無効。移行パスを明記

**チェックポイント**:
- [ ] `trace-coverage.sh` = 100%
- [ ] `manifest-trace violations` = 0 件
- [ ] `lake build Manifest` = 0 sorry, 0 warnings
- [ ] `tests/test-all.sh` = 全 PASS（既存失敗を除く）
- [ ] `/verify` PASS
- [ ] 互換性分類がコミットメッセージに含まれる

---

### Phase 4: 保守 — 変更影響の追跡と継続的改善

**目的**: 変更が公理系の整合性を壊さないことを継続的に保証する。

**手順**:

1. **変更影響分析** — 変更対象の命題を特定し、影響範囲を計算
   ```bash
   # 命題 P3 が変更された場合の影響
   manifest-trace impact P3

   # JSON 出力（CI 統合用）
   manifest-trace impact P3 --json
   ```
   出力:
   - 影響命題（推移的閉包）
   - 影響を受ける実装ファイル
   - 再実行すべきテスト

2. **影響ファイルのトリアージ** — impact の出力を3カテゴリに分類する

   | カテゴリ | 基準 | アクション |
   |---|---|---|
   | **要修正** | 変更対象の命題を直接実装しているファイル（hook, rule, Lean 定義） | 内容を変更する |
   | **整合性確認** | 変更命題を refs で参照しているが、直接実装ではないファイル（skill, agent, doc） | 記述の整合性を確認し、必要なら更新 |
   | **影響なし** | 推移的閉包に含まれるが、実質的な影響がないファイル | 確認のみ（変更不要） |

   この分類により、30+ ファイルの impact 出力から実際に手を動かすべき箇所を絞り込む。

3. **影響テストの再実行** — impact が示すテストを実行
   ```bash
   # 最小: impact が示す直接テストのみ
   bash tests/phase1/test-l1-structural.sh
   bash tests/phase1/test-l1-behavioral.sh

   # 安全策: 全テスト
   bash tests/test-all.sh
   ```

3. **メトリクス確認** — `/metrics` で V1–V7 の現在値を確認
   - 変更前後の差分を記録
   - 改善を主張する前に計測で裏付ける（P4）

4. **公理の健全性維持** — `/ground-axiom` で数学的根拠を検証
   - 新しい axiom は Axiom Card が必須
   - 降格可能な axiom は theorem に降格

5. **漸進的改善** — `/evolve` で構造の改善サイクルを実行
   - 観察 → 仮説化 → 検証 → 統合 → 退役

**トリガー条件**:

| イベント | アクション |
|---|---|
| axiom の追加・変更 | `manifest-trace impact` → 影響テスト再実行 |
| テストの追加 | `trace-coverage.sh` → カバレッジ更新 |
| 成果物の追加 | `artifact-manifest.json` 更新 → `manifest-trace coverage` |
| 外部環境の変更 | `/research` で影響評価 → Phase 0 に戻る可能性 |
| 定期保守 | `/metrics` + `/evolve` + `/ground-axiom` |

---

## クイックリファレンス

### 最小実行パス（新規プロジェクト）

```
/instantiate-model        ← Phase 0: 条件付き公理系を生成
  ↓
テスト作成 + # @traces    ← Phase 1: テスト計画
  ↓
実装 + artifact-manifest  ← Phase 2: TDD
  ↓
trace-coverage.sh         ← Phase 3: カバレッジ 100% 確認
manifest-trace violations ← Phase 3: 半順序違反 0
/verify                   ← Phase 3: 独立検証
  ↓
git commit (with compat)  ← 互換性分類付きコミット
```

### 変更時の最小実行パス（保守）

```
manifest-trace impact <ID>  ← Phase 4: 影響範囲を特定
  ↓
影響テスト再実行            ← Phase 4: 回帰確認
  ↓
trace-coverage.sh           ← Phase 3: カバレッジ維持確認
/verify                     ← Phase 3: 独立検証
  ↓
git commit (with compat)    ← 互換性分類付きコミット
```

### コマンド早見表

| 目的 | コマンド |
|---|---|
| 条件付き公理系の生成 | `/instantiate-model` |
| テストカバレッジ確認 | `bash scripts/trace-coverage.sh` |
| 半順序カバレッジ | `manifest-trace coverage` |
| 半順序違反検出 | `manifest-trace violations` |
| D13 影響分析 | `manifest-trace impact <ID>` |
| 全体健全性 | `manifest-trace health` |
| Lean ビルド | `lake build Manifest` |
| 全テスト実行 | `bash tests/test-all.sh` |
| 独立検証 | `/verify` |
| V1–V7 計測 | `/metrics` |
| 構造改善 | `/evolve` |
| 公理根拠検証 | `/ground-axiom` |

---

## アンチパターン

| やってはいけないこと | 理由 | 代わりに |
|---|---|---|
| テストなしで実装を先に書く | 閉環が保証されない | テスト → 実装の順（TDD） |
| `# @traces` なしでテストを書く | カバレッジが追跡不能 | 全テストに命題ID付与 |
| `artifact-manifest.json` を更新せずに成果物追加 | 逸脱が検出されない | 成果物追加時に refs を明記 |
| `manifest-trace impact` なしで公理を変更 | 影響範囲が不明 | 変更前に影響分析 |
| 自分で書いたコードを自分でレビュー | E1 違反（検証の独立性） | `/verify` で独立検証 |
| 互換性分類なしでコミット | P3 違反（学習の統治） | conservative/compatible/breaking を明記 |
| カバレッジ 100% 未達で次 Phase へ | 閉環が成立しない | Phase 1 で 100% を達成してから進む |
| 改善を主張して計測しない | P4 違反（可観測性） | `/metrics` で before/after を記録 |

## D4 フェーズ順序との関係

本ワークフローは D4（フェーズ順序）に準拠する:

```
安全（L1）→ 検証（P2）→ 可観測性（P4）→ 統治（P3）→ 動的調整
```

各 Phase がこの順序を壊さないことを保証する:

| Workflow Phase | D4 Phase | 保証内容 |
|---|---|---|
| Phase 0 (設計) | — | L1 に違反する公理は追加不可（lake build で型検査） |
| Phase 1 (テスト計画) | L1 | テスト自体が安全境界を検証 |
| Phase 2 (実装) | P2 | TDD で実装が仕様を満たすことを先に保証 |
| Phase 3 (検証) | P4 | カバレッジ・違反・健全性の可観測性を確立 |
| Phase 4 (保守) | P3 | 互換性分類 + 影響分析で統治された漸進的改善 |
