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

## [Unreleased] — Phase 2 完了 (Day 171-173)

### Added (Phase 2 work)

- **DF root integration** (Day 171): D.lean ↔ DesignFoundation の cross-file 重複 70 symbol を解消、`import AgentSpec.Manifest.DesignFoundation/TaskClassification/Traceability` が root 経由で利用可能
- **OpaqueOrigin registry 拡充** (Day 172): 10 → 32 entry、Ontology の opaque 全件を semantic origin tag でカバー (PI-13 完成)
- **examples 拡充** (Day 173): 4 → 5 件 (`05_design_foundation_root.lean` 追加)
- lake build 432 PASS、Manifest 100% root accessible

### Phase 2 NOT goals (Phase 3 候補)

- Theorem coverage 100% port (現 32%)
- Tooling 層の semantic 保証強化拡大 (PI-12 / PI-13 follow-up)
- 別 research priority への分岐

## [Unreleased] — 0.1.0 stable に向けて

- 本 worktree (research/new-foundation) を main へ merge (PR)
- v0.1.0 stable tag (現 v0.1.0-rc1 維持)
