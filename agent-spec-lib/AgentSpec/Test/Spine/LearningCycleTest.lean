import AgentSpec.Spine.LearningCycle
import AgentSpec.Spine.Observable

/-!
# AgentSpec.Test.Spine.LearningCycleTest: LearningCycle type class の behavior test

Day 4 hole-driven: LearningStage enum + transition validity + class の基本性質を
Unit instance で検証。Day 3 評価 A2 (cross-class test 欠落) への対処として
`[EvolutionStep S] [SafetyConstraint S] [LearningCycle S]` 同時要求 example も含む。
-/

universe u

namespace AgentSpec.Test.Spine.LearningCycle

open AgentSpec.Spine

/-! ### LearningStage の next 動作 -/

example : LearningStage.observation.next = LearningStage.hypothesis := rfl
example : LearningStage.hypothesis.next = LearningStage.verification := rfl
example : LearningStage.verification.next = LearningStage.integration := rfl
example : LearningStage.integration.next = LearningStage.retirement := rfl

/-- terminal stage (retirement) は self-loop -/
example : LearningStage.retirement.next = LearningStage.retirement := rfl

/-! ### LearningStage.le 順序関係 -/

/-- observation は全段階以下 -/
example : LearningStage.observation.le LearningStage.retirement = true := rfl
example : LearningStage.observation.le LearningStage.observation = true := rfl

/-- retirement より大きいものはない -/
example : LearningStage.retirement.le LearningStage.observation = false := rfl

/-- forward progression: hypothesis ≤ verification -/
example : LearningStage.hypothesis.le LearningStage.verification = true := rfl

/-- backward は不成立: verification は hypothesis より前にない -/
example : LearningStage.verification.le LearningStage.hypothesis = false := rfl

/-- 全 5 variant の自己反射性 (`s.le s = true`)、Day 4 /verify R1 I3 対処 -/
example : LearningStage.observation.le LearningStage.observation = true := rfl
example : LearningStage.hypothesis.le LearningStage.hypothesis = true := rfl
example : LearningStage.verification.le LearningStage.verification = true := rfl
example : LearningStage.integration.le LearningStage.integration = true := rfl
example : LearningStage.retirement.le LearningStage.retirement = true := rfl

/-! ### LearningStage.isTerminal -/

example : LearningStage.retirement.isTerminal = true := rfl
example : LearningStage.observation.isTerminal = false := rfl

/-! ### Unit instance の動作 -/

/-- Unit の dummy instance は observation 段階を返す -/
example : LearningCycle.currentStage () = LearningStage.observation := rfl

/-- Unit instance の class 解決 -/
example : LearningCycle Unit := inferInstance

/-! ### cross-class interaction (Day 3 /verify R1 A2 への対処)

Spine 層 4 type class を同時に要求する状態の存在を確認。
LearningCycle 統合時に EvolutionStep + SafetyConstraint + LearningCycle が
協調することを示す型レベルテスト。 -/

/-- cross-class: `[EvolutionStep S] [SafetyConstraint S] [LearningCycle S]` を
    同時に要求する関数の型シグネチャ。Unit に対して全 instance が解決される。 -/
def crossClassExample (S : Type u) [EvolutionStep S] [SafetyConstraint S] [LearningCycle S]
    (s : S) : LearningStage :=
  LearningCycle.currentStage s

/-- Unit に対して cross-class 関数が呼べる: 4 type class が共存可能 -/
example : crossClassExample Unit () = LearningStage.observation := rfl

/-- Spine 層 4 type class の同時解決 (Day 4 /verify R1 I4 対処)、
    `×` は Type レベルの product -/
example : EvolutionStep Unit × SafetyConstraint Unit × LearningCycle Unit × Observable Unit :=
  ⟨inferInstance, inferInstance, inferInstance, inferInstance⟩

/-- 4-class cross-class 関数: 全 Spine type class を同時要求し、
    LearningCycle.currentStage と Observable.snapshot を同時利用 -/
def fullSpineExample (S : Type u)
    [EvolutionStep S] [SafetyConstraint S] [LearningCycle S] [Observable S]
    (s : S) : LearningStage × ObservableSnapshot :=
  (LearningCycle.currentStage s, Observable.snapshot s)

/-- Unit に対して 4-class 関数が動作 -/
example : fullSpineExample Unit () =
          (LearningStage.observation,
           {v1:=0, v2:=0, v3:=0, v4:=0, v5:=0, v6:=0, v7:=0 : ObservableSnapshot}) := rfl

end AgentSpec.Test.Spine.LearningCycle
