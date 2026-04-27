import AgentSpec.Provenance.ProvRelation

/-!
# AgentSpec.Test.Provenance.ProvRelationTest: PROV-O 3 relation の behavior test

Day 11 Q3 案 A + Q4 案 A: WasAttributedTo / WasGeneratedBy / WasDerivedFrom の
3 structure (PROV-O 1:1 対応、厳格 type) の検証。
-/

namespace AgentSpec.Test.Provenance.ProvRelation

open AgentSpec.Provenance
open AgentSpec.Process

/-! ### WasAttributedTo (Entity → Agent) -/

/-- 直接構築 -/
example : WasAttributedTo :=
  { entity := .Hypothesis Hypothesis.trivial,
    agent := ResearchAgent.mkResearcher "alice" }

/-- field projection: entity -/
example : ({entity := .Hypothesis Hypothesis.trivial,
             agent := ResearchAgent.trivial} : WasAttributedTo).entity =
          .Hypothesis Hypothesis.trivial := rfl

/-- field projection: agent -/
example : ({entity := .Hypothesis Hypothesis.trivial,
             agent := ResearchAgent.mkVerifier "v1"} : WasAttributedTo).agent =
          ResearchAgent.mkVerifier "v1" := rfl

/-- Smart constructor mk' -/
example : WasAttributedTo.mk' (.Hypothesis Hypothesis.trivial)
            (ResearchAgent.mkReviewer "bob") =
          { entity := .Hypothesis Hypothesis.trivial,
            agent := ResearchAgent.mkReviewer "bob" } := rfl

/-- trivial fixture -/
example : WasAttributedTo.trivial.entity = ResearchEntity.trivial := rfl
example : WasAttributedTo.trivial.agent = ResearchAgent.trivial := rfl

/-- Inhabited instance 解決 -/
example : Inhabited WasAttributedTo := inferInstance

/-! ### WasGeneratedBy (Entity → Activity) -/

/-- 直接構築 -/
example : WasGeneratedBy :=
  { entity := .Hypothesis Hypothesis.trivial,
    activity := .verify Hypothesis.trivial Verdict.proven }

/-- field projection: entity -/
example : ({entity := .Hypothesis Hypothesis.trivial,
             activity := ResearchActivity.trivial} : WasGeneratedBy).entity =
          .Hypothesis Hypothesis.trivial := rfl

/-- field projection: activity (verify variant) -/
example : ({entity := .Hypothesis Hypothesis.trivial,
             activity := .verify Hypothesis.trivial Verdict.refuted}
            : WasGeneratedBy).activity =
          .verify Hypothesis.trivial Verdict.refuted := rfl

/-- Smart constructor mk' -/
example : WasGeneratedBy.mk' (.Hypothesis Hypothesis.trivial)
            ResearchActivity.investigate =
          { entity := .Hypothesis Hypothesis.trivial,
            activity := .investigate } := rfl

/-- trivial fixture: investigate activity 生成 entity -/
example : WasGeneratedBy.trivial.entity = ResearchEntity.trivial := rfl
example : WasGeneratedBy.trivial.activity = ResearchActivity.investigate := rfl

/-- Inhabited instance 解決 -/
example : Inhabited WasGeneratedBy := inferInstance

/-! ### WasDerivedFrom (Entity → Entity) -/

/-- 直接構築: refined hypothesis derived from original hypothesis -/
example : WasDerivedFrom :=
  { entity := .Hypothesis { claim := "refined", rationale := AgentSpec.Spine.Rationale.trivial },
    source := .Hypothesis Hypothesis.trivial }

/-- field projection: entity (derived) -/
example : ({entity := .Hypothesis { claim := "derived", rationale := AgentSpec.Spine.Rationale.trivial },
             source := .Hypothesis Hypothesis.trivial}
            : WasDerivedFrom).entity =
          .Hypothesis { claim := "derived", rationale := AgentSpec.Spine.Rationale.trivial } := rfl

/-- field projection: source (original) -/
example : ({entity := .Hypothesis { claim := "derived", rationale := AgentSpec.Spine.Rationale.trivial },
             source := .Hypothesis Hypothesis.trivial}
            : WasDerivedFrom).source =
          .Hypothesis Hypothesis.trivial := rfl

/-- Smart constructor mk' -/
example : WasDerivedFrom.mk' (.Failure Failure.trivial)
            (.Hypothesis Hypothesis.trivial) =
          { entity := .Failure Failure.trivial,
            source := .Hypothesis Hypothesis.trivial } := rfl

/-- trivial fixture: 同一 entity を source/target に (self-derivation) -/
example : WasDerivedFrom.trivial.entity = ResearchEntity.trivial := rfl
example : WasDerivedFrom.trivial.source = ResearchEntity.trivial := rfl

/-- Inhabited instance 解決 -/
example : Inhabited WasDerivedFrom := inferInstance

/-! ### PROV-O 三項統合: 3 relation 全てが同時利用可能 -/

/-- 3 relation を同一 example で利用 (PROV-O triple set) -/
example :
    let alice := ResearchAgent.mkResearcher "alice"
    let originalHyp := Hypothesis.trivial
    let refinedHyp := { claim := "refined", rationale := AgentSpec.Spine.Rationale.trivial }
    let attribution : WasAttributedTo := .mk' (.Hypothesis refinedHyp) alice
    let generation : WasGeneratedBy := .mk' (.Hypothesis refinedHyp)
                       (.verify originalHyp Verdict.proven)
    let derivation : WasDerivedFrom := .mk' (.Hypothesis refinedHyp)
                       (.Hypothesis originalHyp)
    (attribution.agent = alice) ∧
    (generation.activity = .verify originalHyp Verdict.proven) ∧
    (derivation.source = .Hypothesis originalHyp) := by
  simp [WasAttributedTo.mk', WasGeneratedBy.mk', WasDerivedFrom.mk']

/-! ### Day 30: WasDerivedFrom DAG 制約 (TransDerived / Acyclic) -/

/-- 空 edge list は trivially acyclic -/
example : Acyclic [] := Acyclic.empty

/-- 空 edge list では transitive 派生が存在しない -/
example : ¬ TransDerived [] ResearchEntity.trivial ResearchEntity.trivial :=
  TransDerived.empty_false

/-- 自明な self-loop edge (WasDerivedFrom.trivial) は acyclic でない
    (entity = source = ResearchEntity.trivial) -/
example : ¬ Acyclic [WasDerivedFrom.trivial] := by
  intro h
  exact h ResearchEntity.trivial (TransDerived.base (List.mem_singleton.mpr rfl))

/-- Day 31: TransDerived.subset で大きな edge list に monotone 拡張。
    空 list の derivation は vacuous だが、subset lemma の型整合性を確認。 -/
example {a b : ResearchEntity} (h : TransDerived [] a b) :
    TransDerived [WasDerivedFrom.trivial] a b :=
  TransDerived.subset (fun _ hmem => absurd hmem (by simp)) h

/-- Day 32: Acyclic.subset で edge set 縮小時の acyclicity 保存確認
    (任意 acyclic edges から空 list への縮小は trivially 成立)。 -/
example {edges : List WasDerivedFrom} (h : Acyclic edges) : Acyclic [] :=
  Acyclic.subset (fun _ hmem => absurd hmem (by simp)) h

/-- Day 34: concrete 2-edge TransDerived chain の非 vacuous 実例
    (h3 ← h2 ← h1 の 2 段 transitive closure)。 -/
example :
    let h1 : AgentSpec.Process.Hypothesis := { claim := "h1", rationale := AgentSpec.Spine.Rationale.trivial }
    let h2 : AgentSpec.Process.Hypothesis := { claim := "h2", rationale := AgentSpec.Spine.Rationale.trivial }
    let h3 : AgentSpec.Process.Hypothesis := { claim := "h3", rationale := AgentSpec.Spine.Rationale.trivial }
    let edge1 : WasDerivedFrom := .mk' (.Hypothesis h3) (.Hypothesis h2)
    let edge2 : WasDerivedFrom := .mk' (.Hypothesis h2) (.Hypothesis h1)
    TransDerived [edge1, edge2] (.Hypothesis h3) (.Hypothesis h1) :=
  .trans (.base (List.Mem.head _)) (.base (List.Mem.tail _ (List.Mem.head _)))

/-! ### Day 40: DecidableEq cascade (Day 39 ResearchEntity DecidableEq 連鎖) -/

example : DecidableEq WasAttributedTo := inferInstance
example : DecidableEq WasGeneratedBy := inferInstance
example : DecidableEq WasDerivedFrom := inferInstance

/-- 同一 WasAttributedTo は decide で等号判定可能 -/
example :
    ({entity := ResearchEntity.trivial, agent := ResearchAgent.trivial} : WasAttributedTo) =
    ({entity := ResearchEntity.trivial, agent := ResearchAgent.trivial} : WasAttributedTo) :=
  by decide

/-- 異なる WasDerivedFrom (source 違い) の不等号判定 -/
example :
    ({entity := ResearchEntity.trivial, source := .Hypothesis { claim := "a", rationale := AgentSpec.Spine.Rationale.trivial }} : WasDerivedFrom) ≠
    ({entity := ResearchEntity.trivial, source := .Hypothesis { claim := "b", rationale := AgentSpec.Spine.Rationale.trivial }} : WasDerivedFrom) :=
  by decide

end AgentSpec.Test.Provenance.ProvRelation
