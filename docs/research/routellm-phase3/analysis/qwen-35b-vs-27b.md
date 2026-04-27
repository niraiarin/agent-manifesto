# Qwen A/B Agreement Analysis

- A: `qwen3.6-35b-a3b` from `qwen-labels-500.jsonl` (500 items)
- B: `qwen3.6-27b-q4` from `qwen-labels-27b-q4.jsonl` (500 items)
- Overlap: 500 items

## Summary

- Overall agreement: **0.6460** (323/500)
- Cohen's kappa: **0.4642**
- qwen3.6-35b-a3b vs. mDeBERTa classifier: 165/500 = 0.3300
- qwen3.6-27b-q4 vs. mDeBERTa classifier: 164/500 = 0.3280

## Label distribution

| Label | qwen3.6-35b-a3b | qwen3.6-27b-q4 | delta |
|---|---:|---:|---:|
| local_confident | 72 | 15 | -57 |
| local_probable | 99 | 24 | -75 |
| cloud_required | 234 | 315 | +81 |
| hybrid | 58 | 108 | +50 |
| unknown | 37 | 38 | +1 |

## Confusion matrix (qwen3.6-35b-a3b rows × qwen3.6-27b-q4 columns)

```text
  qwen3.6-35b-a3b \ qwen3.6-27b-q4
  rows=qwen3.6-35b-a3b, cols=qwen3.6-27b-q4

                    local_conf local_prob cloud_requ     hybrid    unknown
   local_confident          12          0         39         18          3
    local_probable           1         20         48         27          3
    cloud_required           1          2        219          7          5
            hybrid           1          0          8         47          2
           unknown           0          2          1          9         25
```

## Disagreements sample (up to 20 of 177)

| id | qwen3.6-35b-a3b | qwen3.6-27b-q4 | predicted | prompt preview |
|---|---|---|---|---|
| gt-qwen-0000 | local_confident | cloud_required | local_confident | じゃぁ、次の新規 context に渡す prompt を生成して... |
| gt-qwen-0003 | local_confident | cloud_required | local_confident |  ドキュメント (Section 12.11 + 改訂 11) に反映してから次のステップ (metadata + 完結... |
| gt-qwen-0004 | local_confident | cloud_required | local_confident |  metadata 反映 + 後続タスク記録を実施... |
| gt-qwen-0007 | local_confident | cloud_required | local_confident | 後続 Issue の同 PR 内で実施して。... |
| gt-qwen-0008 | unknown | cloud_required | local_confident | 独立 context agent で議論し提案して。... |
| gt-qwen-0009 | local_confident | hybrid | local_confident | 後続 docs への反映も実施した上で進めてよし... |
| gt-qwen-0010 | local_confident | cloud_required | local_confident | OK, 次の独立セッションに投げる 初期 prompt を生成して... |
| gt-qwen-0014 | local_confident | cloud_required | local_confident | 既存問題は issue に上げておいて。まとめて commit していいよ... |
| gt-qwen-0016 | local_confident | cloud_required | local_confident | ok,その方針を後続ドキュメントに反映して... |
| gt-qwen-0018 | local_confident | cloud_required | local_confident | 次のセッションに投げる 初期 prompt を生成して... |
| gt-qwen-0020 | local_confident | cloud_required | local_confident | 次の Ssession に渡す prompt を生成して... |
| gt-qwen-0025 | local_confident | cloud_required | local_confident | Parent issue に追記した上で、優先順位を定めて、順番にいこう。... |
| gt-qwen-0027 | local_confident | cloud_required | local_confident | これまでの議論を情報量を落とさずに整理して、issue #126 のコメントに加えてほしい... |
| gt-qwen-0031 | local_confident | cloud_required | local_confident | ok, 既存の handoff 文書で思い出しつつ、Day 30 を開始して。... |
| gt-qwen-0032 | local_confident | cloud_required | local_confident | この改善は既存の handoff skill にも反映しておいて... |
| gt-qwen-0040 | local_confident | cloud_required | local_confident | まず成果物は commit してから、108 に着手して... |
| gt-qwen-0041 | hybrid | local_confident | local_confident | OK、区切りとしたい。context 分離した session に引き継げるように、十分に issue などに情報を残し... |
| gt-qwen-0043 | local_confident | cloud_required | local_confident | OK, 残存指摘と、Section E,F について issue を上げて。次の context への handoff ... |
| gt-qwen-0048 | local_confident | cloud_required | local_confident | ドキュメント (Section 12.14 + 改訂 15) に反映してから次のステップ (metadata 反映 → ... |
| gt-qwen-0052 | local_probable | cloud_required | local_probable | ~/.claude/CLAUDE.md を更新したので読んでもらった後に、Day 77 を Lattice test 拡... |
