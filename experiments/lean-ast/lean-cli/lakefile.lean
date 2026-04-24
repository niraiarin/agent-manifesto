import Lake
open Lake DSL

package «lean-cli-pkg» where

lean_lib «LeanCli» where
  srcDir := "."

@[default_target]
lean_exe «lean-cli» where
  root := `LeanCli
