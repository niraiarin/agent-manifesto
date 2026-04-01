import Lake
open Lake DSL

package «agent-manifest» where
  leanOptions := #[]

lean_lib «Manifest» where
  srcDir := "."

lean_exe «extractdeps» where
  root := `ExtractDeps
  moreLinkArgs := #["-rdynamic"]
