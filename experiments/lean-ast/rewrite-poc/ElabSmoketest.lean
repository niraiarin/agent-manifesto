import Lean

/-!
# Elaborator Runtime Smoketest — Sub-B (#657) CONDITIONAL fork absorption

Sub-B CONDITIONAL で「Elaborator runtime smoketest 未実施」が残存した課題を
本 smoketest で stabilize する。Sub-E (#660) scope に吸収済 (Sub-E method 5a)。

Purpose: confirm `Lean.Elab.runFrontend` (which internally uses `Lean.Elab.Command.elabCommand`)
is runtime-callable and produces a valid Environment from a trivial Lean source.

Exit codes:
  0 = ok, Elaborator API verified runtime-accessible
  3 = type_error (runFrontend returned none)
  10 = internal_error
-/

open Lean

def main : IO Unit := do
  initSearchPath (← findSysroot)
  let content := "axiom foo : Nat\n"
  let env? ← try
    Elab.runFrontend content {} "elab-smoketest-input.lean" `ElabSmoketest (trustLevel := 1024)
  catch e =>
    IO.eprintln s!"ERROR internal_error: {e.toString}"
    IO.Process.exit 10
  match env? with
  | some env =>
    IO.println s!"OK: Elaborator runtime smoketest passed"
    IO.println s!"  runFrontend produced Environment from 'axiom foo : Nat'"
    -- Verify our axiom is in the env
    match env.find? `foo with
    | some ci =>
      let kind := match ci with
        | .axiomInfo _ => "axiom"
        | _ => "other"
      IO.println s!"  Confirmed: 'foo' is in environment as {kind}"
    | none =>
      IO.eprintln "WARN: 'foo' not found in environment, but runFrontend succeeded"
  | none =>
    IO.eprintln "FAIL: runFrontend returned none (elab errors occurred)"
    IO.Process.exit 3
