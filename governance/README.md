# Governance Toolkit (Day 176-177 Phase 3 Theme C)

agent-manifesto プロジェクトで確立された Claude Code governance pattern を、
別 project に転用可能な形で packaging したもの。Lean 非依存、bash + jq + git のみ。

## 提供する governance 規律 (PI-1〜PI-16 のうち Lean 非依存分)

- **L1 安全境界 enforcement**: `.claude/hooks/l1-file-guard.sh` + `l1-safety-check.sh`
  - 秘密ファイル (`.env`, `.pem`, credentials) への書き込み block
  - test file 内の `skip` / `pending` / `xit` / `xdescribe` パターン block
  - destructive command (`rm -rf`, `git push --force`) の事前 confirmation 強制
- **P2 verification 強制**: `.claude/hooks/p2-verify-on-commit.sh`
  - commit 時に `.claude/metrics/p2-verified.jsonl` に valid token がない高 risk file は block
  - critical files (`.claude/hooks/`, `.claude/settings.json`) は `evaluator_independent: true` token 必須
- **Cycle hygiene check**: `scripts/cycle-check.sh` (Check 1-24)
  - Manifest 整合 / commit hash format / 9-step cycle coverage
  - PI-1 pass_layers / PI-2 N連敗 / PI-3 deadline / PI-6 retro / PI-10 hook sync
- **Doc length lint**: `scripts/check-doc-length.sh`
  - markdown / docstring 過剰行数の警告

## Installation

```bash
git clone https://github.com/<owner>/agent-manifesto.git
cd agent-manifesto/governance
bash install.sh /path/to/your-project
```

詳細は `install.sh` の usage を参照。

## Compatibility

- bash 4+
- jq 1.6+
- git
- shasum (macOS) or sha256sum (Linux)

## このパターンの設計根拠

詳細は agent-manifesto 本体の以下文書:
- `lean-formalization/Manifest/DesignFoundation.lean` の `VerificationIndependence` (P2 4 条件)
- `docs/research/new-foundation-survey/usecases/01-current-usecases.md` (現状の use case)
- `docs/research/new-foundation-survey/phase-transitions/03-phase3-acceptance-draft.md` (Phase 3 計画)

## Use case 4 で最も価値が高い理由

`hooks + cycle-check による Claude Code governance pattern` は、別 project で:
- LLM agent (Claude Code) の動作を構造的に制約する仕組みが欲しいとき
- self-evaluation バイアスを排除したいとき
- L1 安全境界を auto-enforce したいとき
にそのまま転用可能。Lean 4 / Mathlib に依存しないため adoption barrier が低い。

## Limitations (Day 176 時点)

- governance toolkit acceptance test (PI-14) 未実施 — 3 例 project への install 動作確認は未完
- USAGE.md 詳細 walkthrough 未整備 (Day 177 予定)
- artifact-manifest.schema.json template は未提供 (project-specific のため)

## Roadmap

- Day 177: USAGE.md (runtime workflow walkthrough)
- Day 178-179: PI-14 acceptance test (3 例 project に install + 動作確認)
- v0.1.0 release 時に governance toolkit も同時 freeze
