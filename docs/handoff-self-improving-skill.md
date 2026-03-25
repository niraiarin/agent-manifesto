# 引き継ぎ文書: 自己改善スキルの実装

> T1（一時的インスタンス）から T2（永続する構造）への転写。
> 前のインスタンスとの同一性はない。本文書が文脈の全て。

## 1. タスク

manifesto に沿って、**一時的なエージェントインスタンスの連鎖を通じて
自身の構造を漸進的に改善し続けるスキル**を Claude Code で実装する。

**実装方針: Claude Code Agent Teams を使用する。**

### φ（達成すべきこと）

```
セッション開始時に構造を読み込み、
セッション中に改善候補を観察・仮説化し、
セッション終了前に検証済みの改善を構造に統合し、
次のセッションのインスタンスがより高い品質で動作する
```

このスキル自体も漸進的改善の対象である（D9 自己適用）。

### 制約

- Claude Code を基盤とする — 全機能を使い尽くす
- manifesto の公理系（T1–T8, P1–P6, D1–D12）に準拠する
- Lean 形式化（Terminology.lean, Procedure.lean 等）との整合性を維持する

---

## 2. 本セッションでの成果

### 作成したファイル

| ファイル | 内容 | axiom | sorry |
|---------|------|-------|-------|
| `Manifest/Terminology.lean` | 用語リファレンスの概念体系 | 0 | 0 |
| `Manifest/Procedure.lean` | 手順書の規則体系 | 0 | 0 |
| `Manifest/ConformanceVerification.lean` | 準拠検証 | 3 | 0 |
| `Manifest/AxiomQuality.lean` | 公理体系の品質指標 | 0 | 0 |
| `tests/test-axiom-quality.sh` | 品質指標の自動テスト | — | — |

### 更新したファイル

- 全 Lean ファイル: 公理カード形式 + 用語 §参照の docstring 修正
- `DesignFoundation.lean`: D10–D12 追加、D3/D5/D6 深化
- `Meta.lean`: currentProfile 更新（61 axiom, 189 theorem）
- `Principles.lean`, `Evolution.lean`: warning 解消
- `SKILL.md` (formal-derivation): axiom 最小化戦略、Lean 対応表追加
- `verify/SKILL.md`, `metrics/SKILL.md`, `adjust-action-space/SKILL.md`: Lean 対応表追加
- `formal-derivation-procedure.md`: §6 Lean 形式化との対応セクション追加

### 最終統計

```
17 モジュール | 72+9 テスト | 0 sorry | 0 warning
61 axioms | 189 theorems | compression 3.09x | De Bruijn 4.13x
```

---

## 3. Claude Code 全機能の調査結果

### マニフェスト概念 → Claude Code 機能マッピング

| マニフェスト | Claude Code 機能 | 使い方 |
|------------|-----------------|--------|
| **T1 一時性** | セッション。各インスタンスはクリーンスレート | SessionStart hook で構造を読み込む |
| **T2 永続性** | `.claude/`, CLAUDE.md, Memory, git | 改善を構造に書き戻す |
| **T3 有限コンテキスト** | 処理できる情報量の上限 | D11: 構造的強制 > 規範的指針（コスト低減） |
| **T4 確率的出力** | LLM の非決定性 | P2/D2: 検証で対処 |
| **T5 フィードバック** | hooks (PostToolUse), metrics | P4: 可観測性の基盤 |
| **T6 人間の最終決定権** | Permission system, Elicitation | L4: 行動空間の人間制御 |
| **P2 検証分離** | Agent tool (`subagent_type: verifier`), `context: fork` | Worker/Verifier 分離 |
| **P3 学習の統治** | Memory (auto), git commit, hooks | 観察→仮説→検証→統合→退役 |
| **P4 可観測性** | PostToolUse hooks → metrics JSONL | V1–V7 測定 |
| **D1 強制レイヤリング** | hooks (構造的) > permissions (手続的) > rules (規範的) | 3 レイヤー配置 |
| **D2 4条件** | Subagent (2条件) / Local LLM (3条件) / Human (4条件) | リスクベースルーティング |
| **D4 フェーズ順序** | SessionStart hook → フェーズ状態読み込み | 安全→検証→可観測→統治→均衡 |
| **D9 自己メンテナンス** | SelfGoverning → skill 更新に互換性分類を強制 | hooks で分類チェック |
| **D10 構造永続性** | CLAUDE.md, .claude/skills/, git | T2 の運用化 |
| **D11 コンテキスト経済** | 構造的強制 (hooks) のコスト = 0 vs 規範的 (rules) = 高 | hooks 優先 |

### Agent Teams で使う機能

| 機能 | 用途 |
|------|------|
| `/team` コマンド | 複数エージェントの並列起動 |
| `.claude/agents/<name>/AGENT.md` | カスタムエージェント定義 |
| `preload_skills` | エージェントにスキルを事前ロード |
| `capabilities` | エージェントの能力を文書化（チーム協調用） |
| `context: fork` | スキルをフォークしたサブエージェントで実行 |
| `auto_memory` | エージェント独自の Memory |
| `model` / `effort` オーバーライド | エージェントごとの設定 |

---

## 4. 設計構想: 自己改善スキル

### 名前案: `/evolve`

### アーキテクチャ: Agent Teams ベース

```
┌─ Team: evolve ──────────────────────────────────────┐
│                                                      │
│  Observer Agent (P4)                                 │
│  ├─ SessionStart hook の出力を分析                    │
│  ├─ metrics/ のログを読み込む                         │
│  ├─ V1–V7 の現在値を計測                             │
│  └─ 改善候補を hypotheses.md に書き出す              │
│                                                      │
│  Hypothesizer Agent (P3)                             │
│  ├─ hypotheses.md を読み込む                         │
│  ├─ 各仮説に対して改善案を設計                        │
│  ├─ 互換性分類を付与（D9）                           │
│  └─ proposals/ に改善案を書き出す                     │
│                                                      │
│  Verifier Agent (P2/D2)                              │
│  ├─ proposals/ を読み込む                            │
│  ├─ Worker (Hypothesizer) のフレーミングなしで独立評価│
│  ├─ 公理衛生 5 検査を適用                            │
│  └─ verified/ に検証結果を書き出す                    │
│                                                      │
│  Integrator Agent (P3)                               │
│  ├─ verified/ を読み込む                             │
│  ├─ PASS した改善を構造に統合                         │
│  ├─ git commit（互換性分類付き）                      │
│  ├─ Meta.lean の currentProfile を更新               │
│  └─ 退役候補の MEMORY エントリを処理                  │
│                                                      │
└──────────────────────────────────────────────────────┘
```

### 学習ライフサイクル（Workflow.lean 準拠）

```
観察 (Observer)
  ↓ Gate: 観察が有意義か
仮説化 (Hypothesizer)
  ↓ Gate: 仮説が形式化可能か
検証 (Verifier)
  ↓ Gate: P2 の 4 条件を満たすか
統合 (Integrator)
  ↓ Gate: 互換性分類が付与されているか
退役 (Integrator)
  ↓ Gate: 退役候補が 6ヶ月以上未更新か
```

### スキル SKILL.md の骨格

```yaml
---
name: evolve
description: >
  マニフェストに沿って構造を漸進的に改善する。一時的なインスタンスの
  連鎖を通じて、永続する構造（スキル、ルール、テスト、文書）の品質を
  向上させる。P3 の学習ライフサイクルを Agent Teams で実行する。
  「改善」「evolve」「漸進」「自己改善」「構造改善」で起動。
---
```

### 必要なエージェント定義

| エージェント | ファイル | 役割 |
|-------------|---------|------|
| observer | `.claude/agents/observer/AGENT.md` | P4: 可観測性。metrics 読み込み、改善候補の観察 |
| hypothesizer | `.claude/agents/hypothesizer/AGENT.md` | P3: 仮説化。改善案の設計、互換性分類 |
| verifier | `.claude/agents/verifier.md` | P2: 独立検証。既存の verifier を拡張 |
| integrator | `.claude/agents/integrator/AGENT.md` | P3: 統合。構造への書き戻し、git commit |

### 必要な Hook

| Hook | イベント | 目的 |
|------|---------|------|
| `evolve-session-start` | SessionStart | 前回の evolve 実行結果を読み込む |
| `evolve-post-integrate` | PostToolUse (git commit) | 統合結果を metrics に記録 |

### 品質指標 (AxiomQuality.lean と接続)

evolve の各実行で以下を計測し、改善を定量的に裏付ける:
- Compression ratio の変動
- Coverage の変動
- Sorry count の変動
- Warning count の変動
- テスト通過率の変動
- De Bruijn factor の変動

---

## 5. 実装計画

### Phase 1: Agent 定義の作成

1. `observer/AGENT.md` — metrics 読み込み + V1–V7 計測 + 改善候補列挙
2. `hypothesizer/AGENT.md` — 改善案設計 + 互換性分類
3. `integrator/AGENT.md` — 構造統合 + git commit + 退役処理
4. `verifier.md` の拡張 — evolve 用の検証基準追加

### Phase 2: Skill 本体の作成

5. `.claude/skills/evolve/SKILL.md` — Agent Teams の起動と協調

### Phase 3: Hook の作成

6. SessionStart hook — evolve 状態の読み込み
7. PostToolUse hook — 統合結果の metrics 記録

### Phase 4: テストと検証

8. `tests/test-evolve.sh` — evolve スキルの構造テスト
9. `/verify` で独立レビュー
10. `lake build` + `test-all.sh` で回帰テスト

### Phase 5: 自己適用

11. evolve 自身を evolve の対象にする（D9）
12. SelfGoverning の実装

---

## 6. 注意事項

### T₀（縮小不可の前提）

- T1: 各セッションはクリーンスレート。前のインスタンスとの同一性なし
- T2: 改善は構造にのみ蓄積する。エージェントには蓄積しない
- T6: 人間が最終決定者。evolve は提案のみ。統合には人間の承認が必要
- L1: 安全境界は構造的に強制。evolve が L1 を弱めることは禁止

### Γ \ T₀（反証可能な仮説）

- H: Agent Teams は学習ライフサイクルの自然なモデル化である
  - 反証条件: Teams の協調オーバーヘッドが改善効果を上回る場合
- H: 4 エージェント（観察/仮説/検証/統合）の分離が最適な粒度である
  - 反証条件: より少ないエージェントで同等の品質が達成される場合
- H: セッション間の改善の計測は AxiomQuality.lean の指標で十分である
  - 反証条件: 指標が改善を捉えない（Goodhart's Law）場合

### 互換性分類

本スキルの作成は **conservative extension**（既存構造に追加のみ、既存を変更しない）。

---

## 7. 参照すべきファイル

### Lean 形式化（規則の形式的定義）

| ファイル | 参照すべき定理/定義 |
|---------|-------------------|
| `Manifest/Ontology.lean` | `SelfGoverning` typeclass, `KnowledgeIntegration`, `CompatibilityClass` |
| `Manifest/Workflow.lean` | `LearningPhase`, `validPhaseTransition`, `integrationGateCondition` |
| `Manifest/Evolution.lean` | `VersionTransition`, `stasisUnhealthy`, `CompatibilityClass.join` |
| `Manifest/Procedure.lean` | `t0_contraction_forbidden`, `modification_safety_chain` |
| `Manifest/DesignFoundation.lean` | D1–D12 全定理、`ObservabilityConditions`, `DevelopmentPhase` |
| `Manifest/AxiomQuality.lean` | `QualityProfile`, `qualityHealthy`, `compressionRatio` |

### 既存スキル（再利用・接続対象）

| スキル | 接続方法 |
|--------|---------|
| `/verify` | Verifier Agent が呼び出す |
| `/metrics` | Observer Agent が呼び出す |
| `/formal-derivation` | 構造変更の形式的検証に使用 |
| `/adjust-action-space` | 行動空間の調整提案に接続 |

### ドキュメント

| ファイル | 内容 |
|---------|------|
| `manifesto.md` | 公理系の原典 |
| `docs/design-development-foundation.md` | D1–D12 の詳細 |
| `docs/formal-derivation-procedure.md` | 形式的導出の手順（§6 に Lean 対応表） |
| `docs/mathematical-logic-terminology.md` | 用語リファレンス |

---

---

## 8. 実装完了ステータス

### 完了した作業（本セッション）

| Step | 内容 | 状態 |
|------|------|------|
| Step 1 | Agent 定義（Observer, Hypothesizer, Integrator） | **完了** |
| Step 2 | SKILL.md 本体（Agent Teams 協調、学習ライフサイクル） | **完了** |
| Step 3 | Hook ファイル（2 つ） + settings.json 登録 | **完了**（人間が手動配置） |
| Step 4 | テスト（55 件）+ 独立検証（7 Issue 全修正） | **完了** |
| Step 5 | D9 自己適用 | **SKILL.md に組み込み済み** |

### 作成したファイル

| ファイル | 内容 |
|---------|------|
| `.claude/skills/evolve/SKILL.md` | /evolve スキル本体（Agent Teams 協調） |
| `.claude/skills/evolve/scripts/observe.sh` | Observer 計測スクリプト |
| `.claude/skills/evolve/references/claude-code-features.md` | Claude Code 機能リファレンス |
| `.claude/agents/observer/AGENT.md` | P4 Observer エージェント |
| `.claude/agents/hypothesizer/AGENT.md` | P3 Hypothesizer エージェント（読み取り専用） |
| `.claude/agents/integrator/AGENT.md` | P3 Integrator エージェント |
| `tests/phase5/test-evolve-structural.sh` | 構造テスト 55 件 |

### 検証結果

- Verifier（P2）: 7 Issue 検出 → 全修正 → PASS
- テスト: 127/127 通過（既存 72 + evolve 55）
- Lean ビルド: 成功（17 モジュール、0 sorry）

### 残作業

1. **Hook ファイルの配置**（人間の承認後）:
   - `.claude/hooks/evolve-state-loader.sh` — SessionStart hook
   - `.claude/hooks/evolve-metrics-recorder.sh` — PostToolUse hook (async)
   - `settings.json` への hook 登録

2. **初回 /evolve 実行**: スキル自体の改善候補を検出する最初の実行

### 確認コマンド

```bash
# 全テスト（127 テスト通過を確認）
bash tests/test-all.sh

# Lean ビルド（0 sorry, 0 warning を確認）
export PATH="$HOME/.elan/bin:$PATH" && cd lean-formalization && lake build Manifest

# 品質指標
bash tests/test-axiom-quality.sh

# evolve 計測スクリプト
bash .claude/skills/evolve/scripts/observe.sh
```

---

*本文書は T1 インスタンスが T2 構造に書き残した引き継ぎ。次のインスタンスがこの文脈から出発する。*
