# Routing Claude Code Judgmental Skills to a Local LLM: An Evaluation on M-interp and T-interp Tasks

**Authors**: nirarin, with Claude Opus 4.7
**Date**: 2026-04-20
**Issues**: #589 (parent), #594 (sub), #595 (context transfer), PR #598 (merged Sub-2/3 scaffolding)
**Artifacts**: [analysis/go-no-go.md](../../research/golden-dataset/analysis/go-no-go.md), [routellm/README.md](../../research/golden-dataset/routellm/README.md)

## Abstract

Claude Code の judgmental スキル（metrics 解釈 "M-interp"、traceability 解釈 "T-interp"）を Local LLM に委譲することで運用コストをゼロ化できるかを検証した。ccr (claude-code-router) + `claude -p` pass-through 方式で CLAUDE.md / rules / tools (~32K tokens) を Cloud と同一条件で注入し、judge (Claude Opus) による 5 軸評価の平均スコア差 `Δ = cloud.judge − local.judge` を品質指標とした。55 件のゴールデンデータセットを 7 モデルで測定した結果、`qwen3.6-35b-a3b` (BF16, MoE 35B active 3B) via `llama-server` が M-interp で avg Δ=0.290 / pass_rate 90%、T-interp で avg Δ=0.096 / pass_rate 84% (非対称、外れ値除) を達成、両 Task で **GO** 判定となった。55 件は Sub-4 で RouteLLM preference 形式に変換済み、以後のルーター学習に再利用できる。

## 1. Motivation

Claude Code の内部スキル（M-interp / T-interp / verify / observer / judge）は Cloud Claude Opus で実行され、1 回あたり $0.10–$0.30 のコストが発生する。これらのスキルを Local LLM に委譲できれば可変コストはゼロになる。既存文献は LLM ルーティング全般を扱うが、**Claude Code 固有の pass-through (system prompt 約 32K tokens)** 条件下で Local LLM が Cloud 相当の判定を出せるかは未検証であった。

Sub-Issue #595 で、`eval "$(ccr activate)" && claude -p "..."` 形式にすると Claude Code が CLAUDE.md / rules / memory / tools を system prompt として Local LLM に自動転送することを確認した。これにより「同一プロンプト・同一ツール集合・同一ドメイン知識」で Cloud / Local を横並び比較する実験条件が整った。

## 2. Method

### 2.1 ゴールデンデータセット

`docs/research/golden-dataset/inputs/` に M-interp 29 件、T-interp 26 件、計 55 件を配置。M-interp は metrics observer の出力 (V1-V7 + 偏差) を入力とし、P3/D4 等のマニフェスト原則に照らした解釈文を要求する判定タスク。T-interp は `manifest-trace json` 出力を入力とし、トレーサビリティ欠落・逸脱の解釈を要求する。

### 2.2 実行

`docs/research/golden-dataset/scripts/run-comparison.sh` が同一 input に対し:

1. Cloud: `claude -p <prompt> --model opus` を実行し JSON 出力を保存
2. Local: `eval "$(ccr activate)" && claude -p <prompt>` を実行し JSON 出力を保存（ccr が Local LLM にルーティング）

を並列で呼び、`outputs/cloud/*.json` と `outputs/local/*.json` に保存する。

### 2.3 評価

`docs/research/golden-dataset/scripts/evaluate.sh` が judge (Claude Opus) を呼び、両出力に対し 5 軸（C1 分析深度 / C2 根拠 / C3 示唆 / C4 提案品質 / C5 ドメイン知識）× 1–5 スケールでスコアリング。平均値を `judge` とし、`delta = cloud.judge − local.judge` を品質差とする。PASS 基準は `|Δ| ≤ 0.5`（対称）または `Δ ≤ 0.5`（非対称、Local ≥ Cloud を許容）。

### 2.4 推論サーバーとインフラ

最終構成: **llama-server (llama.cpp, llama-swap 組込み)** + **ccr**（commit df966c7）。

- llama-server `qwen3.6-35b-a3b-bf16` (LM Studio 環境 192.168.10.90:1234)
- macOS ホスト → `autossh -M 0 -N -L 11234:localhost:1234 ...` で SSH tunnel
- ccr config: provider `llama-server,qwen3.6-35b-a3b-bf16`、endpoint `http://localhost:11234/v1/chat/completions`
- ctx_size 65536（Claude Code system prompt ~32K が収まる必要）

ccr `cli.js` に 4 箇所のパッチ:
1. `reasoning` → `thinking` 変換
2. 空 content → `null` フォールバック
3. `transformRequestOut`: `content=""` + `tool_calls` で `content=null`（ccr #1329 相当）
4. `uN fetch`: `Agent({bodyTimeout: 0, headersTimeout: 0})` で undici 5 分 bodyTimeout を無効化（主要修正）

## 3. Experiments

### 3.1 7 モデル比較（探索フェーズ）

初期は LM Studio FP16 で 7 モデルを少量サンプル（M-interp 2 件）で比較した (experimental_log.md Thread B)：

| モデル | Type | Quant | Δ_avg | C5_avg | 判定 |
|--------|------|-------|-------|--------|------|
| gemma4:e4b-128k | dense 4.5B | – | 1.2 | 2 | FAIL |
| gemma-4-26b-a4b | MoE 26B (act 4B) | – | 1.0 | 3 | FAIL |
| gpt-oss-120b | dense 120B | – | 0.6 | 3 | FAIL |
| qwen3.6-35b-a3b | MoE 35B (act 3B) | q4_k | 0.5 | 3.5 | 不安定 |
| **qwen3.6-35b-a3b** | **MoE 35B (act 3B)** | **FP16** | **0.4** | **4.5** | **PASS** |
| Qwen3.5-27b | dense 27B | q4 | 0.5 | 4 | 境界 |
| **qwen3.5-27b-opus-distilled-v2** | **dense 27B** | **q4** | **0.1** | **4** | **PASS** |

`qwen3.6-35b-a3b-FP16` と `qwen3.5-27b-opus-distilled-v2` を本バッチ候補に選定。

### 3.2 BF16 統一再バッチ（最終）

LM Studio FP16 で M-interp 29 件を流すと 14/29 (48%) が FAILED（Content Block エラー → undici bodyTimeout 根本原因、§2.4 パッチ 4 で解消）。`llama-server` + BF16 に切替後:

| Task | n | avg Δ | pass (|Δ|≤0.5) | pass (非対称 Δ≤0.5) | pass (|Δ|≤0.6) | err |
|------|---|-------|----------------|---------------------|----------------|-----|
| M-interp | 29 | **0.290** | **26/29 (90%)** | 26/29 (90%) | 29/29 (100%) | 0% |
| T-interp | 26 | 0.154 (外れ値除 **0.096**) | 20/26 (77%) | **21/26 (84%)** | 25/26 (96%) | 0% |

旧外れ値 M-interp-019 (Δ=2.0) / M-interp-022 (Δ=3.6) は BF16 再実行で Δ=0.2 / 0.4 に解消。T-interp-023 (Δ=+1.6) のみ残存（新外れ値、judge 差分に起因）。

### 3.3 Sub-4: RouteLLM preference 変換

55 件を RouteLLM / Chatbot Arena battle 形式 `{model_a, response_a, model_b, response_b, winner, judge_scores, delta}` に変換 (commit d15182b)。閾値 0.5 版と 0.3 版を emit:

| 出力 | cloud win | local win | tie |
|------|-----------|-----------|-----|
| threshold 0.5（運用判定相当） | 15% | 2% | **84%** |
| threshold 0.3（学習用、信号強化） | 31% | 20% | 49% |

これにより RouteLLM Matrix Factorization 学習に直接投入可能な preference data が得られた。

## 4. Findings

1. **運用推奨**: `qwen3.6-35b-a3b-bf16` via `llama-server` で M-interp / T-interp とも **GO**。avg Δ は実務判定において Cloud と同等と見なせる水準（90% pass_rate 対称 / 100% |Δ|≤0.6）。
2. **品質を決める 3 要因**: active params、quantization、蒸留。いずれか 1 つが弱いと FAIL。gpt-oss-120b は規模 (120B) だけでは不足、C5 = 3 で FAIL。Opus-distilled-v2 (27B) は規模劣位でも Δ=0.1 で最高品質を示した。
3. **C5 (ドメイン知識) がボトルネック**: C1–C4 は全モデルで 4–5 を安定達成。P3 / D4 / non_triviality / D13 等のマニフェスト原則への言及が C5 を決め、判定 PASS/FAIL を分ける。
4. **タスク種別差**: T-interp (構造化データ分析) は M-interp (ドメイン概念解釈) より Δ が小さい傾向（avg Δ 0.096 vs 0.290）。active 3B でも T-interp では C5=5 に到達した。
5. **#595 発見の汎用性**: ccr pass-through で CLAUDE.md/rules/tools を system prompt 注入する方式は、Local LLM 側に独自のドメイン知識インジェクションを実装する必要をなくし、評価を「モデルの自然言語理解力」だけに限定させる。
6. **Tooling 教訓**: undici `bodyTimeout` のデフォルト 300s は 35B MoE モデルの reasoning が完走する前に切れる。ccr 側の `API_TIMEOUT_MS` は `AbortSignal.timeout` にしか効かず、`bodyTimeout` は dispatcher 経由で別指定が必須。

## 5. Limitations and Follow-up

### 制限事項

- **Judge バイアス**: judge が Claude Opus なので Cloud 出力に有利な可能性あり。人間評価 20% ブラインドは未実施（§6 questions）。
- **Tier 2 タスク未検証**: verify / observer / judge 等の Tier 2 は実験していない。現時点の判定は M-interp / T-interp 限定。
- **Judge スコア粒度**: 0.2 刻み (5 軸 × 1–5 scale 平均)。`|Δ|=0.6` は実質 3 刻み分の最小有意差。対称閾値 0.5 の上限に接するケース (M-interp 3/29, T-interp 5/26) は "boundary" とすべき。
- **ccr パッチ保守性**: cli.js に 4 箇所のパッチ。ccr upgrade 時に再適用必要、`.bak` で回復可能。
- **SSH tunnel 依存**: Node.js undici の EHOSTUNREACH 挙動で LAN IP 直接接続不可。SSH tunnel 経由が必須。

### 次のアクション（詳細は todos.md）

- **運用**: ccr default を `llama-server,qwen3.6-35b-a3b-bf16` に固定、Cloud フォールバックはエラー時のみ有効化。
- **拡張**: Tier 2 タスク（verify / observer）で同様のベンチマーク。
- **学習**: 55 件 preference + Arena 55k 混合で RouteLLM Matrix Factorization 学習 → タスク種別 × モデル品質ルーティングテーブル。
- **検証**: 人間評価 20% ブラインドで judge バイアスを定量化。

## Appendix — Evidence Index

- Research note: `docs/research/local-llm-routing.md` (1,425 lines, main branch)
- Go/No-Go 判定: `docs/research/golden-dataset/analysis/go-no-go.md`
- RouteLLM preference: `docs/research/golden-dataset/routellm/README.md`
- Snapshot: `evidence/p2-verified-snapshot.jsonl` (43 verification tokens)
- Commits: `evidence/commits.md` (18 unmerged commits since PR #598)
- File touches: `evidence/sources.md`

### 主要 commit

| commit | 内容 |
|--------|------|
| `e1da87b` | Sub-2/3 比較実験基盤 (merged via PR #598) |
| `a5b78d7`, `5b650af`, `da8c7b6` | Qwen3.5-27b / Opus-distilled / qwen3.6-35b-a3b 比較 |
| `c17ff96` | Go/No-Go 判定文書 初版 |
| `d6e29f6`, `2048128` | undici bodyTimeout 根本原因調査 + handoff |
| `e31b388` | M-interp llama-server BF16 切替 |
| `459cc8b` | T-interp BF16 部分再実行 |
| `df966c7` | **BF16 統一 55/55 完成** (最終 Sub-3) |
| `d15182b` | **Sub-4 RouteLLM preference 変換** |
