import AgentSpec.Spine.EvolutionStep
import AgentSpec.Spine.SafetyConstraint
import AgentSpec.Spine.LearningCycle
import AgentSpec.Spine.Observable
import AgentSpec.Process.Hypothesis
import AgentSpec.Process.Failure
import AgentSpec.Process.Evolution
import AgentSpec.Process.HandoffChain
import AgentSpec.Provenance.Verdict

/-!
# AgentSpec.Test.Cross.SpineProcessTest: Spine + Process layer cross-layer integration test

Day 8 副成果 (Q2 B-Medium、Q4 案 A 別 file)。Day 7 paper サーベイ Section 12.19 で
識別された改善余地「内部規範 layer 横断 transfer」の継続発展。

Day 4 `fullSpineExample` (Spine 4 type class) と Day 7 `fullProcessExample`
(Process 4 type) を **同一 example で同時利用** することで、Spine と Process layer の
**uniform structure 連携** を型レベルで検証。

Day 8 で EvolutionStep が B4 4-arg post (Hypothesis 入力 + Verdict 出力) に refactor された
ことで、Spine ↔ Process layer の架け橋が initial 形式で確立した。本 test はその架け橋を
検証する。
-/

universe u

namespace AgentSpec.Test.Cross.SpineProcess

open AgentSpec.Spine
open AgentSpec.Process
open AgentSpec.Provenance

/-! ### Spine 4 type class + Process 4 type の同時要求 (8 layer要素) -/

/-- 8 layer 要素を全て Type レベルで同時要求する関数の存在 -/
def fullStackExample
    (S : Type u)
    [EvolutionStep S] [SafetyConstraint S] [LearningCycle S] [Observable S]
    (state : S)
    (h : Hypothesis) (f : Failure) (e : Evolution) (ch : HandoffChain) :
    LearningStage × ObservableSnapshot × Hypothesis × Failure × Evolution × HandoffChain :=
  (LearningCycle.currentStage state, Observable.snapshot state, h, f, e, ch)

/-- Unit に対して 8 要素全てが解決される -/
example :
    fullStackExample Unit ()
      Hypothesis.trivial Failure.trivial Evolution.trivial HandoffChain.trivial =
    (LearningStage.observation,
     {v1:=0, v2:=0, v3:=0, v4:=0, v5:=0, v6:=0, v7:=0 : ObservableSnapshot},
     Hypothesis.trivial, Failure.trivial, Evolution.trivial, HandoffChain.trivial) := rfl

/-! ### Day 8 EvolutionStep B4 4-arg post と Process 層 Evolution の連携 -/

/-- Spine EvolutionStep.transition (Day 8 4-arg post) と
    Process Evolution の `latest` Hypothesis を組合わせる -/
example : ∀ (s : Unit) (e : Evolution),
    EvolutionStep.transition s e.latest Verdict.proven s := by
  intros _ _; trivial

/-- Spine EvolutionStep.transition と Process Hypothesis/Verdict の
    type-level 連携 (Spine が Process/Provenance 型に依存することを実証) -/
def evolveWithVerdict {S : Type u} [EvolutionStep S]
    (pre post : S) (h : Hypothesis) (v : Verdict) : Prop :=
  EvolutionStep.transition pre h v post

/-- Unit に対する evolveWithVerdict の trivial true -/
example : evolveWithVerdict () () Hypothesis.trivial Verdict.proven := trivial

/-! ### Day 7 fullProcessExample 互換 + Day 4 fullSpineExample 互換 -/

/-- Day 7 fullProcessExample 構造の再利用 (Process 4 type のみ) -/
def fullProcessReuse (h : Hypothesis) (f : Failure) (e : Evolution) (ch : HandoffChain) :
    Hypothesis × Failure × Evolution × HandoffChain :=
  (h, f, e, ch)

example : fullProcessReuse Hypothesis.trivial Failure.trivial Evolution.trivial .empty =
          (Hypothesis.trivial, Failure.trivial, Evolution.trivial, .empty) := rfl

end AgentSpec.Test.Cross.SpineProcess
