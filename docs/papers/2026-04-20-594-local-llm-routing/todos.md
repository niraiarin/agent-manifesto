---
schema_version: "1"
generated_at: 2026-04-22T03:02:16Z
source_manifest: manifest.json
decay_days: 30
---

# Follow-up todos (Knowledge Base)

## decisions

- [2026-04-20] M-interp / T-interp は Local LLM 委譲 GO 判定。運用モデル qwen3.6-35b-a3b-bf16 via llama-server
- [2026-04-20] ccr default provider を llama-server,qwen3.6-35b-a3b-bf16 に固定
- [2026-04-20] Sub-4 RouteLLM preference data 生成完了。Matrix Factorization 学習に直接投入可能

## experiments

- [2026-04-22] Q2_K_XL (11GB) ローカル 24GB Mac spot check 3/3: M-interp verdict 全件 Cloud 一致 (WARNING), avg 108s/item  
  - file `spot-check-q2/M-interp-001-q2b.json`
- [2026-04-20] BF16 統一 55/55 完成: M-interp pass_rate 90% / T-interp 84% (非対称外れ値除)
- [2026-04-20] 7 モデル比較で active params × quantization × 蒸留の 3 因子が品質を決めることを確認

## findings

- [2026-04-22] Q2_K_XL はローカル 24GB unified memory で Metal GPU offload 動作、ctx=32768 で安定。avg 108s vs BF16 remote 300s — 3x 高速  
  - file `spot-check-q2/`
- [2026-04-20] ccr pass-through (eval $(ccr activate) + claude -p) で CLAUDE.md/rules/tools が自動転送される
- [2026-04-20] undici bodyTimeout が 300s デフォルトで 35B MoE reasoning を切る。ccr API_TIMEOUT_MS は AbortSignal にしか効かない。dispatcher Agent で明示的に bodyTimeout:0 必要
- [2026-04-20] C5 (ドメイン知識) が judgmental タスクのボトルネック。C1-C4 は全モデルで 4-5 安定、差は C5

## literature

- [2026-04-20] RouteLLM (arxiv:2406.18665) Matrix Factorization 方式。preference data format に準拠

## questions

- [2026-04-22] Q2_K_XL で 55 件フルバッチ (CC pass-through 方式) を user ターミナルで実行し BF16 結果と delta 比較  
  - decay_at=2026-05-22
- [2026-04-22] ctx=65536 でのメモリ安定性 (24GB Mac): 32K で動作、65K は未確認  
  - decay_at=2026-05-22
- [2026-04-20] Judge バイアス検証: サンプル 20% を人間ブラインド評価して judge (Claude Opus) との相関を測る  
  - decay_at=2026-05-20
- [2026-04-20] Tier 2 タスク (verify, observer, judge) での Local 委譲品質は未検証  
  - decay_at=2026-05-20
- [2026-04-20] Arena 55k データとの混合 fine-tuning で RouteLLM ルーターの汎化性能を評価する  
  - decay_at=2026-05-20
- [2026-04-20] Opus-distilled-v2 (27B) は FP16 環境で再テスト未実施。58GB メモリ要求だった LM Studio 環境から llama-server への移行後の性能未測定  
  - decay_at=2026-05-20

## reviews

- [2026-04-20] BF16 で 0% エラー達成したため Sub-3 は信頼性 Gate PASS。LM Studio FP16 時の 48% エラー率 (301s bodyTimeout) は infra に起因、モデル能力起因ではなかった
- [2026-04-20] T-interp-023 (Δ=+1.6) のみ構造的出力で judge 差分。judge の分散自体の検証が必要
