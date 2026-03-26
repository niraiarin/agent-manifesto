import Manifest.EpistemicLayer

open Manifest

def classifyOrd : PropositionId → Nat
  | .t1 | .t2 | .t3 | .t4 | .t5 | .t6 | .t7 | .t8 => 2
  | .e1 | .e2 => 2
  | .p1 | .p2 | .p3 | .p4 | .p5 | .p6 => 1
  | .l1 | .l2 | .l3 | .l4 | .l5 | .l6 => 1
  | .d1 | .d2 | .d3 | .d4 | .d5 | .d6 | .d7 | .d8
  | .d9 | .d10 | .d11 | .d12 | .d13 | .d14 => 0

def allProps : List PropositionId :=
  [.t1, .t2, .t3, .t4, .t5, .t6, .t7, .t8,
   .e1, .e2, .p1, .p2, .p3, .p4, .p5, .p6,
   .l1, .l2, .l3, .l4, .l5, .l6,
   .d1, .d2, .d3, .d4, .d5, .d6, .d7, .d8,
   .d9, .d10, .d11, .d12, .d13, .d14]

def findViolations : List (PropositionId × PropositionId × Nat × Nat) :=
  allProps.foldl (init := []) fun acc a =>
    allProps.foldl (init := acc) fun acc b =>
      if propositionDependsOn a b && classifyOrd b < classifyOrd a then
        acc ++ [(a, b, classifyOrd a, classifyOrd b)]
      else acc

#eval findViolations
