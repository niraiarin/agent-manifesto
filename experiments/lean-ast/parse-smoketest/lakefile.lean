import Lake
open Lake DSL

package «parse-smoketest»

lean_exe «parse-smoketest» where
  root := `ParseSmoketest
  -- Default root. No Mathlib dependency — only Lean core.
