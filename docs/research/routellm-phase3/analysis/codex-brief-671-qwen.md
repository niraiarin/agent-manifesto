# Codex Implementation Brief — #671 Phase 2: Qwen LLM Labeling

Parent: #639 | Sub-6 phase 2 | Worktree: `agent-manifesto-research-671` on branch `research/671-qwen-llm-annotation`

## 背景と目的

#671 PR #674 で infrastructure scripts 完備。本 phase で LLM-pseudo-GT 500 件を Qwen3.6 で生成し、以下を測定:

1. Qwen vs existing Opus pseudo-GT (100 件) の agreement → Qwen annotator trust level
2. Qwen vs mDeBERTa production router の disagreement → classifier calibration signal
3. Qwen 500 を corrections.jsonl に変換して mDeBERTa ECE 再測定準備

user の意図: 有意な結果が出たら human annotation に進める判断材料とする。

## モデル選択

**目標**: `YTan2000/Qwen3.6-27B-TQ3_4S`
**実装**: `~/models/Qwen3.6-35B-A3B-UD-Q2_K_XL.gguf` (substitute)

**substitute の理由**:
- 27B-TQ3_4S は TurboQuant 新 quantization (ggml type 46) で、stock llama.cpp 8890 では load 不可 (type ≤ 41)
- 正規 runtime は `turbo-tan/llama.cpp-tq3` fork が必要で、build from source が要求される
- 同 Qwen3.6 世代の 35B-A3B (MoE, 35B total / 3B active) が手元にあり、stock llama.cpp で稼働確認済み
- 35B-A3B は 27B dense より params が多く、annotator capability は同等以上と推定

`llama-server` の起動状態 (既に起動済み, PID=30485):
```
--model ~/models/Qwen3.6-35B-A3B-UD-Q2_K_XL.gguf
--host 127.0.0.1 --port 8090 --ctx-size 8192
--n-gpu-layers 99 --alias qwen3.6-35b-a3b --jinja
```

Thinking mode 無効化: request body に `chat_template_kwargs: {enable_thinking: false}` を含める。

## Scope (本 PR で実装)

### ✅ 実装対象
1. **qwen_labels.py** (新規): real-prompts.jsonl を input に、llama-server 経由で 5-label 分類 → 結果 jsonl に `gt_label`, `annotator="qwen3.6-35b-a3b"`, `rationale`, `latency_ms` を付与
2. **sample_qwen_candidates.py** (新規): real-prompts.jsonl から 500 candidates 抽出。stratification は `real-corpus-per-prompt.jsonl` の `label` + `confidence` を使う (production mDeBERTa の予測)
3. **qwen_vs_opus.py** (新規): opus_labels.py の hardcoded 100 labels と Qwen の同 id 出力を比較し Cohen's kappa + confusion matrix を計算
4. **start-llama-server.sh** (新規): Qwen 起動 wrapper script (既に 35B で起動中のため文書化メイン)
5. **qwen-labeling-runbook.md** (新規): 実行手順 + Gate 基準

### ❌ 本 PR scope 外
- 27B-TQ3_4S 用の turbo-tan/llama.cpp-tq3 fork build
- human annotation
- retrain mDeBERTa v2 (Qwen labels 完了後の別 PR)

## 成果物の期待動作

### qwen_labels.py

```bash
python3 docs/research/routellm-phase3/classifier/qwen_labels.py \
  --input docs/research/routellm-phase3/label-data/qwen-candidates-500.jsonl \
  --output docs/research/routellm-phase3/label-data/qwen-labels-500.jsonl \
  --llama-url http://localhost:8090/v1/chat/completions \
  --checkpoint-every 50
```

実装要件:
- `/no_think` directive ではなく、request body の `chat_template_kwargs: {enable_thinking: false}` を使用
- `max_tokens=128`, `temperature=0.0`, `top_p=1.0`
- SYSTEM prompt: 既存 `zero_shot_qwen.py` の SYSTEM をほぼそのまま流用
- user prompt: 候補の `prompt` フィールド (最大 1500 文字)
- 応答 parse: JSON `{"label": "..."}` 抽出。正規表現 or ast.literal_eval
- Fallback: JSON parse 失敗時は LABELS 内の最初に出現する文字列を採用、無ければ `"unknown"`
- **checkpoint**: 50 件ごとに現状までの結果を output に write (クラッシュ耐性)。resume 時は既処理 id を skip
- **per-entry**: `gt_label`, `annotator="qwen3.6-35b-a3b"`, `annotator_notes=None`, `latency_ms`, `ts` (ISO8601) を追加
- **集計**: 完了時に label distribution、平均 latency、fallback 率を stdout に出力

### sample_qwen_candidates.py

```bash
python3 docs/research/routellm-phase3/classifier/sample_qwen_candidates.py \
  --real-prompts docs/research/routellm-phase3/label-data/real-prompts.jsonl \
  --corpus-classified docs/research/routellm-phase3/analysis/real-corpus-per-prompt.jsonl \
  --output docs/research/routellm-phase3/label-data/qwen-candidates-500.jsonl \
  --n 500 \
  --seed 42
```

real-prompts.jsonl (full text) と real-corpus-per-prompt.jsonl (session_id + mDeBERTa predicted label/confidence) を session_id と prompt 先頭 100 文字で join。

Stratification target (production routing distribution approximation):
- local_probable ~50%
- cloud_required ~20%
- local_confident ~15%
- hybrid ~10%
- unknown ~5%

実装要件:
- 両 jsonl を読み込み、session_id で inner join
- join 失敗項目 (label 未知) は除外
- 各 label から target 件数を取る。足りなければ余剰を次 label から補充
- confidence bin でも軽く均等化 (low/mid/high から各 ~1/3)
- 出力 schema: `{id, session_id, prompt, prompt_len, predicted_label, predicted_confidence, gt_label: null, annotator_notes: null}`
- id 連番: `gt-qwen-NNN`

### qwen_vs_opus.py

```bash
python3 docs/research/routellm-phase3/classifier/qwen_vs_opus.py \
  --qwen docs/research/routellm-phase3/label-data/qwen-labels-500.jsonl \
  --opus-source docs/research/routellm-phase3/classifier/opus_labels.py \
  --output docs/research/routellm-phase3/analysis/qwen-vs-opus.md
```

実装要件:
- `opus_labels.py` の `OPUS_LABELS` list を import して 100 件の (id, label, rationale) dict に変換
- qwen-labels jsonl から同 id を探す (session_id + prompt 先頭 100 文字で match 試行、なければ skip)
- match した ids の subset で:
  - Cohen's kappa
  - overall agreement
  - per-label confusion matrix
  - disagreement の rationale 列挙 (markdown table)
- match 件数が 30 件未満 → WARN ("Opus overlap too small, Qwen trust cannot be validated")
- match 件数が 30 件以上 → Cohen's kappa を信頼値として出力

出力 markdown: summary + confusion matrix + top disagreement examples (up to 20)

### start-llama-server.sh

```bash
#!/bin/bash
set -euo pipefail
# Qwen3.6-35B-A3B を 8090 で起動 (TQ3_4S は stock llama.cpp で load 不能のため substitute)
MODEL_PATH="${MODEL_PATH:-$HOME/models/Qwen3.6-35B-A3B-UD-Q2_K_XL.gguf}"
PORT="${PORT:-8090}"
exec llama-server \
  --model "$MODEL_PATH" \
  --host 127.0.0.1 --port "$PORT" \
  --ctx-size 8192 --n-gpu-layers 99 \
  --alias qwen3.6-35b-a3b \
  --threads 8 --jinja
```

### qwen-labeling-runbook.md

目次:
1. **Model Setup**: 35B-A3B を既に使っている場合と、27B-TQ3_4S を別途 build する場合の両記載
2. **Start Server**: `bash scripts/start-llama-server.sh` (new script)
3. **Sample 500**: sample_qwen_candidates.py
4. **Qwen Labeling**: qwen_labels.py (所要 ~10-20 分 at 35B)
5. **Agreement Analysis**: qwen_vs_opus.py + kappa.py で Qwen-Opus-mDeBERTa 3-way compare
6. **Next Step (if Gate PASS)**: human annotation for re-validation
7. **Next Step (if Gate FAIL)**: prompt engineering iteration, model change

## Gate 基準 (本 phase)

| 指標 | PASS | CONDITIONAL | FAIL |
|---|---|---|---|
| Qwen-Opus Cohen's kappa (overlap) | ≥ 0.6 | 0.4-0.6 | < 0.4 |
| Qwen 500 labeling 完了率 | 100% | 95-99% | < 95% |
| Qwen 平均 latency | 任意 | 任意 | 任意 (参考値) |
| Qwen label distribution | routing dist と 20% 以内 | 20-30% 差 | > 30% 差 |

**PASS → human annotation phase へ**
**CONDITIONAL → prompt iteration / 部分採用**
**FAIL → annotator としては使えず、別 approach 検討 (人間 annotation 直行)**

## 制約

- **L1**: llama-server は `127.0.0.1` 固定、subprocess shell=False
- **P3**: 既存 `zero_shot_qwen.py`, `opus_labels.py` は変更しない (conservative extension)
- 既存 `sample_for_gt.py` (LR backend) も変更しない

## 検証コマンド (Codex が実装完了後に実行)

```bash
cd /Users/nirarin/work/agent-manifesto-research-671

# 1. syntax check
python3 -c "
import ast
for f in [
  'docs/research/routellm-phase3/classifier/qwen_labels.py',
  'docs/research/routellm-phase3/classifier/sample_qwen_candidates.py',
  'docs/research/routellm-phase3/classifier/qwen_vs_opus.py',
]:
    ast.parse(open(f).read())
print('PASS syntax')"

# 2. bash syntax
bash -n scripts/start-llama-server.sh

# 3. sampling (500 items)
python3 docs/research/routellm-phase3/classifier/sample_qwen_candidates.py \
  --real-prompts docs/research/routellm-phase3/label-data/real-prompts.jsonl \
  --corpus-classified docs/research/routellm-phase3/analysis/real-corpus-per-prompt.jsonl \
  --output docs/research/routellm-phase3/label-data/qwen-candidates-500.jsonl \
  --n 500

wc -l docs/research/routellm-phase3/label-data/qwen-candidates-500.jsonl  # expect 500

# 4. Qwen labeling (server 8090 must be running)
python3 docs/research/routellm-phase3/classifier/qwen_labels.py \
  --input docs/research/routellm-phase3/label-data/qwen-candidates-500.jsonl \
  --output docs/research/routellm-phase3/label-data/qwen-labels-500.jsonl \
  --llama-url http://localhost:8090/v1/chat/completions \
  --checkpoint-every 50

# 5. Qwen-Opus compare
python3 docs/research/routellm-phase3/classifier/qwen_vs_opus.py \
  --qwen docs/research/routellm-phase3/label-data/qwen-labels-500.jsonl \
  --opus-source docs/research/routellm-phase3/classifier/opus_labels.py \
  --output docs/research/routellm-phase3/analysis/qwen-vs-opus.md
```

## 参照ファイル

- `docs/research/routellm-phase3/classifier/zero_shot_qwen.py` (SYSTEM prompt 流用元)
- `docs/research/routellm-phase3/classifier/opus_labels.py` (OPUS_LABELS 参照)
- `docs/research/routellm-phase3/classifier/kappa.py` (kappa 計算、既存を import 可能)
- `docs/research/routellm-phase3/label-data/real-prompts.jsonl` (1199 full prompts、既に生成済み)
- `docs/research/routellm-phase3/analysis/real-corpus-per-prompt.jsonl` (1173 items with mDeBERTa predictions)

## 非対象

- 実際の 500 件 Qwen inference 実行 (本 PR は implementation のみ、実行は Claude 側)
- matplotlib を必須にしない (ASCII fallback で十分)
- turbo-tan/llama.cpp-tq3 の build

## Manifest 準拠

commit message:
- `conservative extension` (新規 script のみ、既存 script は不変更)
- `refs #671`
