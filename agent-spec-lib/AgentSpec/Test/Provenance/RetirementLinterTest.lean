import AgentSpec.Provenance.RetirementLinter
import AgentSpec.Provenance.RetiredEntity

/-!
# AgentSpec.Test.Provenance.RetirementLinterTest: A-Compact `@[retired]` macro behavior test

Day 15 Q1 A 案 + Q2 A-Compact-Hybrid + Q3 案 B + Q4 案 A: `@[retired "msg" "since"]` macro が
`@[deprecated "msg" (since := "since")]` に正しく展開されることの確認。

Day 11 Subagent I3 教訓継続適用 (cycle 内学習 transfer 4 度目、Day 11-15 = 5 Day 連続
rfl preference 維持): 全 example で rfl preference 維持 (simp tactic 不使用)、
set_option linter.deprecated false in で warning 抑制のみ。

Day 14 A-Minimal (`@[deprecated]` 直接付与 4 fixture) と Day 15 A-Compact (`@[retired]`
macro) の並存性確認 (backward compatibility)。
-/

namespace AgentSpec.Test.Provenance.RetirementLinter

open AgentSpec.Provenance
open AgentSpec.Process

/-! ### `@[retired]` macro 基本動作確認 -/

/-- Day 15 D1 macro 展開確認: `@[retired]` 付与 fixture が正常に構築可能 -/
@[retired "退役済 - 確認 (Day 15 macro test)" "2026-04-19"]
def retiredFixtureObsolete : RetiredEntity :=
  RetiredEntity.obsolete ResearchEntity.trivial

@[retired "退役済 - 確認 (Day 15 macro test)" "2026-04-19"]
def retiredFixtureWithdrawn : RetiredEntity :=
  RetiredEntity.withdrawn ResearchEntity.trivial

@[retired "退役済 - Failure 経由 (Day 15 macro test)" "2026-04-19"]
def retiredFixtureRefuted : RetiredEntity :=
  RetiredEntity.refuted ResearchEntity.trivial Failure.trivial

@[retired "退役済 - 後継参照 (Day 15 macro test)" "2026-04-19"]
def retiredFixtureSuperseded : RetiredEntity :=
  RetiredEntity.superseded ResearchEntity.trivial ResearchEntity.trivial

/-! ### Day 15 `@[retired]` fixture rfl 動作確認 (set_option で warning 抑制、rfl preference 維持) -/

set_option linter.deprecated false in
/-- `@[retired]` macro 展開後の fixture が entity accessor で rfl 動作 -/
example : retiredFixtureObsolete.entity = ResearchEntity.trivial := rfl

set_option linter.deprecated false in
/-- `@[retired]` macro 展開後の fixture が reason accessor で rfl 動作 -/
example : retiredFixtureObsolete.reason = .Obsolete := rfl

set_option linter.deprecated false in
/-- Withdrawn variant も同じく rfl 動作 -/
example : retiredFixtureWithdrawn.reason = .Withdrawn := rfl

set_option linter.deprecated false in
/-- Refuted variant (Failure 経由) も rfl 動作 -/
example : retiredFixtureRefuted.reason = .Refuted Failure.trivial := rfl

set_option linter.deprecated false in
/-- Superseded variant (後継参照) も rfl 動作 -/
example : retiredFixtureSuperseded.reason = .Superseded ResearchEntity.trivial := rfl

set_option linter.deprecated false in
/-- whyRetired accessor on retired fixture -/
example : retiredFixtureObsolete.whyRetired = .Obsolete := rfl

/-! ### Day 14 A-Minimal (`@[deprecated]`) + Day 15 A-Compact (`@[retired]`) 並存確認 -/

set_option linter.deprecated false in
/-- Day 14 `@[deprecated]` fixture と Day 15 `@[retired]` fixture が同じ semantic で動作 -/
example :
    let day14 := RetiredEntity.obsoleteTrivialDeprecated  -- @[deprecated] 付与
    let day15 := retiredFixtureObsolete                    -- @[retired] macro 展開 → @[deprecated]
    day14.entity = day15.entity := rfl

set_option linter.deprecated false in
/-- Day 14 + Day 15 両モデルの reason も同じ -/
example :
    let day14 := RetiredEntity.obsoleteTrivialDeprecated
    let day15 := retiredFixtureObsolete
    day14.reason = day15.reason := rfl

/-! ### Day 14 + Day 15 8 variant 全体統合 (内部規範 layer 横断 transfer 9 段階目) -/

set_option linter.deprecated false in
/-- Day 14 (@[deprecated] 4 variant) + Day 15 (@[retired] 4 variant) = 8 variant を List で集約 -/
example :
    let allRetired : List RetiredEntity :=
      -- Day 14 A-Minimal (@[deprecated]) 4 variant
      [ RetiredEntity.refutedTrivialDeprecated,
        RetiredEntity.supersededTrivialDeprecated,
        RetiredEntity.obsoleteTrivialDeprecated,
        RetiredEntity.withdrawnTrivialDeprecated,
      -- Day 15 A-Compact (@[retired] macro) 4 variant
        retiredFixtureRefuted,
        retiredFixtureSuperseded,
        retiredFixtureObsolete,
        retiredFixtureWithdrawn ]
    allRetired.length = 8 := rfl

end AgentSpec.Test.Provenance.RetirementLinter
