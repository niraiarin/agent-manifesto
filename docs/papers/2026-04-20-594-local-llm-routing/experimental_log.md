# Experimental Log

## Thread A — 環境構築 (Sub-1 #592)

**PASS**: ccr v2.0.0 + LM Studio + tool calling 動作確認。Claude Code agent framework 経由で Local LLM に到達することを確認。

- `~/.claude-code-router/config.json` に lm-studio provider 追加
- `eval "$(ccr activate)" && ccr start && claude -p` で疎通
- Sub-1 issue closed (commit e1da87b)

## Thread B — 7 モデル比較実験 (M-interp)

Cloud (Opus) と Local LLM を同一 input (5 件 M-interp task) に対し並列実行し、judge (Claude Opus) で 5 軸 (C1 分析深度 / C2 根拠 / C3 示唆 / C4 提案 / C5 ドメイン知識) × 5 段階の平均点 (`judge`) を付与。`delta = cloud.judge - local.judge` で品質差を測定。

| モデル | Type | Quant | Δ_avg | C5_avg | 判定 |
|--------|------|-------|-------|--------|------|
| gemma4:e4b-128k       | dense 4.5B        | –     | 1.2 | 2   | FAIL |
| gemma-4-26b-a4b       | MoE 26B (act 4B)  | –     | 1.0 | 3   | FAIL |
| gpt-oss-120b          | dense 120B        | –     | 0.6 | 3   | FAIL |
| qwen3.6-35b-a3b       | MoE 35B (act 3B)  | q4_k  | 0.5 | 3.5 | 不安定 |
| qwen3.6-35b-a3b       | MoE 35B (act 3B)  | FP16  | 0.4 | 4.5 | **PASS** |
| Qwen3.5-27b           | dense 27B         | q4    | 0.5 | 4   | 境界 |
| qwen3.5-27b-opus-distilled-v2 | dense 27B | q4    | **0.1** | 4 | **PASS** |

観察:
1. **active params が小さい dense / MoE** (4-4.5B) は Δ ≥ 1.0 で明確に FAIL。
2. **Quantization**: FP16 は q4_k より Δ が 0.2-0.4 改善（qwen3.6-35b-a3b）。
3. **蒸留**: Opus-distilled は同サイズ dense 27B ベースの Δ=0.5 から 0.1 に大幅改善。
4. **120B モデル (gpt-oss)** でも C5 が足りないと FAIL。規模だけでは不十分。

Commits: 6ea6824 (gpt-oss), a5b78d7 (Qwen3.5-27b), 5b650af (distilled), e2f76d1 (gemma-a4b), 71e0fe3 (qwen3.6 q4), b06d0f6 / da8c7b6 (qwen3.6 FP16)。

## Thread C — タイムアウト解消 + BF16 統一再バッチ (Sub-3 最終)

**問題**: LM Studio FP16 で M-interp 29 件バッチの 14/29 (48%) が FAILED。全失敗ログが 301s で一致。

**根本原因**: `undici` (Node 20+ デフォルト HTTP クライアント) の `bodyTimeout` デフォルト 300s。ccr の `API_TIMEOUT_MS:600000` は `AbortSignal.timeout` にのみ反映され、`bodyTimeout` は別ノブ (前セッションの仮説 "Content block is not a text block" は誤認)。

**解消**: ccr `cli.js:uN` の fetch dispatcher を `Agent({bodyTimeout:0, headersTimeout:0})` に差し替え（パッチ 4/4）。`~/.volta/.../claude-code-router/dist/cli.js.bak` にバックアップ保持。M-interp-003 が 21 分で正常完了、以前の 301s タイムアウトが消滅。

**インフラ切替**: LM Studio → llama-server (llama-swap) + BF16 を採用。LM Studio は tool_calls 変換で Content Block エラー頻発、llama-server + OpenAI endpoint 経由で解消。

**BF16 最終結果** (2026-04-19, commit df966c7):

| Task | n | avg_Δ | pass (|Δ|≤0.5) | pass (|Δ|≤0.6) | err_rate |
|------|---|-------|----------------|----------------|----------|
| M-interp | 29 | 0.290 | 26/29 (**90%**) | 29/29 (100%) | 0% |
| T-interp | 26 | 0.154 (外れ値除 0.096) | 20/26 (77%) | 25/26 (96%) | 0% |

旧外れ値 M-interp-019 (Δ=2.0 → 0.2) / M-interp-022 (Δ=3.6 → 0.4) は BF16 再実行で解消。

Commits: d6e29f6 (wip), 2048128 (handoff), e31b388 (BF16 切替), 459cc8b (T-interp 部分再実行), df966c7 (55/55 完成)。

## Thread D — Sub-4 RouteLLM preference data

55 件の判定データを RouteLLM / Chatbot Arena battle 形式 `(model_a, response_a, model_b, response_b, winner)` に変換 (commit d15182b)。閾値 0.5 版と 0.3 版の 2 出力:

| Task | n | model_a (cloud) | model_b (local) | tie |
|------|---|-----------------|-----------------|-----|
| M-interp (thr=0.5) | 29 | 10% | 0%  | 90% |
| T-interp (thr=0.5) | 26 | 19% | 4%  | 77% |
| Total (thr=0.5)    | 55 | 15% | 2%  | 84% |
| Total (thr=0.3)    | 55 | 31% | 20% | 49% |

`scripts/convert-to-routellm.py` + `routellm/README.md` を新設。RouteLLM Matrix Factorization 学習の入力としてそのまま使える。

## Key Decisions

- **運用推奨**: `qwen3.6-35b-a3b-bf16` via llama-server (llama-swap, ctx=65536 以上)
- **ccr default**: `llama-server,qwen3.6-35b-a3b-bf16`
- **SSH tunnel**: `autossh -M 0 -N -L 11234:localhost:1234 <LAN-IP>`、launchd で永続化
- **LM Studio endpoint**: OpenAI 互換 (`/v1/chat/completions`) を使う（LM Studio 固有 API では tool_calls 形式が合わない）
- **品質を決める 3 要因**: active params / quantization / 蒸留。active params が小さいと C5 不足で FAIL
- **Judge バイアスの可能性**: Cloud (Opus) が judge なので Cloud 出力に有利な可能性あり。人間評価 20% ブラインドは未実施（todos.md:questions）
