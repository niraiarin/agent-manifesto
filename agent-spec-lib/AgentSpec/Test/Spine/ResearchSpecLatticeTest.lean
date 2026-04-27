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

/-! ### Day 78 empirical #6 追加 (EDGE E3 test 漏れ + E1 E2 検証) -/

/-- ResearchSpec sup_assoc (Day 77 では inf_assoc のみだった)。 -/
example (s1 s2 s3 : ResearchSpec Nat Nat Nat) : (s1 ⊔ s2) ⊔ s3 = s1 ⊔ (s2 ⊔ s3) := sup_assoc _ _ _

/-- ResearchSpec sup_idem (Day 77 では inf_idem のみだった)。 -/
example (s : ResearchSpec Nat Nat Nat) : s ⊔ s = s := sup_idem _

/-- PostPred sup_inf_self absorption (Day 77 では PrePred のみだった)。 -/
example (p q : PostPred Nat Nat Nat) : p ⊔ (p ⊓ q) = p := sup_inf_self

/-- PostPred inf_sup_self absorption (Day 77 では PrePred のみだった)。 -/
example (p q : PostPred Nat Nat Nat) : p ⊓ (p ⊔ q) = p := inf_sup_self

/-- meetPre semantics: 2 spec の meet は両 pre の AND (Hoare 直感)。 -/
example (p q : PrePred Nat Nat) (s i : Nat) : meetPre p q s i ↔ p s i ∧ q s i := Iff.rfl

/-- joinPost semantics: 2 spec の join は両 post の OR。 -/
example (p q : PostPred Nat Nat Nat) (s i : Nat) (o s' : Nat) :
    joinPost p q s i o s' ↔ p s i o s' ∨ q s i o s' := Iff.rfl

/-! ### DistribLattice (BUG E1 修正後) -/

/-- DistribLattice の le_sup_inf 法則 (Day 77 plain Lattice では未付与だった)。 -/
example (s1 s2 s3 : ResearchSpec Nat Nat Nat) :
    (s1 ⊔ s2) ⊓ (s1 ⊔ s3) ≤ s1 ⊔ (s2 ⊓ s3) := le_sup_inf

/-- DistribLattice の inf_sup_left (BUG E1 で resolution 失敗していた)。 -/
example (s1 s2 s3 : ResearchSpec Nat Nat Nat) :
    s1 ⊓ (s2 ⊔ s3) = (s1 ⊓ s2) ⊔ (s1 ⊓ s3) := inf_sup_left _ _ _

/-! ### OrderTop / OrderBot (EDGE E2 修正後) -/

/-- ⊤ = trivial spec。 -/
example : (⊤ : ResearchSpec Nat Nat Nat) = ResearchSpec.trivial := ResearchSpec.top_eq_trivial

/-- ⊥ = unsatisfiable spec。 -/
example : (⊥ : ResearchSpec Nat Nat Nat) = ResearchSpec.unsatisfiable := ResearchSpec.bot_eq_unsatisfiable

/-- 任意 spec ≤ ⊤。 -/
example (s : ResearchSpec Nat Nat Nat) : s ≤ ⊤ := le_top

/-- ⊥ ≤ 任意 spec。 -/
example (s : ResearchSpec Nat Nat Nat) : ⊥ ≤ s := bot_le

/-! ### ext lemma (EDGE E4 defensive、cases+congr 代替) -/

example (s1 s2 : ResearchSpec Nat Nat Nat)
    (hpre : s1.pre = s2.pre) (hpost : s1.post = s2.post) : s1 = s2 :=
  ResearchSpec.ext hpre hpost

end AgentSpec.Test.Spine.ResearchSpecLatticeTest
