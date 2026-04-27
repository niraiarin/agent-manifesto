import AgentSpec.Provenance.ProvRelationAuxiliary

/-!
# AgentSpec.Test.Provenance.ProvRelationAuxiliaryTest: PROV-O auxiliary + WasRetiredBy 3 relation の behavior test

Day 13 Q1 A-Minimal + Q3 案 B + Q4 案 A: WasInformedBy / ActedOnBehalfOf / WasRetiredBy の
3 structure (PROV-O §4.1 auxiliary + §4.4 retirement relation、Day 11 ProvRelation パターン踏襲) の検証。

Day 11 Subagent I3 教訓継続適用 (cycle 内学習 transfer 2 度目): 全 example で rfl preference 維持
(simp tactic 不使用、Day 12 RetiredEntityTest と同パターン)。
-/

namespace AgentSpec.Test.Provenance.ProvRelationAuxiliary

open AgentSpec.Provenance
open AgentSpec.Process

/-! ### `WasInformedBy` (Activity → Activity) -/

/-- 直接構築: verify activity が investigate activity から通知された関係 -/
example : WasInformedBy :=
  { activity := .verify Hypothesis.trivial Verdict.proven,
    informer := .investigate }

/-- field projection: activity (informee) -/
example : ({activity := .verify Hypothesis.trivial Verdict.proven,
             informer := ResearchActivity.trivial} : WasInformedBy).activity =
          .verify Hypothesis.trivial Verdict.proven := rfl

/-- field projection: informer -/
example : ({activity := ResearchActivity.trivial,
             informer := .investigate} : WasInformedBy).informer =
          .investigate := rfl

/-- Smart constructor mk' -/
example : WasInformedBy.mk' (.verify Hypothesis.trivial Verdict.proven) .investigate =
          { activity := .verify Hypothesis.trivial Verdict.proven,
            informer := .investigate } := rfl

/-- trivial fixture -/
example : WasInformedBy.trivial.activity = ResearchActivity.trivial := rfl
example : WasInformedBy.trivial.informer = ResearchActivity.trivial := rfl

/-- Inhabited instance 解決 -/
example : Inhabited WasInformedBy := inferInstance

/-! ### `ActedOnBehalfOf` (Agent → Agent) -/

/-- 直接構築: Reviewer Agent が Researcher Agent の代理として行動した関係 -/
example : ActedOnBehalfOf :=
  { agent := ResearchAgent.mkReviewer "bob",
    on_behalf_of := ResearchAgent.mkResearcher "alice" }

/-- field projection: agent (delegate) -/
example : ({agent := ResearchAgent.mkReviewer "bob",
             on_behalf_of := ResearchAgent.trivial} : ActedOnBehalfOf).agent =
          ResearchAgent.mkReviewer "bob" := rfl

/-- field projection: on_behalf_of (delegator) -/
example : ({agent := ResearchAgent.trivial,
             on_behalf_of := ResearchAgent.mkResearcher "alice"}
            : ActedOnBehalfOf).on_behalf_of =
          ResearchAgent.mkResearcher "alice" := rfl

/-- Smart constructor mk' -/
example : ActedOnBehalfOf.mk' (ResearchAgent.mkReviewer "bob")
            (ResearchAgent.mkResearcher "alice") =
          { agent := ResearchAgent.mkReviewer "bob",
            on_behalf_of := ResearchAgent.mkResearcher "alice" } := rfl

/-- trivial fixture -/
example : ActedOnBehalfOf.trivial.agent = ResearchAgent.trivial := rfl
example : ActedOnBehalfOf.trivial.on_behalf_of = ResearchAgent.trivial := rfl

/-- Inhabited instance 解決 -/
example : Inhabited ActedOnBehalfOf := inferInstance

/-! ### `WasRetiredBy` (Entity → RetiredEntity) -/

/-- 直接構築: Hypothesis entity が Failure 経由で退役された関係 -/
example : WasRetiredBy :=
  { entity := .Hypothesis Hypothesis.trivial,
    retired := RetiredEntity.refuted (.Hypothesis Hypothesis.trivial) Failure.trivial AgentSpec.Spine.Rationale.trivial }

/-- 直接構築: trivial entity が Obsolete 退役された関係 (trivial fixture と同等) -/
example : WasRetiredBy :=
  { entity := ResearchEntity.trivial, retired := RetiredEntity.trivial }

/-- field projection: entity (退役元) -/
example : ({entity := .Hypothesis Hypothesis.trivial,
             retired := RetiredEntity.trivial} : WasRetiredBy).entity =
          .Hypothesis Hypothesis.trivial := rfl

/-- field projection: retired (Day 12 RetiredEntity record) -/
example : ({entity := ResearchEntity.trivial,
             retired := RetiredEntity.trivial} : WasRetiredBy).retired =
          RetiredEntity.trivial := rfl

/-- Smart constructor mk' -/
example : WasRetiredBy.mk' (.Hypothesis Hypothesis.trivial)
            (RetiredEntity.refuted (.Hypothesis Hypothesis.trivial) Failure.trivial AgentSpec.Spine.Rationale.trivial) =
          { entity := .Hypothesis Hypothesis.trivial,
            retired := RetiredEntity.refuted (.Hypothesis Hypothesis.trivial) Failure.trivial AgentSpec.Spine.Rationale.trivial } := rfl

/-- trivial fixture -/
example : WasRetiredBy.trivial.entity = ResearchEntity.trivial := rfl
example : WasRetiredBy.trivial.retired = RetiredEntity.trivial := rfl

/-- Inhabited instance 解決 -/
example : Inhabited WasRetiredBy := inferInstance

/-! ### entity 重複参照 accessor pattern (Q4 案 A 設計確認) -/

/-- Day 13 D2 設計確認: WasRetiredBy.entity と WasRetiredBy.retired.entity が同一 entity を指す
    場合 (典型的な使用パターン)、両者の参照が一致することを確認。 -/
example :
    let h := ResearchEntity.trivial
    let r := WasRetiredBy.mk' h (RetiredEntity.obsolete h AgentSpec.Spine.Rationale.trivial)
    r.entity = r.retired.entity := rfl

/-! ### Day 11 + Day 13 PROV-O 6 relation 統合 example (内部規範 layer 横断 transfer 8 段階目) -/

/-- Day 11 main 3 relation + Day 13 auxiliary 2 + WasRetiredBy 1 = PROV-O 6 relation を List で集約
    (Day 11 PROV-O triple set 統合 example の拡張、Day 12 4 RetirementReason List 集約に続く 8 段階目) -/
example :
    let alice := ResearchAgent.mkResearcher "alice"
    let bob := ResearchAgent.mkReviewer "bob"
    let h := ResearchEntity.trivial
    -- Day 13 auxiliary + retirement relation 3 種を構築
    let informedBy := WasInformedBy.mk' (.verify Hypothesis.trivial Verdict.proven) .investigate
    let onBehalf := ActedOnBehalfOf.mk' bob alice
    let retiredBy := WasRetiredBy.mk' h (RetiredEntity.obsolete h AgentSpec.Spine.Rationale.trivial)
    -- 3 relation の field projection が想定通り動作
    (informedBy.informer = .investigate) ∧
    (onBehalf.on_behalf_of = alice) ∧
    (retiredBy.retired.entity = h) := by
  refine ⟨rfl, rfl, ?_⟩
  rfl

/-! ### Day 40: DecidableEq cascade (Day 39 ResearchEntity + RetiredEntity 連鎖) -/

example : DecidableEq WasInformedBy := inferInstance
example : DecidableEq ActedOnBehalfOf := inferInstance
example : DecidableEq WasRetiredBy := inferInstance

/-- 同一 WasInformedBy の等号判定 -/
example :
    WasInformedBy.trivial = WasInformedBy.trivial := by decide

/-- 異なる WasRetiredBy (retired reason 違い) の不等号判定 -/
example :
    ({entity := ResearchEntity.trivial,
      retired := { entity := ResearchEntity.trivial, reason := .Obsolete, rationale := AgentSpec.Spine.Rationale.trivial }} : WasRetiredBy) ≠
    ({entity := ResearchEntity.trivial,
      retired := { entity := ResearchEntity.trivial, reason := .Withdrawn, rationale := AgentSpec.Spine.Rationale.trivial }} : WasRetiredBy) :=
  by decide

end AgentSpec.Test.Provenance.ProvRelationAuxiliary
