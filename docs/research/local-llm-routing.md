# Research: Local LLM Routing for Claude Code Skills

**開始日**: 2026-04-16
**状態**: 調査中
**目的**: Claude Code のスキル/サブエージェント処理のうち、品質低下なく Local LLM に委譲できるものを特定し、claude-code-router を用いて実現する

---

## 1. 問題定義

Claude Code (Opus/Sonnet) で実行しているスキル群の中に、Local LLM でも同等品質を出せる処理がある。
これらを Local LLM に委譲することで:
- API コスト削減
- レイテンシ改善（ローカル推論）
- プライバシー向上（コードが外部に出ない）
- オフライン動作の可能性

**核心的な問い**: どの処理を、どの基準で、どうルーティングするか？

### 1.1 背景と出発点

本研究の出発点は nirarin の claude-code-plugins リポジトリ
（`git@github.com:niraiarin/claude-code-plugins.git`）。
このモノレポには termbase, self-plugins, agent-manifesto の 3 プラグインが収められ、
Claude Code のスキル・エージェント・hooks をプロジェクト横断で配布する基盤になっている。

termbase プラグインの `crawl-server` スキルでは既に Local LLM (qwen3.5-4b-ud-q6) を
バックエンドで使用しており、**Local LLM との協働は前例がある**。
この前例をスキル/サブエージェント全般に拡張するのが本研究の動機。

---

## 2. 先行研究サーベイ

### 2.1 モデルルーティング理論

#### RouteLLM (UC Berkeley / LMSYS, ICLR 2025)
- **論文**: https://arxiv.org/abs/2406.18665
- **実装**: https://github.com/lm-sys/RouteLLM
- **手法**: 強モデル/弱モデル間の二択ルーティング。5 種のルーター:
  - Matrix Factorization（推奨）
  - SW Ranking（Elo ベース）
  - BERT 分類器
  - Causal LLM 分類器
  - Random（ベースライン）
- **結果**: MT Bench で 85%+ コスト削減、MMLU で 45%、GSM8K で 35%
- **汎化**: GPT-4 / Mixtral ペアで学習したルーターが他のモデルペアにも汎化
- **実用性**: OpenAI 互換 API、Ollama 対応、ドロップイン置換可

#### Cascade Routing (ETH Zurich, ICML 2025)
- **論文**: https://arxiv.org/abs/2410.10347
- **手法**: ルーティング（1 モデル選択）とカスケーディング（小→大の逐次試行）の統一理論
- **核心洞察**: **品質推定器（quality estimator）が成功の最重要因子**
- **結果**: 既存カスケード手法比で最大 16 倍の効率改善
- **示唆**: ルーティングの精度はタスク難易度推定の精度に直結

#### Triage (2026.04, 最新)
- **論文**: https://arxiv.org/html/2604.07494
- **手法**: SE タスクを light/standard/heavy の 3 層に振り分け
- **ルーティング信号**: コード健全性メトリクス（code health sub-factors）
- **核心発見**: 「中堅 LLM はクリーンなコードで恩恵を受けるが、frontier モデルは受けない」
- **安全弁**: 検証ゲートで品質担保。閾値未達ならフォールバック
- **agent-manifesto との対応**: P2（検証の独立性）+ metrics/trace の構造化出力がルーティング信号になる

### 2.2 サーベイ論文

#### Dynamic Model Routing and Cascading Survey (2026.03)
- **論文**: https://arxiv.org/html/2603.04445v1
- **6 パラダイム分類**:
  1. Difficulty-Aware Routing — 難易度推定で振り分け
  2. Human Preference-Aligned — preference data で学習
  3. Clustering-Based — 教師なし学習でクエリグルーピング
  4. Reinforcement Learning — バンディット/ポリシー最適化
  5. Uncertainty-Based — モデル確信度で判断
  6. Cascading — 小→大の逐次試行
- **設計空間の 3 軸**: When（生成前/後/多段）× What（特徴量）× How（ヒューリスティック/学習）
- **結論**: 「適切に設計されたルーティングは、最強の単一モデルを超えうる」

#### Doing More with Less (2025.02)
- **論文**: https://arxiv.org/html/2502.00409v1
- **未解決課題**: 汎化性、評価標準化、タスク多様性

### 2.3 評価手法 (LLM-as-Judge)

#### LLMs-as-Judges 包括サーベイ (2024.12)
- **論文**: https://arxiv.org/abs/2411.15594
- **GitHub**: https://github.com/CSHaitao/Awesome-LLMs-as-Judges
- **5 軸分類**: 機能・方法論・応用・メタ評価・限界
- **精度**: Pairwise comparison で人間合意率 85%（人間同士は 81%）
- **agent-manifesto との対応**: `judge` エージェントがこのパラダイムの実装。比較実験の自動評価に直接転用可

#### PHUDGE
- Phi-3 ファインチューンの軽量 judge モデル
- ローカル実行可能 → Local LLM による自動評価の可能性

---

## 3. 実装ツール調査

### 3.1 claude-code-router (主要候補)

- **リポジトリ**: https://github.com/musistudio/claude-code-router
- **npm**: `@musistudio/claude-code-router` v2.0.0（2026-01 公開）
- **アーキテクチャ**: ポート 3456 でプロキシ。リクエストを傍受しプロバイダ別に変換・転送

#### ルーティング設定

```json
{
  "Router": {
    "default": "anthropic,claude-sonnet-4-6",
    "background": "ollama,qwen3.5-coder:32b",
    "think": "anthropic,claude-opus-4-6",
    "longContext": "anthropic,claude-opus-4-6",
    "longContextThreshold": 60000,
    "webSearch": "anthropic,claude-sonnet-4-6",
    "image": "anthropic,claude-sonnet-4-6"
  }
}
```

#### サブエージェントごとのルーティング

プロンプト先頭にタグを埋め込む:
```
<CCR-SUBAGENT-MODEL>ollama,qwen3.5-coder:32b</CCR-SUBAGENT-MODEL>
```

または環境変数:
```
CLAUDE_CODE_SUBAGENT_MODEL=ollama,qwen3.5-coder:32b
```

#### カスタムルーター（JavaScript）

```javascript
// ~/.claude-code-router/custom-router.js
module.exports = async function router(req, config) {
  const body = req.body;
  const systemPrompt = body.system?.[0]?.text || '';
  
  // スキル名やエージェント種別でルーティング
  if (systemPrompt.includes('/metrics') || systemPrompt.includes('/trace')) {
    return "ollama,qwen3.5-coder:32b";
  }
  if (systemPrompt.includes('judge') || systemPrompt.includes('verifier')) {
    return "ollama,qwen3.5-coder:32b";  // 実験的
  }
  
  // デフォルトは Claude
  return null;
};
```

#### 対応プロバイダ
OpenRouter, DeepSeek, Ollama, Gemini, Volcengine, ModelScope, Dashscope, AIHubmix, SiliconFlow

#### Transformer システム
- `deepseek`, `gemini`, `openrouter`, `groq`: プロバイダアダプタ
- `maxtoken`: トークン制限
- `tooluse`: ツール呼び出し最適化
- `reasoning`: 拡張思考サポート
- `enhancetool`: ツール呼び出しエラー許容
- カスタム transformer も JS で実装可

### 3.2 実現アプローチの比較と選定

議論の中で 4 つの実現アプローチを検討し、**方針 A** を採用した:

| 方針 | 概要 | 判断 | 根拠 |
|------|------|------|------|
| **A: claude-code-router** | 既存ミドルウェアで最短実現 | **採用** | カスタムルーター(JS)でスキル名ベースのディスパッチが可能。plugin として統合可。サブエージェント単位のルーティング(`<CCR-SUBAGENT-MODEL>`)に対応 |
| B: RouteLLM 組込 | 学術裏付けのある学習型ルーター | Phase 3+ で統合 | カスタムルーター内から RouteLLM API を呼ぶ形で A と共存可能。初期は heuristic で十分 |
| C: 自前ルーター on plugins | plugin.json にモデル要件を追加しhooksでディスパッチ | 不採用（現時点） | 最も柔軟だが工数大。A で検証してから検討 |
| D: #38698 実装待ち | Claude Code 本体に per-agent routing が入る | 不採用（依存不可） | 時期不明。ただし入れば最もクリーン |

**選定理由**: A は既存ツール活用で最速に比較実験を開始でき、B の学習型ルーターへの
段階的移行パスもある。C/D はリスクが高いか時期が読めない。

### 3.3 Local LLM サーバーの選定

ユーザーは既に **LM Studio server** と **llama-server** (llama.cpp) を日常的に使用しており、
Ollama は使っていない。調査の結果、3 サーバーとも Anthropic Messages API 互換であるため、
**既存環境をそのまま活用する**:

| サーバー | Anthropic `/v1/messages` | 用途 | 選定理由 |
|---------|------------------------|------|---------|
| **llama-server** | ネイティブ (2026.01~, PR#17570) | メインサーバー | 最軽量、GGUF パラメータ直接制御、Ollama より 1 層少ない |
| **LM Studio** | v0.4.1~ | モデル探索・実験フェーズ | GUI でモデル切替・パラメータ調整が容易 |
| Ollama | v0.14~ | 使用しない（既存環境に合わない） | ユーザーの既存ワークフローに含まれない |

claude-code-router の provider 設定でポート指定するだけでサーバーの差し替えが可能。

### 3.4 その他のツール

| ツール | URL | 特徴 | 採用判断 |
|--------|-----|------|----------|
| RouteLLM | https://github.com/lm-sys/RouteLLM | 学術裏付け、学習型ルーター | Phase 3+ でカスタムルーター内から利用 |
| llm-use | https://github.com/llm-use/llm-use | Orchestrator/Worker パターン、学習型ルーター | 参考設計として |
| NVIDIA LLM Router | https://github.com/NVIDIA-AI-Blueprints/llm-router | CLIP 埋め込み + NN | 過剰。参考のみ |
| LLMRouter (UIUC) | https://github.com/ulab-uiuc/LLMRouter | 16 種ルーター統合ライブラリ | 評価用に有用 |

### 3.5 Claude Code エコシステム現状

- **サブエージェント + Web Search**: 2026.02 から Local LLM 経由でネイティブ動作
- **Per-agent model routing**: anthropics/claude-code#38698 で feature request 中（未実装）
  - 現状はセッション全体で 1 プロバイダ
  - claude-code-router が現時点の最も実用的なワークアラウンド
- **必要条件**: 64K+ トークンコンテキスト、tool calling サポート

---

## 4. agent-manifesto スキルのルーティング分類

### 4.1 分類基準

Triage 論文 + Cascade Routing の知見に基づく 4 軸:
- **入出力の構造化度**: 高いほど Local LLM 向き
- **推論の複雑さ**: 低いほど Local LLM 向き
- **検証可能性**: 機械的に検証できるほど安全にフォールバックできる
- **人間対話の有無**: 対話が必要なものは Claude に残す

**重要な発見（ゴールデンデータセット設計時に判明）**:
metrics（observe.sh, 1,223 行）と trace（manifest-trace, 1,528 行）は、
**deterministic 部分（Bash スクリプト）と judgmental 部分（LLM 解釈）が明確に分離**している。
deterministic 部分は LLM を使わないので比較不要。比較すべきは judgmental 部分のみ。
この分離は他のスキルにも適用可能で、Tier 分類をより精密にする:

### 4.2 ルーティング候補

#### Tier 1: Local LLM 優先（低リスク）

| スキル/処理 | 理由 | 検証方法 |
|------------|------|----------|
| `metrics` | ログ集計 + テンプレート出力。判断なし | 数値一致 |
| `trace` | 半順序走査 + カバレッジ計算。機械的 | カバレッジ数値一致 |
| hooks (大半) | パターンマッチ + shell 実行。LLM 不要なものも | pass/fail |
| `compress`/`decompress` | termbase 引きの機械的置換 | 双方向一致 |

#### Tier 2: 比較実験で判断（中リスク）

| スキル/処理 | 理由 | 検証方法 |
|------------|------|----------|
| `verify` | 構造化スコア出力。Claude との一致率で評価 | judge による pairwise |
| `judge` | 同上。ただし judge を judge する再帰問題 | 人間評価との一致率 |
| `observer` | 観察結果の構造化。仮説化は別 | 観察項目の再現率 |
| `hypothesizer` | 改善案の設計。判断が入る | judge + 人間レビュー |

#### Tier 3: Claude に残す（高リスク）

| スキル/処理 | 理由 |
|------------|------|
| `evolve` オーケストレーション | 複雑な多段推論 + エージェント協調 |
| `research` Gate 判定 | 技術的判断 + 文脈依存 |
| `instantiate-model` / `brownfield` | 人間ヒアリング + 公理系生成 |
| `formal-derivation` | Lean 4 型レベル推論 |
| `spec-driven-workflow` | 司令塔。全体統合 |
| `generate-plugin` / `design-implementation-plan` | 設計判断 |

---

## 5. 実験計画

### Phase 1: 環境構築 + ベースライン

1. claude-code-router をインストール・設定
2. Local LLM サーバーを準備（llama-server メイン、LM Studio でモデル探索。セクション 3.3 参照）
   - 要件: 64K+ context, tool calling 対応
   - 候補モデル: セクション 5.1 参照

### 5.1 候補モデルの選定経緯

#### 初期候補（サーベイ段階）

Web 調査とプロジェクトの要件（tool calling, 64K+ context）から以下を選定:
GPT-OSS-120B, Llama 4 Scout (109B MoE/17B active), Qwen3.5-27B,
qwen3.5-coder:32b, deepseek-coder-v3, codestral, llama3.3:70b

#### MCP ベンチマーク結果による絞り込み

外部ベンチマーク（SWE-bench, BFCL, 推論, Agent）と内部基準を統合した
MCP ツールのランキング結果を取得し、候補を再評価した:

| Rank | モデル | 外部注目点 | 変動 |
|------|--------|-----------|------|
| 1 | **Devstral-Small-24B** | SWE-bench 強 | ⬆ +5 |
| 2 | **Qwen3-32B** (thinking on/off) | 推論+SWE | ⬆ +5 |
| 3 | **Qwen2.5-Coder-32B** | 安定実績 | ↔ |
| 4 | **Llama 3.3 70B** | 推論+Agent | ⬆ +3 |
| 5 | gemma-4-27B/26B-A4B | 外部測定値少ない | ⬇ -3 |
| 6 | **Qwen3.5-27B** | 汎用 | ⬇ -2 |
| 7 | **Qwen2.5-Coder-14B** | BFCL(function calling)安定 | ⬆ +2 |
| 8 | DeepSeek-Coder-V2-Lite | tool calling 弱め外部報告 | ⬇ -3 |
| 9 | Phi-4 14B | 推論/サイズ比最高 | ↔ |
| 10 | Qwen3.5-9B | — | ⬇ -2 |

#### 除外判断

| モデル | 除外理由 |
|--------|---------|
| Llama 4 Scout (109B MoE) | ベンチマーク圏外。MoE の利点はあるが実績不足 |
| DeepSeek-Coder-V2-Lite | 8 位かつ tool calling 弱め（外部報告）。我々は tool calling 必須 |
| codestral | 後継の Devstral-Small-24B が 1 位。世代交代 |
| gemma-4-27B | 5 位だが外部測定値が少なく信頼性不足 |

#### 最終候補リスト（7 モデル）

| # | モデル | パラメータ | ベンチ | 選定理由 |
|---|--------|-----------|--------|---------|
| 1 | **Devstral-Small-24B** | 24B | 1 位 | SWE-bench 最強、24B で軽量 |
| 2 | **Qwen3-32B** | 32B | 2 位 | thinking on/off 切替、推論+SWE 両立 |
| 3 | **Qwen2.5-Coder-32B** | 32B | 3 位 | 安定実績、コーディング特化 |
| 4 | **Llama 3.3 70B** | 70B | 4 位 | 推論+Agent。70B は VRAM 注意 |
| 5 | **Qwen3.5-27B** | 27B | 6 位 | 汎用 |
| 6 | **Qwen2.5-Coder-14B** | 14B | 7 位 | function calling 安定、14B 最省メモリ |
| 7 | **GPT-OSS-120B** | 120B | 圏外 | OpenAI 初 OSS。120B のため推論品質に期待。評価価値あり |

GPT-OSS-120B はベンチマーク圏外だが、OpenAI 初の OSS モデルとして
評価する価値があると判断し候補に残した。
3. 既存スキルの入出力ペアを収集（ゴールデンデータセット）

### Phase 2: Tier 1 比較実験

4. `metrics` と `trace` で同一入力による Claude vs Local 出力比較
5. `judge` エージェントで自動評価（pairwise comparison）
6. 品質閾値の定義: 一致率 X% 以上で Local LLM に切り替え

### Phase 3: ルーティング統合

7. カスタムルーター実装（スキル名ベースのディスパッチ）
8. 検証ゲート統合（P2 verify による事後検証、閾値未達でフォールバック）
9. claude-code-plugins への統合

### Phase 4: Tier 2 実験 + 漸進拡大

10. verify, observer で比較実験
11. 結果に基づきルーティングルール更新
12. (task, model, quality) ログ蓄積 → 学習型ルーターへの発展可能性

---

## 6. 設計上の検討事項

### 6.1 品質推定の再帰問題

Local LLM の出力品質を judge で評価する場合、judge 自体が Local LLM で動いていると
品質推定の信頼性が下がる。初期は judge を Claude に固定し、
十分なデータが溜まってから judge の Local 化を検討する。

### 6.2 フォールバック戦略

Triage 論文の「検証ゲート」モデル:
1. Local LLM が出力
2. verify/judge が品質チェック
3. 閾値未達 → Claude にフォールバック（追加コスト発生）
4. フォールバック率が高すぎる場合 → そのスキルは Tier 3 に移動

### 6.3 P3 との整合

ルーティングルールの変更は構造変更。互換性分類が必要:
- Local LLM 追加（既存に影響なし）→ conservative extension
- ルーティングルール変更（フォールバックあり）→ compatible change
- Claude 依存スキルの Local 化（品質リスク）→ 要検証

### 6.4 claude-code-plugins との統合

plugin.json にモデル要件を追加する設計案:
```json
{
  "name": "agent-manifesto",
  "skills": {
    "metrics": {
      "model_tier": "local",
      "min_context": 32000,
      "requires_tool_calling": true
    },
    "evolve": {
      "model_tier": "cloud",
      "min_context": 128000,
      "requires_tool_calling": true
    }
  }
}
```

---

## 7. Triage 論文精読ノート

**論文**: Triage: Routing Software Engineering Tasks to Cost-Effective LLM Tiers via Code Quality Signals
**著者**: Lech Madeyski
**投稿**: 2026-04-08 (arXiv: 2604.07494)
**状態**: 提案段階（実験プロトコルを提示。結果はまだ出ていない）

### 7.1 核心的発見: Tier 依存非対称性

> **中堅 LLM はクリーンなコードで恩恵を受けるが、frontier モデルは受けない**

これがルーティングを可能にする根拠。コードの複雑さが推論のボトルネックを生み、
それが小さいモデルに不均衡に影響する。逆に言えば、クリーンなコードでは
小さいモデルでも frontier と同等の成果を出せる。

### 7.2 三段アーキテクチャ

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│  1. Feature      │    │  2. Routing      │    │  3. Verification│
│  Pre-computation │───▶│  Decision        │───▶│  Gate           │
│                  │    │                  │    │                 │
│  CodeHealth      │    │  Heuristic /     │    │  Pass/Fail      │
│  25+ sub-factors │    │  ML classifier / │    │  テスト/lint/型  │
│  per-file        │    │  Oracle          │    │  → 失敗時 heavy │
│  incremental     │    │                  │    │    にフォールバック│
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

#### Stage 1: Feature Pre-computation
- ファイルごとに CodeHealth メトリクスを**事前・差分計算**
- タスク完了後にインクリメンタル更新（変更ファイルのみ再計算）
- クエリ可能なフィーチャーテーブルに格納
- **タスクあたりのレイテンシ増加はほぼゼロ**

#### Stage 2: Routing Decision — 3 つのポリシー
1. **Heuristic thresholds**: 手設計ルール（例: `CodeHealth ≥ 9 → light tier`）
2. **Trained ML classifier**: oracle ラベルから feature→tier マッピングを学習
3. **Perfect-hindsight oracle**: 全 tier で実行し最安の成功 tier を選択（上界）

#### Stage 3: Verification Gate
- テストスイート、リンター、型チェッカーによる二値 pass/fail
- **誤ルーティング時は自動で heavy tier にエスカレーション**
- フィードバックループで分類器をインクリメンタルに学習

### 7.3 Triage Matrix

```
              Light         Standard      Heavy
Healthy     ✓ Safe        OK(overpay)   OK(overpay)
Problematic   Risky       ✓ Safe        OK(overpay)
Unhealthy   ✗ Breaks      Risky         ✓ Handles
```

### 7.4 コスト分析

タスクあたりの期待コスト:
```
E[cost] = rL(cL + fL·cH) + rS(cS + fS·cH) + (1 - rL - rS)·cH
```

節約額:
```
savings = rL(cH - cL) + rS(cH - cS) - (rL·fL + rS·fS)·cH
```

- `rL, rS` = light / standard に振り分ける割合
- `fL, fS` = 誤ルーティングによるフォールバック率
- `cL < cS < cH` = 各 tier のコスト

**重要な不等式**: light tier への振り分けが有益になる条件:
> light tier の pass rate（healthy code 上）> cost ratio `cL/cH`

例: Haiku→Opus のコスト比が 1:5 なら、pass rate 20% 以上で既にプラス。
Local LLM (cL ≈ 0) の場合、pass rate > 0 で**常にプラス**（フォールバックコスト次第）。

### 7.5 CodeHealth サブファクター

CodeScene の CodeHealth メトリクス（25+ 因子、1–10 スケール）:

**モジュールレベル:**
| # | ファクター | 計測対象 |
|---|-----------|---------|
| 1 | Low Cohesion (LCOM4) | 単一責任原則違反 |
| 2 | Brain Class / God Class | 過大な責任集中 |
| 3 | Developer Congestion | 開発者間の調整ボトルネック |
| 4 | Complex Code by Former Contributors | 元開発者が残した複雑コード |
| 5 | Lines of Code | ファイルサイズ |

**関数レベル:**
| # | ファクター | 計測対象 |
|---|-----------|---------|
| 6 | Brain Method / God Function | 複雑な中心関数 |
| 7 | DRY Violations | 共変する重複ロジック |
| 8 | Complex Method | cyclomatic complexity |
| 9 | Primitive Obsession | ドメイン言語の欠如 |
| 10 | Large Method | 行数過多 |

**実装レベル:**
| # | ファクター | 計測対象 |
|---|-----------|---------|
| 11 | Nested Complexity | ネストした条件/ループ |
| 12 | Bumpy Road | 責任のカプセル化失敗 |
| 13 | Complex Conditional | 複合論理演算子 |
| 14 | Large Assertion Blocks | テストの抽象化不足 |
| 15 | Duplicated Assertion Blocks | テストの DRY 違反 |

（残り 10+ 因子は CodeScene 内部。言語依存で 25–30 因子。
cyclomatic complexity, nesting depth 等のサブ閾値メトリクスと推定）

### 7.6 実験設計（結果未出）

- **データセット**: SWE-bench Lite（300 GitHub issue 解決タスク）
- **プロトコル**: 各タスクを 3 tier × 3 回 = 9 回実行（合計 2,700 エージェント実行）
- **多数決**: 非決定性を majority vote で処理
- **マッチドペア**: パッチサイズで difficulty を揃え、CodeHealth の信号を分離

#### Pilot Go/No-Go ゲート（50 タスクで判定）

| ゲート | 条件 | 意味 |
|--------|------|------|
| **Cost Gate** | light tier pass rate > `cL/cH` | コスト的に成り立つか |
| **Signal Gate** | p̂ ≥ 0.56 (probability of superiority) | CodeHealth が tier を弁別できるか |

両方パスしなければ full evaluation に進まない。統計検定は Brunner-Munzel test。

#### Feature Importance (RQ1)
- SHAP で CodeHealth サブファクターをランキング
- top-1, top-3, top-5 サブファクター vs composite score で比較
- Matthews Correlation Coefficient + コスト節約で評価

### 7.7 設計上の注目点

#### 抽象化の二軸
- **モデル軸**: 具体的モデル名でなく capability tier で定義 → モデル差し替え時は tier 再較正のみ
- **メトリクス軸**: CodeHealth に限定せず任意の per-file 品質指標を受容

#### Worst-Health File 仮定
マルチファイルタスクでは最も健全性の低いファイルでルーティングを決定。
1 つの問題ファイルがワークフロー全体に波及するため。

#### Deployment Gap（本番と評価のギャップ）
- 評価時: ground-truth パッチからターゲットファイルが既知
- 本番運用: issue description からファイルを推定する必要あり
- このヒューリスティクスの精度が実効性を制約する

### 7.8 我々のプロジェクトへの転写

| Triage の概念 | agent-manifesto での対応 |
|--------------|-------------------------|
| CodeHealth sub-factors | `metrics` スキルの V1-V7 + trace の構造化出力 |
| Light / Standard / Heavy tier | Local LLM / Sonnet / Opus |
| Verification Gate | `verify` エージェント (P2) |
| Feature Pre-computation | hooks の PostToolUse で自動計測 |
| Heuristic threshold | カスタムルーターの if 文 |
| ML classifier | 将来的に (task, model, quality) ログから学習 |
| Worst-Health File | スキルの複雑度で判定（多段推論 → Opus） |
| Pilot Go/No-Go | Phase 2 の比較実験がこれに相当 |

#### 転写時の差分

1. **ルーティング単位**: Triage は「GitHub issue 解決タスク」単位。我々は「スキル実行」単位。
   スキルは issue より粒度が細かく、入出力が明確 → ルーティングしやすい

2. **品質信号**: Triage は CodeHealth（コードの複雑さ）。我々は**スキルの入出力構造化度**
   がより直接的な信号。構造化出力 = テンプレート充填 = Local LLM 向き

3. **検証ゲート**: Triage はテスト/lint/型。我々は `verify` + `judge` の LLM ベース検証。
   機械的検証と LLM 検証の二層

4. **フォールバックコスト**: Triage は heavy tier の実行コストのみ。
   我々は Local → Claude のフォールバック時、コンテキスト再構築コストが加算される

5. **Deployment Gap が小さい**: Triage は issue→ファイル推定が必要。我々はスキル名で
   ルーティング先が静的に決まる → 推定不要。**これは大きな優位点**

6. **cL ≈ 0 の特殊性**: Local LLM のコストはほぼゼロ。Triage のコスト方程式で cL → 0
   とすると、savings ≈ rL·cH - rL·fL·cH = rL·cH·(1 - fL)。
   **フォールバック率 fL < 1 である限り、常に節約になる**

#### 次のアクション

- [ ] `metrics` / `trace` の過去実行ログから入出力ペアを抽出（ゴールデンデータセット）
- [ ] 50 タスク相当の pilot で Go/No-Go 判定（Triage の手法を踏襲）
- [ ] Cost Gate: Local LLM pass rate > 0 で自動パス（cL ≈ 0 のため）
- [ ] Signal Gate: スキル種別が tier を弁別するか（p̂ ≥ 0.56）で判定

---

## 8. RouteLLM 論文精読ノート

**論文**: RouteLLM: Learning to Route LLMs with Preference Data
**著者**: Isaac Ong, Amjad Almahairi, Vincent Wu, Wei-Lin Chiang, Tianhao Wu, Joseph E. Gonzalez, M Waleed Kadous, Ion Stoica
**所属**: UC Berkeley / LMSYS / Anyscale
**発表**: ICLR 2025 (arXiv: 2406.18665)
**コード**: https://github.com/lm-sys/RouteLLM

### 8.1 問題定式化

二値ルーティング関数:
```
R_bin^α(q) = { 0  if P(win_strong | q) < α
             { 1  otherwise
```

- `q`: 入力クエリ
- `α ∈ [0,1]`: コスト閾値（高い → strong を多用、低い → weak を多用）
- `P(win_strong | q)`: strong モデルが weak に勝つ確率の推定

**報酬モデリングとの違い**: ルーティングは**応答を見る前に**モデルを選ぶ必要がある。
クエリの複雑さとモデル能力のギャップを理解する必要がある。

### 8.2 評価指標

#### PGR (Performance Gap Recovered)
```
PGR(R) = (r(R) - r(M_weak)) / (r(M_strong) - r(M_weak))
```
ルーターが weak/strong の性能ギャップをどれだけ回収したか。0=weak 相当、1=strong 相当。

#### APGR (Average PGR)
```
APGR(R) ≈ (1/10) Σ PGR(R^αi)    (i=1..10)
```
全コスト閾値にわたる PGR の積分。包括的な品質/コスト評価。0.5 = Random ベースライン。

#### CPT (Call-Performance Threshold)
```
CPT(x%) = strong モデルの呼び出し割合の最小値 s.t. PGR ≥ x%
```
例: CPT(50%) = 13.4% → strong を 13.4% しか使わずに PGR 50% を達成。

### 8.3 学習データ

**一次データ**: Chatbot Arena の 80K 対戦データ（人間 preference 判定）

**データ処理**:
- モデルを Elo スコアで 10 tier にクラスタリング（ラベルスパース性を軽減）
- Tier 0-1: strong (GPT-4 相当)
- Tier 2: weak (Mixtral-8x7B 相当)
- **クエリテキストとモデル ID のみ保持。実際の応答は捨てる**

**データ拡張（これが鍵）**:
- `D_gold`: ゴールデンラベル付きデータ（MMLU validation ~1,500 件）
- `D_judge`: LLM judge ラベル（GPT-4 による 120K 件の判定、コスト ~$700）

### 8.4 ルーターアーキテクチャ

#### (1) SW Ranking（Similarity-Weighted）
- **原理**: Bradley-Terry モデル + 類似度ベース重み付け
- **推論時計算**: テストクエリと学習クエリの cosine 類似度を計算、指数重み γ^(1+S) で加重
- **学習不要**: 推論時に都度計算（k-NN 的）
- **コスト**: $37.36/M requests（埋め込み計算がボトルネック）
- **特性**: 低データでも強い。Arena データのみで APGR 0.610（MT Bench）

#### (2) Matrix Factorization（推奨）
- **原理**: 双線形スコアリング関数による協調フィルタリング
- **スコアリング関数**:
  ```
  s(M, q) = w2^T (v_m ⊙ (W1^T v_q + b))
  ```
  - `v_m`: モデル埋め込み (d_m 次元)
  - `v_q`: クエリ埋め込み (d_q 次元)
  - `W1 ∈ R^(d_q × d_m)`: 射影行列
  - `⊙`: Hadamard 積（要素積）
  - `w2 ∈ R^d_m`: 回帰ヘッド
- **勝率推定**: `P(win_strong | q) = σ(s(M_strong, q) - s(M_weak, q))`
- **学習**: 8GB GPU, ~10 epochs, batch 64
- **コスト**: **$1.42/M requests**（最安）
- **特性**: **全体最高性能**。APGR 0.802 (MT Bench + augmentation)

#### (3) BERT Classifier
- **原理**: BERT-base をファインチューン、CLS トークンでロジスティック回帰
- **式**: `P(win_strong | q) = σ(W · h_CLS + b)`
- **学習**: 2×L4 24GB, ~2000 steps, lr=1e-5
- **特性**: 低データで弱い（Arena のみで APGR 0.391）、拡張データで劇的改善（0.751）

#### (4) Causal LLM Classifier
- **原理**: Llama 3 8B を命令追従で学習。次トークン予測でラベル出力
- **学習**: 8×A100, ~2000 steps, lr=1e-6
- **特性**: GSM8K で最強（APGR 0.622）。推論が重い

### 8.5 実験結果（全数値）

#### MT Bench (GPT-4 vs Mixtral-8x7B)

| 学習データ | ルーター | CPT(50%) | CPT(80%) | APGR |
|-----------|---------|----------|----------|------|
| — | Random | 49.0% | 78.1% | 0.500 |
| Arena | SW Ranking | 37.9% | 59.0% | 0.610 |
| Arena | Matrix Fact. | 25.3% | 74.3% | 0.580 |
| Arena | Causal LLM | 28.8% | 77.5% | 0.573 |
| Arena | BERT | 78.1% | 87.6% | 0.391 |
| Arena+Judge | **Matrix Fact.** | **13.4%** | **31.3%** | **0.802** |
| Arena+Judge | SW Ranking | 23.2% | 36.0% | 0.759 |
| Arena+Judge | BERT | 19.6% | 34.0% | 0.751 |
| Arena+Judge | Causal LLM | 31.5% | 48.8% | 0.679 |

**解釈**: Matrix Factorization + Judge 拡張で、strong モデルを **13.4%** しか使わずに
PGR 50% を達成。80% 回復にも 31.3% で十分。

#### MMLU 5-shot

| 学習データ | ルーター | CPT(50%) | CPT(80%) | APGR |
|-----------|---------|----------|----------|------|
| — | Random | 50.1% | 79.9% | 0.500 |
| Arena | 全ルーター | ~45-56% | ~77-80% | ~0.47-0.52 |
| Arena+Gold | SW Ranking | 35.4% | 71.6% | 0.603 |
| Arena+Gold | Causal LLM | 35.5% | 70.3% | 0.600 |
| Arena+Gold | Matrix Fact. | 35.5% | 71.4% | 0.597 |
| Arena+Gold | BERT | 41.3% | 72.2% | 0.572 |

**解釈**: Arena のみではほぼ Random。**たった 1,500 件のゴールデンラベル**（全学習データの 1.5%）
で APGR が 0.50 → 0.60 に跳ね上がる。少量の in-domain データが劇的に効く。

#### GSM8K 8-shot

| 学習データ | ルーター | CPT(50%) | CPT(80%) | APGR |
|-----------|---------|----------|----------|------|
| — | Random | 50.0% | 80.1% | 0.497 |
| Arena+Judge | Causal LLM | 33.6% | 63.3% | 0.622 |
| Arena+Judge | SW Ranking | 41.2% | 72.2% | 0.568 |
| Arena+Judge | Matrix Fact. | 38.8% | 72.6% | 0.565 |
| Arena+Judge | BERT | 44.8% | 79.1% | 0.531 |

#### クロスモデル汎化 (Claude 3 Opus / Llama 3 8B, MT Bench)

| 学習データ | ルーター | CPT(50%) | CPT(80%) | APGR |
|-----------|---------|----------|----------|------|
| — | Random | 47.2% | 77.1% | 0.494 |
| Arena+Judge | **Matrix Fact.** | **30.5%** | **41.8%** | **0.703** |
| Arena+Judge | SW Ranking | 31.7% | 48.4% | 0.667 |
| Arena+Judge | Causal LLM | 40.5% | 55.8% | 0.625 |
| Arena+Judge | BERT | 36.3% | 50.8% | 0.618 |

**重要**: GPT-4/Mixtral で学習したルーターが **再学習なしに** Claude/Llama ペアで動作。
Matrix Factorization が APGR 0.703 を達成。ルーターはモデル固有パターンではなく
**クエリ複雑度 vs モデル能力ギャップ** を学習している。

### 8.6 コスト分析

**モデル価格** (論文時点):
- GPT-4: $24.7/M tokens
- Mixtral-8x7B: $0.24/M tokens
- コスト比: **~103:1**

**ルーティングオーバーヘッド**:
| ルーター | コスト/M requests | スループット |
|---------|-----------------|------------|
| Matrix Fact. | **$1.42** | 155 req/s |
| BERT | $3.19 | 70 req/s |
| Causal LLM | $5.23 | 42 req/s |
| SW Ranking | $37.36 | 2.9 req/s |

Matrix Factorization はコスト・スループットとも最良。GPT-4 コストの 0.006%。

**実効コスト削減**:
| ベンチマーク | 削減率 | 品質維持 |
|------------|--------|---------|
| MT Bench | **3.66×** | GPT-4 の 95% |
| MMLU | 1.41× | 92% |
| GSM8K | 1.49× | 87% |

### 8.7 データセット-ベンチマーク類似度

```
S(B, D_pref) = (1/n) Σ max_j cos(b_i, d_j)
```

| ベンチマーク | Arena のみ | 拡張後 | 差分 |
|------------|-----------|--------|------|
| MT Bench | 0.608 | 0.653 (+Judge) | +7.4% |
| MMLU | 0.482 | 0.568 (+Gold) | +17.8% |
| GSM8K | 0.493 | 0.534 (+Judge) | +8.3% |

**洞察**: 類似度スコアとルーター性能に強い相関。
ターゲットドメインに近いデータを少量追加するだけで劇的に改善。

### 8.8 我々のプロジェクトへの転写

#### 直接適用可能な知見

1. **Matrix Factorization を第一候補にする**
   - 最高性能 + 最低コスト + 最高スループット + クロスモデル汎化
   - 8GB GPU で学習可能（ローカルマシンで実行可）

2. **少量のゴールデンラベルが劇的に効く**
   - MMLU では **1,500 件（全体の 1.5%）** で APGR が 0.50→0.60
   - 我々のスキル実行ログから 50-100 件のラベル付きデータがあれば十分な可能性
   - Phase 2 の比較実験自体がゴールデンデータセットの構築になる

3. **クロスモデル汎化が効く**
   - GPT-4/Mixtral で学習 → Claude/Llama で動作
   - 我々が Claude/Local で学習データを作っても、モデル変更時に再学習不要の可能性

4. **類似度メトリクスで拡張データの効果を予測できる**
   - ルーター学習前に、学習データとターゲットタスクの cos 類似度を測定
   - 0.55 未満ならドメイン固有データの追加が必要

#### Triage との統合設計

```
┌────────────────────────────────┐
│  claude-code-router (proxy)     │
│                                 │
│  ┌───────────────────────────┐ │
│  │ Custom Router (JS)         │ │
│  │                            │ │
│  │  Phase 1: Heuristic        │ │  ← スキル名ベースの静的ルーティング
│  │  if skill ∈ Tier1 → local  │ │
│  │  else → claude              │ │
│  │                            │ │
│  │  Phase 3+: RouteLLM MF     │ │  ← Matrix Factorization による動的ルーティング
│  │  P(win_claude|q) < α       │ │
│  │  → local                   │ │
│  │  else → claude              │ │
│  └───────────────────────────┘ │
│                                 │
│  ┌───────────────────────────┐ │
│  │ Verification Gate (post)   │ │  ← Triage の Stage 3
│  │  verify/judge → pass/fail  │ │
│  │  fail → fallback to claude │ │
│  └───────────────────────────┘ │
└────────────────────────────────┘
```

**Phase 1** (Heuristic): スキル名で静的ルーティング。Triage の Stage 2 heuristic に相当。
**Phase 3+** (Learned): RouteLLM の Matrix Factorization で動的ルーティング。
学習データは Phase 2 の比較実験から構築。

#### RouteLLM 統合の具体的手順

1. `pip install routellm` (or `uv add routellm`)
2. Chatbot Arena データで初期ルーターを学習（汎用ベースライン）
3. Phase 2 比較実験で (query, skill, claude_output, local_output, judge_score) を蓄積
4. judge_score からゴールデンラベル (`D_gold`) を構築
5. Arena + D_gold で Matrix Factorization ルーターを再学習
6. claude-code-router の custom-router.js から RouteLLM API を呼び出し

#### 未解決の問い

- **RouteLLM は二値ルーティング**。我々は 3 tier (Local/Sonnet/Opus) が欲しい。
  → 2 段カスケード: (1) Local vs Cloud、(2) Cloud 内で Sonnet vs Opus
  → または Cascade Routing 論文の手法を適用
- **RouteLLM のクエリ埋め込みはテキスト**。我々のルーティング信号はスキル名（カテゴリカル）。
  → スキルプロンプトのテキスト埋め込みを使うか、スキル名を feature として追加するか
- **RouteLLM の学習には preference data が必要**。我々は judge スコアから生成可能。
  → judge が (claude_output, local_output) を pairwise 比較 → preference ラベル

---

## 9. Cascade Routing 論文精読ノート

**論文**: A Unified Approach to Routing and Cascading for LLMs
**著者**: Jasper Dekoninck, Maximilian Baader, Martin Vechev
**所属**: ETH Zurich (SRI Lab)
**発表**: ICML 2025 (arXiv: 2410.10347)

### 9.1 問題定式化

k 個のモデル m₁,...,mₖ が利用可能。クエリ x に対して:
- `qᵢ(x)`: モデル mᵢ の品質（真値、未知）
- `q̂ᵢ(x)`: 品質推定値
- `cᵢ(x)`: コスト（トークン数 × API 単価）
- `B`: コスト予算

**最適化問題**:
```
max  E[Σᵢ sᵢ(x)·q̂ᵢ(x)]
s.t. E[Σᵢ sᵢ(x)·ĉᵢ(x)] ≤ B
```

ルーティング戦略 `s: X → Δₖ` はクエリをモデルの確率分布にマッピング。

### 9.2 三つのパラダイムの統一

#### Routing（定理 1: 最適ルーティング）

1 回の決定で 1 モデルを選択。最適戦略:
```
s_opt = γ·s^λ_min + (1-γ)·s^λ_max
```

- `τᵢ(x, λ) = q̂ᵢ(x) - λ·ĉᵢ(x)`: コスト調整済み品質
- `s^λ_min`: τ を最大化する最安モデルを選択
- `s^λ_max`: τ を最大化する最高額モデルを選択
- `λ ∈ R⁺`: ラグランジュ乗数（品質-コストトレードオフ）
- `γ ∈ [0,1]`: 混合比率（予算 B ちょうどにする）

λ は二分探索で決定（validation データ上のコストが B に一致するまで）。

#### Cascading（定理 2: 最適カスケーディング）

「スーパーモデル」概念を導入:

**定義**: スーパーモデル M = (mᵢ₁,...,mᵢⱼ) は複数モデルの逐次実行列。

**スーパーモデルの品質**:
```
q̂^(j)_{1:i}(x) = E[max(q̂₁(x),...,q̂ᵢ(x))]
```

**重要**: max の期待値を取る。不確実性を無視すると「スーパーモデルの品質 = 
最良の個別モデルの品質」と誤認し、カスケードの価値を過小評価する。

各段 j で、スーパーモデル M₁:ⱼ₋₁,...,M₁:ₖ の中から選択。
最適戦略は定理 1 と同型だが、λ₁,...,λₖ の k 個のハイパーパラメータを最適化:
```
max_{λ₁,...,λₖ,γ}  Q_D(λ₁,...,λₖ,γ)
s.t.                C_D(λ₁,...,λₖ,γ) ≤ B
```

#### Cascade Routing（定理 3: 統一手法）

カスケードとルーティングを同時に行う。各段で**全スーパーモデル** ℳ から選択可能
（カスケードは M₁:ⱼ,...,M₁:ₖ に制限されていた）。

理論的にはスーパーモデルが 2^k 個に爆発するが、
**補題 1（Negative Marginal Gain Pruning）** で計算量を制御:

> スーパーモデル M にモデル m を追加した時の限界利得が負なら、
> M のスーパーセットを含むスーパーモデルは最適解に現れない。

### 9.3 閾値ベースカスケードとの関係（系 1）

従来の閾値ベースカスケード（「確信度が閾値未満なら次のモデル」）は、
最適カスケードと一致する**必要十分条件**:
1. コスト推定がクエリ x に依存しない
2. 品質推定がクエリ x に依存しない（i ≥ j の場合）
3. スーパーモデルの品質 = 個別モデルの品質

**これらの条件は現実にはほぼ成り立たない** → 閾値ベースは最適ではない。

### 9.4 品質推定器

品質推定の精度が**成否の最重要因子**。

**RouterBench**: 真の品質にゼロ中心ガウスノイズを加算。
3 段階のノイズ水準（low/medium/high）で σ² を変化。

**実用ベンチマーク**: 以下の特徴量で線形回帰:
- **Perplexity**: モデルの不確実性の直接指標
- **ベンチマーク出典**: タスク種別のカテゴリカル特徴
- **カスケード内モデル間の一致度**: 先行モデルの出力が一致 → 正解の可能性高

**不確実性推定**: validation データ上の品質差の分散を使用。
`E[max(q̂₁,...,q̂ᵢ)]` の計算に反映。

### 9.5 実験結果（全数値）

#### RouterBench (AUC %, zero-shot)

**3 モデル:**
| 手法 | Low | Medium | High |
|------|-----|--------|------|
| Linear Interp. | 69.62 | 69.62 | 69.62 |
| Routing | 79.73 | 74.97 | 71.81 |
| Cascade (既存) | 80.86 | 74.64 | 72.48 |
| Cascade (本手法) | 81.13 | 76.10 | 72.67 |
| **Cascade Routing** | **82.34** | **76.56** | **73.23** |

**5 モデル:**
| 手法 | Low | Medium | High |
|------|-----|--------|------|
| Linear Interp. | 69.22 | 69.22 | 69.22 |
| Routing | 81.24 | 74.43 | 71.33 |
| Cascade (既存) | 82.33 | 73.03 | 69.53 |
| Cascade (本手法) | 83.05 | 75.15 | 70.18 |
| **Cascade Routing** | **84.34** | **76.32** | **72.74** |

**11 モデル:**
| 手法 | Low | Medium | High |
|------|-----|--------|------|
| Linear Interp. | 70.51 | 70.51 | 70.51 |
| Routing | 83.25 | 74.63 | 72.67 |
| Cascade (既存) | 84.48 | 73.64 | 69.79 |
| Cascade (本手法) | 84.45 | 75.10 | 70.26 |
| **Cascade Routing** | **87.28** | **77.62** | **74.40** |

**傾向**: モデル数が増えるほど Cascade Routing の優位が拡大（3 モデルで +2.5 → 11 モデルで +2.8）。
ノイズが増えると全手法の性能が低下するが、Cascade Routing の相対的優位は維持。

#### 実用ベンチマーク (AUC %)

**Classification (Llama / Gemma / Mistral):**
| 手法 | Llama | Gemma | Mistral |
|------|-------|-------|---------|
| Routing | 74.92 | 64.44 | 64.89 |
| Cascade (既存) | 74.79 | 54.31 | 61.22 |
| **Cascade Routing** | **75.52** | **64.70** | **64.97** |

**Open-Form (Llama / Gemma / Mistral):**
| 手法 | Llama | Gemma | Mistral |
|------|-------|-------|---------|
| Routing | 79.32 | 58.40 | 58.71 |
| Cascade (既存) | 79.23 | 56.18 | 48.29 |
| **Cascade Routing** | **79.84** | **59.62** | **58.69** |

**傾向**: 実用ベンチマークでは改善が 0–1.2% に縮小。
品質推定のノイズが大きく、カスケードの価値が Routing 単体とほぼ同等。

#### Ablation (11 モデル, RouterBench)

| Variant | Low (AUC/ms) | Medium (AUC/ms) | High (AUC/ms) |
|---------|-------------|-----------------|---------------|
| Cascade Routing | 87.26/12.1 | 77.60/12.8 | 74.41/9.4 |
| No pruning | 87.29/80.0 | 77.62/87.2 | 74.41/67.5 |
| Greedy | 85.93/1.6 | 77.16/1.6 | 74.35/1.0 |
| No-Expect | 85.98/3.4 | 77.11/3.0 | 74.35/1.8 |

- **Pruning**: 性能を犠牲にせず 80ms → 12ms に高速化（6.7×）
- **Greedy**: 1.3% 劣化するが 12ms → 1.6ms（最速）
- **No-Expect**: max の期待値を無視すると 1.3% 劣化 → 不確実性モデルは重要

### 9.6 Routing vs Cascading — いつどちらが勝つか

| 条件 | 有利な手法 |
|------|-----------|
| 異なるタスク種別に特化モデルあり | Routing |
| クエリ難易度のばらつきが大きい | Cascading |
| モデル数が多い | Cascade Routing |
| 品質推定が正確 | Cascade Routing |
| 品質推定がノイジー | Routing（カスケードの恩恵が消える） |
| コスト予算が厳しい | Routing（安いモデル 1 つに集中） |
| コスト予算に余裕あり | Cascading（複数モデルの逐次試行） |

### 9.7 限界と注意点

1. **品質推定の精度が律速** — 高ノイズ下では Cascade Routing ≈ Routing。
   「より精巧な品質推定手法が必要」と著者自身が認めている
2. **実用ベンチマークでの改善は小さい**（≤1.2%）— 品質推定のノイズが支配的
3. **計算オーバーヘッド**: ~12ms/decision。リアルタイム制約下では Greedy (~1.6ms) が現実的
4. **スーパーモデルの品質推定が困難** — `E[max(q̂₁,...,q̂ᵢ)]` の正確な計算は
   validation データの分散推定に依存

### 9.8 我々のプロジェクトへの転写

#### 結論: 我々には Cascade Routing は**不要**、Routing + Verification Gate で十分

理由:

1. **モデル数が少ない**: 我々は 2-3 モデル（Local / Sonnet / Opus）。
   Cascade Routing の優位はモデル数が多い時に拡大（11 モデルで +2.8%、3 モデルで +2.5%）。
   2-3 モデルでは Routing との差がさらに縮小

2. **品質推定がノイジーな領域**: LLM 出力の品質推定は本質的にノイジー。
   論文の実用ベンチマークで改善 ≤1.2% がその証拠。
   我々の judge ベース品質推定も同程度のノイズと予想

3. **Verification Gate がカスケードの代替になる**:
   Triage の検証ゲートは本質的に「2 段カスケード」:
   Local → fail → Claude。これは Cascade Routing の特殊ケース（k=2, 固定順序）で、
   品質推定のノイズに robust（pass/fail の二値判定は continuous estimate より安定）

4. **実装の複雑さ**: Cascade Routing は λ₁,...,λₖ の多変数最適化が必要。
   RouteLLM の Matrix Factorization + 二分探索の方がはるかに単純

#### ただし得られた知見

- **品質推定器が最重要** — これは Triage とも一致する核心的洞察
- **不確実性のモデル化が重要** — Ablation で No-Expect が 1.3% 劣化。
  我々の judge は確信度スコアを出すので、これを活用すべき
- **Greedy variant の実用性** — 12ms → 1.6ms で 1.3% の劣化のみ。
  将来 3+ モデルに拡張する場合は Greedy Cascade Routing が実用的
- **perplexity と model agreement が有用な特徴量** — 品質推定の特徴量設計に参考

#### 最終的な設計判断

```
Phase 1: Heuristic Routing (スキル名 → tier の静的マッピング)
         + Verification Gate (verify/judge → pass/fail → fallback)

Phase 3: RouteLLM Matrix Factorization (動的ルーティング)
         + Verification Gate (同上)

Phase 5+: もし 4+ モデルを使う場合のみ Greedy Cascade Routing を検討
```

RouteLLM の二値ルーティング + Triage の Verification Gate の組み合わせが、
Cascade Routing の利点（逐次試行）をより robustly に実現する。

---

## 10. 三論文の統合的考察

### 共通の核心洞察

3 論文すべてが同じ結論に収束: **品質推定器の精度がルーティングの成否を決める**

| 論文 | 表現 |
|------|------|
| RouteLLM | 少量のゴールデンラベルで劇的に改善（0.50→0.60 APGR） |
| Cascade Routing | 「品質推定器が成功の最重要因子」（明示的に主張） |
| Triage | CodeHealth + Verification Gate で品質推定のノイズを吸収 |

### 我々の設計への統合

```
品質推定の 3 層:

Layer 1: スキル種別（カテゴリカル）
  → Phase 1 Heuristic で使用
  → ノイズゼロ（静的マッピング）

Layer 2: RouteLLM Matrix Factorization
  → Phase 3+ で使用
  → スキルプロンプトの埋め込みベース
  → ゴールデンラベルで学習

Layer 3: Verification Gate（verify + judge）
  → 全フェーズで使用
  → pass/fail 二値判定（ノイズに robust）
  → フォールバックの安全弁
```

この 3 層設計は:
- Triage の三段アーキテクチャ（Pre-computation → Routing → Verification）
- RouteLLM の学習型ルーター（Matrix Factorization）
- Cascade Routing の理論的知見（品質推定の重要性、不確実性モデル化）
を統合している。

---

## 11. ゴールデンデータセット設計

### 11.1 設計原則

RouteLLM の知見: **少量の in-domain ゴールデンラベル（全体の 1.5%）が劇的に効く**。
Triage の知見: **Pilot Go/No-Go ゲート（50 タスク）で継続可否を判定**。

→ 最初の 50 件の比較実験が、(1) Go/No-Go 判定 と (2) RouteLLM 学習データ の二重の役割を果たす。

### 11.2 対象スキルの入出力分析

#### metrics スキル（observe.sh）

**自動化度**: ~95% deterministic。1,223 行の Bash スクリプト。

**入力**: `.claude/metrics/*.jsonl` + Lean ソース + git history
（全てファイルシステム上の静的データ。外部 API 呼び出しなし）

**出力**: 構造化 JSON（~200 行）。以下のセクション:
- `lean`: axioms, theorems, sorry, warnings, compression_ratio, de_bruijn_factor
- `tests`: passed, failed
- `evolve_history`: run count, phases totals
- `v1_v7`: 7 メトリクスそれぞれのサブスコア + 非自明性 + 飽和度

**LLM が関与する部分**: observe.sh の出力を受けて、
WARNING/DEGRADED の解釈と改善提案を生成する部分のみ（Step 4 以降）

**比較実験の分離点**:
```
[deterministic]  observe.sh → JSON output (LLM 不要)
[judgmental]     JSON → 解釈・提案テキスト (LLM が関与)
```

#### trace スキル（manifest-trace CLI）

**自動化度**: deterministic CLI (1,528 行) + judgmental interpretation

**入力**: `artifact-manifest.json` + Lean ソース（Ontology.lean の依存関係）

**出力**: 2 種類
- `manifest-trace json` → 構造化 JSON（propositions, coverage, summary）
- `manifest-trace coverage/health/violations` → 色付きテキストレポート

**LLM が関与する部分**: JSON/レポートを受けて、
ギャップの解釈・根本原因分析・改善提案を生成する部分

**比較実験の分離点**:
```
[deterministic]  manifest-trace json → JSON output (LLM 不要)
[judgmental]     JSON → ギャップ解釈・提案テキスト (LLM が関与)
```

### 11.3 比較実験の対象範囲

observe.sh / manifest-trace の deterministic 部分は LLM を使わない → 比較不要。
**比較すべきは LLM が関与する judgmental 部分**:

| タスク ID | スキル | 入力 | 期待出力 | 判定基準 |
|----------|--------|------|---------|---------|
| M-interp | metrics | observe.sh JSON | V1-V7 解釈テキスト | 構造一致 + 判断の妥当性 |
| M-propose | metrics | observe.sh JSON + WARNING 条件 | 改善提案リスト | 提案の具体性 + 実行可能性 |
| T-interp | trace | manifest-trace json | カバレッジギャップ解釈 | ギャップ特定の正確性 |
| T-propose | trace | manifest-trace json + violations | 改善提案 + 優先順位 | D13 影響波及の考慮 |
| V-review | verify | コード diff + マニフェスト | PASS/FAIL + 指摘事項 | Claude との一致率 |
| J-score | judge | 成果物 + GQM 基準 | C1-C5 スコア | Claude スコアとの相関 |

### 11.4 データ収集プロトコル

#### Step 1: 入力固定化（ゴールデン入力の収集）

```bash
# metrics: observe.sh の出力をスナップショット
bash .claude/skills/evolve/scripts/observe.sh > golden/metrics-input-001.json

# trace: manifest-trace json の出力をスナップショット
bash manifest-trace json > golden/trace-input-001.json

# verify: 過去の PR diff を収集
git diff HEAD~1 > golden/verify-input-001.diff

# judge: evolve-history.jsonl から過去の成果物を収集
jq -s '.' .claude/metrics/evolve-history.jsonl | jq '.[100]' > golden/judge-input-001.json
```

目標: 各タスク種別 10-15 件 × 6 種別 = **60-90 入力**

#### Step 2: Claude 参照出力の収集

各入力に対して Claude (Opus) で処理し、出力を記録:
```json
{
  "id": "M-interp-001",
  "task_type": "M-interp",
  "input_file": "golden/metrics-input-001.json",
  "model": "claude-opus-4-6",
  "output": "... Claude の解釈テキスト ...",
  "timestamp": "2026-04-17T...",
  "tokens_in": 1234,
  "tokens_out": 567
}
```

#### Step 3: Local LLM 出力の収集

同一入力を Local LLM で処理:
```json
{
  "id": "M-interp-001",
  "task_type": "M-interp",
  "input_file": "golden/metrics-input-001.json",
  "model": "qwen3.5-coder:32b",
  "output": "... Local LLM の解釈テキスト ...",
  "timestamp": "2026-04-17T...",
  "tokens_in": 1234,
  "tokens_out": 890
}
```

#### Step 4: 評価

**自動評価（judge エージェント）**:

現在の judge は単一成果物の GQM 評価（pairwise 未対応）。
→ **2 つの評価方法を併用**:

**(a) 独立スコアリング**: Claude 出力と Local 出力をそれぞれ judge で評価。
スコア差 Δ = score(Claude) - score(Local) を計算。

**(b) 機械的一致度**: 構造化出力の場合
- JSON キーの一致率
- 数値の一致（完全一致 or 許容範囲内）
- WARNING/DEGRADED 分類の一致
- PASS/FAIL 判定の一致

**人間評価（サンプリング）**:
全件の 20%（~12-18 件）を人間がブラインド評価。
judge スコアとの相関を測定し、judge の信頼性を検証。

### 11.5 評価指標

#### タスク種別ごとの主指標

| タスク種別 | 主指標 | 閾値 | 根拠 |
|-----------|--------|------|------|
| M-interp | judge スコア差 Δ | Δ ≤ 0.5 | GQM 5.00 スケールの 10% |
| M-propose | 提案の実行可能性一致率 | ≥ 80% | Triage の pass rate 基準 |
| T-interp | ギャップ特定の F1 | ≥ 0.85 | precision + recall |
| T-propose | 優先順位の Kendall τ | ≥ 0.7 | 順序相関 |
| V-review | PASS/FAIL 一致率 | ≥ 90% | 二値判定の信頼性 |
| J-score | スコア相関 (Pearson r) | ≥ 0.8 | LLM-as-Judge 先行研究の 85% 基準 |

#### Go/No-Go ゲート（Triage 準拠）

**Cost Gate**: Local LLM の処理コスト ≈ 0 → **自動パス**

**Signal Gate**: タスク種別が品質差を弁別するか
- H₀: スキル種別と品質差は独立
- H₁: Tier 1 スキルは Tier 2/3 より品質差が小さい
- 検定: Brunner-Munzel test, p̂ ≥ 0.56 (probability of superiority)

**品質 Gate** (追加): Tier 1 タスクの主指標が閾値を超えるか
- 全 Tier 1 タスク種別で閾値クリア → **Phase 3 に進行**
- 一部クリア → クリアしたタスクのみ Local 化
- 全滅 → モデル変更 or アプローチ再検討

### 11.6 RouteLLM 学習データへの変換

比較実験の結果を RouteLLM の preference data 形式に変換:

```python
# judge スコアから preference ラベルを生成
def to_preference(claude_score, local_score, threshold=0.5):
    delta = claude_score - local_score
    if delta > threshold:
        return "claude_wins"      # strong model が勝ち
    elif delta < -threshold:
        return "local_wins"       # weak model が勝ち（稀だが可能）
    else:
        return "tie"              # 同等品質 → weak に振るべき（コスト最適）

# RouteLLM 形式に変換
{
    "query": "<スキルプロンプト + 入力データの要約>",
    "model_a": "claude-opus-4-6",      # strong
    "model_b": "qwen3.5-coder:32b",   # weak
    "winner": "model_a" | "model_b" | "tie",
    "task_type": "M-interp",           # メタデータ
    "skill": "metrics"                  # メタデータ
}
```

tie は weak に有利にカウント（同品質なら安い方を選ぶ）。

### 11.7 データセットのディレクトリ構成

```
docs/research/golden-dataset/
├── README.md                    # プロトコル説明
├── inputs/                      # Step 1: 固定化入力
│   ├── metrics-input-001.json
│   ├── trace-input-001.json
│   ├── verify-input-001.diff
│   └── ...
├── outputs/                     # Step 2-3: モデル出力
│   ├── claude/
│   │   ├── M-interp-001.json
│   │   └── ...
│   └── local/
│       ├── M-interp-001.json
│       └── ...
├── evaluations/                 # Step 4: 評価結果
│   ├── judge-scores.jsonl       # judge の独立スコアリング
│   ├── mechanical-match.jsonl   # 機械的一致度
│   └── human-eval.jsonl         # 人間評価（サンプル）
├── analysis/                    # 集計・分析
│   ├── go-no-go.md              # Go/No-Go 判定結果
│   ├── per-task-summary.json    # タスク種別ごとの集計
│   └── routellm-training.jsonl  # RouteLLM 学習データ形式
└── scripts/
    ├── collect-inputs.sh        # 入力収集スクリプト
    ├── run-comparison.sh        # Claude vs Local 実行
    ├── evaluate.sh              # 評価実行
    └── convert-to-routellm.py   # RouteLLM 形式変換
```

### 11.8 実行スケジュール

| フェーズ | 作業 | 件数 | 見積 |
|---------|------|------|------|
| 1a | 入力固定化 | 60-90 件 | スクリプトで自動収集 |
| 1b | Claude 参照出力収集 | 60-90 件 | 自動実行 |
| 1c | Local LLM 出力収集 | 60-90 件 | Ollama で自動実行 |
| 2a | 機械的一致度計算 | 60-90 件 | スクリプトで自動 |
| 2b | judge 独立スコアリング | 120-180 件 (×2) | 自動実行 |
| 2c | 人間評価 | 12-18 件 | 手動（~1-2 時間） |
| 3 | Go/No-Go 判定 | 1 回 | 統計検定 |

### 11.9 注意事項

1. **入力の多様性**: 同一スナップショットを繰り返し使わない。
   異なる時点の metrics/trace 出力を使う（git checkout で過去状態を復元）

2. **プロンプトの統一**: Claude と Local に渡すプロンプトは完全同一にする。
   SKILL.md のプロンプトをそのまま使用（モデル固有の調整はしない）

6. **ドメインコンテキストの同梱（#594 で判明）**: Claude Code セッション内では
   CLAUDE.md / memory / 会話履歴などのドメイン知識が暗黙に利用可能だが、
   Local LLM（ccr/Ollama 経由）にはプロンプトのテキストしか渡されない。
   ccr はフォーマット変換とルーティングのみでコンテキスト注入を行わない。
   **比較実験では、同一のドメインコンテキストを両方のプロンプトに明示的に含めること**。
   コンテキストファイルは `golden-dataset/context/{task-type}-context.md` に配置。
   → ドメイン知識注入方式の設計は #595 で独立検討

3. **judge の独立性**: judge が Claude で動く場合、Claude 出力に有利なバイアスの可能性。
   → 人間評価との相関で検証。相関 < 0.7 なら judge のバイアスを疑う

4. **非決定性の扱い**: 同一入力で 3 回実行し majority vote（RouteLLM の実験プロトコル準拠）

5. **入力にはコードを含めない**: metrics/trace の入力は JSON/ログなので、
   プライバシーの観点から Local LLM に渡しても問題なし

---

## 12. 参考リンク集

### 論文
- [RouteLLM (ICLR 2025)](https://arxiv.org/abs/2406.18665)
- [Cascade Routing (ICML 2025)](https://arxiv.org/abs/2410.10347)
- [Triage: SE Task Routing (2026.04)](https://arxiv.org/html/2604.07494)
- [Dynamic Model Routing Survey (2026.03)](https://arxiv.org/html/2603.04445v1)
- [Doing More with Less Survey (2025.02)](https://arxiv.org/html/2502.00409v1)
- [LLMs-as-Judges Survey (2024.12)](https://arxiv.org/abs/2411.15594)

### 実装
- [claude-code-router](https://github.com/musistudio/claude-code-router) — 主要候補
- [RouteLLM](https://github.com/lm-sys/RouteLLM) — 学習型ルーター
- [llm-use](https://github.com/llm-use/llm-use) — Orchestrator/Worker パターン
- [LLMRouter (UIUC)](https://github.com/ulab-uiuc/LLMRouter) — 統合ライブラリ
- [NVIDIA LLM Router](https://github.com/NVIDIA-AI-Blueprints/llm-router) — 参考設計

### Claude Code エコシステム
- [Ollama Anthropic API 互換](https://ollama.com/blog/claude)
- [Ollama subagents & web search](https://ollama.com/blog/web-search-subagents-claude-code)
- [Per-agent routing feature request](https://github.com/anthropics/claude-code/issues/38698)
- [Ollama Claude Code docs](https://docs.ollama.com/integrations/claude-code)

---

## 変更ログ

| 日付 | 内容 |
|------|------|
| 2026-04-16 | 初版作成。先行研究サーベイ + claude-code-router 調査 + 実験計画策定 |
| 2026-04-16 | Triage 論文精読。三段アーキテクチャ、コスト方程式、Go/No-Go ゲート、転写分析を追加 |
| 2026-04-16 | RouteLLM 論文精読。4 ルーター詳細、全実験数値、Matrix Factorization 推奨、統合設計案を追加 |
| 2026-04-16 | Cascade Routing 論文精読。3 定理+系1、全実験数値、「我々には不要」の判断根拠、三論文統合考察を追加 |
| 2026-04-16 | ゴールデンデータセット設計。6 タスク種別、収集プロトコル、評価指標、Go/No-Go ゲート、RouteLLM 変換、ディレクトリ構成 |
| 2026-04-16 | 議論内容の反映: 出発点(plugins/termbase前例)、アプローチA-D選定根拠、サーバー選定(llama-server/LM Studio)、MCP ベンチマーク結果、モデル除外根拠、deterministic/judgmental 分離の発見 |
| 2026-04-16 | Sub-3 実験設計修正: run-comparison.sh を `claude -p` + ccr 切り替え方式に全面改修。evaluate.sh 更新。run-all.sh バッチ実行スクリプト追加。E2E テスト成功: Cloud(Opus) judge=4.4 vs Local(gemma4:e4b-128k) judge=3.2, delta=1.2。gemma4:e4b-128k (4.5B) では domain knowledge 不足で閾値超過 — 24B-32B モデルでの本番実験が必要 |
| 2026-04-16 | gpt-oss-120b (LM Studio 192.168.10.90:1234) での比較実験。ccr に lm-studio プロバイダ追加。結果: judge=3.8, delta=0.6 (閾値0.5を0.1超過), agreement=75%。2入力で安定。C5(ドメイン知識)=3 が主因 — P3/D4/non_triviality の深い意味理解が不足。モデル能力ではなくドメイン固有概念の注入方法が課題 |
| 2026-04-16 | Qwen3.5-27b での比較実験。結果: judge=3.9, delta=0.5 (閾値 PASS)。2入力(004/001)で delta=0.5 が安定再現。C5=4 で gpt-oss-120b (C5=3) を上回る。D4フェーズ順序、T6、P2 の言及あり。27B で 120B と同等以上のドメイン理解。latency=220-292s |
| 2026-04-16 | qwen3.5-27b-claude-4.6-opus-reasoning-distilled-v2 での比較実験。**delta=0.2/0.0 — Cloud 同等**。input-004: judge=4.2 (delta=0.2), input-001: judge=4.4 (delta=0.0)。全 C1-C5 で 4 以上。蒸留効果が明確に出ている。M-interp タスクでの Local 化は Go 判定可能 |
| 2026-04-16 | google/gemma-4-26b-a4b (MoE 26B, active 4B) での比較実験。input-004: delta=1.3 (C5=2), input-001: delta=0.7 (C5=4, agreement=100%)。入力依存で不安定。active パラメータが少なく dense 27B 系に劣る |
| 2026-04-16 | gemma-4-31b-it-claude-opus-distill: 31B dense で prefill 中に client disconnected (93.6%)。ccr のアイドル接続タイムアウトが原因。スキップ |
| 2026-04-16 | qwen3.6-35b-a3b (MoE 35B, active 3B) での比較実験。input-004: delta=0.8 (数値不正確, assessment mismatch), input-001: delta=0.2 (judge=4.2)。入力依存で不安定。速い(77-118s)が精度にムラ |
| 2026-04-17 | ccr EHOSTUNREACH 問題: Node.js undici が LAN IP に到達不能。SSH tunnel (ssh -L 11234:localhost:1234) で回避。ccr config を localhost:11234 に変更 |
| 2026-04-17 | T-interp 実験開始。qwen3.6-35b-a3b (FP16) で trace-input-001 (238KB): Cloud=4.8, Local=4.6, delta=0.2 PASS。C5=5 で D13 影響波及を正確にトレース。M-interp に続き T-interp でも Local 化 Go 判定可能 |
| 2026-04-17 | qwen3.6-35b-a3b FP16 で M-interp 再実験。input-004: delta=0.6 (C5=4), input-001: delta=0.2 (C5=5, judge=4.6)。量子化版 (delta=0.5-0.8) から改善。FP16 で M-interp avg delta=0.4 PASS |
| 2026-04-17 | **M-interp エラー率 48% (14/29) の根本原因特定**: ハンドオフ記載の「Content block is not a text block」ではなく **undici BodyTimeoutError (300s)**。ccr ログ分析で全 FAILED ケースが正確に 301s でタイムアウト。原因: qwen3.6-35b-a3b の reasoning が 5分以上チャンクなし → undici のデフォルト bodyTimeout=300s が発動。ccr の `API_TIMEOUT_MS: 600000` は `AbortSignal.timeout` にのみ反映され bodyTimeout には無効。修正: ccr cli.js に `Agent({bodyTimeout:0, headersTimeout:0})` パッチ。追加で `transformRequestOut` の `content=""` + `tool_calls` → `content=null` パッチも適用 |
| 2026-04-17 | **M-interp 29件再バッチ結果 + エラー原因特定**: 14/29 (48%) が exit_code=1 だが、ccr ログタイムライン分析で**全14件が未パッチ ccr で実行されていた**ことを確認。パッチ済み ccr (ccr-20260417224027) は level:40/50 エラー=0, BodyTimeout=0, statusCode:500=0。短レイテンシ FAIL (56-121s) は同時リクエストによる Unhandled rejection の波及。パッチ済み ccr で実行された M-interp-001/003 は両方成功 (461s/483s)。**パッチ済み ccr での再バッチで error_rate ≈ 0% が期待される**。評価結果: M-interp avg_delta=0.37, pass_rate=10/15 (67%); T-interp avg_delta=0.07, pass_rate=18/26 (69%), error_rate=0% |
| 2026-04-18 | **LM Studio → llama-server (llama-swap) に移行**: LM Studio で M-interp 再バッチ中に "Compute error" が頻発、qwen3.6-35b-a3b FP16 が不安定化。llama-server + llama-swap (192.168.10.90:11500) に切替。SSH tunnel (11500) + ccr 設定変更。Q2_K_XL (ctx=128K) でテストしたが M-interp-003 が FAIL → BF16 (ctx=64K) に切替で **17/17 M-interp FAIL 再実行 = 100% 成功**。エラー0件 |
| 2026-04-18 | **BF16 最終結果**: M-interp 29/29 全実行成功 (error_rate=0%)、評価 29件: avg_delta=0.462 (全), 0.289 (外れ値除), pass_rate=24/29 (83%) → **24/27 (89% 外れ値除)**。T-interp 26/26 変わらず (avg_delta=0.069, pass=69%)。外れ値 2件 (M-interp-019 Δ=2.0, M-interp-022 Δ=3.6) は旧 LM Studio 実行時の短縮出力で、BF16 再実行未実施。**運用推奨: qwen3.6-35b-a3b-bf16 via llama-server (Go 判定)** |
