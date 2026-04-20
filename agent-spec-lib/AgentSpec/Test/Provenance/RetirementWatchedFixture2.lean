-- Provenance 層 Test fixture 2: RetirementWatchedFixture2 (Day 25、multi-source register / duplicate handling 観測)
-- Q1 Day 25 main: Day 22 Subagent informational I2 (multi-source duplicate handling) 解消 (Day 22-24 = 3 session 繰り延げ)
-- Q2 A-Minimal: 2 つ目の helper module で (a) 独立 namespace register + (b) 既存 namespace duplicate register を実証
-- Q3 案 A: 新 helper module 1 件 (test scope) 追加 + RetirementLinterCommandTest.lean MODIFY
-- Q4 設計: helper 2 で独立 namespace + duplicate register、#check_retired_auto の出力で挙動観測
import AgentSpec.Provenance.RetirementLinter
import AgentSpec.Provenance.RetirementLinterCommand
import AgentSpec.Test.Provenance.RetirementWatchedFixture

/-!
# AgentSpec.Test.Provenance.RetirementWatchedFixture2: Day 25 multi-source register / duplicate handling 観測 fixture

Phase 0 Week 2 Day 25 (multi-source register / duplicate handling、Day 22 Subagent informational I2 解消、3 session 繰り延げ対処)。

## 設計目的 (Section 2.48 Q1-Q4 確定)

Day 23 で 1 つの helper module (`RetirementWatchedFixture`) から register 経由 import propagate を
実証済。Day 25 は:

1. **2 つ目の独立 namespace** (`AgentSpec.Test.Provenance.RetirementWatchedFixture2`) で
   `@[retired]` decorated `importPropagateFixture2` を定義 + register (独立 source の追加実証)
2. **既存 namespace の duplicate register** (`RetirementWatchedFixture` を重複 register、Day 22
   D10 addEntryFn = `arr.push name` が duplicate を許容することの実測確認)

import 先 test (`RetirementLinterCommandTest.lean`) で `#check_retired_auto` 実行時に:
- 独立 namespace がもう 1 件追加される (watched 6 件)
- duplicate namespace が重複 entry として出現 (同 namespace が 2 回 listed)、retired count も
  重複 count される可能性 (実測で確認)

## Day 22 D10 `addEntryFn := fun arr name => arr.push name` の挙動観測

PersistentEnvExtension の `addEntryFn` が dedup していないため、同 namespace の register が 2 回
起こると array に同 entry が 2 回追加される。これにより `#check_retired_auto` の output で:

- watched namespaces list に同 namespace が 2 回 appear
- 各 namespace iteration で retired count が独立に計算されるため、duplicate namespace の retired
  count は **重複 count** される (同 retired declaration が 2 回 count)

Day 25 は本挙動を **実測 + 観測値記録** のみ (dedup 実装は Day 26+ で判断、Day 22 audit 教訓に
従い「observe first, decide later」)。

## Day 11-25 = 15 Day 連続 rfl preference 維持 milestone (Day 24 14 Day 連続から +1)

cycle 内学習 transfer 6 度目適用継続 (Day 11-24 milestone から +1 day、桁到達後の継続実証 15 Day)。
本 helper module は @[retired] def 1 件 + register 2 件のみで rfl 不要、import 先 test で 15 Day 連続維持。
-/

namespace AgentSpec.Test.Provenance.RetirementWatchedFixture2

/-- Day 25 multi-source register test 用 fixture: 独立 namespace `RetirementWatchedFixture2` の
    retired declaration。Day 23 の `RetirementWatchedFixture.importPropagateFixture` と並列、
    2 source から register された独立 namespace の動作実証。 -/
@[retired "Day 25 multi-source register test fixture: 独立 namespace 第 2 source" "2026-04-22"]
def importPropagateFixture2 : Bool := True

end AgentSpec.Test.Provenance.RetirementWatchedFixture2

-- Day 25 multi-source register (a): 独立 namespace `RetirementWatchedFixture2` を register
register_retirement_namespace AgentSpec.Test.Provenance.RetirementWatchedFixture2

-- Day 25 multi-source register (b): **duplicate register** の挙動観測
-- Day 23 の `RetirementWatchedFixture` を本 helper から重複 register することで、
-- Day 22 D10 addEntryFn = arr.push name が dedup していないことの実測確認
-- 期待: #check_retired_auto output で RetirementWatchedFixture が 2 回 appear + retired count 重複
register_retirement_namespace AgentSpec.Test.Provenance.RetirementWatchedFixture
