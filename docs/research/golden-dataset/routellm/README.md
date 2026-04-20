# RouteLLM Preference Data

Sub-3 ゴールデンデータセット (M-interp 29 + T-interp 26 = 55件) を
RouteLLM / Chatbot Arena battle format に変換したもの。

## ファイル

| ファイル | 閾値 | 用途 |
|---------|------|------|
| `preference-data-threshold-0.5.jsonl` | |Δ|≤0.5 → tie | 運用判定用 (PASS 基準と一致) |
| `preference-data-threshold-0.3.jsonl` | |Δ|≤0.3 → tie | ルーター学習用 (tie を減らして信号強化) |

## スキーマ

```jsonl
{
  "id": "M-interp-001",
  "task_type": "M-interp" | "T-interp",
  "input_file": "metrics-input-001.json",
  "input_data": {...},
  "model_a": "claude-opus-4-6",
  "response_a": "...",
  "model_b": "qwen3.6-35b-a3b-bf16",
  "response_b": "...",
  "judge_scores": {
    "cloud": {"c1":5, "c2":5, "c3":4, "c4":5, "c5":5, "overall":4.8},
    "local": {...}
  },
  "mechanical_agreement": {...},
  "delta": 0.2,
  "winner": "model_a" | "model_b" | "tie",
  "threshold": 0.5
}
```

## 分布

### Threshold 0.5 (PASS 基準)

| Task | n | model_a (cloud) | model_b (local) | tie |
|------|---|-----------------|-----------------|-----|
| M-interp | 29 | 3 (10%) | 0 (0%) | 26 (90%) |
| T-interp | 26 | 5 (19%) | 1 (4%) | 20 (77%) |
| **Total** | **55** | **8 (15%)** | **1 (2%)** | **46 (84%)** |

### Threshold 0.3 (ルーター学習向け)

| Task | n | model_a (cloud) | model_b (local) | tie |
|------|---|-----------------|-----------------|-----|
| M-interp | 29 | 16 (55%) | 0 (0%) | 13 (45%) |
| T-interp | 26 | 8 (31%) | 4 (15%) | 14 (54%) |
| **Total** | **55** | **24 (44%)** | **4 (7%)** | **27 (49%)** |

## RouteLLM での使用手順

```bash
# 1. RouteLLM インストール
uv add routellm

# 2. preference data を RouteLLM が期待する形式に変換
#    (id, prompt, model_a_output, model_b_output, winner)
python3 -c "
import json
records = [json.loads(l) for l in open('preference-data-threshold-0.3.jsonl')]
for r in records:
    # RouteLLM expects: prompt, response_chosen, response_rejected, label
    if r['winner'] == 'model_a':
        chosen, rejected = r['response_a'], r['response_b']
        label = 'chosen_is_strong'
    elif r['winner'] == 'model_b':
        chosen, rejected = r['response_b'], r['response_a']
        label = 'chosen_is_weak'
    else:
        continue  # tie を除外するか、別ラベルで扱う
"

# 3. Matrix Factorization ルーターを学習
# （RouteLLM の train_matrix_factorization() 等を使用）
```

## 制限事項

1. **サンプルサイズ**: 55件は RouteLLM の本格学習には少ない (Chatbot Arena は ~55k件)。
   Arena データと混ぜて fine-tuning するのが現実的。
2. **タスク多様性**: M-interp/T-interp の 2 タスクのみ。実運用前に他スキルへ拡張必要。
3. **Judge バイアス**: Claude が judge のため Claude 出力に有利なバイアスの可能性。
   人間評価で補正するのが望ましい。
4. **Tie 過多**: threshold=0.5 では 84% が tie で信号が弱い。学習には threshold=0.3 推奨。
