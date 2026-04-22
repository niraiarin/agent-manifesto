# LLM Task Taxonomy for Routing — Agent-Manifesto

Issue: #647 (Sub-2, #639)
Date: 2026-04-23

## 1. 先行研究サーベイ

### 1.1 RouteLLM (ICLR 2025, arXiv:2406.18665)

Strong/weak 二値ルーティング。Chatbot Arena preference data で MF / BERT classifier / causal LM の 3 方式を学習。2x+ コスト削減。
**我々への示唆**: 2 モデル routing の基盤。Phase 1 で既に採用。タスク taxonomy は扱っていない。

### 1.2 BELLA: Skill Profiles (arXiv:2602.02386, Feb 2026)

critic モデルで LLM 出力を**スキル単位に分解**し、capability matrix にクラスタリング。多目的最適化でモデル選択。金融ドメインで実証。
**我々への示唆**: skill profile の軸（reasoning, domain knowledge, format compliance 等）を taxonomy の分類軸に採用すべき。

### 1.3 TRouter: Task-Aware Routing (arXiv:2604.09377, Apr 2026)

階層的 task taxonomy（domain → subcategory → difficulty）を構築し、cold-start 環境でも routing を可能に。
**我々への示唆**: 我々の agent-manifesto も cold-start（55 件しか domain data がない）。TRouter の taxonomy 構築手法を参考にする。

### 1.4 SkillRouter (arXiv:2603.22455, Mar 2026)

LLM agent の skill routing を 80K skill scale で評価。**skill body（全文）が routing の決定的信号**、name/description では 29-44pp 低下。1.2B retrieve-and-rerank で 74% Hit@1。
**我々への示唆**: `.claude/skills/*/SKILL.md` の本文が routing 判断の入力になるべき。

### 1.5 実務ベンチマーク (ianlpaterson.com, 2026)

15 LLM × 38 実タスクで routing table を構築。「routing beats model selection」が実証。
**我々への示唆**: タスク固有の経験的 routing table が最も実用的。

### 1.6 Local LLM Coding Agent 状況 (tomron.net, Feb 2026)

Qwen3-Coder-Next 58.7% SWE-bench (24GB GPU)。hybrid routing がデフォルト戦略化。
**我々への示唆**: coding task は local で十分な水準に到達。routing の価値は non-coding タスクで大きい。

## 2. 内部サーベイ: 全 LLM タスク列挙

`.claude/skills/`, `.claude/agents/`, `.claude/hooks/`, `scripts/`, Claude Code built-in から網羅的に列挙。

### 2.1 Agent 定義 (6 agents)

| Agent | タスク | 入力 | 出力 | ツール使用 |
|-------|------|------|------|----------|
| **Verifier** | コード/設計の独立検証 (P2) | diff, 設計文書 | PASS/FAIL + findings | Read, Glob, Grep |
| **Judge** | GQM 品質評価 | proposals, criteria JSON | scores (discrete/logprob) | Read, Glob, Grep |
| **Observer** | V1-V7 + 改善候補列挙 | プロジェクト状態 | observation report | Read, Glob, Grep, Bash, Skill |
| **Hypothesizer** | 改善仮説設計 | observer report | change_specs + compatibility class | Read, Glob, Grep, Bash, Agent |
| **Integrator** | 検証済み改善の統合 | verifier PASS | git commits, PR | Read, Glob, Grep, Bash, Edit, Write |
| **Model-Questioner** | ビジョン聞き取り → 公理系生成 | 自然言語対話 | Lean code, JSON metadata | Read, Glob, Grep, Bash |

### 2.2 Skills (16 skills)

| Skill | 主要 LLM タスク | 呼び出す agent/script |
|-------|---------------|---------------------|
| /verify | リスク判定 + 独立検証 | Verifier agent, verifier_local.py |
| /evolve | 4-phase Agent Team pipeline | Observer → Hypothesizer → Verifier → Integrator |
| /research | Gate-driven 研究ワークフロー | Judge agent, verifier_local.py |
| /formal-derivation | Lean 証明構成 | Verifier agent |
| /paperize | 5-agent 論文生成 pipeline | Outline/Plotting/LitReview/Writing/Refinement |
| /trace | トレーサビリティ解釈 | (deterministic + judgmental 混合) |
| /metrics | V1-V7 計算 | (主に deterministic) |
| /handoff | セッション引き継ぎ | (judgmental: 状態統合) |
| /instantiate-model | 公理系インスタンス化 | Model-Questioner agent |
| /generate-plugin | D17 state machine plugin 生成 | /research, /instantiate-model |
| /ground-axiom | 公理の数学的根拠検証 | (judgmental: 文献調査) |
| /adjust-action-space | 行動空間調整 | (judgmental: V4/V5 分析) |
| /design-implementation-plan | 設計計画書生成 | (judgmental) |
| /spec-driven-workflow | 仕様駆動開発 | /research, /formal-derivation, /verify |
| /brownfield | 既存プロジェクト公理系構築 | Model-Questioner |
| /paperize | 論文化 | 5-agent pipeline |

### 2.3 Claude Code Built-in タスク (7 types)

| タスク | 説明 | 頻度 |
|-------|------|------|
| **コード生成** | ユーザー指示からコード作成 | 最高 |
| **ツール選択** | どのツール (Bash/Read/Edit/...) を呼ぶか判断 | 最高 |
| **会話・Q&A** | 質問応答、説明、議論 | 高 |
| **要約・圧縮** | /compact、context 管理 | 中 |
| **計画** | /plan モード、タスク分解 | 中 |
| **スキーマ推論** | JSON/YAML 構造生成 | 低 |
| **ループ制御** | /loop 自己スケジューリング | 低 |

### 2.4 Hook 経由 LLM タスク (3 types)

| Hook | LLM 関与 | 種別 |
|------|---------|------|
| p2-verify-on-commit | P2 トークン検証 | deterministic (jsonl check) |
| hallucination-check | ファイルパス整合性検証 | deterministic |
| p4-drift-detector | evolve 状態ロード | deterministic (context injection) |

### 2.5 Script 経由 LLM タスク (2 types)

| Script | LLM 関与 | 種別 |
|--------|---------|------|
| verifier_local.py | logprob pairwise/tournament | LLM (local) |
| verifier-refinement.py | 論文 refinement halt rule | LLM (local) |

## 3. 分類軸の定義

BELLA の skill profile + TRouter の hierarchical taxonomy + Phase 1 の C5 発見を統合。

### 3.1 6 軸プロファイル

| 軸 | 値 | 定義 | routing への影響 |
|---|---|---|---|
| **A1: ドメイン知識** | low / medium / high | マニフェスト固有概念 (P3, D4, D13 等) への言及が必要か | high → Cloud 傾向 (C5 ボトルネック) |
| **A2: 推論深度** | shallow / medium / deep | multi-hop reasoning の有無。deep = 4+ hops | deep → Cloud 傾向 |
| **A3: ツール使用** | none / read-only / read-write | ツール呼び出しが必要か | read-write → Cloud (safety) |
| **A4: 出力構造度** | free-form / structured / deterministic | 出力形式の制約 | structured → Local 向き |
| **A5: 品質感度** | low / medium / high / critical | 誤りの影響度 | critical → Cloud 固定 |
| **A6: Latency 許容度** | real-time / interactive / batch | 応答速度の要求 | batch → Local 向き (低コスト優先) |

### 3.2 SkillRouter 知見の反映

SkillRouter の発見「skill body が routing の決定的信号」を踏まえ、
各タスクの **SKILL.md 本文** を routing 判断の primary input とする設計を推奨。
name/description だけでは 29-44pp 精度低下。

## 4. 全 LLM タスクのプロファイリング

### 4.1 Agent タスク

| Agent | A1 知識 | A2 推論 | A3 ツール | A4 構造 | A5 感度 | A6 速度 | **Routing 仮説** |
|-------|---------|---------|----------|---------|---------|---------|-----------------|
| Verifier | high | deep | read-only | structured | critical | batch | **Cloud** |
| Judge | high | medium | read-only | structured | high | batch | **Cloud / Hybrid** |
| Observer | high | medium | read-only | structured | medium | batch | **Local probable** |
| Hypothesizer | high | deep | read-only | structured | medium | batch | **Cloud** |
| Integrator | medium | shallow | read-write | structured | high | batch | **Cloud** (write safety) |
| Model-Questioner | low | medium | read-only | free-form | medium | interactive | **Local probable** |

### 4.2 Skill タスク (LLM-driven 部分のみ)

| Skill | A1 知識 | A2 推論 | A3 ツール | A4 構造 | A5 感度 | A6 速度 | **Routing 仮説** |
|-------|---------|---------|----------|---------|---------|---------|-----------------|
| /verify (risk判定) | high | medium | read-only | structured | critical | batch | **Cloud** |
| /evolve (全体) | high | deep | read-write | mixed | high | batch | **Cloud** (orchestration) |
| /research (実験) | high | deep | read-write | free-form | medium | batch | **Cloud** |
| /formal-derivation | high | deep | read-write | deterministic | critical | batch | **Cloud** |
| /paperize writing | medium | medium | none | free-form | medium | batch | **Local probable** |
| /paperize outline | medium | shallow | none | structured | low | batch | **Local confident** |
| /paperize litreview | low | shallow | read-only | structured | low | batch | **Local confident** |
| /trace 解釈 | high | medium | read-only | structured | medium | batch | **Local probable** (= T-interp 相当、GO 判定済み) |
| /metrics 解釈 | high | medium | read-only | structured | medium | batch | **Local probable** (= M-interp 相当、GO 判定済み) |
| /handoff 状態統合 | medium | shallow | read-only | structured | medium | batch | **Local confident** |
| /ground-axiom | high | deep | read-only | structured | high | batch | **Cloud** |
| /adjust-action-space | medium | medium | read-only | structured | medium | batch | **Local probable** |

### 4.3 Built-in タスク

| タスク | A1 知識 | A2 推論 | A3 ツール | A4 構造 | A5 感度 | A6 速度 | **Routing 仮説** |
|-------|---------|---------|----------|---------|---------|---------|-----------------|
| コード生成 | medium | deep | read-write | structured | high | interactive | **Cloud** (SWE-bench 差が大きい) |
| ツール選択 | low | shallow | meta | deterministic | high | real-time | **Cloud** (誤選択コスト高) |
| 会話・Q&A | varies | varies | none | free-form | low | interactive | **Hybrid** (入力依存) |
| 要約・圧縮 | low | shallow | none | structured | medium | batch | **Local confident** |
| 計画 | medium | deep | none | structured | medium | interactive | **Cloud** |
| スキーマ推論 | low | shallow | none | deterministic | low | batch | **Local confident** |

### 4.4 Script タスク

| Script | A1 知識 | A2 推論 | A3 ツール | A4 構造 | A5 感度 | A6 速度 | **Routing 仮説** |
|-------|---------|---------|----------|---------|---------|---------|-----------------|
| verifier_local.py | low | shallow | none | deterministic | medium | batch | **Local** (設計上 local) |
| verifier-refinement.py | low | shallow | none | deterministic | medium | batch | **Local** (設計上 local) |

## 5. Routing 仮説サマリ

### 5.1 分布

| Routing 仮説 | タスク数 | 例 |
|---|---|---|
| **Local confident** | 6 | /paperize outline, litreview, /handoff, 要約, スキーマ推論, verifier_local |
| **Local probable** | 6 | Observer, /trace 解釈, /metrics 解釈, /paperize writing, Model-Questioner, /adjust-action-space |
| **Cloud required** | 10 | Verifier, /verify, /evolve, /research, /formal-derivation, コード生成, ツール選択, Hypothesizer, Integrator, /ground-axiom |
| **Hybrid** | 2 | Judge, 会話・Q&A |

### 5.2 Phase 1 との対応

| Phase 1 タスク | Taxonomy 上のカテゴリ | Routing 仮説 | 実験結果 |
|---|---|---|---|
| M-interp | /metrics 解釈 | Local probable | **GO** (Δ=0.29) |
| T-interp | /trace 解釈 | Local probable | **GO** (Δ=0.10) |

Phase 1 の 2 タスクは「Local probable」6 件のうち 2 件を検証済み。残り 4 件が Tier 2 spot check 対象。

### 5.3 Spot Check 優先順位

TRouter の fail-fast 原則 + BELLA の skill decomposition を参考:

| 優先 | タスク | 理由 |
|------|------|------|
| 1 | **Observer** (V1-V7 観察) | M-interp と入出力構造が近い。/evolve Phase 1 の要。検証コスト低 |
| 2 | **Model-Questioner** (対話型聞き取り) | 唯一の free-form interactive タスク。domain 知識 low で Local 向き |
| 3 | **/paperize writing** (論文執筆) | medium domain knowledge × medium reasoning。既に /paperize 稼働中 |

## 6. 先行研究からの設計示唆

| 先行研究 | 示唆 | 適用先 |
|---------|------|-------|
| BELLA | skill profile 6 軸で透明な routing 判断 | §3.1 の A1-A6 軸に採用 |
| TRouter | 階層 taxonomy + cold-start 対策 | §4 のプロファイリング構造に採用 |
| SkillRouter | SKILL.md 本文が routing signal | ccr router が SKILL.md 本文を読む設計を推奨 |
| RouteLLM | preference data + MF は多モデル向き | 2 モデルの間は threshold で十分、5+ モデル時に再検討 |
| Augment Code guide | hybrid routing がデフォルト化 | Cloud/Local 二値ではなく Hybrid カテゴリを設置 |
| Local LLM coding state | Qwen3-Coder-Next 58.7% SWE-bench on 24GB | コード生成は local 移行の threshold に近づいている |

## References

- [RouteLLM (ICLR 2025)](https://arxiv.org/abs/2406.18665)
- [BELLA: Skill Profiles (arXiv:2602.02386)](https://arxiv.org/abs/2602.02386)
- [TRouter: Task-Aware Routing (arXiv:2604.09377)](https://arxiv.org/abs/2604.09377)
- [SkillRouter (arXiv:2603.22455)](https://arxiv.org/abs/2603.22455)
- [Not-Diamond/awesome-ai-model-routing](https://github.com/Not-Diamond/awesome-ai-model-routing)
- [15 LLMs × 38 Tasks Routing Table](https://ianlpaterson.com/blog/llm-benchmark-2026-38-actual-tasks-15-models-for-2-29/)
- [State of Coding Agents Using Local LLMs (Feb 2026)](https://tomron.net/2026/02/01/the-state-of-coding-agents-using-local-llms-february-2026/)
- [Augment Code: AI Model Routing Guide](https://www.augmentcode.com/guides/ai-model-routing-guide)
