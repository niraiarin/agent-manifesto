---
name: evolve
description: >
  マニフェストに沿って構造を漸進的に改善する。一時的なインスタンスの連鎖を通じて、
  永続する構造（スキル、ルール、テスト、フック、文書）の品質を向上させる。
  P3 の学習ライフサイクル（観察→仮説化→検証→統合→退役）を
  Agent Teams で実行する。このスキル自体も漸進的改善の対象（D9 自己適用）。
  「改善」「evolve」「漸進」「自己改善」「構造改善」「進化」で起動。
---

# /evolve — 構造の漸進的改善スキル

> 一時的なエージェントインスタンスの連鎖を通じて、永続する構造が自身を改善し続ける。
> — manifesto.md §1

## 至上命題

このスキルは manifesto の至上命題そのものを運用化する:

```
構造品質(t+1) > 構造品質(t)
```

ただし改善は**漸進的**（conservative extension 優先）であり、
**統治された**（P3 のライフサイクルに従う）プロセスである。

## 前提知識

### マニフェスト公理系との対応

| マニフェスト概念 | Claude Code 機能 | 本スキルでの使い方 |
|----------------|-----------------|-----------------|
| **T1 一時性** | セッション | 各 evolve 実行は独立。前回の結果は構造（evolve-history.jsonl）から復元 |
| **T2 永続性** | `.claude/`, CLAUDE.md, Memory, git | 改善は構造に書き戻す。エージェントには蓄積しない |
| **T3 有限コンテキスト** | コンテキストウィンドウ | Agent Teams で分散。各エージェントは自分の役割に集中（D11） |
| **T4 確率的出力** | LLM の非決定性 | Verifier エージェントで検証（P2）。同一改善案が毎回異なる可能性 |
| **T5 フィードバック** | hooks (PostToolUse), metrics | Observer が V1-V7 を計測。改善の前後比較が基盤 |
| **T6 人間の最終決定権** | Permission system | 統合は人間の承認後のみ実行。Integrator は提案のみ |
| **T7 リソース有限性** | `globalResourceBound` (Ontology.lean), ccusage | evolve-history.jsonl のコスト記録。1 回の evolve で実装可能な改善数の制約 |
| **T8 精度水準** | `PrecisionLevel` (Ontology.lean), テスト/Lean ビルド | 改善案の品質基準（0 sorry, 0 warning, 140 tests pass が最低品質水準） |
| **P2 検証分離** | Agent tool (verifier subagent) | Worker（Hypothesizer）と Verifier は別コンテキスト |
| **P3 学習の統治** | Memory, git, hooks | 観察→仮説化→検証→統合→退役の全フェーズを実行 |
| **P4 可観測性** | PostToolUse hooks → metrics JSONL | Observer が V1-V7 を計測し改善を定量化 |
| **D1 強制レイヤリング** | hooks > permissions > rules | L1 は hook で強制、改善提案は規範的レイヤー |
| **D4 フェーズ順序** | Agent Teams の実行順序 | 安全→検証→可観測→統治→動的調整 |
| **D9 自己適用** | SelfGoverning パターン | /evolve 自体が改善対象。SKILL.md も変更される |
| **D11 コンテキスト経済** | Agent Teams で分散 | 各エージェントが必要最小限の情報を処理 |

### Lean 形式化との対応

| スキルの概念 | Lean ファイル | 定理/定義 |
|------------|-------------|----------|
| 学習ライフサイクル | Workflow.lean | `LearningPhase`, `validPhaseTransition` |
| 統合ゲート条件 | Workflow.lean | `integrationGateCondition` |
| 退役候補の判定 | Workflow.lean | `retirementCandidate` |
| 検証なしの統合禁止 | Workflow.lean | `integration_requires_verification` |
| フィードバック先行 | Workflow.lean | `feedback_precedes_improvement` |
| 互換性分類の合成 | Evolution.lean | `CompatibilityClass.join`, `breaking_change_dominates` |
| 静止の不健全性 | Evolution.lean | `stasisUnhealthy` |
| T₀ 縮小禁止 | Procedure.lean | `t0_contraction_forbidden` |
| 修正の安全性順序 | Procedure.lean | `modification_safety_chain` |
| D2 検証の 4 条件 | DesignFoundation.lean | `VerificationIndependence` |
| D8 過剰拡大リスク | DesignFoundation.lean | `d8_overexpansion_risk` |

## Progressive Disclosure（D11 コンテキスト経済）

本スキルは Agent Skills Spec に準拠し、3 層の progressive disclosure を使用:

| 層 | 内容 | ロードタイミング |
|----|------|----------------|
| **Metadata** | name + description（~100 tokens） | 常時コンテキスト内 |
| **Instructions** | この SKILL.md 本体 | `/evolve` 起動時 |
| **Resources** | `references/`, `scripts/` | 必要時にオンデマンド |

### バンドルリソース

```
.claude/skills/evolve/
├── SKILL.md                              # 本体（Level 2）
├── scripts/
│   └── observe.sh                        # Observer 計測スクリプト（Level 3）
└── references/
    └── claude-code-features.md           # Claude Code 機能詳細（Level 3）
```

- `scripts/observe.sh` — 構造の現在状態を JSON で出力（Observer が使用）
- `references/claude-code-features.md` — Claude Code 高度機能の詳細リファレンス

## アーキテクチャ: Agent Teams

```
┌─ /evolve ──────────────────────────────────────────────────────┐
│                                                                 │
│  Phase 1: 観察 ─────────────────────────────────────────────── │
│  │ Observer Agent (P4)                                         │
│  │ ├─ /metrics で V1-V7 を計測                                 │
│  │ ├─ Lean ビルド品質指標を取得                                 │
│  │ ├─ git 履歴から停滞・傾向を検出                              │
│  │ ├─ MEMORY 退役候補を検出                                     │
│  │ └─ 観察報告を出力                                            │
│  │                                                              │
│  │ Gate: 改善候補が 1 つ以上存在するか                          │
│  ▼                                                              │
│  Phase 2: 仮説化 ──────────────────────────────────────────── │
│  │ Hypothesizer Agent (P3)                                     │
│  │ ├─ 観察報告から改善案を設計                                   │
│  │ ├─ 各案に互換性分類を付与                                     │
│  │ ├─ 実装手順・テスト計画・リスク評価を含む                     │
│  │ ├─ 優先度順に並べる（D4: 安全→検証→可観測→統治）            │
│  │ └─ 仮説化報告を出力                                          │
│  │                                                              │
│  │ Gate: 実行可能な改善案が 1 つ以上存在するか                  │
│  ▼                                                              │
│  Phase 3: 検証 ────────────────────────────────────────────── │
│  │ Verifier Agent (P2)                                         │
│  │ ├─ 改善案を独立コンテキストで評価                             │
│  │ ├─ Worker のフレーミングに依存しない基準で判断                │
│  │ ├─ リスクレベルに応じた検証手段を選択（D2）                   │
│  │ │   ├─ critical: 人間レビュー必須（自動停止）                │
│  │ │   ├─ high: 人間レビュー推奨（警告表示）                    │
│  │ │   ├─ moderate: Subagent で十分                             │
│  │ │   └─ low: Subagent（手動でも可）                           │
│  │ └─ PASS / FAIL 判定を出力                                    │
│  │                                                              │
│  │ Gate: PASS 判定の改善案が 1 つ以上存在するか                 │
│  ▼                                                              │
│  Phase 4: 統合 ────────────────────────────────────────────── │
│  │ Integrator Agent (P3)                                       │
│  │ ├─ 【人間の承認を取得（T6）】                                │
│  │ ├─ 改善を構造に適用                                          │
│  │ ├─ lake build + test-all.sh で回帰チェック                   │
│  │ ├─ git commit（互換性分類付き）                               │
│  │ ├─ evolve-history.jsonl に実行記録を保存                      │
│  │ └─ 統合報告を出力                                            │
│  │                                                              │
│  │ Gate: 退役候補が存在するか                                   │
│  ▼                                                              │
│  Phase 5: 退役 ────────────────────────────────────────────── │
│    Integrator Agent (P3)                                       │
│    ├─ 陳腐化した MEMORY エントリを退役                           │
│    ├─ breakingChange で無効化された知識を退役                    │
│    └─ 退役報告を出力                                            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 実行手順

### Step 0: 前回の evolve 実行記録の読み込み

```bash
# 前回の実行記録があれば読み込む
cat .claude/metrics/evolve-history.jsonl 2>/dev/null | tail -1
```

前回の結果がある場合、Observer にコンテキストとして渡す。
なければ初回実行として進む。

### Step 1: Observer エージェントの起動

Observer エージェント（`.claude/agents/observer/AGENT.md`）を起動する。

**起動方法:**
```
Agent tool を使用:
  subagent_type: general-purpose (observer AGENT.md を参照)
  prompt: 観察報告を生成せよ（前回の evolve 記録: [あれば添付]）
```

**ゲート判定:** 観察報告に改善候補が 0 件の場合、
「構造は健全。改善候補なし。」と報告して終了。

### Step 2: Hypothesizer エージェントの起動

Hypothesizer エージェント（`.claude/agents/hypothesizer/AGENT.md`）を起動する。
Observer の観察報告を入力として渡す。

**ゲート判定:** 実行可能な改善案が 0 件の場合、
「改善候補は確認されたが、現在の行動空間では実行不可。」と報告して終了。

### Step 3: Verifier エージェントの起動

既存の Verifier エージェント（`.claude/agents/verifier.md`）を使用する。
Hypothesizer の改善案を**独立コンテキスト**で検証する。

**重要（P2 準拠）:**
- Hypothesizer の思考過程を Verifier に渡さない（コンテキスト分離）
- 改善案の内容のみを渡す（フレーミング非依存）
- Verifier は自らの基準で判断する

**P2 の限界（透明性のための注記）:**
この検証は moderate レベル（2/4 条件充足）。同一モデルの Subagent を使用するため
evaluatorIndependent は満たされない。また、Worker（orchestrator）が Verifier への
プロンプトを構成するため、framingIndependent は PARTIAL。
high/critical リスクの改善案は人間レビューが必要（D2）。

**Verifier への入力:**
```
検証対象: [改善案のタイトルと内容]
変更対象ファイル: [ファイルリスト]
互換性分類: [分類]
テスト計画: [テスト計画]
```

**リスク判定と対応（D2）:**
- **critical**: 「人間レビュー必須」を表示し、自動停止
- **high**: 「人間レビュー推奨」を表示し、続行可否を確認
- **moderate/low**: Verifier の PASS/FAIL に従う

**ゲート判定:**

PASS 判定が 1 件以上 → PASS 分を Phase 4 へ進める。

FAIL 判定がある場合 → 以下の **FAIL 分析** を Phase 3 内で実行する:

**FAIL 分析（Phase 3 内サブステップ）:**

FAIL は公理系における反例であり、最も価値の高い学習データである。
「次回に持ち越す」のではなく、同一 evolve 実行内で原因を特定し修正する。

Step 1: 各 FAIL の根本原因を分類する:
- **observation_error**: Observer の計測データが不正確（例: observe.sh のバグ）
- **hypothesis_error**: Hypothesizer がデータを誤引用、または論理的誤り
- **assumption_error**: 前提条件の誤り（互換性分類の誤り、行動空間外等）
- **precondition_error**: 先行フェーズの成果物が不十分

Step 2: ループバック判定:
- observation_error → 計測バグを修正し、Phase 1 に戻って再観察
- hypothesis_error → 正確なデータで Phase 2 に戻って再仮説化
- assumption_error → 前提条件を修正し Phase 2 に戻って再設計
- precondition_error → Phase 1 に戻って先行成果物を補完

Step 3: ループバック制限（T7 リソース有限性）:
- 同一改善案のループバックは最大 2 回まで
- 2 回 FAIL → 失敗パターンとして記録し見送り

PASS が 0 件かつループバック不可 →
「改善案は検証に通過しなかった。理由: [FAIL 分析結果]」と報告して終了。

### Step 4: 人間の承認取得（T6）

統合の前に、人間に以下を提示して承認を求める:

```
=== /evolve 統合承認要求 ===

以下の改善案が検証を通過しました。統合してよいですか？

1. [タイトル]（互換性: conservative extension）
   変更: [概要]
   検証結果: PASS

2. ...

承認: 全て統合 / 選択して統合 / 中止
```

### Step 5: Integrator エージェントの起動

人間が承認した改善案を Integrator に渡す。

Integrator は以下を実行:
1. 改善を構造に適用
2. `lake build Manifest` で Lean ビルド成功を確認
3. `bash tests/test-all.sh` でテスト全通過を確認
4. git commit（互換性分類付き）
5. evolve-history.jsonl に記録

### Step 6: 退役処理

退役には 2 種類の基準がある（混同しないこと）:

**基準 A: Lean 形式化に基づく退役（Workflow.lean `retirementCandidate`）**
- breakingChange により無効化された統合済み知識 → 退役
- 形式的根拠: `ki.status = .integrated ∧ ki.compatibility = .breakingChange`

**基準 B: ポリシーに基づく退役（p3-governed-learning.md）**
- 6ヶ月以上未更新の MEMORY エントリ → 退役候補として確認後に退役
- 根拠: 規範的ルール（構造的強制ではない）

## 品質指標（AxiomQuality.lean と接続）

各 evolve 実行で以下を計測し、改善を定量化する:

| 指標 | 計測方法 | 改善方向 |
|------|---------|---------|
| axiom count | `grep -r "^axiom " --include="*.lean"` | → (不要な増加を避ける) |
| theorem count | `grep -r "^theorem " --include="*.lean"` | ↑ |
| sorry count | `grep -r "sorry" --include="*.lean"` | ↓ (0 を維持) |
| warning count | `lake build 2>&1 \| grep warning` | ↓ (0 を維持) |
| test pass rate | `bash tests/test-all.sh` | ↑ (100% を維持) |
| compression ratio | axiomCount の定義より | ↑ |
| De Bruijn factor | AxiomQuality.lean より | → (4.0 前後が健全) |
| V1-V7 | /metrics スキル | 各 V に応じた改善方向 |

## 終了条件

### 正常終了

以下のいずれかで終了:

1. **改善の統合完了**: 全ての承認済み改善が統合され、テスト全通過
2. **改善候補なし**: Observer が改善候補を検出しなかった
3. **実行不可**: 改善候補はあるが行動空間内で実行不可能
4. **検証失敗**: 全改善案が Verifier で FAIL

### 異常終了

1. **L1 違反検出**: 即座に停止し、人間に報告
2. **Lean ビルド失敗**: ロールバックして報告
3. **テスト失敗**: ロールバックして報告

## 出力フォーマット

```markdown
# /evolve 実行報告

## 実行日時
YYYY-MM-DD HH:MM

## 実行結果: 成功 / 部分成功 / 改善なし / 失敗

## Phase 1: 観察
[Observer の要約]

## Phase 2: 仮説化
[Hypothesizer の要約 — 改善案数、互換性分類の分布]

## Phase 3: 検証
[Verifier の要約 — PASS/FAIL の分布、リスクレベル]
[FAIL 分析: 根本原因分類、ループバック回数、修正結果]

## Phase 4: 統合
[Integrator の要約 — 統合した改善数、コミットハッシュ]

## Phase 5: 退役
[退役した知識の要約]

## V1-V7 変動サマリ
| V | 実行前 | 実行後 | Δ |
|---|--------|--------|---|
| ... | ... | ... | ... |

## Lean 品質変動
| 指標 | 実行前 | 実行後 | Δ |
|------|--------|--------|---|
| axioms | N | N | +0 |
| theorems | N | N | +M |
| sorry | 0 | 0 | 0 |

## 次回への引き継ぎ
[次の evolve 実行で注目すべき観察項目]
```

## D9: このスキル自身のメンテナンス（自己適用）

### /evolve 自体が /evolve の改善対象

Observer が以下のファイルも観察対象に含める:

```
.claude/skills/evolve/SKILL.md          — このスキル
.claude/agents/observer/AGENT.md        — Observer 定義
.claude/agents/hypothesizer/AGENT.md    — Hypothesizer 定義
.claude/agents/integrator/AGENT.md      — Integrator 定義
.claude/agents/verifier.md              — Verifier 定義
.claude/hooks/evolve-*.sh               — evolve 用 hooks
```

### 更新トリガー

- manifesto.md が更新された場合（公理系の変更）
- Lean 形式化（Workflow.lean, Evolution.lean 等）が変更された場合
- 実際の evolve 実行で手順の不備が判明した場合
- Claude Code の新機能がリリースされた場合
- 品質指標が改善の余地を示している場合

### 更新の互換性分類

- **conservative extension**: 説明の追加、例の追加、出力フォーマットの微修正
- **compatible change**: Phase 内の手順微修正、エージェント定義の調整
- **breaking change**: Phase の追加/削除/順序変更、エージェントの追加/削除

**注記（D9 自己適用）:** 本スキルの初回作成は conservative extension だが、
/evolve が自身を改善対象とする場合（D9）、その改善は上記分類に従い
compatible change または breaking change に該当しうる。
各 evolve 実行は改善内容に応じて適切な分類を付与すること。

### 漸近的改善の仮説（Γ \ T₀）

以下は本スキルの設計における反証可能な仮説:

| 仮説 | 反証条件 | 現状評価（9回実行データ） |
|------|----------|----------------------|
| H1: Agent Teams が学習ライフサイクルの自然なモデル化 | Teams の協調オーバーヘッドが改善効果を上回る | 未反証。9回中8回 success（1件は human_feedback）。協調オーバーヘッドの定量評価は phases フィールド蓄積後に可能 |
| H2: 4 エージェント分離が最適粒度 | より少ないエージェントで同等品質が達成される | 未検証。エージェント別寄与の計測データ不足（phases フィールドは run 10 から記録開始） |
| H3: AxiomQuality.lean の指標で改善を計測可能 | Goodhart's Law により指標が改善を捉えない | 部分的に支持。axioms=61 固定、theorems 209→210（run 1→2）。V4 blocked=0 に Goodhart 懸念あり |
| H4: conservative extension 優先が最適戦略 | conservative extension が蓄積し複雑度を増す | 支持傾向。9回で24改善統合、breaking change 0件 |
| H5: 1 セッション 1 evolve 実行が適切な頻度 | より高頻度/低頻度が適切 | 未検証。ccusage daily データ取得済みだが evolve 単体のコスト分離が不可 |

これらの仮説は evolve の実行を通じて検証・更新される。

## Claude Code 機能の活用マップ

本スキルが使用する Claude Code の全機能:

| 機能カテゴリ | 機能 | 使用箇所 |
|------------|------|---------|
| **Skills** | SKILL.md | /evolve 本体 |
| | preload_skills | Observer に /metrics、Hypothesizer に /formal-derivation |
| | skill trigger | 「改善」「evolve」等で起動 |
| **Agents** | AGENT.md | Observer, Hypothesizer, Integrator の定義 |
| | Agent tool (subagent) | 各フェーズのエージェント起動 |
| | verifier subagent_type | P2 検証（Verifier エージェント） |
| | capabilities | エージェント間の能力宣言 |
| | model override | Observer/Integrator は sonnet、Hypothesizer は opus |
| **Hooks** | PreToolUse: Bash | L1 安全チェック、P3 互換性分類チェック |
| | PreToolUse: Edit/Write | L1 ファイルガード |
| | PostToolUse | P4 メトリクス収集（async） |
| | SessionStart | evolve 状態読み込み、ドリフト検出 |
| | UserPromptSubmit | V5 承認追跡 |
| | TaskCompleted | V7 タスク追跡 |
| **Memory** | MEMORY.md | 退役候補の検出・処理 |
| | auto-memory | セッション間の知見の永続化 |
| **Settings** | permissions (deny) | L1 の手続的強制 |
| | permissions (allow) | 行動空間の定義（L4） |
| | env vars | `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` |
| **Git** | git commit | 互換性分類付きの構造変更の永続化 |
| | git log | Observer の停滞検出 |
| | git diff | 変更の追跡 |
| **CLI** | Bash tool | Lean ビルド、テスト実行 |
| | Read/Edit/Write | 構造ファイルの読み書き |
| | Glob/Grep | コードベースの探索 |
| **Metrics** | .claude/metrics/ | V1-V7 データ、evolve 実行履歴 |
| **Skills 連携** | /metrics | Observer が呼び出す |
| | /verify | Verifier フェーズで使用 |
| | /formal-derivation | 構造変更の形式的検証 |
| | /adjust-action-space | 行動空間の調整提案 |
