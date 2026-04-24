import AgentSpec.Tooling.SkillRegistry

/-\!
# SkillVCG — Verification Condition Generator for Skill (Phase 0 Week 5-6、Day 127)

GA-C26 (VcForSkill VCG) の skeleton。
SkillMeta から proof obligation を自動生成し、agent_verify tactic で解決する流れの基盤。

将来拡張:
- skill SKILL.md の section をパースして obligation 列挙
- p2-verified.jsonl の verification token に対応する Lean theorem 生成
- agent_verify tactic と組合せて proof discharge
-/

namespace AgentSpec.Tooling

/-- Skill verification の最小 obligation。
    現状: skill name が non-empty であること (skill registry の sanity 条件)。
    将来: skill の各 section に対応する semantic obligation を増やす。 -/
structure SkillObligation where
  skill   : SkillMeta
  /-- skill name は non-empty (registry の最小 sanity)。 -/
  nameNonEmpty : skill.name ≠ "" := by decide

/-- SkillObligation を満たす SkillMeta を構築する helper。
    Lean type system で「name は ""」状態の skill を構造的に排除。 -/
def mkVerifiedSkill (name : String) (description : String)
    (h : name ≠ "" := by decide) : SkillObligation :=
  { skill := { name := name, description := description }, nameNonEmpty := h }

/-- VCG が生成する Lean proposition の最小例。
    将来: VCG が skill metadata 全体を走査して proposition の合成を生成する。 -/
def vcgComposite (obligations : List SkillObligation) : Prop :=
  ∀ o ∈ obligations, o.skill.name ≠ ""

/-- vcgComposite の標準証明: SkillObligation の field から直接導出。 -/
theorem vcgComposite_holds (obligations : List SkillObligation) :
    vcgComposite obligations := by
  intro o _
  exact o.nameNonEmpty

/-- Smoke test: mkVerifiedSkill で構築した skill list で vcgComposite_holds 適用可能。 -/
example : vcgComposite [mkVerifiedSkill "verify" "P2 skill", mkVerifiedSkill "research" "P3 skill"] :=
  vcgComposite_holds _

end AgentSpec.Tooling
