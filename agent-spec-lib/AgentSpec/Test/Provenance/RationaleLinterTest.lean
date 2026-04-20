import AgentSpec.Provenance.RationaleLinter
import AgentSpec.Process.Hypothesis
import AgentSpec.Spine.ResearchGoal
import AgentSpec.Spine.State

/-!
# AgentSpec.Test.Provenance.RationaleLinterTest: #check_unattributed_rationale command の動作確認

Day 60 F1 Option C sprint 1/4: value-level scanner が (a) 既存の unattributed 使用 decl を
正しく flag し、(b) strict / mk' 等 attributed API 利用 decl を ✓ 判定することを
#check で info output として確認。

Day 14 RetirementLinter Test と対称 (#check_retired info output を `--set-option`
log_level で保持)。
-/

namespace AgentSpec.Test.Provenance.RationaleLinter

open AgentSpec.Provenance
open AgentSpec.Process (Hypothesis)
open AgentSpec.Spine

/-! ### value-level 検査: 既存 unattributed 使用 decl を flag -/

-- Hypothesis.trivial は内部で Rationale.trivial を使用 → ⚠ flag 期待
#check_unattributed_rationale AgentSpec.Process.Hypothesis.trivial

-- ResearchGoal.trivial も Rationale.trivial 使用 → ⚠ flag
#check_unattributed_rationale AgentSpec.Spine.ResearchGoal.trivial

-- Hypothesis.ofClaimWithText は Rationale.ofText 使用 (author 未指定) → ⚠ flag
-- Day 58 で @[deprecated] 付きだが、RationaleLinter は value-level なので両 mechanism が重複検出
set_option linter.deprecated false in
#check_unattributed_rationale AgentSpec.Process.Hypothesis.ofClaimWithText

/-! ### attributed API 利用 decl は ✓ 判定 -/

-- Rationale.strict 自身は blacklist にないため ✓
#check_unattributed_rationale AgentSpec.Spine.Rationale.strict

-- Rationale.mk' 自身も blacklist にないため ✓ (caller が rationale を渡す API)
#check_unattributed_rationale AgentSpec.Spine.Rationale.mk'

/-! ### blacklist 定数自身を検査 (自己参照) -/

-- Rationale.trivial 自身の body は Rationale.mk constructor のみ (blacklist 定数は使わず)
#check_unattributed_rationale AgentSpec.Spine.Rationale.trivial

/-! ### inductive / structure (defnInfo でない decl) は ○ 判定 -/

-- Rationale 自身 (structure) は defnInfo ではない
#check_unattributed_rationale AgentSpec.Spine.Rationale

-- LifeCyclePhase (inductive) も defnInfo ではない
#check_unattributed_rationale AgentSpec.Spine.LifeCyclePhase

/-! ### Day 61 (F1 sprint 2/4): register_rationale_watched_namespace 動作確認 -/

-- Day 61 で追加された register command が動作 (env mutation)
register_rationale_watched_namespace AgentSpec.Test.Provenance.RationaleLinter

end AgentSpec.Test.Provenance.RationaleLinter
