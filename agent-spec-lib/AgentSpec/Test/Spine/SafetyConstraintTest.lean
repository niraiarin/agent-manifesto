import AgentSpec.Spine.SafetyConstraint

/-!
# AgentSpec.Test.Spine.SafetyConstraintTest: SafetyConstraint type class の behavior test

Day 3 hole-driven: `safe : S → Bool` member と `SafeState` refinement type の
基本性質を Unit instance で検証。
-/

universe u

namespace AgentSpec.Test.Spine.SafetyConstraint

open AgentSpec.Spine
open AgentSpec.Spine.SafetyConstraint

/-! ### Unit instance の safe 動作 -/

/-- Unit の任意 state は safe (dummy instance: 全 true) -/
example : SafetyConstraint.safe () = true := rfl

/-- Unit instance は decidable に safe -/
example : decide (SafetyConstraint.safe () = true) = true := rfl

/-! ### SafeState refinement type の Unit instance (Subtype 標準 API 利用) -/

/-- Unit の SafeState は構築可能 (refinement proof は rfl) -/
example : SafeState Unit := ⟨(), rfl⟩

/-- SafeState の `.val` で元の state を取り出す (Subtype 標準 API) -/
example : (⟨(), rfl⟩ : SafeState Unit).val = () := rfl

/-! ### S4 P2 Refinement の有用性: 関数引数として SafeState を要求 -/

/-- Refinement type の利用例: 「safe な state のみ受理する」関数の型シグネチャ。
    `.val`/`.property` を内部で使えば safe 性を仮定として使える。 -/
def doSafeOperation {S : Type u} [SafetyConstraint S] (_s : SafeState S) : Unit := ()

/-- SafeState を引数に渡せる: refinement type が「証明済み入力」として機能 -/
example : doSafeOperation (⟨(), rfl⟩ : SafeState Unit) = () := rfl

/-! ### type class instance 解決 -/

/-- SafetyConstraint Unit instance が解決される -/
example : SafetyConstraint Unit := inferInstance

/-! ### TyDD-S4 Refinement type の挙動 -/

/-- SafeState は subtype として val/property の標準 API が使える -/
example : ((⟨(), rfl⟩ : SafeState Unit).val) = () := rfl

/-- SafeState の inhabited (dummy instance を介して構築可能) -/
example : Inhabited (SafeState Unit) := ⟨⟨(), rfl⟩⟩

end AgentSpec.Test.Spine.SafetyConstraint
