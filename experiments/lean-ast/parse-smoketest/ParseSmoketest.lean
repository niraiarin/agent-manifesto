import Lean

/-!
# Parse Smoketest — Sub-B PoC

Validates that we can:
1. Parse a .lean file using `Lean.Parser.Module.testParseFile`
2. Extract each top-level command as `Syntax`
3. Get the byte-level source range via `Syntax.getRange?`

Output: JSON array of declarations with name (if available), kind, and range.

Reference: Sub-B #657 Gate verification.
-/

open Lean Parser

/-- Recursively walk a Syntax and return the first identifier name. Partial because
    general Syntax has no structural termination measure that Lean can infer. -/
partial def firstIdent? (s : Syntax) : Option String :=
  match s with
  | .ident _ _ val _ => some val.toString
  | .node _ _ args => args.findSome? firstIdent?
  | _ => none

/-- Extract a declaration name from a command Syntax, or empty string if none. -/
def declName? (cmd : Syntax) : String :=
  (firstIdent? cmd).getD ""

/-- Classify command by its syntax kind. -/
def cmdKind (cmd : Syntax) : String :=
  match cmd with
  | .node _ kind _ =>
    let kstr := kind.toString
    if kstr.endsWith ".axiom" then "axiom"
    else if kstr.endsWith ".theorem" then "theorem"
    else if kstr.endsWith ".def" then "def"
    else if kstr.endsWith ".opaque" then "opaque"
    else if kstr.endsWith ".inductive" then "inductive"
    else if kstr.endsWith ".structure" then "structure"
    else if kstr.endsWith ".namespace" then "namespace"
    else if kstr.endsWith ".import" then "import"
    else kstr
  | _ => "unknown"

/-- JSON-escape a string (minimal). -/
def jsonEsc (s : String) : String :=
  s.foldl (init := "") fun acc c =>
    match c with
    | '"' => acc ++ "\\\""
    | '\\' => acc ++ "\\\\"
    | '\n' => acc ++ "\\n"
    | c => acc.push c

/-- Format a `Lean.Syntax.Range` as `[start, stop]` byte offsets. -/
def fmtRange (r : Lean.Syntax.Range) : String :=
  s!"[{r.start.byteIdx}, {r.stop.byteIdx}]"

def main (args : List String) : IO Unit := do
  match args with
  | [fname] => do
    -- Initialize search path and create a minimal environment
    initSearchPath (← findSysroot)
    let env ← importModules #[{ module := `Init }] {} (trustLevel := 1024)
    -- Parse the target file
    let stx ← testParseFile env fname
    -- stx.raw structure: node `Module.module` with args [header, listNode cmds]
    let raw : Syntax := stx.raw
    let args := raw.getArgs
    if args.size < 2 then
      IO.println "{\"error\": \"unexpected module structure\"}"
      return
    let header := args[0]!
    let cmdsNode := args[1]!
    let cmds := cmdsNode.getArgs
    -- Emit JSON
    IO.println "{"
    IO.println s!"  \"file\": \"{jsonEsc fname}\","
    match header.getRange? with
    | some r => IO.println s!"  \"headerRange\": {fmtRange r},"
    | none => IO.println "  \"headerRange\": null,"
    IO.println "  \"commands\": ["
    for i in [:cmds.size] do
      let cmd := cmds[i]!
      let name := declName? cmd
      let kind := cmdKind cmd
      let range := match cmd.getRange? with
        | some r => fmtRange r
        | none => "null"
      let comma := if i + 1 < cmds.size then "," else ""
      IO.println s!"    \{\"kind\": \"{jsonEsc kind}\", \"name\": \"{jsonEsc name}\", \"range\": {range}}{comma}"
    IO.println "  ]"
    IO.println "}"
  | _ =>
    IO.println "Usage: parse-smoketest <file.lean>"
    IO.Process.exit 1
