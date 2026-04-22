import AgentSpec.Spine.Rationale

/-!
# AgentSpec.Test.Spine.RationaleTest: Rationale structure の behavior test

Day 44 hole-driven minimal: structure 3 field + 4 smart constructor + isTrivial の検証。
GA-S8 (judgmental 構造化) の Lean 着手、各 type attach は Day 45+。
-/

namespace AgentSpec.Test.Spine.Rationale

open AgentSpec.Spine

/-! ### structure 構築 -/

/-- 全 field 直接指定 -/
example : Rationale := { text := "hypothesis confirmed", references := [.doi "10.1145/x"], confidence := 85 }

/-- 最小構築 (trivial と等価) -/
example : Rationale := { text := "", references := [], confidence := 0 }

/-! ### field projection -/

example :
    ({text := "t", references := [], confidence := 42} : Rationale).text = "t" := rfl
example :
    ({text := "", references := [.url "a", .url "b"], confidence := 0} : Rationale).references = [.url "a", .url "b"] := rfl
example :
    ({text := "", references := [], confidence := 99} : Rationale).confidence = 99 := rfl

/-! ### Smart constructor ofText / mk' / addReference -/

example : Rationale.ofText "evidence by induction" 80 =
          { text := "evidence by induction", references := [], confidence := 80 } := rfl

example : Rationale.mk' "h" [.url "r1", .url "r2"] 50 =
          { text := "h", references := [.url "r1", .url "r2"], confidence := 50 } := rfl

example :
    (Rationale.ofText "t" 10).addReference (.url "new-ref") =
    { text := "t", references := [.url "new-ref"], confidence := 10 } := rfl

example :
    (Rationale.mk' "h" [.url "r1"] 50).addReference (.url "r2") =
    { text := "h", references := [.url "r1", .url "r2"], confidence := 50 } := rfl

/-! ### trivial fixture + isTrivial -/

example : Rationale.trivial = { text := "", references := [], confidence := 0 } := rfl

example : Rationale.trivial.isTrivial = true := rfl

example : (Rationale.ofText "x" 0).isTrivial = false := rfl
example : (Rationale.mk' "" [.url "r"] 0).isTrivial = false := rfl
example : (Rationale.mk' "" [] 1).isTrivial = false := rfl

/-! ### DecidableEq / Inhabited -/

example : DecidableEq Rationale := inferInstance
example : Inhabited Rationale := inferInstance

/-- 同値判定 -/
example :
    (Rationale.ofText "same" 50) = (Rationale.ofText "same" 50) := by decide

/-- 異値判定 (text 違い) -/
example :
    (Rationale.ofText "a" 50) ≠ (Rationale.ofText "b" 50) := by decide

/-- 異値判定 (confidence 違い) -/
example :
    (Rationale.ofText "x" 10) ≠ (Rationale.ofText "x" 20) := by decide

/-- 異値判定 (references 違い) -/
example :
    (Rationale.mk' "x" [.url "a"] 10) ≠ (Rationale.mk' "x" [.url "b"] 10) := by decide

/-! ### Day 49: attribution 拡張 (author / timestamp、Day 44 D2 deferred 解消) -/

/-- author / timestamp を明示指定で構築 -/
example : Rationale :=
  { text := "verified by peer review", references := [.arxiv "2604.14572"],
    confidence := 90, author := some "alice", timestamp := some 1714000000 }

/-- field default 維持 (author / timestamp 未指定で既存 Day 44 API 互換) -/
example :
    ({text := "", references := [], confidence := 0} : Rationale).author = none := rfl
example :
    ({text := "", references := [], confidence := 0} : Rationale).timestamp = none := rfl

/-- Rationale.trivial も author/timestamp はデフォルト none -/
example : Rationale.trivial.author = none := rfl
example : Rationale.trivial.timestamp = none := rfl

/-- withAuthor helper -/
example :
    (Rationale.ofText "t" 10).withAuthor "alice" =
    { text := "t", references := [], confidence := 10,
      author := some "alice", timestamp := none } := rfl

/-- withTimestamp helper -/
example :
    (Rationale.ofText "t" 10).withTimestamp 1234567890 =
    { text := "t", references := [], confidence := 10,
      author := none, timestamp := some 1234567890 } := rfl

/-- withAuthor / withTimestamp chain -/
example :
    ((Rationale.ofText "t" 50).withAuthor "bob").withTimestamp 1000 =
    { text := "t", references := [], confidence := 50,
      author := some "bob", timestamp := some 1000 } := rfl

/-- isAttributed: author 指定時 true -/
example : ((Rationale.ofText "t" 0).withAuthor "alice").isAttributed = true := rfl

/-- isAttributed: author 未指定時 false -/
example : (Rationale.ofText "t" 50).isAttributed = false := rfl

example : Rationale.trivial.isAttributed = false := rfl

/-- 異なる author の不等号判定 (GA-S8 attribution 型強制) -/
example :
    ((Rationale.ofText "t" 0).withAuthor "alice") ≠
    ((Rationale.ofText "t" 0).withAuthor "bob") := by decide

/-- 異なる timestamp の不等号判定 -/
example :
    ((Rationale.ofText "t" 0).withTimestamp 100) ≠
    ((Rationale.ofText "t" 0).withTimestamp 200) := by decide

/-! ### Day 52: strict constructor + isProperlyAttributed + A-Minimal deprecated fixtures -/

/-- Rationale.strict 全 5 field 必須構築 -/
example : Rationale :=
  Rationale.strict "induction proof n≥0" [.arxiv "2604.14572", .url "Lean4 Prelude"]
                   85 "alice" 1714000000

/-- strict 構築結果の field 確認 -/
example :
    (Rationale.strict "t" [.url "r"] 50 "alice" 100).author = some "alice" := rfl
example :
    (Rationale.strict "t" [.url "r"] 50 "alice" 100).timestamp = some 100 := rfl

/-- isProperlyAttributed: strict 構築は true -/
example :
    (Rationale.strict "evidence" [.doi "paper:X"] 80 "bob" 200).isProperlyAttributed = true := rfl

/-- isProperlyAttributed: trivial は false (全 field 空) -/
example : Rationale.trivial.isProperlyAttributed = false := rfl

/-- isProperlyAttributed: ofText は false (author 欠損) -/
example : (Rationale.ofText "some claim" 70).isProperlyAttributed = false := rfl

/-- isProperlyAttributed: withAuthor/withTimestamp 付きでも references 空なら false -/
example :
    (((Rationale.ofText "t" 50).withAuthor "alice").withTimestamp 100).isProperlyAttributed = false := rfl

/-- isProperlyAttributed: confidence = 0 でも false (境界値) -/
example :
    (Rationale.strict "t" [.url "r"] 0 "alice" 100).isProperlyAttributed = false := rfl

-- Day 52 deprecated fixture: trivialDeprecated は trivial と等価 (挙動は同じ、警告のみ)
set_option linter.deprecated false in
example : Rationale.trivialDeprecated = Rationale.trivial := rfl

-- Day 52 deprecated fixture: ofTextUnauthoredDeprecated も ofText と等価
set_option linter.deprecated false in
example : Rationale.ofTextUnauthoredDeprecated "t" 50 = Rationale.ofText "t" 50 := rfl

-- deprecated fixture も Inhabited/DecidableEq を維持
set_option linter.deprecated false in
example : Rationale.trivialDeprecated.isProperlyAttributed = false := rfl

end AgentSpec.Test.Spine.Rationale
