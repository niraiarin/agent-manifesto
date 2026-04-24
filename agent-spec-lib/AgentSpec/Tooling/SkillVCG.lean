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

/-- Skill verification の最小 obligation (Day 127 第 1 弾: nameNonEmpty)。
    Day 130 拡張: descriptionNonEmpty を追加 (skill description の sanity)。 -/
structure SkillObligation where
  skill   : SkillMeta
  /-- skill name は non-empty (registry の最小 sanity)。 -/
  nameNonEmpty        : skill.name ≠ "" := by decide
  /-- skill description も non-empty (Day 130 追加、SKILL.md description field 必須化)。 -/
  descriptionNonEmpty : skill.description ≠ "" := by decide

/-- SkillObligation を満たす SkillMeta を構築する helper。
    Lean type system で「name/description は ""」状態の skill を構造的に排除。 -/
def mkVerifiedSkill (name : String) (description : String)
    (h1 : name ≠ "" := by decide)
    (h2 : description ≠ "" := by decide) : SkillObligation :=
  { skill := { name := name, description := description },
    nameNonEmpty := h1, descriptionNonEmpty := h2 }

/-- VCG が生成する Lean proposition (Day 127 第 1 弾、name のみ)。 -/
def vcgComposite (obligations : List SkillObligation) : Prop :=
  ∀ o ∈ obligations, o.skill.name ≠ ""

/-- vcgComposite の標準証明: SkillObligation の field から直接導出。 -/
theorem vcgComposite_holds (obligations : List SkillObligation) :
    vcgComposite obligations := by
  intro o _
  exact o.nameNonEmpty

/-- Day 130 拡張 VCG: name + description の両方が non-empty。 -/
def vcgCompositeFull (obligations : List SkillObligation) : Prop :=
  ∀ o ∈ obligations, o.skill.name ≠ "" ∧ o.skill.description ≠ ""

/-- vcgCompositeFull の標準証明: SkillObligation 2 field から直接導出。 -/
theorem vcgCompositeFull_holds (obligations : List SkillObligation) :
    vcgCompositeFull obligations := by
  intro o _
  exact ⟨o.nameNonEmpty, o.descriptionNonEmpty⟩

/-- Smoke test: 拡張 VCG が両 obligation を check。 -/
example : vcgCompositeFull [mkVerifiedSkill "verify" "P2 skill", mkVerifiedSkill "research" "P3 skill"] :=
  vcgCompositeFull_holds _

end AgentSpec.Tooling
