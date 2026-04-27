# 現状 (v0.1.0-rc1) の use case 一覧

Day 173 user 質問 (「使い方を解説して」) への回答を文書化。Phase 3 計画 (`docs/research/new-foundation-survey/phase-transitions/03-phase3-acceptance-draft.md`) の入力。

## プロジェクト全体像 (3 層構造)

| 層 | 中身 | 主な用途 |
|---|---|---|
| **agent-manifesto** (規範層) | T1-T8 / P1-P6 / L1-L6 / V1-V7 / D1-D18 の axiom system | LLM agent 設計の公理体系 (人間が読む規範書) |
| **agent-spec-lib** (型表現層) | 上記公理を Lean 4 で型として実装 | proof-as-code、agent infrastructure 設計時の型レベル制約 |
| **.claude/** (運用層) | hooks + skills + cycle-check + p2-verify | Claude Code セッション内で公理体系を強制する仕組み |

## Use case 一覧 (5 件)

### Use case 1: agent-spec-lib を Lean library として使う

別 project で agent 設計を formalize するとき。`import AgentSpec` で公理 + theorem 全 import、Lean type system で agent infrastructure の型レベル制約を表現。

セットアップ: lakefile に `require «agent-spec-lib» from git ...` 追加。

### Use case 2: agent_verify tactic で外部 attestation を proof として扱う

P2 verification (independent verifier) の結果を `TrustDelegation` typeclass + named axiom 経由で Lean type system に取り込み、`agent_verify` tactic で auto discharge。`#print axioms` で provenance 透明。

### Use case 3: opaque def の semantic origin を query

`AgentSpec.Tooling.OpaqueOrigin.opaqueOriginRegistry` に Ontology 全 32 opaque def の (name, origin, description) が typed list で利用可能。docstring grep ではなく typed lookup。

### Use case 4: Claude Code 運用に cycle-check / hooks を転用

別 project の Claude Code セッションに governance を導入。`scripts/cycle-check.sh` (Check 1-24) + `.claude/hooks/p2-verify-on-commit.sh` を template として copy、PI-1〜13 で確立した process improvement を別 project に再利用可能。

### Use case 5: agent-manifesto を design reference として読む

LLM agent 設計議論で「この設計は T6 を満たしているか?」を共通語彙として使う。規範書 (lean-formalization/Manifest.lean) + 解説 (docs/design-development-foundation.md) + Gap Analysis (docs/research/new-foundation-survey/10-gap-analysis.md)。

## 価値順位 (Day 173 主観評価)

1. **Use case 4** (Claude Code governance 転用) — 別 project 直接転用可、Lean 非依存
2. **Use case 1** (Lean library) — 限定的だが coherent
3. **Use case 5** (design reference) — 議論共通語彙として有用
4. **Use case 2/3** (Tooling) — niche、Lean 提案層 user 限定

## 現状の限界 (Phase 3 work 候補)

| # | 限界 | 状態 | Phase 3 候補? |
|---|---|---|---|
| L1 | API stable ではない | v0.1.0-rc1、breaking change 可能性あり | ✓ Theme A |
| L2 | main merge 前 | research/new-foundation branch のみ | ✓ Theme A |
| L3 | Mathlib heavy dependency | 初回 build 時間 + disk 使用量大 | ✓ Theme D (optional) |
| L4 | examples が trivial | 5 件は demo 用、production code レベルではない | ✓ Theme B |
| L5 | DF 70 theorem は research-side のみ | port 側は def/structure のみ | ✓ Theme B |
| L6 | theorem coverage 32% | 1670 中 526 が port、残 1144 は research のみ | ✓ Theme B (部分) |
| L7 | CI gate は GitHub Actions のみ | local pre-commit hook 未提供 | ✓ Theme C |
| L8 | governance toolkit が template only | install script / packaging なし | ✓ Theme C (Use case 4 priority 起因) |
