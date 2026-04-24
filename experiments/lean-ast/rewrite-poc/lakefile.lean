import Lake
open Lake DSL

package «rewrite-poc»

lean_exe «rewrite-poc» where
  root := `RewritePoC

lean_exe «elab-smoketest» where
  root := `ElabSmoketest
