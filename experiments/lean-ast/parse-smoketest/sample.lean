-- Sample file for parse smoketest

axiom foo : Nat

theorem bar : True := trivial

def baz (n : Nat) : Nat := n

opaque qux : Nat → Prop

namespace Sample

axiom nested : ∀ (x : Nat), True

end Sample
