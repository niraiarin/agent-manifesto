import AgentSpec.Spine.Observable

/-!
# AgentSpec.Test.Spine.ObservableTest: Observable type class の behavior test

Day 4 hole-driven: ObservableSnapshot structure + Observable class の
基本性質を Unit instance で検証。
-/

namespace AgentSpec.Test.Spine.Observable

open AgentSpec.Spine

/-! ### ObservableSnapshot field projection -/

/-- 初期化済 snapshot の各 field 取り出し -/
example : ({v1:=1, v2:=2, v3:=3, v4:=4, v5:=5, v6:=6, v7:=7 : ObservableSnapshot}).v1 = 1 := rfl
example : ({v1:=1, v2:=2, v3:=3, v4:=4, v5:=5, v6:=6, v7:=7 : ObservableSnapshot}).v7 = 7 := rfl

/-- DecidableEq: 同一値同士は等しい -/
example : ({v1:=0, v2:=0, v3:=0, v4:=0, v5:=0, v6:=0, v7:=0 : ObservableSnapshot}) =
          ({v1:=0, v2:=0, v3:=0, v4:=0, v5:=0, v6:=0, v7:=0 : ObservableSnapshot}) := by decide

/-- DecidableEq: 1 field だけ違えば不等 -/
example : ({v1:=0, v2:=0, v3:=0, v4:=0, v5:=0, v6:=0, v7:=0 : ObservableSnapshot}) ≠
          ({v1:=1, v2:=0, v3:=0, v4:=0, v5:=0, v6:=0, v7:=0 : ObservableSnapshot}) := by decide

/-! ### Unit instance の snapshot -/

/-- Unit の dummy instance は全 0 snapshot を返す -/
example : Observable.snapshot () =
          ({v1:=0, v2:=0, v3:=0, v4:=0, v5:=0, v6:=0, v7:=0 : ObservableSnapshot}) := rfl

/-- Unit instance の class 解決 -/
example : Observable Unit := inferInstance

/-! ### Inhabited / Repr -/

example : Inhabited ObservableSnapshot := inferInstance

end AgentSpec.Test.Spine.Observable
