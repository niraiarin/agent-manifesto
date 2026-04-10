---
name: trace
user-invocable: true
description: >
  全成果物の半順序導出・カバレッジ検出・逸脱検出。P4（可観測性）+ D13（影響波及）の
  運用ツール。公理系から実装が漏れている状況、実装が公理系から逸脱している状況を
  自動的・機械的に検出する。
  「トレース」「trace」「カバレッジ」「coverage」「逸脱」「deviation」
  「半順序」「partial order」で起動。
dependencies:
  invokes:
    - skill: evolve
      type: soft
      phase: "Step 3"
      condition: "ギャップが検出され改善が必要な場合"
---
<!-- @traces P4, D3, D13, V6 -->

# Artifact Trace (P4 + D13: 半順序トレーサビリティ)

全成果物（hooks, skills, agents, rules, tests）と公理系（T/E/P/L/D）の
半順序関係を導出し、カバレッジギャップと逸脱を検出する。

## Manifesto Root Resolution

このスキルは agent-manifesto リポジトリのファイル（Lean 形式化、artifact-manifest.json）を参照する。
実行前に以下でリポジトリルートを解決すること:

```bash
MANIFESTO_ROOT=$(bash .claude/skills/shared/resolve-manifesto-root.sh 2>/dev/null || echo "")
```

解決できない場合はユーザーに案内する。以降の `lean-formalization/` および `artifact-manifest.json` への参照は `${MANIFESTO_ROOT}/` を前置して解決する。

## Lean 形式化との対応

| スキルの概念 | Lean ファイル | 定理/定義 |
|------------|-------------|----------|
| 命題間半順序 | Ontology.lean | `PropositionId.dependencies`, `dependency_respects_strength` |
| 認識論的強度 | Ontology.lean | `PropositionCategory.strength` |
| 構造種別優先度 | Ontology.lean | `StructureKind.priority`, `structureDependsOn` |
| 逆方向依存 | Ontology.lean | `PropositionId.dependents` |
| D13 影響波及 | DesignFoundation.lean | `d13_propagation`, `affected` |
| 推移的依存 | EpistemicLayer.lean | `TransitivelyDependsOn` |
| 層割当単調性 | EpistemicLayer.lean | `LayerAssignment.monotone`, `canonicalAssignment` |
| D3 可観測性 | DesignFoundation.lean | `ObservabilityConditions` |

## タスク自動化分類（TaskClassification.lean 準拠, #377/#381）

各ステップの `TaskAutomationClass` をデザインタイムに定義する。
実行時に LLM が毎回判断するコストを排除する（`designtime_classification_amortizes`）。

| ステップ | 分類 | 推奨実装手段 | 備考 |
|---|---|---|---|
| Step 1: manifest-trace CLI 実行 | **deterministic** | CLI コマンド | サブコマンド選択はユーザー指示に基づく機械的分岐 |
| Step 2: 結果の解釈 | **judgmental** | LLM | カバレッジギャップ・違反の意味論的評価。自動化不可 |
| Step 3: 改善提案 | **judgmental** | LLM | ギャップの原因分析と /evolve 連携判断。自動化不可 |
| Step 4: JSON 構造的分析 | **deterministic** | jq クエリ群 | 4a-4e の全クエリが定型的。スクリプト化済み相当 |
| Step 5: 改善提案テンプレート | **deterministic + judgmental（未分離）** | LLM が直接実行 | deterministic: 検出パターン→提案テンプレートの照合 / judgmental: 提案の優先順位付けと文脈化 |

**設計原則**:
- Step 1, 4 は deterministic — manifest-trace CLI 自体がスクリプト化の具現
- Step 2, 3 は judgmental — 半順序の意味論的解釈は normative 層の本来の用途
- Step 5 の deterministic 成分（テンプレート照合）は分離候補（`mixed_task_decomposition`）

## 実行手順

### Step 1: `manifest-trace` CLI + 検証スクリプトの実行

ユーザーの要求に応じて適切なサブコマンドを実行する:

```bash
# 全指標サマリ（デフォルト）
./manifest-trace health

# カバレッジギャップレポート
./manifest-trace coverage

# 特定命題のトレース（順方向・逆方向・実装成果物）
./manifest-trace trace <PropositionID>

# 半順序違反レポート
./manifest-trace violations

# DOT 形式の依存グラフ（可視化用）
./manifest-trace graph > trace-graph.dot

# refs 本文言及違反レポート（層4 深い検証）
bash scripts/detect-refs-body-violations.sh
```

### Step 2: 結果の解釈

#### カバレッジギャップ
- **✗ 実装なし**: その命題を直接実装する成果物がない。新しい hook/skill/test の追加を検討
- **△ テストなし**: 実装はあるが検証がない。テストの追加を優先

#### 半順序違反
- **依存先未カバー**: 成果物が参照する命題の上流に実装がない。D13 の伝播パターン
- **強制レベル不一致**: L1 (安全境界) を参照する成果物が structural enforcement でない

#### refs 本文言及違反
- **VIOLATION [artifact-id]: 命題リスト**: artifact-manifest.json の refs に宣言した命題が
  ファイル本文（@traces ヘッダ除外）に出現しない。根拠説明の追加が必要

### Step 3: 改善提案

カバレッジギャップや違反が見つかった場合:
1. ギャップの原因を分析（本当に実装が必要か、命題が環境依存で実装不要か）
2. 必要な場合は `/evolve` の Observer フェーズで改善候補として報告
3. 実装する場合は `artifact-manifest.json` にメタデータを追加

### Step 4: JSON 構造的分析

`manifest-trace json` の出力を jq で解析し、定量的な洞察を得る。

#### 4a. 深さ別カバレッジ（strength 5→1）

```bash
./manifest-trace json | jq '
  [.propositions[] | {s: .strength, covered: (.coverage.total > 0)}]
  | group_by(.s) | map({
      strength: .[0].s,
      total: length,
      covered: [.[] | select(.covered)] | length
    })
  | sort_by(-.strength)
  | .[] | "\(.strength): \(.covered)/\(.total)"
'
```

#### 4b. 根拠カバレッジ（evidence）

```bash
./manifest-trace json | jq '{
  with_evidence: .summary.with_evidence | length,
  without_evidence: .summary.without_evidence | length,
  without_list: .summary.without_evidence
}'
```

#### 4c. テストなし命題の優先順位（D13 伝播を考慮）

依存者が多い命題ほど優先度高（変更の影響が広い）:

```bash
./manifest-trace json | jq '
  [.propositions[]
   | select(.coverage.has_test == false and .coverage.total > 0)
   | {id, dependents: (.depended_by | length), strength}]
  | sort_by(-.dependents, -.strength)
'
```

#### 4d. 孤立ノード検出

depends_on も depended_by も空の命題（半順序に接続されていない）:

```bash
./manifest-trace json | jq '
  [.propositions[]
   | select((.depends_on | length == 0) and (.depended_by | length == 0))
   | .id]
'
```

#### 4e. 依存チェーンの完全性

trunk（根ノード）から leaf まで、カバレッジギャップのない経路が存在するか:

```bash
./manifest-trace json | jq '
  .summary as $s |
  {
    roots: ($s.roots | length),
    leaves: ($s.leaves | length),
    uncovered_on_path: [.propositions[]
      | select((.depends_on | length > 0) and (.depended_by | length > 0) and .coverage.total == 0)
      | .id]
  }
'
```

### Step 5: 改善提案テンプレート

json 分析結果から改善提案を生成する:

| 検出パターン | 改善提案 |
|------------|---------|
| uncovered + strength ≥ 3 | 「{id} に hook/skill を追加すべき（高強度命題の未実装）」 |
| has_test == false + dependents ≥ 3 | 「{id} のテスト追加を優先（D13 伝播で {n} 命題に影響）」 |
| has_evidence == false + T/E 層 | 「{id} に Axiom Card が必要（根拠の欠落）」 |
| 孤立ノード | 「{id} の依存関係を Ontology.lean で定義すべき」 |
| 鮮度期限切れ | 「{id} の根拠を再評価すべき（Last validated 期限超過）」 |

## データソース

- `artifact-manifest.json` — 全成果物→公理マッピング（単一真実源）
- `lean-formalization/Manifest/Ontology.lean` — 命題間依存定義
- `lean-formalization/Manifest/DesignFoundation.lean` — D13 影響波及
- `lean-formalization/Manifest/{Axioms,EmpiricalPostulates,Observable}.lean` — Axiom Card（根拠 + 鮮度）

## 注意事項

- `artifact-manifest.json` のメタデータは手動付与。成果物の追加・変更時に更新が必要
- L5 (プラットフォーム境界) や T3 (有限コンテキスト) など、環境制約として暗黙的に実装されている命題もある
- violations の結果は「潜在的」違反。全てが修正必須ではない
- T8 (grounded constraint) は axiom から theorem に降格済み。Derivation Card で追跡され、Axiom Card (evidence) は不要。observe.sh の evidence_coverage からは除外し、derivation_completeness に含める
