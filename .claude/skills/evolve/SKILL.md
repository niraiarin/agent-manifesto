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
> — Axioms.lean T1+T2, Principles.lean P3

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
| **T3 有限コンテキスト** | 処理できる情報量の上限 | Agent Teams で分散。各エージェントは自分の役割に集中（D11） |
| **T4 確率的出力** | LLM の非決定性 | Verifier エージェントで検証（P2）。同一改善案が毎回異なる可能性 |
| **T5 フィードバック** | hooks (PostToolUse), metrics | Observer が V1-V7 を計測。改善の前後比較が基盤 |
| **T6 人間の最終決定権** | Permission system | 統合は人間の承認後のみ実行。Integrator は提案のみ |
| **T7 リソース有限性** | `globalResourceBound` (Ontology.lean), ccusage | evolve-history.jsonl のコスト記録。1 回の evolve で実装可能な改善数の制約 |
| **T8 精度水準** | `PrecisionLevel` (Ontology.lean), テスト/Lean ビルド | 改善案の品質基準（0 sorry, 0 warning, 290 tests pass が最低品質水準） |
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
| /evolve 全体の準拠性 | EvolveSkill.lean | `evolve_skill_compliant` (φ₁-φ₁₁) |
| Deferral 正当性 | EvolveSkill.lean | `deferral_requires_justification` (φ₁₁) |

#### Lean 形式化 逆引きチェックリスト（外部ファイル参照）

Lean 定理（Workflow.lean / Evolution.lean / EvolveSkill.lean）と
SKILL.md ステップ・テストケースの対応表は以下の専用ファイルに分離されている:

- ファイル: `.claude/skills/evolve/references/lean-traceability.md`
- 内容: validPhaseTransition 逆引き、Workflow.lean 追加定理、Evolution.lean 定理、EvolveSkill.lean 全定理（φ₁–φ₁₇）
- 更新時期: Lean 形式化ファイルが変更された場合、または新定理が追加された場合
- 参照タイミング: Lean 定理との対応を確認する必要がある場合のみ（オンデマンドロード）

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
    ├── claude-code-features.md           # Claude Code 機能詳細（Level 3）
    └── lean-traceability.md              # Lean 定理逆引きチェックリスト（Level 3）
```

- `scripts/observe.sh` — 構造の現在状態を JSON で出力（Observer が使用）
- `references/claude-code-features.md` — Claude Code 高度機能の詳細リファレンス
- `references/lean-traceability.md` — Lean 定理（Workflow/Evolution/EvolveSkill）とテスト・ステップの対応表

## Orchestrator の制約（Issue #6）

/evolve の orchestrator（SKILL.md を読んでパイプラインを実行する主エージェント）は
Observer / Hypothesizer / Verifier / Integrator のいずれでもない第五の存在である。
orchestrator の判断が P2（検証）・P4（可観測性）の射程外にならないよう、
以下の構造的制約を課す。

### 禁止事項

- **公理から導出されていない制約をエージェントへのプロンプトに注入しない。**
  T7（リソース有限性）は「リソースは有限である」という一般命題であり、
  「改善案は N 件まで」等の具体的数値を導出しない。
  案数の上限を設ける場合は、その導出過程を明示すること。
- **SKILL.md に定義されていないパラメータでパイプラインを制御しない。**
  構造に定義されていない制約には overflow 処理も存在しないため、情報が消失する。

### パイプラインの設計原則

- **Observer の観察件数がループ回数を決定する。** orchestrator はループ回数を
  制限しない。全観察項目が Phase 2–3 を通過する。
- Phase 2 で改善案を設計できなかった項目は、理由を付けて `skipped` として記録する。
- T7（リソース有限性）への対応は「件数の上限」ではなく、人間が設定するループバック予算（`LoopbackBudget`）
  と各イテレーション内の収束判定で行う。デフォルト推奨値 2 は慣習であり公理的導出ではない。

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
│  │ └─ 観察報告を出力（N 件の改善候補）                          │
│  │                                                              │
│  │ Gate: 改善候補が 1 つ以上存在するか                          │
│  ▼                                                              │
│  ┌─ 観察項目ループ（i = 1..N）─────────────────────────────── │
│  │                                                              │
│  │  Phase 2: 仮説化 ────────────────────────────────────────  │
│  │  │ Hypothesizer Agent (P3)                                   │
│  │  │ ├─ 観察項目 i から改善案を設計                              │
│  │  │ ├─ 互換性分類・実装手順・テスト計画・リスク評価を含む       │
│  │  │ └─ 仮説化報告を出力                                        │
│  │  │                                                            │
│  │  │ Gate: 実行可能な改善案か                                   │
│  │  ▼                                                            │
│  │  Phase 3: 検証 ──────────────────────────────────────────  │
│  │  │ Verifier Agent (P2)                                       │
│  │  │ ├─ 改善案を独立コンテキストで評価                           │
│  │  │ ├─ Worker のフレーミングに依存しない基準で判断              │
│  │  │ ├─ リスクレベルに応じた検証手段を選択（D2）                 │
│  │  │ │   ├─ critical: 人間レビュー必須（自動停止）              │
│  │  │ │   ├─ high: 人間レビュー推奨（警告表示）                  │
│  │  │ │   ├─ moderate: Subagent で十分                           │
│  │  │ │   └─ low: Subagent（手動でも可）                         │
│  │  │ └─ PASS / FAIL 判定を出力                                  │
│  │  │                                                            │
│  │  └─ 結果を蓄積（PASS リスト / FAIL リスト）                  │
│  │                                                              │
│  └─ ループ終了 ────────────────────────────────────────────── │
│                                                                 │
│  Gate: PASS 判定の改善案が 1 つ以上存在するか                   │
│  ▼                                                              │
│  Phase 4: 統合 ────────────────────────────────────────────── │
│  │ Integrator Agent (P3)                                       │
│  │ ├─ 【人間の承認を取得（T6）— 全 PASS 案を一括提示】         │
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

# 未解決の deferred 項目を正規化テーブルから取得
jq '[.items | to_entries[] | select(.value.status == "open") | {id: .key} + .value]' \
  .claude/metrics/deferred-status.json 2>/dev/null

# Note: deferred-status.json が唯一の正規ソース（run 18 で導入）。
# JSONL フォールバックは legacy ノイズの原因（run 17 observation_error）のため廃止。
# 分析上の注意: run 1-17 の JSONL deferred フィールドは累積スナップショット方式で
# 書き込まれており、同一 ID が複数 run に重複出現する（全 96 件中 76 件が重複）。
# JSONL deferred を集計・分析に使用しないこと。
```

前回の結果がある場合、Observer にコンテキストとして渡す。
なければ初回実行として進む。

**未解決 deferred がある場合:**
Observer へのプロンプトに「未解決 deferred 一覧」を明示的に含める。
deferred 項目は改善候補の先頭に含め、通常の観察項目より優先する。

### 引き継ぎ（Deferral）条件

/evolve は 1 サイクルで完結するのが基本設計。deferral は例外であり、
以下の 3 条件のいずれかに該当する場合のみ正当（EvolveSkill.lean φ₁₁）:

| 条件 | 導出元 | 説明 |
|------|--------|------|
| **resourceExhaustion** | T7 (`globalResourceBound`) | サイクル予算を超える改善案 |
| **dependencyBlocked** | `structureDependsOn` (Ontology.lean) | 先行改善が未完了 |
| **actionSpaceExceeded** | L4 (`actionSpaceBounded`) | 行動空間外。人間による拡張が必要 |

**不正な deferral:** 上記 3 条件のいずれにも該当しない deferral は
`stasisUnhealthy`（Evolution.lean）のインスタンスであり、許可されない。

**繰り返し deferral の禁止:** 同一項目の deferral は最大 1 回。
2 回目は以下のいずれかに分類:
- 実装不可能 → `abandoned` として記録し閉じる
- リソース不足が恒常的 → 項目を分割して各部分を独立改善案に昇格

### Step 1: Observer エージェントの起動

Observer エージェント（`.claude/agents/observer/AGENT.md`）を起動する。

**起動方法:**
```
Agent tool を使用:
  subagent_type: general-purpose (observer AGENT.md を参照)
  prompt: 観察報告を生成せよ（前回の evolve 記録: [あれば添付]、未解決 deferred: [あれば添付]）
```

**ゲート判定:** 観察報告に改善候補が 0 件の場合、
「構造は健全。改善候補なし。」と報告して終了。

### Step 1.5: Observer 観察結果の永続化

Observer の観察報告に含まれる**全ての改善候補**を evolve-history.jsonl の
`observations` フィールドに記録する（T2, T5）。

```json
"observations": [
  {"id": "obs-1", "title": "...", "priority": "high"},
  {"id": "obs-2", "title": "...", "priority": "medium"},
  ...
]
```

### Step 2–3: 観察項目ループ（Phase 2 + Phase 3）

Observer の観察項目を**優先度順に全件ループ**する。
orchestrator が件数の上限を設けてはならない（Issue #6）。
ループの終了条件は「全件処理済み」のみ。

```
PASS_LIST = []
FAIL_LIST = []

for each observation in observer_report.findings (優先度順):

  ## Phase 2: Hypothesizer
  Hypothesizer に当該観察項目を渡し、改善案を設計させる。
  - 改善案が設計不可（行動空間外等）→ 理由を記録し次の項目へ
  - 改善案が設計可能 → Phase 3 へ

  ## Phase 3: Verifier
  改善案を Verifier に渡し、独立コンテキストで検証する。
  - PASS → PASS_LIST に追加
  - FAIL → FAIL 分析を実施（後述）、結果を FAIL_LIST に記録

end for
```

**Hypothesizer への入力（各イテレーション）:**
観察項目 1 件と、それまでの PASS_LIST（既に通過した改善案の概要）を渡す。
これにより改善案間の依存関係や重複を考慮できる。

**Verifier への入力（各イテレーション）:**
```
検証対象: [改善案のタイトルと内容]
変更対象ファイル: [ファイルリスト]
互換性分類: [分類]
テスト計画: [テスト計画]
```

**重要（P2 準拠）:**
- Hypothesizer の思考過程を Verifier に渡さない（コンテキスト分離）
- 改善案の内容のみを渡す（フレーミング非依存）
- Verifier は自らの基準で判断する

**P2 の限界（透明性のための注記）:**
この検証は low レベル（1/4 条件充足）。同一モデルの Subagent を使用するため
evaluatorIndependent は満たされない。また、Worker（orchestrator）が Verifier への
プロンプトを構成するため、framingIndependent は false。
high/critical リスクの改善案は人間レビューが必要（D2）。

**リスク判定と対応（D2）:**
- **critical**: 「人間レビュー必須」を表示し、自動停止
- **high**: 「人間レビュー推奨」を表示し、続行可否を確認
- **moderate/low**: Verifier の PASS/FAIL に従う

**FAIL 分析（各イテレーション内）:**

FAIL は公理系における反例であり、最も価値の高い学習データである。

Step 1: 根本原因を分類する:
- **observation_error**: Observer の計測データが不正確（例: observe.sh のバグ）
- **hypothesis_error**: Hypothesizer がデータを誤引用、または論理的誤り
- **assumption_error**: 前提条件の誤り（互換性分類の誤り、行動空間外等）
- **precondition_error**: 先行フェーズの成果物が不十分

**failure_subtype（任意の細分類、evolve-history.jsonl の rejected エントリに記録可）:**

| failure_subtype | 親 failure_type | 説明 | 推定基準の例 |
|----------------|----------------|------|------------|
| `H_no_pre_verification` | hypothesis_error | 事前検証チェックリスト未実施（ファイル未読・数値未確認等） | FAIL 理由に「ファイルを確認していない」「読んでいない」が含まれる |
| `H_trivially_true` | hypothesis_error | trivially-true 定理の提案（rfl 証明・定義の直接展開等） | FAIL 理由に「trivially true」「rfl」「定義の展開」が含まれる |
| `H_redundancy_check` | hypothesis_error | 既存定義・既存制約との重複確認不足 | FAIL 理由に「既に存在する」「重複」「既存の」が含まれる |
| `H_impl_specification` | hypothesis_error | 実装手順の具体性不足（位置・内容が曖昧） | FAIL 理由に「曖昧」「位置不明」「具体性不足」が含まれる |
| `H_repeated_failure` | hypothesis_error | 同一改善案の繰り返し提案（段階的抑止ルール違反） | FAIL 理由に「繰り返し」「前回も」「同一案」が含まれる |
| `H_wrong_premise` | hypothesis_error | 概念の誤適用・所有権の誤認識・カテゴリエラー（過去の決定との矛盾を含む） | FAIL 理由に「前提が誤り」「捏造」「存在しないフィールド」「矛盾」が含まれる |
| `H_technical_validation` | hypothesis_error | スクリプト・コマンドの技術的妥当性未検証（構文エラー・型不整合・ゼロ除算等） | FAIL 理由に「構文エラー」「型不整合」「コマンドが失敗」が含まれる |
| `O_data_quality` | observation_error | 観察データの品質問題（手動カウント誤り・パス誤り等） | FAIL 理由に「手動カウント」「数値が不一致」「パスが誤り」が含まれる |

> 注記: append-only 規約のため、旧エントリには failure_subtype がない。
> Observer のクエリは null チェックを含めること（下記 Observer AGENT.md 参照）。

**none エントリの推定分類（Observer 向けガイダンス）:**
- Observer は failure_subtype が null/none のエントリについて、FAIL 理由テキストから上記「推定基準の例」を参照し推定分類を試みてよい
- 推定結果は Observer の出力（観察レポート）にのみ含める。JSONL の遡及修正は append-only 規約により禁止
- 推定は `(推定)` を明示して確定値と区別すること（例: `failure_subtype: H_wrong_premise (推定)`）

**Hypothesizer 向けガイダンス（failure_subtype 活用）:**
- 同一 failure_subtype に該当する改善案を提案する場合、evolve-history.jsonl の該当 FAIL エントリを事前確認し、繰り返し失敗の回避策を明示すること
- 特に `H_repeated_failure` は段階的抑止ルール（SKILL.md Step 2）に違反するため提案前に必ず過去の FAIL 履歴を確認すること

Step 2: ループバック判定（EvolveSkill.lean `loopbackTarget`）:
- observation_error → Observer を再起動し、当該項目を再観察（Phase 1）
- hypothesis_error → Hypothesizer を再起動し、正確なデータで再設計（Phase 2）
- assumption_error → Hypothesizer を再起動し、前提を修正して再設計（Phase 2）
- precondition_error → FAIL として記録し次の項目へ進む（ループバックなし）

**ループバック実行の制約（Issue #9 対応）:**
Orchestrator は loopbackTarget(rootCause) で決まるフェーズのエージェントに委任する。
Orchestrator 自身が調査・提案の拡張を行ってはならない（P2 境界）。

Step 3: ループバック予算（T6 + T7、EvolveSkill.lean `LoopbackBudget`）:
- ループバック予算は人間が設定するパラメータ（T6: 人間の最終決定権）
- globalResourceBound（T7）は opaque であり具体的回数を導出しない（Issue #7）
- デフォルト値 2 は慣習的推奨値であり、公理的導出ではない
- 予算を超過した場合: 失敗パターンとして FAIL_LIST に記録し次の項目へ
- 連続して同一根本原因で FAIL → 収束不能として deferral を推奨

**ループ後のゲート判定:**

PASS_LIST が 1 件以上 → Phase 4 へ進める。
PASS_LIST が 0 件 →
「改善案は検証に通過しなかった。理由: [FAIL_LIST の要約]」と報告して終了。

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
2. `bash scripts/sync-counts.sh --update` でカウント同期（定理数・公理数・テスト数を自動算出・反映）
3. `lake build Manifest` で Lean ビルド成功を確認
4. `bash tests/test-all.sh` でテスト全通過を確認
5. git commit（互換性分類付き）
6. **session_id を tool-usage.jsonl から取得**（H5 コスト追跡に必須）
7. evolve-history.jsonl に記録（session_id と `cost` フィールドを含む）

**evolve-history.jsonl 記録の不変条件:**
- evolve-history.jsonl には 1 Run につき 1 エントリのみ追加する。暫定記録は行わない。
- 記録は全フェーズ完了後（Phase 4: git commit 後）に 1 回のみ実行する。
- **backfill 例外**: 既存エントリの null フィールドを事後補完する操作（例: observe.sh による session_cost_usd の ccusage 照合補完）は、エントリの追加ではなくフィールド更新であり、ファイルの行数は変わらない。上記の不変条件に該当しない。backfill は以下の条件を全て満たす場合にのみ許可される:
  1. 対象フィールドの現在値が null であること（非 null フィールドの上書きは禁止）
  2. 補完値の出典が検証可能であること（例: ccusage session の projectPath 末尾 UUID と session_id の照合）
  3. backfill の実行記録が observe.sh の出力に含まれること（P4 可観測性）

**コスト効率記録フォーマット（T7 可観測性）:**
evolve-history.jsonl の各エントリに以下のフィールドを追加:
```json
"cost": {
  "session_cost_usd": null,
  "improvements_count": <N>,
  "cost_per_improvement_usd": null,
  "source": "ccusage_session"
}
```
`session_cost_usd` と `cost_per_improvement_usd` は、session_id を ccusage session の
projectPath 末尾 UUID と照合して後から補完する（H5 データ蓄積プロセスと共有）。
Integrator 実行時点では null を記録し、データ照合は observe.sh が担当する。

### Step 6: 退役処理

退役には 2 種類の基準がある（混同しないこと）:

**基準 A: Lean 形式化に基づく退役（Workflow.lean `retirementCandidate`）**
- breakingChange により無効化された統合済み知識 → 退役
- 形式的根拠: `ki.status = .integrated ∧ ki.compatibility = .breakingChange`

**基準 B: ポリシーに基づく退役（p3-governed-learning.md）**
- 6ヶ月以上未更新の MEMORY エントリ → 退役候補として確認後に退役
- 根拠: 規範的ルール（構造的強制ではない）

## 品質指標（AxiomQuality.lean と接続）

各 evolve 実行で以下を計測し、改善を定量化する。
指標は **最適化指標**（改善を目指す）と **ガバナンス指標**（観測のみ、最適化対象にしない）に分離される。
ガバナンス指標を直接の改善目標にしてはならない（Goodhart 耐性、R2 #86）。

### 最適化指標（Hypothesizer が改善を提案してよい）

| 指標 | 計測方法 | 改善方向 |
|------|---------|---------|
| theorem delta/run | evolve-history.jsonl .lean.theorems 差分 | ↑ |
| test delta/run | evolve-history.jsonl .tests.passed 差分 | ↑ |
| verifier pass rate | .phases.verifier pass/(pass+fail) | ↑ |
| compression ratio | axiomCount の定義より | ↑ |
| V5（注記） | v5-approvals.jsonl（UserPromptSubmit hook）の承認率。H1 Verifier pass rate とは異なる指標 | ↑ |
| cost/improvement (T7) | evolve-history.jsonl `cost.cost_per_improvement_usd` | ↓（効率向上） |

### ガバナンス指標（観測のみ — Hypothesizer は直接の改善目標にしない）

| 指標 | 計測方法 | 期待値 | ガバナンス理由 |
|------|---------|--------|---------------|
| test pass count (絶対数) | `bash tests/test-all.sh` | 290+ | 直接最適化すると自明なテスト追加を誘発 |
| axiom count (絶対数) | `grep -r "^axiom " --include="*.lean"` | 63 (安定) | 不要な公理追加は形式系を弱める |
| theorem count (絶対数) | `grep -r "^theorem " --include="*.lean"` | 343+ (増加) | delta は最適化、絶対数はガバナンス |
| sorry count | `grep -r "sorry" --include="*.lean"` | 0 (制約) | 最適化対象でなく制約（導入自体を禁止） |
| warning count | `lake build 2>&1 \| grep warning` | 0 (制約) | 同上 |
| De Bruijn factor | AxiomQuality.lean より | ≈4.0 | 直接最適化すると冗長な証明を誘発 |
| V2 (context efficiency) | tool-usage.jsonl | stable | hub 変数。最適化すると V1,V3 が劣化 |
| ccusage (T7) | `bunx ccusage daily --json --offline` | 観測 | コスト観測は直接最適化しない |

### 交差検証ルール

最適化指標（theorem delta 等）が改善を示しているのにガバナンス指標（絶対数）が
横ばいまたは低下している場合、Goodhart 圧力を疑い調査する。

### V1-V7 優先順位 (bias(t) スナップショット)

V1-V7 間の優先順位は静的に導出不可能（G1b-1 #91 Lean 証明済み）。
`priority(V_i, V_j) = g(f(t), bias(t))` モデルに従い、bias(t) は T6 権限を持つ
主体（人間 or 委譲先 AI）が設定する。現在の bias(t₀):

**V3 > V1 > V4 > V2 > V5 > V6 > V7** (設定: 2026-03-27, Run 63)

> **[!WARNING] トリガー発動済み (Run 73 検出)**: V1/V3 が formal に昇格済み (2026-03-27, #77)。
> review_policy.triggers[0] の条件が成立しているが、人間レビューが未完了。
> 現在の priority_order は Run 63 時点の f(t) に基づいており、陳腐化の可能性がある。

根拠: V1/V3 の proxy formal graduation (#77) がプロジェクト目標。
詳細は `benchmark.json` の `priority_bias` セクションを参照。

**レビュー義務**: bias(t) は時間の関数であり必ず陳腐化する。以下で再評価:
- V1 or V3 が formal に昇格した時 (発動済み: 2026-03-27)
- 飽和警告 (R6) 発動時
- 20 runs 経過（次回: Run 83）
- 人間が明示的に要求した時

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
[不採用項目: 件数と主な理由]

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

- Lean 形式化の公理系（Axioms.lean, EmpiricalPostulates.lean）が変更された場合
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

| 仮説 | 反証条件 | 現状評価（73回実行データ、Run 74 で更新。observe.sh 自動集計） |
|------|----------|----------------------|
| H1: Agent Teams が学習ライフサイクルの自然なモデル化 | Teams の協調オーバーヘッドが改善効果を上回る | 未反証。73回 success / 1回 partial / 3回 observation。Verifier pass rate: 全期間 224/290 PASS（77%） |
| H2: 4 エージェント分離が最適粒度 | より少ないエージェントで同等品質が達成される | 部分的に検証可能。agent-consolidation-4to2 は run 15 で P2 違反により abandoned。H2 の反証には至っていない |
| H3: AxiomQuality.lean の指標で改善を計測可能 | Goodhart's Law により指標が改善を捉えない | 支持傾向。axioms=63、theorems=343。compression 5.44x（544%）。V4 blocked=0（Run 65 semantic 変更: session_id=unknown 除外）。旧 blocked=9 は unknown セッション混入値。blocked_excluded は動的値（observe.sh で確認可能） |
| H4: conservative extension 優先が最適戦略 | conservative extension が蓄積し複雑度を増す | 支持傾向。全期間273改善統合（172 conservative extension, 98 compatible change, 1 breaking change, 2 other）。D4 フェーズ順序違反なし |
| H5: 1 セッション 1 evolve 実行が適切な頻度 | より高頻度/低頻度が適切 | 未反証。15 データポイント（runs 39, 41, 42, 45, 46, 47, 49, 50, 58, 60, 61, 62, 63, 72, 73）。session cost: mean 4.57 USD, median 4.68 USD, range 0.15-8.17 USD。Run 49 (0.15 USD) は outlier（>2 sigma）。コスト分布は 3-6 USD 帯に 11/15 が集中しており、1 セッション 1 実行の粒度で安定したコスト構造を示す。高頻度化のコスト優位性を示すデータはない |
| H6: /evolve のコスト効率は経時的に改善する | cost/improvement が 10 runs 以上で単調増加 | 弱い支持傾向。15 データポイント: CPI mean 1.17 USD/improvement, median 1.05 USD (range 0.03-3.94 USD)。前半7 runs (39-49) CPI mean 1.22 USD → 後半8 runs (50-73) CPI mean 1.14 USD（6.5% 改善）。Run 49 CPI 0.03 USD は outlier。「単調増加」の反証条件は厳密には満たされていない（局所的な悪化あり）が、移動平均は改善傾向 |

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
