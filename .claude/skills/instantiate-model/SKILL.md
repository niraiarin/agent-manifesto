---
name: instantiate-model
user-invocable: true
description: >
  認識論的層モデルのインスタンシエーション・ワークフロー。人間のプロジェクトの
  ビジョンを聞き取り、要件・仮定・制約を引き出し、EpistemicLayerClass の
  公理体系に準拠した条件付き公理体系を Lean 文書として生成する。
  「モデル生成」「instantiate」「層モデル」「条件付き公理」「公理体系を生成」で起動。
dependencies:
  invokes:
    - skill: design-implementation-plan
      type: hard
      phase: "Step 9d"
      condition: "FeedbackReport 受信時"
    - skill: verify
      type: soft
      phase: "Step 8"
      condition: "生成された公理体系の検証時"
  invoked_by:
    - skill: spec-driven-workflow
      phase: "Phase 0 Step 1"
      expected_output: "条件付き公理体系"
    - skill: design-implementation-plan
      phase: "Step 3"
      expected_output: "条件付き公理体系"
    - skill: generate-plugin
      phase: "Phase 1-2"
      expected_output: "条件付き公理体系"
  agents:
    - agent: model-questioner
      role: "Phase 0-1 dialogue for requirements extraction"
---
<!-- @traces D5, D1 -->

# /instantiate-model

> **Portability: repo-only** — このスキルは agent-manifesto リポジトリ内でのみ動作する。
> .claude/agents/model-questioner.md、lean-formalization/Manifest/Models/ への深い依存があり、plugin 単体での利用は不可。

認識論的層モデルのインスタンシエーション・ワークフロー。

人間のプロジェクトのビジョンを聞き取り、要件・仮定・制約を引き出し、
EpistemicLayerClass の公理体系に準拠した条件付き公理体系を Lean 文書として生成する。

## タスク自動化分類（TaskClassification.lean 準拠, #377/#384）

各ステップの `TaskAutomationClass` をデザインタイムに定義する。
実行時に LLM が毎回判断するコストを排除する（`designtime_classification_amortizes`）。

| ステップ | 分類 | 推奨実装手段 | 備考 |
|---|---|---|---|
| Step 1: 対話（Phase 0-1） | **judgmental** | model-questioner agent | 人間との対話による要件引き出し。自動化不可 |
| Step 2: 構造推論（Phase 2） | **deterministic + judgmental（分離済み）** | extract-dependency-graph.sh（抽出） + model-questioner agent（推論） | `mixed_task_decomposition` 適用済み ✓ |
| Step 3: 矛盾解消（Phase 3） | **judgmental** | model-questioner agent + 人間対話 | 矛盾の解消方法は人間の判断に依存（T6） |
| Step 4: ModelSpec JSON 生成 | **deterministic + judgmental（未分離）** | LLM が直接実行 | deterministic: JSON スキーマ構造 / judgmental: Phase 2 出力の構造化 |
| Step 5: 事前検証 | **deterministic** | check-monotonicity.sh | スクリプト化済み ✓ |
| Step 6: Lean コード生成 + 検証 | **deterministic** | generate-conditional-axiom-system.sh + lake build | スクリプト化済み ✓ |
| Step 7: Assumptions の更新 | **deterministic + judgmental（未分離）** | LLM が直接実行 | deterministic: Lean テンプレート構造 / judgmental: validity 内容の記述 |
| Step 7b: /verify P2 独立検証 | **deterministic** | /verify スキル | FAIL→修正→再検証ループ。Agent tool 直接呼出し不可 |
| Step 8: 完了 | **deterministic** | git commit 提案 | 承認は T6（人間判断）だがステップ自体は機械的 |
| Step 9a: FeedbackReport 受信 | **deterministic** | データ解析 | /design-implementation-plan からの構造化入力 |
| Step 9b: 仮定の追加 | **deterministic + judgmental（未分離）** | LLM が直接実行 | deterministic: Assumptions.lean テンプレート / judgmental: EpistemicSource 分類 |
| Step 9c: 条件付き公理系の再構築 | **deterministic** | スクリプト群 + lake build | Step 5-6 の再実行 |
| Step 9d: /design-implementation-plan に戻る | **deterministic** | スキル呼び出し | 遷移条件は明確（miss=0 or iteration>=3） |

**設計原則**:
- Step 5, 6 は deterministic でスクリプト化済み — 構造的強制の好例
- Step 1, 3 は judgmental — 人間との対話は normative 層の本来の用途
- Step 4, 7, 9b の deterministic 成分（テンプレート構造）は分離候補（`mixed_task_decomposition`）
- Step 9 全体は D17 feedback ループの実装であり、収束条件は deterministic（miss=0 or iteration>=3）

## D17 演繹的設計ワークフローとの対応

本スキルは D17 の Step 1 (extract) と Step 2 (construct) を担当する。

- **Step 1 extract**: Phase 0-1 の対話で仮定 (C/H) を抽出
  - D17 の verify gate: `extractStepValid` = 全仮定に TemporalValidity + 仮定数 > 0
- **Step 2 construct**: Phase 2-3 で条件付き公理系を構築
  - D17 の verify gate: `constructStepValid` = sorryCount = 0 ∧ buildSuccess = true

高リスク遷移（stepTransitionRisk = high）のため、extract/construct の出力は
可能な限り独立検証すべき（D2: 3/4 条件）。

## 起動トリガー

「モデル生成」「instantiate」「層モデル」「条件付き公理」「公理体系を生成」で起動。

## ワークフロー概要

```
Phase 0: ビジョンの聞き取り
  ↓
Phase 1: 要件・仮定・制約の引き出し
  ↓
Phase 2: LLM 内部で構造推論 + 公理系照合
  ↓ 矛盾あり → Phase 3 → Phase 1 or 2 に戻る
  ↓ 矛盾なし
ModelSpec JSON 生成
  ↓
check-monotonicity.sh（事前検証）
  ↓ 違反あり → 修正（H なら自律、C なら Phase 3）→ 再検証
  ↓ 違反なし
generate-conditional-axiom-system.sh（Lean 生成）
  ↓
lake build（最終検証）
  ↓ 失敗 → フィードバック → 修正 → 再生成
  ↓ 成功
/verify（P2 独立検証、トークン書き込み）
  ↓ FAIL → 修正 → /verify 再実行（エラーゼロまでループ）
  ↓ PASS
✓ 完了（git commit 提案）
```

## 使用するコンポーネント

### エージェント

- `.claude/agents/model-questioner.md` — Phase 0-3 の対話と推論

### スクリプト（コードによるルール）

- `lean-formalization/Manifest/Models/extract-dependency-graph.sh` — 依存グラフ抽出
- `lean-formalization/Manifest/Models/check-monotonicity.sh` — 単調性事前検証
- `lean-formalization/Manifest/Models/generate-conditional-axiom-system.sh` — Lean コード生成

### Lean ファイル（入力/出力）

- `lean-formalization/Manifest/EpistemicLayer.lean` — 公理体系 (A)。**Read-only**
- `lean-formalization/Manifest/Models/Assumptions/EpistemicLayer.lean` — 仮定の蓄積 (C∪H)
- `lean-formalization/Manifest/Models/ConditionalAxiomSystem.lean` — 条件付き公理体系 (D)

## 実行手順

### Step 1: 対話（Phase 0-1）

model-questioner エージェントを起動し、人間との対話を行う。

```
Phase 0: 「どんなものを作ろうとしていますか？」
Phase 1: 回答から要件・仮定・制約を引き出す
  Phase 1a: 各仮定の時間的有効性を確認する（#225）
```

#### Phase 1a: 時間的有効性の確認

各 C/H について以下を確認する（TemporalValidity、#225）:

- **ソース参照**: 「この仮定の根拠となるドキュメント・URL・リポジトリは？」
- **鮮度**: 「このソースを最後に確認したのはいつですか？」
- **見直し間隔**: 「このソースはどのくらいの頻度で変わりますか？」
  - 頻繁に変化 → reviewInterval を設定（例: 90 日）
  - 安定している → reviewInterval = None（明示的トリガーのみ）
  - 不明 → デフォルト 180 日を提案

これにより、生成される Assumption に `validity` フィールドが付与される。

### Step 2: 構造推論（Phase 2）

model-questioner エージェントの Phase 2 を実行する。
内部で依存グラフ抽出と公理系照合を行う。

```bash
# 依存グラフの抽出（Phase 2 の入力）
bash lean-formalization/Manifest/Models/extract-dependency-graph.sh
```

### Step 3: 矛盾解消（Phase 3、必要な場合のみ）

Phase 2 で矛盾が検出された場合、人間に平易な言葉で確認する。

### Step 4: ModelSpec JSON の生成

Phase 2 の出力を JSON ファイルに書き出す。

各 Assumption の `validity` を JSON に含める:

```json
{
  "assumptions": [
    {
      "id": "C1",
      "source": { "humanDecision": { "phase": 1, "question": "Q1", "date": "2026-04-08" } },
      "content": "...",
      "validity": {
        "sourceRef": "https://docs.example.com/api/v2",
        "lastVerified": "2026-04-08",
        "reviewInterval": 90
      }
    }
  ]
}
```

`validity` フィールドは Optional。既存の JSON（`validity` なし）はそのまま互換。
`generate-conditional-axiom-system.sh` と `check-monotonicity.sh` は `validity` を
パースしない（層分類と単調性のみ検証）ため、スクリプト変更は不要。

### Step 5: 事前検証

```bash
bash lean-formalization/Manifest/Models/check-monotonicity.sh -f model-spec.json
```

- 違反あり + justification が H のみ → LLM が自律修正して再検証
- 違反あり + justification に C 含む → Phase 3 に戻る
- 違反なし → Step 6 へ

### Step 6: Lean コード生成 + 検証

```bash
bash lean-formalization/Manifest/Models/generate-conditional-axiom-system.sh \
  -f model-spec.json \
  -o lean-formalization/Manifest/Models/ConditionalAxiomSystem.lean
```

自動で `lake build` が実行される。失敗したら Step 5 に戻る。

### Step 7: Assumptions の更新

Phase 1-3 で得た C と H を `Assumptions/EpistemicLayer.lean` に書き出す。

各 Assumption には Phase 1a で収集した `validity` を付与する:

```lean
def c1 : Assumption := {
  id := "C1"
  source := .humanDecision 1 "Q1" "2026-04-08"
  content := "..."
  validity := some {
    sourceRef := "https://docs.example.com/api/v2"
    lastVerified := "2026-04-08"
    reviewInterval := some 90  -- 90日ごとに見直し
  }
}
```

`validity` が `none` の仮定は「恒久的」と見なされるが、
条件付き公理系の仮定は外部ソースに由来するため `some` を推奨する。

### Step 7b: /verify による P2 独立検証（必須）

lake build 成功後、**必ず `/verify` を実行する**（Agent tool の verifier 直接呼出しではなく、
`/verify` スキルを使用すること。`/verify` が P2 検証トークンを書き込み、
`p2-verify-on-commit.sh` がコミット時にトークンを検証する）。

- PASS → Step 8 へ
- FAIL → 修正 → `/verify` 再実行（**エラーゼロまでループ。修正後の再検証を省略しない**）

**重要**: Verifier が FAIL を返した場合、修正後に**再度 `/verify` を実行する**。
修正後のコードが別の問題を含む可能性があるため、修正のみで PASS と見なさない。
これは D2（検証独立性）の要件であり、省略は P2 違反となる。

### Step 8: 完了

git commit を提案する（人間の承認を待つ）。
P2 検証トークンが有効でない場合、`p2-verify-on-commit.sh` がブロックする。

### Step 9: フィードバック受容（D17 Step 5 → Step 1 ループ）

**D17 state machine の feedback → extract 遷移を実装。**

/design-implementation-plan の Step 9b が FeedbackReport を生成した場合、
本スキルがフィードバックを受け取り、仮定を追加して条件付き公理系を再構築する。

#### 9a: FeedbackReport の受信

/design-implementation-plan から以下を受け取る:
- `addAssumption` アクションのリスト（不足��定）
- scoped recall の現在値

#### 9b: 仮定の追加

各 `addAssumption` について:
1. 仮定の内容を Assumptions.lean に追加
2. `EpistemicSource` を設定（C: 人間判断なら humanDecision、H: LLM推論なら llmInference）
3. `TemporalValidity` を付与（sourceRef, lastVerified, reviewInterval）
4. instance-manifest.json の assumptions セクションを更新

#### 9c: 条件付き公理系の再構築

1. 追加された仮定に基づいて ConditionalDesignFoundation.lean を更新
2. 新仮定に対応する CC axiom を追加（必要な場合）
3. `lake build` で再検証
4. `validate-instance-manifest.sh` で検証

#### 9d: /design-implementation-plan に戻る

再構築された条件付き公理系で /design-implementation-plan の Step 3 (derive) を再実行。

#### 収束条件

- miss のうち「仮定不足」が **0 件** → 停止（仮定追加で解消可能なものは全て解消済み）
- iteration >= 3 → 強制停止（D15a: 有限リソース下の retry bound）
- 停止時の残存 miss は「スコープ外」と「構造的限界」のみ
- 「構造的限界」は公理系の存在論拡張が必要であり、人間に判断を委ねる（T6）

## S=(A,C,H,D) の追跡

| 概念 | ファイル | 管理 |
|------|---------|------|
| A (公理体系) | EpistemicLayer.lean | Read-only |
| C (人間判断) | Assumptions/EpistemicLayer.lean `[C]` | Phase 1 で蓄積 |
| H (LLM推論) | Assumptions/EpistemicLayer.lean `[H]` | Phase 2 で蓄積 |
| D (導出) | ConditionalAxiomSystem.lean | 生成スクリプトで出力 |

C と H は Lean の `EpistemicSource` 型で型レベルで区別される。
各仮定の時間的有効性は `TemporalValidity` 型で追跡される（#225）。

## 仮定の時間的有効性（#225）

条件付き公理系の仮定 (C/H) は外部ソースに由来し、時間とともに変化しうる。
Phase 1a で各仮定の `TemporalValidity` を収集し、Assumption に付与する。

| フィールド | 型 | 説明 |
|-----------|-----|------|
| sourceRef | String | 再 fetch 可能な外部ソース参照 |
| lastVerified | String | 最終検証日 (YYYY-MM-DD) |
| reviewInterval | Option Nat | 見直し間隔（日数）。None = 明示的トリガーのみ |

仮定が失効した場合、D13 の影響波及が発動する:
依存する導出は再検証対象となる（DesignFoundation.lean の `assumptionImpact`）。

## Traceability

| 命題 | このスキルとの関係 |
|------|-------------------|
| D5 | Phase 0-3 で条件付き公理系（仕様）を先に構築し、実装はその導出として後続する順序を強制 |
| D1 | check-monotonicity.sh と lake build による事前検証・最終検証で、公理系の整合性を LLM 判断に依存せず構造的に保証 |
