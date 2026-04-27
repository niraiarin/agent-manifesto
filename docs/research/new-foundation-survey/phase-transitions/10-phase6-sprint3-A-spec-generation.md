# Phase 6 sprint 3 A — Survey P0 #5 仕様生成 framework (Day 203 plan)

## 背景

Survey GA-E5 + G2-4.1 + G3-1.2: CLEVER ベンチマーク 161 問中 1 問 (0.6%) しか End-to-End (自然言語 → 仕様 → 実装 → 証明) に成功しない、本研究領域の最大困難。

Phase 5 で **既存 port の equivalence verification** (problem 変換) で 100% 達成したが、Survey P0 #5「正しい仕様の生成」自体は未対処。

## 現実的 scope (autonomous mode 制約)

CLEVER 0.6% を直接改善することは scope 外。本 sprint の deliverable は:

> **「仕様生成の評価 harness を構築する」** (not 「仕様生成を解く」)

= LLM-driven spec generation の pipeline + evaluation harness。CLEVER style benchmark に乗せて measurement 可能化。

## sprint 3 A acceptance criteria 5 項目

| # | criterion | scope | deliverable |
|---|---|---|---|
| 1 | **spec generation prompt template** | subagent dispatch 用、自然言語要件 → Lean axiom/theorem statement | `docs/research/.../spec-gen-prompt.md` |
| 2 | **harness script** | prompt + subagent + Lean parse 検証 + parity check (PI-17 連動) | `scripts/eval-spec-generation.sh` |
| 3 | **benchmark dataset** (10 prompts) | 既存 PI-19 26 theorems から 10 を逆方向 (statement → 自然言語) で benchmark 化 | `docs/research/.../spec-gen-benchmark.json` |
| 4 | **pass rate measurement** | 10 prompt × subagent dispatch、syntax pass / parity pass / semantic equiv pass の 3 段階 | report Markdown |
| 5 | **examples 13** | 簡単な spec generation pattern demo | `examples/13_spec_generation_demo.lean` |

## 期待される pass rate (Survey 起源予測)

| stage | 期待 pass rate | 根拠 |
|---|---|---|
| syntax pass (Lean parser PASS) | 60-80% | 構文は LLM で対応可、標準 axiom/theorem template |
| parity pass (既存 axiom 名と意味的に近い) | 20-40% | 既存 vocabulary 内の生成、cross-reference 可 |
| semantic equiv pass (既存 statement と byte-identical or proof-equivalent) | **5-15%** | CLEVER 0.6% より高い (我々の prompt は既存 spec を参照可、less open-ended) |

5-15% でも CLEVER 0.6% から ~10x 改善、infrastructure 構築の研究貢献。

## sprint 3 工数 estimate

- A #1: 0.5 Day (prompt template)
- A #2: 1-2 Day (harness script、subagent dispatch + Lean parse 統合)
- A #3: 0.5 Day (benchmark 10 件選定)
- A #4: 1 Day (10 prompt × dispatch、measurement)
- A #5: 0.5 Day (example)

**合計 3.5-4.5 Day** (Day 203-207 予定)

## risk

| risk | mitigation |
|---|---|
| subagent dispatch のコスト増大 (10 prompt) | benchmark を 5 件に縮小、または ε 限定 (cost 制約) |
| LLM 出力の Lean syntax error 多発 | A #2 で minimal parse validation、syntax error は syntax_fail として記録 (FAIL ではない) |
| 0% pass rate (CLEVER 0.6% を下回る) | infrastructure 構築自体が研究貢献、negative result も documented |
| Lean parse 統合が複雑 | lean-cli 経由で wrap、`lean --print-axioms` 等の既存 tool 活用 |

## next step

- Day 203: A #1 prompt template + 本 plan 文書化
- Day 204-205: A #2 harness script
- Day 206: A #3 benchmark dataset
- Day 207: A #4 pass rate measurement + A #5 example
- Day 208: sprint 3 audit + main merge
