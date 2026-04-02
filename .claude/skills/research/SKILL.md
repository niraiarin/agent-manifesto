---
name: research
description: >
  Gate-Driven Research Workflow を実行する。P3（学習の統治）の運用インスタンス。
  実装前の技術的リサーチを構造化された手順で進める。
  Gap Analysis → Parent Issue → Sub-Issues (with Gates) → Worktree 隔離実験 → Gate 判定。
  「リサーチ」「research」「調査」「研究」「Gap Analysis」で起動。
---

# Gate-Driven Research Workflow

P3（学習の統治）ライフサイクルの運用インスタンス。
実装前の「should we do X?」型の問いに対して、構造化されたリサーチプロセスを実行する。

## Manifesto Root Resolution

このスキルは agent-manifesto リポジトリのファイル（docs/research/）を参照する。
実行前に以下でリポジトリルートを解決すること:

```bash
MANIFESTO_ROOT=$(bash .claude/skills/shared/resolve-manifesto-root.sh 2>/dev/null || echo "")
```

解決できない場合はユーザーに案内する。以降の `docs/` への参照は `${MANIFESTO_ROOT}/` を前置して解決する。

詳細な定義: `${MANIFESTO_ROOT}/docs/research/workflow/research-workflow.md`

## ワークフロー

```
Gap Analysis → Parent Issue → Sub-Issues (with gates)
                                  ↓
                          Git Worktree (isolated)
                                  ↓
                          Experiment → Results (issue comment)
                                  ↓
                          Gate Judgment
                         ╱      │       ╲
                      PASS  CONDITIONAL  FAIL
                       │        │         │
                     Close   Sub-issue  Escalate
                              (recurse)
```

## P3 ライフサイクルとの対応

| ステップ | P3 段階 |
|---|---|
| Gap Analysis | 観察 |
| Sub-Issue + Gate 定義 | 仮説化 |
| 実験 + 結果記録 | 検証 |
| Gate PASS | 統合 |
| Gate CONDITIONAL | 仮説化（再帰） |
| Gate FAIL | 退役 |

## 実行手順

### Step 1: Gap Analysis

対象の現状と目標を把握し、Gap を列挙する。

各 Gap について:
```markdown
### Gap N: [Name]
- **現状**: ...
- **必要**: ...
- **リスク**: high / medium / low
- **未知**: ...
```

リスクで降順ソート。最高リスクの Gap を最初に着手する（fail-fast）。

### Step 2: Parent Issue 作成

`gh issue create` で以下を含む Parent Issue を作成:

```markdown
## 背景
[なぜこのリサーチが必要か]

## 現状 vs 目標
[表形式]

## Gap 一覧
[リスク付きの表]

## Sub-Issues
[リンク表 — 初期は TBD]

## 実行順序
[依存関係の図]
```

### Step 3: Sub-Issues 作成

各 Gap を Sub-Issue にする。テンプレート:

```markdown
Parent: #N

## 目的
[一文: この研究が答える問い]

## 背景
[なぜ重要か]

## 方法
[具体的な実験手順]

## 成果物
[何が生まれるか]

## 依存
[他の Sub-Issue への依存、または "なし"]

## Gate 判定プロセス

実験実施 → 結果記録（コメント） → Gate 判定
  ├─ PASS: [基準] → [アクション]
  ├─ CONDITIONAL: [基準] → sub-issue 起票
  └─ FAIL: [基準] → [アクション]
```

作成後、Parent Issue の Sub-Issues テーブルを更新する。

### Step 4: Git Worktree 作成

コード変更が見込まれる場合:

```bash
git worktree add ../project-research-N -b research/N-topic-name main
```

### Step 5: 実験実施

Worktree で作業。結果は Issue コメントとして記録:

```markdown
### [YYYY-MM-DD] 実験名

**条件**: ...
**結果**: ...
**考察**: ...
**次のアクション**: ...
```

### Step 6: Judge 評価 + Gate 判定

Gate 判定の前に、LLM-as-a-judge（`.claude/agents/judge.md`）による構造化評価を実施する。

#### 6a. Judge 評価の実施

Judge agent に以下を渡す:
- 実験結果のコメント
- Sub-Issue で定義した Gate PASS/FAIL 基準
- 成果物のファイルリスト

Judge は G1-G4 基準で評価:

| # | 基準 | 問い |
|---|------|------|
| G1 | 問い応答 | Sub-Issue の問いに答えているか？ |
| G2 | 再現性 | 結果を再現できるか？ |
| G3 | 判断根拠 | PASS/FAIL の根拠が定量的か？ |
| G4 | 次アクション | 次のステップが明確か？ |

#### 6b. Gate 判定

Judge 評価を踏まえて Gate 判定を行う:

```markdown
### Judge 評価

| 基準 | スコア | 根拠 |
|------|--------|------|
| G1 問い応答 | N/5 | ... |
| G2 再現性 | N/5 | ... |
| G3 判断根拠 | N/5 | ... |
| G4 次アクション | N/5 | ... |

**総合スコア**: X.X/5.0

### Gate: [判定名]

**日付**: YYYY-MM-DD
**判定**: PASS / CONDITIONAL / FAIL
**Judge スコア**: X.X/5.0
**根拠**: [定量データまたは定性的評価]
**追加研究**: 必要 → #XX / 不要
**次のアクション**: ...
```

Judge 推奨: 平均 ≥ 3.5 → PASS 推奨、< 3.5 → 再検討推奨。
最終判定は人間が行う（T6）。Judge 結果は参考材料。

| 判定 | 意味 | アクション |
|------|------|----------|
| PASS | 基準充足 | Issue close。Parent 更新 |
| CONDITIONAL | 追加研究が必要 | 子 issue 起票（再帰） |
| FAIL | 前提が崩れた | Parent にエスカレーション |

### Step 7: クロージング

全 Sub-Issue 完了後:

1. Parent Issue に全体サマリをコメント
2. 全体 Gate 判定（GO / NO-GO / CONDITIONAL）
3. GO → PR 作成、マージ後に Worktree クリーンアップ
4. NO-GO → 代替案を文書化して close

## アンチパターン

| やってはいけないこと | 理由 | 代わりに |
|---|---|---|
| Gate なしの探索 | 収束しない | Gate 基準を事前定義 |
| 結果を見てから閾値設定 | 確証バイアス | Sub-Issue 作成時に定義 |
| 最終コメント1つにまとめる | 途中の失敗が不可視 | 実験ごとにコメント |
| Gate 前に Worktree マージ | 未検証コードが main に入る | PASS がマージの前提 |
| CONDITIONAL で子 issue なし | 「追加研究が必要」で放置 | 必ず子 issue を起票 |

## D13 との関係

Gate FAIL は D13（前提否定の影響波及）を発動する:
- FAIL した仮説に依存する sibling sub-issue は影響集合に含まれる
- Lean の `d13_propagation` で**マニフェスト命題間**の影響範囲を計算可能（PropositionId レベル。研究 sub-issue 間の依存には直接適用されない）
