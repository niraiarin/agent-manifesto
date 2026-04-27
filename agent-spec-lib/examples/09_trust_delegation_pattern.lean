import AgentSpec

/-! # Example 09: TrustDelegation real-world pattern

PI-11 (Day 154) で導入された TrustDelegation typeclass の real-world 利用 pattern。
external evaluator (subagent / human / Local LLM) からの attestation を
named axiom 経由で Lean type system に取り込み、`#print axioms` で provenance 追跡。
-/

namespace AgentSpec.Examples.TrustDelegationPattern

open AgentSpec.Tooling

/-- 利用 pattern (verify_token macro 経由):
    ```
    verify_token my_safety_review "human:alice@example.com" : MyComponentIsSafe my_component
    ```
    生成: axiom my_safety_review : MyComponentIsSafe my_component
        + instance : TrustDelegation (MyComponentIsSafe my_component) := ⟨my_safety_review, "human:alice@example.com"⟩

    使用: `theorem my_use : MyComponentIsSafe my_component := by agent_verify`
        → `#print axioms my_use` で `my_safety_review` が表示
        → provenance ("human:alice@example.com") が transparent -/
example : True := trivial

/-- Manual instance 例 (production では verify_token macro 推奨)。 -/
axiom example_safety_attestation : 1 = 1
instance : TrustDelegation (1 = 1) := ⟨example_safety_attestation, "subagent/claude"⟩
example : 1 = 1 := by agent_verify

end AgentSpec.Examples.TrustDelegationPattern
