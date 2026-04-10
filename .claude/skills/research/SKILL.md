---
name: research
user-invocable: true
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

実験結果が後続ステップの入力になる場合（条件付き公理系の構築、プラットフォーム調査等）、
Issue コメントだけでなく**構造化ファイル**（Lean, JSON 等）として永続化すること。
→ Step 5.5 で外部事実を Assumption 型に変換する。

### Step 5.5: 仮定抽出と構造化 (#336)

実験で使用した**外部事実**（プラットフォーム仕様、API 挙動、ドキュメントからの推論等）を
条件付き公理系の仮定 (CC-C/H) として構造化する。

**省略条件**: 研究が調査のみ（コード成果物・条件付き公理系の変更なし）の場合はスキップ可能。
省略した場合、Judge の G5 は N/A として評価する。

**このステップを省略した場合**: 外部事実が def にハードコードされ、
TemporalValidity による陳腐化検知が不可能になる。
（#311 PR #330 で 9 件の仮定が未登録のまま Gate PASS し、7 ラウンドの修正が必要になった）

#### 5.5a. 外部事実の識別

実験結果から外部事実を列挙する。各事実を以下に分類:
- **C (Human Decision)**: 人間が選択した設計判断（T6 の権威に基づく）
- **H (LLM Inference)**: ドキュメント・実装から LLM が推論した事実

判定基準: 「人間が別の選択をしていたら変わるか？」→ Yes なら C、No なら H。

#### 5.5b. Assumption 型への変換

各外部事実を `Assumptions.lean` に追加:

```lean
def cc_hN : Assumption := {
  id := "CC-HN"
  source := .llmInference
    ["依存する仮定 ID リスト"]
    "反証条件: どのような変化が起きたらこの仮定が無効になるか"
  content := "事実の内容"
  validity := some {
    sourceRef := "再検証可能な URL またはファイルパス"
    lastVerified := "YYYY-MM-DD"
    reviewInterval := some N  -- 日数（変動リスクに応じて 60-180）
  }
}
```

#### 5.5c. チェックリスト

- [ ] def/theorem の Derivation Card がドキュメント URL を直接参照していないか？
  → URL がある場合、それは Assumption 経由に変換すべき外部事実
- [ ] 全ての新規 Assumption に TemporalValidity が設定されているか？
- [ ] 全ての H-type Assumption に反証条件が付与されているか？
- [ ] `allAssumptions` に全件登録されているか？
- [ ] Derivation Card の `Derives from` が Assumption ID を参照しているか？

### Step 6: Judge 評価 + Gate 判定

Gate 判定の前に、LLM-as-a-judge（`.claude/agents/judge.md`）による構造化評価を実施する。

#### 6a. Judge 評価の実施

Judge agent に以下を渡す:
- 実験結果のコメント
- Sub-Issue で定義した Gate PASS/FAIL 基準
- 成果物のファイルリスト

Judge は G1-G5 基準で評価:

| # | 基準 | 問い |
|---|------|------|
| G1 | 問い応答 | Sub-Issue の問いに答えているか？ |
| G2 | 再現性 | 結果を再現できるか？ |
| G3 | 判断根拠 | PASS/FAIL の根拠が定量的か？ |
| G4 | 次アクション | 次のステップが明確か？ |
| G5 | 仮定接続 | 外部事実が Assumption 型を経由し、Derivation Card が仮定 ID を参照しているか？ (#336) |

#### 6b. 減点解消ループ（#289 対応）

Judge 評価の各減点を **addressable**（対処可能）/ **unaddressable**（構造的限界）に分類し、
対処可能な減点を解消してから Gate 判定に進む。

```
Judge 評価 → 各減点を addressable / unaddressable に分類
  ├─ addressable が 0 件
  │   → Gate 判定へ（unaddressable の理由を記録）
  ├─ addressable が残存
  │   → Judge の対処案に従い修正
  │   → Judge に再判定を依頼（最大 2 回）
  │   → 2 回後も addressable が残存 → unaddressable に降格し理由を記録
  └─ 全基準が 1 点以下
      → Gate FAIL
```

**旧閾値（≥ 3.5 → PASS 推奨）の廃止理由:**
スコア閾値は「対処可能な減点を放置する免罪符」として機能していた（#289）。
G1-G3 のいずれかで減点があり、その減点が対処可能であるにもかかわらず、
平均スコアが閾値を超えているだけで PASS 扱いされ、品質問題が蓄積していた。

#### 6c. Gate 判定

減点解消ループ後、Gate 判定を行う:

```markdown
### Judge 評価

| 基準 | スコア | 根拠 |
|------|--------|------|
| G1 問い応答 | N/5 | ... |
| G2 再現性 | N/5 | ... |
| G3 判断根拠 | N/5 | ... |
| G4 次アクション | N/5 | ... |
| G5 仮定接続 | N/5 | ... |

**総合スコア**: X.X/5.0（診断値。判定基準は減点分類）

### 減点分類

| 基準 | 減点内容 | 分類 | 対処案 |
|------|---------|------|--------|
| ... | ... | addressable / unaddressable | ... |

### Gate: [判定名]

**日付**: YYYY-MM-DD
**判定**: PASS / CONDITIONAL / FAIL
**根拠**: [定量データまたは定性的評価]
**残存減点**: [unaddressable のみ（addressable は解消済み）]
**追加研究**: 必要 → #XX / 不要
**次のアクション**: ...
```

スコアは診断ツール。判定基準は「対処可能な減点が残っているか」。
最終判定は人間が行う（T6）。Judge 結果は参考材料。

| 判定 | 意味 | アクション |
|------|------|----------|
| PASS | addressable 減点なし | Issue close。Parent 更新 |
| CONDITIONAL | 追加研究が必要 | 子 issue 起票（再帰） |
| FAIL | 前提が崩れた | Parent にエスカレーション |

### Step 7: クロージング

全 Sub-Issue 完了後:

1. Parent Issue に全体サマリをコメント
2. 全体 Gate 判定（GO / NO-GO / CONDITIONAL）
3. GO → PR 作成、マージ後に Worktree クリーンアップ
4. NO-GO → 代替案を文書化して close

### Step 7.5: Downstream Skill 連携 (#336)

研究成果を後続スキルに接続する。D4 フェーズ順序に従い:

1. **/verify**: Lean コード成果物がある場合、P2 独立検証を実施
   - Judge (G1-G5) とは別に、Verifier agent によるコード正確性検証
   - リスクレベルに応じて human review をエスカレーション
2. **/trace**: 新規成果物を `artifact-manifest.json` に登録
   - 型定義、定理、仮定のトレーサビリティを確保
   - /trace の `manifest-trace coverage` で検出可能にする
3. **/metrics**: V1-V7 への影響を before/after で計測
   - 特に V6（知識構造品質）、V7（タスク設計効率）

省略条件: 研究が調査のみ（コード成果物なし）の場合、Step 7.5 は省略可能。

## See Also: 呼び出し元スキル (#336)

/research は以下のスキルから呼び出される。出力形式はこれらの入力要件を意識すること。

| 呼び出し元 | 呼び出し箇所 | 期待される出力 |
|---|---|---|
| `/spec-driven-workflow` | Phase 0 Step 2 | Gap Analysis 結果 → Phase 1 の入力 |
| `/design-implementation-plan` | Step 0 investigate | platform-decisions.json 形式の調査結果 |
| `/generate-plugin` | Phase 0 | プラットフォームの PD (Platform Decisions) |
| `/ground-axiom` | Step 1 | 先行研究の文献調査結果 |
| `/evolve` | Research Gate | breaking change 提案の裏付け調査 |

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

## 既知の改善候補

以下は運用で発見された不備と対応状況。

### 改善 1: 研究成果の永続化要件が欠如 → **反映済み (2026-04-10, #336)**

Step 5.5 (仮定抽出と構造化) で対応。外部事実は Assumption 型として Assumptions.lean に
構造化永続化される。TemporalValidity により陳腐化検知が可能。

### 改善 2: D17 との連携が未定義 → **反映済み (2026-04-10, #336)**

See Also セクションで呼び出し元 5 スキルを列挙。
/design-implementation-plan の期待出力 (platform-decisions.json) を明記。

### 改善 3: 失敗・見落としの記録メカニズムがない → **反映済み (2026-04-10, #336)**

Gate CONDITIONAL/FAIL 時の自己改善判定:
Judge 評価の G5 (仮定接続) が追加され、仮定管理の欠落が Gate 判定前に検出される。
Gate CONDITIONAL の場合、「skill 自体の不備か、研究課題の本質的困難か」を判別し、
skill 不備の場合はこのセクションに追記すること。

### 改善 4: SKILL.md 変更で対処不能な欠落 (#336)

以下は /research SKILL.md のステップ追加では対処できず、別の仕組みで対応が必要:

- **B3 (artifact-manifest 登録)**: /trace skill 側の自動検出に依存。Step 7.5 で手動呼び出しを推奨
- **B5 (公理根拠検証)**: /ground-axiom skill の責務。/research が新規 axiom を導入する場合のみ関連
- **E8 (Agent Teams サポート)**: /evolve の Agent Teams アーキテクチャ側の改善が必要
- **C2 (既存層定義との型レベル関係)**: Lean コード設計の責務。/formal-derivation で対応

（#336 Phase 3 / /evolve で漸進的に対処）
