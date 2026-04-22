import AgentSpec.Spine.ResearchSpecLattice

/-! # AgentSpec.Test.Spine.ResearchSpecLatticeTest (Day 77、Q2=B 後半)

GA-S15 SpecSig Lattice の behavior test。Day 76 の PrePred/PostPred 自動 Lattice
+ Day 77 ResearchSpec 全体 Lattice instance の動作確認。
-/

namespace AgentSpec.Test.Spine.ResearchSpecLatticeTest

open AgentSpec.Spine
open AgentSpec.Spine.ResearchSpecLattice

/-! ### PrePred/PostPred Lattice 自動継承 (Pi.instLattice + Prop.instDistribLattice) -/

example (p q : PrePred Nat Nat) : PrePred Nat Nat := p ⊓ q
example (p q : PrePred Nat Nat) : PrePred Nat Nat := p ⊔ q
example (p q : PostPred Nat Nat Nat) : PostPred Nat Nat Nat := p ⊓ q
example (p q : PostPred Nat Nat Nat) : PostPred Nat Nat Nat := p ⊔ q

/-! ### PrePred Lattice 法則 -/

example (p q : PrePred Nat Nat) : p ⊓ q = q ⊓ p := inf_comm _ _
example (p q : PrePred Nat Nat) : p ⊔ q = q ⊔ p := sup_comm _ _
example (p q r : PrePred Nat Nat) : (p ⊓ q) ⊓ r = p ⊓ (q ⊓ r) := inf_assoc _ _ _
example (p q r : PrePred Nat Nat) : (p ⊔ q) ⊔ r = p ⊔ (q ⊔ r) := sup_assoc _ _ _
example (p q : PrePred Nat Nat) : p ⊓ (p ⊔ q) = p := inf_sup_self
example (p q : PrePred Nat Nat) : p ⊔ (p ⊓ q) = p := sup_inf_self
example (p : PrePred Nat Nat) : p ⊓ p = p := inf_idem _
example (p : PrePred Nat Nat) : p ⊔ p = p := sup_idem _

/-! ### PostPred Lattice 法則 -/

example (p q : PostPred Nat Nat Nat) : p ⊓ q = q ⊓ p := inf_comm _ _
example (p q r : PostPred Nat Nat Nat) : (p ⊓ q) ⊓ r = p ⊓ (q ⊓ r) := inf_assoc _ _ _
example (p q r : PostPred Nat Nat Nat) : (p ⊔ q) ⊔ r = p ⊔ (q ⊔ r) := sup_assoc _ _ _

/-! ### meetPre / joinPost 動作確認 -/

example (p q : PrePred Nat Nat) : meetPre p q = p ⊓ q := rfl
example (p q : PostPred Nat Nat Nat) : joinPost p q = p ⊔ q := rfl

/-! ### ResearchSpec lattice (Day 77 新規) -/

/-- accept Nat input + output = input + 1 -/
def specInc : ResearchSpec Nat Nat Nat :=
  { pre := fun _ i => i < 10,
    post := fun _ i o _ => o = i + 1 }

/-- accept Nat input + output = input * 2 -/
def specDouble : ResearchSpec Nat Nat Nat :=
  { pre := fun _ i => i < 5,
    post := fun _ i o _ => o = i * 2 }

example : ResearchSpec Nat Nat Nat := specInc ⊓ specDouble
example : ResearchSpec Nat Nat Nat := specInc ⊔ specDouble

example : (specInc ⊓ specDouble).pre = specInc.pre ⊓ specDouble.pre := ResearchSpec.inf_pre _ _
example : (specInc ⊓ specDouble).post = specInc.post ⊓ specDouble.post := ResearchSpec.inf_post _ _
example : (specInc ⊔ specDouble).pre = specInc.pre ⊔ specDouble.pre := ResearchSpec.sup_pre _ _
example : (specInc ⊔ specDouble).post = specInc.post ⊔ specDouble.post := ResearchSpec.sup_post _ _

/-! ### ResearchSpec PartialOrder 法則 -/

example : specInc ≤ specInc := le_refl _
example (s : ResearchSpec Nat Nat Nat) : s ≤ s := le_refl _

example (s1 s2 : ResearchSpec Nat Nat Nat) : s1 ≤ s2 ↔ s1.pre ≤ s2.pre ∧ s1.post ≤ s2.post :=
  ResearchSpec.le_iff _ _

/-! ### ResearchSpec Lattice 法則 -/

example (s1 s2 : ResearchSpec Nat Nat Nat) : s1 ⊓ s2 = s2 ⊓ s1 := inf_comm _ _
example (s1 s2 : ResearchSpec Nat Nat Nat) : s1 ⊔ s2 = s2 ⊔ s1 := sup_comm _ _
example (s1 s2 s3 : ResearchSpec Nat Nat Nat) : (s1 ⊓ s2) ⊓ s3 = s1 ⊓ (s2 ⊓ s3) := inf_assoc _ _ _
example (s1 s2 : ResearchSpec Nat Nat Nat) : s1 ⊓ (s1 ⊔ s2) = s1 := inf_sup_self
example (s1 s2 : ResearchSpec Nat Nat Nat) : s1 ⊔ (s1 ⊓ s2) = s1 := sup_inf_self
example (s : ResearchSpec Nat Nat Nat) : s ⊓ s = s := inf_idem _

/-! ### Day 53 helper との連結 (rfl 経由 definitional equality) -/

example (s : ResearchSpec Nat Nat Nat) (extra : PrePred Nat Nat) :
    (s.strengthenPre extra).pre = meetPre s.pre extra := rfl

example (s : ResearchSpec Nat Nat Nat) (alt : PostPred Nat Nat Nat) :
    (s.weakenPost alt).post = joinPost s.post alt := rfl

end AgentSpec.Test.Spine.ResearchSpecLatticeTest
