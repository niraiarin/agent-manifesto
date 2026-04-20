import AgentSpec.Provenance.RetirementLinterCommand

/-!
# AgentSpec.Test.Provenance.RetirementLinterCommandTest: `#check_retired` command の動作確認

Day 18 Q1 A 案 + Q2 A-Minimal + Q3 案 A + Q4 案 A: Lean.Elab.Command 拡張の `#check_retired`
command が Day 14 A-Minimal deprecated fixture / 通常 (non-deprecated) definition を正しく
判定するかの動作確認。

Day 11 Subagent I3 教訓継続適用 (cycle 内学習 transfer 6 度目、Day 11-19 = **9 Day 連続**
rfl preference 維持の記録更新、Day 19 で A-Standard-Lite namespace 検出拡張でも rfl 維持):
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

end AgentSpec.Test.Provenance.RetirementLinterCommand
