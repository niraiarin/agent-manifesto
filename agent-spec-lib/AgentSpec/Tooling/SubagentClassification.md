# PI-8 Protocol: change_category subagent 委譲 (部分採用)

Day 148 plan PI-8 (Day 156-158 implementation): Worker (私) の自己評価バイアスを排除するため、`verifier_history.change_category` enum 選択を独立 subagent に委譲する。

## 適用範囲 (部分採用)

| 判定対象 | 委譲先 | Day 158+ |
|---|---|---|
| `change_category` (10 enum) | **Verifier subagent** (general-purpose) | 必須 |
| `pass_layers.implementation` (pass/fail/not_attempted/n_a) | Worker (私) | 維持 (PI-1 で外部検証可能化済) |
| `pass_layers.cycle_hygiene` | cycle-check.sh exit code | 機械的 |
| `pass_layers.evaluation` | Worker (私) | 維持 |

PI-7 部分採用 (案 A): change_category のみ委譲、implementation 判定は Worker 維持。
理由: PI-1 (pass_layers field 化) で implementation の根拠が外部検証可能になっており、change_category の方が enum 選択ミスリスクが高い。

## Subagent dispatch protocol

各 Day commit 前に以下を実行:

1. Worker が変更内容 (file list + 概要) を整理
2. Verifier subagent (general-purpose) に dispatch:
   ```
   prompt 構造:
   - Day N commit (staged) の変更内容
   - change_category enum 10 値の説明
   - 1 行回答要求 (change_category: <enum>、reason: <1 文>)
   ```
3. subagent 回答を verifier_history.change_category にそのまま記録
4. Worker は変更可能だが、変更時は理由を verifier_history.evaluator field に明記

## 例外 (subagent 委譲しない場合)

- pure cycle-check log update (mechanical)
- pure metadata field rename (no semantic change)

これらは Worker が直接判定可、ただし pass_layers.implementation = "n_a" を必須とする。

## subagent_dispatch field の意味変更

verifier_history.subagent_dispatch=true は今後 「PI-8 委譲を実施した」 を意味する。
Day 156 までは ad-hoc な subagent 利用を含んでいたが、Day 158+ は PI-8 protocol 適用 = true、未適用 = false。

## 監視

cycle-check Check 25 (将来追加): 直近 N day で subagent_dispatch=true の比率が一定以上を維持しているか。
