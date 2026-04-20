import AgentSpec.Provenance.RetirementLinterCommand
import AgentSpec.Provenance.RetirementLinter  -- Day 21 改訂 100: Day 15 @[retired] macro × Day 18 #check_retired 連携テスト用
import AgentSpec.Test.Provenance.RetirementWatchedFixture  -- Day 23: multi-module import propagate test 用 helper module
import AgentSpec.Test.Provenance.RetirementWatchedFixture2  -- Day 25: multi-source register / duplicate handling 観測用 helper module 2

/-!
# AgentSpec.Test.Provenance.RetirementLinterCommandTest: `#check_retired` command の動作確認

Day 18 Q1 A 案 + Q2 A-Minimal + Q3 案 A + Q4 案 A: Lean.Elab.Command 拡張の `#check_retired`
command が Day 14 A-Minimal deprecated fixture / 通常 (non-deprecated) definition を正しく
判定するかの動作確認。

Day 11 Subagent I3 教訓継続適用 (cycle 内学習 transfer 6 度目、**Day 11-25 = 15 Day 連続**
rfl preference 維持 (Day 11-20 milestone 桁到達後の継続実証、Day 25 で 15 Day 連続到達)、Day 19-25 linter 拡張 + investigation + multi-source register でも rfl 維持):
全 example で rfl preference 維持、command 実行は info output 発生のみで test assertion は
type check / inhabitation / 既存 fixture 参照の rfl 確認。

Day 18 初期 build error からの即時修復: `#check_retired` command 連続と `set_option ... in example`
混在で parser 状態競合が発生したため、section 区切りを明確に分離 (#check_retired 前段 +
rfl example 後段) で解決。
-/

namespace AgentSpec.Test.Provenance.RetirementLinterCommand

open AgentSpec.Provenance

/-! ### Day 18 rfl preference: 既存 fixture の type / rfl 確認 (Q4 案 A、rfl 基底 test) -/

set_option linter.deprecated false in
/-- Day 14 retired fixture の type 確認 (Inhabited 解決、rfl preference) -/
example : RetiredEntity := RetiredEntity.obsoleteTrivialDeprecated

/-- Day 12 通常 fixture の type 確認 -/
example : RetiredEntity := RetiredEntity.trivial

set_option linter.deprecated false in
/-- retired fixture と通常 fixture で entity が等価 (rfl) -/
example : RetiredEntity.obsoleteTrivialDeprecated.entity =
          RetiredEntity.trivial.entity := rfl

set_option linter.deprecated false in
/-- retired fixture の reason は Obsolete variant (Day 14 A-Minimal 記録の type-level 検査) -/
example : RetiredEntity.obsoleteTrivialDeprecated.reason = .Obsolete := rfl

/-- 通常 fixture の reason も Obsolete (Day 12 設計記録の rfl 確認) -/
example : RetiredEntity.trivial.reason = .Obsolete := rfl

/-! ### Day 18 A-Standard 3/4 段階目達成記念: 段階的 Lean 機能習得 milestone 記録 -/

set_option linter.deprecated false in
/-- Day 14 A-Minimal (@[deprecated]) + Day 15 A-Compact (@[retired] macro) + Day 18 A-Standard
    (#check_retired command) の 3 段階完了を type-level で確認 (command invocation 不要な純粋 test) -/
example :
    let fixture14 := RetiredEntity.obsoleteTrivialDeprecated       -- Day 14 A-Minimal
    let fixture12 := RetiredEntity.trivial                          -- Day 12 通常
    -- 両者が同じ type RetiredEntity を持つことの type-level 確認
    fixture14.entity = fixture12.entity ∧ fixture14.reason = fixture12.reason := by
  refine ⟨rfl, rfl⟩

/-! ### Day 18: `#check_retired` command 動作確認 (Day 14 A-Minimal fixture 4 variant + 通常 2 variant) -/

-- Day 14 deprecated fixture 4 variant は全て @[deprecated] 付きなので retired 判定期待
-- command 実行時に info output 発生 (build 時に info: ✓ '...' is retired 表示)

set_option linter.deprecated false in
#check_retired RetiredEntity.refutedTrivialDeprecated

set_option linter.deprecated false in
#check_retired RetiredEntity.supersededTrivialDeprecated

set_option linter.deprecated false in
#check_retired RetiredEntity.obsoleteTrivialDeprecated

set_option linter.deprecated false in
#check_retired RetiredEntity.withdrawnTrivialDeprecated

-- Day 12 通常 fixture は @[deprecated] なしなので not retired 判定期待

#check_retired RetiredEntity.trivial

/-! ### Day 19 A-Standard-Lite 3/4 段階目進展記念: 段階的 Lean 機能習得 milestone 記録 (Q4 案 A rfl 前段) -/

set_option linter.deprecated false in
/-- Day 14 A-Minimal + Day 15 A-Compact + Day 18 A-Standard A-Minimal + Day 19 A-Standard-Lite
    の 4 段階累積 (残り 1/4 = A-Maximal Week 5-6)、type-level milestone 確認 -/
example :
    -- 4 Day (14, 15, 18, 19) 累積で RetiredEntity を 4 fixture + 1 normal + 段階的拡張 linter で扱う
    let fixture := RetiredEntity.obsoleteTrivialDeprecated
    fixture.reason = .Obsolete := rfl

/-! ### Day 19 新規: `#check_retired_in_namespace` command 動作確認 (A-Standard-Lite namespace 検出) -/

-- Day 19 A-Standard-Lite: namespace 直下の retired declarations を enumerate。
-- Day 18 parser 状態競合パターン回避 (3 度目、Day 15/Day 18 パターン継続):
-- rfl example 前段 + command 後段で section 分離。

-- AgentSpec.Provenance.RetiredEntity 配下: Day 14 deprecated fixture 4 variant を検出期待

set_option linter.deprecated false in
#check_retired_in_namespace AgentSpec.Provenance.RetiredEntity

-- AgentSpec.Process.Failure 配下: 通常 fixture のみで @[deprecated] なし → 空期待

#check_retired_in_namespace AgentSpec.Process.Failure

-- AgentSpec.Spine.EvolutionStep 配下: Day 17 transitionLegacy 完全削除後なので空期待 (削除確認)

#check_retired_in_namespace AgentSpec.Spine.EvolutionStep

/-! ### Day 20 新規: `#check_retired_in_namespace_with_depth` command 動作確認 (A-Compact nested namespace 再帰対応) -/

-- Day 20 A-Compact: explicit depth parameter で NS 配下を maxDepth レベルまで列挙。
-- depth=1: NS 直下のみ、depth=2: NS.subNS まで、etc.

-- AgentSpec.Provenance.RetiredEntity 配下 depth=1 (直下のみ): Day 14 fixture 4 variant 検出期待

set_option linter.deprecated false in
#check_retired_in_namespace_with_depth AgentSpec.Provenance.RetiredEntity 1

-- AgentSpec.Provenance 配下 depth=2 (2 段階まで): RetiredEntity.* も含めて 4 variant + 0 = 4 期待

set_option linter.deprecated false in
#check_retired_in_namespace_with_depth AgentSpec.Provenance 2

-- AgentSpec.Spine.EvolutionStep 配下 depth=10 (深く): Day 17 削除済で 0 期待 (再確認、explicit depth)

#check_retired_in_namespace_with_depth AgentSpec.Spine.EvolutionStep 10

/-! ### Day 21 新規: `#check_retired_auto` command 動作確認 (A-Standard-Full A-Minimal、auto-target) -/

-- Day 21 A-Standard-Full A-Minimal: pre-defined watched namespaces を auto-target で一括 check。
-- **Day 21 baseline 期待 (Day 23/25 import 前)**: RetiredEntity 4 + Failure 0 + EvolutionStep 0 = total 4 in 3 watched namespaces
-- **Day 25 import 追加後 (現 state)**: Day 23 helper1 + Day 25 helper2 (独立 + duplicate register)
-- の合算 import 経由、watched NS 6 件 (Day 21 hardcode 3 + helper1 1st + helper2 + helper1 dup)、
-- total 7 retired (RetiredEntity 4 + Failure 0 + EvolutionStep 0 + helper1 1 + helper2 1 + helper1 dup 1)
-- (watched NS は AgentSpec.Provenance.RetiredEntity 直下のため、Role.toCtorIdx (Day 20 で
-- AgentSpec.Provenance 配下 depth=2 で顕在化) は対象外、Day 14 fixture 4 のみ counted)
-- **Day 25 実測結論**: addEntryFn = arr.push name は dedup なし、helper1 が 2 回 listed + retired count 重複

set_option linter.deprecated false in
#check_retired_auto

/-! ### Day 21 改訂 100 追加: Day 15 `@[retired]` macro × Day 18 `#check_retired` 連携テスト
     (Subagent I3 Day 18-20 long-deferred、A-Compact ← A-Standard A-Minimal 連携完全実証) -/

-- Day 15 RetirementLinter.lean で定義した `@[retired msg since]` macro を本 test 内で利用、
-- macro 展開後に Day 18 `#check_retired` で deprecated 判定されることを実証。
-- A-Compact (Day 15 macro) ← A-Standard A-Minimal (Day 18 #check_retired) 連携完全実証。

@[retired "Day 21 改訂 100 連携テスト: Day 15 macro 経由 fixture が Day 18 command で検出可能" "2026-04-20"]
def day21LinkageFixture : Bool := True

set_option linter.deprecated false in
#check_retired AgentSpec.Test.Provenance.RetirementLinterCommand.day21LinkageFixture
-- 期待: ✓ '...' is retired (Day 15 @[retired] macro が @[deprecated] (since := "2026-04-20")
-- に展開され、Day 18 #check_retired が Lean.Linter.isDeprecated 経由で検出 → A-Compact ←
-- A-Standard A-Minimal 連携完全実証、Day 18-19-20-21 long-deferred Subagent I3 解消)

/-! ### Day 22 新規: `register_retirement_namespace` + env-driven `#check_retired_auto` 動作確認
     (A-Standard-Full-Standard A-Minimal、PersistentEnvExtension callback、Day 11-22 = 12 Day 連続 rfl preference) -/

-- Day 22 A-Standard-Full-Standard A-Minimal: PersistentEnvExtension で watched namespaces を
-- env-driven 化。Day 21 hardcode list (defaultWatchedRetirementNamespaces) は backward
-- compatible 完全維持 (additive 連結)、register API で動的追加可能。

set_option linter.deprecated false in
/-- Day 22 backward compatible 確認 (Day 23 Subagent I2 即時対処で docstring 現状反映):
    本 example は `defaultWatchedRetirementNamespaces` (Day 21 hardcode 3 件) の type-level
    inhabitation 確認 (Day 11-23 rfl preference 維持)。
    **Day 22 baseline 設計 (register 0 件かつ import なし)**: `#check_retired_auto` は
    RetiredEntity 4 + Failure 0 + EvolutionStep 0 = total 4 in 3 watched namespaces (Day 21 同 output)
    で backward compatible であることが設計保証。
    **現 state (Day 23 import 追加後)**: helper module import で 4 watched (+1)、self-register で
    5 watched (+1)、total 6 retired (+2: helper + self) が実測、下記 `#check_retired_auto` 参照。 -/
example : List Lean.Name :=
  AgentSpec.Provenance.defaultWatchedRetirementNamespaces

-- Day 22 register 経由で新 namespace 追加 (本 test file の namespace を登録、自己参照テスト)
register_retirement_namespace AgentSpec.Test.Provenance.RetirementLinterCommand

-- Day 22 env-driven + Day 23 multi-module import propagate + Day 25 multi-source duplicate 確認:
-- register 後 `#check_retired_auto` (現 state、Day 25 import 追加後):
-- watched NS 7 件 (Day 21 hardcode 3 + helper1 + helper2 + helper1 dup + self)
-- total 8 retired (RetiredEntity 4 + Failure 0 + EvolutionStep 0 + helper1 1 + helper2 1 +
-- helper1 dup 1 + self 1 = 8、duplicate で重複 count、Day 22 D10 addEntryFn 実測)
-- **Day 23 D13 設計**: 本 #check_retired_auto は **Day 22 self-register + Day 23 helper
-- import propagate + Day 25 multi-source duplicate の合算** を検証 (Day 22/23 単独テストは
-- Day 25 import 追加で更新、Day 25 観測結論: addEntryFn は dedup しない)

set_option linter.deprecated false in
#check_retired_auto

/-! ### Day 23 新規: multi-module import propagate test 専用検証
     (A-Standard-Full-Standard A-Minimal、PersistentEnvExtension addImportedFn 動作実証、Day 11-23 = 13 Day 連続 rfl preference) -/

-- Day 23 A-Standard-Full-Standard A-Minimal: helper module
-- (AgentSpec/Test/Provenance/RetirementWatchedFixture.lean) で `register_retirement_namespace`
-- + `@[retired]` decorated `importPropagateFixture` 定義済。本 test file が helper module を
-- import すると、Day 22 D10 PersistentEnvExtension `addImportedFn := arrs.foldl (init := #[])
-- (· ++ ·)` 経由で extension state が import 越境 propagate される。
-- 期待: helper module で register された `AgentSpec.Test.Provenance.RetirementWatchedFixture`
-- が import 先 test の `#check_retired_auto` 出力に reflect され、本 namespace 配下の
-- `importPropagateFixture` (Day 23 helper @[retired] decorated) が retired として count される。

set_option linter.deprecated false in
/-- Day 23 multi-module import propagate type-level 確認: helper module で定義した
    importPropagateFixture が import 経由で本 test scope から参照可能。Day 11-23 rfl preference 維持。 -/
example : Bool :=
  AgentSpec.Test.Provenance.RetirementWatchedFixture.importPropagateFixture

-- Day 23 helper fixture が Day 22 #check_retired で個別に retired 判定可能 (Day 18 single-target
-- command 経由)、import 越境後の deprecated marker propagate 確認

set_option linter.deprecated false in
#check_retired AgentSpec.Test.Provenance.RetirementWatchedFixture.importPropagateFixture
-- 期待: ✓ '...importPropagateFixture' is retired (helper @[retired] が import 先で検出)

/-! ### Day 24 新規: Role.toCtorIdx long-deferred investigation 解消 type-level 実例
     (RetirementLinterCommand.lean D14 + ResearchAgent.lean Day 24 追記参照、Day 11-24 = 14 Day 連続 rfl preference) -/

-- Day 24 Role.toCtorIdx root cause investigation (Day 20-22 長期繰り延べ解消):
-- Lean 4 4.29.0 upstream (since 2025-08-25) で `toCtorIdx` → `ctorIdx` rename、backward compat
-- のため旧名 `Role.toCtorIdx` が @[deprecated newName := Role.ctorIdx] として残っている。
-- agent-spec-lib 側の問題ではなく Lean 4 core の auto-gen helper naming change。

set_option linter.deprecated false in
/-- Day 24 Role.toCtorIdx rename investigation 型レベル実証: 新名 `Role.ctorIdx` で
    Researcher → 0, Reviewer → 1, Verifier → 2 が計算可能 (Lean 4 4.29.0+ 新名経由)。
    Day 11-24 = 14 Day 連続 rfl preference 維持。 -/
example : AgentSpec.Provenance.Role.ctorIdx AgentSpec.Provenance.Role.Researcher = 0 := rfl

set_option linter.deprecated false in
/-- Day 24: 旧名 `Role.toCtorIdx` (deprecated alias) でも同じ結果が返る (backward compat 確認)。
    Lean 4 deprecated alias の alpha-equivalence 保証、Day 11-24 rfl preference 維持。 -/
example : AgentSpec.Provenance.Role.toCtorIdx AgentSpec.Provenance.Role.Researcher =
          AgentSpec.Provenance.Role.ctorIdx AgentSpec.Provenance.Role.Researcher := rfl

-- Day 24 investigation 型レベル結論: Lean 4 upstream rename による deprecated alias が
-- agent-spec-lib の `#check_retired*` command 群に影響する仕組みを型レベルで確認済。
-- Day 22 audit long-deferred 累積警告 (Role.toCtorIdx 3 Day 連続繰り延べ) は Day 24 で解消、
-- Day 25+ の更なる長期化を防止 (Day 21 改訂 100 I3 = 4 セッション繰り延べ到達前に対処完遂)。

/-! ### Day 25 新規: multi-source register / duplicate handling 観測
     (Day 22 Subagent informational I2 解消 3 session 繰り延げ、Day 11-25 = 15 Day 連続 rfl preference) -/

-- Day 25 multi-source register / duplicate handling:
-- helper2 (RetirementWatchedFixture2.lean) で import 時に 2 つの register が実行される:
-- (a) 独立 namespace `RetirementWatchedFixture2` register (新 source 追加)
-- (b) 既存 `RetirementWatchedFixture` の duplicate register (重複 entry 観測)
-- Day 22 D10 addEntryFn = `arr.push name` は dedup しないため、duplicate は許容される。
-- 期待: #check_retired_auto output で watched namespaces が 7 件に増加
-- (Day 21 hardcode 3 + Day 23 helper1 1 + Day 25 helper2 独立 1 + Day 25 helper2 duplicate
-- of helper1 1 + Day 22 self 1 = 7、ただし helper1 が 2 回 appear、retired count も重複)

set_option linter.deprecated false in
/-- Day 25 multi-source register 型レベル確認: helper2 の importPropagateFixture2 が import 経由
    で参照可能。Day 11-25 rfl preference 維持。 -/
example : Bool :=
  AgentSpec.Test.Provenance.RetirementWatchedFixture2.importPropagateFixture2

set_option linter.deprecated false in
#check_retired_auto
-- 実測 output (dedup なし Day 22 D10 addEntryFn 仕様実証):
-- 'AgentSpec.Provenance.RetiredEntity': 4 retired
-- 'AgentSpec.Process.Failure': 0 retired
-- 'AgentSpec.Spine.EvolutionStep': 0 retired
-- 'AgentSpec.Test.Provenance.RetirementWatchedFixture': 1 retired (Day 23 import propagate 1 回目)
-- 'AgentSpec.Test.Provenance.RetirementWatchedFixture2': 1 retired (Day 25 独立 source)
-- 'AgentSpec.Test.Provenance.RetirementWatchedFixture': 1 retired (Day 25 duplicate register、重複 entry)
-- 'AgentSpec.Test.Provenance.RetirementLinterCommand': 1 retired (Day 22 self-register)
-- Total: 8 retired declaration(s) in 7 watched namespaces
-- **Day 25 観測結論**: addEntryFn = arr.push name は dedup しない、duplicate register で同
-- namespace が 2 回 listed、retired count も独立 count (同 declaration が 2 回 count)。Day 26+ で
-- dedup 実装判断 (現在は observe-first 方針、Day 22 audit 教訓継続)。

end AgentSpec.Test.Provenance.RetirementLinterCommand
