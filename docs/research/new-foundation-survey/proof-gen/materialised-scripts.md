# Materialised Proof Scripts (Day 215 Phase 7 sprint 3 #3)

Each row shows the tactic script suggested by `aesop?` / `duper?` for benchmarks that PASS.

Source benchmark: docs/research/new-foundation-survey/proof-gen/benchmark-v0.2.0.json

| id | tool | suggested script |
|---|---|---|
| `p_implies_p` | aesop | `intro a` |
| `p_implies_p` | duper | `duper [*] {portfolioInstance := 1}` |
| `and_symmetry` | aesop | `simp_all only [and_self]` |
| `and_symmetry` | duper | `duper [*] {portfolioInstance := 1}` |
| `modus_ponens_chain` | aesop | `simp_all only [forall_const]` |
| `modus_ponens_chain` | duper | `duper [*] {portfolioInstance := 1}` |
| `function_equality_chain` | aesop | `subst h1 h2` |
| `function_equality_chain` | duper | `duper [h1, h2] {portfolioInstance := 1}` |
| `nat_zero_add` | aesop | `simp_all only [zero_add]` |
| `nat_zero_add` | duper | (FAIL or no suggestion) |
| `or_symmetry` | aesop | `cases h with` |
| `or_symmetry` | duper | `duper [*] {portfolioInstance := 1}` |
| `triple_negation_collapse` | aesop | `intro a` |
| `triple_negation_collapse` | duper | `duper [*] {portfolioInstance := 1}` |
| `exists_elim_propagation` | aesop | `obtain ⟨w, h⟩ := h` |
| `exists_elim_propagation` | duper | `duper [*] {portfolioInstance := 1}` |
| `list_length_zero_iff_nil` | aesop | `simp_all only [List.length_eq_zero_iff]` |
| `list_length_zero_iff_nil` | duper | (FAIL or no suggestion) |
| `nat_add_comm` | aesop | `sorry` |
| `nat_add_comm` | duper | (FAIL or no suggestion) |
| `subset_transitivity` | aesop | `sorry` |
| `subset_transitivity` | duper | (FAIL or no suggestion) |
| `function_const_compose` | aesop | `rfl` |
| `function_const_compose` | duper | `duper [*] {portfolioInstance := 2}` |
