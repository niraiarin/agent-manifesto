# #157 公理系の数理的基盤整備 — 作業ワークフロー

## 概要

公理系の全要素（T, E, P, L, D, 定理）を数理的基盤に基づいて再検証・再分類する。
LLM の数理統計学的構成から演繹可能な「公理」を定理に降格し、
真に仮定が必要なもの（契約、定義的選択）のみを公理として残す。

## ツール一覧

| コマンド | 用途 | フェーズ |
|---|---|---|
| `depgraph.sh classify` | 全 axiom の分類表示（basis / 再分類候補 / rdeps） | 計画 |
| `depgraph.sh axioms` | 全 axiom の依存・被依存数一覧 | 計画 |
| `depgraph.sh subgraph <name>` | 指定要素の関連グラフ抽出（DOT/JSON） | 分析 |
| `depgraph.sh deps <name>` | 指定要素の依存先一覧 | 分析 |
| `depgraph.sh impact <name>` | 変更の波及範囲（影響を受ける全 theorem） | 分析 |
| `depgraph.sh rebuild` | generate + diff + verify を一括実行 | 検証 |
| `depgraph.sh diff <old> [new]` | 変更前後のグラフ差分 | 検証 |
| `depgraph-verify.sh` | 完全性・DAG 整合・到達性・相互参照の検証 | 検証 |

## 作業サイクル

```
┌─────────────────────────────────────────────────────────┐
│  Phase 0: 計画                                          │
│                                                         │
│  classify → 着手順序を決定                               │
│  (rdeps=0 かつ derivable な axiom から着手 = fail-fast)  │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│  Phase 1: 分析（対象 axiom ごとに繰り返す）              │
│                                                         │
│  1. subgraph <axiom> --format=json                      │
│     → 関連するノード・エッジの構造を把握                  │
│                                                         │
│  2. impact <axiom>                                      │
│     → 変更したら何が壊れるかを事前確認                    │
│                                                         │
│  3. deps <axiom>                                        │
│     → この axiom が依存する型定義を確認                   │
│                                                         │
│  4. 数理的基盤の検討                                     │
│     → この axiom は何から導出可能か？                     │
│     → 必要な基礎理論（softmax, attention 等）は何か？     │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│  Phase 2: 実装                                          │
│                                                         │
│  1. 数理的基盤を Lean に定義                             │
│     (def / structure / theorem)                         │
│                                                         │
│  2. axiom → theorem に書き換え                           │
│     (axiom 宣言を theorem 宣言 + 証明に変更)             │
│                                                         │
│  3. lake build Manifest で型検査通過を確認               │
│                                                         │
│  4. 影響を受ける theorem が壊れていないか確認             │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│  Phase 3: 検証                                          │
│                                                         │
│  rebuild                                                │
│    → 自動スナップショット + generate + diff + verify     │
│                                                         │
│  確認事項:                                               │
│    - diff: Kind Changes に対象 axiom → theorem が表示    │
│    - diff: axiom 数が -1、theorem 数が +N               │
│    - diff: 新規ノード（基礎理論の def/structure）が表示  │
│    - verify: VERDICT = PASS                              │
│    - verify: 孤立 axiom 数が減少（または維持）           │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│  Phase 4: 記録                                          │
│                                                         │
│  1. Issue #157 にコメント（変更内容・diff 結果）         │
│  2. コミット（互換性分類付き）                           │
│  3. 次の axiom へ → Phase 1 に戻る                      │
└─────────────────────────────────────────────────────────┘
```

## 着手順序の基準

`classify` の出力に基づき、以下の優先順位で着手する:

### 1. rdeps=0 × derivable（最優先 — 影響ゼロで安全に検証可能）

| Axiom | Basis | rdeps |
|---|---|---|
| `context_bounds_action` | environment | 0 |
| `no_cross_session_memory` | environment | 0 |
| `resource_finite` | environment | 0 |
| `session_no_shared_state` | environment | 0 |

これらは変更しても他の theorem に影響がない。
数理的基盤の導入方法を確立するための最初の実験対象。

### 2. rdeps > 0 × derivable（中優先 — 波及あり、基盤確立後に着手）

| Axiom | Basis | rdeps |
|---|---|---|
| `output_nondeterministic` | natural-science | 3 |
| `context_finite` | environment | 1 |
| `session_bounded` | environment | 2 |
| `structure_persists` | environment | 3 |
| `structure_accumulates` | environment | 4 |
| `context_contribution_nonuniform` | natural-science | 3 |
| `no_improvement_without_feedback` | natural-science | 2 |

### 3. derivable?（仮説由来 — 統計的検定理論からの導出を検討）

| Axiom | Basis | rdeps |
|---|---|---|
| `verification_requires_independence` | hypothesis | 4 |
| `capability_risk_coscaling` | hypothesis | 3 |
| `no_self_verification` | hypothesis | 1 |
| `shared_bias_reduces_detection` | hypothesis | 0 |

### 4. true-axiom（据え置き — 契約由来、数理的導出不可能）

| Axiom | Basis | rdeps |
|---|---|---|
| `human_resource_authority` | contract | 0 |
| `resource_revocable` | contract | 1 |
| `task_has_precision` | contract | 1 |

これらは真の公理として残る。ただし計算可能な数式化は検討対象。

### 5. no-card / design（最後 — Axiom Card 未整備または設計判断由来）

37 axioms。Axiom Card の整備 → 分類 → 個別判断の順で処理。

## 各フェーズの具体的コマンド例

### Phase 0: 計画

```bash
# 全 axiom の分類を確認
depgraph.sh classify

# rdeps=0 の axiom を確認（影響ゼロの安全な着手候補）
depgraph.sh axioms | grep 'rdeps=  0'
```

### Phase 1: 分析（例: output_nondeterministic）

```bash
# 関連グラフを JSON で取得
depgraph.sh subgraph output_nondeterministic --format=json > /tmp/t4-subgraph.json

# 関連グラフを DOT で可視化
depgraph.sh subgraph output_nondeterministic > /tmp/t4.dot
dot -Tpng /tmp/t4.dot -o /tmp/t4.png  # graphviz 必要

# 影響範囲を確認
depgraph.sh impact output_nondeterministic

# 依存先を確認
depgraph.sh deps output_nondeterministic
```

### Phase 2: 実装

```bash
# Lean コードを変更（エディタで作業）
# axiom output_nondeterministic → theorem + 証明

# ビルド確認
cd lean-formalization
export PATH="$HOME/.elan/bin:$PATH"
lake build Manifest
```

### Phase 3: 検証

```bash
# 一括実行: スナップショット保存 + 再生成 + diff + verify
depgraph.sh rebuild

# または手動で個別実行:
cp depgraph.json depgraph-before.json
depgraph.sh generate
depgraph.sh diff depgraph-before.json
depgraph-verify.sh
```

### Phase 4: 記録

```bash
# Issue にコメント
gh issue comment 157 --body "..."

# コミット（互換性分類付き）
git commit -m "#157: output_nondeterministic を axiom → theorem に降格 (compatible change)

softmax + temperature > 0 からの導出を Lean で形式化。
depgraph diff: axiom -1, theorem +1, 新規 def +2"
```

## 不変条件

ワークフロー全体を通じて以下を維持する:

1. **`lake build Manifest` が常に成功する** — 型検査エラーゼロ
2. **`depgraph-verify.sh` が PASS** — DAG 整合性、到達性、完全性
3. **sorry が 0 のまま** — 証明の穴を作らない
4. **影響を受けた theorem が壊れない** — impact で事前確認、rebuild で事後確認
5. **各コミットに互換性分類** — P3 の構造変更ルール準拠
