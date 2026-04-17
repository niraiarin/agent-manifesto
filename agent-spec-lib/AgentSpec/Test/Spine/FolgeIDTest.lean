import AgentSpec.Spine.FolgeID

/-!
# AgentSpec.Test.Spine.FolgeIDTest: FolgeID.lean の behavior test

Week 2 Day 1: hole-driven signature に対する最小 behavior assertion。
TDD 原則に従い `example` で検証、`decide` で compile-time 証明。

## カバーする Gap / 原則

- **GA-S2** (FolgeID): prefix order の反射性・非対称性・推移性の基本例
- **GA-I9** (テストカバレッジ): Spine 層 FolgeID の behavior assertion
- **TyDD-H3** (BiTrSpec): DecidableEq / LE / child の型レベル性質
-/

namespace AgentSpec.Test.Spine.FolgeID

open AgentSpec.Spine

/-! ### root FolgeID の性質 -/

/-- root は自身の prefix (反射性) -/
example : FolgeID.root ≤ FolgeID.root := by decide

/-- root は任意の FolgeID の prefix -/
example : FolgeID.root ≤ ⟨[Sum.inl 1]⟩ := by decide

/-- root は "1.2a" (= [inl 1, inl 2, inr 'a']) の prefix -/
example : FolgeID.root ≤ ⟨[Sum.inl 1, Sum.inl 2, Sum.inr 'a']⟩ := by decide

/-! ### prefix order の反射性・反対称性 -/

/-- 自身は自身の prefix (反射性) -/
example : ({path := [Sum.inl 1] : FolgeID}) ≤ ({path := [Sum.inl 1] : FolgeID}) := by decide

/-- 長い path は短い path の prefix ではない (反対称性の一方向) -/
example : ¬ (({path := [Sum.inl 1, Sum.inl 2] : FolgeID}) ≤
             ({path := [Sum.inl 1] : FolgeID})) := by decide

/-- 異なる先頭要素では prefix 関係にない -/
example : ¬ (({path := [Sum.inl 1] : FolgeID}) ≤
             ({path := [Sum.inl 2] : FolgeID})) := by decide

/-! ### child 構築と prefix 順序 -/

/-- `a.child s` は `a` の子、かつ `a ≤ a.child s` -/
example : FolgeID.root ≤ FolgeID.root.child (Sum.inl 1) := by decide

/-- 2 段子 "1.2" の構築 -/
example : (FolgeID.root.child (Sum.inl 1)).child (Sum.inl 2) =
          ⟨[Sum.inl 1, Sum.inl 2]⟩ := by decide

/-! ### DecidableEq / Inhabited -/

/-- 異なる path を持つ FolgeID は等しくない -/
example : ({path := [Sum.inl 1] : FolgeID}) ≠ ({path := [Sum.inl 2] : FolgeID}) := by decide

/-- Inhabited instance が存在する -/
example : Inhabited FolgeID := inferInstance

end AgentSpec.Test.Spine.FolgeID
