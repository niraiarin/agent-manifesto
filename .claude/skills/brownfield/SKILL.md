---
name: brownfield
user-invocable: true
description: >
  既存プロジェクトに対して条件付き公理系を構築し、公理系支配ワークフローを適用する。
  コード解析・Web Search・人間ヒアリング・manifesto 照合の 4 種観察手段による
  反復的公理系構築。/instantiate-model の brownfield 対応版。
  「brownfield」「既存プロジェクト」「公理系適用」「axiom governance」で起動。
dependencies:
  invokes:
    - skill: instantiate-model
      type: soft
      phase: "Phase 2 Step 7-8"
      condition: "JSON→Lean 生成・検証パイプライン共有"
    - skill: verify
      type: hard
      phase: "Phase 2 Step 9"
    - skill: trace
      type: soft
      phase: "Phase 4"
      condition: "半順序確立時"
    - skill: research
      type: soft
      phase: "Phase 0 Step 2"
      condition: "未知の技術スタックの調査が必要な場合"
  invoked_by:
    - skill: spec-driven-workflow
      phase: "Phase 0"
      expected_output: "条件付き公理体系（外部プロジェクト）"
  agents: []
---
<!-- @traces D5, D1, D8 -->

# /brownfield

> **Portability: repo-only** — このスキルは agent-manifesto リポジトリ内で実行し、
> 対象プロジェクトを外部参照する。成果物は manifesto リポジトリ内に配置。

既存プロジェクトに対して条件付き公理系を構築し、公理系支配ワークフローを適用する。

## /instantiate-model との関係

出力形式は同一（EpistemicLayerClass instance + instance-manifest.json）。
差分は入力側にある:

| | /instantiate-model (greenfield) | /brownfield |
|---|---|---|
| 入力 | 人間のビジョン（対話で抽出） | 既存コードベース |
| 観察手段 | 人間ヒアリングのみ | コード解析 + Web Search + 人間ヒアリング + manifesto 照合 |
| Phase 数 | Phase 0-3 + Step 4-8 | Phase 0-5 |
| Phase 3 以降 | なし（新規実装） | リファクタリング → 半順序確立 → 還元 |
| 適用先 | manifesto リポジトリ内 | 外部プロジェクト |

**共有コンポーネント**（/instantiate-model の Step 5-6 に相当）:
- `check-monotonicity.sh` — 単調性事前検証
- `generate-conditional-axiom-system.sh` — JSON → Lean コード生成
- `lake build` — 最終検証

## タスク自動化分類（TaskClassification.lean 準拠）

| ステップ | 分類 | 推奨実装手段 |
|---|---|---|
| Phase 0 Step 1: リポジトリ構造取得 | **deterministic** | gh API + スクリプト |
| Phase 0 Step 2: 構造分類 | **deterministic + judgmental** | スクリプト（ファイル分布集計）+ LLM（分類判定）|
| Phase 0 Step 3: スコーピング文書作成 | **judgmental** | LLM + 人間確認（T6）|
| Phase 1 Step 1: 分解単位の決定 | **judgmental** | LLM（戦略選択）|
| Phase 1 Step 2: 観察反復 | **judgmental** | LLM（4 種観察エンジン）|
| Phase 1 Step 3: 収束判定 | **deterministic** | convergence スクリプト |
| Phase 2 Step 4: ModelSpec JSON 生成 | **deterministic + judgmental** | LLM |
| Phase 2 Step 5-6: 事前検証 + Lean 生成 | **deterministic** | 共有スクリプト群 |
| Phase 2 Step 7-8: Assumptions 更新 + 検証 | **deterministic + judgmental** | LLM + /verify |
| Phase 2 Step 9: /verify P2 独立検証 | **deterministic** | /verify スキル |
| Phase 3: リファクタリング | **judgmental** | LLM + 人間確認（T6）|
| Phase 4: 半順序確立 | **deterministic + judgmental** | /trace + LLM |
| Phase 5: 還元 | **judgmental** | LLM + 人間確認（T6）|

## 外部プロジェクトアクセスパターン

| Phase | アクセス方法 | 理由 |
|-------|-------------|------|
| Phase 0 | gh API のみ（clone 不要） | 構造把握に十分。帯域節約 |
| Phase 1-2 | ローカル clone | ファイル内容の詳細解析が必要 |
| Phase 3 | clone 上で作業（fork + branch） | 変更を加える |
| Phase 4-5 | manifesto リポジトリ内 | 成果物は manifesto 側 |

**成果物配置先**: `lean-formalization/Manifest/Models/instances/<project-name>/`
- `instance-manifest.json` — 双方向トレーサビリティ
- `Assumptions.lean` — プロジェクト固有の仮定
- `ConditionalAxiomSystem.lean` — 条件付き公理系

**Read-only モード**: 対象リポジトリへの変更権限がない場合、Phase 3 をスキップし
Phase 0-2（公理系構築）+ Phase 4-5（半順序確立・還元）のみ実行する。

## ワークフロー

```
Phase 0: スコーピング
  │ gh API で構造把握 → 人間と合意
  ↓
Phase 1: 観察（反復）
  │ 分解 → 4 種観察エンジン → Platform Decision 収集
  │ ← 収束判定（発見率 < 5%）まで反復
  ↓
Phase 2: 条件付き公理系の構築
  │ ModelSpec JSON → check-monotonicity → generate → lake build → /verify
  ↓
Phase 3: リファクタリング（権限がある場合のみ）
  │ 公理系に基づくコード変更提案
  ↓
Phase 4: 半順序確立
  │ /trace で manifesto 公理系との関係を確立
  ↓
Phase 5: 還元
  │ ドメイン非依存の知見を manifesto に還元
  ↓
✓ 完了
```

## Phase 0: スコーピング

対象プロジェクトの境界と手段を人間と合意する。clone 不要。

### Step 1: リポジトリ構造の取得（deterministic）

```bash
# ファイルツリーの取得
gh api 'repos/{owner}/{repo}/git/trees/{branch}?recursive=1' \
  --jq '[.tree[] | select(.type=="blob") | .path]' > /tmp/file-tree.json

# ファイル分布の集計
cat /tmp/file-tree.json | jq -r '.[]' | \
  sed 's|/.*||' | sort | uniq -c | sort -rn
```

### Step 2: 構造分類（deterministic + judgmental）

ファイル分布から以下を分類:

| カテゴリ | 説明 | 例 |
|----------|------|----|
| **構造的コア** | エージェントの行動を規定するファイル | skills/, hooks/, rules/, agents/, commands/ |
| **コンテンツ** | 構造に従って生成・管理されるファイル | docs/, examples/, assets/ |
| **インフラ** | ビルド・CI・設定ファイル | scripts/, .github/, package.json |
| **テスト** | 検証ファイル | tests/ |

**判定基準**: 「このファイルを変更すると、エージェントの行動が変わるか？」
- Yes → 構造的コア
- No → コンテンツ / インフラ / テスト

### Step 3: スコーピング文書の作成（judgmental）

人間と以下を合意する（T6）:

```markdown
## スコーピング文書

**対象**: {owner}/{repo}
**ファイル数**: N
**構造的コア**: {ディレクトリリスト} ({ファイル数})
**スコープ**: Phase {N} まで実施 / read-only モード
**除外**: {除外するディレクトリ・ファイルパターン}
**既知の制約**: {技術スタック固有の制約}
```

## Phase 1: 観察（反復）

### Step 1: 分解単位の決定（judgmental）

対象の構造的コアを分解単位に分割する。

**推奨戦略: Hybrid（top-down → bottom-up）**

1. **top-down**: 構造的コアのディレクトリを第 1 レベルの分解単位とする
2. **bottom-up**: 各分解単位内で機能的な凝集度を評価し、必要に応じてサブ分割
3. **閾値**: 1 分解単位あたり最大 50 ファイル。超過した場合はサブ分割

```markdown
## 分解計画

| # | 分解単位 | ファイル数 | 優先度 | 理由 |
|---|---------|-----------|--------|------|
| 1 | skills/ | N | P1 | 構造的コアの最大構成要素 |
| 2 | rules/ | N | P1 | エージェント行動の規定 |
| ... | ... | ... | ... | ... |
```

**優先順位**: 構造的コア > インフラ > テスト > コンテンツ

### Step 2: 観察反復（judgmental）

各分解単位に対して 4 種の観察手段を適用:

#### 2a. コード解析

対象ファイルを読み、以下を抽出:
- 暗黙の設計判断（命名規約、ディレクトリ構造の意味）
- 依存関係（ファイル間の参照、import パターン）
- 不変条件（常に守られているルール）

#### 2b. Web Search

技術スタック固有の情報を収集:
- フレームワーク・ライブラリのドキュメント
- ベストプラクティス・制約
- 既知の問題・ワークアラウンド

#### 2c. 人間ヒアリング

設計意図やドメイン知識を質問:
- 「なぜこの構造にしたのか？」
- 「変更してはいけない制約は？」
- 「最も重要な品質属性は？」

#### 2d. manifesto 照合

観察結果を manifesto 公理系と照合:
- T1-T8, E1-E2, P1-P6, L1-L6 の各命題に対応する実装があるか
- 対応がない場合、それは「逸脱」か「ドメイン固有の理由による除外」か
- DomainClassification.lean の分類基準を適用

#### 観察結果の記録

各反復の PD を JSON 配列として記録し、`convergence.sh add-detailed` で登録する（#457）:

```bash
# PD 詳細を JSON 配列で記録
cat > /tmp/pds-iteration-1.json <<'EOF'
[
  {
    "id": "PD-001",
    "content": "Skills are Markdown files with clear sections",
    "source": "code_analysis",
    "manifesto_mapping": "D5",
    "confidence": "high"
  }
]
EOF

# convergence.sh に登録（PD 詳細が iteration ファイルに埋め込まれる）
bash .claude/skills/brownfield/convergence.sh add-detailed <observations-dir> 1 "skills/" /tmp/pds-iteration-1.json
```

**PD 詳細の必須フィールド**:
- `id`: `PD-NNN` 形式（グローバル一意）
- `content`: PD の内容
- `source`: `code_analysis` / `web_search` / `human_interview` / `manifesto_mapping`
- `confidence`: `high` / `medium` / `low`

**禁止**: `convergence.sh add`（count のみ）を使って PD 詳細を省略すること。
`add` は後方互換性のために残存するが、新規実行では `add-detailed` を使用する。

生成される `iteration-{N}.json` の形式:

```json
{
  "iteration": 1,
  "unit": "skills/",
  "timestamp": "2026-04-12T10:00:00Z",
  "platform_decisions": [
    {
      "id": "PD-001",
      "content": "Skills are Markdown files with clear sections",
      "source": "code_analysis",
      "manifesto_mapping": "D5",
      "confidence": "high"
    }
  ],
  "decisions_found": 1,
  "cumulative_total": 1,
  "incremental_rate": 1.0000
}
```

### Step 3: 収束判定（deterministic）

各反復後に収束を判定:

```
増分率 = decisions_found / cumulative_total
収束条件: 増分率 < 0.05（5% 未満）
```

- 収束した → Phase 2 へ
- 未収束 → 次の分解単位で Step 2 を反復
- 10 反復超過 → 強制終了。未観察の分解単位を記録して Phase 2 へ

## Phase 2: 条件付き公理系の構築

Phase 1 の観察結果を条件付き公理系に変換する。
/instantiate-model の Step 4-8 に相当する手順を実行。

### Step 4: ModelSpec JSON の生成

Phase 1 の Platform Decision を ModelSpec JSON に変換。
/instantiate-model Step 4 と同一形式。

### Step 5-6: 事前検証 + Lean コード生成

/instantiate-model の共有コンポーネントを使用:

```bash
# 事前検証
bash lean-formalization/Manifest/Models/check-monotonicity.sh -f model-spec.json

# Lean 生成 + lake build
bash lean-formalization/Manifest/Models/generate-conditional-axiom-system.sh \
  -f model-spec.json \
  -o lean-formalization/Manifest/Models/instances/<project-name>/ConditionalAxiomSystem.lean
```

### Step 7-8: Assumptions 更新 + 完了

Phase 1 で収集した C/H を Assumptions に書き出す。
/instantiate-model Step 7-8 と同一手順。

### Step 9: /verify P2 独立検証（必須）

lake build 成功後、必ず `/verify` を実行する。
FAIL → 修正 → /verify 再実行（エラーゼロまでループ）。

## Phase 3: リファクタリング（権限がある場合のみ）

公理系に基づくコード変更を対象プロジェクトに提案する。

**外部 L1**: manifesto L1 からデフォルト継承:
- テスト削除禁止
- API 破壊禁止
- 破壊的操作は人間確認

プロジェクト固有の L1 は Phase 1 で追加。

## Phase 4: 半順序確立

### Step 1: マッピング前の定義確認（mandatory, #458）

partial-order-mapping.json を作成する**前に**、マッピング対象の定義を読むこと。

**手順**:
1. 各 proposition の `manifestoPropositions` に D-ID を含める場合、
   `DesignFoundation.lean` の該当セクション（`-- D{N}: {title}` で始まるブロック）を読む
2. justification が定義の内容と整合することを確認してから記述する

**禁止**: 定義を読まずに D-ID の番号と名前だけからマッピングすること。
（#444 で D7「信頼の非対称性」を「最小変更単位」と誤解してマッピングした事例あり）

### Step 2: マッピング品質検証（deterministic）

マッピング作成後、検証スクリプトで定義と justification を並べて表示し、人間が目視確認する:

```bash
bash .claude/skills/brownfield/check-mapping-accuracy.sh \
  lean-formalization/Manifest/Models/Instances/<project-name>/partial-order-mapping.json
```

出力の各エントリについて `[  ] Justification matches definition(s)?` を確認する。
不整合があれば修正してから次へ進む。

### Step 3: 半順序検証

/trace を使用して manifesto 公理系との半順序関係を確立:

```bash
# instance-manifest.json の検証
bash scripts/manifest-trace validate \
  --instance lean-formalization/Manifest/Models/Instances/<project-name>/instance-manifest.json
```

## Phase 5: 還元

ドメイン非依存の知見を manifesto に還元する。
Phase 4 の半順序検証で FAIL した場合、Phase 3 に戻る。

## Traceability

| 命題 | このスキルとの関係 |
|------|-------------------|
| D5 | Phase 0-2 で条件付き公理系（仕様）を先に構築し、Phase 3 のリファクタリングをその導出として実行 |
| D1 | check-monotonicity.sh, generate-conditional-axiom-system.sh, lake build による構造的検証 |
| D8 | Phase 1 の 4 種観察手段の組み合わせにより、単一手段のバイアスを均衡 |
