import AgentSpec

/-! # Example 02: agent_verify tactic — IsVerifyToken / TrustDelegation 利用

`agent_verify` tactic の利用例。Day 154 PI-11 で IsVerifyToken (object-level proof)
と TrustDelegation (meta-level external attestation) の二段検索を実装。

End-user perspective: P2 verification token を Lean type system で扱うとき、
agent_verify tactic 1 つで proof discharge できる (kernel proof 優先、attestation fallback)。
-/

namespace AgentSpec.Examples.AgentVerify

open AgentSpec.Tooling

/-- IsVerifyToken (kernel proof) 経由で証明 discharge。
    smoke test 由来の `instance : IsVerifyToken (1 + 1 = 2) := ⟨rfl⟩` を利用。 -/
example : 1 + 1 = 2 := by agent_verify

/-- assumption fallback 経路 (IsVerifyToken instance なしで hypothesis 利用)。 -/
example (h : 1 + 1 = 2) : 1 + 1 = 2 := by agent_verify

/-- TrustDelegation 経路の使用例 (axiom 経由、`#print axioms` で追跡可能)。
    本 example では axiom を declare せず、protocol 説明に留める:
    ```
    axiom my_external : SomeProp
    instance : TrustDelegation SomeProp := ⟨my_external, "evaluator_id"⟩
    example : SomeProp := by agent_verify
    ```
    `#print axioms` で `my_external` が表示され、provenance が透明。 -/
example : True := trivial

end AgentSpec.Examples.AgentVerify
