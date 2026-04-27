# API Surface Manifest (Day 175 Phase 3 Theme A1)

`agent-spec-lib` の Public API surface 文書化 + stability classification。
v0.1.0 stable release (Theme A5) 前の API freeze audit。

## Stability Tiers

- **stable**: API freeze 対象、breaking change は major version bump 必要
- **provisional**: experimental、minor version で変更可能
- **internal**: public 利用非推奨、private extension の可能性

## Module Tree (root AgentSpec.lean、79 imports)

### AgentSpec.Core (stable)

| Module | Stability | Notes |
|---|---|---|
| `AgentSpec.Core` | **stable** | SemVer / 基本型 |

### AgentSpec.Spine (stable、Phase 0 Week 2-3 確立)

| Module | Stability | Notes |
|---|---|---|
| `AgentSpec.Spine.FolgeID` | **stable** | identity 型 |
| `AgentSpec.Spine.Edge` | **stable** | edge type lattice |
| `AgentSpec.Spine.EvolutionStep` | **stable** | evolution step |
| `AgentSpec.Spine.SafetyConstraint` | **stable** | safety constraint |
| `AgentSpec.Spine.LearningCycle` | **stable** | learning cycle |
| `AgentSpec.Spine.Observable` | **stable** | observable bridge |

### AgentSpec.Process (stable)

| Module | Stability | Notes |
|---|---|---|
| `AgentSpec.Process.Hypothesis` | **stable** | hypothesis structure |
| `AgentSpec.Process.Failure` | **stable** | failure structure |
| `AgentSpec.Process.Evolution` | **stable** | process evolution |
| `AgentSpec.Process.HandoffChain` | **stable** | handoff chain |

### AgentSpec.Provenance (stable、PROV-O 統合済)

| Module | Stability | Notes |
|---|---|---|
| `AgentSpec.Provenance.Verdict` | **stable** | verification verdict |
| `AgentSpec.Provenance.ResearchAgent` | **stable** | PROV agent |
| `AgentSpec.Provenance.ResearchEntity` | **stable** | PROV entity |
| `AgentSpec.Provenance.ResearchActivity` | **stable** | PROV activity |
| `AgentSpec.Provenance.EvolutionMapping` | **stable** | evolution to PROV |
| `AgentSpec.Provenance.ProvRelation` | **stable** | PROV-O relation |
| `AgentSpec.Provenance.RetiredEntity` | **stable** | retirement |
| `AgentSpec.Provenance.ProvRelationAuxiliary` | **stable** | aux helpers |
| `AgentSpec.Provenance.RetirementLinter` | **stable** | linter |
| `AgentSpec.Provenance.RetirementLinterCommand` | **provisional** | command syntax (lean elab 依存度高) |

### AgentSpec.Manifest (stable、Day 161-171 で 100% port 完成)

| Module | Stability | Notes |
|---|---|---|
| `AgentSpec.Manifest.Ontology` | **stable** | core types (Agent / Action / World / etc) |
| `AgentSpec.Manifest.T1` 〜 `T8` | **stable** | T axioms |
| `AgentSpec.Manifest.E1` 〜 `E3` | **stable** | E axioms |
| `AgentSpec.Manifest.P1` 〜 `P6` | **stable** | P axioms |
| `AgentSpec.Manifest.D` / `D4` / `V` | **stable** | derived |
| `AgentSpec.Manifest.Terminology` | **stable** | terminology |
| `AgentSpec.Manifest.Procedure` | **stable** | procedural |
| `AgentSpec.Manifest.EpistemicLayer` | **stable** | epistemic |
| `AgentSpec.Manifest.Observable` | **stable** | V1-V7 measurable |
| `AgentSpec.Manifest.EmpiricalPostulates` | **stable** | E axioms (port Day 157) |
| `AgentSpec.Manifest.ObservableDesign` | **stable** | observable design (Day 157) |
| `AgentSpec.Manifest.Axioms` | **stable** | additional T axioms (Day 161) |
| `AgentSpec.Manifest.Principles` | **stable** | P axioms (Day 161) |
| `AgentSpec.Manifest.Evolution` | **stable** | evolution (Day 161) |
| `AgentSpec.Manifest.Workflow` | **stable** | workflow (Day 161) |
| `AgentSpec.Manifest.Meta` | **stable** | meta (Day 161) |
| `AgentSpec.Manifest.AxiomQuality` | **stable** | axiom quality (Day 161) |
| `AgentSpec.Manifest.DesignFoundation` | **stable** | DF (Day 165 + 171 root integration) |
| `AgentSpec.Manifest.TaskClassification` | **stable** | task classification (Day 165) |
| `AgentSpec.Manifest.Traceability` | **stable** | traceability (Day 165 + 171) |
| `AgentSpec.Manifest.ConformanceVerification` | **stable** | conformance |
| `AgentSpec.Manifest.EvolveSkill` | **stable** | evolve skill |
| `AgentSpec.Manifest.FormalDerivationSkill` | **stable** | formal derivation |
| `AgentSpec.Manifest.Framework.*` | **stable** | NodeKind / CoTFaithfulness / AcyclicGraph / DanglingDetection / EpistemicBridge / LLMRejection / EpistemicTagging |
| `AgentSpec.Manifest.Models.Assumptions.EpistemicLayer` | **provisional** | model assumption (data-driven、JSON instance 連動) |

### AgentSpec.Tooling (provisional → stable 移行中)

| Module | Stability | Notes |
|---|---|---|
| `AgentSpec.Tooling.AgentVerify` | **provisional** | tactic API、Day 154 PI-11 で二段検索化 (breaking risk あり) |
| `AgentSpec.Tooling.SkillRegistry` | **provisional** | env extension API |
| `AgentSpec.Tooling.SkillVCG` | **provisional** | VCG composite |
| `AgentSpec.Tooling.VerifyToken` | **stable** | IsVerifyToken / TrustDelegation typeclass (Day 154 改修済) |
| `AgentSpec.Tooling.VerifyTokenLoader` | **provisional** | jsonl bridge IO |
| `AgentSpec.Tooling.VerifyTokenMacro` | **provisional** | verify_token macro (Day 154 で syntax 変更済) |
| `AgentSpec.Tooling.CriticalPatterns` | **stable** | hook ↔ Lean sync (Day 153) |
| `AgentSpec.Tooling.MeasurableSemantic` | **provisional** | typeclass、各 m への適用例なし (PI-12 follow-up) |
| `AgentSpec.Tooling.OpaqueOrigin` | **stable** | registry (Day 172 で 32/32 完成) |

### AgentSpec.Proofs (stable)

| Module | Stability | Notes |
|---|---|---|
| `AgentSpec.Proofs.RoundTrip` | **stable** | round-trip proofs |

## API Freeze 結論 (v0.1.0 stable 候補)

### Stable (53 modules、API freeze 対象)

- Core / Spine / Process / Provenance (10 module、`RetirementLinterCommand` 除く)
- Manifest 公理体系 (40 module、`Models.Assumptions` 除く)
- Tooling 部分 (`VerifyToken` / `CriticalPatterns` / `OpaqueOrigin` の 3 module)

### Provisional (10 modules、minor version で変更可能)

- `RetirementLinterCommand` (elab 依存)
- `Models.Assumptions.EpistemicLayer` (data-driven)
- Tooling (`AgentVerify` / `SkillRegistry` / `SkillVCG` / `VerifyTokenLoader` / `VerifyTokenMacro` / `MeasurableSemantic` の 6 module)

### Internal (なし、現状全 import は public 想定)

## Breaking change 履歴 (v0.0.x → v0.1.0-rc1 → v0.1.0)

### Day 154 (PI-11) breaking change

- `IsVerifyToken P` の二段化: `verify_token name : Prop` → `verify_token name "evaluator" : Prop` (TrustDelegation 経由)
- 影響: production 利用ゼロ確認済、smoke test 内部のみ

### Day 162 (Phase 1 #2) compatible_change

- `verificationSound` / `cognitive_separation_required` を Principles.lean から削除 (P2.lean 既存重複)
- 影響: 直接 `import AgentSpec.Manifest.Principles` していた user は経路変更必要

### v0.1.0 release 後の breaking 規律 (Theme A5 後)

- stable 53 module への breaking 変更は major version bump (v0.2.0+) でのみ
- provisional は minor version でも breaking 許容、ただし CHANGELOG 必須記録
- PI-15 (Theme A) で auto-detect 機構を整備
