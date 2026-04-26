import Lean

/-\! # IsVerifyToken / TrustDelegation — object proof vs meta attestation 二分岐 (PI-11、Day 154)

二つの typeclass で「証明源」を区別する:

- **IsVerifyToken P** — Lean kernel verifiable proof (rfl, by tactic, term proof) を evidence とする
  object 層 typeclass。`#print axioms` には専用 axiom が現れない (proof は kernel 検証済)。
- **TrustDelegation P** — 外部 attestation (independent evaluator / human / Local LLM) を表す
  meta 層 typeclass。evidence は named axiom 経由で `#print axioms` に追跡可能。

`agent_verify` tactic は両方検索、IsVerifyToken を preferred (kernel proof)、
TrustDelegation を fallback (axiom-backed) として使う。
provenance 区別が #print axioms 出力で観察可能になる。

PI-11 (Day 148 plan): IsVerifyToken と TrustDelegation を分離することで、
Lean object 層の証明と meta 層の trust attestation の区別が typeclass 構造で表現される。
構文/意味 × 対象/メタ 評価の弱点 #1 (trust delegation と proof の混淆) への structural 対処。
-/

namespace AgentSpec.Tooling

/-- Verify token typeclass (object 層、kernel verifiable proof)。
    `instance : IsVerifyToken P := ⟨proof⟩` で Lean 型検査済の proof を marker 化。
    `#print axioms` に専用 axiom 不出現 (proof が kernel 検証済)。 -/
class IsVerifyToken (P : Prop) : Prop where
  evidence : P

/-- Trust delegation typeclass (meta 層、外部 attestation)。
    `instance : TrustDelegation P := ⟨named_axiom, "evaluator_id"⟩` で
    independent evaluator (human / Local LLM / 別 API) 由来の attestation を marker 化。
    evidence は named axiom 経由で `#print axioms` に追跡可能、provenance 透明。
    PI-11 で IsVerifyToken から分離 (Day 148 plan、Day 154 実装)。 -/
class TrustDelegation (P : Prop) where
  evidence    : P
  attestation : String  -- evaluator id (例: "subagent/claude", "ollama/qwen2.5", "human")

/-- IsVerifyToken instance を proof として展開する helper。 -/
def verifyTokenProof {P : Prop} [inst : IsVerifyToken P] : P :=
  inst.evidence

/-- TrustDelegation instance を proof として展開する helper。
    使用時に `#print axioms` で attestation 由来 axiom が表示されるため、
    evaluator 経路が透明になる。 -/
def trustDelegationProof {P : Prop} [inst : TrustDelegation P] : P :=
  inst.evidence

/-- Smoke test: trivial proposition への IsVerifyToken instance (kernel verifiable)。 -/
instance : IsVerifyToken (1 + 1 = 2) := ⟨rfl⟩

/-- Smoke test: IsVerifyToken instance を verifyTokenProof で展開して theorem を証明。
    `#print axioms one_plus_one_verified` は空 (kernel proof のみ)。 -/
theorem one_plus_one_verified : 1 + 1 = 2 :=
  verifyTokenProof

end AgentSpec.Tooling
