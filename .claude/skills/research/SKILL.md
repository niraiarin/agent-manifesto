---
name: research
user-invocable: true
description: >
  Gate-Driven Research Workflow を実行する。P3（学習の統治）の運用インスタンス。
  実装前の技術的リサーチを構造化された手順で進める。
  Gap Analysis → Parent Issue → Sub-Issues (with Gates) → Worktree 隔離実験 → Gate 判定。
  「やるべきか？」「可能か？」「調査して」など実装前の判断が必要な場合に使う。
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
    - skill: formal-derivation
      type: soft
      phase: "Step 6"
      condition: "Lean 形式化が必要な場合"
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
  (loop until                    │                ↓
   addressable=0)                │    Step 3.1: 事前分解判定 (C2, C3)
                                 │    Step 3.2: 深度チェック (max_depth=4)
                                 │    Step 3.3: Context 判定 (Q1-Q4)
                                 │                ↓
                                 │    Sub-Issue Verify (P2)
                                 │     (loop until addressable=0)
                                 │                ↓
                                 │        Git Worktree (isolated)
                                 │                ↓
                                 │        Experiment → Checkpoint (C4/C5/C6)
                                 │                ↓
                                 │        Gate Judgment
                                 │       ╱      │       ╲
                                 │    PASS  CONDITIONAL  FAIL
                                 │      │        │         │
                                 │      │    子 issue 起票  │
                                 │      │    (tree 深化)    │
                                 │      └────────┴─────────┘
                                 │               ↓
                                 │     Step 6c.1: 上方集約 (1段ずつ)
                                 │     Step 6d: 後続再評価 (sibling)
                                 │     Step 6d.1: Cross-level 再評価
                                 │               ↓
                                 └──── Next Sub-Issue / Step 7
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
| Step 1b: Gap 列挙 + 順位付け | **judgmental + deterministic（分離済み）** | LLM（列挙） + verifier_local.py tournament（順位付け） | 列挙は judgmental。順位付けは logprob tournament（#600） |
| Step 1.5: Gap 検証ループ | **bounded + deterministic（分離済み）** | Verifier agent（検証） + カウント判定スクリプト（残存数） | `mixed_task_decomposition` 適用済み ✓: bounded = Verifier 委譲、deterministic = addressable 残存数判定 |
| Step 2: Parent Issue 作成 | **deterministic + judgmental（未分離）** | テンプレートスクリプト + LLM（内容記述） | deterministic: テンプレート構造生成 / judgmental: 背景・Gap 一覧の記述 |
| Step 3: Sub-Issue 作成 | **deterministic + judgmental（未分離）** | テンプレートスクリプト + LLM（内容記述） | deterministic: テンプレート構造生成 / judgmental: Gate 基準の設計 |
| Step 3.1: 事前分解判定 | **judgmental** | LLM（C2/C3 チェックリスト） | ドメイン干渉・精度不整合の判定は意味論的 |
| Step 3.2: 深度チェック | **deterministic** | depth カウント + T6 承認 | depth は Observable（Issue tree 走査） |
| Step 3.3: Context 判定 | **deterministic + judgmental（未分離）** | Q1-Q4 フロー | Q1/Q4 は deterministic、Q2/Q3 は judgmental |
| Step 3.5: Sub-Issue 検証ループ | **bounded + deterministic（分離済み）** | Verifier agent（検証） + カウント判定スクリプト（残存数） | `mixed_task_decomposition` 適用済み ✓: bounded = Verifier 委譲、deterministic = addressable 残存数判定 |
| Step 4: Worktree 作成 | **deterministic** | スクリプト（worktree.sh） | スクリプト化済み ✓ |
| Step 5: 実験実施 | **judgmental** | LLM | 研究の本質。自動化不可 |
| Step 5 Checkpoint | **deterministic + judgmental（未分離）** | C4 は deterministic（compaction 検知）/ C5 は judgmental / C6 は deterministic（カウント比較） | 実験完了ごとに実行 |
| Step 5.5: 仮定抽出 | **judgmental + deterministic（未分離）** | LLM（識別・分類） + チェックスクリプト（5.5c） | judgmental: 外部事実の識別と C/H 分類 / deterministic: 5.5c チェックリスト |
| Step 6a: 品質評価 | **deterministic + bounded（分離済み）** | verifier_local.py (logprob) / Judge agent (フォールバック) | Verifier モード: スクリプト実行（deterministic）。Judge モード: agent 委譲（bounded）。#600 |
| Step 6b: 減点解消 | **judgmental + deterministic（未分離）** | LLM（修正） + カウント判定スクリプト | judgmental: 修正内容の判断 / deterministic: addressable 残存数判定 |
| Step 6c: Gate 判定 + Handoff | **judgmental + deterministic（未分離）** | 人間（T6） + Handoff 判定（deterministic） | judgmental: 最終判定は人間（T6） / deterministic: Handoff 先判定は Yes/No |
| Step 6c.1: 上方集約 | **deterministic + judgmental（分離済み）** | `propagate.sh update-parent`（テーブル更新・全子状態確認） + LLM（親 Gate 判定要否） | `mixed_task_decomposition` 適用済み ✓ (#596): deterministic = propagate.sh、judgmental = 親 Gate 判定 |
| Step 6d: 後続再評価 | **deterministic + judgmental（分離済み）** | `propagate.sh successor-list` + `check-premises`（走査・突合） + LLM（影響判定） | `mixed_task_decomposition` 適用済み ✓ (#596): deterministic = propagate.sh、judgmental = 前提変化判定 |
| Step 6d.1: Cross-level 再評価 | **deterministic + judgmental（分離済み）** | `propagate.sh successor-list`（親 Issue 特定） + LLM（前提変化判定） | `mixed_task_decomposition` 適用済み ✓ (#596): deterministic = propagate.sh、judgmental = 前提変化判定 |
| Step 7: クロージング | **deterministic + judgmental（未分離）** | クロージングスクリプト + LLM（サマリ） | deterministic: issue close / judgmental: 全体サマリ記述 |
| Step 7a: ドキュメント更新 | **deterministic + judgmental（未分離）** | チェックリスト + LLM（更新内容） | deterministic: チェックリスト / judgmental: 更新箇所の判断 |
| Step 7b: 研究レポート | **judgmental** | LLM（6 項目レポート） | 研究の構造化伝達。項目 5,6 が 7c の入力 |
| Step 7c: 後続 Issue 起票 | **deterministic + judgmental（未分離）** | LLM（課題識別）+ gh issue create | deterministic: issue 作成 / judgmental: 起票要否の判断 |
| Step 7d: PR 作成 | **deterministic** | gh pr create | 7a-7c 完了が前提条件 |
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
| Step 1b | judgmental + deterministic（分離済み） | `mixed_task_decomposition`, `deterministic_must_be_structural` | 列挙は judgmental（意味論的）。順位付けは logprob tournament（#600） |
| Step 1.5 | bounded + deterministic（分離済み） | `mixed_task_decomposition`, `observable_implies_automatable` | bounded: Verifier 委譲 / deterministic: 残存数は Observable |
| Step 2 | deterministic + judgmental（未分離） | `mixed_task_decomposition` | テンプレート構造は deterministic、内容記述は judgmental |
| Step 3 | deterministic + judgmental（未分離） | `mixed_task_decomposition` | テンプレート構造は deterministic、Gate 基準設計は judgmental |
| Step 3.1 | judgmental | `classification_is_judgmental` | ドメイン干渉・精度不整合の判定は意味論的（Rice の定理）|
| Step 3.2 | deterministic | `observable_implies_automatable` | depth は Observable（Issue tree 走査で決定可能）|
| Step 3.3 | deterministic + judgmental（未分離） | `mixed_task_decomposition` | Q1/Q4 は deterministic（binary 判定）、Q2/Q3 は judgmental |
| Step 3.5 | bounded + deterministic（分離済み） | `mixed_task_decomposition`, `observable_implies_automatable` | bounded: Verifier 委譲 / deterministic: 残存数は Observable |
| Step 4 | deterministic | `deterministic_must_be_structural`, `observable_implies_automatable` | worktree 作成の成功条件は Observable（ディレクトリ存在） |
| Step 5 | judgmental | `classification_is_judgmental` | 研究の本質。決定手続き不在 |
| Step 5 Checkpoint | deterministic + judgmental（未分離） | `mixed_task_decomposition` | C4 は deterministic（compaction 検知）、C5 は judgmental、C6 は deterministic |
| Step 5.5 | judgmental + deterministic（未分離） | `mixed_task_decomposition` | 識別・分類は judgmental、チェックリストは deterministic |
| Step 6a | deterministic + bounded（分離済み） | `mixed_task_decomposition`, `deterministic_must_be_structural` | Verifier モード: verifier_local.py（deterministic）/ Judge モード: agent（bounded）。#600 |
| Step 6b | judgmental + deterministic（未分離） | `mixed_task_decomposition` | 修正内容は judgmental、残存数判定は deterministic |
| Step 6c | judgmental + deterministic（未分離） | `mixed_task_decomposition` | 最終判定は judgmental（T6）、Handoff 先判定は deterministic |
| Step 6c.1 | deterministic + judgmental（分離済み） | `mixed_task_decomposition`, `observable_implies_automatable` | deterministic: `propagate.sh update-parent` (#596) / judgmental: 親 Gate 判定 |
| Step 6d | deterministic + judgmental（分離済み） | `mixed_task_decomposition`, `observable_implies_automatable` | deterministic: `propagate.sh successor-list` + `check-premises` (#596) / judgmental: 前提変化判定 |
| Step 6d.1 | deterministic + judgmental（分離済み） | `mixed_task_decomposition`, `observable_implies_automatable` | deterministic: `propagate.sh successor-list` (#596) / judgmental: 前提変化判定 |
| Step 7 | deterministic + judgmental（未分離） | `mixed_task_decomposition` | issue close は deterministic、サマリは judgmental |
| Step 7a | deterministic + judgmental（未分離） | `mixed_task_decomposition` | チェックリストは deterministic、更新箇所判断は judgmental |
| Step 7b | judgmental | `classification_is_judgmental` | 研究の構造化伝達。6 項目レポート |
| Step 7c | deterministic + judgmental（未分離） | `mixed_task_decomposition` | gh issue create は deterministic、起票要否は judgmental |
| Step 7d | deterministic | `deterministic_must_be_structural` | 7a-7c 完了が前提。gh pr create |
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

#### Gap 優先順位の客観化（Pairwise Tournament, #600）

Gap が 2 件以上ある場合、logprob pairwise tournament で優先順位を客観化する。
主観的リスク評価（high/medium/low）を D1-D3 基準で順位付けし、Sub-Issue 作成順序を決定。

```bash
# Verifier モードが利用可能な場合
HEALTH=$(python3 scripts/verifier_local.py ensure 2>/dev/null)
AVAILABLE=$(echo "$HEALTH" | jq -r '.available')

if [ "$AVAILABLE" = "true" ] && [ "$GAP_COUNT" -ge 2 ]; then
  echo "{
    \"problem\": \"Prioritizing research gaps for #NNN.\",
    \"proposals\": [
      {\"id\": \"gap-1\", \"description\": \"Gap 1 の現状・必要・リスク・未知の要約\"},
      {\"id\": \"gap-2\", \"description\": \"Gap 2 の同上\"},
      ...
    ],
    \"criteria\": [
      {\"id\": \"downstream_dependency\", \"name\": \"Downstream Dependency\", \"description\": \"Does closing this gap unblock other gaps? Prerequisite gaps score HIGH. Isolated gaps score LOW.\"},
      {\"id\": \"risk_severity\", \"name\": \"Risk Severity\", \"description\": \"What is worst case if gap remains? Gaps affecting safety (L1) or principles (P) score HIGH. Design-only (D) gaps score LOW.\"},
      {\"id\": \"experiment_ease\", \"name\": \"Experiment Ease\", \"description\": \"How quickly can this be verified? Minimal setup scores HIGH (fail-fast). Complex infrastructure scores LOW.\"}
    ]
  }" | python3 scripts/verifier_local.py tournament
fi
```

**tournament 結果の使い方:**
- `ranking` の順序で Sub-Issue を作成・着手する（fail-fast 原則との整合: experiment_ease が高い Gap が優先される）
- 主観的リスク評価と乖離した場合、tournament 順位を優先
- Verifier モード利用不可の場合、従来の「リスクで降順ソート」をフォールバックとして使用

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

## Tree Context
- **Parent**: #N
- **Root**: #N (最上位の Parent Issue)
- **Depth**: [現在の depth]
- **Children**: (none) / #X, #Y
- **Context**: independent / shared with #N

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
  ├─ CONDITIONAL: [基準] → sub-issue 起票（再帰的に tree を深化）
  └─ FAIL: [基準] → [アクション]
```

作成後、Parent Issue の Sub-Issues テーブルを更新する。

### Step 3.1: 事前分解判定（#577 対応, #582/#583 で校正済み）

各 Sub-Issue について C2, C3 をチェックする。

#### C2: domain_interference チェック（#582 操作的定義）

「干渉ドメイン」= 以下 3 条件のうち **2 つ以上が異なる**知識単位:

| 条件 | 判定方法 | 例 |
|------|---------|-----|
| (a) ツールチェイン | deterministic: 使用ツール・言語が異なるか | Lean 4 vs Python, gh API vs lake build |
| (b) 推論フレーム | judgmental: 推論パターンが異なるか | 形式証明(演繹) vs 実験分析(帰納) vs 設計判断(abduction) |
| (c) 語彙空間 | judgmental: 専門用語集合が重複しないか | axiom/theorem/sorry vs hook/rule/skill |

判定手順（Step 3.1 実行者が実施）:
1. [ ] この Sub-Issue の実験に必要な**ツールチェイン**を列挙する
2. [ ] この Sub-Issue の結論に至る**推論パターン**（演繹/帰納/abduction）を特定する
3. [ ] この Sub-Issue で使用する**専門用語の主要な集合**を特定する

判定:
- 1 条件のみ異なる → 同一ドメインの亜種（分解不要）
- 2 条件以上異なり、結論が**独立** → **分解する**（各ドメインを別 Sub-Issue に）
- 2 条件以上異なり、結論が**依存** → **分解せず**、ただし I1-I4 を事中監視:
  - I1: Verifier の cross-domain 指摘（1 件以上で警告）
  - I2: Judge スコアの基準間 range ≥ 2.0
  - I3: Verifier round ≥ 3 で cross-domain 指摘が交互出現
  - I4: 実験前半 30% 以内で context compaction 発動

#### C3: precision_heterogeneity チェック（#583 T8 精度スケール）

T8 精度スケール（P1-P4）:

| レベル | 名称 | T8 range | 定義 | 検証手段 |
|--------|------|----------|------|----------|
| P4 | Formal | 900-1000 | 機械検証が必要 | `lake build` 0 sorry |
| P3 | Deterministic | 600-899 | スクリプトで PASS/FAIL 判定可能 | テストスクリプト |
| P2 | Structured | 300-599 | テンプレート・基準に沿った構造化判断 | Judge + checklist |
| P1 | Exploratory | 1-299 | 方向性の探索 | 比較表 + 推奨根拠 |

分類ルール: 「この Sub-Issue の Gate PASS を最終的に確認する手段は何か？」で判定。

C3 発動基準:
- [ ] 1 段階差（例: P4+P3）: 許容 — 検証手段が近接
- [ ] **2 段階差**（例: P4+P2, P3+P1）: **C3 発動** → 分割を推奨
- [ ] **3 段階差**（例: P4+P1）: **強制分割**

いずれかに該当する場合、Sub-Issue をさらに分割する。
分割後の各 Sub-Issue にも再帰的に C2, C3 を適用する。

**C2/C3 は judgmental 条件**（`classification_is_judgmental`）。
校正データ: C2 は #276, #549/#551 で検証済み。C3 は #226 で検証済み (N=6)。
N=15-20 到達後に段階差閾値を再校正する。

### Step 3.2: 深度チェック（#577 対応）

現在の issue tree の depth を確認:
- **depth 1-3**: 通常の分解判定に従う
- **depth 4**: 人間の承認を取得してから Sub-Issue を作成（T6）。「なぜ depth 4 が必要か」を Issue コメントに記録
- **depth 5+**: 原則禁止。研究の再設計を検討（別の Parent Issue に分割、スコープ再定義）

**根拠**: `d15d_computation_saturation`（飽和点の存在証明）。飽和点の位置は計算不能なため、depth 4 で T6 を発動し人間に判断を委ねる。max_depth は実運用データの蓄積後に調整（D8 均衡探索）。

### Step 3.3: Context 判定（#577 対応）

各 Sub-Issue について context モードを判定:

1. **P2 検証（Judge/Verifier）を含む** → **独立 context**（必須）
2. **前の Sub-Issue の結果を入力として使い、同一ドメイン** → **同一 context 推奨**
3. **前の Sub-Issue の結果を入力として使うが、異なるドメイン** → **独立 context 推奨**
4. **他の Sub-Issue と並列実行可能** → **独立 context 推奨**
5. **それ以外** → **同一 context 推奨**（overhead 回避）

判定結果を Sub-Issue body の Tree Context セクションに記載。

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
**推論チェイン**: [dependent hop の列挙。例: "Gap特定→仮説設計→実験実行→結果解釈 (depth=4)"]
**各ホップの confidence**: [例: "hop1:H, hop2:H, hop3:M, hop4:L"]
**結果**: ...
**考察**: ...
**判断根拠**: [なぜこの結論に至ったか。定量データまたは比較の要約]
**次のアクション**: ...
```

#### Step 5 Checkpoint（#577 対応, #584 で校正済み）

各実験の完了時（Issue コメント記録時）に以下をチェック:
- [ ] C4: context compaction が発動していないか？（発動 ≈ context 飽和のシグナル）
- [ ] C5: dependent reasoning hops > 3 かつ後半 hop の confidence が低下していないか？
      （depth 記録: 推論チェイン欄に hop 列挙。confidence 記録: 各 hop に H/M/L を付与）
      （校正データ蓄積中。n=20 到達後に閾値レビュー。2026-06 目標）
- [ ] C6: Verifier 指摘数が前回の実験より増加していないか？（初回は N/A）

いずれかに該当する場合:
1. 現在の実験結果を Issue コメントに中間記録する
2. 残りの実験を Sub-Issue として起票する
3. Step 6 の Gate 判定に進む（CONDITIONAL が想定される）

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

### Step 6: 品質評価 + Gate 判定 (#600 Verifier パラダイム対応)

Gate 判定の前に、品質評価を実施する。Verifier モード（logprob + pairwise）と
Judge モード（離散スコア）の二重構造（`.claude/agents/judge.md` 参照）。

#### 6a. 品質評価の実施

**モード選択（orchestrator が実行）:**
```bash
# ensure: 未起動なら自動起動。モデル未配置の場合のみ false
HEALTH=$(python3 scripts/verifier_local.py ensure 2>/dev/null)
AVAILABLE=$(echo "$HEALTH" | jq -r '.available')
# available=true → Verifier モード（デフォルト）、false → Judge モード
```

**Verifier モード（推奨: ローカル LLM 稼働時）:**
実験結果を baseline（「実験なし・変更なし」）と pairwise 比較。
```bash
echo '{
  "problem": "Evaluating research experiment results for Gate judgment.",
  "proposal_a": "<実験結果の要約>",
  "proposal_b": "No experiment conducted. No data available.",
  "criteria": [<G1-G5 の JSON 定義 — judge.md 参照>],
  "k_rounds": 3
}' | python3 scripts/verifier_local.py pairwise
```
winner="A" → 実験結果が baseline を上回る → Gate 評価へ進む。

**Judge モード（フォールバック: ローカル LLM 未稼働時）:**
Judge agent に以下を渡す:
- 実験結果のコメント
- Sub-Issue で定義した Gate PASS/FAIL 基準
- 成果物のファイルリスト

**省略条件（パターン確立後の軽量 Gate）**:
同一 Parent Issue 内で以下の条件を **全て** 満たす場合、評価を Verifier PASS のみに簡略化できる:
1. 先行 Sub-Issue で同一スコープの評価が 2 件以上完了している（パターン確立）
2. 先行評価で G1-G5 が全て 4.00/5.00 以上（Judge モード）または全基準 winner="A"（Verifier モード）
3. 現在の Sub-Issue の成果物が先行と同一形式（例: 全て SKILL.md へのテーブル追加）
4. Verifier が addressable 指摘 0 件で PASS

省略した場合、Issue コメントに「Verifier PASS + パターン確立済み（#NNN, #NNN で確認）」と
先行評価の参照を明記すること。事後の Judge 追記は任意だが、全体評価で指摘された場合は追記する。
（#377 Phase 3-4 で Judge スキップし全体評価で G3 減点 → 事後追記で解消した経験から導出）

G1-G5 評価基準（観測可能な事実に基づく, #600）:

| # | 基準 | 問い | 観測可能な検証方法 |
|---|------|------|-------------------|
| G1 | 問い応答 | Sub-Issue の問いに答えているか？ | issue コメントに問いのキーワードに対応するセクションが存在する |
| G2 | 再現性 | 結果を再現できるか？ | issue コメントにコマンド + 出力データが含まれる（コードブロック存在） |
| G3 | 判断根拠 | PASS/FAIL の根拠が定量的か？ | issue コメントに数値（%、件数、スコア等）が含まれる |
| G4 | 次アクション | 次のステップが明確か？ | PASS/FAIL/CONDITIONAL + 次アクション記述が存在する |
| G5 | 仮定接続 | 外部事実に仮定 ID が付いているか？ | Derivation Card に CC-H/CC-A 等の仮定 ID が参照されている（grep 可能）(#336) |

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
| G1 問い応答 | X.XX/5.00 | ... |
| G2 再現性 | X.XX/5.00 | ... |
| G3 判断根拠 | X.XX/5.00 | ... |
| G4 次アクション | X.XX/5.00 | ... |
| G5 仮定接続 | X.XX/5.00 | ... |

**総合スコア**: X.XX/5.00（診断値。判定基準は減点分類）

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

### /verify 検証詳細 (#459)

| ラウンド | 指摘数 | addressable | 修正内容 |
|---------|--------|------------|---------|
| 1 | N | M | [要約] |
| 2 | N | M | [要約] |

<details>
<summary>主要な指摘（最大 5 件）</summary>

| # | 指摘 | 分類 | 対処 |
|---|------|------|------|
| 1 | [Verifier の指摘内容] | addressable / informational | [修正内容 or 記録] |
| ... | ... | ... | ... |

</details>

### Unaddressable 課題の Handoff

| 課題 | 行き先 (issue #必須) | 理由 |
|------|---------------------|------|
| ... | #XX (Parent) / #XX (新規起票) | ... |
```

#### Unaddressable 課題の Handoff ルール

Gate 判定で unaddressable と分類された課題は**必ず行き先を決定し、issue 番号を記録する**。
放置は禁止（トラッキングされない課題は消失する）。

行き先の判定基準:
- **Parent Issue に追記**: 同一リサーチの後続 sub-issue で対処可能な場合 → Parent `#XX` を記載
- **別 issue を起票**: スコープ外（別スキル、別ワークフロー）で対処が必要な場合 → `gh issue create` で起票し `#XX` を記載

**「行き先」列には必ず issue 番号（`#XX`）を記載すること。**
「実装 PR」「将来対応」「スコープ外」等の文言のみは禁止。
issue を起票してから番号を記載する（#526 で「実装 PR で対処」と書いたが issue 未起票で課題が消失した）。

判定は deterministic（「この研究の sub-issue で対処可能か」の Yes/No）。
Yes → Parent、No → 別 issue。

スコアは診断ツール。判定基準は「対処可能な減点が残っているか」。
最終判定は人間が行う（T6）。Judge 結果は参考材料。

| 判定 | 意味 | アクション |
|------|------|----------|
| PASS | addressable 減点なし | Issue close。Parent 更新。Step 6c.1 → 6d へ |
| CONDITIONAL | 追加研究が必要 | 子 issue 起票（再帰的に tree を深化）。Step 6c.1 → 6d へ |
| FAIL | 前提が崩れた | Parent にエスカレーション。Step 6c.1 → 6d へ |

CONDITIONAL の子 issue は tree の次の depth に追加される。
各子 issue も同じ /research ワークフロー（Step 1-7）を再帰的に実行する。
深度は Step 3.2 の depth guard で制御される。

#### 6c.1. 上方集約（#577 対応, #596 スクリプト化）

Gate 判定後、親ノードへの結果伝播を実行する（`deterministic` → スクリプトで実行）:

```bash
# 親 Issue の Sub-Issues テーブルを自動更新
bash .claude/skills/research/scripts/propagate.sh update-parent <parent-issue> <child-issue> <PASS|CONDITIONAL|FAIL>
```

1. 自ノードの Gate 結果を**親 Issue にコメント**として記録（judgmental: LLM）
2. 親 Issue の **Sub-Issues テーブルを更新**（deterministic: `propagate.sh update-parent`）
3. 同一親の全子ノードが最終状態に達したか確認（deterministic: `propagate.sh update-parent` が自動表示）:
   - **全最終** → 親の Gate 判定を実行
   - **未最終** → 親は保留（残りの子ノードを待つ）

伝播ルール:
- **全子 PASS**: 親の対応 Gap を解決済みにマーク
- **一部 CONDITIONAL**: 子の CONDITIONAL が **1 件以上**あれば親は待機
- **一部 FAIL**: D13 発動。親の前提が崩れた可能性を評価
- **混合**: 個別に処理（PASS 部分は解決、CONDITIONAL は待機、FAIL は D13）

**重要**: 上方伝播は **1 段ずつ**（子→親のみ）。孫→祖父は直接伝播しない。
各親ノードが自分の Gate 判定で統合することで全体の一貫性を保つ。

#### 6d. 後続 Sub-Issue の再評価（#362 検証済み, #577 拡張, #596 スクリプト化）

Gate 判定の結果（PASS/CONDITIONAL/FAIL いずれも）は、後続 sub-issue の前提を
変える可能性がある。D13（影響波及）を FAIL 以外にも適用する。

**実行手順**（deterministic 成分はスクリプトで実行）:

```bash
# 推奨: cascade-next を繰り返し呼ぶ。1回1件、状態ファイルで進捗追跡
bash .claude/skills/research/scripts/propagate.sh cascade-next <parent-issue> <completed-issue>
# → 1件目を表示。LLM が判定後、同じコマンドを再実行
bash .claude/skills/research/scripts/propagate.sh cascade-next <parent-issue> <completed-issue>
# → 2件目を表示（前件の修正が反映済み）。STATUS: DONE まで繰り返す
```

`cascade-next` の設計:
- **ステートフル**: `.cascade-state/<parent>-<completed>.done` で処理済み Issue を追跡
- **1回1件**: 呼び出すたびに次の未処理 Issue をトポロジカル順に1件だけ表示
- **カスケード保証**: 各 Issue の前提は都度 `gh issue view` で最新を取得するため、
  前ステップで `gh issue edit` した修正が自動反映される
- **LLM は判定のみ**: 順序制御・進捗追跡は構造的に強制（`deterministic_must_be_structural`）

LLM が判定（judgmental）:
- 影響なし → 同じコマンドを再実行
- アプローチ変更が必要 → `gh issue edit` で修正後、同じコマンドを再実行
- 不要になった → `gh issue close` 後、同じコマンドを再実行
- 新規 Gap 発見 → 新しい sub-issue を起票後、同じコマンドを再実行

**省略条件**: `cascade-next` の結果が「後続 Issue: なし」の場合。

**検証済み (#577)**: 以下の 3 項目が検証された:
- **頻度**: 毎回実行が適切。再評価コストは低い（各 Issue の前提と Gate 結果の比較のみ）
- **依存グラフ形式**: Parent Issue テーブル + 各 Issue body の Tree Context セクション（(a)+(d) hybrid）
- **mixed タスク分解**: deterministic（`propagate.sh` で走査・突合）+ judgmental（前提変化判定は LLM）。#596 で分離完了

#### 6d.1. Cross-level 再評価（#577 対応）

depth > 2 のノードの Gate 結果について:
1. 1 段上の**親ノードの前提が変化したか**評価
2. 変化した場合、親 Issue にコメントで通知し、親の Sub-Issues テーブルを更新
3. 親の sibling への影響評価は、**親の Gate 判定時**に親の Step 6d で処理に委ねる

### Step 7: クロージング

進捗確認（`deterministic` → スクリプトで実行）:

```bash
bash .claude/skills/research/scripts/closing.sh status <parent-issue-number>
```

全 Sub-Issue 完了後:

1. Parent Issue に全体サマリをコメント（judgmental: LLM）
2. 全体 Gate 判定（GO / NO-GO / CONDITIONAL）（judgmental: 人間）
3. GO → Step 7a → 7b → 7c → 7d → PR 作成 → マージ → Worktree クリーンアップ
4. NO-GO → 代替案を文書化して close

#### Step 7a: ドキュメント更新（PR 前必須）

PR 作成前に、研究成果が影響する既存ドキュメントを更新する。
**PR にドキュメント更新が含まれていない場合、PR 作成をブロックする。**

チェックリスト:
- [ ] SKILL.md: 研究で改善されたスキルの記載を更新
- [ ] MEMORY: 次セッションに必要な知識を永続化（MEMORY.md + 個別ファイル）
- [ ] convergence/config: 閾値・パラメータの変更があれば関連スクリプトとドキュメントを同期
- [ ] テスト: 変更された振る舞いに対するテストの追加・更新（既存テストの PASS 確認）
- [ ] instance-manifest.json: 新規成果物のメタデータ作成（該当する場合）

「ドキュメント更新なし」が正当な場合（純粋な調査研究でコード変更なし）は、
PR body に理由を明記すること。

#### Step 7b: 研究レポート作成（PR 前必須）

以下の 6 項目フォーマットで研究レポートを作成し、PR body に含める。
各項目 500 文字以内、階層箇条書き。

```markdown
## 研究レポート

### 1. どんなもの？
[研究の概要と成果物]

### 2. 先行研究と比べてどこがすごい？
[既存手法・既存成果物との差分]

### 3. 技術や手法の肝はどこ？
[核心的な技術的貢献]

### 4. どうやって有効だと検証した？
[検証方法と結果の定量データ]

### 5. 議論はある？
[限界、未解決問題、前提条件]

### 6. 次に読むべき論文は？
[関連研究、発展的な調査対象]
```

**理由**: 研究成果が PR レビュアーと次のインスタンスに構造化された形で伝達される。
項目 5（議論）と項目 6（次の研究）が Step 7d の入力になる。

#### Step 7c: 後続 Issue 起票（PR 前必須）

研究レポートの項目 5（議論）と項目 6（次の研究）から、
解決すべき課題や発展性のある調査研究を Issue として起票する。

判定基準:
- **議論で挙げた未解決問題** → 対処可能なら Issue 起票
- **検証中に発見した欠陥・改善候補** → 既知の改善候補セクションに追記 + Issue 起票
- **次の研究で挙げた発展的テーマ** → 実行可能かつ価値があるなら Issue 起票

各 Issue に含めること:
- 発見元の研究（Parent Issue #N）への参照
- 発見の経緯（どの Step で、何がきっかけで）
- 予想される影響範囲

**起票が不要な場合**（全ての未解決問題が既存 Issue でカバー済み）は、
PR body に「後続 Issue: なし（理由: ...）」と明記すること。

#### Step 7d: PR 作成

Step 7a-7c の完了を確認してから PR を作成する。

**Worktree → PR の手順** (#544):

1. worktree の変更を main repo の feature branch にコピー:
   ```bash
   bash .claude/skills/research/scripts/worktree.sh pr <issue-number> <topic-name> <pr-branch-name>
   ```
2. カウント同期（hook がブロックするため必須）:
   ```bash
   SYNC_SKIP_TESTS=1 bash scripts/sync-counts.sh --update
   ```
3. ビルド確認:
   ```bash
   cd lean-formalization && lake build Manifest
   ```
4. 全テスト実行（**PR 前必須。未実行の Test Plan 項目を含む PR は禁止**）:
   ```bash
   bash tests/test-all.sh
   ```
   全 PASS を確認してからコミットする。failure がある場合は原因を特定し修正する。
5. コミット + push + PR 作成
6. PR マージ後に Worktree クリーンアップ:
   ```bash
   bash .claude/skills/research/scripts/worktree.sh cleanup <issue-number> <topic-name>
   ```

**注意**: Worktree 内で直接コミット・push すると、hooks が main repo のブランチを参照して
誤検知する（#543）。必ず `worktree.sh pr` で main repo にコピーしてからコミットすること。

PR body テンプレート:
```markdown
## Summary
[1-3 bullet points]

## 研究レポート
[Step 7b のレポート全文]

## ドキュメント更新
[Step 7a のチェックリスト結果]

## 後続 Issue
[Step 7c で起票した Issue のリスト、または「なし（理由）」]

## Test plan
[実行結果を記載（未実行禁止）]
```

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
| レポートなしで PR 作成 | 研究成果が構造化されず伝達不能 | Step 7b の 6 項目レポートを PR body に含める |
| ドキュメント更新なしで PR 作成 | 次のインスタンスが陳腐化した情報で作業する | Step 7a のチェックリストを完了してから PR |
| 未解決問題を PR に埋没させる | issue 化されない課題は消失する | Step 7c で後続 Issue を起票 |
| depth guard なしの再帰的分解 | ノード数が指数的に増加し Gate/Judge 固定費が爆発 | Step 3.2 で depth check。depth 4 は T6 承認制 |
| 上方集約なしの深い tree | 子の Gate 結果が親に伝播せず、全体の一貫性が崩壊 | Step 6c.1 で 1 段ずつ上方伝播 |

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

### 改善 5: 後続 Sub-Issue の再評価が未定義 → **検証済み + 拡張 (2026-04-16, #577)**

Step 6d として暫定実装 (#362)。#577 で 3 未検証項目が全て検証され、正式実装に昇格:
- **頻度**: 毎回実行（コスト低）
- **依存グラフ形式**: (a)+(d) hybrid（Parent テーブル + Tree Context）
- **mixed タスク分解**: deterministic（走査）+ judgmental（判定）

#577 で追加: Step 6d.1（cross-level 再評価）により depth > 2 のノードの上方伝播にも対応。

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

### 改善 9: 再帰的 tree 構造と停止基準が未定義 → **完了 (2026-04-16, #577 + #582-584)**

#577 で設計、#582-584 で C2/C3/C5 を校正。以下が SKILL.md に統合済み:
- **分解判定関数 v1.0**: 全 6 条件 (C1-C6) の操作的定義完了
  - C1 executor_failure: Gate CONDITIONAL 出力 (deterministic)
  - C2 domain_interference (#582): 3 条件 + 2/3 閾値 + I1-I4 指標 (judgmental)
  - C3 precision_heterogeneity (#583): P1-P4 精度スケール + 段階差判定 (judgmental)
  - C4 context_saturation: context utilization 60% (deterministic)
  - C5 multi_hop_depth (#584): adaptive guard (dependent hops>3 + confidence degradation)
  - C6 error_accumulation: Verifier/Judge スコア推移 (deterministic)
- **Interim depth guard**: max_depth=4, soft limit（depth 4 は T6 承認制）
- **Tree 管理**: (a)+(d) hybrid + Tree Context セクション
- **上方集約プロトコル**: Step 6c.1（4 ケース定義、1 段ずつ伝播）
- **Context 判定**: Q1-Q4 フロー（Step 3.3）
- **事中分解監視**: Step 5 Checkpoint（C4/C5/C6）+ 推論チェインデータ収集
- **統一フロー**: Step 3.1-3.3 + Step 5 Checkpoint + Step 6c.1/6d.1

以下は運用データ蓄積後に校正:
- C2 判定者間一致率の測定（I1-I4 ログ蓄積後）
- C3 段階差閾値の再校正（N=15-20 到達後）
- C5 閾値レビュー（n=20 到達後。2026-06 目標）
- Context 判定 (Q1-Q4) の追加検証（#225 等での照合率 ≥ 75%）
- C4 の 60% 閾値の推論劣化適用性（実運用データ蓄積後に校正）
- Overhead 計測基盤（handoff JSONL に token count フィールド追加提案）

## Traceability

| 命題 | このスキルとの関係 |
|------|-------------------|
| D3 | Gap Analysis・Judge 評価・Gate 判定により、研究の各段階の状態を可観測にしてから次の意思決定に進む |
