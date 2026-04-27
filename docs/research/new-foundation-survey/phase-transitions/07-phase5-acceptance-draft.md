# Phase 5 Acceptance Criteria (Day 191 draft)

Day 187 三面評価を受けて、survey 起源の真の Phase 5 候補から **A. 仕様等価性自動検証 framework (GA-E5、P0)** を採用。

## 設計方針

Survey 計画 (Day 1) で P0 として挙げられた 5 件のうち、Phase 1-4 で 3/5 解消 (退役 / 失敗 / rationale)、残 2/5:

- **仕様等価性証明の壊滅的困難** (CLEVER 0.6%) — GA-E5
- **正しい仕様の生成** (G2-4.1)

うち GA-E5 を Phase 5 primary。理由:
1. Manifest port (Day 165 で 100% by name 達成) の **semantic equivalence** を validate する自然な next step
2. 既存材料 (#print axioms / TrustDelegation / MeasurableSemantic / OpaqueOrigin registry) を framework に統合可能
3. 前回反省 (構文/意味 × 対象/メタ 評価) で指摘した「形式化された規範 vs 実装された規範の gap」への直接対処
4. 「正しい仕様の生成」(本研究 P0 #2) の前段階として「仕様等価の検証」が前提

## Phase 5 acceptance criteria 5 項目

| # | criterion | 操作的定義 | 工数 | priority |
|---|---|---|---|---|
| **1** | **Statement parity audit** | source `lean-formalization/Manifest/*` と port `agent-spec-lib/AgentSpec/Manifest/*` で同名 axiom/theorem の statement を namespace prefix を modulo で比較、divergence を検出 | 3-5 Day | high |
| **2** | **Axiom dependency parity** | 各 theorem に対し `#print axioms` 出力を取得、source ↔ port で axiom dependency set を比較。port-only 追加は許容、source 由来 axiom の欠落 / 別名置換は detect | 3-5 Day | high |
| **3** | **Equivalence registry** | `AgentSpec.Tooling.SemanticEquivalence` Lean module で ~50 critical theorems の equivalence record (name × statement_hash × axiom_deps_match) を保持、`#print axioms` から auto-derive | 2-3 Day | medium |
| **4** | **CI gate (Check 27)** | cycle-check Check 27 追加: equivalence drift (added/removed/modified theorem statement または dep mismatch) を auto detect | 1-2 Day | medium |
| **5** | **examples 11**: equivalence pattern usage demo | `examples/11_semantic_equivalence.lean` で source theorem ↔ port theorem の equivalence proof / record lookup pattern | 1 Day | low |

**工数 estimate**: 10-16 Day (Day 192-207 想定)

## Phase 5 secondary 候補 (Phase 6 候補に格下げ)

| 候補 | tag | 工数 | 採用判断 |
|---|---|---|---|
| B. SMT ハンマー統合 (Lean-Auto / Boole) | GA-C7 | 大 | **Phase 6 へ defer** (lakefile heavy 変更、scope creep risk) |
| C. Atlas augment 戦略 | GA-M2 | 中 | **Phase 6 へ defer** (具体性不足) |
| D. CLEVER 風自己評価 | GA-M1 | 中 | **Phase 5 内 stretch goal** (#3 registry の延長で部分対応可能) |
| E. EnvExtension Auto-Register | GA-C9 | 中 | **Phase 6 へ defer** (norm_cast pattern 採用は要設計) |
| F. Perspective / Iterative Search | GA-C12-15 | 大 | **Phase 6+ へ defer** |
| G. ProofWidget Visualizer | (Survey #13) | 中 | UI、本質ではない、長期 defer |

## Phase 5 PI 追加候補

| 新 PI | 内容 | acceptance |
|---|---|---|
| **PI-17** | Statement parity audit script (`scripts/check-source-port-parity.sh`) | #1 |
| **PI-18** | Axiom dependency parity audit (`#print axioms` の bulk extract + diff) | #2 |
| **PI-19** | SemanticEquivalence registry module の auto-update (Day cycle で統合) | #3 |
| **PI-20** | cycle-check Check 27 (equivalence drift detection) | #4 |

## Phase 5 終了基準

- 5/5 acceptance criteria 達成
- 4 PI (PI-17〜20) 全 done
- divergence detected があれば documented (port-only 追加は許容、source 由来欠落は require fix)
- main へ merge (Phase 5 完了後、α path と同様の squash merge PR)

## risk + mitigation

| risk | mitigation |
|---|---|
| `#print axioms` を 543 theorem 全件で run すると build 時間爆発 | sample-based: 50 critical theorems から始め、後で拡張 |
| port-only 追加 axiom (Day 119/172 拡充) を "divergence" と誤検出 | port_only_allowed list を registry に保持、explicit allow-list pattern |
| source の theorem statement が複雑で hash 比較できない場合 | Lean meta-program で Expr 正規化 (whnf or reduce)、Day 191+ で実装 |
| Mathlib 依存 theorem (Foundation/Probability 等) で `#print axioms` が大量出力 | filter regex で Mathlib-internal axiom を除外 |

## 着手順序

- Day 191: 本 draft 文書化 + PI-17〜20 を pending_items に追加
- Day 192-194: #1 Statement parity audit (PI-17) 実装
- Day 195-198: #2 Axiom dependency parity (PI-18) 実装
- Day 199-201: #3 Equivalence registry (PI-19) 実装
- Day 202-203: #4 CI gate Check 27 (PI-20) 実装
- Day 204: #5 examples 11
- Day 205-206: Phase 5 final audit + main merge PR prep
- Day 207: main merge (Phase 5 close)
