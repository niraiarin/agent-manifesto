# Phase 3 Acceptance Criteria (Day 174 draft)

Day 173 user 質問 (「使い方を解説して」) で抽出された現状の限界 8 件 + Use case 価値順位 (Use case 4 priority) を入力として Phase 3 を計画。Phase 1 (Day 156 draft) と同型の acceptance criteria 5 項目 + theme 別 sub-task 構成。

## 設計方針

Use case 4 (Claude Code governance 転用) を **Phase 3 primary focus** とする。理由:
- Day 173 価値評価で最高 priority
- Lean 非依存 → user adoption 広い
- PI-1〜13 で確立した pattern を reusable artifact として packaging する自然な延長

Theme 構造 (Phase 1 = 5 acceptance criteria pattern):

| Theme | Phase 3 acceptance | 限界対応 |
|---|---|---|
| **A: Stabilization & Release** | API freeze + main merge + v0.1.0 stable tag | L1, L2 |
| **B: Production Polish** | DF theorem port + theorem coverage 50% + production examples | L4, L5, L6 |
| **C: Governance Toolkit Packaging** | install script + governance subpackage 分離 + local pre-commit hook | L7, L8 (Use case 4 priority) |
| **D: Build Improvement** | Mathlib slim profile (optional) | L3 |

## Phase 3 acceptance criteria 5 項目 (proposal)

| # | criterion | 操作的定義 | priority | 工数推定 |
|---|---|---|---|---|
| 1 | **Release stability** | API freeze (breaking change audit) + main merge PR + v0.1.0 stable tag | high | 中 (3-5 Day) |
| 2 | **Production examples** | 5 → 10+ 件、各 use case (1-5) ごと realistic example、Use case 4 governance recipe 含む | high | 中 (3-5 Day) |
| 3 | **Governance toolkit packaging** | `scripts/cycle-check.sh` + `.claude/hooks/` を別 sub-package として分離、`bash install.sh` で別 project に installable | **highest** | 大 (5-7 Day) |
| 4 | **Local CI gate** | pre-commit / pre-push hook で cycle-check 自動起動、GitHub Actions 同等 | medium | 小 (1-2 Day) |
| 5 | **Theorem coverage 拡大** | 32% → 50% (DesignFoundation 70 theorem port を含む) | low | 大 (5-10 Day) |

## Theme 別 sub-task 詳細

### Theme A: Stabilization & Release (3-5 Day)

- A1. API surface audit: root export (AgentSpec.lean) で breaking change risk 列挙
- A2. CHANGELOG finalize (Phase 0 + Phase 1 + Phase 2 全 work 反映、unreleased セクション空)
- A3. CONTRIBUTING.md 新設 (本 project への contribution gateway 文書化)
- A4. main へ merge PR 準備 (commit squash 戦略、conflict 予測)
- A5. v0.1.0 stable tag 切り (lakefile version `v!"0.1.0"` bump)

### Theme B: Production Polish (3-5 Day for examples; 5-10 Day for theorem)

- B1. examples 拡充: 5 → 10+ 件
  - 06: 複数 axiom 組合せ proof (T1 + T6 連動)
  - 07: Tooling chain end-to-end (verify_token macro → agent_verify discharge)
  - 08: governance recipe (Use case 4: cycle-check 自前実装例)
  - 09: PI-11 TrustDelegation real-world pattern (subagent attestation)
  - 10: agent infrastructure formalization (Manifest 公理 1 setup)
- B2. DesignFoundation 70 theorem の port 側 derive (research-side コピーで PoC)
- B3. theorem coverage 32% → 50% (313 theorem 追加 port、scope 大なら部分実施)

### Theme C: Governance Toolkit Packaging (5-7 Day)

- C1. `governance/` 新 sub-package 作成 (`agent-spec-lib/governance/`)
- C2. `scripts/cycle-check.sh` を governance/ に移動、Lean 依存箇所を切り離し
- C3. `.claude/hooks/p2-verify-on-commit.sh` 等を governance/hooks/ に整理
- C4. `governance/install.sh` 新設: 別 project の `.claude/` に hooks + scripts を install
- C5. README + USAGE 文書: PI-1〜13 pattern を governance toolkit として説明
- C6. **PI-14 (新 PI 候補)**: governance toolkit acceptance test (3 例 project に install して動作確認)

### Theme D: Build Improvement (optional、後回し)

- D1. lakefile に Mathlib subset profile (skip 未使用 module、build 時間短縮)
- D2. Mathlib v4.30+ への upgrade 試行 (現 v4.29.0)

## 新 PI (process improvement) 候補

Phase 3 で導入 / 拡張する process improvement:

| 新 PI | 内容 | tier |
|---|---|---|
| **PI-14** | governance toolkit acceptance test (Theme C 必須) | C |
| **PI-15** | API breaking change auto-detect (Theme A 必須、Day cycle で自動 audit) | A |
| **PI-16** | examples の compile gate を CI に組込み (Theme B 副次効果) | B |

## 工数 estimate

| Theme | Day 数 | 完了予測 (Day 174 起算) |
|---|---|---|
| A (release) | 3-5 | Day 178 |
| B (examples + theorem subset) | 3-5 + (optional) | Day 182 + |
| C (governance toolkit) | 5-7 | Day 184 |
| D (build) | optional | — |

**最短 Phase 3 完了 (A + B examples + C)**: Day 174 → Day 184 = 10 Day

## 提案

5 項目を全部やるか、subset を選ぶか:

| 選択 | 内容 |
|---|---|
| **(α) Full 5 criteria** | A + B (full) + C + D = 15-20 Day |
| **(β) Practical 4 criteria** | A + B (examples のみ) + C + (D optional) = 8-12 Day |
| **(γ) Minimal 3 criteria** | A + C + (B examples 副次) = 6-8 Day |
| **(δ) Governance focus** | C only (Use case 4 最重視) + A 部分 = 5-7 Day |

**私の推奨: (β) Practical 4 criteria**
- Use case 4 (governance toolkit) を確実に packaging
- examples 拡充で user adoption barrier 低下
- DesignFoundation theorem port は workload 大きい割に user value 限定 (research-side で参照可)
- v0.1.0 stable で release narrative 完成

## user 確認

- (α) (β) (γ) (δ) どれを採用するか
- 他に Phase 3 に含めたい工数 (例: 別 research priority 分岐) があれば
