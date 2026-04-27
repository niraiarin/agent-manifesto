import AgentSpec.Spine.State

/-!
# AgentSpec.Test.Spine.StateTest: LifeCyclePhase + AllowedTransition の behavior test

Day 51 GA-S7 Type-Safe State Machine。8 variant LifeCyclePhase + 8 遷移 Prop + transition
関数の検証。05-plaintext-issue-tracker.md §4.1/§4.3 仕様準拠。
-/

namespace AgentSpec.Test.Spine.State

open AgentSpec.Spine

/-! ### 8 variant 構築 -/

example : LifeCyclePhase := .Proposed
example : LifeCyclePhase := .Investigating
example : LifeCyclePhase := .Specifying
example : LifeCyclePhase := .Implementing
example : LifeCyclePhase := .Reviewing
example : LifeCyclePhase := .Verified
example : LifeCyclePhase := .Retired
example : LifeCyclePhase := .Cancelled

/-! ### DecidableEq / Inhabited / Repr -/

example : DecidableEq LifeCyclePhase := inferInstance
example : Inhabited LifeCyclePhase := inferInstance

example : (LifeCyclePhase.Proposed) = (LifeCyclePhase.Proposed) := by decide
example : LifeCyclePhase.Proposed ≠ LifeCyclePhase.Investigating := by decide
example : LifeCyclePhase.Retired ≠ LifeCyclePhase.Cancelled := by decide

/-! ### accessor: initial / isTerminal / isActive -/

example : LifeCyclePhase.initial = LifeCyclePhase.Proposed := rfl

example : LifeCyclePhase.Proposed.isTerminal = false := rfl
example : LifeCyclePhase.Retired.isTerminal = true := rfl
example : LifeCyclePhase.Cancelled.isTerminal = true := rfl
example : LifeCyclePhase.Verified.isTerminal = false := rfl

example : LifeCyclePhase.Proposed.isActive = false := rfl
example : LifeCyclePhase.Investigating.isActive = true := rfl
example : LifeCyclePhase.Implementing.isActive = true := rfl
example : LifeCyclePhase.Reviewing.isActive = true := rfl
example : LifeCyclePhase.Verified.isActive = false := rfl
example : LifeCyclePhase.Retired.isActive = false := rfl

/-! ### AllowedTransition: 許可遷移の Prop 構築 -/

/-- Proposed → Investigating: 直列主経路 -/
example : AllowedTransition .Proposed .Investigating :=
  .proposed_to_investigating

/-- Investigating → Specifying -/
example : AllowedTransition .Investigating .Specifying :=
  .investigating_to_specifying

/-- Specifying → Implementing -/
example : AllowedTransition .Specifying .Implementing :=
  .specifying_to_implementing

/-- Implementing → Reviewing -/
example : AllowedTransition .Implementing .Reviewing :=
  .implementing_to_reviewing

/-- Reviewing → Verified: 検証完了 -/
example : AllowedTransition .Reviewing .Verified :=
  .reviewing_to_verified

/-- Reviewing → Implementing: rework (差戻し) -/
example : AllowedTransition .Reviewing .Implementing :=
  .reviewing_to_implementing

/-- Verified → Retired: 退役 -/
example : AllowedTransition .Verified .Retired :=
  .verified_to_retired

/-- 任意状態 → Cancelled (universal cancellation) -/
example : AllowedTransition .Proposed .Cancelled := .any_to_cancelled
example : AllowedTransition .Investigating .Cancelled := .any_to_cancelled
example : AllowedTransition .Implementing .Cancelled := .any_to_cancelled
example : AllowedTransition .Verified .Cancelled := .any_to_cancelled
example : AllowedTransition .Retired .Cancelled := .any_to_cancelled

/-! ### transition 関数 (型 safe な遷移) -/

/-- 遷移 proof 付きで next phase を取得 -/
example :
    transition .Proposed .Investigating .proposed_to_investigating =
    .Investigating := rfl

example :
    transition .Reviewing .Verified .reviewing_to_verified =
    .Verified := rfl

example :
    transition .Verified .Retired .verified_to_retired = .Retired := rfl

/-! ### 不正遷移は compile-time error として拒否される (GA-S7 の本質)

以下の遷移は AllowedTransition の constructor が存在しないため、proof を
構築できず、transition 関数呼び出しが compile-time で拒否される:
- Proposed → Verified (中間 phase 省略の禁止)
- Retired → Proposed (terminal からの復帰禁止)
- Verified → Implementing (逆遷移禁止、Reviewing からのみ rework 可)

これが Lean 型で不正遷移を静的に防ぐ GA-S7 の本質。
-/

end AgentSpec.Test.Spine.State
