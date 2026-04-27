# agent-spec-lib CHANGELOG

[Keep a Changelog](https://keepachangelog.com/) 形式 + [Semantic Versioning](https://semver.org/)。
互換性分類は P3 学習統治規律 (conservative_extension / compatible_change / breaking_change) に準拠。

## [0.1.0-rc1] — 2026-04-27 (Day 162)

### Added (Phase 0 sprint 完了範囲)

- **Manifest 公理体系**: T1-T8, P1-P6, L1-L6 (BoundaryId 内), V1-V7, D1-D18, E1-E3 を AgentSpec.Manifest 配下に port 完了 (47 source-only file 中 44 = 94%)
  - residual 3 file (DesignFoundation.lean / TaskClassification.lean / Traceability.lean) は DF chain として Phase 2 defer
- **Tooling 層** (Day 125-160): AgentVerify tactic, SkillRegistry, SkillVCG, IsVerifyToken / TrustDelegation 二分岐, VerifyTokenLoader (jsonl bridge), VerifyTokenMacro, CriticalPatterns (hook sync), MeasurableSemantic, OpaqueOrigin registry
- **Process Improvement (PI-1〜PI-13)**: 13 項目完了 (Day 148-160)、自己評価バイアス削減 / cycle 構造修正 / Lean 形式系 semantic 補強

### Public API surface (Phase 1 acceptance #2)

`import AgentSpec` で以下が一括 import される (詳細 `AgentSpec.lean` 参照):
- 全 Manifest 公理 + 派生定理 (Ontology / T1-T8 / P1-P6 / D1-D18 / V / E1-E3 / Procedure / Terminology 等)
- Tooling layer (agent_verify tactic, IsVerifyToken / TrustDelegation typeclass, VerifyTokenLoader IO)
- Spine layer (FolgeID, Edge, EvolutionStep, SafetyConstraint, LearningCycle, Observable)
- Provenance layer (Verdict, ResearchAgent, ResearchEntity, ResearchActivity, EvolutionMapping, ProvRelation, RetiredEntity, RetirementLinter)
- Process layer (Hypothesis, Failure, Evolution, HandoffChain)

### Build & verification

- `lake build` PASS (429 jobs)
- 0 sorry, 0 native_decide (Day 153 PI-9 で全撤去)
- axiom 86, theorem 428+ (Day 161 surge: +11 axiom / +67 theorem)

### Known limitations (Phase 1 移行前 review 候補)

- DesignFoundation.lean (1952 LOC) の Lean port 未完 — 公理体系の意味的 metadata は本 lib 内 def で代替可能、形式定理は research 用 lean-formalization/Manifest/DesignFoundation.lean を参照
- examples/ 未整備 (Phase 1 acceptance #3)
- CI gate (GitHub Actions) 未稼働 (Phase 1 acceptance #5)

## [0.1.0-rc2] — Phase 2 完了 (Day 171-173)

### Added (Phase 2 work)

- **DF root integration** (Day 171): D.lean ↔ DesignFoundation の cross-file 重複 70 symbol を解消、`import AgentSpec.Manifest.DesignFoundation/TaskClassification/Traceability` が root 経由で利用可能
- **OpaqueOrigin registry 拡充** (Day 172): 10 → 32 entry、Ontology の opaque 全件を semantic origin tag でカバー (PI-13 完成)
- **examples 拡充** (Day 173): 4 → 5 件 (`05_design_foundation_root.lean` 追加)
- lake build 432 PASS、Manifest 100% root accessible

## [0.1.0] — 2026-04-27 (Day 188 stable release)

Phase 3 (α) Full criteria + Phase 4 完了、production-ready 状態に到達。

### Added (Phase 3 + 4 累積)

- **API_SURFACE.md** (Day 175): 79 module を stable 53 / provisional 10 に分類、breaking 履歴記録
- **CONTRIBUTING.md** (Day 175): 互換性分類 + PI 規律 16 件 + workflow guide
- **governance/ sub-package** (Day 176-178、Phase 3 Theme C):
  - `install.sh`: 別 project に hooks + scripts を deploy
  - `scripts/cycle-check.sh` + `check-doc-length.sh`
  - `hooks/{l1-file-guard, l1-safety-check, p2-verify-on-commit}.sh`
  - `templates/pre-commit-hook.sh` (Day 179)
  - `README.md` + `USAGE.md` (Day 176-177)
  - 3 例 install acceptance PASS (PI-14)
- **examples 5 → 10 件** (Day 178、Phase 3 Theme B):
  - `06_axiom_combination` (T1+T6 axiom 連動)
  - `07_tooling_chain_e2e` (IsVerifyToken + agent_verify + OpaqueOrigin)
  - `08_governance_recipe` (Use case 4 Lean side reference)
  - `09_trust_delegation_pattern` (TrustDelegation + named axiom)
  - `10_agent_infrastructure` (BoundaryLayer + canTransition)
- **Foundation 6/6 port** (Day 183、Phase 4 γ):
  - ControlTheory, InformationTheory, ProcessModel, StatisticalTesting (no mathlib)
  - Probability (Mathlib.Probability + Log)
  - RiskTheory (Mathlib.Order.Monotone)
  - 17 theorem 追加
- **PI-12 follow-up** (Day 184): V1-V7 MeasurableSemantic instances (named axiom 経由、`#print axioms` で attestation 追跡可能)
- **PI-13 follow-up** (Day 185): cycle-check Check 26 (OpaqueOrigin registry coverage 100% enforce)
- **PI-15** (Day 181-182): cycle-check Check 25 (API surface drift detection)
- **PI-16** (Day 186): CI workflow に examples compile を strict mode 組込

### Process Improvement (PI 16/16 = 100% done)

- PI-1 pass_layers field、PI-2 failed_attempt + Check 21、PI-3 decision_deadline + Check 22
- PI-4 Step 3 PoC + TyDD eval 分割、PI-5 1 commit/Day 化、PI-6 weekly_retro + Check 23
- PI-7 Phase 0 chronological gate (Day 155 + 170 audit 2 回完遂)
- PI-8 change_category subagent 委譲 (Day 158+ 全 entry で適用)
- PI-9 native_decide 撤去 (11 occurrence 全置換)
- PI-10 Hook ↔ Lean criticalPatterns sync + Check 24
- PI-11 IsVerifyToken / TrustDelegation 二分岐
- PI-12 + PI-13 + PI-14 + PI-15 + PI-16 (Phase 3+4 で完成)

### Build & verification

- lake build: **2056 jobs PASS**
- sorry: 0
- native_decide tactic: 0
- cycle-check Check 1-26: 全 PASS
- examples 10 件: 全 compile PASS
- governance install: 3 例 acceptance PASS

### Known limitations (Phase 5 候補)

- Models 1169 JSON fixture port は production 価値 very low、defer
- Mathlib slim profile 未着手 (Probability 1965 transitive build jobs)
- AgentSpecTest 拡充は Phase 5 以降

### Migration from 0.1.0-rc1 / rc2

- breaking change なし (Phase 3+4 全て additive / process_only)
- API_SURFACE.md の stable 53 module は freeze 対象、major version bump (v0.2.0+) で変更
- provisional 10 module は minor version で変更可能

## [Unreleased] — 次 release (v0.1.1 or v0.2.0)

- Phase 5 候補 (user direction 次第):
  - α completed (本 release で v0.1.0 達成)
  - δ Models port (defer 維持推奨)
  - ε 別 research priority
  - ζ examples 11-20
  - η Mathlib slim profile
  - θ AgentSpecTest 拡充
