# Divergence Triage Protocol (Phase 6 sprint 2 D #2、Day 202)

PI-17 / PI-18 / D #1 audit で検出された source-port divergence を triage する protocol。
`parity-allow-list.txt` の hand-curation を subagent dispatch で structural 化。

## triage 対象

audit script 実行で出力される 3 種類の divergence:

| 種類 | 例 | 判定軸 |
|---|---|---|
| **statement-divergent** (PI-17) | `governed_update_classified` (allow-listed) | port 改修で structure 変化、意味的差異あり/なし |
| **source-only declaration** | `affected_contains_dependency_chain` 等 (107 件) | port 未実装、port-worthy or out-of-scope |
| **proof-divergent** (PI-18) | (現状ゼロ) | tactic / structural 改修、semantic equiv 維持/破壊 |

## triage 4 択

| verdict | 内容 | 後続 action |
|---|---|---|
| **A. Approve (allow-list 追加)** | 既知の structural 改修 (PI-9 native_decide 等)、semantic equiv 維持 | parity-allow-list.txt に entry 追加、Why コメント |
| **B. Fix (port 修正)** | semantic equiv 破壊、port 側 bug | Day cycle で port 修正、commit "fix(parity): ..." |
| **C. Defer (Phase X+)** | port 未実装の declaration、scope-out | pending_items に entry 追加 |
| **D. Escalate (user 判断)** | 微妙な judgment (例: source 側 typo か意図的か) | user に提示 + 4 択再 |

## subagent dispatch protocol

CI run / cycle-check Check 27 で divergence が検出された時:

```
1. divergence の context (file path、source / port snippet) を抽出
2. Verifier subagent (general-purpose) に dispatch、prompt 構造:
   - "Source X / Port Y の divergence を triage してください"
   - 上記 4 verdict + reason 1 文
3. subagent 回答を triage entry として記録
4. verdict に応じた後続 action を実施
```

## sprint 2 D #2 acceptance

- 本 protocol 文書化 ✓
- 将来の divergence 検出時に protocol 適用可能 (subagent dispatch pattern PI-8 と同型)
- 現状 audit では allow-list 13 件 + source-only 107 件、いずれも既知の意図的 divergence (Day 165 DF dedup 等)
- 将来の port 改修 / source upstream pull で新 divergence 発生時に protocol 起動

## reference

- PI-17 statement parity audit (Day 192)
- PI-18 proof byte-identical audit (Day 193)
- PI-19 SemanticEquivalence registry (Day 194)
- PI-8 subagent dispatch protocol (Day 158)
- D #1 comprehensive pass rate (Day 201)
