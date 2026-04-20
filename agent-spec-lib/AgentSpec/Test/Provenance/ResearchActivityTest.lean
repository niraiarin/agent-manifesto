import AgentSpec.Provenance.ResearchActivity

/-!
# AgentSpec.Test.Provenance.ResearchActivityTest: ResearchActivity 5 variant の behavior test

Day 9: 02-data-provenance §4.1 PROV-O 5 variant (investigate / decompose / refine /
verify / retire) と verify variant の Hypothesis/Verdict 連携 (Day 8 EvolutionStep
B4 4-arg post 整合) の検証。
-/

namespace AgentSpec.Test.Provenance.ResearchActivity

open AgentSpec.Provenance
open AgentSpec.Process

/-! ### 5 variant 構築 -/

example : ResearchActivity := .investigate
example : ResearchActivity := .decompose
example : ResearchActivity := .refine
example : ResearchActivity := .retire

/-- verify variant は Hypothesis + Verdict payload (Day 8 EvolutionStep B4 4-arg post 整合) -/
example : ResearchActivity := .verify Hypothesis.trivial Verdict.trivial

/-- verify variant: proven verdict のケース -/
example : ResearchActivity := .verify { claim := "test" } Verdict.proven

/-- verify variant: refuted verdict のケース -/
example : ResearchActivity := .verify Hypothesis.trivial Verdict.refuted

/-! ### isVerify / isRetire 判定 -/

example : ResearchActivity.isVerify (.verify Hypothesis.trivial Verdict.proven) = true := rfl
example : ResearchActivity.isVerify .investigate = false := rfl
example : ResearchActivity.isVerify .retire = false := rfl

example : ResearchActivity.isRetire .retire = true := rfl
example : ResearchActivity.isRetire .investigate = false := rfl
example : ResearchActivity.isRetire (.verify Hypothesis.trivial Verdict.proven) = false := rfl

/-! ### trivial fixture -/

example : ResearchActivity.trivial = ResearchActivity.investigate := rfl
example : ResearchActivity.trivial.isVerify = false := rfl

/-! ### DecidableEq / Inhabited -/

/-- 同 variant 同士の等価性 (payload なし variants) -/
example : (ResearchActivity.investigate : ResearchActivity) = .investigate := by decide

/-- 異 variant の不等 -/
example : (ResearchActivity.investigate : ResearchActivity) ≠ .decompose := by decide

/-- verify variant の DecidableEq (payload Hypothesis + Verdict 含む) -/
example : ResearchActivity.verify Hypothesis.trivial Verdict.proven =
          ResearchActivity.verify Hypothesis.trivial Verdict.proven := by decide

/-- verify variant の不等 (Verdict 違い) -/
example : ResearchActivity.verify Hypothesis.trivial Verdict.proven ≠
          ResearchActivity.verify Hypothesis.trivial Verdict.refuted := by decide

/-- DecidableEq instance 解決 -/
example : DecidableEq ResearchActivity := inferInstance

/-- Inhabited instance 解決 -/
example : Inhabited ResearchActivity := inferInstance

/-! ### Day 8 EvolutionStep B4 4-arg post との整合検証

verify variant が EvolutionStep の transition signature と完全に対応することを示す。
EvolutionStep.transition : (pre : S) → (input : Hypothesis) → (output : Verdict) → (post : S) → Prop
ResearchActivity.verify : (input : Hypothesis) → (output : Verdict) → ResearchActivity

Day 10+ で EvolutionStep の transition を ResearchActivity.verify として PROV mapping する path 確立。 -/

/-- 同一 Hypothesis + Verdict から ResearchActivity.verify を構築できる
    (parameter 形式 example: 注記 — Subagent I2 対処)。

    本 example は通常の `example : <type>` と異なり parameter (`(h : Hypothesis) (v : Verdict)`)
    を取る形式。これは「任意の Hypothesis/Verdict ペアで verify variant が構築可能」という
    universal property を表現するため、Day 1-9 の閉式 example (`rfl` / `decide`) とは
    異なる役割を持つ。example_count としては 1 件としてカウント (Day 10+ で集計方針統一検討)。 -/
example (h : Hypothesis) (v : Verdict) : ResearchActivity := .verify h v

/-! ### Day 26 新規: investigateOf / retireOf payload 付き variants (Day 24 audit 次 long-deferred candidate 解消、Day 13-22 = 12 Day 連続繰り延げ対処、Day 11-26 = 16 Day 連続 rfl preference) -/

-- Day 26 investigateOf: 調査 activity with target hypothesis (02-data-provenance §4.1 PROV-O Activity
-- optional payload、Day 9 `verify` pattern 継続)
example : ResearchActivity := .investigateOf Hypothesis.trivial
example : ResearchActivity := .investigateOf { claim := "Day 26 investigation target" }

-- Day 26 retireOf: 退役 activity with target entity (Day 27+ で RetiredEntity 拡張検討 path、
-- Day 12 RetiredEntity と semantic 整合)
example : ResearchActivity := .retireOf Hypothesis.trivial
example : ResearchActivity := .retireOf { claim := "Day 26 retirement target" }

-- Day 26 accessor rfl 実証 (Day 11-26 = 16 Day 連続 rfl preference 維持)
example : ResearchActivity.isInvestigateOf (.investigateOf Hypothesis.trivial) = true := rfl
example : ResearchActivity.isInvestigateOf .investigate = false := rfl
example : ResearchActivity.isRetireOf (.retireOf Hypothesis.trivial) = true := rfl
example : ResearchActivity.isRetireOf .retire = false := rfl

-- Day 26 backward compatibility 確認: 既存 payloadless `investigate` / `retire` 依存が不変
-- (ResearchActivity.trivial = .investigate、isVerify / isRetire 等の既存 accessor 動作維持)
example : ResearchActivity.trivial = .investigate := rfl
example : ResearchActivity.isRetire .retire = true := rfl
example : ResearchActivity.isRetire (.retireOf Hypothesis.trivial) = false := rfl  -- retireOf は retire と区別される

end AgentSpec.Test.Provenance.ResearchActivity
