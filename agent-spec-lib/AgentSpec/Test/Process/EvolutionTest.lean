import AgentSpec.Process.Evolution
import AgentSpec.Process.Failure
import AgentSpec.Process.HandoffChain

/-!
# AgentSpec.Test.Process.EvolutionTest: Evolution + cross-process test

Day 7 hole-driven: Evolution inductive の構築 + accessor + Q2 案 A の cross-process test
(Hypothesis × Failure × Evolution × HandoffChain) を実装。
Q4 案 A により Spine 統合 test (LearningCycleTest) とは別 file。
-/

namespace AgentSpec.Test.Process.Evolution

open AgentSpec.Process

/-! ### Evolution 構築 (initial / refineWith) -/

/-- initial constructor で開始 -/
example : Evolution := .initial Hypothesis.trivial

/-- refineWith で 1 step 進める -/
example : Evolution :=
  .refineWith (.initial Hypothesis.trivial) { claim := "refined" }

/-- 2 step の chain -/
example : Evolution :=
  .refineWith
    (.refineWith (.initial Hypothesis.trivial) { claim := "step 1" })
    { claim := "step 2" }

/-! ### Accessor: origin / latest / stepCount -/

/-- initial の origin -/
example : Evolution.origin (.initial Hypothesis.trivial) = Hypothesis.trivial := rfl

/-- refineWith の origin (元の Hypothesis を返す) -/
example : Evolution.origin
    (.refineWith (.initial { claim := "first" }) { claim := "second" }) =
    { claim := "first" } := rfl

/-- initial の latest = origin -/
example : Evolution.latest (.initial Hypothesis.trivial) = Hypothesis.trivial := rfl

/-- refineWith の latest (refined hypothesis を返す) -/
example : Evolution.latest
    (.refineWith (.initial { claim := "first" }) { claim := "second" }) =
    { claim := "second" } := rfl

/-- initial の stepCount = 0 -/
example : Evolution.stepCount (.initial Hypothesis.trivial) = 0 := rfl

/-- 1 refineWith で stepCount = 1 -/
example : Evolution.stepCount
    (.refineWith (.initial Hypothesis.trivial) { claim := "x" }) = 1 := rfl

/-- 2 refineWith で stepCount = 2 -/
example : Evolution.stepCount
    (.refineWith
      (.refineWith (.initial Hypothesis.trivial) { claim := "a" })
      { claim := "b" }) = 2 := rfl

/-! ### trivial fixture -/

/-- trivial evolution は initial Hypothesis.trivial -/
example : Evolution.trivial = .initial Hypothesis.trivial := rfl

example : Evolution.trivial.origin = Hypothesis.trivial := rfl
example : Evolution.trivial.stepCount = 0 := rfl

/-! ### Inhabited / Repr -/

/-- Evolution Inhabited (deriving 経由) -/
example : Inhabited Evolution := inferInstance

/-! ### Q2 案 A: cross-process test (Hypothesis × Failure × Evolution × HandoffChain)

    Day 4 fullSpineExample パターン踏襲。Spine 層と異なり Process 層は
    type class ではなく structure/inductive のため、4-tuple で同時利用を示す。
    Section 2.12 🟡 cross-process interaction test の解消。 -/

/-- Process 層 4 type を同時に構築する関数の存在 (型レベルで 4 type が共存可能を示す) -/
def fullProcessExample
    (h : Hypothesis) (f : Failure) (e : Evolution) (ch : HandoffChain) :
    Hypothesis × Failure × Evolution × HandoffChain :=
  (h, f, e, ch)

/-- 全 4 type を trivial fixture で構築 -/
example : Hypothesis × Failure × Evolution × HandoffChain :=
  fullProcessExample Hypothesis.trivial Failure.trivial Evolution.trivial .empty

/-- 4 type の同時利用と accessor 連携: Evolution の latest が Hypothesis 型として
    使え、Failure の reason が抽出可能、HandoffChain の length が取れる。

    `simp` を使用する理由 (Subagent A2 注記): `let` で導入した値の展開と
    複数の def (`Evolution.latest`, `HandoffChain.length`, smart constructor
    `Failure.refuted`) を同時に reduce する必要があるため、`rfl` 単独では不可。
    Day 1-6 では single-step `rfl`/`decide` で済んだが、Day 7 cross-process test は
    複数 type の同時 reduction が必要な複合 example で `simp` が natural。 -/
example :
    let h := Hypothesis.trivial
    let f := Failure.refuted h.claim "no evidence"
    let e := Evolution.refineWith (.initial h) { claim := "refined" }
    let ch := HandoffChain.cons HandoffChain.trivialHandoff .empty
    (e.latest.claim = "refined") ∧
    (f.failedHypothesis = h.claim) ∧
    (ch.length = 1) := by
  simp [Evolution.latest, HandoffChain.length, Hypothesis.trivial,
        Failure.refuted]

end AgentSpec.Test.Process.Evolution
