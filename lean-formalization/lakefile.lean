import Lake
open Lake DSL

package «agent-manifest» where
  leanOptions := #[]

require mathlib from git
  "https://github.com/leanprover-community/mathlib4" @ "master"

lean_lib «Manifest» where
  srcDir := "."

lean_exe «extractdeps» where
  root := `ExtractDeps
  moreLinkArgs := #["-rdynamic"]
