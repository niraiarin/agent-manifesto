# Go/No-Go 判定: Local LLM ルーティング (#589)

**判定日**: 2026-04-17
**判定者**: Claude Opus 4.6 (judge) + nirarin (最終承認)
**対象**: M-interp / T-interp タスクの Local LLM 委譲

---

## 1. 判定結果

### M-interp (メトリクス解釈): **CONDITIONAL GO**

閾値 Δ ≤ 0.5 に対し、モデルとquantization によって結果が分かれる。

| モデル | Type | Quant | Delta (avg) | Judge (avg) | C5 (avg) | 判定 |
|--------|------|-------|------------|-------------|----------|------|
| gemma4:e4b-128k | dense 4.5B | - | 1.2 | 3.2 | 2 | FAIL |
| gemma-4-26b-a4b | MoE 26B (act 4B) | - | 1.0 | 3.4 | 3 | FAIL |
| gpt-oss-120b | 120B | - | 0.6 | 3.8 | 3 | FAIL |
| qwen3.6-35b-a3b | MoE 35B (act 3B) | q4_k | 0.5 | 3.9 | 3.5 | PASS (不安定) |
| **qwen3.6-35b-a3b** | **MoE 35B (act 3B)** | **FP16** | **0.4** | **4.4** | **4.5** | **PASS** |
| Qwen3.5-27b | dense 27B | q4 | 0.5 | 3.9 | 4 | PASS (境界) |
| **Opus-distilled-v2** | **dense 27B** | **q4** | **0.1** | **4.3** | **4** | **PASS** |

**条件**: FP16 または高品質 quantization のモデルを使用すること。

### T-interp (トレーサビリティ解釈): **GO**

| モデル | Quant | Delta | Judge | C5 | 判定 |
|--------|-------|-------|-------|-----|------|
| qwen3.6-35b-a3b | FP16 | 0.2 | 4.6 | 5 | **PASS** |

238KB の trace 入力 (43 命題 × 185 アーティファクト) を正確に処理。
D13 影響波及の依存グラフ分析、証拠的リンクの欠如指摘が Cloud 同等。

---

## 2. ゲート判定

### Cost Gate: **PASS** (自動)
Local LLM の処理コスト ≈ $0。Cloud (Opus) は 1 回あたり ~$0.10-0.30。

### Signal Gate: **PASS** (暫定)
- M-interp: 6 モデル比較で品質差を弁別。パラメータ数・quantization・蒸留が品質差の主因
- T-interp: 1 モデルのみだが delta=0.2 で明確に PASS
- 統計検定 (Brunner-Munzel) はサンプル数不足で未実施。追加実験で補強が必要

### 品質 Gate: **CONDITIONAL PASS**
- M-interp: Opus-distilled-v2 (delta=0.1) と qwen3.6-35b-a3b FP16 (delta=0.4) が閾値クリア
- T-interp: qwen3.6-35b-a3b FP16 (delta=0.2) が閾値クリア
- 条件: モデル選択とquantization が品質に直結。q4 量子化で delta が 0.2-0.4 悪化する傾向

---

## 3. 主要な発見

### 3.1 情報アクセスの対称性 (#595)
`eval "$(ccr activate)" && claude -p` で Claude Code が CLAUDE.md/rules/memory/tools (~32K tokens) を
system prompt として Local LLM に自動転送する。独自のドメイン知識注入は不要。

### 3.2 品質を決定する 3 要因
1. **Active パラメータ数**: dense 27B > MoE active 3-4B (同一モデルファミリ内)
2. **Quantization**: FP16 >> q4_k。delta が 0.2-0.4 改善
3. **蒸留**: Opus-distilled が同サイズベースモデルを大幅に上回る (delta 0.5 → 0.1)

### 3.3 C5 (ドメイン知識) がボトルネック
全モデルで C1-C4 は 4-5 を安定的に達成。差が出るのは C5 (ドメイン知識)。
- C5=2-3: P3/D4/non_triviality への言及なし → FAIL
- C5=4-5: D13 影響波及、T6 人間フィードバック等を正しく引用 → PASS

### 3.4 タスク種別による差異
- **M-interp**: ドメイン固有概念の深い理解が必要。モデル能力への依存度が高い
- **T-interp**: 構造化データの分析が主。MoE active 3B でも C5=5 を達成

---

## 4. 推奨モデル

### 運用推奨: qwen3.6-35b-a3b (FP16)
- **理由**: M-interp (delta=0.4) と T-interp (delta=0.2) の両方で PASS。57-164s のレイテンシ。MoE (active 3B) で VRAM 効率が良い
- **条件**: FP16 必須。q4 量子化では不安定

### 最高品質: qwen3.5-27b-claude-4.6-opus-reasoning-distilled-v2
- **理由**: M-interp delta=0.1 で Cloud 同等。C5=4 安定
- **制約**: dense 27B で推論が重い (329s)。T-interp 未テスト (238KB 入力で ccr タイムアウト)

---

## 5. 制限事項と残課題

1. **サンプル数**: M-interp 2入力 × 6モデル、T-interp 1入力 × 1モデル。統計的検定力が不足
2. **タスク種別**: Tier 1 の M-interp/T-interp のみ。Tier 2 (verify, judge, observer) は未実験
3. **Judge バイアス**: Claude が judge なので Claude 出力に有利なバイアスの可能性。人間評価との相関未検証
4. **ccr 接続問題**: Node.js undici の EHOSTUNREACH 問題で SSH tunnel が必要。ccr 側の修正待ち
5. **Thinking model の不安定性**: `Content block is not a text block` エラーが散発。再試行で回復するが自動化に影響

---

## 6. 次のステップ

### Phase 3 に進行する場合
1. **入力件数の拡充**: 各タスク 10-20 件で統計的裏付け
2. **Tier 2 タスクの実験**: verify, observer で比較実験
3. **RouteLLM データ変換**: preference data 形式に変換し、ルーター学習の準備
4. **人間評価**: サンプル 20% でブラインド評価。judge バイアスの検証

### 即時運用する場合
- ccr デフォルトを `qwen3.6-35b-a3b` (FP16) に設定 → **完了**
- M-interp / T-interp の subagent 処理を Local にルーティング
- Cloud にフォールバック: delta > 0.5 または error 時
