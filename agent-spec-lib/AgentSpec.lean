import AgentSpec.Core
import AgentSpec.Spine.FolgeID
import AgentSpec.Spine.Edge
import AgentSpec.Spine.EvolutionStep
import AgentSpec.Spine.SafetyConstraint
import AgentSpec.Spine.LearningCycle
import AgentSpec.Spine.Observable
import AgentSpec.Process.Hypothesis
import AgentSpec.Process.Failure
import AgentSpec.Process.Evolution
import AgentSpec.Process.HandoffChain
import AgentSpec.Provenance.Verdict
import AgentSpec.Provenance.ResearchAgent
import AgentSpec.Provenance.ResearchEntity
import AgentSpec.Provenance.ResearchActivity
import AgentSpec.Provenance.EvolutionMapping
import AgentSpec.Provenance.ProvRelation
import AgentSpec.Provenance.RetiredEntity
import AgentSpec.Provenance.ProvRelationAuxiliary
import AgentSpec.Provenance.RetirementLinter
import AgentSpec.Provenance.RetirementLinterCommand
import AgentSpec.Proofs.RoundTrip
import AgentSpec.Manifest.Ontology
import AgentSpec.Manifest.T1
import AgentSpec.Manifest.T2
import AgentSpec.Manifest.T3
import AgentSpec.Manifest.T4
import AgentSpec.Manifest.T5
import AgentSpec.Manifest.T6
import AgentSpec.Manifest.T7
import AgentSpec.Manifest.T8
import AgentSpec.Manifest.E1
import AgentSpec.Manifest.E2
import AgentSpec.Manifest.E3
import AgentSpec.Manifest.P1
import AgentSpec.Manifest.P2
import AgentSpec.Manifest.P3
import AgentSpec.Manifest.P4
import AgentSpec.Manifest.P5
import AgentSpec.Manifest.P6
import AgentSpec.Manifest.D4
import AgentSpec.Manifest.V
import AgentSpec.Spine.ResearchSpecLattice

-- Test modules は AgentSpecTest.lean に分離 (Week 2 Day 2)
-- → `lake build AgentSpecTest` で test lib をビルドする

/-!
# AgentSpec: agent-manifesto 新基盤 Lean ライブラリ ルート

agent-manifesto プロジェクトの研究プロセス記録を、GitHub Issue 依存から脱却し、
Lean 言語による型安全な tree structure + 半順序関係 + traceability 保証に再設計する。

## 設計根拠

- `docs/research/new-foundation-survey/00-synthesis.md`: サーベイ統合まとめ
- `docs/research/new-foundation-survey/10-gap-analysis.md`: Gap Analysis (104 Gap + 10 Warning、Verifier 3 ラウンド PASS)
- `research/survey_type_driven_development_2025.md`: TyDD サーベイ
- `research/lean4-handoff.md`: Lean 4 学習 handoff

## Phase 0 構成（G5-1 Section 3.5 の 8 週ロードマップ）

- **Week 1 (現状)**: 環境準備 — `lakefile.lean`, `lean-toolchain`, 最小 `Core.lean`
- Week 2-3: Spine 層 — EvolutionStep, SafetyConstraint, LearningCycle, Observable
- Week 3-4: Manifest 移植 — T1-T8, P1-P6 を AgentSpec/Manifest/ 配下へ
- Week 4-5: Process 層 — Hypothesis, Failure, Evolution, HandoffChain
- Week 5-6: Tooling 層 — `agent_verify` tactic, `VcForSkill` VCG, SMT hammer bridge
- Week 6-7: CI 整備
- Week 7-8: 既存 theorems 再証明 + CLEVER 風自己評価

## 高リスク Gap の実装順序（GA- タグ参照）

**型基盤 (Week 2-3)**:
- GA-S1 (ResearchNode umbrella) ← Week 2 着手
- GA-S2 (FolgeID) / GA-S4 (Edge Type) ← Week 2
- GA-S3 (Provenance Triple) ← Week 3
- GA-S5 (Retirement) / GA-S6 (Failure) / GA-S8 (Rationale) ← Week 4

**能力層 (Week 5-6)**:
- GA-C7 (SMT hammer 統合)
- GA-C9 (EnvExtension Auto-Register)

詳細な Gap 一覧は `docs/research/new-foundation-survey/10-gap-analysis.md` 参照。
-/
