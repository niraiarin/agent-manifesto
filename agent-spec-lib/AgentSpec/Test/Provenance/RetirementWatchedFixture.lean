-- Provenance 層 Test fixture: RetirementWatchedFixture (Day 23、A-Standard-Full-Standard A-Minimal、multi-module import propagate test)
-- Q1 Day 23 main: Day 22 PersistentEnvExtension addImportedFn の import 越境 propagate 動作検証
-- Q2 A-Minimal: 新 helper module (本 file) で register_retirement_namespace 実施
-- Q3 案 A: 新 helper module 1 件 (test 用) + RetirementLinterCommandTest.lean MODIFY で import 経由 propagate 確認
-- Q4 設計: 本 file で fixture namespace + @[retired] def を含み、register_retirement_namespace で extension state に追加、import 先 (test) で #check_retired_auto に reflect されることを検証
import AgentSpec.Provenance.RetirementLinter
import AgentSpec.Provenance.RetirementLinterCommand

/-!
# AgentSpec.Test.Provenance.RetirementWatchedFixture: Day 23 multi-module import propagate fixture

Phase 0 Week 2 Day 23 (A-Standard-Full-Standard A-Minimal、Day 22 Subagent informational I1 直接対処)。

## 設計目的 (Section 2.44 Q1-Q4 確定)

Day 22 で `SimplePersistentEnvExtension` + `register_retirement_namespace` を導入したが、
Day 22 test は **同 module 内 self-register** のみで extension の `addImportedFn` 経由の
**import 越境 propagate** は未検証 (Day 22 Subagent informational I1)。

本 helper module は:
1. fixture namespace `AgentSpec.Test.Provenance.RetirementWatchedFixture` 内で `@[retired]`
   decorated `importPropagateFixture` を定義
2. module 末尾で `register_retirement_namespace AgentSpec.Test.Provenance.RetirementWatchedFixture`
   実行 (本 module の env state extension に entry 追加)
3. RetirementLinterCommandTest.lean が本 module を import すると `addImportedFn` が呼ばれ、
   import 先 env state に extension entry が propagate される

import 先 test で `#check_retired_auto` 実行時に本 fixture namespace が watched list に
含まれ、`importPropagateFixture` 1 件が retired として count されることを検証。

## Day 22 D10 PersistentEnvExtension の addImportedFn 動作確認

`addImportedFn := fun arrs => arrs.foldl (init := #[]) (· ++ ·)` で imported modules の
extension state を additive 連結する。本 fixture が import される時、`arrs` には本
fixture の register 結果 (`#[`AgentSpec.Test.Provenance.RetirementWatchedFixture`]`) が
含まれ、import 先で `getState env` 経由で取得可能になる。

## Day 11-23 = 13 Day 連続 rfl preference 維持 milestone (Day 22 12 Day 連続から +1)

cycle 内学習 transfer 6 度目適用継続 (Day 11-22 milestone から +1 day、桁到達後の継続実証 13 Day)。
本 helper module は @[retired] def 1 件のみで rfl 不要だが、import 先 test で 13 Day 連続維持。
-/

namespace AgentSpec.Test.Provenance.RetirementWatchedFixture

/-- Day 23 multi-module import propagate test 用 fixture: Day 15 `@[retired]` macro で
    `@[deprecated]` 展開、本 fixture を含む namespace を `register_retirement_namespace` で
    watched list に追加することで、import 先 test で `#check_retired_auto` の出力に
    本 fixture の retired count が reflect されることを検証。 -/
@[retired "Day 23 multi-module import propagate test fixture: helper module register が import 経由で propagate されることを検証" "2026-04-21"]
def importPropagateFixture : Bool := True

end AgentSpec.Test.Provenance.RetirementWatchedFixture

-- Day 23 multi-module import propagate: 本 helper module で register、import 先 test で
-- `#check_retired_auto` 経由 propagate 確認。Day 22 D11 register_retirement_namespace は
-- declarative side-effect (no `#`-prefix)、env mutation 後に本 module の extension state に
-- 本 namespace が entry として追加される。
register_retirement_namespace AgentSpec.Test.Provenance.RetirementWatchedFixture
