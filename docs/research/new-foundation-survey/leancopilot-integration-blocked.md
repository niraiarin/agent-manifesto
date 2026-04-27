# LeanCopilot Integration: Blocked with Cause (Day 210, Phase 7 sprint 1 #3)

Phase 7 sprint 1 acceptance #3 per `12-phase7-plan.md`:
> `LeanCopilot` integration attempted with explicit outcome: `integrated` or `blocked with cause`.

**Outcome: blocked.**

## Cause

| 項目 | agent-spec-lib | LeanCopilot |
|---|---|---|
| Lean toolchain | `leanprover/lean4:v4.29.0` | `leanprover/lean4:v4.28.0` |
| Mathlib version | v4.29.0 | implied v4.28.0 (matches toolchain) |
| Latest tag | (本 project) | v4.28.0 (2026-02-16) |
| Latest main commit | (本 project) | bbecd66 (2026-02-17) |
| Version lag | — | 1 minor version, ~2 ヶ月停滞 |

Direct ecosystem incompatibility: LeanCopilot does not support Lean v4.29.0 as of Day 210 (2026-04-27). Cross-version `require` would conflict with mathlib4 v4.29.0 (Duper / Aesop の v4.29.0 tag と inconsistent state)。

## Investigation 経路

1. `https://raw.githubusercontent.com/lean-dojo/LeanCopilot/main/lean-toolchain` → `leanprover/lean4:v4.28.0`
2. `https://api.github.com/repos/lean-dojo/LeanCopilot/tags` → 最新 `v4.28.0`、`v4.29.0` tag なし
3. `https://api.github.com/repos/lean-dojo/LeanCopilot/branches` → `main`, `stable` のみ、v4.29.0 branch なし
4. Recent commits: 2026-02-17 が最新、以後 stagnant

## Resolution Options (将来 sprint 候補)

### Option A: Wait for upstream (推奨)

LeanCopilot v4.29.0 release を待つ。pros: zero work、自然な ecosystem sync。cons: timing 不確定 (upstream maintainer 依存、最終 commit から 2+ months stagnant が懸念)。

### Option B: Downgrade agent-spec-lib to v4.28.0

mathlib v4.28.0 + Aesop / Duper の v4.28.0 tag に全 dep を rollback。pros: LeanCopilot 即時利用可能。cons: **breaking change** (525 byte-identical port equivalence test、PI-19 SemanticEquivalence registry 等が v4.29.0 base で確立)、Phase 5/6 累積 main commits の整合性破壊リスク。**推奨しない**。

### Option C: Pin LeanCopilot main HEAD with version override

`require LeanCopilot from git ... @ "main"` + Lean version override (`@[default_target]` で別 toolchain)。pros: nightly track 可能。cons: native lib build (CTranslate2, OpenNMT) と Lean version 不整合で link error 確実、unstable nightly 依存 → CI 不安定化。**Phase 7 sprint 1 scope では NG**。

### Option D: Skip LeanCopilot, use Aesop + Duper のみ

Phase 7 sprint 1 のうち #3 を defer、#1 (Aesop) + #2 (Duper) のみで sprint 1 acceptance partial 達成。pros: 既存実装活用。cons: 3-tier tool comparison (Aesop / Duper / LeanCopilot) の baseline data 不完全。

## 決定

**Option A (wait) + Option D (parallel skip)** を採用:

- Phase 7 sprint 2 / 3 は Aesop + Duper の 2-tier baseline で進める
- LeanCopilot は backlog (PI-24 Lean 4.30 upgrade 評価時に同時再検証)
- Phase 7 sprint 1 #3 acceptance は "blocked with cause documented" で satisfied

## PI Cross-reference

- PI-23 (Mathlib slim profile): independent、本 blockage に影響なし
- PI-24 (Lean 4.30 upgrade): LeanCopilot 同期 timing と coupling、Phase 7 sprint 後 evaluation 候補
- PI 候補 (新規 Day 210): "ecosystem dependency version lag tracking" (Aesop / Duper / LeanCopilot / Mathlib の version sync 状態を quarterly で audit)

## References

- LeanCopilot: https://github.com/lean-dojo/LeanCopilot
- LeanCopilot v4.28.0 release: https://github.com/lean-dojo/LeanCopilot/releases/tag/v4.28.0
- Lean v4.29.0 release: https://github.com/leanprover/lean4/releases/tag/v4.29.0
- Phase 7 plan: docs/research/new-foundation-survey/12-phase7-plan.md
