---
name: research
user-invocable: true
description: >
  Gate-Driven Research Workflow を実行する。P3（学習の統治）の運用インスタンス。
  実装前の技術的リサーチを構造化された手順で進める。
  Gap Analysis → Parent Issue → Sub-Issues (with Gates) → Worktree 隔離実験 → Gate 判定。
  「リサーチ」「research」「調査」「研究」「Gap Analysis」で起動。
dependencies:
  invokes:
    - skill: verify
      type: soft
      phase: "Step 7.5"
      condition: "Lean コード成果物がある場合"
    - skill: trace
      type: soft
      phase: "Step 7.5"
      condition: "新規成果物がある場合"
    - skill: metrics
      type: soft
      phase: "Step 7.5"
      condition: "コード成果物がある場合"
  invoked_by:
    - skill: spec-driven-workflow
      phase: "Phase 0 Step 2"
      expected_output: "Gap Analysis 結果"
    - skill: design-implementation-plan
      phase: "Step 0 investigate"
      expected_output: "platform-decisions.json 形式の調査結果"
    - skill: generate-plugin
      phase: "Phase 0"
      expected_output: "Platform Decisions (PD)"
    - skill: ground-axiom
      phase: "Step 1"
      expected_output: "先行研究の文献調査結果"
    - skill: evolve
      phase: "Research Gate"
      expected_output: "breaking change 提案の裏付け調査"
  agents:
    - agent: judge
      role: "G1-G5 structured evaluation for Gate judgment"
---
<!-- @traces P3, D3, D13 -->

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
Gap Analysis ⇄ Verify (P2)  → Parent Issue → Sub-Issues (with gates)
  (loop until                                      ↓
   addressable=0)                      Sub-Issue Verify (P2)
                                        (loop until
                                         addressable=0)
                                                   ↓
                                           Git Worktree (isolated)
                                                   ↓
                                           Experiment → Results (issue comment)
                                                   ↓
                                           Gate Judgment
                                          ╱      │       ╲
                                       PASS  CONDITIONAL  FAIL
                                         │        │         │
                                         └────────┴─────────┘
                                                  ↓
                                        Re-evaluate remaining
                                           Sub-Issues (6d)
                                                  ↓
                                         Next Sub-Issue / Step 7
```

## P3 ライフサイクルとの対応

| ステップ | P3 段階 |
|---|---|
| Gap Analysis | 観察 |
| Gap Analysis 検証 (Step 1.5) | 検証（P2 独立性） |
| Sub-Issue + Gate 定義 | 仮説化 |
| Sub-Issue 検証 (Step 3.5) | 検証（P2 独立性） |
| 実験 + 結果記録 | 検証 |
| Gate PASS | 統合 |
| Gate CONDITIONAL | 仮説化（再帰） |
| Gate FAIL | 退役 |

## タスク自動化分類（TaskClassification.lean 準拠, #359/#377）

各ステップの `TaskAutomationClass` をデザインタイムに定義する。
実行時に LLM が毎回判断するコストを排除する（`designtime_classification_amortizes`）。

| ステップ | 分類 | 推奨実装手段 | 備考 |
|---|---|---|---|
| Step 1a: 調査ログ | **judgmental** | LLM | 調査過程・却下理由の記録。自動化不可 |
| Step 1b: Gap 列挙 | **judgmental** | LLM | 意味論的評価。自動化不可 |
| Step 1.5: Gap 検証ループ | **bounded + deterministic（分離済み）** | Verifier agent（検証） + カウント判定スクリプト（残存数） | `mixed_task_decomposition` 適用済み ✓: bounded = Verifier 委譲、deterministic = addressable 残存数判定 |
| Step 2: Parent Issue 作成 | **deterministic + judgmental（未分離）** | テンプレートスクリプト + LLM（内容記述） | deterministic: テンプレート構造生成 / judgmental: 背景・Gap 一覧の記述 |
| Step 3: Sub-Issue 作成 | **deterministic + judgmental（未分離）** | テンプレートスクリプト + LLM（内容記述） | deterministic: テンプレート構造生成 / judgmental: Gate 基準の設計 |
| Step 3.5: Sub-Issue 検証ループ | **bounded + deterministic（分離済み）** | Verifier agent（検証） + カウント判定スクリプト（残存数） | `mixed_task_decomposition` 適用済み ✓: bounded = Verifier 委譲、deterministic = addressable 残存数判定 |
| Step 4: Worktree 作成 | **deterministic** | スクリプト（worktree.sh） | スクリプト化済み ✓ |
| Step 5: 実験実施 | **judgmental** | LLM | 研究の本質。自動化不可 |
| Step 5.5: 仮定抽出 | **judgmental + deterministic（未分離）** | LLM（識別・分類） + チェックスクリプト（5.5c） | judgmental: 外部事実の識別と C/H 分類 / deterministic: 5.5c チェックリスト |
| Step 6a: Judge 評価 | **bounded** | Judge agent | 構造化評価。agent 委譲済み |
| Step 6b: 減点解消 | **judgmental + deterministic（未分離）** | LLM（修正） + カウント判定スクリプト | judgmental: 修正内容の判断 / deterministic: addressable 残存数判定 |
| Step 6c: Gate 判定 + Handoff | **judgmental + deterministic（未分離）** | 人間（T6） + Handoff 判定（deterministic） | judgmental: 最終判定は人間（T6） / deterministic: Handoff 先判定は Yes/No |
| Step 6d: 後続再評価 | **deterministic + judgmental（未分離）** | 依存グラフ走査スクリプト + LLM（影響判定） | deterministic: グラフ走査 / judgmental: 前提変化の影響判定 |
| Step 7: クロージング | **deterministic + judgmental（未分離）** | クロージングスクリプト + LLM（サマリ） | deterministic: issue close, worktree cleanup / judgmental: 全体サマリ記述 |
| Step 7.5: 下流連携 | **deterministic + judgmental（未分離）** | チェックリストスクリプト + LLM（判断） | deterministic: /trace, /verify 呼び出し / judgmental: 呼び出し要否の判断 |

**設計原則**:
- deterministic 成分は構造的強制で実行する（`deterministic_must_be_structural`）
- 未分離ステップ（Step 2, 3, 5.5, 6b, 6c, 6d, 7, 7.5）は成分分離の対象（`mixed_task_decomposition`）
- judgmental タスクを LLM に委ねるのは適切（normative 層の本来の用途）

### 照合チェックリスト（#364 G2: 分類の正当化マッピング）

各ステップの分類を正当化する TaskClassification.lean の定理。
独立再現: この表の各行について、定理の内容とステップの性質が整合するか検証可能。

| ステップ | 分類 | 正当化する定理 | 正当化の根拠 |
|---|---|---|---|
| Step 1a | judgmental | `classification_is_judgmental` | 調査過程の記録は意味論的評価（Rice の定理）|
| Step 1b | judgmental | `classification_is_judgmental` | Gap の意味論的評価は決定不能 |
| Step 1.5 | bounded + deterministic（分離済み） | `mixed_task_decomposition`, `observable_implies_automatable` | bounded: Verifier 委譲 / deterministic: 残存数は Observable |
| Step 2 | deterministic + judgmental（未分離） | `mixed_task_decomposition` | テンプレート構造は deterministic、内容記述は judgmental |
| Step 3 | deterministic + judgmental（未分離） | `mixed_task_decomposition` | テンプレート構造は deterministic、Gate 基準設計は judgmental |
| Step 3.5 | bounded + deterministic（分離済み） | `mixed_task_decomposition`, `observable_implies_automatable` | bounded: Verifier 委譲 / deterministic: 残存数は Observable |
| Step 4 | deterministic | `deterministic_must_be_structural`, `observable_implies_automatable` | worktree 作成の成功条件は Observable（ディレクトリ存在） |
| Step 5 | judgmental | `classification_is_judgmental` | 研究の本質。決定手続き不在 |
| Step 5.5 | judgmental + deterministic（未分離） | `mixed_task_decomposition` | 識別・分類は judgmental、チェックリストは deterministic |
| Step 6a | bounded | `automation_enforcement_consistent` | 評価は有限時間で完了するが、正解の決定手続きはない |
| Step 6b | judgmental + deterministic（未分離） | `mixed_task_decomposition` | 修正内容は judgmental、残存数判定は deterministic |
| Step 6c | judgmental + deterministic（未分離） | `mixed_task_decomposition` | 最終判定は judgmental（T6）、Handoff 先判定は deterministic |
| Step 6d | deterministic + judgmental（未分離） | `mixed_task_decomposition` | グラフ走査は deterministic、影響判定は judgmental |
| Step 7 | deterministic + judgmental（未分離） | `mixed_task_decomposition` | issue close は deterministic、サマリは judgmental |
| Step 7.5 | deterministic + judgmental（未分離） | `mixed_task_decomposition` | /trace 呼び出しは deterministic、要否判断は judgmental |

**維持手順** (#364 G4): ステップ追加・変更時は上記テーブルも更新すること。
整合性は `scripts/validate-task-classification.sh` で自動検証される。

## 実行手順

### Step 1: Gap Analysis

対象の現状と目標を把握し、Gap を列挙する。

#### 1a. 調査ログの記録

Gap Analysis に至るまでの調査過程を記録する。
結果だけでなく「何を読み、何を比較し、何を捨てたか」を残す。

**記録先**: Step 2 で Parent Issue を作成した直後に転記する。
Step 1a の時点では手元（会話内テキスト）に記録し、Step 2 で Issue 作成後に
最初のコメントとして投稿する。

```markdown
### [YYYY-MM-DD] 調査ログ

**調査対象**: [読んだファイル、参照した定理、比較した実装]
**発見**: [何がわかったか]
**却下した選択肢**: [検討したが採用しなかったアプローチとその理由]
**Gap への接続**: [この調査から導出された Gap の番号]
```

**理由**: 調査過程が記録されないと、(1) 後続の実行者が同じ調査を繰り返す、
(2) Gap の妥当性を検証する際に根拠を遡れない、
(3) 却下した選択肢が再提案される。

#### 1b. Gap の列挙

各 Gap について:
```markdown
### Gap N: [Name]
- **現状**: ...
- **必要**: ...
- **リスク**: high / medium / low
- **未知**: ...
```

リスクで降順ソート。最高リスクの Gap を最初に着手する（fail-fast）。

### Step 1.5: Gap Analysis の独立検証（ループ）

Gap Analysis は judgmental タスク（`classification_is_judgmental`）であり、
観察段階のバイアスが後続の全ステップに波及する（D13）。
P2（検証の独立性）に基づき、Verifier agent による独立検証を実施する。

検証項目:
- **分類の正確性**: 各 Gap の性質分類は正しいか（誤分類はないか）
- **公理系との整合性**: 参照している定理・定義と Gap の対応は正確か
- **漏れ**: 指摘されていない Gap はないか
- **リスク評価**: high / medium / low の評価は妥当か
- **事実確認**: 現状記述が実際のコード・ファイルと一致するか

#### 減点解消ループ（Step 6b と同パターン）

```
Gap Analysis → Verifier 検証
  → 各指摘を addressable / unaddressable に分類
  ├─ addressable が 0 件
  │   → Step 2 へ進む（unaddressable の理由を記録）
  ├─ addressable が残存
  │   → Gap Analysis を修正（修正箇所を記録）
  │   → Verifier に再検証を依頼（最大 2 回）
  │   → 2 回後も addressable が残存 → unaddressable に降格し理由を記録
  └─ Gap Analysis の根本的誤り（全 Gap が無効等）
      → Step 1 からやり直し
```

「addressable 指摘が残存するか」の判定は deterministic（カウント比較）。
修正自体は judgmental（`mixed_task_decomposition` の適用対象）。

**完了条件（deterministic）**: 以下の 2 条件を **両方** 満たすこと:
1. Verifier の最終ラウンドで addressable = 0 件
2. その最終ラウンド以降に成果物（Gap Analysis テキスト）への変更がないこと

条件 2 が満たされない場合（= 修正した場合）、修正後の状態で Verifier を再実行する。
**自分で「修正したから OK」と判断して次に進むことは P2 違反。**

**省略条件**: Gap が 1 件のみで low risk の場合はスキップ可能。

### Step 2: Parent Issue 作成

テンプレート骨格をスクリプトで生成し、LLM が内容を記述する（`mixed_task_decomposition`）:

```bash
bash .claude/skills/research/scripts/issue-template.sh parent "タイトル"
```

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

テンプレート骨格をスクリプトで生成し、LLM が内容を記述する（`mixed_task_decomposition`）:

```bash
bash .claude/skills/research/scripts/issue-template.sh sub <parent-number> <gap-number> "タイトル"
```

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

### Step 3.5: Sub-Issue の独立検証（ループ）

Sub-Issue の Gate 基準は後続の全実験の方向を決定する。
Gate 基準の不備は実験完了後まで検出されず、手戻りコストが大きい（D13）。
P2（検証の独立性）に基づき、Verifier agent による独立検証を実施する。

検証項目:
- **Gap Analysis との整合性**: 各 Sub-Issue が対応する Gap を正しく反映しているか
- **Gate 基準の計測可能性**: PASS/CONDITIONAL/FAIL の基準が客観的に判定可能か（曖昧な基準はないか）
- **Gate 基準の反証可能性**: FAIL 条件が定義されているか（PASS しかない Gate は無意味）
- **依存関係の正確性**: Sub-Issue 間の依存が正しく指定されているか
- **方法の具体性**: 実験手順が次の実行者に再現可能な具体性を持っているか
- **成果物の明確性**: 何が生まれるかが具体的に定義されているか

#### 減点解消ループ（Step 1.5 と同パターン）

```
Sub-Issues → Verifier 検証
  → 各指摘を addressable / unaddressable に分類
  ├─ addressable が 0 件
  │   → Step 4 へ進む（unaddressable の理由を記録）
  ├─ addressable が残存
  │   → Sub-Issue を修正（修正箇所を記録）
  │   → Verifier に再検証を依頼（最大 2 回）
  │   → 2 回後も addressable が残存 → unaddressable に降格し理由を記録
  └─ Sub-Issue の根本的誤り（Gate 基準が全て無効等）
      → Step 3 からやり直し
```

「addressable 指摘が残存するか」の判定は deterministic（カウント比較）。
修正自体は judgmental（`mixed_task_decomposition` の適用対象）。

**完了条件（deterministic）**: 以下の 2 条件を **両方** 満たすこと:
1. Verifier の最終ラウンドで addressable = 0 件
2. その最終ラウンド以降に成果物（Sub-Issue テキスト）への変更がないこと

条件 2 が満たされない場合（= 修正した場合）、修正後の状態で Verifier を再実行する。
**自分で「修正したから OK」と判断して次に進むことは P2 違反。**

**省略条件**: Sub-Issue が 1 件のみで、かつ Gate 基準が定量的に定義されている場合はスキップ可能。

### Step 4: Git Worktree 作成

コード変更が見込まれる場合（`deterministic` → スクリプトで実行）:

```bash
bash .claude/skills/research/scripts/worktree.sh create <issue-number> <topic-name>
```

### Step 5: 実験実施

Worktree で作業。結果は Issue コメントとして記録:

```markdown
### [YYYY-MM-DD] 実験名

**条件**: ...
**アプロー���選択**: [採用した方法と、検討して却���した代替案]
**先行調査**: [参照したファイ���・定理・外部資料]
**結果**: ...
**考察**: ...
**判断根拠**: [なぜこの結論に至ったか。定量データまたは比較の要約]
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

**省略条件（パターン確立後の軽量 Gate）**:
同一 Parent Issue 内で以下の条件を **全て** 満たす場合、Judge 評価を Verifier PASS のみに簡略化できる:
1. 先行 Sub-Issue で同一スコープの Judge 評価が 2 件以上完了している（パターン確立）
2. 先行 Judge で G1-G4 が全て 4/5 以上
3. 現在の Sub-Issue の成果物が先行と同一形式（例: 全て SKILL.md へのテーブル追加）
4. Verifier が addressable 指摘 0 件で PASS

省略した場合、Issue コメントに「Verifier PASS + パターン確立済み（#NNN, #NNN で確認）」と
先行 Judge の参照を明記すること。事後の Judge 追記は任意だが、全体評価で指摘された場合は追記する。
（#377 Phase 3-4 で Judge スキップし全体評価で G3 減点 → 事後追記で解消した経験から導出）

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

**完了条件（deterministic）**: 以下の 2 条件を **両方** 満たすこと:
1. Judge/Verifier の最終ラウンドで addressable = 0 件
2. その最終ラウンド以降に成果物（実験結果・コード）への変更がないこと

条件 2 が満たされない場合（= 修正した場合）、修正後の状態で Judge/Verifier を再実行する。
**自分で「修正したから OK」と判断して Gate 判定に進むことは P2 違反。**

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

### Unaddressable 課題の Handoff

| 課題 | 行き先 | 理由 |
|------|--------|------|
| ... | Parent Issue / 別 issue #XX | ... |
```

#### Unaddressable 課題の Handoff ルール

Gate 判定で unaddressable と分類された課題は**必ず行き先を決定する**。
放置は禁止（トラッキングされない課題は消失する）。

行き先の判定基準:
- **Parent Issue に追記**: 同一リサーチの後続 sub-issue で対処可能な場合
- **別 issue を起票**: スコープ外（別スキル、別ワークフロー）で対処が必要な場合

判定は deterministic（「この研究の sub-issue で対処可能か」の Yes/No）。
Yes → Parent、No → 別 issue。

スコアは診断ツール。判定基準は「対処可能な減点が残っているか」。
最終判定は人間が行う（T6）。Judge 結果は参考材料。

| 判定 | 意味 | アクション |
|------|------|----------|
| PASS | addressable 減点なし | Issue close。Parent 更新。Step 6d へ |
| CONDITIONAL | 追加研究が必要 | 子 issue 起票（再帰）。Step 6d へ |
| FAIL | 前提が崩れた | Parent にエスカレーション。Step 6d へ |

#### 6d. 後続 Sub-Issue の再評価（暫定実装 — Gap 5 対応）

Gate 判定の結果（PASS/CONDITIONAL/FAIL いずれも）は、後続 sub-issue の前提を
変える可能性がある。D13（影響波及）を FAIL 以外にも適用する。

```
Gate 判定完了 → 後続 sub-issue リストを走査
  1. 依存グラフから影響を受ける後続 issue を列挙（deterministic: グラフ走査）
  2. 各 issue について前提が変化したか判定（judgmental）
  ├─ 影響なし → 次の sub-issue に進む
  ├─ アプローチ変更が必要 → issue を更新（方法・Gate 基準を修正）
  ├─ 不要になった → close with reason
  └─ 新規 Gap 発見 → 新しい sub-issue を起票、Parent を更新
```

**省略条件**: Sub-Issue が 1 件のみ、または残存 sub-issue に依存関係がない場合。

**暫定実装の注記**: このステップは Gap 5 の仮実装。以下が未検証:
- 再評価の頻度とコストのバランス（毎回実行 vs 条件付き実行）
- 依存グラフの表現形式（Parent Issue 内テキスト vs 構造化データ）
- 再評価自体の mixed タスク分解（グラフ走査のスクリプト化）

### Step 7: クロージング

進捗確認（`deterministic` → スクリプトで実行）:

```bash
bash .claude/skills/research/scripts/closing.sh status <parent-issue-number>
```

全 Sub-Issue 完了後:

1. Parent Issue に全体サマリをコメント（judgmental: LLM）
2. 全体 Gate 判定（GO / NO-GO / CONDITIONAL）（judgmental: 人間）
3. GO → PR 作成、マージ後に Worktree クリーンアップ:
   ```bash
   bash .claude/skills/research/scripts/worktree.sh cleanup <issue-number> <topic-name>
   ```
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

Gate 判定の結果（PASS/CONDITIONAL/FAIL いずれも）は D13（影響波及）を発動しうる:
- FAIL した仮説に依存する sibling sub-issue は影響集合に含まれる
- PASS/CONDITIONAL の結果が後続 sub-issue の前提を変える場合も再評価が必要（Step 6d）
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

### 改善 5: 後続 Sub-Issue の再評価が未定義 → **検証済み (2026-04-10, #362)**

Step 6d として暫定実装。D13 の適用範囲を FAIL のみから全 Gate 結果に拡張。
以下が未検証（次回の /research 実行で検証予定）:
- 再評価の頻度とコストのバランス（毎回実行 vs 条件付き実行）
- 依存グラフの表現形式（Parent Issue 内テキスト vs 構造化データ）
- 再評価自体の mixed タスク分解（グラフ走査のスクリプト化）

### 改善 6: Gap Analysis ↔ Verify のフィードバックループが未定義 → **検証済み (2026-04-10, #362)**

Step 1.5 に減点解消ループ（Step 6b と同パターン）を追加。
以下が未検証:
- ループ回数の上限（最大 2 回）の妥当性
- 「根本的誤り → Step 1 やり直し」の判定基準
- addressable / unaddressable 分類の deterministic 成分のスクリプト化可能性

### 改善 7: Unaddressable 課題の Handoff メカニズムが未定義 → **反映済み (2026-04-10, #359)**

Step 6c の Gate 判定テンプレートに Handoff テーブルとルールを追加。
判定基準: 「この研究の sub-issue で対処可能か」→ Yes なら Parent Issue、No なら別 issue。
#360 の Gate 判定中に発見（G2 照合手順、G4 テーブル維持手順がトラッキングされず消失していた）。

### 改善 8: 調査過程・判断根拠の記録が未定義 → **反映済み (2026-04-10, #359)**

Step 1 を 1a（調査ログ）+ 1b（Gap 列挙）に分割。Step 5 の実験コメントテンプレートに
「アプローチ選択」「先行調査」「判断根拠」フィールドを追加。
#359 の研究過程で発見（Gap Analysis に至る調査過程が issue に残らず、
却下した選択肢の再提案や同じ調査の繰り返しが発生しうる状態だった）。

## Traceability

| 命題 | このスキルとの関係 |
|------|-------------------|
| D3 | Gap Analysis・Judge 評価・Gate 判定により、研究の各段階の状態を可観測にしてから次の意思決定に進む |
