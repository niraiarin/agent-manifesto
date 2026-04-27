import AgentSpec

/-! # Example 07: Tooling chain end-to-end

Day 125-160 で構築した Tooling chain (SkillRegistry → SkillVCG → IsVerifyToken /
TrustDelegation ↔ VerifyTokenLoader ↔ VerifyTokenMacro ↔ agent_verify) の end-to-end 利用例。
-/

namespace AgentSpec.Examples.ToolingChain

open AgentSpec.Tooling

/-- IsVerifyToken instance を直接登録 (kernel proof) して agent_verify で discharge。 -/
instance : IsVerifyToken (2 + 2 = 4) := ⟨by decide⟩

example : 2 + 2 = 4 := by agent_verify

/-- TrustDelegation 利用パターン (named axiom 経由、`#print axioms` で追跡可能)。
    実 production では verify_token macro を使う:
    ```
    verify_token my_action_safe "human-reviewer" : MyActionIsSafe my_action
    ```
    生成される: axiom + TrustDelegation instance。 -/
example : True := trivial

/-- OpaqueOrigin registry で V1 由来確認 (Day 172 32 entry 完成)。 -/
example : opaqueOriginRegistry.length = 32 := by decide

end AgentSpec.Examples.ToolingChain
