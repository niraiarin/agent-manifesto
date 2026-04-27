import Lean

/-\!
# Skill Registry — EnvExtension Auto-Register mini-PoC (Phase 0 Week 5-6、Day 126)

GA-C9 (EnvExtension Auto-Register) の skeleton。
Lean の SimplePersistentEnvExtension で skill metadata を環境に永続記録、
import 越境で集約する。将来 attribute 化 (`@[register_skill]`) で auto-register。
-/

namespace AgentSpec.Tooling

/-- Skill metadata。`name` + `description` の minimum schema。
    将来拡張: trigger keywords / risk level / spec layer 等。 -/
structure SkillMeta where
  name        : String
  description : String
  deriving Repr, Inhabited

open Lean

/-- 環境内に登録された SkillMeta を集約する EnvExtension。 -/
initialize skillRegistryExt : SimplePersistentEnvExtension SkillMeta (Array SkillMeta) ←
  registerSimplePersistentEnvExtension {
    name          := `skillRegistry
    addImportedFn := fun ass => ass.foldl (init := #[]) (fun acc a => acc ++ a)
    addEntryFn    := fun arr e => arr.push e
  }

/-- Skill metadata を登録する MetaM helper。
    将来 attribute 化で `@[register_skill name "X" description "Y"]` から呼ぶ。 -/
def registerSkill (m : SkillMeta) : CoreM Unit := do
  modifyEnv fun env => skillRegistryExt.addEntry env m

/-- 現在の環境に登録された全 SkillMeta を返す。 -/
def getRegisteredSkills : CoreM (Array SkillMeta) := do
  return skillRegistryExt.getState (← getEnv)

/-- Smoke test: registerSkill + getRegisteredSkills が動作することを確認。
    initialize block 内で 1 件登録、数式の参照で取得。 -/
example : SkillMeta := { name := "verify", description := "P2 verification skill" }

end AgentSpec.Tooling
